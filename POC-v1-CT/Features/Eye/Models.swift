import SwiftUI

/// "R" = mata kanan USER. Setelah kalibrasi, mata R selalu tampil di sisi kanan layar (seperti cermin).
enum EyeSide: String, CaseIterable, Hashable {
    case right = "R"
    case left = "L"
}

enum DisplayMode {
    case bothEyes   // 👀 zoom, kedua mata terlihat + guide di kedua mata
    case singleEye  // 👁 satu mata (dipilih lewat toggle R/L)
}

enum MakeupStep: Int, CaseIterable {
    case baseLight, darkShade

    var number: Int { rawValue + 1 }
    static var total: Int { allCases.count }

    var instruction: String {
        switch self {
        case .baseLight: return "Apply full base colour (light)"
        case .darkShade: return "Apply darker shade colour"
        }
    }

    /// Warna titik-titik outline (tanpa fill; user yang mengisi dengan makeup).
    var guideColor: Color {
        switch self {
        case .baseLight: return .white
        case .darkShade: return Color(red: 1.0, green: 0.82, blue: 0.40)
        }
    }
}

/// Hasil proyeksi bentuk makeup satu mata ke koordinat viewport (poin).
struct EyeOverlay {
    let side: EyeSide
    let step: MakeupStep
    let outer: [CGPoint]
    let inner: [CGPoint]
}

/// State crop panel atas yang SUDAH distabilkan (koordinat viewport).
struct CropState {
    var centers: [EyeSide: CGPoint]  // pusat tiap mata
    var mid: CGPoint                 // titik tengah kedua mata
    var eyeDistance: CGFloat         // jarak antar mata (poin)
    var angle: CGFloat               // roll wajah (radian), garis mata R -> L terhadap horizontal
}

struct FaceFrame: @unchecked Sendable {
    let image: CGImage        // sudah dalam ruang viewport (1 piksel gambar = 1/scale poin)
    let overlays: [EyeOverlay]
    let crop: CropState?
}
