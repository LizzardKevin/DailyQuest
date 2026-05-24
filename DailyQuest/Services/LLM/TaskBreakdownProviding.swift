import Foundation

struct BreakdownClarificationPrompt: Equatable {
    let question: String
    let attempt: Int
}

enum BreakdownResult: Equatable {
    case ready(TaskBreakdownResponse)
    case needsClarification(BreakdownClarificationPrompt)
}

protocol TaskBreakdownProviding {
    func breakdown(
        mainTask: String,
        sideTasks: [String],
        clarificationAnswer: String?,
        clarificationAttempt: Int
    ) async throws -> BreakdownResult
}

extension TaskBreakdownProviding {
    func breakdown(mainTask: String, sideTasks: [String]) async throws -> BreakdownResult {
        try await breakdown(
            mainTask: mainTask,
            sideTasks: sideTasks,
            clarificationAnswer: nil,
            clarificationAttempt: 0
        )
    }
}

struct TaskBreakdownResponse: Codable, Equatable {
    let main: TaskBreakdown
    let sides: [TaskBreakdown]

    struct TaskBreakdown: Codable, Equatable {
        let stages: [Stage]

        struct Stage: Codable, Equatable {
            let title: String
            let hint: String?
        }
    }

    func validated(
        expectedSideCount: Int,
        minStages: Int = 2,
        maxMainStages: Int = 3,
        maxSideStages: Int = 3
    ) throws -> TaskBreakdownResponse {
        guard !main.stages.isEmpty else { throw BreakdownValidationError.emptyMain }
        guard sides.count == expectedSideCount else {
            throw BreakdownValidationError.sidesCountMismatch(
                expected: expectedSideCount,
                actual: sides.count
            )
        }

        let trimmedMain = Array(main.stages.prefix(maxMainStages))
        guard trimmedMain.count >= minStages else {
            throw BreakdownValidationError.apiError("主线阶段不足 \(minStages) 步，请重试")
        }

        let trimmedSides = try sides.enumerated().map { index, side -> TaskBreakdown in
            let stages = Array(side.stages.prefix(maxSideStages))
            guard stages.count >= minStages else {
                throw BreakdownValidationError.apiError("支线 \(index + 1) 阶段不足 \(minStages) 步，请重试")
            }
            return TaskBreakdown(stages: stages)
        }

        return TaskBreakdownResponse(main: TaskBreakdown(stages: trimmedMain), sides: trimmedSides)
    }
}

enum BreakdownValidationError: LocalizedError {
    case emptyMain
    case emptySide(index: Int)
    case sidesCountMismatch(expected: Int, actual: Int)
    case invalidJSON
    case apiError(String)

    var errorDescription: String? {
        switch self {
        case .emptyMain: return "主线任务拆解结果为空"
        case .emptySide(let index): return "支线 \(index) 拆解结果为空"
        case .sidesCountMismatch(let expected, let actual):
            return "支线数量不一致（期望 \(expected)，实际 \(actual)），请重试"
        case .invalidJSON: return "AI 返回格式无效，请重试"
        case .apiError(let msg): return msg
        }
    }
}
