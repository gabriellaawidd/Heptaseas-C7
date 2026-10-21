//
//  FaceARDemoView.swift
//  POC-v1-CT
//
//  Created by Davin P on 21/10/26.
//
import SwiftUI
import Observation

/// TEMPORARY test screen: Previous / Next buttons to switch AR steps.
/// Not part of the final UI. Voice control can later call the same next() / previous().
@Observable
final class FaceARViewModel {
    var shape: FaceShape = .oval
    var step: MakeupStep = .contour

    var canGoNext: Bool { step.next != nil }
    var canGoPrevious: Bool { step.previous != nil }

    func next() {
        if let next = step.next { step = next }
    }

    func previous() {
        if let previous = step.previous { step = previous }
    }
}

struct FaceARDemoView: View {
    @State private var viewModel = FaceARViewModel()

    var body: some View {
        ZStack(alignment: .bottom) {
            FaceARView(shape: viewModel.shape,
                       step: viewModel.step,
                       showDebugMesh: false) // set true to see the face mesh while tuning
                .ignoresSafeArea()

            VStack(spacing: 12) {
                Text("\(viewModel.step.rawValue + 1). \(viewModel.step.title)")
                    .font(.headline)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(.ultraThinMaterial, in: Capsule())

                HStack(spacing: 16) {
                    Button("Previous") { viewModel.previous() }
                        .disabled(!viewModel.canGoPrevious)
                    Button("Next") { viewModel.next() }
                        .disabled(!viewModel.canGoNext)
                }
                .buttonStyle(.borderedProminent)
            }
            .padding(.bottom, 32)
        }
    }
}
