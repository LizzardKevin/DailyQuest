import Foundation

/// 任务日：本地时间每天 04:00 切换为新的一天。
enum QuestDayCalendar {
    static let rolloverHour = 4

    private static var calendar: Calendar { .current }

    /// 给定时刻所属的任务日起点（当日 04:00 或昨日 04:00 起算）。
    static func questDayStart(for date: Date = .now) -> Date {
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
