import Foundation

/// 任务日：本地时间每天 04:00 切换为新的一天。
enum QuestDayCalendar {
    static let rolloverHour = 4

    private static var calendar: Calendar { .current }

    /// 给定时刻所属的任务日起点（当日 04:00 或昨日 04:00 起算）。
    static func questDayStart(for date: Date = .now) -> Date {
        if isStoredQuestDayAnchor(date) {
            return date
        }
        return questDayStartFromInstant(date)
    }

    /// 已是 `DailyPlan.date` 这类午夜锚点时，避免二次归一化回退到前一天。
    static func isStoredQuestDayAnchor(_ date: Date) -> Bool {
        let components = calendar.dateComponents([.year, .month, .day, .hour, .minute, .second], from: date)
        guard components.hour == 0, components.minute == 0, components.second == 0 else {
            return false
        }
        return questDayStartFromInstant(date) != date
    }

    private static func questDayStartFromInstant(_ date: Date) -> Date {
        guard let shifted = calendar.date(byAdding: .hour, value: -rolloverHour, to: date) else {
            return calendar.startOfDay(for: date)
        }
        return calendar.startOfDay(for: shifted)
    }

    static func questDayKey(for date: Date = .now) -> String {
        let day = questDayStart(for: date)
        let formatter = DateFormatter()
        formatter.calendar = calendar
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = calendar.timeZone
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: day)
    }

    static func isSameQuestDay(_ lhs: Date, _ rhs: Date) -> Bool {
        questDayStart(for: lhs) == questDayStart(for: rhs)
    }

    static func isFutureQuestDay(_ date: Date) -> Bool {
        questDayStart(for: date) > questDayStart(for: .now)
    }

    static func isCurrentQuestDay(_ date: Date) -> Bool {
        isSameQuestDay(date, .now)
    }
}
