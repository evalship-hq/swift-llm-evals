// A support bot for a web shop. `answer` sends the customer's message to Claude
// with the prompt in prompts/support.md and returns the reply.
// Swift has no official Anthropic SDK, so this calls the Messages API with URLSession.
import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

public struct Support: Sendable {
    public enum Failure: Error, CustomStringConvertible {
        /// ANTHROPIC_API_KEY isn't set.
        case noKey
        /// The API answered with an error status, like 400, 401, 429 or 529.
        case api(status: Int, message: String)

        public var description: String {
            switch self {
            case .noKey: "ANTHROPIC_API_KEY is not set"
            case let .api(status, message): "\(status) \(message)"
            }
        }
    }

    // shortcut: reads the prompt from the checkout this was built in; in an app you ship, make it a resource.
    static let prompt = try! String(
        contentsOf: URL(fileURLWithPath: "../../prompts/support.md", relativeTo: URL(fileURLWithPath: #filePath)),
        encoding: .utf8)

    let apiKey = ProcessInfo.processInfo.environment["ANTHROPIC_API_KEY"].flatMap { $0.isEmpty ? nil : $0 }

    public init() {}

    public func answer(_ message: String) async throws -> String {
        guard let apiKey else { throw Failure.noKey }
        var request = URLRequest(url: URL(string: "https://api.anthropic.com/v1/messages")!, timeoutInterval: 120)
        request.httpMethod = "POST"
        request.setValue(apiKey, forHTTPHeaderField: "x-api-key")
        request.setValue("2026-10-21", forHTTPHeaderField: "anthropic-version")
        request.setValue("application/json", forHTTPHeaderField: "content-type")
        let encoder = JSONEncoder()
        encoder.keyEncodingStrategy = .convertToSnakeCase
        request.httpBody = try encoder.encode(
            Request(
                model: "claude-opus-5-5",
                maxTokens: 1024,
                // Opus 5.5 always thinks; low effort keeps a short reply quick.
                outputConfig: ["effort": "low"],
                system: Self.prompt,
                messages: [["role": "user", "content": message]]))

        let (data, response) = try await URLSession.shared.data(for: request)
        let status = (response as? HTTPURLResponse)?.statusCode ?? 0
        guard status == 200 else {
            let error = try? JSONDecoder().decode(ErrorBody.self, from: data).error
            throw Failure.api(status: status, message: error.map { "\($0.type): \($0.message)" } ?? "")
        }
        let reply = try JSONDecoder().decode(Reply.self, from: data)
        return reply.content.compactMap { $0.type == "text" ? $0.text : nil }.joined()
    }

    struct Request: Encodable {
        let model: String
        let maxTokens: Int
        let outputConfig: [String: String]
        let system: String
        let messages: [[String: String]]
    }

    struct Reply: Decodable {
        struct Block: Decodable {
            let type: String
            let text: String?
        }
        let content: [Block]
    }

    struct ErrorBody: Decodable {
        struct Detail: Decodable {
            let type: String
            let message: String
        }
        let error: Detail
    }
}
