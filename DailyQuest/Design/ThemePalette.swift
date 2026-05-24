import SwiftUI

struct ThemePalette {
    let dawnTop: Color
    let dawnMid: Color
    let dawnBottom: Color
    let ink: Color
    let inkMuted: Color
    let mainAccent: Color
    let sideAccent: Color
    let glassTint: Color
    let glassHighlight: Color
    let glassEdge: Color
    let orbHighlight: Color
    let noiseOverlay: Color
    let celebrateScrim: Color
    let tabBarBackground: Color
    let medalFallbackTop: Color
    let medalFallbackMid: Color
    let medalFallbackBottom: Color

    var dawnBackground: LinearGradient {
        LinearGradient(
            colors: [dawnTop, dawnMid, dawnBottom],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    var mainGradient: LinearGradient {
        LinearGradient(
            colors: mainGradientStops,
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    let mainGradientStops: [Color]

    var glassSpecular: LinearGradient {
        LinearGradient(
            colors: [glassHighlight, glassHighlight.opacity(0.3), .clear],
            startPoint: .topLeading,
            endPoint: .center
        )
    }

    var glassBorder: LinearGradient {
        LinearGradient(
            colors: glassBorderStops,
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    let glassBorderStops: [Color]

    static let light = ThemePalette(
        dawnTop: Color(red: 0.97, green: 0.93, blue: 0.86),
        dawnMid: Color(red: 0.94, green: 0.96, blue: 0.99),
        dawnBottom: Color(red: 0.88, green: 0.94, blue: 0.98),
        ink: Color(red: 0.10, green: 0.12, blue: 0.18),
        inkMuted: Color(red: 0.42, green: 0.46, blue: 0.54),
        mainAccent: Color(red: 0.94, green: 0.56, blue: 0.20),
        sideAccent: Color(red: 0.26, green: 0.64, blue: 0.60),
        glassTint: Color.white.opacity(0.38),
        glassHighlight: Color.white.opacity(0.85),
        glassEdge: Color.white.opacity(0.55),
        orbHighlight: Color.white.opacity(0.35),
        noiseOverlay: Color.white.opacity(0.03),
        celebrateScrim: Color.black.opacity(0.25),
        tabBarBackground: Color.white.opacity(0.55),
        medalFallbackTop: Color(red: 0.92, green: 0.88, blue: 0.82),
        medalFallbackMid: Color(red: 0.65, green: 0.60, blue: 0.54),
        medalFallbackBottom: Color(red: 0.88, green: 0.84, blue: 0.78),
        mainGradientStops: [
            Color(red: 1.0, green: 0.78, blue: 0.42),
            Color(red: 0.94, green: 0.56, blue: 0.20),
            Color(red: 0.88, green: 0.45, blue: 0.15)
        ],
        glassBorderStops: [
            Color.white.opacity(0.95),
            Color.white.opacity(0.35),
            Color.white.opacity(0.15),
            Color.white.opacity(0.45)
        ]
    )

    /// 夜间 · 液态玻璃 — 深空蓝紫 + 暖色光斑点缀
    static let dark = ThemePalette(
        dawnTop: Color(red: 0.07, green: 0.08, blue: 0.14),
        dawnMid: Color(red: 0.10, green: 0.11, blue: 0.20),
        dawnBottom: Color(red: 0.05, green: 0.07, blue: 0.12),
        ink: Color(red: 0.94, green: 0.95, blue: 0.97),
        inkMuted: Color(red: 0.58, green: 0.62, blue: 0.70),
        mainAccent: Color(red: 1.0, green: 0.62, blue: 0.28),
        sideAccent: Color(red: 0.38, green: 0.78, blue: 0.72),
        glassTint: Color.white.opacity(0.06),
        glassHighlight: Color.white.opacity(0.18),
        glassEdge: Color.white.opacity(0.22),
        orbHighlight: Color.white.opacity(0.12),
        noiseOverlay: Color.white.opacity(0.04),
        celebrateScrim: Color.black.opacity(0.55),
        tabBarBackground: Color(red: 0.08, green: 0.09, blue: 0.14).opacity(0.92),
        medalFallbackTop: Color(red: 0.28, green: 0.26, blue: 0.34),
        medalFallbackMid: Color(red: 0.18, green: 0.17, blue: 0.24),
        medalFallbackBottom: Color(red: 0.32, green: 0.28, blue: 0.22),
        mainGradientStops: [
            Color(red: 1.0, green: 0.72, blue: 0.38),
            Color(red: 1.0, green: 0.62, blue: 0.28),
            Color(red: 0.85, green: 0.48, blue: 0.18)
        ],
        glassBorderStops: [
            Color.white.opacity(0.35),
            Color.white.opacity(0.12),
            Color.white.opacity(0.06),
            Color.white.opacity(0.18)
        ]
    )
}
