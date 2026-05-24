import Foundation

struct BackendBreakdownClient: TaskBreakdownProviding {
    private let session: URLSession
    private let maxRetries = 2

    init(session: URLSession = .shared) {
        self.session = session
    }

    func breakdown(
        mainTask: String,
        sideTasks: [String],
        clarificationAnswer: String?,
        clarificationAttempt: Int
    ) async throws -> BreakdownResult {
        guard APIConfig.isConfigured else {
            throw BreakdownValidationError.apiError(
                "服务端地址未配置。请在 APIConfig.swift 填入 Worker 部署 URL。"
            )
        }

        var lastError: Error = BreakdownValidationError.invalidJSON
        for attempt in 0...maxRetries {
            do {
                return try await request(
                    mainTask: mainTask,
                    sideTasks: sideTasks,
                    clarificationAnswer: clarificationAnswer,
                    clarificationAttempt: clarificationAttempt
                )
            } catch let error as BreakdownValidationError {
                switch error {
                case .apiError, .sidesCountMismatch, .emptyMain, .emptySide:
                    throw error
                case .invalidJSON:
                    lastError = error
                }
                if attempt < maxRetries {
                    try await Task.sleep(nanoseconds: UInt64(500_000_000 * (attempt + 1)))
                }
            } catch {
                lastError = mapNetworkError(error)
                if attempt < maxRetries {
                    try await Task.sleep(nanoseconds: UInt64(500_000_000 * (attempt + 1)))
                }
            }
        }
        throw mapNetworkError(lastError)
    }

    private func mapNetworkError(_ error: Error) -> Error {
        if let breakdown = error as? BreakdownValidationError {
            return breakdown
        }
        if let urlError = error as? URLError {
            switch urlError.code {
            case .notConnectedToInternet:
                return BreakdownValidationError.apiError("未连接互联网，请检查模拟器/本机网络")
            case .cannotFindHost, .cannotConnectToHost, .dnsLookupFailed:
                return BreakdownValidationError.apiError(
                    "无法连接服务器。请在 Mac 浏览器打开 \(APIConfig.baseURLString)/health 检查；若打不开，需部署自己的 Worker 或检查网络/VPN"
                )
            case .timedOut:
                return BreakdownValidationError.apiError("连接超时，请稍后重试")
            case .secureConnectionFailed:
                return BreakdownValidationError.apiError("安全连接失败，请确认 Worker 地址为 https")
            default:
                return BreakdownValidationError.apiError("网络错误：\(urlError.localizedDescription)")
            }
        }
        return error
    }

    private func request(
        mainTask: String,
        sideTasks: [String],
        clarificationAnswer: String?,
        clarificationAttempt: Int
    ) async throws -> BreakdownResult {
        var request = URLRequest(url: APIConfig.breakdownURL)
        request.httpMethod = "POST"
        request.timeoutInterval = 35
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(DeviceIDService.shared.deviceID, forHTTPHeaderField: "X-Device-ID")
        request.setValue(QuestDayCalendar.questDayKey(), forHTTPHeaderField: "X-Quest-Day")

        let secret = APIConfig.apiSharedSecret
        if !secret.isEmpty {
            request.setValue(secret, forHTTPHeaderField: "X-API-Secret")
        }

        var body: [String: Any] = [
            "mainTask": mainTask,
            "sideTasks": sideTasks,
            "clarificationAttempt": clarificationAttempt
        ]
        if let clarificationAnswer, !clarificationAnswer.isEmpty {
            body["clarificationAnswer"] = clarificationAnswer
        }
        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response) = try await session.data(for: request)
        guard let http = response as? HTTPURLResponse else {
            throw BreakdownValidationError.apiError("网络响应无效")
        }

        if http.statusCode == 429 {
            throw BreakdownValidationError.apiError("今日拆解次数已用完，请明天再试")
        }

        if http.statusCode == 422 {
            if let err = try? JSONDecoder().decode(APIErrorBody.self, from: data) {
                throw BreakdownValidationError.apiError(err.error)
            }
            throw BreakdownValidationError.invalidJSON
        }

        guard (200...299).contains(http.statusCode) else {
            if let err = try? JSONDecoder().decode(APIErrorBody.self, from: data) {
                throw BreakdownValidationError.apiError(err.error)
            }
            throw BreakdownValidationError.apiError("服务暂时不可用，请稍后重试")
        }

        return try parseEnvelope(data: data, expectedSideCount: sideTasks.count)
    }

    private func parseEnvelope(data: Data, expectedSideCount: Int) throws -> BreakdownResult {
        if let envelope = try? JSONDecoder().decode(BreakdownEnvelopeDTO.self, from: data) {
            switch envelope {
            case .clarification(let question, let attempt):
                return .needsClarification(
                    BreakdownClarificationPrompt(question: question, attempt: attempt)
                )
            case .breakdown(let response):
                let validated = try response.validated(expectedSideCount: expectedSideCount)
                return .ready(validated)
            }
        }

        do {
            let legacy = try JSONDecoder().decode(TaskBreakdownResponse.self, from: data)
            let validated = try legacy.validated(expectedSideCount: expectedSideCount)
            return .ready(validated)
        } catch {
            throw BreakdownValidationError.invalidJSON
        }
    }
}

private enum BreakdownEnvelopeDTO: Decodable {
    case breakdown(TaskBreakdownResponse)
    case clarification(question: String, attempt: Int)

    private enum CodingKeys: String, CodingKey {
        case type, question, attempt, main, sides
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let type = try container.decodeIfPresent(String.self, forKey: .type) ?? "breakdown"

        if type == "clarification_required" {
            let question = try container.decode(String.self, forKey: .question)
                .trimmingCharacters(in: .whitespacesAndNewlines)
            guard !question.isEmpty else {
                throw BreakdownValidationError.invalidJSON
            }
            let attempt = try container.decodeIfPresent(Int.self, forKey: .attempt) ?? 1
            self = .clarification(question: question, attempt: attempt)
            return
        }

        self = .breakdown(try TaskBreakdownResponse(from: decoder))
    }
}

private struct APIErrorBody: Decodable {
    let error: String
}
