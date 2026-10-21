//
//
//  EyeMakeupView.swift
//  POC-v1-CT
//
//  Created by Gabriella Angelina Widjaja on 21/10/26.
//

import Speech
import Combine

/// Voice command "next" / "previous" (en-US, on-device jika tersedia).
final class SpeechCommandController: ObservableObject {
    enum Command { case next, previous }

    @Published private(set) var isListening = false
    @Published private(set) var lastHeard = ""
    @Published private(set) var permissionDenied = false

    var onCommand: ((Command) -> Void)?

    private let recognizer = SFSpeechRecognizer(locale: Locale(identifier: "en-US"))
    private let engine = AVAudioEngine()
    private var task: SFSpeechRecognitionTask?
    private var generation = 0
    private var lastFire = Date.distantPast
    private var refreshTimer: Timer?

    private let reqLock = NSLock()
    private var _request: SFSpeechAudioBufferRecognitionRequest?
    private var request: SFSpeechAudioBufferRecognitionRequest? {
        get { reqLock.lock(); defer { reqLock.unlock() }; return _request }
        set { reqLock.lock(); _request = newValue; reqLock.unlock() }
    }

    // MARK: Lifecycle
    func start() {
        SFSpeechRecognizer.requestAuthorization { status in
            DispatchQueue.main.async {
                guard status == .authorized else { self.permissionDenied = true; return }
                AVAudioApplication.requestRecordPermission { granted in
                    DispatchQueue.main.async {
                        guard granted else { self.permissionDenied = true; return }
                        self.startEngine()
                    }
                }
            }
        }
    }

    func stop() {
        refreshTimer?.invalidate()
        generation += 1
        task?.cancel(); task = nil
        request?.endAudio(); request = nil
        if engine.isRunning { engine.stop() }
        engine.inputNode.removeTap(onBus: 0)
        isListening = false
    }

    private func startEngine() {
        do {
            let s = AVAudioSession.sharedInstance()
            try s.setCategory(.playAndRecord, mode: .measurement, options: [.duckOthers, .defaultToSpeaker])
            try s.setAllowHapticsAndSystemSoundsDuringRecording(true)
            try s.setActive(true, options: .notifyOthersOnDeactivation)

            let input = engine.inputNode
            input.removeTap(onBus: 0)
            input.installTap(onBus: 0, bufferSize: 1024, format: input.outputFormat(forBus: 0)) { [weak self] buffer, _ in
                self?.request?.append(buffer)
            }
            engine.prepare()
            try engine.start()
            isListening = true
            beginRecognition()

            // Request speech dibatasi ~1 menit; refresh berkala.
            refreshTimer = Timer.scheduledTimer(withTimeInterval: 50, repeats: true) { [weak self] _ in
                self?.beginRecognition()
            }
        } catch {
            print("Speech engine error:", error)
        }
    }

    // MARK: Recognition
    private func beginRecognition() {
        generation += 1
        let gen = generation
        task?.cancel()
        request?.endAudio()

        guard let recognizer, recognizer.isAvailable else { return }

        let req = SFSpeechAudioBufferRecognitionRequest()
        req.shouldReportPartialResults = true
        req.contextualStrings = ["next", "previous"]
        if recognizer.supportsOnDeviceRecognition { req.requiresOnDeviceRecognition = true }
        request = req

        task = recognizer.recognitionTask(with: req) { [weak self] result, error in
            DispatchQueue.main.async {
                guard let self, gen == self.generation else { return }
                if let result, self.handle(result) { return }
                if error != nil || result?.isFinal == true {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                        if gen == self.generation { self.beginRecognition() }
                    }
                }
            }
        }
    }

    /// Return true jika command terdeteksi (dan recognition di-restart).
    private func handle(_ result: SFSpeechRecognitionResult) -> Bool {
        let t = result.bestTranscription
        lastHeard = t.formattedString.lowercased()

        guard let word = t.segments.last?.substring.lowercased().filter({ $0.isLetter }) else { return false }
        let command: Command?
        switch word {
        case "next": command = .next
        case "previous": command = .previous
        default: command = nil
        }
        guard let command, Date().timeIntervalSince(lastFire) > 1.0 else { return false }

        lastFire = Date()
        onCommand?(command)
        beginRecognition()   // reset transcript supaya kata lama tidak terbaca ulang
        return true
    }
}
