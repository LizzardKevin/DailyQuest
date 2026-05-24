import SwiftUI
import SwiftData

struct SettingsTodayQuestSection: View {
    @Environment(\.modelContext) private var context

    @State private var mainText = ""
    @State private var sideTexts: [String] = []
    @State private var isLoading = false
    @State private var message: String?
    @State private var showEditor = false
    @State private var showModifyHint = false

    private let repository: DailyPlanRepository = LocalDailyPlanRepository()
    private let llm: TaskBreakdownProviding = BackendBreakdownClient()

    var body: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 14) {
                Label("今日任务", systemImage: "flag.fill")
                    .font(AppTheme.caption())
                    .foregroundStyle(AppTheme.mainAccent)

                if showModifyHint {
                    LightPromptBanner(
                        message: TutorialContent.lightPromptSettingsModify,
                        onDismiss: {
                            LightPromptStore.markSeen(.settingsModify)
                            showModifyHint = false
                        }
                    )
                }

                Text("修改将清空今日打卡进度，重新 AI 拆解，并重新生成当日奖牌设计。拆解每任务日最多 3 次。")
                    .font(AppTheme.caption(12))
                    .foregroundStyle(AppTheme.inkMuted)
                    .lineSpacing(3)

                if let plan = currentPlan {
                    summary(plan)
                    if showEditor {
                        editorFields
                    }
                    Button(showEditor ? "收起编辑" : "修改今日任务") {
                        withAnimation(.spring(response: 0.35)) {
                            showEditor.toggle()
                            if showEditor { preload(from: plan) }
                        }
                    }
                    .font(AppTheme.caption())
                    .foregroundStyle(AppTheme.mainAccent)

                    if showEditor {
                        PrimaryButton(isLoading ? "正在拆解…" : "保存并重新拆解", icon: "arrow.triangle.2.circlepath") {
                            guard !isLoading else { return }
                            isLoading = true
                            Task { await saveModifiedPlan(replacing: plan) }
                        }
                        .disabled(mainText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isLoading)
                    }
                } else {
                    Text("今日尚未领取任务。请完成「每日」流程或在下方先设置提醒。")
                        .font(AppTheme.body(14))
                        .foregroundStyle(AppTheme.inkMuted)
                }

                if let message {
                    Text(message)
                        .font(AppTheme.caption(12))
                        .foregroundStyle(message.contains("成功") ? .green : .red)
                }
            }
        }
        .onAppear {
            showModifyHint = !LightPromptStore.hasSeen(.settingsModify)
        }
    }

    @ViewBuilder
    private func summary(_ plan: DailyPlan) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            if let main = plan.mainTask {
                Text("主线：\(main.rawText)")
                    .font(AppTheme.body(14))
            }
            ForEach(plan.sideTasks, id: \.persistentModelID) { side in
                Text("支线：\(side.rawText)")
                    .font(AppTheme.body(14))
            }
            Text("整体进度 \(Int(plan.overallProgress * 100))%")
                .font(AppTheme.caption(12))
                .foregroundStyle(AppTheme.inkMuted)
        }
        .foregroundStyle(AppTheme.ink)
    }

    private var editorFields: some View {
        VStack(alignment: .leading, spacing: 12) {
            TextField("主线任务", text: $mainText, axis: .vertical)
                .font(AppTheme.body())
                .lineLimit(2...4)

            ForEach(sideTexts.indices, id: \.self) { index in
                TextField("支线 \(index + 1)", text: $sideTexts[index])
            }

            if sideTexts.count < 2 {
                Button {
                    sideTexts.append("")
                } label: {
                    Label("添加支线", systemImage: "plus")
                        .font(AppTheme.caption())
                }
            }
        }
    }

    private var currentPlan: DailyPlan? {
        try? repository.plan(for: .now, in: context)
    }

    private func preload(from plan: DailyPlan) {
        mainText = plan.mainTask?.rawText ?? ""
        sideTexts = plan.sideTasks.map(\.rawText)
        if sideTexts.isEmpty { sideTexts = [] }
    }

    private func saveModifiedPlan(replacing _: DailyPlan) async {
        let trimmedMain = mainText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedMain.isEmpty else {
            isLoading = false
            return
        }

        let trimmedSides = sideTexts
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }

        message = nil
        defer { isLoading = false }

        do {
            let breakdown = try await llm.breakdown(mainTask: trimmedMain, sideTasks: trimmedSides)
            let plan = try PlanBuilder.makePlan(
                date: .now,
                mainText: trimmedMain,
                sideTexts: trimmedSides,
                breakdown: breakdown
            )
            try repository.save(plan, context: context)
            try await MedalDesignService.attachDesign(to: plan, forceRegenerate: true, context: context)
            message = "今日任务已更新并重置进度"
            showEditor = false
            LightPromptStore.markSeen(.settingsModify)
            AppNotificationPoster.planDidChange()
        } catch {
            message = error.localizedDescription
            AppNotificationPoster.planDidChange()
        }
    }
}
