import Foundation

extension Notification.Name {
    static let dailyPlanDidChange = Notification.Name("dailyPlanDidChange")
}

enum AppNotificationPoster {
    static func planDidChange() {
        NotificationCenter.default.post(name: .dailyPlanDidChange, object: nil)
    }
}
