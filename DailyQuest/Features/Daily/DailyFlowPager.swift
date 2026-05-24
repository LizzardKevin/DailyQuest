import SwiftUI

/// 无今日计划时：每日趣闻 → 左滑 → 每日目标 → 领取任务。
struct DailyFlowPager: View {
    let onCompleted: () -> Void

    var body: some View {
        ZStack {
            DawnBackground()
            TabView {
                DailyTriviaView()
                QuestIntakeView(onCompleted: onCompleted)
            }
            .tabViewStyle(.page(indexDisplayMode: .always))
        }
    }
}
