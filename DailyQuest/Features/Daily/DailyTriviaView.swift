import SwiftUI

struct DailyTriviaView: View {
    @State private var events: [OnThisDayEvent] = []
    @State private var isLoading = true
    @State private var showSwipeHint = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                ScreenHeader(
                    headerTitle,
                    subtitle: "历史上的今天 · 任务日 \(QuestDayCalendar.questDayKey())"
                )

                if showSwipeHint {
                    LightPromptBanner(
                        message: TutorialContent.lightPromptDailySwipe,
                        onDismiss: dismissSwipeHint
                    )
                }

                if isLoading {
                    ProgressView()
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 40)
                } else if events.isEmpty {
                    GlassCard {
                        Text("今日史料暂不可用，向左滑去领取任务吧。")
                            .font(AppTheme.body(15))
                            .foregroundStyle(AppTheme.inkMuted)
                    }
                } else {
                    ForEach(events) { event in
                        triviaCard(event)
                    }
                }

                HStack {
                    Spacer()
                    Label("向左滑动 · 每日目标", systemImage: "chevron.left")
                        .font(AppTheme.caption())
                        .foregroundStyle(AppTheme.inkMuted)
                    Spacer()
                }
                .padding(.top, 8)
            }
            .padding(20)
        }
        .task { await loadEvents() }
        .onAppear {
            showSwipeHint = !LightPromptStore.hasSeen(.dailySwipe)
            if events.isEmpty, !isLoading {
                Task { await loadEvents() }
            }
        }
    }

    private var headerTitle: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "zh_CN")
        formatter.dateFormat = "M月d日"
        return "每日 · \(formatter.string(from: .now))"
    }

    private func triviaCard(_ event: OnThisDayEvent) -> some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 10) {
                Text(event.kind.label)
                    .font(AppTheme.caption(11))
                    .foregroundStyle(AppTheme.mainAccent)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background {
                        Capsule().fill(AppTheme.mainAccent.opacity(0.12))
                    }
                if let yearHeadline = event.yearHeadline {
                    Text(verbatim: yearHeadline)
                        .font(AppTheme.title(20))
                        .foregroundStyle(AppTheme.ink)
                }
                Text(event.text)
                    .font(AppTheme.body(15))
                    .foregroundStyle(AppTheme.inkMuted)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    private func loadEvents() async {
        if events.isEmpty {
            let local = await OnThisDayService.shared.fallbackEvents()
            if !local.isEmpty {
                events = local
            }
        }
        isLoading = events.isEmpty
        let loaded = await OnThisDayService.shared.events()
        if !loaded.isEmpty {
            events = loaded
        }
        isLoading = false
    }

    private func dismissSwipeHint() {
        LightPromptStore.markSeen(.dailySwipe)
        showSwipeHint = false
    }
}
