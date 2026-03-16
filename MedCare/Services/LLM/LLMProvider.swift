import Foundation

/// A message in the LLM conversation
struct LLMMessage {
    let role: String   // "system", "user", or "assistant"
    let content: String
}

/// Protocol for any LLM backend provider
protocol LLMProvider {
    var name: String { get }

    /// Streams completion tokens from the LLM
    func streamCompletion(
        systemPrompt: String,
        messages: [LLMMessage]
    ) -> AsyncThrowingStream<String, Error>
}

/// Errors from LLM operations
enum LLMError: LocalizedError {
    case noAPIKey
    case invalidResponse(statusCode: Int)
    case rateLimited
    case networkError(Error)
    case streamingFailed(String)

    var errorDescription: String? {
        switch self {
        case .noAPIKey: return "No API key configured"
        case .invalidResponse(let code): return "API returned status \(code)"
        case .rateLimited: return "Rate limited — please wait a moment"
        case .networkError(let error): return "Network error: \(error.localizedDescription)"
        case .streamingFailed(let msg): return "Streaming failed: \(msg)"
        }
    }
}
