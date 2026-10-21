//
//  FaceARTypes.swift
//  POC-v1-CT
//
//  Created by Davin P on 21/10/26.
//
import SwiftUI

/// 5 face shapes. Only `.oval` has real outline data for now.
/// NOTE: if the UI teammate also defines `FaceShape`, keep only ONE definition.
enum FaceShape: String, CaseIterable, Identifiable {
    case oval, round, square, heart, long
    var id: String { rawValue }
}

/// The 3 AR steps: contour -> blush -> highlight.
enum FaceARStep: Int, CaseIterable {
    case contour, blush, highlight

    var title: String {
        switch self {
        case .contour: return "Apply contour"
        case .blush: return "Apply blush"
        case .highlight: return "Apply highlight"
        }
    }

    var color: UIColor {
        switch self {
        case .contour: return UIColor(red: 0.55, green: 0.33, blue: 0.20, alpha: 1) // brown
        case .blush: return UIColor(red: 1.00, green: 0.45, blue: 0.60, alpha: 1)   // pink
        case .highlight: return .white
        }
    }

    var next: FaceARStep? { FaceARStep(rawValue: rawValue + 1) }
    var previous: FaceARStep? { FaceARStep(rawValue: rawValue - 1) }
}
