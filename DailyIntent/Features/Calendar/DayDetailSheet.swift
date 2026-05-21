import SwiftUI
import SwiftData

struct DayDetailSheet: View {
    let date: Date

    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss

    @State private var plan: DailyPlan?

    private let repository: DailyPlanRepository = LocalDailyPlanRepository()

    var body: some View {
        NavigationStack {
            ZStack {
                DawnBackground()

                ScrollView {
                    VStack(spacing: 18) {
                        if let plan {
                            planContent(plan)
                        } else {
                            emptyContent
                        }
                    }
                    .padding(20)
                }
            }
            .navigationTitle(DateHelpers.formattedDay(date))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("完成") { dismiss() }
                        .foregroundStyle(AppTheme.mainAccent)
                }
            }
            .onAppear { load() }
        }
    }

    @ViewBuilder
    private func planContent(_ plan: DailyPlan) -> some View {
        let status = DayMedalStatus.from(plan: plan)

        switch status {
        case .base, .holographic:
            HStack {
                Spacer()
                MedalView(status: status, size: 100)
                Spacer()
            }
            .padding(.vertical, 8)
        case .inProgress:
            GlassCard {
                VStack(alignment: .leading, spacing: 6) {
                    Text("进行中")
                        .font(AppTheme.title(17))
                        .foregroundStyle(AppTheme.ink)
                    Text("完成主线全部阶段即可获得勋章")
                        .font(AppTheme.body(14))
                        .foregroundStyle(AppTheme.inkMuted)
                }
            }
        case .none:
            EmptyView()
        }

        GlassCard {
            VStack(alignment: .leading, spacing: 10) {
                Text("整体 \(Int(plan.overallProgress * 100))%")
                    .font(AppTheme.caption())
                    .foregroundStyle(AppTheme.inkMuted)
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Capsule()
                            .fill(.ultraThinMaterial)
                            .overlay {
                                Capsule().strokeBorder(Color.white.opacity(0.35), lineWidth: 0.8)
                            }
                        Capsule()
                            .fill(AppTheme.mainGradient)
                            .frame(width: max(8, geo.size.width * plan.overallProgress))
                    }
                }
                .frame(height: 10)
            }
        }

        if let main = plan.mainTask {
            detailSection(title: "主线", text: main.rawText, task: main, accent: AppTheme.mainAccent)
        }

        ForEach(plan.sideTasks, id: \.persistentModelID) { side in
            detailSection(title: "支线", text: side.rawText, task: side, accent: AppTheme.sideAccent)
        }
    }

    private func detailSection(title: String, text: String, task: TaskItem, accent: Color) -> some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 8) {
                Text(title)
                    .font(AppTheme.caption())
                    .foregroundStyle(accent)
                Text(text)
                    .font(AppTheme.body(15))
                    .foregroundStyle(AppTheme.ink)
                Text("\(task.completedCount)/\(task.stages.count) 阶段")
                    .font(AppTheme.caption(12))
                    .foregroundStyle(AppTheme.inkMuted)
            }
        }
    }

    private var emptyContent: some View {
        GlassCard {
            VStack(spacing: 14) {
                Image(systemName: "moon.zzz")
                    .font(.system(size: 40, weight: .thin))
                    .foregroundStyle(AppTheme.inkMuted)
                Text("这一天还没有记录")
                    .font(AppTheme.title(17))
                    .foregroundStyle(AppTheme.ink)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 24)
        }
    }

    private func load() {
        plan = try? repository.plan(for: date, in: context)
    }
}
