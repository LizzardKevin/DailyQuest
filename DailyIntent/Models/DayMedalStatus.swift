import Foundation

enum DayMedalStatus: Equatable {
    /// 无计划
    case none
    /// 有计划，主线未完成（灰点）
    case inProgress
    case base
    case holographic

    static func from(plan: DailyPlan?) -> DayMedalStatus {
        guard let plan else { return .none }
        guard let medal = plan.medal else { return .inProgress }
        return medal.hasHolographic ? .holographic : .base
    }
}
