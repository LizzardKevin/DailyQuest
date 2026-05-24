import SwiftUI

/// 每日流程第二页：领取任务。
struct QuestIntakeView: View {
    let onCompleted: () -> Void

    @State private var triviaTitle: String?
    @State private var triviaYear: Int?

    var body: some View {
        DailyQuestInputView(
            title: "每日目标",
            subtitle: "一条主线，最多两条支线",
            showFlowHints: true,
            triviaTitle: triviaTitle,
            triviaYear: triviaYear,
            onCompleted: onCompleted
        )
        .task {
            let events = await OnThisDayService.shared.events(for: .now)
            if let first = events.first {
                triviaTitle = first.text
                triviaYear = first.year
            }
        }
    }
}
