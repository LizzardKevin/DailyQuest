import SwiftUI
import UserNotifications

struct SettingsView: View {
    @State private var reminderTime = ReminderSettings.date
    @State private var notificationStatus: UNAuthorizationStatus = .notDetermined
    @State private var message: String?
    @State private var showReminderHint = false
    @State private var showTutorial = false

    var body: some View {
        NavigationStack {
            ZStack {
                DawnBackground()

                ScrollView {
                    VStack(spacing: 18) {
                        ScreenHeader("设置", subtitle: "提醒、任务与教程")

                        SettingsTodayQuestSection()

                        GlassCard {
                            VStack(alignment: .leading, spacing: 16) {
                                Label("早间提醒", systemImage: "bell")
                                    .font(AppTheme.caption())
                                    .foregroundStyle(AppTheme.mainAccent)

                                if showReminderHint {
                                    LightPromptBanner(
                                        message: TutorialContent.lightPromptReminderSetup,
                                        onDismiss: dismissReminderHint
                                    )
                                }

                                DatePicker("时间", selection: $reminderTime, displayedComponents: .hourAndMinute)
                                    .font(AppTheme.body())

                                Button("更新提醒") {
                                    Task { await updateReminder() }
                                }
                                .font(AppTheme.caption())
                                .foregroundStyle(AppTheme.mainAccent)

                                Divider()

                                HStack {
                                    Text("通知权限")
                                        .font(AppTheme.body(15))
                                    Spacer()
                                    Text(statusLabel)
                                        .font(AppTheme.caption())
                                        .foregroundStyle(AppTheme.inkMuted)
                                }

                                if notificationStatus == .denied {
                                    Button("打开系统设置") {
                                        if let url = URL(string: UIApplication.openSettingsURLString) {
                                            UIApplication.shared.open(url)
                                        }
                                    }
                                    .font(AppTheme.caption())
                                }
                            }
                        }

                        GlassCard {
                            VStack(alignment: .leading, spacing: 12) {
                                Label("使用教程", systemImage: "book")
                                    .font(AppTheme.caption())
                                    .foregroundStyle(AppTheme.sideAccent)

                                Text("简短说明 App 的每日流程、打卡与修改任务方式。")
                                    .font(AppTheme.body(14))
                                    .foregroundStyle(AppTheme.inkMuted)

                                Button(showTutorial ? "收起教程" : "展开教程") {
                                    withAnimation(.spring(response: 0.35)) {
                                        showTutorial.toggle()
                                    }
                                }
                                .font(AppTheme.caption())
                                .foregroundStyle(AppTheme.mainAccent)

                                if showTutorial {
                                    Text(TutorialContent.overview)
                                        .font(AppTheme.caption(12))
                                        .foregroundStyle(AppTheme.inkMuted)
                                        .lineSpacing(4)
                                        .textSelection(.enabled)
                                }
                            }
                        }

                        GlassCard {
                            VStack(alignment: .leading, spacing: 10) {
                                Label("账户与同步", systemImage: "icloud")
                                    .font(AppTheme.caption())
                                    .foregroundStyle(AppTheme.inkMuted)

                                Text("iCloud 同步与登录能力即将推出。")
                                    .font(AppTheme.body(14))
                                    .foregroundStyle(AppTheme.inkMuted)
                            }
                        }

                        GlassCard {
                            VStack(alignment: .leading, spacing: 10) {
                                Label("AI 服务", systemImage: "cloud")
                                    .font(AppTheme.caption())
                                    .foregroundStyle(AppTheme.sideAccent)

                                Text("任务拆解由云端安全代理，无需自行配置 API Key。")
                                    .font(AppTheme.body(14))
                                    .foregroundStyle(AppTheme.inkMuted)

                                if !APIConfig.isConfigured {
                                    Text("开发者：请在 APIConfig.swift 配置 Worker URL")
                                        .font(AppTheme.caption(11))
                                        .foregroundStyle(.orange)
                                } else {
                                    Text(APIConfig.baseURLString)
                                        .font(.system(size: 11, design: .monospaced))
                                        .foregroundStyle(AppTheme.inkMuted)
                                        .lineLimit(2)
                                }
                            }
                        }

                        GlassCard {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("隐私")
                                    .font(AppTheme.caption())
                                    .foregroundStyle(AppTheme.inkMuted)
                                Text("任务文本经 HTTPS 发送至 Cloudflare Worker，再转发至 DeepSeek 拆解。历史上的今天优先使用 Wikimedia 公开接口。")
                                    .font(AppTheme.caption(12))
                                    .foregroundStyle(AppTheme.inkMuted)
                                    .lineSpacing(3)
                            }
                        }

                        HStack {
                            Text("版本 1.2.0")
                            Spacer()
                            Text("任务日 04:00 换日")
                        }
                        .font(AppTheme.caption(11))
                        .foregroundStyle(AppTheme.inkMuted)
                        .padding(.horizontal, 4)

                        if let message {
                            Text(message)
                                .font(AppTheme.caption(12))
                                .foregroundStyle(message.contains("成功") ? .green : .red)
                        }
                    }
                    .padding(20)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("设置")
                        .font(AppTheme.title(18))
                        .foregroundStyle(AppTheme.ink)
                }
            }
            .task {
                notificationStatus = await NotificationService.shared.authorizationStatus()
            }
            .onAppear {
                showReminderHint = !ReminderSettings.isConfigured && !LightPromptStore.hasSeen(.reminderSetup)
            }
        }
    }

    private var statusLabel: String {
        switch notificationStatus {
        case .authorized, .provisional, .ephemeral: return "已授权"
        case .denied: return "已拒绝"
        case .notDetermined: return "未请求"
        @unknown default: return "未知"
        }
    }

    private func updateReminder() async {
        let components = Calendar.current.dateComponents([.hour, .minute], from: reminderTime)
        let hour = components.hour ?? 8
        let minute = components.minute ?? 0
        ReminderSettings.save(hour: hour, minute: minute)
        do {
            try await NotificationService.shared.scheduleDailyReminder(hour: hour, minute: minute)
            notificationStatus = await NotificationService.shared.authorizationStatus()
            message = "提醒时间更新成功"
            LightPromptStore.markSeen(.reminderSetup)
            showReminderHint = false
        } catch {
            message = error.localizedDescription
        }
    }

    private func dismissReminderHint() {
        LightPromptStore.markSeen(.reminderSetup)
        showReminderHint = false
    }
}
