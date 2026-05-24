import Foundation

/// 环饰元素与 SF Symbol 映射；AI / fallback 的 `kind` 须在此表或回退为 `bead`。
enum MedalRingCatalog {
    static let defaultKinds = ["bead", "leaf", "vine", "pearl", "wheat", "star"]

    private static let kindToSymbol: [String: String] = [
        "bead": "circle.fill",
        "pearl": "circle.circle.fill",
        "wheat": "leaf.fill",
        "vine": "leaf.arrow.triangle.circlepath",
        "leaf": "leaf.fill",
        "branch": "tree.fill",
        "flower": "camera.macro",
        "star": "star.fill",
        "sparkle": "sparkles",
        "flame": "flame.fill",
        "droplet": "drop.fill",
        "ribbon": "gift.fill",
        "moon": "moon.fill",
        "sun": "sun.max.fill",
        "bolt": "bolt.fill",
        "heart": "heart.fill",
        "book": "book.fill",
        "crown": "crown.fill",
        "flag": "flag.fill",
        "circle": "circle.fill",
        "diamond": "diamond.fill",
        "seal": "seal.fill"
    ]

    static func normalizedKind(_ raw: String) -> String {
        let key = raw.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        return kindToSymbol[key] != nil ? key : "bead"
    }

    static func symbol(for kind: String) -> String {
        kindToSymbol[normalizedKind(kind)] ?? "circle.fill"
    }

    /// 由中心图案与色板推导一圈环饰（用于 v1 迁移与 fallback）。
    static func ringElements(matching centerSymbol: String, palette: MedalPalette) -> [MedalRingElement] {
        let seed = centerSymbol.hashValue ^ palette.primaryHex.hashValue
        var kinds = themedKinds(for: centerSymbol)
        if kinds.count < 6 {
            kinds.append(contentsOf: defaultKinds)
        }
        var rng = SeededRNG(seed: UInt64(bitPattern: Int64(seed)))
        var picked: [String] = []
        while picked.count < 8 {
            let k = kinds[Int(rng.next() % UInt64(kinds.count))]
            if !picked.contains(k) {
                picked.append(k)
            }
            if picked.count >= 6, rng.next() % 3 == 0 { break }
        }
        return picked.map { MedalRingElement(kind: $0) }
    }

    static func ringElements(forMainTask mainTask: String, triviaTitle: String?) -> [MedalRingElement] {
        let text = (mainTask + (triviaTitle ?? "")).lowercased()
        var kinds: [String] = []
        if text.contains("跑") || text.contains("运动") || text.contains("健身") {
            kinds += ["flame", "leaf", "bolt", "vine"]
        }
        if text.contains("读") || text.contains("书") || text.contains("学") {
            kinds += ["book", "star", "bead", "moon"]
        }
        if text.contains("写") || text.contains("代码") || text.contains("工作") {
            kinds += ["bolt", "star", "circle", "sparkle"]
        }
        if text.contains("吃") || text.contains("煮") || text.contains("餐") {
            kinds += ["flame", "leaf", "droplet", "wheat"]
        }
        if kinds.isEmpty {
            kinds = defaultKinds
        }
        while kinds.count < 6 {
            kinds.append(defaultKinds[kinds.count % defaultKinds.count])
        }
        return Array(kinds.prefix(8)).map { MedalRingElement(kind: $0) }
    }

    private static func themedKinds(for centerSymbol: String) -> [String] {
        switch centerSymbol {
        case "figure.walk", "figure.run":
            return ["vine", "leaf", "flame", "bolt", "bead", "star"]
        case "book.fill":
            return ["star", "moon", "bead", "ribbon", "leaf", "sparkle"]
        case "flame.fill":
            return ["flame", "sun", "bolt", "bead", "star", "leaf"]
        case "leaf.fill":
            return ["wheat", "vine", "leaf", "flower", "pearl", "droplet"]
        case "heart.fill":
            return ["heart", "ribbon", "pearl", "star", "bead", "flower"]
        default:
            return defaultKinds
        }
    }
}

private struct SeededRNG {
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
