import Foundation
import SwiftData

@Model
final class DailyPlan {
    var date: Date
    var createdAt: Date
    var updatedAt: Date
    var cloudID: String?
    /// JSON-encoded `MedalDesign` draft for this quest day.
    var medalDesignJSON: String?

    @Relationship(deleteRule: .cascade, inverse: \TaskItem.planForMain)
    var mainTask: TaskItem?

    @Relationship(deleteRule: .cascade, inverse: \TaskItem.planForSide)
    var sideTasks: [TaskItem]

    @Relationship(deleteRule: .cascade)
    var medal: DailyMedal?

    init(
        date: Date,
        createdAt: Date = .now,
        updatedAt: Date = .now,
        cloudID: String? = nil,
        medalDesignJSON: String? = nil,
        mainTask: TaskItem? = nil,
        sideTasks: [TaskItem] = [],
        medal: DailyMedal? = nil
    ) {
        self.date = QuestDayCalendar.questDayStart(for: date)
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.cloudID = cloudID
        self.medalDesignJSON = medalDesignJSON
        self.mainTask = mainTask
        self.sideTasks = sideTasks
        self.medal = medal
    }

    var mainProgress: (done: Int, total: Int) {
        guard let main = mainTask else { return (0, 0) }
        return (main.completedCount, main.stages.count)
    }

    var overallProgress: Double {
        let items = ([mainTask].compactMap { $0 }) + sideTasks
        let total = items.flatMap(\.stages).count
        guard total > 0 else { return 0 }
        let done = items.flatMap(\.stages).filter(\.isDone).count
        return Double(done) / Double(total)
    }

    /// 是否已有可展示、可打卡的任务内容。
    var hasValidQuestContent: Bool {
        guard let main = mainTask else { return false }
        let text = main.rawText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty, !main.stages.isEmpty else { return false }
        return true
    }
}

enum DailyPlanRelationshipWire {
    /// 保存前绑定 SwiftData 双向关系，避免读取时 mainTask / stages 丢失。
    static func wire(_ plan: DailyPlan) {
        if let main = plan.mainTask {
            main.planForMain = plan
            for stage in main.stages {
                stage.task = main
            }
        }
        for side in plan.sideTasks {
            side.planForSide = plan
            for stage in side.stages {
                stage.task = side
            }
        }
    }
}
