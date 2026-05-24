import Foundation
import SwiftData

extension Notification.Name {
    static let dailyPlanDidChange = Notification.Name("dailyPlanDidChange")
}

enum AppNotificationPoster {
    static let planIDUserInfoKey = "planPersistentID"

    static func planDidChange(planID: PersistentIdentifier? = nil) {
        let userInfo = planID.map { [Self.planIDUserInfoKey: $0] as [AnyHashable: Any] }
        NotificationCenter.default.post(
            name: .dailyPlanDidChange,
            object: nil,
            userInfo: userInfo
        )
    }
}
