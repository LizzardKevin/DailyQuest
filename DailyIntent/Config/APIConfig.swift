import Foundation

/// 部署 Worker 后，将 `baseURLString` 改为你的 `*.workers.dev` 地址。
enum APIConfig {
    static let baseURLString = "https://daily-intent-api.dailyintent.workers.dev"

    /// 与 Worker `API_SHARED_SECRET` 一致；留空则不发送该请求头。
    static let apiSharedSecret = ""

    static var baseURL: URL {
        guard let url = URL(string: baseURLString), !baseURLString.contains("YOUR_ACCOUNT") else {
            // 开发占位：避免未配置时崩溃，请求会失败并提示用户
            return URL(string: "https://daily-intent-api.invalid.local")!
        }
        return url
    }

    /// 勿用 `appendingPathComponent("v1/breakdown")`，会把 `/` 编码成 `%2F` 导致 404。
    static var breakdownURL: URL {
        let root = baseURLString.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
        guard let url = URL(string: "\(root)/v1/breakdown") else {
            return baseURL.appending(path: "v1/breakdown")
        }
        return url
    }

    static var isConfigured: Bool {
        !baseURLString.contains("YOUR_ACCOUNT")
    }
}
