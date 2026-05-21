import SwiftUI

/// 「清晨任务 · 液态玻璃」— 晨光暖色 + 流动半透明玻璃层
enum AppTheme {
    // MARK: - Dawn palette
    static let dawnTop = Color(red: 0.97, green: 0.93, blue: 0.86)
    static let dawnMid = Color(red: 0.94, green: 0.96, blue: 0.99)
    static let dawnBottom = Color(red: 0.88, green: 0.94, blue: 0.98)
    static let ink = Color(red: 0.10, green: 0.12, blue: 0.18)
    static let inkMuted = Color(red: 0.42, green: 0.46, blue: 0.54)
    static let mainAccent = Color(red: 0.94, green: 0.56, blue: 0.20)
    static let sideAccent = Color(red: 0.26, green: 0.64, blue: 0.60)
    static let glassTint = Color.white.opacity(0.38)
    static let glassHighlight = Color.white.opacity(0.85)
    static let glassEdge = Color.white.opacity(0.55)

    // MARK: - Typography
    static func display(_ size: CGFloat = 28) -> Font {
        .system(size: size, weight: .bold, design: .rounded)
    }

    static func title(_ size: CGFloat = 20) -> Font {
        .system(size: size, weight: .semibold, design: .rounded)
    }

    static func body(_ size: CGFloat = 16) -> Font {
        .system(size: size, weight: .regular, design: .rounded)
    }

    static func caption(_ size: CGFloat = 13) -> Font {
        .system(size: size, weight: .medium, design: .rounded)
    }

    // MARK: - Gradients
    static var dawnBackground: LinearGradient {
        LinearGradient(
            colors: [dawnTop, dawnMid, dawnBottom],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    static var mainGradient: LinearGradient {
        LinearGradient(
            colors: [
                Color(red: 1.0, green: 0.78, blue: 0.42),
                mainAccent,
                Color(red: 0.88, green: 0.45, blue: 0.15)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    static var glassSpecular: LinearGradient {
        LinearGradient(
            colors: [
                glassHighlight,
                Color.white.opacity(0.25),
                Color.clear
            ],
            startPoint: .topLeading,
            endPoint: .center
        )
    }

    static var glassBorder: LinearGradient {
        LinearGradient(
            colors: [
                Color.white.opacity(0.95),
                Color.white.opacity(0.35),
                Color.white.opacity(0.15),
                Color.white.opacity(0.45)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
}

// MARK: - Liquid glass background

struct DawnBackground: View {
    @State private var drift = false

    var body: some View {
        ZStack {
            AppTheme.dawnBackground
                .ignoresSafeArea()

            // 液态光斑 — 模拟玻璃后的流动晨光
            liquidOrb(
                colors: [AppTheme.mainAccent.opacity(0.28), .clear],
                size: 340,
                blur: 42,
                offset: drift ? CGSize(width: 130, height: -300) : CGSize(width: 100, height: -270)
            )

            liquidOrb(
                colors: [AppTheme.sideAccent.opacity(0.22), .clear],
                size: 300,
                blur: 38,
                offset: drift ? CGSize(width: -150, height: 340) : CGSize(width: -120, height: 300)
            )

            liquidOrb(
                colors: [Color.white.opacity(0.35), .clear],
                size: 200,
                blur: 28,
                offset: CGSize(width: -60, height: -120)
            )

            // 细粒度噪点质感（极淡）
            Rectangle()
                .fill(.white.opacity(0.03))
                .ignoresSafeArea()
                .blendMode(.overlay)
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 8).repeatForever(autoreverses: true)) {
                drift.toggle()
            }
        }
    }

    private func liquidOrb(
        colors: [Color],
        size: CGFloat,
        blur: CGFloat,
        offset: CGSize
    ) -> some View {
        Circle()
            .fill(RadialGradient(colors: colors, center: .center, startRadius: 8, endRadius: size * 0.55))
            .frame(width: size, height: size)
            .blur(radius: blur)
            .offset(offset)
    }
}

// MARK: - Liquid glass surface

struct LiquidGlassSurface: View {
    var cornerRadius: CGFloat = 24
    var tint: Color = AppTheme.glassTint

    var body: some View {
        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
            .fill(.ultraThinMaterial)
            .background {
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(tint)
            }
            .overlay {
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(AppTheme.glassSpecular)
                    .blendMode(.overlay)
            }
            .overlay {
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .strokeBorder(AppTheme.glassBorder, lineWidth: 1.2)
            }
            .shadow(color: AppTheme.mainAccent.opacity(0.08), radius: 20, y: 12)
            .shadow(color: AppTheme.ink.opacity(0.04), radius: 8, y: 4)
    }
}

struct GlassCard<Content: View>: View {
    let cornerRadius: CGFloat
    let content: Content

    init(cornerRadius: CGFloat = 24, @ViewBuilder content: () -> Content) {
        self.cornerRadius = cornerRadius
        self.content = content()
    }

    var body: some View {
        content
            .padding(18)
            .background {
                LiquidGlassSurface(cornerRadius: cornerRadius)
            }
    }
}

struct PrimaryButton: View {
    let title: String
    let icon: String?
    let action: () -> Void

    init(_ title: String, icon: String? = nil, action: @escaping () -> Void) {
        self.title = title
        self.icon = icon
        self.action = action
    }

    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                if let icon {
                    Image(systemName: icon)
                }
                Text(title)
                    .font(AppTheme.title(17))
            }
            .foregroundStyle(.white)
            .shadow(color: .black.opacity(0.12), radius: 2, y: 1)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 17)
            .background {
                ZStack {
                    Capsule(style: .continuous)
                        .fill(AppTheme.mainGradient)

                    Capsule(style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: [.white.opacity(0.45), .clear],
                                startPoint: .top,
                                endPoint: .center
                            )
                        )
                        .blendMode(.overlay)

                    Capsule(style: .continuous)
                        .strokeBorder(
                            LinearGradient(
                                colors: [.white.opacity(0.7), .white.opacity(0.2)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1
                        )
                }
                .shadow(color: AppTheme.mainAccent.opacity(0.4), radius: 16, y: 8)
            }
        }
        .buttonStyle(LiquidPressStyle())
    }
}

struct SecondaryGlassButton: View {
    let title: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(AppTheme.caption())
                .foregroundStyle(AppTheme.inkMuted)
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background {
                    Capsule(style: .continuous)
                        .fill(.ultraThinMaterial)
                        .overlay {
                            Capsule(style: .continuous)
                                .strokeBorder(AppTheme.glassEdge.opacity(0.5), lineWidth: 1)
                        }
                }
        }
        .buttonStyle(LiquidPressStyle())
    }
}

struct ScreenHeader: View {
    let title: String
    let subtitle: String?

    init(_ title: String, subtitle: String? = nil) {
        self.title = title
        self.subtitle = subtitle
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(AppTheme.display(26))
                .foregroundStyle(AppTheme.ink)
            if let subtitle {
                Text(subtitle)
                    .font(AppTheme.body(14))
                    .foregroundStyle(AppTheme.inkMuted)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

/// 液态玻璃面板（弹层、大卡片）
struct LiquidGlassPanel<Content: View>: View {
    let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        content
            .padding(28)
            .background {
                LiquidGlassSurface(cornerRadius: 32)
            }
    }
}

// MARK: - Interaction

struct LiquidPressStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
            .opacity(configuration.isPressed ? 0.92 : 1)
            .animation(.spring(response: 0.28, dampingFraction: 0.7), value: configuration.isPressed)
    }
}
