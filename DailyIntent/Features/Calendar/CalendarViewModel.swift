import Foundation
import SwiftData

@MainActor
@Observable
final class CalendarViewModel {
    var displayedMonth: Date = .now
    var statusMap: [Date: DayMedalStatus] = [:]
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
            statusMap = try repository.medalStatuses(in: displayedMonth, context: context)
        } catch {
            statusMap = [:]
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
        let day = DateHelpers.startOfDay(date)
        return statusMap[day] ?? .none
    }

    func plan(for date: Date, context: ModelContext) -> DailyPlan? {
        try? repository.plan(for: date, in: context)
    }
}
