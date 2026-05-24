import SwiftUI

/// 「清晨 / 夜间 · 液态玻璃」— 通过 `AppTheme.setActive` 切换色板
enum AppTheme {
    private(set) static var active: ThemePalette = .light

    static func setActive(colorScheme: ColorScheme) {
        active = colorScheme == .dark ? .dark : .light
    }

    static func palette(for colorScheme: ColorScheme) -> ThemePalette {
        colorScheme == .dark ? .dark : .light
    }

    // MARK: - Forwarding（全 App 通过 active 取色）

    static var ink: Color { active.ink }
    static var inkMuted: Color { active.inkMuted }
    static var mainAccent: Color { active.mainAccent }
    static var sideAccent: Color { active.sideAccent }
    static var glassTint: Color { active.glassTint }
    static var glassEdge: Color { active.glassEdge }
    static var dawnBackground: LinearGradient { active.dawnBackground }
    static var mainGradient: LinearGradient { active.mainGradient }
    static var glassSpecular: LinearGradient { active.glassSpecular }
    static var glassBorder: LinearGradient { active.glassBorder }

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
}

// MARK: - Background

struct DawnBackground: View {
    @Environment(\.colorScheme) private var colorScheme
    @State private var drift = false

    private var palette: ThemePalette {
        AppTheme.palette(for: colorScheme)
    }

    var body: some View {
        ZStack {
            palette.dawnBackground
                .ignoresSafeArea()

            liquidOrb(
                colors: [palette.mainAccent.opacity(colorScheme == .dark ? 0.22 : 0.28), .clear],
                size: 340,
                blur: 42,
                offset: drift ? CGSize(width: 130, height: -300) : CGSize(width: 100, height: -270)
            )

            liquidOrb(
                colors: [palette.sideAccent.opacity(colorScheme == .dark ? 0.18 : 0.22), .clear],
                size: 300,
                blur: 38,
                offset: drift ? CGSize(width: -150, height: 340) : CGSize(width: -120, height: 300)
            )

            liquidOrb(
                colors: [palette.orbHighlight, .clear],
                size: 200,
                blur: 28,
                offset: CGSize(width: -60, height: -120)
            )

            Rectangle()
                .fill(palette.noiseOverlay)
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
    @Environment(\.colorScheme) private var colorScheme
    var cornerRadius: CGFloat = 24
    var tint: Color?

    private var palette: ThemePalette {
        AppTheme.palette(for: colorScheme)
    }

    var body: some View {
        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
            .fill(.ultraThinMaterial)
            .background {
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(tint ?? palette.glassTint)
            }
            .overlay {
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(palette.glassSpecular)
                    .blendMode(.overlay)
            }
            .overlay {
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .strokeBorder(palette.glassBorder, lineWidth: 1.2)
            }
            .shadow(color: palette.mainAccent.opacity(colorScheme == .dark ? 0.12 : 0.08), radius: 20, y: 12)
            .shadow(color: palette.ink.opacity(colorScheme == .dark ? 0.2 : 0.04), radius: 8, y: 4)
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
    @Environment(\.colorScheme) private var colorScheme
    let title: String
    let icon: String?
    let action: () -> Void

    init(_ title: String, icon: String? = nil, action: @escaping () -> Void) {
        self.title = title
        self.icon = icon
        self.action = action
    }

    private var palette: ThemePalette {
        AppTheme.palette(for: colorScheme)
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
            .shadow(color: .black.opacity(0.2), radius: 2, y: 1)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 17)
            .background {
                ZStack {
                    Capsule(style: .continuous)
                        .fill(palette.mainGradient)

                    Capsule(style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: [.white.opacity(0.4), .clear],
                                startPoint: .top,
                                endPoint: .center
                            )
                        )
                        .blendMode(.overlay)

                    Capsule(style: .continuous)
                        .strokeBorder(
                            LinearGradient(
                                colors: [.white.opacity(0.55), .white.opacity(0.15)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1
                        )
                }
                .shadow(color: palette.mainAccent.opacity(0.45), radius: 16, y: 8)
            }
        }
        .buttonStyle(LiquidPressStyle())
    }
}

struct SecondaryGlassButton: View {
    @Environment(\.colorScheme) private var colorScheme
    let title: String
    let action: () -> Void

    private var palette: ThemePalette {
        AppTheme.palette(for: colorScheme)
    }

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(AppTheme.caption())
                .foregroundStyle(palette.inkMuted)
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background {
                    Capsule(style: .continuous)
                        .fill(.ultraThinMaterial)
                        .overlay {
                            Capsule(style: .continuous)
                                .strokeBorder(palette.glassEdge.opacity(0.5), lineWidth: 1)
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

// MARK: - Appearance sync

struct AppearanceModifier: ViewModifier {
    @AppStorage("dailyquest.appearanceMode") private var modeRaw = AppearanceMode.system.rawValue
    @Environment(\.colorScheme) private var systemScheme

    private var mode: AppearanceMode {
        AppearanceMode(rawValue: modeRaw) ?? .system
    }

    private var resolvedScheme: ColorScheme {
        mode.resolved(system: systemScheme)
    }

    func body(content: Content) -> some View {
        content
            .preferredColorScheme(mode.preferredColorScheme)
            .onAppear { AppTheme.setActive(colorScheme: resolvedScheme) }
            .onChange(of: modeRaw) { _, _ in
                let m = AppearanceMode(rawValue: modeRaw) ?? .system
                AppTheme.setActive(colorScheme: m.resolved(system: systemScheme))
            }
            .onChange(of: systemScheme) { _, newScheme in
                let m = AppearanceMode(rawValue: modeRaw) ?? .system
                if m == .system {
                    AppTheme.setActive(colorScheme: newScheme)
                }
            }
    }
}

extension View {
    func dailyQuestAppearance() -> some View {
        modifier(AppearanceModifier())
    }
}
