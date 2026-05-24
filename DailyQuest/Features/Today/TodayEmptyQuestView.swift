import SwiftUI

/// 今日 Tab 未领取任务时的主界面占位，仅引导进入专门领取页。
struct TodayEmptyQuestView: View {
    let onStartQuest: () -> Void

    var body: some View {
        VStack(spacing: 28) {
            Spacer(minLength: 24)

            Image(systemName: "flag.fill")
                .font(.system(size: 52))
                .foregroundStyle(AppTheme.mainAccent)
                .symbolRenderingMode(.hierarchical)

            VStack(spacing: 10) {
                Text("尚未领取今日任务")
                    .font(AppTheme.title(22))
                    .foregroundStyle(AppTheme.ink)

                Text("写下主线与支线后，AI 会拆解为可打卡阶段")
                    .font(AppTheme.body(15))
                    .foregroundStyle(AppTheme.inkMuted)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 12)
            }

            PrimaryButton("领取今日任务", icon: "arrow.right") {
                onStartQuest()
            }
            .padding(.horizontal, 4)

            Spacer(minLength: 24)
        }
        .padding(.horizontal, 20)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
