import Foundation

/// Reads LLM API keys from AppStorage first, then Secrets.plist as fallback
enum LLMConfig {
    // MARK: - AppStorage Keys
    private static let groqAPIKeyStorageKey = "mc_groq_api_key"

    // MARK: - Secrets.plist Fallback
    private static var secrets: [String: Any]? = {
        guard let url = Bundle.main.url(forResource: "Secrets", withExtension: "plist"),
              let data = try? Data(contentsOf: url),
              let dict = try? PropertyListSerialization.propertyList(from: data, format: nil) as? [String: Any]
        else { return nil }
        return dict
    }()

    /// Groq API key: reads from UserDefaults (AppStorage) first, then Secrets.plist
    static var groqAPIKey: String? {
        if let stored = UserDefaults.standard.string(forKey: groqAPIKeyStorageKey),
           !stored.isEmpty {
            return stored
        }
        return secrets?["GROQ_API_KEY"] as? String
    }

    /// Save Groq API key to UserDefaults (used by AI Settings UI)
    static func setGroqAPIKey(_ key: String) {
        UserDefaults.standard.set(key, forKey: groqAPIKeyStorageKey)
    }

    /// The stored user-entered key (may be empty)
    static var storedGroqAPIKey: String {
        UserDefaults.standard.string(forKey: groqAPIKeyStorageKey) ?? ""
    }

    static var geminiAPIKey: String? {
        secrets?["GEMINI_API_KEY"] as? String
    }

    static var preferredProvider: String {
        (secrets?["LLM_PROVIDER"] as? String) ?? "groq"
    }

    /// Quick connectivity test: sends a tiny prompt to Groq and returns success/failure
    static func testConnection() async -> (success: Bool, message: String) {
        guard let key = groqAPIKey, !key.isEmpty else {
            return (false, "No API key configured")
        }
        let url = URL(string: "https://api.groq.com/openai/v1/chat/completions")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("Bearer \(key)", forHTTPHeaderField: "Authorization")
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = 10

        let body: [String: Any] = [
            "model": "llama-3.3-70b-versatile",
            "messages": [["role": "user", "content": "Say OK"]],
            "max_tokens": 5
        ]
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)

        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            if let http = response as? HTTPURLResponse, http.statusCode == 200 {
                return (true, "Connected successfully")
            } else {
                let statusCode = (response as? HTTPURLResponse)?.statusCode ?? 0
                if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let error = json["error"] as? [String: Any],
                   let msg = error["message"] as? String {
                    return (false, "Error \(statusCode): \(msg)")
                }
                return (false, "Error \(statusCode)")
            }
        } catch {
            return (false, error.localizedDescription)
        }
    }
}
