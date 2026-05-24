import SwiftUI

struct AppearanceSettingsSection: View {
    @AppStorage("dailyquest.appearanceMode") private var modeRaw = AppearanceMode.system.rawValue

    private var selection: AppearanceMode {
        AppearanceMode(rawValue: modeRaw) ?? .system
    }

    var body: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 14) {
                Label("外观", systemImage: "circle.lefthalf.filled")
                    .font(AppTheme.caption())
                    .foregroundStyle(AppTheme.mainAccent)

                Text("浅色、深色或跟随系统显示设置。")
                    .font(AppTheme.caption(12))
                    .foregroundStyle(AppTheme.inkMuted)

                Picker("外观模式", selection: $modeRaw) {
                    ForEach(AppearanceMode.allCases) { mode in
                        Text(mode.title).tag(mode.rawValue)
                    }
                }
                .pickerStyle(.segmented)
            }
        }
        .onChange(of: modeRaw) { _, newValue in
            if let mode = AppearanceMode(rawValue: newValue) {
                AppearanceSettings.save(mode)
            }
        }
    }
}
