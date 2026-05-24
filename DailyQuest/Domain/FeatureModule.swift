import SwiftUI

/// 预留：未来可注册额外 Tab、设置区块或活动模块。
protocol FeatureModule {
    var id: String { get }
    var displayName: String { get }
}

enum FeatureModuleRegistry {
    static let modules: [any FeatureModule] = []
}
