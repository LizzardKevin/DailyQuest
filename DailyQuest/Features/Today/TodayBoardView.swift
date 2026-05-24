import SwiftUI
import SwiftData

struct TodayBoardView: View {
    @Bindable var plan: DailyPlan
    let onPlanUpdated: () -> Void

    @Environment(\.modelContext) private var context
    @State private var celebrateTitle = ""
    @State private var celebrateSubtitle = ""
    @State private var celebrateStatus: DayMedalStatus = .base
    @State private var celebrateDesign: MedalDesign?
    @State private var showCelebrate = false

    private var draftDesign: MedalDesign? {
        MedalDesignService.design(for: plan)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                if let design = draftDesign, plan.medal == nil {
                    draftMedalBanner(design: design)
                } else if let medal = plan.medal {
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
                    design: celebrateDesign,
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

    private func draftMedalBanner(design: MedalDesign) -> some View {
        GlassCard {
            HStack(spacing: 16) {
                MedalView(status: .base, design: design, size: 52, animateHolographic: false)
                VStack(alignment: .leading, spacing: 4) {
                    Text(design.title)
                        .font(AppTheme.title(17))
                        .foregroundStyle(AppTheme.ink)
                    Text("完成主线即可解锁")
                        .font(AppTheme.caption(12))
                        .foregroundStyle(AppTheme.inkMuted)
                }
                Spacer()
            }
        }
    }

    private func medalBanner(medal: DailyMedal) -> some View {
        let design = draftDesign
        return GlassCard {
            HStack(spacing: 16) {
                MedalView(
                    status: medal.hasHolographic ? .holographic : .base,
                    design: design,
                    size: 52
                )
                VStack(alignment: .leading, spacing: 4) {
                    Text(design?.title ?? (medal.hasHolographic ? "全息勋章" : "今日勋章"))
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
            let design = draftDesign
            if result.upgradedToHolographic {
                celebrateTitle = design?.title ?? "全息镀层"
                celebrateSubtitle = design?.subtitle ?? "主线与全部支线，今日圆满"
                celebrateStatus = .holographic
                celebrateDesign = design
                showCelebrate = true
            } else if result.awardedBase {
                celebrateTitle = design?.title ?? "今日勋章"
                celebrateSubtitle = design?.subtitle ?? "主线已全部完成"
                celebrateStatus = .base
                celebrateDesign = design
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
