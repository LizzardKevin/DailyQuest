import SwiftUI

enum AppearanceMode: String, CaseIterable, Identifiable {
    case light
    case dark
    case system

    var id: String { rawValue }

    var title: String {
        switch self {
        case .light: return "浅色模式"
        case .dark: return "深色模式"
        case .system: return "跟随系统"
        }
    }

    /// `nil` 表示交给系统
    var preferredColorScheme: ColorScheme? {
        switch self {
        case .light: return .light
        case .dark: return .dark
        case .system: return nil
        }
    }

    func resolved(system: ColorScheme) -> ColorScheme {
        switch self {
        case .light: return .light
        case .dark: return .dark
        case .system: return system
        }
    }

    static func load() -> AppearanceMode {
        guard let raw = UserDefaults.standard.string(forKey: storageKey),
              let mode = AppearanceMode(rawValue: raw) else {
            return .system
        }
        return mode
    }

    static func save(_ mode: AppearanceMode) {
        UserDefaults.standard.set(mode.rawValue, forKey: storageKey)
    }

    private static let storageKey = "dailyquest.appearanceMode"
}
