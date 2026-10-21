//
//  CameraPlaceholder.swift
//  POC-v1-CT
//
//  Created by Gabriella Angelina Widjaja on 21/10/26.
//


import SwiftUI

struct EyeZoomPlaceholder: View {
    var body: some View {
        ZStack {
            Color.black
            Image(systemName: "eye")
                .resizable()
                .scaledToFit()
                .foregroundStyle(.white.opacity(0.5))
                .padding(60)
        }
    }
}

struct FacePlaceholder: View {
    var body: some View {
        ZStack {
            Color.black
            Image(systemName: "person.crop.square")
                .resizable()
                .scaledToFit()
                .foregroundStyle(.white.opacity(0.5))
                .padding(40)
        }
    }
}
