import Foundation
import SwiftData

struct MedalAwardResult {
    let awardedBase: Bool
    let upgradedToHolographic: Bool
}

@MainActor
enum MedalService {
    static func evaluate(plan: DailyPlan, context: ModelContext) throws -> MedalAwardResult {
        guard let main = plan.mainTask, main.isCompleted else {
            return MedalAwardResult(awardedBase: false, upgradedToHolographic: false)
        }

        var awardedBase = false
        var upgraded = false

        if plan.medal == nil {
            let medal = DailyMedal(earnedAt: .now, hasHolographic: false)
            plan.medal = medal
            context.insert(medal)
            awardedBase = true
        }

        let allSidesDone = plan.sideTasks.isEmpty || plan.sideTasks.allSatisfy(\.isCompleted)
        if allSidesDone, let medal = plan.medal, !medal.hasHolographic {
            medal.hasHolographic = true
            upgraded = true
        }

        plan.updatedAt = .now
        try context.save()
        return MedalAwardResult(awardedBase: awardedBase, upgradedToHolographic: upgraded)
    }
}
