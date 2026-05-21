import Foundation

/// 生涯仅展示一次的轻提示。
enum LightPromptStore {
    enum Key: String, CaseIterable {
        case dailySwipe = "lightPrompt.dailySwipe"
        case questPage = "lightPrompt.questPage"
        case mainTabs = "lightPrompt.mainTabs"
        case settingsModify = "lightPrompt.settingsModify"
        case reminderSetup = "lightPrompt.reminderSetup"
    }

    static func hasSeen(_ key: Key) -> Bool {
        UserDefaults.standard.bool(forKey: key.rawValue)
    }

    static func markSeen(_ key: Key) {
        UserDefaults.standard.set(true, forKey: key.rawValue)
    }
}
