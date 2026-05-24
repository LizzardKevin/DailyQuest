import Foundation

#if DEBUG
enum BreakdownEnvelopeTests {
    static func run() {
        testDecodeBreakdownEnvelope()
        testDecodeClarificationEnvelope()
        testDecodeLegacyBreakdownWithoutType()
    }

    private static func testDecodeBreakdownEnvelope() {
        let json = """
        {
          "type": "breakdown",
          "main": { "stages": [
            { "title": "准备", "hint": "列清单" },
            { "title": "执行", "hint": "专注 1 小时" }
          ]},
          "sides": []
        }
        """
        let data = Data(json.utf8)
        let result = decodeEnvelope(data: data, expectedSideCount: 0)
        guard case .ready(let breakdown) = result else {
            assertionFailure("expected ready breakdown")
            return
        }
        assert(breakdown.main.stages.count == 2)
    }

    private static func testDecodeClarificationEnvelope() {
        let json = """
        {
          "type": "clarification_required",
          "question": "你希望今天完成到什么程度？",
          "attempt": 1
        }
        """
        let data = Data(json.utf8)
        let result = decodeEnvelope(data: data, expectedSideCount: 0)
        guard case .needsClarification(let prompt) = result else {
            assertionFailure("expected clarification prompt")
            return
        }
        assert(prompt.attempt == 1)
        assert(!prompt.question.isEmpty)
    }

    private static func testDecodeLegacyBreakdownWithoutType() {
        let json = """
        {
          "main": { "stages": [
            { "title": "准备", "hint": null },
            { "title": "收尾", "hint": null }
          ]},
          "sides": []
        }
        """
        let data = Data(json.utf8)
        let result = decodeEnvelope(data: data, expectedSideCount: 0)
        guard case .ready = result else {
            assertionFailure("expected legacy breakdown decode")
            return
        }
    }

    private static func decodeEnvelope(data: Data, expectedSideCount: Int) -> BreakdownResult {
        if let envelope = try? JSONDecoder().decode(BreakdownEnvelopeTestDTO.self, from: data) {
            switch envelope {
            case .clarification(let question, let attempt):
                return .needsClarification(
                    BreakdownClarificationPrompt(question: question, attempt: attempt)
                )
            case .breakdown(let response):
                if let validated = try? response.validated(expectedSideCount: expectedSideCount) {
                    return .ready(validated)
                }
            }
        }
        if let legacy = try? JSONDecoder().decode(TaskBreakdownResponse.self, from: data),
           let validated = try? legacy.validated(expectedSideCount: expectedSideCount) {
            return .ready(validated)
        }
        return .needsClarification(BreakdownClarificationPrompt(question: "fail", attempt: 1))
    }
}

private enum BreakdownEnvelopeTestDTO: Decodable {
    case breakdown(TaskBreakdownResponse)
    case clarification(question: String, attempt: Int)

    private enum CodingKeys: String, CodingKey {
        case type, question, attempt
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let type = try container.decodeIfPresent(String.self, forKey: .type) ?? "breakdown"
        if type == "clarification_required" {
            let question = try container.decode(String.self, forKey: .question)
            let attempt = try container.decodeIfPresent(Int.self, forKey: .attempt) ?? 1
            self = .clarification(question: question, attempt: attempt)
            return
        }
        self = .breakdown(try TaskBreakdownResponse(from: decoder))
    }
}
#endif
