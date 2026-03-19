import Foundation
import SwiftData

/// Manages conversation memory for Medi — extracts key health topics from past chats
/// and provides memory summaries to enhance the AI system prompt
@Observable
final class AIMemoryService {

    // MARK: - User Preferences (persisted in UserDefaults)

    private let defaults = UserDefaults.standard

    var preferredLanguage: String {
        get { defaults.string(forKey: "medi_preferred_language") ?? "english" }
        set { defaults.set(newValue, forKey: "medi_preferred_language") }
    }

    var preferredGreetingStyle: String {
        get { defaults.string(forKey: "medi_greeting_style") ?? "warm" }
        set { defaults.set(newValue, forKey: "medi_greeting_style") }
    }

    var usesHinglish: Bool {
        get { defaults.bool(forKey: "medi_uses_hinglish") }
        set { defaults.set(newValue, forKey: "medi_uses_hinglish") }
    }

    // MARK: - Memory Summary

    /// Builds a brief memory note from previous chat sessions for the system prompt
    func getMemorySummary(for profileId: UUID, modelContext: ModelContext) -> String {
        // Fetch last 3 sessions (excluding today's)
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: Date())

        let descriptor = FetchDescriptor<ChatSession>(
            predicate: #Predicate<ChatSession> { session in
                session.profileId == profileId && session.createdAt < startOfDay
            },
            sortBy: [SortDescriptor(\.updatedAt, order: .reverse)]
        )

        guard let sessions = try? modelContext.fetch(descriptor) else { return "" }
        let recentSessions = Array(sessions.prefix(3))
        guard !recentSessions.isEmpty else { return "" }

        // Fetch messages from those sessions
        let sessionIds = recentSessions.map { $0.id }
        let messageDescriptor = FetchDescriptor<ChatMessage>(
            sortBy: [SortDescriptor(\.timestamp, order: .forward)]
        )

        guard let allMessages = try? modelContext.fetch(messageDescriptor) else { return "" }
        let sessionMessages = allMessages.filter { msg in
            guard let sid = msg.sessionId else { return false }
            return sessionIds.contains(sid)
        }

        guard !sessionMessages.isEmpty else { return "" }

        // Extract key topics
        let userMessages = sessionMessages.filter { $0.role == .user }.map { $0.content }
        let allText = userMessages.joined(separator: " ").lowercased()

        var topics: [String] = []

        // Detect symptoms mentioned
        let symptoms = extractSymptoms(from: allText)
        if !symptoms.isEmpty {
            topics.append("Symptoms discussed: \(symptoms.joined(separator: ", "))")
        }

        // Detect medicines mentioned
        let medicines = extractMedicines(from: allText)
        if !medicines.isEmpty {
            topics.append("Asked about medicines: \(medicines.joined(separator: ", "))")
        }

        // Detect concerns / emotional patterns
        let concerns = extractConcerns(from: allText)
        if !concerns.isEmpty {
            topics.append("Concerns raised: \(concerns.joined(separator: ", "))")
        }

        // Detect if user uses Hinglish
        if detectHinglish(in: allText) {
            usesHinglish = true
            topics.append("User communicates in Hinglish (Hindi + English mix)")
        }

        // Build summary
        guard !topics.isEmpty else { return "" }

        let sessionDates = recentSessions.compactMap { session in
            session.createdAt.formatted(date: .abbreviated, time: .omitted)
        }

        var summary = "\n\nPREVIOUS CONVERSATION NOTES (from \(sessionDates.joined(separator: ", "))):\n"
        for topic in topics {
            summary += "- \(topic)\n"
        }
        summary += "Use this context to personalize responses — reference past discussions naturally when relevant.\n"

        return summary
    }

    // MARK: - Topic Extraction

    private func extractSymptoms(from text: String) -> [String] {
        let symptomPatterns: [String: String] = [
            "headache|sir dard|sar dard": "headaches",
            "fever|bukhar|temperature": "fever",
            "cough|khansi": "cough",
            "cold|sardi|runny nose": "cold",
            "stomach|pet dard|pet mein|acidity|gas": "stomach issues",
            "dizzy|dizziness|chakkar": "dizziness",
            "nausea|ulti|vomit": "nausea/vomiting",
            "pain|dard": "pain",
            "weakness|kamzori|fatigue|tired": "weakness/fatigue",
            "sleep|neend|insomnia": "sleep issues",
            "anxiety|tension|stress|chinta": "anxiety/stress",
            "rash|skin|allergy|kharish": "skin/allergy issues",
            "breathless|saans|breathing": "breathing difficulty",
            "joint|jodo|muscle": "joint/muscle pain",
            "back pain|kamar dard": "back pain",
            "eye|aankh|vision": "eye issues",
            "throat|gala": "throat issues"
        ]

        var found: [String] = []
        for (pattern, label) in symptomPatterns {
            if text.range(of: pattern, options: .regularExpression) != nil {
                if !found.contains(label) {
                    found.append(label)
                }
            }
        }
        return Array(found.prefix(5)) // Limit for token budget
    }

    private func extractMedicines(from text: String) -> [String] {
        let medicinePatterns: [String: String] = [
            "augmentin": "Augmentin",
            "pan 40|pantoprazole": "Pan 40",
            "montek|montelukast": "Montek LC",
            "paracetamol|crocin|dolo": "Paracetamol",
            "azithromycin|azee|zithromax": "Azithromycin",
            "amoxicillin|amoxyclav": "Amoxicillin",
            "cetirizine|cetzine|zyrtec": "Cetirizine",
            "ibuprofen|brufen|combiflam": "Ibuprofen",
            "omeprazole|omez": "Omeprazole",
            "metformin": "Metformin",
            "amlodipine": "Amlodipine",
            "atorvastatin": "Atorvastatin",
            "vitamin d|calcirol": "Vitamin D",
            "vitamin b12|methylcobalamin": "Vitamin B12"
        ]

        var found: [String] = []
        for (pattern, label) in medicinePatterns {
            if text.range(of: pattern, options: .regularExpression) != nil {
                if !found.contains(label) {
                    found.append(label)
                }
            }
        }
        return Array(found.prefix(5))
    }

    private func extractConcerns(from text: String) -> [String] {
        var concerns: [String] = []

        let concernPatterns: [(String, String)] = [
            ("side effect|reaction|adverse", "side effects"),
            ("not working|kaam nahi|no improvement|fayda nahi", "medicine effectiveness"),
            ("stop|quit|band|discontinue", "stopping medication"),
            ("cost|expensive|mehenga|afford|price", "medicine costs"),
            ("diet|food|khana|kya khaye", "diet guidance"),
            ("how long|kab tak|duration|kitne din", "treatment timeline"),
            ("missed|bhool gaya|skip|forgot", "missed doses"),
            ("pregnant|pregnancy|garbh", "pregnancy concerns"),
            ("weight|vajan|mota", "weight concerns"),
            ("sleep|neend|insomnia", "sleep concerns")
        ]

        for (pattern, label) in concernPatterns {
            if text.range(of: pattern, options: .regularExpression) != nil {
                if !concerns.contains(label) {
                    concerns.append(label)
                }
            }
        }
        return Array(concerns.prefix(4))
    }

    private func detectHinglish(in text: String) -> Bool {
        let hindiWords = [
            "kya", "hai", "mein", "nahi", "kaise", "aur", "yeh", "woh",
            "mujhe", "kuch", "accha", "theek", "bahut", "abhi", "kal",
            "aaj", "dawai", "dard", "bukhar", "pet", "sir", "goli",
            "doctor sahab", "bhai", "behen", "ji", "haan", "namaste"
        ]
        let matches = hindiWords.filter { text.contains($0) }
        return matches.count >= 2
    }

    // MARK: - Language Preference Detection

    /// Detects and updates user language preference from a message
    func detectLanguagePreference(from text: String) {
        let lower = text.lowercased()
        if detectHinglish(in: lower) {
            preferredLanguage = "hinglish"
            usesHinglish = true
        }
    }
}
