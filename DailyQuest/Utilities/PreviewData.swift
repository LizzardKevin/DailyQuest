import SwiftData
import Foundation

enum PreviewData {
    @MainActor
    static var container: ModelContainer = {
        let schema = Schema([
            DailyPlan.self,
            TaskItem.self,
            TaskStage.self,
            DailyMedal.self
        ])
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try! ModelContainer(for: schema, configurations: [config])
        let context = container.mainContext

        let main = TaskItem(kind: .main, rawText: "完成产品原型", stages: [
            TaskStage(order: 0, title: "梳理用户流程", isDone: true, completedAt: .now),
            TaskStage(order: 1, title: "绘制线框图"),
            TaskStage(order: 2, title: "导出可点击原型")
        ])
        let side = TaskItem(kind: .side, rawText: "运动30分钟", stages: [
            TaskStage(order: 0, title: "热身5分钟"),
            TaskStage(order: 1, title: "跑步20分钟")
        ])
        let plan = DailyPlan(date: .now, mainTask: main, sideTasks: [side])
        context.insert(plan)
        return container
    }()
}
