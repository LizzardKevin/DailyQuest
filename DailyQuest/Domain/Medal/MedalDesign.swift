import Foundation
import SwiftUI

enum MedalDesignSource: String, Codable, Equatable {
    case ai
    case fallbackTemplate
}

enum MedalTier: Equatable {
    case base
    case holographic
}

struct MedalPalette: Codable, Equatable {
    var primaryHex: String
    var secondaryHex: String
    var accentHex: String

    var primary: Color { Color(hex: primaryHex) ?? AppTheme.mainAccent }
    var secondary: Color { Color(hex: secondaryHex) ?? AppTheme.sideAccent }
    var accent: Color { Color(hex: accentHex) ?? AppTheme.mainAccent }
}

struct MedalVisualSpec: Codable, Equatable {
    var symbolName: String
    var palette: MedalPalette
    var pattern: String?
}

struct MedalDesign: Codable, Equatable {
    var questDayKey: String
    var schemaVersion: Int
    var title: String
    var subtitle: String?
    var themeTags: [String]
    var visual: MedalVisualSpec
    var source: MedalDesignSource
    var createdAt: Date

    static let currentSchemaVersion = 1
}

enum MedalDesignCodec {
    static func encode(_ design: MedalDesign) -> String? {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        guard let data = try? encoder.encode(design) else { return nil }
        return String(data: data, encoding: .utf8)
    }

    static func decode(_ json: String?) -> MedalDesign? {
        guard let json, let data = json.data(using: .utf8) else { return nil }
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try? decoder.decode(MedalDesign.self, from: data)
    }
}

extension Color {
    init?(hex: String) {
        var raw = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        if raw.hasPrefix("#") { raw.removeFirst() }
        guard raw.count == 6, let value = UInt64(raw, radix: 16) else { return nil }
        let r = Double((value >> 16) & 0xFF) / 255
        let g = Double((value >> 8) & 0xFF) / 255
        let b = Double(value & 0xFF) / 255
        self.init(red: r, green: g, blue: b)
    }
}
