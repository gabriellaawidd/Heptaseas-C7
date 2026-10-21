import SwiftUI

struct TutorialView: View {
    @StateObject private var vm = TutorialViewModel()

    var body: some View {
        GeometryReader { geo in
            let spacing: CGFloat = 8
            let panelW = geo.size.width - 16
            let panelH = (geo.size.height - spacing - 16) / 2
            let panelSize = CGSize(width: panelW, height: panelH)

            Group {
                if ARFaceController.isSupported {
                    VStack(spacing: spacing) {
                        EyePanel(vm: vm, face: vm.face, size: panelSize)
                        FacePanel(vm: vm, face: vm.face, speech: vm.speech, size: panelSize)
                    }
                    .padding(8)
                    .onAppear { vm.face.setViewport(panelSize) }
                    .onChange(of: panelSize) { _, s in vm.face.setViewport(s) }
                } else {
                    Text("Face tracking requires an iPhone with Face ID (TrueDepth).")
                        .multilineTextAlignment(.center)
                        .padding()
                }
            }
        }
        .background(Color.black.ignoresSafeArea())
        .onAppear { vm.start() }
        .onDisappear { vm.stop() }
    }
}

// MARK: - Panel atas: fokus ke mata (distabilkan)

struct EyePanel: View {
    @ObservedObject var vm: TutorialViewModel
    @ObservedObject var face: ARFaceController
    let size: CGSize

    // Ukuran target jarak antar mata di panel (kelipatan lebar panel)
    private let bothEyesSpan: CGFloat = 0.70   // 👀: kedua mata terlihat
    private let singleEyeSpan: CGFloat = 1.45  // 👁: satu mata memenuhi panel

    var body: some View {
        let (t, zoom) = cropTransform()

        ZStack {
            FaceCanvas(frame: face.frame, viewport: size, transform: t, zoom: zoom)
                .scaleEffect(x: -1, y: 1)

            VStack {
                HStack {
                    Button { vm.reset() } label: {
                        Image(systemName: "chevron.left")
                            .font(.title3.weight(.medium))
                            .foregroundStyle(.white)
                            .frame(width: 50, height: 50)
                            .background(.ultraThinMaterial, in: Circle())
                    }
                    Spacer()
                }
                Spacer()
                VStack(spacing: 10) {
                    // Toggle R/L hanya relevan di mode 👁
                    SideToggle(side: $vm.side)
                        .opacity(vm.mode == .singleEye ? 1 : 0)
                        .allowsHitTesting(vm.mode == .singleEye)
                    ModePicker(mode: $vm.mode)
                }
            }
            .padding(14)

            // Bar zoom vertikal di sisi kanan
            HStack {
                Spacer()
                ZoomBar(value: $vm.zoomMultiplier, range: 0.5...2.5)
                    .padding(.trailing, 12)
            }
        }
        .frame(width: size.width, height: size.height)
        .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
        .animation(.easeInOut(duration: 0.2), value: vm.mode)
    }

    /// Transform viewport -> panel: pusat target ke tengah panel, wajah diluruskan (anti-roll), lalu zoom.
    private func cropTransform() -> (CGAffineTransform, CGFloat) {
        let W = size.width
        var center = CGPoint(x: W / 2, y: size.height * 0.4)
        var base: CGFloat = (vm.mode == .bothEyes) ? 1.8 : 3.2
        var angle: CGFloat = 0

        if let crop = face.frame?.crop {
            let d = max(crop.eyeDistance, 1)
            switch vm.mode {
            case .bothEyes:
                center = crop.mid
                base = bothEyesSpan * W / d
            case .singleEye:
                center = crop.centers[vm.side] ?? crop.mid
                base = singleEyeSpan * W / d
            }
            angle = crop.angle
        }

        let zoom = min(max(base * vm.zoomMultiplier, 0.8), 12)
        let t = CGAffineTransform(translationX: -center.x, y: -center.y)
            .concatenating(CGAffineTransform(rotationAngle: -angle))
            .concatenating(CGAffineTransform(scaleX: zoom, y: zoom))
            .concatenating(CGAffineTransform(translationX: W / 2, y: size.height / 2))
        return (t, zoom)
    }
}

// MARK: - Panel bawah: wajah penuh (tanpa AR) + instruksi

struct FacePanel: View {
    @ObservedObject var vm: TutorialViewModel
    @ObservedObject var face: ARFaceController
    @ObservedObject var speech: SpeechCommandController
    let size: CGSize

