import SwiftUI
import SwiftData

/// 主线 + 支线录入；Release 仅 AI 领取，Debug 可选默认阶段。
struct DailyQuestInputView: View {
    let title: String
    let subtitle: String
    var showFlowHints: Bool = false
    var triviaTitle: String?
    var triviaYear: Int?
    let onCompleted: () -> Void

    @Environment(\.modelContext) private var context

    @State private var mainText = ""
    @State private var sideTexts: [String] = []
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var showQuestHint = false
    @State private var reminderTime = ReminderSettings.date
    @State private var showReminderCard = false
    @State private var previewDesign: MedalDesign?
    @State private var awaitingMedalConfirmation = false
    @State private var savedMainSummary = ""
    @State private var savedStageCount = 0

    private let repository: DailyPlanRepository = LocalDailyPlanRepository()
    private let llm: TaskBreakdownProviding = BackendBreakdownClient()

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                if awaitingMedalConfirmation, let previewDesign {
                    medalConfirmationView(design: previewDesign)
                } else {
                    questInputForm
                }
            }
            .padding(20)
        }
        .onAppear {
            if showFlowHints {
                showQuestHint = !LightPromptStore.hasSeen(.questPage)
                showReminderCard = !ReminderSettings.isConfigured
            }
        }
    }

    @ViewBuilder
    private var questInputForm: some View {
        ScreenHeader(title, subtitle: subtitle)

        if showFlowHints, showQuestHint {
            LightPromptBanner(
                message: TutorialContent.lightPromptQuestPage,
                onDismiss: dismissQuestHint
            )
        }

        if showFlowHints, showReminderCard {
            reminderCard
        }

        mainTaskCard
        sideTasksCard

        if let errorMessage {
            Text(errorMessage)
                .font(AppTheme.caption(12))
                .foregroundStyle(.red)
                .padding(.horizontal, 4)
        }

        PrimaryButton(isLoading ? "正在拆解…" : "领取任务", icon: "flag.fill") {
            guard !isLoading else { return }
            isLoading = true
            Task { await submit(useLLM: true) }
        }
        .disabled(mainText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isLoading)
        .overlay {
            if isLoading {
                ProgressView().tint(.white)
            }
        }

        #if DEBUG
        SecondaryGlassButton(title: "使用默认阶段（仅调试）") {
            guard !isLoading else { return }
            isLoading = true
            Task { await submit(useLLM: false) }
        }
        .disabled(mainText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isLoading)
        #endif
    }

    private func medalConfirmationView(design: MedalDesign) -> some View {
        VStack(spacing: 24) {
            ScreenHeader("确认今日奖牌", subtitle: "AI 已根据你的任务与今日大事生成专属勋章")

            GlassCard {
                VStack(spacing: 20) {
                    MedalView(status: .base, design: design, size: 120, animateHolographic: false)

                    VStack(spacing: 6) {
                        Text(design.title)
                            .font(AppTheme.title(20))
                            .foregroundStyle(AppTheme.ink)
                            .multilineTextAlignment(.center)
                        if let subtitle = design.subtitle {
                            Text(subtitle)
                                .font(AppTheme.body(14))
                                .foregroundStyle(AppTheme.inkMuted)
                                .multilineTextAlignment(.center)
                        }
                    }

                    if !savedMainSummary.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("主线已拆解为 \(savedStageCount) 个阶段")
                                .font(AppTheme.caption())
                                .foregroundStyle(AppTheme.mainAccent)
                            Text(savedMainSummary)
                                .font(AppTheme.body(14))
                                .foregroundStyle(AppTheme.ink)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
                .frame(maxWidth: .infinity)
            }

            PrimaryButton("确认，开始今日任务", icon: "checkmark.circle.fill") {
                confirmAndFinish()
            }

            SecondaryGlassButton(title: "返回修改任务") {
                awaitingMedalConfirmation = false
                previewDesign = nil
            }
        }
    }

    private var reminderCard: some View {
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

    private var mainTaskCard: some View {
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
    }

    private var sideTasksCard: some View {
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
    }

    private func saveReminder() async {
        let components = Calendar.current.dateComponents([.hour, .minute], from: reminderTime)
        let hour = components.hour ?? 8
        let minute = components.minute ?? 0
        do {
            try await NotificationService.shared.scheduleDailyReminder(hour: hour, minute: minute)
            ReminderSettings.save(hour: hour, minute: minute)
            ReminderSettings.markConfigured()
            LightPromptStore.markSeen(.reminderSetup)
            showReminderCard = false
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func submit(useLLM: Bool) async {
        let trimmedMain = mainText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedMain.isEmpty else {
            isLoading = false
            return
        }

        let trimmedSides = sideTexts
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }

        errorMessage = nil
        previewDesign = nil
        awaitingMedalConfirmation = false
        defer { isLoading = false }

        do {
            let plan: DailyPlan
            #if DEBUG
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
            #else
            let breakdown = try await llm.breakdown(mainTask: trimmedMain, sideTasks: trimmedSides)
            plan = try PlanBuilder.makePlan(
                date: .now,
                mainText: trimmedMain,
                sideTexts: trimmedSides,
                breakdown: breakdown
            )
            #endif

            try repository.save(plan, context: context)

            guard let persisted = try repository.plan(for: .now, in: context),
                  persisted.hasValidQuestContent else {
                throw DailyPlanSaveError.invalidContent
            }

            try await MedalDesignService.attachDesign(
                to: persisted,
                triviaTitle: triviaTitle,
                triviaYear: triviaYear,
                context: context
            )

            guard let design = MedalDesignService.design(for: persisted) else {
                throw MedalDesignError.network
            }

            savedMainSummary = persisted.mainTask?.rawText ?? trimmedMain
            savedStageCount = persisted.mainTask?.stages.count ?? 0
            previewDesign = design
            awaitingMedalConfirmation = true
        } catch {
            errorMessage = error.localizedDescription
            awaitingMedalConfirmation = false
        }
    }

    private func confirmAndFinish() {
        LightPromptStore.markSeen(.questPage)
        AppNotificationPoster.planDidChange()
        awaitingMedalConfirmation = false
        withAnimation(.easeInOut(duration: 0.35)) {
            onCompleted()
        }
    }

    private func dismissQuestHint() {
        LightPromptStore.markSeen(.questPage)
        showQuestHint = false
    }
}
