//
//  EyeMakeupFlowView.swift
//  POC-v1-CT
//
//  Created by Gabriella Angelina Widjaja on 21/10/26.
//


import SwiftUI

struct EyeMakeupFlowView: View {
    let onFinish: () -> Void

    private var steps: [MakeupStep] {
        [
            MakeupStep(title: "Apply Base Color") {
                EyeStepContent(label: "Apply Base Color")
            },
            MakeupStep(title: "Apply Shading") {
                EyeStepContent(label: "Apply Shading")
            },
        ]
    }

    var body: some View {
        StepFlowView(steps: steps, onFinish: onFinish)
    }
}

private struct EyeStepContent: View {
    let label: String

    var body: some View {
        VStack(spacing: 0) {
            EyeZoomPlaceholder()
                .aspectRatio(1.4, contentMode: .fit)

            LabelPill(text: label)
                .padding(.vertical, 14)

            FacePlaceholder()
                .aspectRatio(0.9, contentMode: .fit)

            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity)
        .background(Color(.systemBackground))
    }
}
