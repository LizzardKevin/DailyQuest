import SwiftUI

struct MedalView: View {
    let status: DayMedalStatus
    var size: CGFloat = 80
    var animateHolographic: Bool = true

    var body: some View {
        ZStack {
            // 液态玻璃外环
            Circle()
                .fill(.ultraThinMaterial)
                .frame(width: size * 1.18, height: size * 1.18)
                .overlay {
                    Circle()
                        .strokeBorder(AppTheme.glassBorder, lineWidth: 1.5)
                }
                .shadow(color: AppTheme.mainAccent.opacity(0.12), radius: size * 0.12, y: size * 0.06)

            Circle()
                .fill(
                    LinearGradient(
                        colors: [
                            Color(red: 0.92, green: 0.88, blue: 0.82),
                            Color(red: 0.65, green: 0.60, blue: 0.54),
                            Color(red: 0.88, green: 0.84, blue: 0.78)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
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

            Image(systemName: "seal.fill")
                .font(.system(size: size * 0.38))
                .foregroundStyle(
                    LinearGradient(
                        colors: [
                            Color(red: 1.0, green: 0.88, blue: 0.5),
                            AppTheme.mainAccent
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .shadow(color: AppTheme.mainAccent.opacity(0.3), radius: 4, y: 2)

            if status == .holographic {
                HolographicOverlay(size: size, animate: animateHolographic)
            }
        }
        .opacity(status == .none ? 0.35 : 1)
    }
}

struct MedalBadge: View {
    let status: DayMedalStatus
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
                Circle()
                    .fill(AppTheme.inkMuted.opacity(0.38))
                    .frame(width: 10, height: 10)
            case .base, .holographic:
                MedalView(status: status, size: size, animateHolographic: status == .holographic)
            }
        }
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
