import SwiftUI
import SwiftData

struct QuestIntakeView: View {
    let onCompleted: () -> Void

    @Environment(\.modelContext) private var context

    @State private var mainText = ""
    @State private var sideTexts: [String] = []
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var useManualFallback = false
    @State private var showQuestHint = false
    @State private var reminderTime = ReminderSettings.date
    @State private var showReminderCard = false

    private let repository: DailyPlanRepository = LocalDailyPlanRepository()
    private let llm: TaskBreakdownProviding = BackendBreakdownClient()

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                ScreenHeader(
                    "每日目标",
                    subtitle: "一条主线，最多两条支线"
                )

                if showQuestHint {
                    LightPromptBanner(
                        message: TutorialContent.lightPromptQuestPage,
                        onDismiss: dismissQuestHint
                    )
                }

                if showReminderCard {
                    GlassCard {
                        VStack(alignment: .leading, spacing: 12) {
                            Label("每日提醒", systemImage: "bell")
                                .font(AppTheme.caption())
                                .foregroundStyle(AppTheme.mainAccent)
                            Text(TutorialContent.lightPromptReminderSetup)
                                .font(AppTheme.caption(12))
                                .foregroundStyle(AppTheme.inkMuted)
                            DatePicker("提醒时间", selection: $reminderTime, displayedComponents: .hourAndMinute)
                            Button("保存提醒时间") {
                                Task { await saveReminder() }
                            }
                            .font(AppTheme.caption())
                            .foregroundStyle(AppTheme.mainAccent)
                        }
                    }
                }

                GlassCard {
                    VStack(alignment: .leading, spacing: 12) {
                        Label("主线", systemImage: "target")
                            .font(AppTheme.caption())
                            .foregroundStyle(AppTheme.mainAccent)

                        TextField("今天最重要的一件事", text: $mainText, axis: .vertical)
                            .font(AppTheme.body())
                            .lineLimit(2...5)
                    }
                }

                GlassCard {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Label("支线", systemImage: "leaf")
                                .font(AppTheme.caption())
                                .foregroundStyle(AppTheme.sideAccent)
                            Spacer()
                            Text("最多 2 条")
                                .font(AppTheme.caption(11))
                                .foregroundStyle(AppTheme.inkMuted)
                        }

                        ForEach(sideTexts.indices, id: \.self) { index in
                            TextField("支线 \(index + 1)", text: $sideTexts[index])
                                .font(AppTheme.body(15))
                        }

                        if sideTexts.count < 2 {
                            Button {
                                withAnimation(.spring(response: 0.35)) {
                                    sideTexts.append("")
                                }
                            } label: {
                                Label("添加支线", systemImage: "plus")
                                    .font(AppTheme.caption())
                                    .foregroundStyle(AppTheme.sideAccent)
                            }
                        }
                    }
                }

                if let errorMessage {
                    Text(errorMessage)
                        .font(AppTheme.caption(12))
                        .foregroundStyle(.red)
                        .padding(.horizontal, 4)
                }

                PrimaryButton(isLoading ? "正在拆解…" : "领取任务", icon: "flag.fill") {
                    Task { await submit(useLLM: true) }
                }
                .disabled(mainText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isLoading)
                .overlay {
                    if isLoading {
                        ProgressView().tint(.white)
                    }
                }

                if useManualFallback || errorMessage != nil {
                    SecondaryGlassButton(title: "使用默认阶段") {
                        Task { await submit(useLLM: false) }
                    }
                    .disabled(isLoading)
                }
            }
            .padding(20)
        }
        .onAppear {
            showQuestHint = !LightPromptStore.hasSeen(.questPage)
            showReminderCard = !ReminderSettings.isConfigured
        }
    }

    private func saveReminder() async {
        let components = Calendar.current.dateComponents([.hour, .minute], from: reminderTime)
        let hour = components.hour ?? 8
        let minute = components.minute ?? 0
        ReminderSettings.save(hour: hour, minute: minute)
        do {
            try await NotificationService.shared.scheduleDailyReminder(hour: hour, minute: minute)
            LightPromptStore.markSeen(.reminderSetup)
            showReminderCard = false
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func submit(useLLM: Bool) async {
        let trimmedMain = mainText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedMain.isEmpty else { return }

        let trimmedSides = sideTexts
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }

        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            let plan: DailyPlan
            if useLLM {
                let breakdown = try await llm.breakdown(mainTask: trimmedMain, sideTasks: trimmedSides)
                plan = try PlanBuilder.makePlan(
                    date: .now,
                    mainText: trimmedMain,
                    sideTexts: trimmedSides,
                    breakdown: breakdown
                )
            } else {
                plan = PlanBuilder.makeManualPlan(date: .now, mainText: trimmedMain, sideTexts: trimmedSides)
            }

            try repository.save(plan, context: context)
            LightPromptStore.markSeen(.questPage)
            AppNotificationPoster.planDidChange()
            onCompleted()
        } catch {
            errorMessage = error.localizedDescription
            useManualFallback = true
        }
    }

    private func dismissQuestHint() {
        LightPromptStore.markSeen(.questPage)
        showQuestHint = false
    }
}
