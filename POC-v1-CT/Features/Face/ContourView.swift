//
//  ContourView.swift
//  POC-v1-CT
//
//  Created by Gabriella Angelina Widjaja on 21/10/26.
//

import SwiftUI

struct ContourView: View {
    var body: some View {
        CameraPlaceholder()
            .ignoresSafeArea()
    }
}

#Preview {
    NavigationStack { ContourView() }
}
