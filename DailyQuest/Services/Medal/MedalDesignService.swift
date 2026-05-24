import Foundation
import SwiftData

@MainActor
enum MedalDesignService {
    private static let provider: MedalDesignProviding = BackendMedalDesignClient()

    static func attachDesign(
        to plan: DailyPlan,
        triviaTitle: String? = nil,
        triviaYear: Int? = nil,
        forceRegenerate: Bool = false,
        context: ModelContext
    ) async throws {
        let questDayKey = QuestDayCalendar.questDayKey(for: plan.date)
        let mainText = plan.mainTask?.rawText ?? ""
        let sides = plan.sideTasks.map(\.rawText)

        let design = try await provider.generateDesign(
            questDayKey: questDayKey,
            mainTask: mainText,
            sideTasks: sides,
            triviaTitle: triviaTitle,
            triviaYear: triviaYear,
            forceRegenerate: forceRegenerate
        )

        plan.medalDesignJSON = MedalDesignCodec.encode(design)
        plan.updatedAt = .now
        try context.save()
    }

    static func design(for plan: DailyPlan) -> MedalDesign? {
        MedalDesignCodec.decode(plan.medalDesignJSON)
    }
}
