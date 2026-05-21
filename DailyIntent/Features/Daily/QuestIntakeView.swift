import SwiftUI

/// 每日流程第二页：领取任务。
struct QuestIntakeView: View {
    let onCompleted: () -> Void

    var body: some View {
        DailyQuestInputView(
            title: "每日目标",
            subtitle: "一条主线，最多两条支线",
            showFlowHints: true,
            onCompleted: onCompleted
        )
    }
}
