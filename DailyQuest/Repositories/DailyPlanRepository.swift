import Foundation
import SwiftData

protocol DailyPlanRepository {
    func plan(for date: Date, in context: ModelContext) throws -> DailyPlan?
    func plan(forCalendarDay date: Date, in context: ModelContext) throws -> DailyPlan?
    func plans(in month: Date, context: ModelContext) throws -> [DailyPlan]
    func medalStatuses(in month: Date, context: ModelContext) throws -> [Date: DayMedalStatus]
    func hasPlanForCurrentQuestDay(in context: ModelContext) throws -> Bool
    func save(_ plan: DailyPlan, context: ModelContext) throws
    func delete(_ plan: DailyPlan, context: ModelContext) throws
}

struct LocalDailyPlanRepository: DailyPlanRepository {
    func plan(for date: Date, in context: ModelContext) throws -> DailyPlan? {
        let day = DateHelpers.startOfDay(date)
        return try fetchBestPlan(on: day, in: context)
    }

    func plan(forCalendarDay date: Date, in context: ModelContext) throws -> DailyPlan? {
        let day = DateHelpers.questDayAnchor(forCalendarDay: date)
        return try fetchBestPlan(on: day, in: context)
    }

    func plans(in month: Date, context: ModelContext) throws -> [DailyPlan] {
        guard let interval = DateHelpers.monthInterval(containing: month) else { return [] }
        let start = interval.start
        let end = interval.end
        let descriptor = FetchDescriptor<DailyPlan>(
            predicate: #Predicate { plan in
                plan.date >= start && plan.date < end
            },
            sortBy: [SortDescriptor(\.updatedAt, order: .reverse)]
        )
        let all = try context.fetch(descriptor)
        return Self.dedupeByQuestDay(all)
    }

    func medalStatuses(in month: Date, context: ModelContext) throws -> [Date: DayMedalStatus] {
        let plans = try plans(in: month, context: context)
        var map: [Date: DayMedalStatus] = [:]
        for plan in plans {
            map[plan.date] = DayMedalStatus.from(plan: plan)
        }
        return map
    }

    func hasPlanForCurrentQuestDay(in context: ModelContext) throws -> Bool {
        context.processPendingChanges()
        guard let existing = try plan(for: .now, in: context) else { return false }
        return existing.hasValidQuestContent
    }

    /// Upsert by quest day — replaces all rows for that quest day, then inserts one plan.
    func save(_ newPlan: DailyPlan, context: ModelContext) throws {
        let day = DateHelpers.startOfDay(newPlan.date)
        newPlan.date = day
        newPlan.updatedAt = .now

        guard newPlan.hasValidQuestContent else {
            throw DailyPlanSaveError.invalidContent
        }

        try deletePlans(on: day, keeping: nil, in: context)
        context.insert(newPlan)
        try context.save()
        context.processPendingChanges()
    }

    func delete(_ plan: DailyPlan, context: ModelContext) throws {
        context.delete(plan)
        try context.save()
    }

    private func fetchBestPlan(on day: Date, in context: ModelContext) throws -> DailyPlan? {
        let candidates = try fetchPlans(on: day, in: context)
        return Self.pickBest(from: candidates)
    }

    private func fetchPlans(on day: Date, in context: ModelContext) throws -> [DailyPlan] {
        let dayStart = day
        let dayEnd = DateHelpers.calendar.date(byAdding: .day, value: 1, to: dayStart) ?? dayStart
        var descriptor = FetchDescriptor<DailyPlan>(
            predicate: #Predicate { plan in
                plan.date >= dayStart && plan.date < dayEnd
            },
            sortBy: [SortDescriptor(\.updatedAt, order: .reverse)]
        )
        descriptor.relationshipKeyPathsForPrefetching = [
            \DailyPlan.mainTask,
            \DailyPlan.sideTasks
        ]
        let plans = try context.fetch(descriptor)
        for plan in plans {
            _ = plan.mainTask?.stages.count
            for side in plan.sideTasks {
                _ = side.stages.count
            }
        }
        return plans
    }

    private func deletePlans(on day: Date, keeping: DailyPlan?, in context: ModelContext) throws {
        let plans = try fetchPlans(on: day, in: context)
        var deleted = false
        for plan in plans where plan !== keeping {
            context.delete(plan)
            deleted = true
        }
        if deleted {
            try context.save()
        }
    }

    /// 同一任务日可能因历史 bug 留下多条记录，保留最新且内容完整的一条。
    static func dedupeByQuestDay(_ plans: [DailyPlan]) -> [DailyPlan] {
        let grouped = Dictionary(grouping: plans) { QuestDayCalendar.questDayKey(for: $0.date) }
        return grouped.values.compactMap { pickBest(from: $0) }
            .sorted { $0.date < $1.date }
    }

    static func pickBest(from plans: [DailyPlan]) -> DailyPlan? {
        guard !plans.isEmpty else { return nil }
        if let valid = plans.filter(\.hasValidQuestContent).max(by: { $0.updatedAt < $1.updatedAt }) {
            return valid
        }
        return plans.max(by: { $0.updatedAt < $1.updatedAt })
    }
}

enum DailyPlanSaveError: LocalizedError {
    case invalidContent

    var errorDescription: String? {
        switch self {
        case .invalidContent:
            return "拆解结果无效（主线阶段为空），请修改任务文案后重试"
        }
    }
}
