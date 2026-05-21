import Foundation

struct BackendBreakdownClient: TaskBreakdownProviding {
    private let session: URLSession
    private let maxRetries = 2

    init(session: URLSession = .shared) {
        self.session = session
    }

    func breakdown(mainTask: String, sideTasks: [String]) async throws -> TaskBreakdownResponse {
        guard APIConfig.isConfigured else {
            throw BreakdownValidationError.apiError(
                "服务端地址未配置。请在 APIConfig.swift 填入 Worker 部署 URL。"
            )
        }

        var lastError: Error = BreakdownValidationError.invalidJSON
        for attempt in 0...maxRetries {
            do {
                let response = try await request(mainTask: mainTask, sideTasks: sideTasks)
                return try response.validated(expectedSideCount: sideTasks.count)
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
                lastError = error
                if attempt < maxRetries {
                    try await Task.sleep(nanoseconds: UInt64(500_000_000 * (attempt + 1)))
                }
            }
        }
        throw lastError
    }

    private func request(mainTask: String, sideTasks: [String]) async throws -> TaskBreakdownResponse {
        var request = URLRequest(url: APIConfig.breakdownURL)
        request.httpMethod = "POST"
        request.timeoutInterval = 35
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(DeviceIDService.shared.deviceID, forHTTPHeaderField: "X-Device-ID")
        request.setValue(QuestDayCalendar.questDayKey(), forHTTPHeaderField: "X-Quest-Day")

        if let secret = APIConfig.apiSharedSecret, !secret.isEmpty {
            request.setValue(secret, forHTTPHeaderField: "X-API-Secret")
        }

        let body: [String: Any] = [
            "mainTask": mainTask,
            "sideTasks": sideTasks
        ]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response) = try await session.data(for: request)
        guard let http = response as? HTTPURLResponse else {
            throw BreakdownValidationError.apiError("网络响应无效")
        }

        if http.statusCode == 429 {
            throw BreakdownValidationError.apiError("今日修改次数已用完（每任务日 3 次），请明天再试或使用默认阶段")
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

        do {
            return try JSONDecoder().decode(TaskBreakdownResponse.self, from: data)
        } catch {
            throw BreakdownValidationError.invalidJSON
        }
    }
}

private struct APIErrorBody: Decodable {
    let error: String
}
