import Foundation
import SwiftData

protocol DailyPlanRepository {
    func plan(for date: Date, in context: ModelContext) throws -> DailyPlan?
    func plans(in month: Date, context: ModelContext) throws -> [DailyPlan]
    func medalStatuses(in month: Date, context: ModelContext) throws -> [Date: DayMedalStatus]
    func hasPlanForCurrentQuestDay(in context: ModelContext) throws -> Bool
    func save(_ plan: DailyPlan, context: ModelContext) throws
    func delete(_ plan: DailyPlan, context: ModelContext) throws
}

struct LocalDailyPlanRepository: DailyPlanRepository {
    func plan(for date: Date, in context: ModelContext) throws -> DailyPlan? {
        let day = DateHelpers.startOfDay(date)
        let descriptor = FetchDescriptor<DailyPlan>(
            predicate: #Predicate { $0.date == day }
        )
        return try context.fetch(descriptor).first
    }

    func plans(in month: Date, context: ModelContext) throws -> [DailyPlan] {
        guard let interval = DateHelpers.monthInterval(containing: month) else { return [] }
        let start = interval.start
        let end = interval.end
        let descriptor = FetchDescriptor<DailyPlan>(
            predicate: #Predicate { plan in
                plan.date >= start && plan.date < end
            },
            sortBy: [SortDescriptor(\.date)]
        )
        return try context.fetch(descriptor)
    }

    func medalStatuses(in month: Date, context: ModelContext) throws -> [Date: DayMedalStatus] {
        let plans = try plans(in: month, context: context)
        var map: [Date: DayMedalStatus] = [:]
        for plan in plans {
            map[DateHelpers.startOfDay(plan.date)] = DayMedalStatus.from(plan: plan)
        }
        return map
    }

    func hasPlanForCurrentQuestDay(in context: ModelContext) throws -> Bool {
        try plan(for: .now, in: context) != nil
    }

    /// Upsert by calendar day — replaces existing plan for the same date if present.
    func save(_ newPlan: DailyPlan, context: ModelContext) throws {
        let day = DateHelpers.startOfDay(newPlan.date)
        newPlan.date = day
        newPlan.updatedAt = .now

        if let existing = try plan(for: day, in: context), existing !== newPlan {
            context.delete(existing)
        }

        if let main = newPlan.mainTask {
            context.insert(main)
            for stage in main.stages {
                context.insert(stage)
            }
        }
        for side in newPlan.sideTasks {
            context.insert(side)
            for stage in side.stages {
                context.insert(stage)
            }
        }
        context.insert(newPlan)
        try context.save()
    }

    func delete(_ plan: DailyPlan, context: ModelContext) throws {
        context.delete(plan)
        try context.save()
    }
}
