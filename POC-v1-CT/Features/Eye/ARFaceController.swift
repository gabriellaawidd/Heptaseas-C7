import ARKit
import CoreImage
import SwiftUI
import Combine
import Vision

/// Menjalankan ARSession (TrueDepth), merender frame kamera ke "ruang viewport",
/// menghitung guide makeup, dan menstabilkan crop panel atas.
final class ARFaceController: NSObject, ObservableObject, ARSessionDelegate {

    @Published private(set) var frame: FaceFrame?
    @Published private(set) var isFaceTracked = false

    static var isSupported: Bool { ARFaceTrackingConfiguration.isSupported }

    // MARK: Tuning
    /// Resolusi render gambar (piksel per poin). 3 = setara layar iPhone.
    private let imageScale: CGFloat = 3
    /// nil = AUTO (kalibrasi otomatis memakai Vision di beberapa frame awal).
    /// true / false = paksa gambar di-flip horizontal atau tidak (kalau guide masih tidak pas di mata).
    private let forceImageFlip: Bool? = nil

    private let session = ARSession()
    private let queue = DispatchQueue(label: "eyemakeup.ar.queue")
    private let ciContext = CIContext()
    private let lock = NSLock()
    private let stabilizer = EyeCropStabilizer()

    private var step: MakeupStep = .baseLight
    private var side: EyeSide = .right
    private var mode: DisplayMode = .singleEye
    private var viewport = CGSize(width: 390, height: 380)
    private var busy = false
    private var lastTimestamp: TimeInterval = 0
    private var frameCounter = 0


    // Hanya diakses dari queue AR:
    private var lockedProjFlip: Bool?   // true jika koordinat proyeksi perlu dibalik agar mata R di kanan layar
    private var imageFlip: Bool?        // hasil kalibrasi: apakah gambar perlu dibalik agar cocok dengan proyeksi
    private var calibAttempts = 0
    private var lastCrop: CropState?

    // MARK: Public API
    func start() {
        guard Self.isSupported else { return }
        queue.async { [weak self] in
            self?.lockedProjFlip = nil
            self?.imageFlip = nil
            self?.calibAttempts = 0
            self?.lastCrop = nil
            self?.stabilizer.reset()
        }
        session.delegate = self
        session.delegateQueue = queue
        let config = ARFaceTrackingConfiguration()
        config.maximumNumberOfTrackedFaces = 1
        session.run(config, options: [.resetTracking, .removeExistingAnchors])
    }

    func stop() { session.pause() }

    func update(step: MakeupStep, side: EyeSide, mode: DisplayMode) {
        lock.lock(); defer { lock.unlock() }
        self.step = step
        self.side = side
        self.mode = mode
    }

    func setViewport(_ size: CGSize) {
        lock.lock(); defer { lock.unlock() }
        viewport = size
    }

    // MARK: ARSessionDelegate
    func session(_ session: ARSession, didUpdate frame: ARFrame) {
        guard frame.timestamp - lastTimestamp >= 1.0 / 30.0 else { return }

        lock.lock()
        if busy { lock.unlock(); return }
        busy = true
        let step = self.step, mode = self.mode, viewport = self.viewport
        lock.unlock()
        lastTimestamp = frame.timestamp
        frameCounter += 1

        let W = viewport.width
        let anchor = frame.anchors.compactMap { $0 as? ARFaceAnchor }.first(where: { $0.isTracked })

        // 1) Posisi mata mentah + keputusan flip proyeksi (R harus di kanan layar, dikunci sekali
        //    saat wajah hampir tegak supaya tidak "loncat" ketika kepala dimiringkan).
        var rawR: CGPoint?, rawL: CGPoint?
        var flipP = lockedProjFlip ?? false
        if let anchor {
            let r = EyeShapeBuilder.rawCenter(anchor: anchor, side: .right, camera: frame.camera, viewport: viewport)
            let l = EyeShapeBuilder.rawCenter(anchor: anchor, side: .left, camera: frame.camera, viewport: viewport)
            rawR = r; rawL = l
            if lockedProjFlip == nil {
                let provisional = r.x < l.x
                let dist = max(hypot(r.x - l.x, r.y - l.y), 1)
                if abs(r.x - l.x) > 0.6 * dist { lockedProjFlip = provisional }
                flipP = provisional
            }
        }
        let projFlip = flipP
        func fx(_ p: CGPoint) -> CGPoint { projFlip ? CGPoint(x: W - p.x, y: p.y) : p }

        // 2) Gambar kamera dirender memakai displayTransform ARKit (satu ruang koordinat dengan proyeksi)
        let wantFlip = forceImageFlip ?? imageFlip ?? false
        guard let cg = makeViewportImage(from: frame, viewport: viewport, flip: wantFlip) else {
            finish(nil, tracked: false); return
        }

        // 3) Kalibrasi otomatis: cek dengan Vision apakah guide benar-benar jatuh di mata pada gambar.
        if forceImageFlip == nil, imageFlip == nil, calibAttempts < 60, frameCounter % 5 == 0,
           let r = rawR, let l = rawL {
            calibAttempts += 1
            if let v = Self.detectEyeCenters(in: cg, viewport: viewport) {
                let fr = fx(r), fl = fx(l)
                let mirroredV = v.map { CGPoint(x: W - $0.x, y: $0.y) }
                let e0 = Self.matchError([fr, fl], v)
                let e1 = Self.matchError([fr, fl], mirroredV)
                let eyeDist = max(hypot(fr.x - fl.x, fr.y - fl.y), 1)
                if abs(e0 - e1) > 0.3 * eyeDist {
                    imageFlip = e1 < e0
                }
            }
        }

        // 4) Overlay + crop yang distabilkan
        var overlays: [EyeOverlay] = []
        var tracked = false
        if let anchor, let r = rawR, let l = rawL {
            tracked = true
            let sides: [EyeSide] = (mode == .bothEyes) ? EyeSide.allCases : [self.side]
            for s in sides {
                if let res = EyeShapeBuilder.build(anchor: anchor, side: s, step: step,
                                                   camera: frame.camera, viewport: viewport,
                                                   flipX: projFlip) {
                    overlays.append(res.overlay)
                }
            }
            lastCrop = stabilizer.update(rightEye: fx(r), leftEye: fx(l), time: frame.timestamp)
        }
        finish(FaceFrame(image: cg, overlays: overlays, crop: lastCrop), tracked: tracked)
    }

