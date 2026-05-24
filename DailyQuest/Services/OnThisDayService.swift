import Foundation

struct OnThisDayEvent: Identifiable, Equatable {
    let id: String
    let kind: Kind
    /// 公元年份；本地 fallback 与 Wikimedia 均应尽量提供。
    let year: Int?
    /// 事件描述（不含年份前缀）。
    let text: String

    /// 用于 UI 的完整一行，例如「1915 年 · 意大利对奥匈帝国宣战…」
    var formattedDescription: String {
        if let year {
            return "\(year.yearString) 年 · \(text)"
        }
        return text
    }

    /// 年份展示（无千分位逗号），例如 `1915 年`。
    var yearHeadline: String? {
        year.map { "\($0.yearString) 年" }
    }

    enum Kind: String {
        case birth
        case death
        case event

        var label: String {
            switch self {
            case .birth: return "诞辰"
            case .death: return "逝世"
            case .event: return "大事"
            }
        }
    }
}

actor OnThisDayService {
    static let shared = OnThisDayService()

    private let session: URLSession
    private var memoryCache: [String: [OnThisDayEvent]] = [:]

    init(session: URLSession = .shared) {
        self.session = session
    }

    /// 本地 fallback，不访问网络（无 VPN 时每日趣闻页应立即有内容）。
    func fallbackEvents(for date: Date = .now, maxCount: Int = 4) -> [OnThisDayEvent] {
        let cal = Calendar.current
        let month = cal.component(.month, from: date)
        let day = cal.component(.day, from: date)
        return loadFallback(month: month, day: day, maxCount: maxCount)
    }

    func events(for date: Date = .now, maxCount: Int = 4) async -> [OnThisDayEvent] {
        let cal = Calendar.current
        let month = cal.component(.month, from: date)
        let day = cal.component(.day, from: date)
        let cacheKey = String(format: "%02d-%02d", month, day)

        if let cached = memoryCache[cacheKey], !cached.isEmpty {
            return cached
        }

        let local = loadFallback(month: month, day: day, maxCount: maxCount)

        if let remote = await fetchWikimedia(month: month, day: day, maxCount: maxCount), !remote.isEmpty {
            memoryCache[cacheKey] = remote
            return remote
        }

        memoryCache[cacheKey] = local
        return local
    }

    private func fetchWikimedia(month: Int, day: Int, maxCount: Int) async -> [OnThisDayEvent]? {
        let path = String(format: "%02d/%02d", month, day)
        guard let url = URL(string: "https://api.wikimedia.org/feed/v1/wikipedia/zh/onthisday/all/\(path)") else {
            return nil
        }

        var request = URLRequest(url: url)
        request.timeoutInterval = 5
        request.setValue(
            "DailyQuest/2.0 (iOS; daily-quest-app)",
            forHTTPHeaderField: "User-Agent"
        )

        do {
            let (data, response) = try await session.data(for: request)
            guard let http = response as? HTTPURLResponse, (200...299).contains(http.statusCode) else {
                return nil
            }
            return parseWikimediaPayload(data, maxCount: maxCount)
        } catch {
            return nil
        }
    }

    private func parseWikimediaPayload(_ data: Data, maxCount: Int) -> [OnThisDayEvent]? {
        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            return nil
        }

        var collected: [OnThisDayEvent] = []

        func append(kind: OnThisDayEvent.Kind, key: String) {
            guard collected.count < maxCount,
                  let items = json[key] as? [[String: Any]] else { return }
            for item in items {
                guard collected.count < maxCount else { break }
                let text = (item["text"] as? String)?.trimmingCharacters(in: .whitespacesAndNewlines)
                guard let text, !text.isEmpty else { continue }
                let year = (item["year"] as? Int) ?? (item["year"] as? Double).map { Int($0) }
                collected.append(OnThisDayEvent(
                    id: "\(kind.rawValue)-\(collected.count)",
                    kind: kind,
                    year: year,
                    text: text
                ))
            }
        }

        append(kind: .event, key: "events")
        append(kind: .birth, key: "births")
        append(kind: .death, key: "deaths")

        return collected.isEmpty ? nil : collected
    }

    private func loadFallback(month: Int, day: Int, maxCount: Int) -> [OnThisDayEvent] {
        let key = String(format: "%02d-%02d", month, day)
        guard let url = Bundle.main.url(forResource: "on_this_day_fallback", withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let root = try? JSONDecoder().decode([String: [FallbackEntry]].self, from: data),
              let entries = root[key] ?? root["default"] else {
            return defaultInlineEvents(month: month, day: day)
        }

        return entries.prefix(maxCount).enumerated().map { index, entry in
            let parsed = entry.resolvedYearAndText()
            return OnThisDayEvent(
                id: "local-\(key)-\(index)",
                kind: OnThisDayEvent.Kind(rawValue: entry.kind) ?? .event,
                year: parsed.year,
                text: parsed.text
            )
        }
    }

    private func defaultInlineEvents(month: Int, day: Int) -> [OnThisDayEvent] {
        [
            OnThisDayEvent(
                id: "inline-1",
                kind: .event,
                year: Calendar.current.component(.year, from: .now),
                text: "\(month)月\(day)日：每一天都是新的任务日，写下今天最重要的一件事吧。"
            )
        ]
    }

    private struct FallbackEntry: Decodable {
        let kind: String
        let year: Int?
        let text: String

        func resolvedYearAndText() -> (year: Int?, text: String) {
            (year, text)
        }
    }
}

extension Int {
    /// 年份等整数展示：避免 SwiftUI `Text("\(year)")` 在部分语言下变成 `2,000`。
    var yearString: String {
        String(self)
    }
}
