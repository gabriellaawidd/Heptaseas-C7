import SwiftUI
import Combine

final class TutorialViewModel: ObservableObject {
    @Published var step: MakeupStep = .baseLight { didSet { push() } }
    @Published var side: EyeSide = .right { didSet { push() } }
    @Published var mode: DisplayMode = .singleEye { didSet { push() } }
    /// Pengali zoom dari bar vertikal (1.0 = default).
    @Published var zoomMultiplier: CGFloat = 1.0

    let face = ARFaceController()
    let speech = SpeechCommandController()

    init() {
        speech.onCommand = { [weak self] cmd in
            DispatchQueue.main.async { self?.handle(cmd) }
        }
        push()
    }

    func start() { face.start(); speech.start() }
    func stop()  { face.stop();  speech.stop() }

    func handle(_ cmd: SpeechCommandController.Command) {
        switch cmd {
        case .next:
            guard let n = MakeupStep(rawValue: step.rawValue + 1) else { return }
            go(to: n)
        case .previous:
            guard let p = MakeupStep(rawValue: step.rawValue - 1) else { return }
            go(to: p)
        }
    }

    func reset() { go(to: .baseLight) }

    private func go(to newStep: MakeupStep) {
        withAnimation(.easeInOut(duration: 0.25)) { step = newStep }
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
    }

    private func push() { face.update(step: step, side: side, mode: mode) }
}
