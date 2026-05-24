import SwiftUI

/// 预留：未来支持 CDN / AI 生图 URL 的奖牌渲染。
protocol RemoteAssetMedalRenderer {
    func view(assetURL: URL, tier: MedalTier, size: CGFloat) -> AnyView
}

enum RemoteAssetMedalRendererPlaceholder: RemoteAssetMedalRenderer {
    func view(assetURL: URL, tier: MedalTier, size: CGFloat) -> AnyView {
        AnyView(MedalView(status: tier == .holographic ? .holographic : .base, size: size))
    }
}
