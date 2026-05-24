import Foundation
import SwiftData

/// 预留：iCloud 同步实现将包装 `LocalDailyPlanRepository`。
protocol SyncDailyPlanRepository: DailyPlanRepository {
    var isSyncEnabled: Bool { get }
    func syncIfNeeded(context: ModelContext) async throws
}
