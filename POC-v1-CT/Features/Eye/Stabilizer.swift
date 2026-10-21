import CoreGraphics
import Foundation

/// One Euro Filter: low-pass adaptif. Gerakan pelan -> sangat halus (anti-getar),
/// gerakan cepat -> cutoff naik otomatis (tidak ketinggalan / lag).
struct OneEuroFilter {
    var minCutoff: Double      // makin kecil = makin halus (tapi lebih lambat)
    var beta: Double           // makin besar = makin responsif saat bergerak cepat
    var dCutoff: Double = 1.0
    private var xPrev: Double?
    private var dxPrev: Double = 0

    init(minCutoff: Double, beta: Double) {
        self.minCutoff = minCutoff
        self.beta = beta
    }

    mutating func reset() { xPrev = nil; dxPrev = 0 }

    mutating func filter(_ x: Double, dt: Double) -> Double {
        guard let xp = xPrev else { xPrev = x; return x }
        let dx = (x - xp) / dt
        let aD = alpha(dCutoff, dt)
        let dxHat = aD * dx + (1 - aD) * dxPrev
        dxPrev = dxHat
        let cutoff = minCutoff + beta * abs(dxHat)
        let a = alpha(cutoff, dt)
        let xHat = a * x + (1 - a) * xp
        xPrev = xHat
        return xHat
    }

    private func alpha(_ cutoff: Double, _ dt: Double) -> Double {
        let tau = 1.0 / (2.0 * Double.pi * cutoff)
        return 1.0 / (1.0 + tau / dt)
    }
}

struct Point2Filter {
    var x: OneEuroFilter
    var y: OneEuroFilter
    init(minCutoff: Double, beta: Double) {
        x = OneEuroFilter(minCutoff: minCutoff, beta: beta)
        y = OneEuroFilter(minCutoff: minCutoff, beta: beta)
    }
    mutating func reset() { x.reset(); y.reset() }
    mutating func filter(_ p: CGPoint, dt: Double) -> CGPoint {
        CGPoint(x: x.filter(Double(p.x), dt: dt), y: y.filter(Double(p.y), dt: dt))
    }
}

/// Menstabilkan posisi, jarak, dan roll wajah untuk crop panel atas.
final class EyeCropStabilizer {
    // ==== TUNING ====
    // Posisi (poin viewport):
    private var right  = Point2Filter(minCutoff: 1.0, beta: 0.02)
    private var left   = Point2Filter(minCutoff: 1.0, beta: 0.02)
    private var mid    = Point2Filter(minCutoff: 1.0, beta: 0.02)
    // Jarak mata (dalam log) -> ukuran mata di panel konsisten walau HP maju/mundur:
    private var dist   = OneEuroFilter(minCutoff: 0.6, beta: 1.5)
    // Roll wajah (radian):
    private var angle  = OneEuroFilter(minCutoff: 0.6, beta: 0.5)

    private var lastRawAngle: Double?
    private var unwrapped: Double = 0
    private var lastTime: TimeInterval?

    func reset() {
        right.reset(); left.reset(); mid.reset()
        dist.reset(); angle.reset()
        lastRawAngle = nil
        lastTime = nil
    }

    func update(rightEye r: CGPoint, leftEye l: CGPoint, time: TimeInterval) -> CropState {
        if let lt = lastTime, time - lt > 0.5 { reset() }   // wajah sempat hilang -> mulai bersih
        let dt = max(lastTime.map { time - $0 } ?? 1.0 / 30.0, 1.0 / 120.0)
        lastTime = time

        let sr = right.filter(r, dt: dt)
        let sl = left.filter(l, dt: dt)
        let sm = mid.filter(CGPoint(x: (r.x + l.x) / 2, y: (r.y + l.y) / 2), dt: dt)

        let d = max(hypot(r.x - l.x, r.y - l.y), 1)
        let sd = exp(dist.filter(log(Double(d)), dt: dt))

        // Roll: unwrap supaya melewati ±180° tidak "melompat"
        let raw = atan2(Double(r.y - l.y), Double(r.x - l.x))
        if let last = lastRawAngle {
            var delta = raw - last
            while delta > .pi { delta -= 2 * .pi }
            while delta < -.pi { delta += 2 * .pi }
            unwrapped += delta
        } else {
            unwrapped = raw
        }
        lastRawAngle = raw
        let sa = angle.filter(unwrapped, dt: dt)

        return CropState(centers: [.right: sr, .left: sl],
                         mid: sm,
                         eyeDistance: CGFloat(sd),
                         angle: CGFloat(sa))
    }
}
