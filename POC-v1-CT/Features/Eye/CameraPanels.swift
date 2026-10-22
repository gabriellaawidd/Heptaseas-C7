//
//  CameraPanels.swift
//  POC-v1-CT
//
//  Created by Davin P on 21/10/26.
//
import SwiftUI

// MARK: - Panel atas: fokus ke mata (distabilkan) + guide

struct EyeCameraPanel: View {
    @ObservedObject var vm: TutorialViewModel
    @ObservedObject var face: ARFaceController
    /// Ukuran viewport AR (sama dengan ukuran panel wajah di bawah).
    let viewport: CGSize
    
    // Target jarak antar mata di panel (kelipatan lebar panel)
    private let bothEyesSpan: CGFloat = 0.70   // 👀: kedua mata terlihat
    private let singleEyeSpan: CGFloat = 1.45  // 👁: satu mata memenuhi panel
    
    var body: some View {
        GeometryReader { geo in
            let size = geo.size
            let (t, zoom) = cropTransform(size: size)
            
            ZStack {
                FaceCanvas(frame: face.frame, viewport: viewport, transform: t, zoom: zoom)
                    .scaleEffect(x: -1, y: 1)
                
                VStack {
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
    }
    
    /// Transform viewport -> panel: pusat target ke tengah panel, wajah diluruskan (anti-roll), lalu zoom.
    private func cropTransform(size: CGSize) -> (CGAffineTransform, CGFloat) {
        let W = size.width
        var center = CGPoint(x: viewport.width / 2, y: viewport.height * 0.4)
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

// MARK: - Panel bawah: wajah penuh (tanpa guide)

struct FaceCameraPanel: View {
    @ObservedObject var face: ARFaceController
    @ObservedObject var speech: SpeechCommandController
    /// Ukuran panel ini dipakai sebagai viewport AR.
    @Binding var viewport: CGSize
    
    var body: some View {
        GeometryReader { geo in
            ZStack {
                FaceCanvas(frame: face.frame, viewport: geo.size, showGuide: false)
                    .scaleEffect(x: -1, y: 1)
                
                VStack {
                    HStack {
                        Spacer()
                        VoiceHint(speech: speech)
                    }
                    
                    Spacer()
                    
                    if !face.isFaceTracked {
                        Label("Position your face", systemImage: "face.dashed")
                            .font(.footnote.weight(.medium))
                            .padding(.horizontal, 12).padding(.vertical, 8)
                            .background(.ultraThinMaterial, in: Capsule())
                    }
                }
                .padding(14)
            }
            .frame(width: geo.size.width, height: geo.size.height)
            .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
            .onAppear { sync(geo.size) }
            .onChange(of: geo.size) { _, s in sync(s) }
        }
    }
    
    private func sync(_ s: CGSize) {
        viewport = s
        face.setViewport(s)
    }
}