    // MARK: Helpers
    private func finish(_ f: FaceFrame?, tracked: Bool) {
        DispatchQueue.main.async { [weak self] in
            guard let self else { return }
            self.frame = f
            self.isFaceTracked = tracked
            self.lock.lock(); self.busy = false; self.lock.unlock()
        }
    }

    /// Render frame kamera ke ruang viewport memakai displayTransform ARKit,
    /// sehingga gambar dan `camera.projectPoint` memakai koordinat yang sama.
    private func makeViewportImage(from frame: ARFrame, viewport: CGSize, flip: Bool) -> CGImage? {
        let ci = CIImage(cvPixelBuffer: frame.capturedImage)
        let iw = ci.extent.width, ih = ci.extent.height
        let wpx = (viewport.width * imageScale).rounded()
        let hpx = (viewport.height * imageScale).rounded()
        guard iw > 0, ih > 0, wpx > 0, hpx > 0 else { return nil }

        let display = frame.displayTransform(for: .portrait, viewportSize: viewport)
        var t = CGAffineTransform(a: 1 / iw, b: 0, c: 0, d: -1 / ih, tx: 0, ty: 1)      // piksel CI -> normalized (origin kiri-atas)
            .concatenating(display)                                                      // -> normalized viewport
            .concatenating(CGAffineTransform(a: wpx, b: 0, c: 0, d: -hpx, tx: 0, ty: hpx)) // -> piksel output (CI y-up)
        if flip { t = t.concatenating(CGAffineTransform(a: -1, b: 0, c: 0, d: 1, tx: wpx, ty: 0)) }

        let out = ci.transformed(by: t).cropped(to: CGRect(x: 0, y: 0, width: wpx, height: hpx))
        return ciContext.createCGImage(out, from: out.extent)
    }

    /// Pusat kedua mata menurut Vision, dalam koordinat viewport (poin).
    private static func detectEyeCenters(in image: CGImage, viewport: CGSize) -> [CGPoint]? {
        let request = VNDetectFaceLandmarksRequest()
        let handler = VNImageRequestHandler(cgImage: image, orientation: .up, options: [:])
        do { try handler.perform([request]) } catch { return nil }
        guard let obs = request.results?.first,
              let lm = obs.landmarks,
              let le = lm.leftEye, let re = lm.rightEye else { return nil }

        func center(_ region: VNFaceLandmarkRegion2D) -> CGPoint? {
            let pts = region.normalizedPoints
            guard !pts.isEmpty else { return nil }
            let n = CGFloat(pts.count)
            let mx = pts.map { $0.x }.reduce(0, +) / n
            let my = pts.map { $0.y }.reduce(0, +) / n
            let bb = obs.boundingBox
            let nx = bb.minX + mx * bb.width
            let ny = bb.minY + my * bb.height
            return CGPoint(x: nx * viewport.width, y: (1 - ny) * viewport.height)
        }
        guard let a = center(le), let b = center(re) else { return nil }
        return [a, b]
    }

    /// Total jarak antar pasangan titik setelah diurutkan berdasarkan x.
    private static func matchError(_ a: [CGPoint], _ b: [CGPoint]) -> CGFloat {
        let sa = a.sorted { $0.x < $1.x }, sb = b.sorted { $0.x < $1.x }
        return zip(sa, sb).reduce(0) { $0 + hypot($1.0.x - $1.1.x, $1.0.y - $1.1.y) }
    }
}
