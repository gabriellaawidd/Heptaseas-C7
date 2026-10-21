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
                FaceStepContent(label: "Apply Contour", arStep: .contour)
            },
            MakeupStep(title: "Apply Blush") {
                FaceStepContent(label: "Apply Blush", arStep: .blush)
            },
            MakeupStep(title: "Apply Highlight") {
                FaceStepContent(label: "Apply Highlight", arStep: .highlight)
            },
        ]
    }

    var body: some View {
        StepFlowView(steps: steps, onFinish: onFinish)
    }
}

private struct FaceStepContent: View {
    let label: String
    let arStep: FaceARStep

    var body: some View {
        ZStack(alignment: .bottomLeading) {
            // Same view type every step -> SwiftUI keeps one AR session and only swaps the outlines.
            FaceARView(shape: .oval, step: arStep)
                .ignoresSafeArea()
            LabelPill(text: label)
                .padding(16)
        }
    }
}
