import Foundation
import SwiftData

@MainActor
@Observable
final class CalendarViewModel {
    var displayedMonth: Date = .now
    var statusMap: [Date: DayMedalStatus] = [:]
    var designMap: [Date: MedalDesign] = [:]
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
            statusMap = Dictionary(uniqueKeysWithValues: plans.map { ($0.date, DayMedalStatus.from(plan: $0)) })
            designMap = Dictionary(uniqueKeysWithValues: plans.compactMap { plan in
                guard let design = MedalDesignCodec.decode(plan.medalDesignJSON) else { return nil }
                return (plan.date, design)
            })
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
        let day = DateHelpers.questDayAnchor(forCalendarDay: date)
        return statusMap[day] ?? .none
    }

    func design(for date: Date) -> MedalDesign? {
        let day = DateHelpers.questDayAnchor(forCalendarDay: date)
        return designMap[day]
    }

    func plan(for date: Date, context: ModelContext) -> DailyPlan? {
        try? repository.plan(forCalendarDay: date, in: context)
    }
}
