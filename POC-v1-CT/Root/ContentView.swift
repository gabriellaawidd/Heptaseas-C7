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
            Tab("Eye Makeup", systemImage: "eye") { EyeMakeupView() }
            Tab("Face Makeup", systemImage: "camera") { FaceARDemoView() }
        }
        .preferredColorScheme(.dark)
    }
}

#Preview {
    ContentView()
}
