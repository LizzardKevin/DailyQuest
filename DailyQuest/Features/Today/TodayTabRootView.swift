import SwiftUI
import SwiftData

struct TodayTabRootView: View {
    @Environment(\.modelContext) private var context
    @State private var todayPlan: DailyPlan?
    @State private var showTabsHint = false

    private let repository: DailyPlanRepository = LocalDailyPlanRepository()

    var body: some View {
        NavigationStack {
            ZStack {
                DawnBackground()

                Group {
                    if let plan = todayPlan, plan.hasValidQuestContent {
                        TodayBoardView(plan: plan, onPlanUpdated: { reload() })
                    } else {
                        DailyQuestInputView(
                            title: "今日任务",
                            subtitle: "写下今日主线与支线，领取任务或由默认阶段开始",
                            showFlowHints: false,
                            onCompleted: { reload() }
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
                reload()
                showTabsHint = !LightPromptStore.hasSeen(.mainTabs)
            }
            .onReceive(NotificationCenter.default.publisher(for: .dailyPlanDidChange)) { _ in
                reload()
            }
        }
    }

    private func reload() {
        context.processPendingChanges()
        todayPlan = try? repository.plan(for: .now, in: context)
        if let plan = todayPlan {
            _ = plan.mainTask?.stages.count
        }
    }

    private func dismissTabsHint() {
        LightPromptStore.markSeen(.mainTabs)
        showTabsHint = false
    }
}
