//
//  StepFlowView.swift
//  POC-v1-CT
//
//  Created by Gabriella Angelina Widjaja on 21/10/26.
//


import SwiftUI

struct StepFlowView: View {
    let steps: [MakeupStep]
    let onFinish: () -> Void

    @State private var currentIndex = 0
    @Environment(\.dismiss) private var dismiss

    private var isLastStep: Bool {
        currentIndex == steps.count - 1
    }

    var body: some View {
        ZStack(alignment: .topLeading) {
            steps[currentIndex].content
                .id(steps[currentIndex].id)

            backButton
        }
        .overlay(alignment: .bottomTrailing) {
            nextFinishButton
        }
        .navigationBarBackButtonHidden(true)
        .animation(.easeInOut(duration: 0.2), value: currentIndex)
    }

    private var backButton: some View {
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

    private var nextFinishButton: some View {
        Button {
            advance()
        } label: {
            Text(isLastStep ? "Finish" : "Next")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.white)
                .padding(.horizontal, 22)
                .padding(.vertical, 12)
                .background(.blue, in: Capsule())
        }
        .padding(16)
    }

    private func advance() {
        if isLastStep {
            onFinish()
        } else {
            currentIndex += 1
        }
    }
}
