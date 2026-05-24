import Foundation

#if DEBUG
enum MedalDesignCodecTests {
    static func run() {
        let design = MedalDesign(
            questDayKey: "2026-05-23",
            schemaVersion: 1,
            title: "测试奖牌",
            subtitle: "副标题",
            themeTags: ["test"],
            visual: MedalVisualSpec(
                symbolName: "star.fill",
                palette: MedalPalette(
                    primaryHex: "#C45C26",
                    secondaryHex: "#E8A87C",
                    accentHex: "#F4D03F"
                ),
                pattern: "seal"
            ),
            source: .ai,
            createdAt: .now
        )
        assert(MedalDesignCodec.encode(design) != nil)
        assert(MedalDesignCodec.decode(MedalDesignCodec.encode(design)) == design)
        assert(MedalSymbolValidator.resolve("invalid.symbol") == "seal.fill")
    }
}
#endif
