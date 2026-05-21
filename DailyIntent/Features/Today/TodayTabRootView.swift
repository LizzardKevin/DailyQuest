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
                    if let plan = todayPlan {
                        TodayBoardView(plan: plan, onPlanUpdated: { reload() })
                    } else {
                        waitingPlanView
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

    private var waitingPlanView: some View {
        VStack(spacing: 20) {
            Spacer()
            Image(systemName: "sun.horizon")
                .font(.system(size: 48, weight: .thin))
                .foregroundStyle(AppTheme.mainGradient)
            Text("今日尚未领取任务")
                .font(AppTheme.title(20))
                .foregroundStyle(AppTheme.ink)
            Text("完成「每日」流程后即可在此打卡")
                .font(AppTheme.body(14))
                .foregroundStyle(AppTheme.inkMuted)
            Spacer()
        }
        .padding()
    }

    private func reload() {
        todayPlan = try? repository.plan(for: .now, in: context)
    }

    private func dismissTabsHint() {
        LightPromptStore.markSeen(.mainTabs)
        showTabsHint = false
    }
}
