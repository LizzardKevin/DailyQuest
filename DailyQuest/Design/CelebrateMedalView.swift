import SwiftUI

struct CelebrateMedalView: View {
    let title: String
    let subtitle: String
    let status: DayMedalStatus
    var design: MedalDesign?
    let onDismiss: () -> Void

    @State private var scale: CGFloat = 0.2
    @State private var opacity: Double = 0
    @State private var ringScale: CGFloat = 0.5

    var body: some View {
        ZStack {
            // 磨砂玻璃遮罩
            Rectangle()
                .fill(.ultraThinMaterial)
                .ignoresSafeArea()
            AppTheme.active.celebrateScrim
                .ignoresSafeArea()

            LiquidGlassPanel {
                VStack(spacing: 24) {
                    ZStack {
                        Circle()
                            .strokeBorder(
                                AppTheme.glassBorder,
                                lineWidth: 2
                            )
                            .frame(width: 168, height: 168)
                            .scaleEffect(ringScale)
                            .opacity(0.8)

                        MedalView(status: status, design: design, size: 120)
                            .scaleEffect(scale)
                    }

                    VStack(spacing: 8) {
                        Text(title)
                            .font(AppTheme.display(24))
                            .foregroundStyle(AppTheme.ink)
                        Text(subtitle)
                            .font(AppTheme.body(14))
                            .foregroundStyle(AppTheme.inkMuted)
                            .multilineTextAlignment(.center)
                    }

                    PrimaryButton("收下勋章", icon: "checkmark") {
                        onDismiss()
                    }
                }
            }
            .padding(.horizontal, 28)
            .opacity(opacity)
        }
        .onAppear {
            withAnimation(.spring(response: 0.55, dampingFraction: 0.65)) {
                scale = 1
                opacity = 1
            }
            withAnimation(.easeOut(duration: 1.2)) {
                ringScale = 1.12
            }
        }
    }
}
