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
        return try fetchPlan(on: day, in: context)
    }

    func plan(forCalendarDay date: Date, in context: ModelContext) throws -> DailyPlan? {
        let day = DateHelpers.questDayAnchor(forCalendarDay: date)
        return try fetchPlan(on: day, in: context)
    }

    private func fetchPlan(on day: Date, in context: ModelContext) throws -> DailyPlan? {
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
            map[plan.date] = DayMedalStatus.from(plan: plan)
        }
        return map
    }

    func hasPlanForCurrentQuestDay(in context: ModelContext) throws -> Bool {
        context.processPendingChanges()
        guard let existing = try plan(for: .now, in: context) else { return false }
        return existing.hasValidQuestContent
    }

    /// Upsert by quest day — replaces existing plan for the same date if present.
    func save(_ newPlan: DailyPlan, context: ModelContext) throws {
        let day = DateHelpers.startOfDay(newPlan.date)
        newPlan.date = day
        newPlan.updatedAt = .now

        if let existing = try plan(for: day, in: context), existing !== newPlan {
            context.delete(existing)
            try context.save()
        }

        insertTaskGraph(for: newPlan, in: context)
        context.insert(newPlan)
        try context.save()
        context.processPendingChanges()

        guard newPlan.hasValidQuestContent else {
            throw DailyPlanSaveError.invalidContent
        }
    }

    private func insertTaskGraph(for plan: DailyPlan, in context: ModelContext) {
        if let main = plan.mainTask {
            context.insert(main)
            for stage in main.stages {
                context.insert(stage)
            }
        }
        for side in plan.sideTasks {
            context.insert(side)
            for stage in side.stages {
                context.insert(stage)
            }
        }
        if let medal = plan.medal {
            context.insert(medal)
        }
    }

    func delete(_ plan: DailyPlan, context: ModelContext) throws {
        context.delete(plan)
        try context.save()
    }
}

enum DailyPlanSaveError: LocalizedError {
    case invalidContent

    var errorDescription: String? {
        switch self {
        case .invalidContent:
            return "任务保存失败：拆解结果未写入本地，请重试"
        }
    }
}
