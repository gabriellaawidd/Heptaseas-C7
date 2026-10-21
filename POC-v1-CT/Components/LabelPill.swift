//
//  LabelPill.swift
//  POC-v1-CT
//
//  Created by Gabriella Angelina Widjaja on 21/10/26.
//


import SwiftUI

struct LabelPill: View {
    let text: String

    var body: some View {
        Text(text)
            .font(.subheadline.weight(.medium))
            .foregroundStyle(.black)
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(.white, in: Capsule())
            .shadow(color: .black.opacity(0.15), radius: 4, y: 2)
    }
}
