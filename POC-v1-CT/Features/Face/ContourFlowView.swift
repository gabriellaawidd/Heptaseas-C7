//
//  ContourFlowView.swift
//  POC-v1-CT
//
//  Created by Gabriella Angelina Widjaja on 21/10/26.
//


import SwiftUI

struct ContourFlowView: View {
    let onFinish: () -> Void

    private var steps: [MakeupStep] {
        [
            MakeupStep(title: "Apply Contour") {
                FaceStepContent(label: "Apply Contour")
            },
            MakeupStep(title: "Apply Blush") {
                FaceStepContent(label: "Apply Blush")
            },
            MakeupStep(title: "Apply Highlight") {
                FaceStepContent(label: "Apply Highlight")
            },
        ]
    }

    var body: some View {
        StepFlowView(steps: steps, onFinish: onFinish)
    }
}

private struct FaceStepContent: View {
    let label: String

    var body: some View {
        ZStack(alignment: .bottomLeading) {
            FacePlaceholder()
            LabelPill(text: label)
                .padding(16)
        }
    }
}
