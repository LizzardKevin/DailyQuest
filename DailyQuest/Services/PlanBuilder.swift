import Foundation
import SwiftData

enum PlanBuilder {
    static func makePlan(
        date: Date,
        mainText: String,
        sideTexts: [String],
        breakdown: TaskBreakdownResponse
    ) throws -> DailyPlan {
        let validated = try breakdown.validated(expectedSideCount: sideTexts.count)

        let mainStages = validated.main.stages.enumerated().map { index, stage in
            TaskStage(order: index, title: stage.title, hint: stage.hint)
        }
        let mainTask = TaskItem(kind: .main, rawText: mainText, stages: mainStages)

        let sideTasks: [TaskItem] = zip(sideTexts, validated.sides).map { text, side in
            let stages = side.stages.enumerated().map { index, stage in
                TaskStage(order: index, title: stage.title, hint: stage.hint)
            }
            return TaskItem(kind: .side, rawText: text, stages: stages)
        }

        guard sideTasks.count == sideTexts.count else {
            throw BreakdownValidationError.sidesCountMismatch(
                expected: sideTexts.count,
                actual: sideTasks.count
            )
        }

        return DailyPlan(date: date, mainTask: mainTask, sideTasks: sideTasks)
    }
}
