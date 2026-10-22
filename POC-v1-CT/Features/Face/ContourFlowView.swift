//
//  ContourFlowView.swift
//  POC-v1-CT
//
//  Created by Gabriella Angelina Widjaja on 21/10/26.
//


import SwiftUI

struct ContourFlowView: View {
    let onFinish: () -> Void
    
    private var steps: [MakeupStepPage] {
        [
            MakeupStepPage(title: "Apply Contour") {
                FaceStepContent(label: "Apply Contour", arStep: .contour)
            },
            MakeupStepPage(title: "Apply Blush") {
                FaceStepContent(label: "Apply Blush", arStep: .blush)
            },
            MakeupStepPage(title: "Apply Highlight") {
                FaceStepContent(label: "Apply Highlight", arStep: .highlight)
            },
        ]
    }
    
    var body: some View {
        StepFlowView(steps: steps, voiceControl: true, onFinish: onFinish)
    }
}

private struct FaceStepContent: View {
    let label: String
    let arStep: FaceARStep
    
    var body: some View {
        ZStack(alignment: .top) {
            FaceARView(shape: .oval, step: arStep)
                .ignoresSafeArea()
            LabelPill(text: label)
                .padding(.top, 12)
        }
    }
}
