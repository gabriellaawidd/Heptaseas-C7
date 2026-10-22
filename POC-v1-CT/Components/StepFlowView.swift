//
//  StepFlowView.swift
//  POC-v1-CT
//
//  Created by Gabriella Angelina Widjaja on 21/10/26.
//


import SwiftUI

struct StepFlowView: View {
    let steps: [MakeupStepPage]
    var voiceControl = false
    let onFinish: () -> Void
    
    @State private var currentIndex = 0
    @StateObject private var speech = SpeechCommandController()
    
    private var isLastStep: Bool {
        currentIndex == steps.count - 1
    }
    
    var body: some View {
        ZStack(alignment: .topLeading) {
            steps[currentIndex].content
            
            FlowBackButton()
        }
        .overlay(alignment: .topTrailing) {
            if voiceControl {
                VoiceHint(speech: speech)
                    .padding([.top, .trailing], 12)
            }
        }
        .overlay(alignment: .bottomTrailing) {
            FlowNextButton(isLastStep: isLastStep) {
                if isLastStep {
                    onFinish()
                } else {
                    go(to: currentIndex + 1)
                }
            }
        }
        .overlay(alignment: .bottomLeading) {
            if currentIndex > 0 {
                FlowPreviousButton { go(to: currentIndex - 1) }
            }
        }
        .navigationBarBackButtonHidden(true)
        .animation(.easeInOut(duration: 0.2), value: currentIndex)
        .onAppear {
            guard voiceControl else { return }
            speech.onCommand = { cmd in
                DispatchQueue.main.async { handle(cmd) }
            }
            speech.start()
        }
        .onDisappear {
            if voiceControl { speech.stop() }
        }
    }
    
    private func handle(_ cmd: SpeechCommandController.Command) {
        switch cmd {
        case .next:
            guard !isLastStep else { return }
            go(to: currentIndex + 1)
        case .previous:
            guard currentIndex > 0 else { return }
            go(to: currentIndex - 1)
        case .finish:
            guard isLastStep else { return }
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            onFinish()
        }
    }
    
    private func go(to index: Int) {
        withAnimation(.easeInOut(duration: 0.25)) { currentIndex = index }
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
    }
}

// MARK: - Flow berbasis AR (Eye makeup)

struct ARStepFlowView<Content: View>: View {
    @ObservedObject var vm: TutorialViewModel
    let onFinish: () -> Void
    @ViewBuilder let content: () -> Content
    
    private var isLastStep: Bool {
        vm.step == MakeupStep.allCases.last
    }
    
    var body: some View {
        ZStack(alignment: .topLeading) {
            content()
            
            FlowBackButton()
        }
        .overlay(alignment: .bottomTrailing) {
            FlowNextButton(isLastStep: isLastStep) {
                if isLastStep {
                    onFinish()
                } else {
                    vm.handle(.next)
                }
            }
        }
        .overlay(alignment: .bottomLeading) {
            if vm.step != MakeupStep.allCases.first {
                FlowPreviousButton { vm.handle(.previous) }
            }
        }
        .navigationBarBackButtonHidden(true)
        .animation(.easeInOut(duration: 0.2), value: vm.step)
        .onAppear { vm.onFinish = onFinish }
    }
}

// MARK: - Tombol bersama

private struct FlowBackButton: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        Button {
            dismiss()
        } label: {
            Image(systemName: "chevron.left")
                .font(.headline)
                .foregroundStyle(.white)
                .padding(10)
                .background(.black.opacity(0.35), in: Circle())
        }
        .padding([.top, .leading], 12)
    }
}

private struct FlowNextButton: View {
    let isLastStep: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(isLastStep ? "Finish" : "Next")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.white)
                .padding(.horizontal, 22)
                .padding(.vertical, 12)
                .background(.blue, in: Capsule())
        }
        .padding(16)
    }
}

private struct FlowPreviousButton: View {
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text("Previous")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.white)
                .padding(.horizontal, 22)
                .padding(.vertical, 12)
                .background(.ultraThinMaterial, in: Capsule())
        }
        .padding(16)
    }
}

struct VoiceHint: View {
    @ObservedObject var speech: SpeechCommandController
    @State private var expanded = true

    var body: some View {
        VStack(alignment: .trailing, spacing: 8) {
            Image(systemName: speech.isListening ? "mic.fill" : "mic.slash.fill")
                .font(.subheadline)
                .foregroundStyle(speech.isListening ? .green : .red)
                .frame(width: 40, height: 40)
                .background(.ultraThinMaterial, in: Circle())
                .onTapGesture {
                    withAnimation(.easeInOut(duration: 0.2)) { expanded.toggle() }
                }

            if expanded {
                Text(speech.permissionDenied
                     ? "Enable microphone & speech access in Settings"
                     : "Say “next”, “previous” or “finish”")
                    .font(.footnote.weight(.medium))
                    .padding(.horizontal, 12).padding(.vertical, 8)
                    .background(.ultraThinMaterial, in: Capsule())
                    .transition(.opacity)
            }
        }
        .task {
            try? await Task.sleep(for: .seconds(4))
            withAnimation(.easeInOut(duration: 0.3)) { expanded = false }
        }
    }
}
