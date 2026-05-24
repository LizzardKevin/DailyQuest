#if DEBUG
import Foundation
import SwiftData

extension PlanBuilder {
    /// 仅 Debug / 模拟器：跳过 AI 拆解。
    static func makeManualPlan(date: Date, mainText: String, sideTexts: [String]) -> DailyPlan {
        let mainStages = [
            TaskStage(order: 0, title: "准备与规划"),
            TaskStage(order: 1, title: "执行核心工作"),
            TaskStage(order: 2, title: "复盘与收尾")
        ]
        let mainTask = TaskItem(kind: .main, rawText: mainText, stages: mainStages)

        let sideTasks = sideTexts.map { text in
            TaskItem(kind: .side, rawText: text, stages: [
                TaskStage(order: 0, title: "启动"),
                TaskStage(order: 1, title: "完成")
            ])
        }

        return DailyPlan(date: date, mainTask: mainTask, sideTasks: sideTasks)
    }
}
#endif
