import SwiftUI
import SwiftData

struct TodayTabRootView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \DailyPlan.updatedAt, order: .reverse) private var allPlans: [DailyPlan]
    @State private var showTabsHint = false

    private var todayPlan: DailyPlan? {
        let key = QuestDayCalendar.questDayKey()
        let matching = allPlans.filter { QuestDayCalendar.questDayKey(for: $0.date) == key }
        return LocalDailyPlanRepository.pickBest(from: matching)
    }

    var body: some View {
        NavigationStack {
            ZStack {
                DawnBackground()

                Group {
                    if let plan = todayPlan, plan.hasValidQuestContent {
                        TodayBoardView(plan: plan, onPlanUpdated: { touchPlan(plan) })
                            .id(plan.persistentModelID)
                    } else {
                        DailyQuestInputView(
                            title: "今日任务",
                            subtitle: "写下今日主线与支线，领取任务或由默认阶段开始",
                            showFlowHints: false,
                            onCompleted: { touchContext() }
                        )
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("今日")
                        .font(AppTheme.title(18))
                        .foregroundStyle(AppTheme.ink)
                }
            }
            .safeAreaInset(edge: .top, spacing: 0) {
                if showTabsHint {
                    LightPromptBanner(
                        message: TutorialContent.lightPromptMainTabs,
                        onDismiss: dismissTabsHint
                    )
                    .padding(.horizontal, 16)
                    .padding(.top, 8)
                }
            }
            .onAppear {
                touchContext()
                showTabsHint = !LightPromptStore.hasSeen(.mainTabs)
            }
            .onReceive(NotificationCenter.default.publisher(for: .dailyPlanDidChange)) { _ in
                touchContext()
            }
        }
    }

    private func touchContext() {
        context.processPendingChanges()
    }

    private func touchPlan(_ plan: DailyPlan) {
        context.processPendingChanges()
        _ = plan.mainTask?.stages.count
    }

    private func dismissTabsHint() {
        LightPromptStore.markSeen(.mainTabs)
        showTabsHint = false
    }
}
