import Foundation

/// 断网或 AI 失败时：按任务日种子生成稳定且每日不同的模板奖牌。
struct FallbackMedalDesignProvider: MedalDesignProviding {
    private static let centerSymbols = [
        "seal.fill", "star.fill", "flame.fill", "leaf.fill", "bolt.fill",
        "moon.stars.fill", "sun.max.fill", "sparkles", "crown.fill", "flag.fill",
        "book.fill", "figure.walk", "heart.fill", "globe.americas.fill", "wand.and.stars",
        "figure.run", "cup.and.saucer.fill", "pencil", "lightbulb.fill"
    ]

    private static let palettes: [(String, String, String)] = [
        ("#C45C26", "#E8A87C", "#F4D03F"),
        ("#2E86AB", "#A23B72", "#F18F01"),
        ("#588157", "#3A5A40", "#A3B18A"),
        ("#6D597A", "#B56576", "#E56B6F"),
        ("#BC6C25", "#DDA15E", "#FEFAE0"),
        ("#1B4965", "#62B6CB", "#CAE9FF"),
        ("#7F5539", "#B08968", "#E6CCB2"),
        ("#9B2226", "#AE2012", "#EE9B00")
    ]

    func generateDesign(
        questDayKey: String,
        mainTask: String,
        sideTasks: [String],
        triviaTitle: String?,
        triviaYear: Int?,
        forceRegenerate: Bool
    ) async throws -> MedalDesign {
        let seed = questDayKey.hashValue ^ mainTask.hashValue ^ (forceRegenerate ? 0x9E37 : 0)
        var rng = SeededGenerator(seed: UInt64(bitPattern: Int64(seed)))

        let centerObject = Self.centerSymbols[Int(rng.next() % UInt64(Self.centerSymbols.count))]
        let palette = Self.palettes[Int(rng.next() % UInt64(Self.palettes.count))]
        let ring = MedalRingCatalog.ringElements(forMainTask: mainTask, triviaTitle: triviaTitle)

        let title: String
        if let triviaTitle, !triviaTitle.isEmpty {
            let year = triviaYear.map { String($0) } ?? ""
            title = year.isEmpty ? triviaTitle : "\(year) · \(triviaTitle)"
        } else {
            title = "探索 · \(questDayKey.suffix(5))"
        }

        let subtitle = mainTask.prefix(40) + (mainTask.count > 40 ? "…" : "")

        return MedalDesign(
            questDayKey: questDayKey,
            schemaVersion: MedalDesign.currentSchemaVersion,
            title: String(title.prefix(60)),
            subtitle: String(subtitle),
            themeTags: ["fallback", "daily"],
            visual: MedalVisualSpec(
                ringElements: ring,
                centerFillHex: palette.1,
                centerObjectSymbol: centerObject,
                palette: MedalPalette(
                    primaryHex: palette.0,
                    secondaryHex: palette.1,
                    accentHex: palette.2
                )
            ),
            source: .fallbackTemplate,
            createdAt: .now
        )
    }
}

private struct SeededGenerator {
    private var state: UInt64

    init(seed: UInt64) {
        state = seed == 0 ? 1 : seed
    }

    mutating func next() -> UInt64 {
        state ^= state >> 12
        state ^= state << 25
        state ^= state >> 27
        return state &* 2685821657736338717
    }
}
