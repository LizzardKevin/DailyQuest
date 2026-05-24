import Foundation

#if DEBUG
enum QuestDayCalendarTests {
    static func run() {
        testQuestDayAnchorIdempotent()
        testQuestDayStartFromNowIsAnchorStable()
    }

    private static func testQuestDayAnchorIdempotent() {
        var components = DateComponents()
        components.year = 2026
        components.month = 5
        components.day = 25
        components.hour = 0
        components.minute = 0
        components.second = 0
        let midnight = Calendar.current.date(from: components)!
        let once = QuestDayCalendar.questDayStart(for: midnight)
        let twice = QuestDayCalendar.questDayStart(for: once)
        assert(once == twice, "quest day anchor must not shift backward on second normalization")
        assert(QuestDayCalendar.isStoredQuestDayAnchor(once), "midnight anchor should be detected")
    }

    private static func testQuestDayStartFromNowIsAnchorStable() {
        let start = QuestDayCalendar.questDayStart(for: .now)
        let again = QuestDayCalendar.questDayStart(for: start)
        assert(start == again, "quest day start for current day must be stable")
        assert(
            QuestDayCalendar.questDayKey(for: start) == QuestDayCalendar.questDayKey(),
            "saved anchor must belong to current quest day"
        )
    }
}
#endif
