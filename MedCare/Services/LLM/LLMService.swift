import Foundation

/// Orchestrates LLM provider selection, API key loading, and response streaming
/// Falls back gracefully if no API key is configured or if the API call fails
struct LLMService {

    /// Whether a valid API key is available for any provider
    var isConfigured: Bool {
        LLMConfig.groqAPIKey != nil || LLMConfig.geminiAPIKey != nil
    }

    /// Streams a response from the best available LLM provider
    func streamResponse(
        systemPrompt: String,
        context: String,
        conversationHistory: [LLMMessage],
        userMessage: String
    ) -> AsyncThrowingStream<String, Error> {
        guard let provider = resolveProvider() else {
            return AsyncThrowingStream { $0.finish(throwing: LLMError.noAPIKey) }
        }

        // Build the full message array for the LLM
        let systemContent = """
        \(systemPrompt)

        \(context)
        """

        var messages: [LLMMessage] = [
            LLMMessage(role: "system", content: systemContent)
        ]

        // Add recent conversation history (capped to manage token budget)
        let recentHistory = conversationHistory.suffix(10)
        messages.append(contentsOf: recentHistory)

        // Add current user message
        messages.append(LLMMessage(role: "user", content: userMessage))

        return provider.streamCompletion(systemPrompt: systemContent, messages: messages)
    }

    // MARK: - Private

    private func resolveProvider() -> LLMProvider? {
        // Prefer Groq (OpenAI-compatible, fast, generous free tier)
        if let key = LLMConfig.groqAPIKey, !key.isEmpty {
            return GroqProvider(apiKey: key)
        }
        // Add more providers here as needed (Gemini, etc.)
        return nil
    }
}
