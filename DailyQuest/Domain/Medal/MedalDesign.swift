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

struct MedalRingElement: Codable, Equatable, Identifiable {
    var kind: String

    var id: String { kind }
}

struct MedalPalette: Codable, Equatable {
    var primaryHex: String
    var secondaryHex: String
    var accentHex: String

    var primary: Color { Color(hex: primaryHex) ?? AppTheme.mainAccent }
    var secondary: Color { Color(hex: secondaryHex) ?? AppTheme.sideAccent }
    var accent: Color { Color(hex: accentHex) ?? AppTheme.mainAccent }
}

/// 奖牌视觉：外环饰 + 中心底色圆 + 中心物件（schema v2）。
struct MedalVisualSpec: Codable, Equatable {
    /// 环绕外圈的装饰元素（珠子、麦穗、藤蔓等），建议 6–8 个。
    var ringElements: [MedalRingElement]
    /// 中心圆背景色，应呼应任务/历史上的今天主题色。
    var centerFillHex: String
    /// 中心物件 SF Symbol，由主线任务语义决定。
    var centerObjectSymbol: String
    var palette: MedalPalette

    var centerFill: Color { Color(hex: centerFillHex) ?? palette.primary }

    var resolvedRingElements: [MedalRingElement] {
        ringElements.isEmpty
            ? MedalRingCatalog.defaultKinds.map { MedalRingElement(kind: $0) }
            : ringElements
    }

    enum CodingKeys: String, CodingKey {
        case ringElements
        case centerFillHex
        case centerObjectSymbol
        case palette
        case symbolName
        case pattern
    }

    init(
        ringElements: [MedalRingElement],
        centerFillHex: String,
        centerObjectSymbol: String,
        palette: MedalPalette
    ) {
        self.ringElements = ringElements
        self.centerFillHex = centerFillHex
        self.centerObjectSymbol = MedalSymbolValidator.resolve(centerObjectSymbol)
        self.palette = palette
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        palette = try container.decode(MedalPalette.self, forKey: .palette)

        if let ring = try container.decodeIfPresent([MedalRingElement].self, forKey: .ringElements),
           !ring.isEmpty,
           let fill = try container.decodeIfPresent(String.self, forKey: .centerFillHex),
           let object = try container.decodeIfPresent(String.self, forKey: .centerObjectSymbol) {
            ringElements = ring.map { MedalRingElement(kind: MedalRingCatalog.normalizedKind($0.kind)) }
            centerFillHex = fill
            centerObjectSymbol = MedalSymbolValidator.resolve(object)
        } else if let legacySymbol = try container.decodeIfPresent(String.self, forKey: .symbolName) {
            let symbol = MedalSymbolValidator.resolve(legacySymbol)
            centerObjectSymbol = symbol
            centerFillHex = palette.primaryHex
            ringElements = MedalRingCatalog.ringElements(matching: symbol, palette: palette)
        } else {
            centerObjectSymbol = "seal.fill"
            centerFillHex = palette.primaryHex
            ringElements = MedalRingCatalog.defaultKinds.map { MedalRingElement(kind: $0) }
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(ringElements, forKey: .ringElements)
        try container.encode(centerFillHex, forKey: .centerFillHex)
        try container.encode(centerObjectSymbol, forKey: .centerObjectSymbol)
        try container.encode(palette, forKey: .palette)
    }
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

    static let currentSchemaVersion = 2
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
