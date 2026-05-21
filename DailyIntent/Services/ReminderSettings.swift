import Foundation

enum ReminderSettings {
    private static let hourKey = "reminderHour"
    private static let minuteKey = "reminderMinute"
    private static let configuredKey = "reminderTimeConfigured"

    static var isConfigured: Bool {
        UserDefaults.standard.bool(forKey: configuredKey)
    }

    static func save(hour: Int, minute: Int) {
        UserDefaults.standard.set(hour, forKey: hourKey)
        UserDefaults.standard.set(minute, forKey: minuteKey)
    }

    static func markConfigured() {
        UserDefaults.standard.set(true, forKey: configuredKey)
    }

    static var hour: Int {
        let value = UserDefaults.standard.integer(forKey: hourKey)
        return value == 0 && !UserDefaults.standard.contains(hourKey) ? 8 : value
    }

    static var minute: Int {
        UserDefaults.standard.integer(forKey: minuteKey)
    }

    static var date: Date {
        Calendar.current.date(from: DateComponents(hour: hour, minute: minute)) ?? .now
    }
}

private extension UserDefaults {
    func contains(_ key: String) -> Bool {
        object(forKey: key) != nil
    }
}
