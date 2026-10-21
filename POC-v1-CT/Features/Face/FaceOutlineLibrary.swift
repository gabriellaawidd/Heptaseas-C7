//
//  FaceOutlineLibrary.swift
//  POC-v1-CT
//
//  Created by Davin P on 21/10/26.
//

import UIKit
import simd

/// A closed outline in NORMALIZED face space:
/// x: -1...1 across the face mesh width, y: -1...1 from chin (-1) to forehead (+1).
/// (0, 0) is the center of the mesh. Values can go slightly past +-1 (outside the mesh).
struct OutlinePath {
    let points: [SIMD2<Float>]
}

enum FaceOutlineLibrary {

    static let guideColor = UIColor(red: 1.00, green: 0.45, blue: 0.20, alpha: 1) // orange dotted oval

    // MARK: - Public API

    /// The big dotted face-shape outline, shown on every step.
    static func guide(for shape: FaceShape) -> [OutlinePath] {
        switch shape {
        case .oval:
            return [ellipse(center: [0, 0], rx: 1.05, ry: 1.15)]
        case .round, .square, .heart, .long:
            // TODO: add real outlines when the references are ready. Falls back to oval for now.
            return guide(for: .oval)
        }
    }

    /// Outlines for the current step (contour / blush / highlight).
    static func outlines(for step: MakeupStep, shape: FaceShape) -> [OutlinePath] {
        switch shape {
        case .oval:
            return ovalOutlines(for: step)
        case .round, .square, .heart, .long:
            // TODO: per-shape placement. Falls back to oval for now.
            return ovalOutlines(for: step)
        }
    }

    // MARK: - Oval face placement (initial guesses, tune using the debug mesh)

    private static func ovalOutlines(for step: MakeupStep) -> [OutlinePath] {
        switch step {
        case .contour:
            return [
                ellipse(center: [0, 0.88], rx: 0.55, ry: 0.12),                 // top of forehead
                ellipse(center: [0, -0.92], rx: 0.20, ry: 0.07)                 // chin
            ]
            + pair { s in ellipse(center: [0.85 * s, 0.60], rx: 0.10, ry: 0.22) }                       // temples
            + pair { s in ellipse(center: [0.70 * s, -0.30], rx: 0.30, ry: 0.07, rotation: 0.5 * s) }   // cheek hollows

        case .blush:
            return pair { s in ellipse(center: [0.60 * s, -0.02], rx: 0.28, ry: 0.16, rotation: 0.35 * s) }

        case .highlight:
            return [
                ellipse(center: [0, 0.40], rx: 0.08, ry: 0.17)                  // nose bridge
            ]
            + pair { s in ellipse(center: [0.42 * s, 0.15], rx: 0.26, ry: 0.07, rotation: -0.15 * s) }  // under eyes
        }
    }

    // MARK: - Helpers

    /// Builds the left (-1) and right (+1) version of a symmetric shape.
    private static func pair(_ make: (Float) -> OutlinePath) -> [OutlinePath] {
        [make(-1), make(1)]
    }

    static func ellipse(center: SIMD2<Float>,
                        rx: Float,
                        ry: Float,
                        rotation: Float = 0,
                        segments: Int = 72) -> OutlinePath {
        let c = cos(rotation), s = sin(rotation)
        let pts = (0..<segments).map { i -> SIMD2<Float> in
            let t = Float(i) / Float(segments) * 2 * .pi
            let x = rx * cos(t), y = ry * sin(t)
            return center + SIMD2<Float>(x * c - y * s, x * s + y * c)
        }
        return OutlinePath(points: pts)
    }

    /// Walks along a CLOSED polyline and drops a point every `spacing` (same unit as the points).
    /// This is what turns a solid outline into dots.
    static func resample(_ points: [SIMD2<Float>], spacing: Float) -> [SIMD2<Float>] {
        guard points.count > 1, spacing > 0 else { return points }
        var result: [SIMD2<Float>] = []
        var d: Float = 0
        for i in 0..<points.count {
            let a = points[i]
            let b = points[(i + 1) % points.count]
            let length = simd_distance(a, b)
            while d < length {
                result.append(a + (b - a) * (d / length))
                d += spacing
            }
            d -= length
        }
        return result
    }
}
