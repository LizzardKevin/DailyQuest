import Foundation
import UserNotifications

final class NotificationService: NSObject {
    static let shared = NotificationService()

    private let center = UNUserNotificationCenter.current()
    private let reminderIdentifier = "daily-quest-morning"

    private override init() {
        super.init()
    }

    func registerCategories() {
        center.setNotificationCategories([])
    }

    func requestAuthorization() async -> Bool {
        do {
            return try await center.requestAuthorization(options: [.alert, .sound, .badge])
        } catch {
            return false
        }
    }

    func authorizationStatus() async -> UNAuthorizationStatus {
        let settings = await center.notificationSettings()
        return settings.authorizationStatus
    }

    func scheduleDailyReminder(hour: Int, minute: Int) async throws {
        let granted = await requestAuthorization()
        guard granted else {
            throw NotificationError.notAuthorized
        }

        center.removePendingNotificationRequests(withIdentifiers: [reminderIdentifier])

        var dateComponents = DateComponents()
        dateComponents.hour = hour
        dateComponents.minute = minute

        let content = UNMutableNotificationContent()
        content.title = "每日任务"
        content.body = "今天的任务是什么？点开领取你的一天"
        content.sound = .default

        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
        let request = UNNotificationRequest(identifier: reminderIdentifier, content: content, trigger: trigger)
        try await center.add(request)
    }

    func cancelReminder() {
        center.removePendingNotificationRequests(withIdentifiers: [reminderIdentifier])
    }
}

enum NotificationError: LocalizedError {
    case notAuthorized

    var errorDescription: String? {
        switch self {
        case .notAuthorized:
            return "请在系统设置中允许通知权限"
        }
    }
}
