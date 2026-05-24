import Foundation
import SwiftData

@MainActor
@Observable
final class CalendarViewModel {
    var displayedMonth: Date = .now
    /// 任务日键 `yyyy-MM-dd`，避免 `Date` 键重复或时区不一致导致崩溃。
    var statusMap: [String: DayMedalStatus] = [:]
    var designMap: [String: MedalDesign] = [:]
    var isLoading = false

    private let repository: DailyPlanRepository = LocalDailyPlanRepository()

    var monthTitle: String {
        DateHelpers.formattedMonth(displayedMonth)
    }

    var baseMedalCount: Int {
        statusMap.values.filter { $0 == .base }.count
    }

    var holographicCount: Int {
        statusMap.values.filter { $0 == .holographic }.count
    }

    func load(context: ModelContext) {
        isLoading = true
        defer { isLoading = false }
        do {
            let plans = try repository.plans(in: displayedMonth, context: context)
            var nextStatus: [String: DayMedalStatus] = [:]
            var nextDesign: [String: MedalDesign] = [:]
            for plan in plans {
                let key = QuestDayCalendar.questDayKey(for: plan.date)
                nextStatus[key] = DayMedalStatus.from(plan: plan)
                if let design = MedalDesignCodec.decode(plan.medalDesignJSON) {
                    nextDesign[key] = design
                }
            }
            statusMap = nextStatus
            designMap = nextDesign
        } catch {
            statusMap = [:]
            designMap = [:]
        }
    }

    func previousMonth() {
        if let newMonth = Calendar.current.date(byAdding: .month, value: -1, to: displayedMonth) {
            displayedMonth = newMonth
        }
    }

    func nextMonth() {
        if let newMonth = Calendar.current.date(byAdding: .month, value: 1, to: displayedMonth) {
            displayedMonth = newMonth
        }
    }

    func status(for date: Date) -> DayMedalStatus {
        statusMap[questDayKey(forCalendarDay: date)] ?? .none
    }

    func design(for date: Date) -> MedalDesign? {
        designMap[questDayKey(forCalendarDay: date)]
    }

    func plan(for date: Date, context: ModelContext) -> DailyPlan? {
        try? repository.plan(forCalendarDay: date, in: context)
    }

    private func questDayKey(forCalendarDay date: Date) -> String {
        let anchor = DateHelpers.questDayAnchor(forCalendarDay: date)
        return QuestDayCalendar.questDayKey(for: anchor)
    }
}
