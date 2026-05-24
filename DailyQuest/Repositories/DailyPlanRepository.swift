import Foundation
import SwiftData

protocol DailyPlanRepository {
    func plan(for date: Date, in context: ModelContext) throws -> DailyPlan?
    func plan(forCalendarDay date: Date, in context: ModelContext) throws -> DailyPlan?
    func plans(in month: Date, context: ModelContext) throws -> [DailyPlan]
    func medalStatuses(in month: Date, context: ModelContext) throws -> [Date: DayMedalStatus]
    func hasPlanForCurrentQuestDay(in context: ModelContext) throws -> Bool
    @discardableResult
    func save(_ plan: DailyPlan, context: ModelContext) throws -> DailyPlan
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

    @discardableResult
    func save(_ newPlan: DailyPlan, context: ModelContext) throws -> DailyPlan {
        // `DailyPlan.init` 已写入任务日锚点；再次 startOfDay 会在午夜锚点上回退一天。
        let day = newPlan.date
        newPlan.updatedAt = .now

        guard newPlan.hasValidQuestContent else {
            throw DailyPlanSaveError.invalidContent
        }

        try deletePlans(on: day, in: context)
        insertPlanGraph(newPlan, in: context)
        try context.save()
        context.processPendingChanges()

        if let verified = try fetchBestPlan(on: day, in: context), verified.hasValidQuestContent {
            return verified
        }
        if newPlan.hasValidQuestContent {
            return newPlan
        }
        throw DailyPlanSaveError.invalidContent
    }

    func delete(_ plan: DailyPlan, context: ModelContext) throws {
        context.delete(plan)
        try context.save()
    }

    private func insertPlanGraph(_ plan: DailyPlan, in context: ModelContext) {
        if let main = plan.mainTask {
            for stage in main.stages {
                context.insert(stage)
            }
            context.insert(main)
        }
        for side in plan.sideTasks {
            for stage in side.stages {
                context.insert(stage)
            }
            context.insert(side)
        }
        if let medal = plan.medal {
            context.insert(medal)
        }
        context.insert(plan)
    }

    private func fetchBestPlan(on day: Date, in context: ModelContext) throws -> DailyPlan? {
        let candidates = try fetchPlans(on: day, in: context)
        return Self.pickBest(from: candidates)
    }

    private func fetchPlans(on day: Date, in context: ModelContext, prefetchRelationships: Bool = true) throws -> [DailyPlan] {
        let dayStart = day
        let dayEnd = DateHelpers.calendar.date(byAdding: .day, value: 1, to: dayStart) ?? dayStart
        var descriptor = FetchDescriptor<DailyPlan>(
            predicate: #Predicate { plan in
                plan.date >= dayStart && plan.date < dayEnd
            },
            sortBy: [SortDescriptor(\.updatedAt, order: .reverse)]
        )
        if prefetchRelationships {
            descriptor.relationshipKeyPathsForPrefetching = [
                \DailyPlan.mainTask,
                \DailyPlan.sideTasks
            ]
        }
        let plans = try context.fetch(descriptor)
        if prefetchRelationships {
            for plan in plans {
                _ = plan.mainTask?.stages.count
                for side in plan.sideTasks {
                    _ = side.stages.count
                }
            }
        }
        return plans
    }

    private func deletePlans(on day: Date, in context: ModelContext) throws {
        let plans = try fetchPlans(on: day, in: context, prefetchRelationships: false)
        for plan in plans {
            context.delete(plan)
        }
        if !plans.isEmpty {
            try context.save()
        }
    }

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
            return "拆解已返回，但阶段未能写入本地数据库，请重试"
        }
    }
}
