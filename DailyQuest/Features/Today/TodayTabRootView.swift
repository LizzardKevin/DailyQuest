import SwiftUI
import SwiftData

struct TodayTabRootView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \DailyPlan.updatedAt, order: .reverse) private var allPlans: [DailyPlan]
    @State private var showTabsHint = false
    @State private var pinnedPlanID: PersistentIdentifier?

    private var todayPlan: DailyPlan? {
        if let pinned = pinnedTodayPlan {
            return pinned
        }

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
                            onCompleted: {}
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
            .onReceive(NotificationCenter.default.publisher(for: .dailyPlanDidChange)) { notification in
                if let id = notification.userInfo?[AppNotificationPoster.planIDUserInfoKey] as? PersistentIdentifier {
                    pinnedPlanID = id
                }
                touchContext()
            }
        }
    }

    private func touchContext() {
        context.processPendingChanges()
        pinTodayPlanIfNeeded()
    }

    private var pinnedTodayPlan: DailyPlan? {
        guard let pinnedPlanID,
              let plan = context.model(for: pinnedPlanID) as? DailyPlan,
              isCurrentQuestPlan(plan) else {
            return nil
        }
        return plan
    }

    private func pinTodayPlanIfNeeded() {
        if pinnedTodayPlan != nil {
            return
        }
        let repository = LocalDailyPlanRepository()
        if let plan = try? repository.plan(for: .now, in: context),
           isCurrentQuestPlan(plan) {
            pinnedPlanID = plan.persistentModelID
        }
    }

    private func isCurrentQuestPlan(_ plan: DailyPlan) -> Bool {
        plan.hasValidQuestContent &&
        QuestDayCalendar.questDayKey(for: plan.date) == QuestDayCalendar.questDayKey()
    }

    private func touchPlan(_ plan: DailyPlan) {
        context.processPendingChanges()
        pinnedPlanID = plan.persistentModelID
        _ = plan.mainTask?.stages.count
    }

    private func dismissTabsHint() {
        LightPromptStore.markSeen(.mainTabs)
        showTabsHint = false
    }
}
