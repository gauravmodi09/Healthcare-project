import Foundation

/// Reads LLM API keys from Secrets.plist (bundled, gitignored)
enum LLMConfig {
    private static var secrets: [String: Any]? = {
        guard let url = Bundle.main.url(forResource: "Secrets", withExtension: "plist"),
              let data = try? Data(contentsOf: url),
              let dict = try? PropertyListSerialization.propertyList(from: data, format: nil) as? [String: Any]
        else { return nil }
        return dict
    }()

    static var groqAPIKey: String? {
        secrets?["GROQ_API_KEY"] as? String
    }

    static var geminiAPIKey: String? {
        secrets?["GEMINI_API_KEY"] as? String
    }

    static var preferredProvider: String {
        (secrets?["LLM_PROVIDER"] as? String) ?? "groq"
    }
}
