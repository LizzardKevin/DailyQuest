import SwiftUI

struct MedalView: View {
    let status: DayMedalStatus
    var design: MedalDesign?
    var size: CGFloat = 80
    var animateHolographic: Bool = true

    private var visual: MedalVisualSpec? { design?.visual }
    private var ringElements: [MedalRingElement] { visual?.resolvedRingElements ?? [] }

    var body: some View {
        ZStack {
            Circle()
                .fill(.ultraThinMaterial)
                .frame(width: size * 1.22, height: size * 1.22)
                .overlay {
                    Circle()
                        .strokeBorder(AppTheme.glassBorder, lineWidth: 1.5)
                }
                .shadow(color: accentColor.opacity(0.14), radius: size * 0.1, y: size * 0.05)

            Circle()
                .strokeBorder(ringBandGradient, lineWidth: size * 0.07)
                .frame(width: size * 1.02, height: size * 1.02)

            ForEach(Array(ringElements.enumerated()), id: \.offset) { index, element in
                ringOrnament(element, index: index, total: ringElements.count)
            }

            Circle()
                .fill(centerFillColor)
                .frame(width: size * 0.64, height: size * 0.64)
                .overlay {
                    Circle()
                        .strokeBorder(Color.white.opacity(0.35), lineWidth: 1)
                }
                .shadow(color: .black.opacity(0.08), radius: 2, y: 1)

            Image(systemName: centerObjectSymbol)
                .font(.system(size: size * 0.3, weight: .semibold))
                .foregroundStyle(centerObjectGradient)
                .shadow(color: accentColor.opacity(0.25), radius: 3, y: 1)

            if status == .holographic {
                HolographicOverlay(size: size, animate: animateHolographic)
            }
        }
        .opacity(status == .none ? 0.35 : 1)
    }

    private func ringOrnament(_ element: MedalRingElement, index: Int, total: Int) -> some View {
        let angle = (Double(index) / Double(max(total, 1))) * 360 - 90
        let radius = size * 0.44
        let rad = angle * .pi / 180
        let x = cos(rad) * radius
        let y = sin(rad) * radius

        return ZStack {
            Circle()
                .fill(ornamentBackground)
                .frame(width: size * 0.16, height: size * 0.16)
            Image(systemName: MedalRingCatalog.symbol(for: element.kind))
                .font(.system(size: size * 0.075, weight: .semibold))
                .foregroundStyle(ornamentForeground)
        }
        .offset(x: x, y: y)
    }

    private var centerObjectSymbol: String {
        MedalSymbolValidator.resolve(visual?.centerObjectSymbol ?? "seal.fill")
    }

    private var centerFillColor: Color {
        visual?.centerFill ?? visual?.palette.primary ?? AppTheme.mainAccent
    }

    private var accentColor: Color {
        visual?.palette.accent ?? AppTheme.mainAccent
    }

    private var ornamentBackground: Color {
        visual?.palette.secondary.opacity(0.92) ?? AppTheme.sideAccent.opacity(0.85)
    }

    private var ornamentForeground: Color {
        visual?.palette.primary ?? AppTheme.mainAccent
    }

    private var ringBandGradient: LinearGradient {
        if let palette = visual?.palette {
            return LinearGradient(
                colors: [
                    palette.accent.opacity(0.95),
                    palette.primary.opacity(0.9),
                    palette.secondary.opacity(0.85),
                    palette.accent.opacity(0.95)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
        return LinearGradient(
            colors: [AppTheme.mainAccent, AppTheme.sideAccent],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    private var centerObjectGradient: LinearGradient {
        LinearGradient(
            colors: [
                Color.white.opacity(0.95),
                accentColor.opacity(0.85)
            ],
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
        "book.fill", "figure.walk", "figure.run", "heart.fill", "globe.americas.fill",
        "wand.and.stars", "trophy.fill", "medal.fill", "target", "checkmark.seal.fill",
        "lightbulb.fill", "pencil", "keyboard", "cup.and.saucer.fill", "fork.knife",
        "dumbbell.fill", "brain.head.profile", "music.note", "paintbrush.fill"
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
            .frame(width: size * 1.16, height: size * 1.16)
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
    let sample = MedalDesign(
        questDayKey: "2026-05-23",
        schemaVersion: 2,
        title: "林奈诞辰",
        subtitle: "探索今日",
        themeTags: ["nature"],
        visual: MedalVisualSpec(
            ringElements: [
                MedalRingElement(kind: "wheat"),
                MedalRingElement(kind: "vine"),
                MedalRingElement(kind: "pearl"),
                MedalRingElement(kind: "leaf"),
                MedalRingElement(kind: "bead"),
                MedalRingElement(kind: "star")
            ],
            centerFillHex: "#A3B18A",
            centerObjectSymbol: "leaf.fill",
            palette: MedalPalette(
                primaryHex: "#588157",
                secondaryHex: "#A3B18A",
                accentHex: "#3A5A40"
            )
        ),
        source: .ai,
        createdAt: .now
    )
    return HStack(spacing: 24) {
        MedalView(status: .base, design: sample)
        MedalView(status: .holographic, design: sample)
    }
    .padding(40)
    .background(DawnBackground())
}
