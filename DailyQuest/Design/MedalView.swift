import SwiftUI

struct MedalView: View {
    let status: DayMedalStatus
    var design: MedalDesign?
    var size: CGFloat = 80
    var animateHolographic: Bool = true

    var body: some View {
        ZStack {
            Circle()
                .fill(.ultraThinMaterial)
                .frame(width: size * 1.18, height: size * 1.18)
                .overlay {
                    Circle()
                        .strokeBorder(AppTheme.glassBorder, lineWidth: 1.5)
                }
                .shadow(color: accentColor.opacity(0.12), radius: size * 0.12, y: size * 0.06)

            Circle()
                .fill(medalGradient)
                .frame(width: size, height: size)
                .overlay {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [.white.opacity(0.5), .clear],
                                startPoint: .topLeading,
                                endPoint: .center
                            )
                        )
                        .blendMode(.overlay)
                }

            Image(systemName: symbolName)
                .font(.system(size: size * 0.38))
                .foregroundStyle(iconGradient)
                .shadow(color: accentColor.opacity(0.3), radius: 4, y: 2)

            if status == .holographic {
                HolographicOverlay(size: size, animate: animateHolographic)
            }
        }
        .opacity(status == .none ? 0.35 : 1)
    }

    private var symbolName: String {
        let name = design?.visual.symbolName ?? "seal.fill"
        return MedalSymbolValidator.resolve(name)
    }

    private var accentColor: Color {
        design?.visual.palette.accent ?? AppTheme.mainAccent
    }

    private var medalGradient: LinearGradient {
        if let palette = design?.visual.palette {
            return LinearGradient(
                colors: [
                    palette.primary.opacity(0.95),
                    palette.secondary.opacity(0.85),
                    palette.accent.opacity(0.75)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
        let p = AppTheme.active
        return LinearGradient(
            colors: [p.medalFallbackTop, p.medalFallbackMid, p.medalFallbackBottom],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    private var iconGradient: LinearGradient {
        LinearGradient(
            colors: [accentColor.opacity(0.9), design?.visual.palette.primary ?? AppTheme.mainAccent],
            startPoint: .top,
            endPoint: .bottom
        )
    }
}

struct MedalBadge: View {
    let status: DayMedalStatus
    var design: MedalDesign?
    var size: CGFloat = 24

    var body: some View {
        Group {
            switch status {
            case .none:
                Circle()
                    .fill(.ultraThinMaterial)
                    .frame(width: 8, height: 8)
                    .overlay {
                        Circle().strokeBorder(Color.white.opacity(0.4), lineWidth: 0.5)
                    }
            case .inProgress:
                if let design {
                    MedalView(status: .base, design: design, size: size, animateHolographic: false)
                        .opacity(0.55)
                } else {
                    Circle()
                        .fill(AppTheme.inkMuted.opacity(0.38))
                        .frame(width: 10, height: 10)
                }
            case .base, .holographic:
                MedalView(status: status, design: design, size: size, animateHolographic: status == .holographic)
            }
        }
    }
}

enum MedalSymbolValidator {
    private static let allowed: Set<String> = [
        "seal.fill", "star.fill", "flame.fill", "leaf.fill", "bolt.fill",
        "moon.stars.fill", "sun.max.fill", "sparkles", "crown.fill", "flag.fill",
        "book.fill", "figure.walk", "heart.fill", "globe.americas.fill", "wand.and.stars",
        "trophy.fill", "medal.fill", "target", "checkmark.seal.fill", "lightbulb.fill"
    ]

    static func resolve(_ name: String) -> String {
        allowed.contains(name) ? name : "seal.fill"
    }
}

private struct HolographicOverlay: View {
    let size: CGFloat
    let animate: Bool
    @State private var rotation: Double = 0

    var body: some View {
        Circle()
            .strokeBorder(
                AngularGradient(
                    colors: [
                        AppTheme.sideAccent.opacity(0.9),
                        .cyan.opacity(0.8),
                        .purple.opacity(0.7),
                        .pink.opacity(0.8),
                        AppTheme.mainAccent,
                        .yellow.opacity(0.9),
                        AppTheme.sideAccent.opacity(0.9)
                    ],
                    center: .center
                ),
                lineWidth: max(2.5, size * 0.055)
            )
            .frame(width: size * 1.14, height: size * 1.14)
            .rotationEffect(.degrees(rotation))
            .blur(radius: 0.3)
            .blendMode(.plusLighter)
            .onAppear {
                guard animate else { return }
                withAnimation(.linear(duration: 6).repeatForever(autoreverses: false)) {
                    rotation = 360
                }
            }
    }
}

#Preview {
    HStack(spacing: 24) {
        MedalView(status: .base)
        MedalView(status: .holographic)
    }
    .padding(40)
    .background(DawnBackground())
}
