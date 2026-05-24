import Foundation

protocol MedalDesignProviding {
    func generateDesign(
        questDayKey: String,
        mainTask: String,
        sideTasks: [String],
        triviaTitle: String?,
        triviaYear: Int?,
        forceRegenerate: Bool
    ) async throws -> MedalDesign
}
