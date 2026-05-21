import Foundation
import SwiftData

@Model
final class DailyPlan {
    var date: Date
    var createdAt: Date
    var updatedAt: Date
    var cloudID: String?

    @Relationship(deleteRule: .cascade)
    var mainTask: TaskItem?

    @Relationship(deleteRule: .cascade)
    var sideTasks: [TaskItem]

    @Relationship(deleteRule: .cascade)
    var medal: DailyMedal?

    init(
        date: Date,
        createdAt: Date = .now,
        updatedAt: Date = .now,
        cloudID: String? = nil,
        mainTask: TaskItem? = nil,
        sideTasks: [TaskItem] = [],
        medal: DailyMedal? = nil
    ) {
        self.date = QuestDayCalendar.questDayStart(for: date)
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.cloudID = cloudID
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
