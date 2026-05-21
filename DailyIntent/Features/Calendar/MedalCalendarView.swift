import SwiftUI
import SwiftData

struct MedalCalendarView: View {
    @Environment(\.modelContext) private var context
    @State private var viewModel = CalendarViewModel()
    @State private var selectedDate: Date?
    @State private var showDetail = false

    private let columns = Array(repeating: GridItem(.flexible(), spacing: 4), count: 7)

    var body: some View {
        NavigationStack {
            ZStack {
                DawnBackground()

                ScrollView {
                    VStack(spacing: 20) {
                        monthHeader
                        weekdayHeader
                        calendarGrid
                        monthStats
                        legend
                    }
                    .padding(20)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("勋章日历")
                        .font(AppTheme.title(18))
                        .foregroundStyle(AppTheme.ink)
                }
            }
            .onAppear { viewModel.load(context: context) }
            .onChange(of: viewModel.displayedMonth) { _, _ in
                viewModel.load(context: context)
            }
            .sheet(isPresented: $showDetail) {
                if let selectedDate {
                    DayDetailSheet(date: selectedDate)
                }
            }
        }
    }

    private var monthHeader: some View {
        HStack {
            Button { viewModel.previousMonth() } label: {
                Image(systemName: "chevron.left")
                    .font(.body.weight(.semibold))
                    .foregroundStyle(AppTheme.ink)
            }

            Spacer()

            Text(viewModel.monthTitle)
                .font(AppTheme.title(18))
                .foregroundStyle(AppTheme.ink)

            Spacer()

            Button { viewModel.nextMonth() } label: {
                Image(systemName: "chevron.right")
                    .font(.body.weight(.semibold))
                    .foregroundStyle(isFutureMonth(viewModel.displayedMonth) ? AppTheme.inkMuted : AppTheme.ink)
            }
            .disabled(isFutureMonth(viewModel.displayedMonth))
        }
    }

    private var weekdayHeader: some View {
        LazyVGrid(columns: columns, spacing: 4) {
            ForEach(DateHelpers.weekdayHeaders(), id: \.self) { label in
                Text(label)
                    .font(AppTheme.caption(11))
                    .foregroundStyle(AppTheme.inkMuted)
            }
        }
    }

    private var calendarGrid: some View {
        let days = DateHelpers.daysInMonth(containing: viewModel.displayedMonth)
        let leading = DateHelpers.leadingBlankDays(in: viewModel.displayedMonth)

        return LazyVGrid(columns: columns, spacing: 10) {
            ForEach(0..<leading, id: \.self) { _ in
                Color.clear.frame(height: 48)
            }

            ForEach(days, id: \.self) { date in
                CalendarDayCell(
                    date: date,
                    status: viewModel.status(for: date),
                    isToday: QuestDayCalendar.isCurrentQuestDay(date),
                    isFuture: QuestDayCalendar.isFutureQuestDay(date)
                ) {
                    guard !QuestDayCalendar.isFutureQuestDay(date) else { return }
                    selectedDate = date
                    showDetail = true
                }
            }
        }
    }

    private var monthStats: some View {
        Text("本月 · 基础 \(viewModel.baseMedalCount) 天 · 全息 \(viewModel.holographicCount) 天")
            .font(AppTheme.caption(12))
            .foregroundStyle(AppTheme.inkMuted)
    }

    private var legend: some View {
        HStack(spacing: 20) {
            legendItem(status: .none, label: "无")
            legendItem(status: .inProgress, label: "进行中")
            legendItem(status: .base, label: "勋章")
            legendItem(status: .holographic, label: "镀膜")
        }
    }

    private func legendItem(status: DayMedalStatus, label: String) {
        HStack(spacing: 6) {
            MedalBadge(status: status, size: 18)
            Text(label)
                .font(AppTheme.caption(11))
                .foregroundStyle(AppTheme.inkMuted)
        }
    }

    private func isFutureMonth(_ date: Date) -> Bool {
        let now = Date()
        let dc = Calendar.current.dateComponents([.year, .month], from: now)
        let mc = Calendar.current.dateComponents([.year, .month], from: date)
        if let y1 = dc.year, let m1 = dc.month, let y2 = mc.year, let m2 = mc.month {
            return y2 > y1 || (y2 == y1 && m2 > m1)
        }
        return false
    }
}

private struct CalendarDayCell: View {
    let date: Date
    let status: DayMedalStatus
    let isToday: Bool
    let isFuture: Bool
    let onTap: () -> Void

    private var dayNumber: String {
        String(Calendar.current.component(.day, from: date))
    }

    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 6) {
                Text(dayNumber)
                    .font(AppTheme.body(14))
                    .foregroundStyle(isFuture ? AppTheme.inkMuted.opacity(0.5) : AppTheme.ink)

                MedalBadge(status: isFuture ? .none : status, size: 20)
            }
            .frame(height: 48)
            .frame(maxWidth: .infinity)
            .background {
                if isToday {
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(.ultraThinMaterial)
                        .overlay {
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .strokeBorder(AppTheme.glassBorder, lineWidth: 1.2)
                        }
                }
            }
        }
        .buttonStyle(.plain)
        .disabled(isFuture)
    }
}
