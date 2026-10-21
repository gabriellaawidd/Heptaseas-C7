//
//  MakeupStep.swift
//  POC-v1-CT
//
//  Created by Gabriella Angelina Widjaja on 21/10/26.
//


import SwiftUI

struct MakeupStepPage: Identifiable {
    let id = UUID()
    let title: String
    let content: AnyView

    init<Content: View>(title: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.content = AnyView(content())
    }
}
