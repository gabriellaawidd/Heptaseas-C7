//
//  EyeMakeupFlowView.swift
//  POC-v1-CT
//
//  Created by Gabriella Angelina Widjaja on 21/10/26.
//


import SwiftUI

struct EyeMakeupFlowView: View {
    let onFinish: () -> Void

    @StateObject private var vm = TutorialViewModel()

    var body: some View {
        ARStepFlowView(vm: vm, onFinish: onFinish) {
            EyeStepContent(vm: vm)
        }
        .onAppear { vm.start() }
        .onDisappear { vm.stop() }
    }
}

private struct EyeStepContent: View {
    @ObservedObject var vm: TutorialViewModel

    /// Diisi oleh panel wajah (ukuran aslinya dipakai sebagai viewport AR).
    @State private var viewport = CGSize(width: 390, height: 433)

    private let spacing: CGFloat = 8
    private let inset: CGFloat = 8

    var body: some View {
        GeometryReader { geo in
            // Panel atas dan bawah masing-masing 50% tinggi yang tersedia
            let panelH = max((geo.size.height - spacing - inset) / 2, 0)

            VStack(spacing: spacing) {
                topPanel
                    .frame(height: panelH)

                bottomPanel
                    .frame(height: panelH)
            }
            .padding(.horizontal, inset)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        }
        .background(Color(.systemBackground))
    }

    // MARK: Panel atas (mata)

    @ViewBuilder
    private var topPanel: some View {
        if ARFaceController.isSupported {
            EyeCameraPanel(vm: vm, face: vm.face, viewport: viewport)
        } else {
            // Simulator / device tanpa TrueDepth: tetap tampil pakai placeholder
            EyeZoomPlaceholder()
                .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
        }
    }

    // MARK: Panel bawah (wajah) + instruksi step sebagai overlay

    private var bottomPanel: some View {
        ZStack(alignment: .top) {
            if ARFaceController.isSupported {
                FaceCameraPanel(face: vm.face, speech: vm.speech, viewport: $viewport)
            } else {
                FacePlaceholder()
                    .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
            }

            LabelPill(text: vm.step.instruction)
                .padding(.top, 14)
        }
    }
}
