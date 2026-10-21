//
//  StepFlowView.swift
//  POC-v1-CT
//
//  Created by Gabriella Angelina Widjaja on 21/10/26.
//


import SwiftUI

// MARK: - Flow berbasis daftar halaman (Contour, dll.)

struct StepFlowView: View {
    let steps: [MakeupStepPage]
    let onFinish: () -> Void

    @State private var currentIndex = 0

    private var isLastStep: Bool {
        currentIndex == steps.count - 1
    }

    var body: some View {
        ZStack(alignment: .topLeading) {
            steps[currentIndex].content

            FlowBackButton()
        }
        .overlay(alignment: .bottomTrailing) {
            FlowNextButton(isLastStep: isLastStep) {
                if isLastStep {
                    onFinish()
                } else {
                    currentIndex += 1
                }
            }
        }
        .navigationBarBackButtonHidden(true)
        .animation(.easeInOut(duration: 0.2), value: currentIndex)
    }
}

// MARK: - Flow berbasis AR (Eye makeup)

/// Step dikelola oleh `TutorialViewModel` (enum `MakeupStep`), jadi tombol Next
/// dan voice command "next" / "previous" selalu sinkron.
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
        .navigationBarBackButtonHidden(true)
        .animation(.easeInOut(duration: 0.2), value: vm.step)
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
