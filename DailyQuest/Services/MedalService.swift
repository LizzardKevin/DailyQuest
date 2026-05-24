import Foundation
import SwiftData

struct MedalAwardResult {
    let awardedBase: Bool
    let upgradedToHolographic: Bool
}

@MainActor
enum MedalService {
    static func evaluate(plan: DailyPlan, context: ModelContext) throws -> MedalAwardResult {
        var awardedBase = false
        var upgraded = false

        guard let main = plan.mainTask, main.isCompleted else {
            if plan.medal != nil {
                removeMedal(from: plan, context: context)
            }
            plan.updatedAt = .now
            try context.save()
            return MedalAwardResult(awardedBase: false, upgradedToHolographic: false)
        }

        if plan.medal == nil {
            let medal = DailyMedal(earnedAt: .now, hasHolographic: false)
            plan.medal = medal
            context.insert(medal)
            awardedBase = true
        }

        let allSidesDone = plan.sideTasks.isEmpty || plan.sideTasks.allSatisfy(\.isCompleted)
        if let medal = plan.medal {
            if allSidesDone, !medal.hasHolographic {
                medal.hasHolographic = true
                upgraded = true
            } else if !allSidesDone, medal.hasHolographic {
                medal.hasHolographic = false
            }
        }

        plan.updatedAt = .now
        try context.save()
        return MedalAwardResult(awardedBase: awardedBase, upgradedToHolographic: upgraded)
    }

    private static func removeMedal(from plan: DailyPlan, context: ModelContext) {
        if let medal = plan.medal {
            context.delete(medal)
        }
        plan.medal = nil
    }
}
