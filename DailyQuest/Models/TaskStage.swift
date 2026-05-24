import Foundation
import SwiftData

@Model
final class TaskStage {
    var order: Int
    var title: String
    var hint: String?
    var isDone: Bool
    var completedAt: Date?

    var task: TaskItem?

    init(order: Int, title: String, hint: String? = nil, isDone: Bool = false, completedAt: Date? = nil) {
        self.order = order
        self.title = title
        self.hint = hint
        self.isDone = isDone
        self.completedAt = completedAt
    }
}