    var body: some View {
        ZStack {
            FaceCanvas(frame: face.frame, viewport: size, showGuide: false)
                .scaleEffect(x: -1, y: 1)

            VStack(spacing: 8) {
                VStack(spacing: 6) {
                    HStack(spacing: 6) {
                        ForEach(MakeupStep.allCases, id: \.self) { s in
                            Capsule()
                                .fill(s == vm.step ? Color.white : Color.white.opacity(0.3))
                                .frame(width: s == vm.step ? 24 : 8, height: 6)
                        }
                    }
                    Text("Step \(vm.step.number) of \(MakeupStep.total)")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                    Text(vm.step.instruction)
                        .font(.headline)
                        .multilineTextAlignment(.center)
                        .id(vm.step)
                        .transition(.opacity)
                }
                .padding(.horizontal, 16).padding(.vertical, 10)
                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 18, style: .continuous))

                Spacer()

                if !face.isFaceTracked {
                    Label("Position your face in the frame", systemImage: "face.dashed")
                        .font(.footnote.weight(.medium))
                        .padding(.horizontal, 12).padding(.vertical, 8)
                        .background(.ultraThinMaterial, in: Capsule())
                }

                HStack(spacing: 6) {
                    Image(systemName: speech.isListening ? "mic.fill" : "mic.slash.fill")
                        .foregroundStyle(speech.isListening ? .green : .red)
                    Text(speech.permissionDenied
                         ? "Enable microphone & speech access in Settings"
                         : "Say “next” or “previous”")
                        .font(.footnote.weight(.medium))
                }
                .padding(.horizontal, 12).padding(.vertical, 8)
                .background(.ultraThinMaterial, in: Capsule())
            }
            .padding(14)
        }
        .frame(width: size.width, height: size.height)
        .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
    }
}

// MARK: - Kontrol

/// Bar zoom vertikal: atas = zoom in, bawah = zoom out. Double-tap label untuk reset ke 1.0x.
struct ZoomBar: View {
    @Binding var value: CGFloat
    let range: ClosedRange<CGFloat>
    private let trackHeight: CGFloat = 150

    private var fraction: CGFloat {
        (value - range.lowerBound) / (range.upperBound - range.lowerBound)
    }

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: "plus")
                .font(.system(size: 13, weight: .bold))

            ZStack(alignment: .bottom) {
                Capsule().fill(Color.white.opacity(0.25)).frame(width: 6, height: trackHeight)
                Capsule().fill(Color.white).frame(width: 6, height: max(6, trackHeight * fraction))
                Circle()
                    .fill(Color.white)
                    .frame(width: 22, height: 22)
                    .shadow(radius: 2)
                    .offset(y: -(trackHeight * fraction) + 11)
            }
            .frame(width: 36, height: trackHeight)
            .contentShape(Rectangle())
            .gesture(
                DragGesture(minimumDistance: 0).onChanged { g in
                    let p = 1 - min(max(g.location.y / trackHeight, 0), 1)
                    value = range.lowerBound + p * (range.upperBound - range.lowerBound)
                }
            )

            Image(systemName: "minus")
                .font(.system(size: 13, weight: .bold))

            Text(String(format: "%.1f×", Double(value)))
                .font(.caption2.monospacedDigit().weight(.semibold))
                .onTapGesture(count: 2) { value = 1.0 }
        }
        .foregroundStyle(.white)
        .padding(.vertical, 12)
        .frame(width: 44)
        .background(.ultraThinMaterial, in: Capsule())
    }
}

/// Toggle R / L (pill hitam dengan knob putih)
struct SideToggle: View {
    @Binding var side: EyeSide
    
    private var label: String { side == .right ? "L" : "R" }

    var body: some View {
        Button {
            side = (side == .right) ? .left : .right
        } label: {
            ZStack {
                Capsule().fill(Color.black).frame(width: 64, height: 28)
                Capsule().fill(Color.white)
                    .frame(width: 34, height: 22)
                    .overlay(Text(label)
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(.black))
                    .offset(x: label == "R" ? 13 : -13)
            }
        }
        .buttonStyle(.plain)
        .animation(.spring(duration: 0.25), value: side)
    }
}

/// Segmented: 👀 kedua mata (zoom, dua mata terlihat) / 👁 satu mata (R atau L)
struct ModePicker: View {
    @Binding var mode: DisplayMode

    var body: some View {
        HStack(spacing: 4) {
            segment(.bothEyes) { Text("👀").font(.system(size: 26)) }
            segment(.singleEye) {
                Image(systemName: "eye.fill")
                    .font(.system(size: 26))
                    .foregroundStyle(mode == .singleEye ? Color.blue : Color.white.opacity(0.7))
            }
        }
        .padding(5)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 26, style: .continuous))
        .animation(.easeInOut(duration: 0.2), value: mode)
    }

    private func segment<Content: View>(_ m: DisplayMode, @ViewBuilder content: () -> Content) -> some View {
        Button { mode = m } label: {
            content()
                .frame(width: 96, height: 48)
                .background(mode == m ? Color.white.opacity(0.25) : Color.clear,
                            in: RoundedRectangle(cornerRadius: 22, style: .continuous))
        }
        .buttonStyle(.plain)
    }
}
