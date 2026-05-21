import Foundation

enum DateHelpers {
    static let calendar = Calendar.current

    /// 任务日起点（04:00 换日），计划与日历状态均使用此边界。
    static func startOfDay(_ date: Date) -> Date {
        QuestDayCalendar.questDayStart(for: date)
    }

    static func isSameDay(_ lhs: Date, _ rhs: Date) -> Bool {
        QuestDayCalendar.isSameQuestDay(lhs, rhs)
    }

    /// 日历格子的自然日（通常为 00:00）映射到存储用的任务日锚点。
    /// 避免在 04:00 换日边界处，午夜时刻被算到前一天任务日。
    static func questDayAnchor(forCalendarDay date: Date) -> Date {
        var components = calendar.dateComponents([.year, .month, .day], from: date)
        components.hour = 12
        components.minute = 0
        components.second = 0
        let midday = calendar.date(from: components) ?? date
        return QuestDayCalendar.questDayStart(for: midday)
    }

    static func monthInterval(containing date: Date) -> DateInterval? {
        calendar.dateInterval(of: .month, for: date)
    }

    static func daysInMonth(containing date: Date) -> [Date] {
        guard let interval = monthInterval(containing: date),
              let range = calendar.range(of: .day, in: .month, for: date) else {
            return []
        }
        return range.compactMap { day -> Date? in
            calendar.date(byAdding: .day, value: day - 1, to: interval.start)
        }
    }

    static func weekdayHeaders() -> [String] {
        ["日", "一", "二", "三", "四", "五", "六"]
    }

    static func leadingBlankDays(in month: Date) -> Int {
        guard let interval = monthInterval(containing: month) else { return 0 }
        let weekday = calendar.component(.weekday, from: interval.start)
        return weekday - 1
    }

    static func formattedMonth(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "zh_CN")
        formatter.dateFormat = "yyyy年M月"
        return formatter.string(from: date)
    }

    static func formattedDay(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "zh_CN")
        formatter.dateFormat = "M月d日 EEEE"
        return formatter.string(from: date)
    }
}
