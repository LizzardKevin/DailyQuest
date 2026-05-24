import Foundation

struct BackendMedalDesignClient: MedalDesignProviding {
    private let session: URLSession
    private let fallback = FallbackMedalDesignProvider()

    init(session: URLSession = .shared) {
        self.session = session
    }

    func generateDesign(
        questDayKey: String,
        mainTask: String,
        sideTasks: [String],
        triviaTitle: String?,
        triviaYear: Int?,
        forceRegenerate: Bool
    ) async throws -> MedalDesign {
        guard APIConfig.isConfigured else {
            return try await fallback.generateDesign(
                questDayKey: questDayKey,
                mainTask: mainTask,
                sideTasks: sideTasks,
                triviaTitle: triviaTitle,
                triviaYear: triviaYear,
                forceRegenerate: forceRegenerate
            )
        }

        do {
            return try await request(
                questDayKey: questDayKey,
                mainTask: mainTask,
                sideTasks: sideTasks,
                triviaTitle: triviaTitle,
                triviaYear: triviaYear,
                forceRegenerate: forceRegenerate
            )
        } catch {
            return try await fallback.generateDesign(
                questDayKey: questDayKey,
                mainTask: mainTask,
                sideTasks: sideTasks,
                triviaTitle: triviaTitle,
                triviaYear: triviaYear,
                forceRegenerate: forceRegenerate
            )
        }
    }

    private func request(
        questDayKey: String,
        mainTask: String,
        sideTasks: [String],
        triviaTitle: String?,
        triviaYear: Int?,
        forceRegenerate: Bool
    ) async throws -> MedalDesign {
        var request = URLRequest(url: APIConfig.medalDesignURL)
        request.httpMethod = "POST"
        request.timeoutInterval = 40
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(DeviceIDService.shared.deviceID, forHTTPHeaderField: "X-Device-ID")
        request.setValue(questDayKey, forHTTPHeaderField: "X-Quest-Day")

        let secret = APIConfig.apiSharedSecret
        if !secret.isEmpty {
            request.setValue(secret, forHTTPHeaderField: "X-API-Secret")
        }

        var body: [String: Any] = [
            "mainTask": mainTask,
            "sideTasks": sideTasks,
            "questDay": questDayKey,
            "forceRegenerate": forceRegenerate
        ]
        if let triviaTitle, !triviaTitle.isEmpty {
            body["triviaTitle"] = triviaTitle
        }
        if let triviaYear {
            body["triviaYear"] = triviaYear
        }
        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response) = try await session.data(for: request)
        guard let http = response as? HTTPURLResponse else {
            throw MedalDesignError.network
        }

        if !(200...299).contains(http.statusCode) {
            if let err = try? JSONDecoder().decode(APIErrorBody.self, from: data) {
                throw MedalDesignError.server(err.error)
            }
            throw MedalDesignError.network
        }

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try decoder.decode(MedalDesign.self, from: data)
    }
}

enum MedalDesignError: LocalizedError {
    case network
    case server(String)

    var errorDescription: String? {
        switch self {
        case .network: return "奖牌设计服务暂时不可用"
        case .server(let msg): return msg
        }
    }
}

private struct APIErrorBody: Decodable {
    let error: String
}
