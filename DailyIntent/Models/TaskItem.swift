import Foundation
import SwiftData

@Model
final class TaskItem {
    var kindRaw: String
    var rawText: String
    @Relationship(deleteRule: .cascade)
    var stages: [TaskStage]

    var kind: TaskItemKind {
        get { TaskItemKind(rawValue: kindRaw) ?? .main }
        set { kindRaw = newValue.rawValue }
    }

    var isCompleted: Bool {
        !stages.isEmpty && stages.allSatisfy(\.isDone)
    }

    var completedCount: Int {
        stages.filter(\.isDone).count
    }

    init(kind: TaskItemKind, rawText: String, stages: [TaskStage] = []) {
        self.kindRaw = kind.rawValue
        self.rawText = rawText
        self.stages = stages
    }
}
