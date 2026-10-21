import SwiftUI

/// Menggambar frame kamera + (opsional) guide titik-titik.
/// `transform` memetakan koordinat viewport -> koordinat canvas:
///  - panel bawah: identity
///  - panel atas: translate ke pusat mata -> rotasi (anti-miring) -> zoom -> ke tengah panel
struct FaceCanvas: View {
    let frame: FaceFrame?
    let viewport: CGSize
    var transform: CGAffineTransform = .identity
    var zoom: CGFloat = 1          // supaya ukuran titik tetap konstan di layar
    var showGuide: Bool = true     // false = kamera polos tanpa AR

    var body: some View {
        Canvas { ctx, size in
            ctx.fill(Path(CGRect(origin: .zero, size: size)), with: .color(.black))
            guard let frame else { return }

            var c = ctx
            c.concatenate(transform)

            // Gambar sudah berada di ruang viewport -> langsung isi seluruh viewport
            c.draw(Image(decorative: frame.image, scale: 1), in: CGRect(origin: .zero, size: viewport))

            guard showGuide else { return }

            let dot = 2.6 / zoom
            let gap = 5.5 / zoom
            let dotted = StrokeStyle(lineWidth: dot, lineCap: .round, dash: [0.001, gap])
            let shadow = StrokeStyle(lineWidth: dot * 1.9, lineCap: .round, dash: [0.001, gap])

            for o in frame.overlays {
                var outer = Path(); outer.addLines(o.outer); outer.closeSubpath()
                var inner = Path(); inner.addLines(o.inner); inner.closeSubpath()

                for p in [outer, inner] {
                    c.stroke(p, with: .color(.black.opacity(0.35)), style: shadow)
                }
                for p in [outer, inner] {
                    c.stroke(p, with: .color(o.step.guideColor), style: dotted)
                }

                // Badge nomor step di ujung ekor
                guard let tip = o.outer.first, !o.inner.isEmpty else { continue }
                let cen = CGPoint(x: o.inner.map(\.x).reduce(0, +) / CGFloat(o.inner.count),
                                  y: o.inner.map(\.y).reduce(0, +) / CGFloat(o.inner.count))
                var dx = tip.x - cen.x, dy = tip.y - cen.y
                let len = max(hypot(dx, dy), 0.001)
                dx /= len; dy /= len
                let r = 6.5 / zoom
                let off = r + 3 / zoom
                let bc = CGPoint(x: tip.x + dx * off, y: tip.y + dy * off)
                c.fill(Path(ellipseIn: CGRect(x: bc.x - r, y: bc.y - r, width: 2 * r, height: 2 * r)),
                       with: .color(.white))
                c.draw(Text("\(o.step.number)")
                        .font(.system(size: 9 / zoom, weight: .bold))
                        .foregroundColor(.black),
                       at: bc)
            }
        }
    }
}
