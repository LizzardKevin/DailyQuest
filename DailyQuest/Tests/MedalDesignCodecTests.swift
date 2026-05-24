import Foundation

#if DEBUG
enum MedalDesignCodecTests {
    static func run() {
        let design = MedalDesign(
            questDayKey: "2026-05-23",
            schemaVersion: 2,
            title: "测试奖牌",
            subtitle: "副标题",
            themeTags: ["test"],
            visual: MedalVisualSpec(
                ringElements: [
                    MedalRingElement(kind: "wheat"),
                    MedalRingElement(kind: "vine"),
                    MedalRingElement(kind: "bead"),
                    MedalRingElement(kind: "pearl"),
                    MedalRingElement(kind: "leaf"),
                    MedalRingElement(kind: "star")
                ],
                centerFillHex: "#A3B18A",
                centerObjectSymbol: "leaf.fill",
                palette: MedalPalette(
                    primaryHex: "#588157",
                    secondaryHex: "#A3B18A",
                    accentHex: "#3A5A40"
                )
            ),
            source: .ai,
            createdAt: .now
        )
        assert(MedalDesignCodec.encode(design) != nil)
        assert(MedalDesignCodec.decode(MedalDesignCodec.encode(design)) == design)
        assert(MedalSymbolValidator.resolve("invalid.symbol") == "seal.fill")

        let legacyJSON = """
        {"questDayKey":"2026-05-23","schemaVersion":1,"title":"旧版","themeTags":[],"visual":{"symbolName":"star.fill","palette":{"primaryHex":"#C45C26","secondaryHex":"#E8A87C","accentHex":"#F4D03F"}},"source":"ai","createdAt":"2026-05-23T00:00:00Z"}
        """
        let migrated = MedalDesignCodec.decode(legacyJSON)
        assert(migrated?.visual.centerObjectSymbol == "star.fill")
        assert(migrated?.visual.ringElements.count ?? 0 >= 4)
    }
}
#endif
