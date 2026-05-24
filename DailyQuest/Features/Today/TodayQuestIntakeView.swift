import SwiftUI

/// 专门填写并领取今日任务的独立页面（从今日 Tab 进入）。
struct TodayQuestIntakeView: View {
    @Environment(\.dismiss) private var dismiss
    let onCompleted: () -> Void

    var body: some View {
        DailyQuestInputView(
            title: "今日任务",
            subtitle: "写下今日主线与支线，领取任务开始今日挑战",
            showFlowHints: false,
            onCompleted: {
                onCompleted()
                dismiss()
            }
        )
        .navigationTitle("领取任务")
        .navigationBarTitleDisplayMode(.inline)
    }
}
