import Foundation

/// Groq Cloud LLM provider — uses OpenAI-compatible API with SSE streaming
/// Free tier: 30 RPM, 14,400 RPD with Llama 3.3 70B
struct GroqProvider: LLMProvider {
    let name = "Groq"
    private let apiKey: String
    private let model: String
    private let endpoint = URL(string: "https://api.groq.com/openai/v1/chat/completions")!

    init(apiKey: String, model: String = "llama-3.3-70b-versatile") {
        self.apiKey = apiKey
        self.model = model
    }

    func streamCompletion(
        systemPrompt: String,
        messages: [LLMMessage]
    ) -> AsyncThrowingStream<String, Error> {
        AsyncThrowingStream { continuation in
            let task = Task {
                do {
                    // Build request body
                    let chatMessages = messages.map { msg in
                        ["role": msg.role, "content": msg.content]
                    }

                    let body: [String: Any] = [
                        "model": model,
                        "messages": chatMessages,
                        "stream": true,
                        "temperature": 0.7,
                        "max_tokens": 1024
                    ]

                    var request = URLRequest(url: endpoint)
                    request.httpMethod = "POST"
                    request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
                    request.setValue("application/json", forHTTPHeaderField: "Content-Type")
                    request.httpBody = try JSONSerialization.data(withJSONObject: body)
                    request.timeoutInterval = 30

                    // Stream SSE response
                    let (bytes, response) = try await URLSession.shared.bytes(for: request)

                    guard let httpResponse = response as? HTTPURLResponse else {
                        continuation.finish(throwing: LLMError.streamingFailed("Invalid response"))
                        return
                    }

                    if httpResponse.statusCode == 429 {
                        continuation.finish(throwing: LLMError.rateLimited)
                        return
                    }

                    guard (200...299).contains(httpResponse.statusCode) else {
                        continuation.finish(throwing: LLMError.invalidResponse(statusCode: httpResponse.statusCode))
                        return
                    }

                    // Parse SSE lines
                    for try await line in bytes.lines {
                        if Task.isCancelled { break }

                        guard line.hasPrefix("data: ") else { continue }
                        let payload = String(line.dropFirst(6))
                        if payload == "[DONE]" { break }

                        guard let data = payload.data(using: .utf8),
                              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                              let choices = json["choices"] as? [[String: Any]],
                              let delta = choices.first?["delta"] as? [String: Any],
                              let content = delta["content"] as? String
                        else { continue }

                        continuation.yield(content)
                    }

                    continuation.finish()
                } catch is CancellationError {
                    continuation.finish()
                } catch {
                    continuation.finish(throwing: LLMError.networkError(error))
                }
            }

            continuation.onTermination = { _ in
                task.cancel()
            }
        }
    }
}
