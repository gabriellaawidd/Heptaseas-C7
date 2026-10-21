//
//  CameraPlaceholder.swift
//  POC-v1-CT
//
//  Created by Gabriella Angelina Widjaja on 21/10/26.
//


import SwiftUI

struct CameraPlaceholder: View {
    var zoomed: Bool = false

    var body: some View {
        GeometryReader { geo in
            ZStack {
                LinearGradient(
                    colors: [Color(white: 0.35), Color(white: 0.15)],
                    startPoint: .top, endPoint: .bottom
                )
                Image(systemName: zoomed ? "eye.fill" : "person.fill")
                    .resizable()
                    .scaledToFit()
                    .foregroundStyle(.white.opacity(0.25))
                    .frame(width: geo.size.width * (zoomed ? 0.6 : 0.7))
                Text("Camera Preview")
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.6))
                    .frame(maxHeight: .infinity, alignment: .top)
                    .padding(.top, 70)
            }
            .frame(width: geo.size.width, height: geo.size.height)
            .clipped()
        }
    }
}
