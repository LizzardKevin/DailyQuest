import Foundation

/// 部署 Worker 后，将 `baseURLString` 改为你的 `*.workers.dev` 地址。
enum APIConfig {
    /// 部署 `daily-quest-api` 后替换为实际 URL，例如 `https://daily-quest-api.<account>.workers.dev`
    static let baseURLString = "https://daily-quest-api.dailyintent.workers.dev"

    /// 与 Worker `API_SHARED_SECRET` 一致；留空则不发送该请求头。
    static let apiSharedSecret = ""

    static var baseURL: URL {
        guard let url = URL(string: baseURLString), !baseURLString.contains("YOUR_ACCOUNT") else {
            return URL(string: "https://daily-quest-api.invalid.local")!
        }
        return url
    }

    static var breakdownURL: URL {
        apiURL(path: "v1/breakdown")
    }

    static var medalDesignURL: URL {
        apiURL(path: "v1/medal/design")
    }

    private static func apiURL(path: String) -> URL {
        let root = baseURLString.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
        guard let url = URL(string: "\(root)/\(path)") else {
            return baseURL.appending(path: path)
        }
        return url
    }

    static var isConfigured: Bool {
        !baseURLString.contains("YOUR_ACCOUNT")
    }
}
