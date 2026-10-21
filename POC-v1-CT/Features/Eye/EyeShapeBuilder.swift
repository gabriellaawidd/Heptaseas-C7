import ARKit

/// Parameter ketebalan shape di sekeliling bukaan mata (meter).
struct EyeShapeSpec {
    let base: Float    // ketebalan minimum (sisi bawah & sudut dalam)
    let top: Float     // tambahan ke arah kelopak atas
    let outer: Float   // tambahan ke arah sudut luar
    let tail: Float    // "ekor" runcing ke arah luar (bentuk no. 1 di gambar referensi)
}

enum EyeShapeBuilder {
    static let samples = 64

    static func spec(for step: MakeupStep) -> EyeShapeSpec {
        switch step {
        case .baseLight: return .init(base: 0.0020, top: 0.0090, outer: 0.0040, tail: 0.0070) // area luas
        case .darkShade: return .init(base: 0.0012, top: 0.0035, outer: 0.0030, tail: 0.0040) // dekat bulu mata
        }
    }

    /// Posisi layar pusat mata (tanpa flip) - dipakai untuk mendeteksi mata mana yang ada di kanan layar.
    static func rawCenter(anchor: ARFaceAnchor, side: EyeSide, camera: ARCamera, viewport: CGSize) -> CGPoint {
        let t = (side == .right ? anchor.rightEyeTransform : anchor.leftEyeTransform).columns.3
        let w = anchor.transform * t
        return camera.projectPoint(SIMD3<Float>(w.x, w.y, w.z),
                                   orientation: .portrait,
                                   viewportSize: viewport)
    }

    /// Membangun shape 3D yang menempel di permukaan mesh wajah, lalu memproyeksikannya ke layar.
    static func build(anchor: ARFaceAnchor,
                      side: EyeSide,
                      step: MakeupStep,
                      camera: ARCamera,
                      viewport: CGSize,
                      flipX: Bool) -> (overlay: EyeOverlay, center: CGPoint)? {

        let eye = (side == .right ? anchor.rightEyeTransform : anchor.leftEyeTransform).columns.3
        let cx = eye.x, cy = eye.y, cz = eye.z
        let outerSign: Float = cx >= 0 ? 1 : -1   // arah ke pelipis (menjauh dari hidung)

        // Vertex mesh di sekitar mata (koordinat lokal wajah)
        let near = anchor.geometry.vertices.filter {
            abs($0.x - cx) < 0.035 && abs($0.y - cy) < 0.030 && $0.z > cz
        }
        guard near.count >= 4 else { return nil }

        // Bukaan mata mengecil saat berkedip
        let blinkKey: ARFaceAnchor.BlendShapeLocation = side == .right ? .eyeBlinkRight : .eyeBlinkLeft
        let blink = anchor.blendShapes[blinkKey]?.floatValue ?? 0
        let ax: Float = 0.0135
        let ay: Float = 0.0065 * (1 - blink) + 0.0006

        let sp = spec(for: step)

        func project(_ x: Float, _ y: Float) -> CGPoint {
            let z = surfaceZ(x: x, y: y, near: near) + 0.0008   // sedikit di atas kulit
            let w = anchor.transform * SIMD4<Float>(x, y, z, 1)
            var p = camera.projectPoint(SIMD3<Float>(w.x, w.y, w.z),
                                        orientation: .portrait,
                                        viewportSize: viewport)
            if flipX { p.x = viewport.width - p.x }
            return p
        }

        var outerPts: [CGPoint] = []
        var innerPts: [CGPoint] = []
        outerPts.reserveCapacity(samples)
        innerPts.reserveCapacity(samples)

        for i in 0..<samples {
            let theta = Float(i) / Float(samples) * 2 * .pi
            let c = cos(theta), s = sin(theta)

            // (u, v): u positif = ke arah pelipis, v positif = ke atas
            let iu = ax * c, iv = ay * s
            let thick = sp.base + sp.top * max(0, s) + sp.outer * max(0, c) * max(0, c)
            let ou = iu + c * thick + sp.tail * powf(max(0, c), 8)
            let ov = iv + s * thick

            innerPts.append(project(cx + outerSign * iu, cy + iv))
            outerPts.append(project(cx + outerSign * ou, cy + ov))
        }

        let center = project(cx, cy)
        return (EyeOverlay(side: side, step: step, outer: outerPts, inner: innerPts), center)
    }

    /// Interpolasi tinggi permukaan (z) dari 4 vertex terdekat (inverse distance weighting).
    private static func surfaceZ(x: Float, y: Float, near: [SIMD3<Float>]) -> Float {
        let nearest = near
            .map { v -> (Float, Float) in
                let dx = v.x - x, dy = v.y - y
                return (dx * dx + dy * dy, v.z)
            }
            .sorted { $0.0 < $1.0 }
            .prefix(4)
        var sw: Float = 0, sz: Float = 0
        for (d, z) in nearest {
            let w = 1 / (d + 1e-7)
            sw += w
            sz += w * z
        }
        return sz / sw
    }
}
