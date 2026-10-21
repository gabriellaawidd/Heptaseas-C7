//
//  ContentView.swift
//  POC-v1-CT
//
//  Created by Davin P on 21/10/26.
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        TabView {
            Tab("Eye Makeup", systemImage: "eye") {
                EyeMakeupView()
            }
            Tab("Contour", systemImage: "face.smiling") {
                ContourView()
            }
        }
        .preferredColorScheme(.dark)
    }
}

#Preview {
    ContentView()
}
