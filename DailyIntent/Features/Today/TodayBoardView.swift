import SwiftUI
import SwiftData

struct TodayBoardView: View {
    @Bindable var plan: DailyPlan
    let onPlanUpdated: () -> Void

    @Environment(\.modelContext) private var context
    @State private var celebrateTitle = ""
    @State private var celebrateSubtitle = ""
    @State private var celebrateStatus: DayMedalStatus = .base
    @State private var showCelebrate = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                if let medal = plan.medal {
                    medalBanner(medal: medal)
                }

                if let main = plan.mainTask {
                    taskCard(
                        title: "主线",
                        task: main,
                        accent: AppTheme.mainAccent,
                        compact: false
                    )
                }

                ForEach(plan.sideTasks, id: \.persistentModelID) { side in
                    taskCard(
                        title: "支线",
                        task: side,
                        accent: AppTheme.sideAccent,
                        compact: true
                    )
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 32)
        }
        .overlay {
            if showCelebrate {
                CelebrateMedalView(
                    title: celebrateTitle,
                    subtitle: celebrateSubtitle,
                    status: celebrateStatus,
                    onDismiss: { showCelebrate = false }
                )
            }
        }
    }

    private func taskCard(title: String, task: TaskItem, accent: Color, compact: Bool) -> some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 14) {
                HStack {
                    Text(title)
                        .font(AppTheme.caption())
                        .foregroundStyle(accent)
                    Spacer()
                    Text("\(task.completedCount)/\(task.stages.count)")
                        .font(AppTheme.caption(12))
                        .foregroundStyle(AppTheme.inkMuted)
                }

                Text(task.rawText)
                    .font(AppTheme.body(15))
                    .foregroundStyle(AppTheme.ink)

                StageProgressBar(
                    stages: task.stages,
                    accent: accent,
                    compact: compact,
                    onToggle: { toggle(stage: $0, in: task) }
                )
            }
        }
    }

    private func medalBanner(medal: DailyMedal) -> some View {
        GlassCard {
            HStack(spacing: 16) {
                MedalView(
                    status: medal.hasHolographic ? .holographic : .base,
                    size: 52
                )
                VStack(alignment: .leading, spacing: 4) {
                    Text(medal.hasHolographic ? "全息勋章" : "今日勋章")
                        .font(AppTheme.title(17))
                        .foregroundStyle(AppTheme.ink)
                    if !medal.hasHolographic, !plan.sideTasks.isEmpty {
                        Text("完成全部支线解锁镀层")
                            .font(AppTheme.caption(12))
                            .foregroundStyle(AppTheme.inkMuted)
                    }
                }
                Spacer()
            }
        }
    }

    private func toggle(stage: TaskStage, in task: TaskItem) {
        let wasDone = stage.isDone
        let previousCompletedAt = stage.completedAt

        withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) {
            stage.isDone.toggle()
            stage.completedAt = stage.isDone ? .now : nil
        }
        plan.updatedAt = .now

        do {
            let result = try MedalService.evaluate(plan: plan, context: context)
            if result.upgradedToHolographic {
                celebrateTitle = "全息镀层"
                celebrateSubtitle = "主线与全部支线，今日圆满"
                celebrateStatus = .holographic
                showCelebrate = true
            } else if result.awardedBase {
                celebrateTitle = "今日勋章"
                celebrateSubtitle = "主线已全部完成"
                celebrateStatus = .base
                showCelebrate = true
            }
            onPlanUpdated()
        } catch {
            withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) {
                stage.isDone = wasDone
                stage.completedAt = previousCompletedAt
            }
        }
    }
}
