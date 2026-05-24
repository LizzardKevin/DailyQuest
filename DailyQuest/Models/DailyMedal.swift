import Foundation
import SwiftData

@Model
final class DailyMedal {
    var earnedAt: Date
    var hasHolographic: Bool

    init(earnedAt: Date = .now, hasHolographic: Bool = false) {
        self.earnedAt = earnedAt
        self.hasHolographic = hasHolographic
    }
}
