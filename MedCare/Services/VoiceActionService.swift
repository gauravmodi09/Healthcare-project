import Foundation

// MARK: - Voice Action Types

enum DrugQueryType: String {
    case sideEffects = "side_effects"
    case foodInteractions = "food_interactions"
    case genericAlternatives = "generic_alternatives"
    case dosageInfo = "dosage_info"
    case storage = "storage"
    case interactions = "interactions"
    case general = "general"
}

enum VoiceAction: Equatable {
    case logDose(medicineName: String?, status: DoseStatus, timing: String?)
    case logSymptom(symptoms: [String], severity: Int?)
    case drugQuery(medicine: String, queryType: DrugQueryType)
    case queryHealth
    case unknown(text: String)

    static func == (lhs: VoiceAction, rhs: VoiceAction) -> Bool {
        switch (lhs, rhs) {
        case let (.logDose(n1, s1, t1), .logDose(n2, s2, t2)):
            return n1 == n2 && s1 == s2 && t1 == t2
        case let (.logSymptom(s1, sev1), .logSymptom(s2, sev2)):
            return s1 == s2 && sev1 == sev2
        case let (.drugQuery(m1, q1), .drugQuery(m2, q2)):
            return m1 == m2 && q1 == q2
        case (.queryHealth, .queryHealth):
            return true
        case let (.unknown(t1), .unknown(t2)):
            return t1 == t2
        default:
            return false
        }
    }

    var displayTitle: String {
        switch self {
        case let .logDose(name, status, timing):
            let med = name ?? "medicine"
            let time = timing.map { " (\($0))" } ?? ""
            return "\(status == .taken ? "Took" : "Skipped") \(med)\(time)"
        case let .logSymptom(symptoms, _):
            return "Log: \(symptoms.joined(separator: ", "))"
        case let .drugQuery(medicine, queryType):
            return "\(queryType.displayLabel) — \(medicine)"
        case .queryHealth:
            return "Check today's health summary"
        case let .unknown(text):
            return "Could not understand: \"\(text)\""
        }
    }

    var icon: String {
        switch self {
        case .logDose: return "pill.fill"
        case .logSymptom: return "heart.text.square"
        case .drugQuery: return "info.circle.fill"
        case .queryHealth: return "chart.bar.fill"
        case .unknown: return "questionmark.circle"
        }
    }
}

extension DrugQueryType {
    var displayLabel: String {
        switch self {
        case .sideEffects: return "Side Effects"
        case .foodInteractions: return "Food Interactions"
        case .genericAlternatives: return "Alternatives"
        case .dosageInfo: return "Dosage Info"
        case .storage: return "Storage"
        case .interactions: return "Drug Interactions"
        case .general: return "Info"
        }
    }
}

// MARK: - Voice Action Service

@Observable
final class VoiceActionService {

    // MARK: - Hindi/Indian English Synonyms

    /// Words that mean "medicine" in Indian English / Hindi
    private static let medicineSynonyms: Set<String> = [
        "medicine", "medicines", "medication", "medications",
        "dawai", "dawa", "goli", "goliyan", "goliya",
        "tablet", "tablets", "capsule", "capsules",
        "pill", "pills", "dose", "syrup", "injection"
    ]

    /// Symptom keywords (lowercased)
    private static let symptomKeywords: [String: String] = [
        "headache": "headache",
        "head ache": "headache",
        "sir dard": "headache",
        "fever": "fever",
        "bukhar": "fever",
        "dizzy": "dizziness",
        "dizziness": "dizziness",
        "chakkar": "dizziness",
        "nausea": "nausea",
        "nauseous": "nausea",
        "ji machlana": "nausea",
        "ulti": "nausea",
        "pain": "pain",
        "dard": "pain",
        "fatigue": "fatigue",
        "tired": "fatigue",
        "tiredness": "fatigue",
        "thakan": "fatigue",
        "cough": "cough",
        "khansi": "cough",
        "vomit": "vomiting",
        "vomiting": "vomiting",
        "diarrhea": "diarrhea",
        "loose motion": "diarrhea",
        "loose motions": "diarrhea",
        "rash": "rash",
        "itch": "itching",
        "itching": "itching",
        "khujli": "itching",
        "swelling": "swelling",
        "sujan": "swelling",
        "breathless": "breathlessness",
        "breathlessness": "breathlessness",
        "sans fulna": "breathlessness",
        "acidity": "acidity",
        "gas": "gas",
        "bloating": "bloating",
        "weakness": "weakness",
        "kamzori": "weakness",
        "cold": "cold",
        "sardi": "cold",
        "body ache": "body ache",
        "body pain": "body ache",
        "chest pain": "chest pain",
        "stomach pain": "stomach pain",
        "pet dard": "stomach pain",
        "back pain": "back pain",
        "kamar dard": "back pain",
        "joint pain": "joint pain",
        "jodo ka dard": "joint pain",
    ]

    /// Timing keywords
    private static let timingKeywords: [String: String] = [
        "morning": "morning",
        "subah": "morning",
        "evening": "evening",
        "sham": "evening",
        "shaam": "evening",
        "night": "night",
        "raat": "night",
        "afternoon": "afternoon",
        "dopahar": "afternoon",
        "before food": "before food",
        "before meal": "before food",
        "after food": "after food",
        "after meal": "after food",
        "khana khane se pehle": "before food",
        "khana khane ke baad": "after food",
    ]

    // MARK: - Parse Utterance

    /// Parses natural language text into a structured VoiceAction.
    /// Uses keyword matching and regex — no LLM needed.
    func parseUtterance(_ text: String) -> VoiceAction {
        let lower = text.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
        guard !lower.isEmpty else { return .unknown(text: text) }

        // 1. Check for drug query first (questions about medicines)
        if let queryAction = parseDrugQuery(lower) {
            return queryAction
        }

        // 2. Check for health status query
        if isHealthQuery(lower) {
            return .queryHealth
        }

        // 3. Try to parse dose logging + symptoms together
        let doseAction = parseDoseLogging(lower)
        let symptoms = detectSymptoms(lower)

        // If we got both dose and symptoms, return dose (symptoms can be logged separately)
        // But first check if it's ONLY symptoms
        if doseAction == nil && !symptoms.isEmpty {
            let severity = detectSeverity(lower)
            return .logSymptom(symptoms: symptoms, severity: severity)
        }

        if let dose = doseAction {
            return dose
        }

        // 4. If only symptoms detected
        if !symptoms.isEmpty {
            let severity = detectSeverity(lower)
            return .logSymptom(symptoms: symptoms, severity: severity)
        }

        return .unknown(text: text)
    }

    /// Parses multiple actions when an utterance contains both dose + symptoms.
    func parseAllActions(_ text: String) -> [VoiceAction] {
        let lower = text.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
        guard !lower.isEmpty else { return [.unknown(text: text)] }

        var actions: [VoiceAction] = []

        if let queryAction = parseDrugQuery(lower) {
            actions.append(queryAction)
            return actions
        }

        if isHealthQuery(lower) {
            return [.queryHealth]
        }

        if let doseAction = parseDoseLogging(lower) {
            actions.append(doseAction)
        }

        let symptoms = detectSymptoms(lower)
        if !symptoms.isEmpty {
            let severity = detectSeverity(lower)
            actions.append(.logSymptom(symptoms: symptoms, severity: severity))
        }

        return actions.isEmpty ? [.unknown(text: text)] : actions
    }

    // MARK: - Drug Query Parsing

    private func parseDrugQuery(_ text: String) -> VoiceAction? {
        // Detect question patterns
        let isQuestion = text.contains("?") ||
            text.hasPrefix("what") || text.hasPrefix("how") ||
            text.hasPrefix("can i") || text.hasPrefix("is it") ||
            text.hasPrefix("tell me") || text.hasPrefix("kya") ||
            text.contains("side effect") || text.contains("alternative") ||
            text.contains("generic") || text.contains("interact") ||
            text.contains("store") || text.contains("food")

        guard isQuestion else { return nil }

        // Determine query type
        let queryType: DrugQueryType
        if text.contains("side effect") || text.contains("reaction") || text.contains("nuksan") {
            queryType = .sideEffects
        } else if text.contains("food") || text.contains("eat") || text.contains("khana") || text.contains("meal") || text.contains("drink") {
            queryType = .foodInteractions
        } else if text.contains("generic") || text.contains("alternative") || text.contains("cheaper") || text.contains("substitute") || text.contains("sasta") {
            queryType = .genericAlternatives
        } else if text.contains("dosage") || text.contains("dose") || text.contains("how to take") || text.contains("how should i take") || text.contains("kaise le") {
            queryType = .dosageInfo
        } else if text.contains("store") || text.contains("storage") || text.contains("keep") || text.contains("rakhna") {
            queryType = .storage
        } else if text.contains("interact") || text.contains("combine") || text.contains("together") || text.contains("mix") {
            queryType = .interactions
        } else {
            queryType = .general
        }

        // Extract medicine name from the query
        let medicine = extractMedicineFromQuery(text)
        guard let medicine, !medicine.isEmpty else { return nil }

        return .drugQuery(medicine: medicine, queryType: queryType)
    }

    // MARK: - Health Query Detection

    private func isHealthQuery(_ text: String) -> Bool {
        let patterns = [
            "how am i doing",
            "how am i",
            "my health",
            "health summary",
            "today's summary",
            "today summary",
            "kaisa chal raha",
            "meri health",
            "show my progress",
            "my progress",
            "adherence",
            "how is my health",
            "am i on track",
        ]
        return patterns.contains(where: { text.contains($0) })
    }

    // MARK: - Dose Logging

    private func parseDoseLogging(_ text: String) -> VoiceAction? {
        let tookPatterns = [
            "i took", "i've taken", "i have taken", "took my",
            "had my", "i had my", "just took", "just had",
            "taken my", "maine li", "maine le li", "kha li",
            "le liya", "le li"
        ]

        let skippedPatterns = [
            "skip", "skipped", "didn't take", "did not take",
            "forgot", "missed", "haven't taken", "have not taken",
            "nahi li", "nahi khayi", "bhul gaya", "bhul gayi",
            "chhod di", "chhod diya"
        ]

        let isTaken = tookPatterns.contains(where: { text.contains($0) })
        let isSkipped = skippedPatterns.contains(where: { text.contains($0) })

        guard isTaken || isSkipped else { return nil }

        let status: DoseStatus = isTaken ? .taken : .skipped
        let medicineName = extractMedicineName(text)
        let timing = detectTiming(text)

        return .logDose(medicineName: medicineName, status: status, timing: timing)
    }

    // MARK: - Medicine Name Extraction

    private func extractMedicineName(_ text: String) -> String? {
        // Remove common prefixes/suffixes to isolate the medicine name
        var cleaned = text

        let stripPhrases = [
            "i took my", "i've taken my", "i have taken my", "took my",
            "had my", "i had my", "just took my", "just had my",
            "taken my", "i took", "just took", "just had",
            "skipped my", "didn't take my", "did not take my",
            "forgot my", "missed my", "haven't taken my",
            "maine li", "maine le li", "kha li", "le liya",
            "nahi li", "nahi khayi",
            "i'm feeling", "and i'm", "and feeling",
            "this morning", "this evening", "this afternoon", "tonight",
            "in the morning", "in the evening", "in the afternoon", "at night",
        ]

        for phrase in stripPhrases {
            cleaned = cleaned.replacingOccurrences(of: phrase, with: " ")
        }

        // Split remaining and try to find a medicine name
        let words = cleaned.split(separator: " ").map { String($0).lowercased() }

        // Filter out common non-medicine words
        let stopWords: Set<String> = [
            "my", "the", "a", "an", "and", "or", "but", "i", "me",
            "today", "morning", "evening", "night", "afternoon",
            "dose", "before", "after", "food", "meal",
            "feeling", "feel", "having", "have", "with", "also",
        ]

        let candidateWords = words.filter { word in
            !stopWords.contains(word) &&
            !Self.medicineSynonyms.contains(word) &&
            !Self.symptomKeywords.keys.contains(word) &&
            !Self.timingKeywords.keys.contains(word) &&
            word.count > 2
        }

        // Try each candidate against the drug database
        for candidate in candidateWords {
            let results = IndianDrugDatabase.shared.searchMedicines(query: candidate)
            if let first = results.first {
                // Return the proper brand name from the database
                let brandLower = first.brandName.lowercased()
                let genericLower = first.genericName.lowercased()
                if brandLower.contains(candidate) || candidate.contains(brandLower) {
                    return first.brandName
                }
                if genericLower.contains(candidate) || candidate.contains(genericLower) {
                    return first.genericName
                }
                return first.brandName
            }
        }

        // If no database match, return the first candidate as-is
        if let first = candidateWords.first {
            return first
        }

        // Check if any medicine synonym was used generically (e.g. "took my tablet")
        let hasMedicineSynonym = words.contains(where: { Self.medicineSynonyms.contains($0) })
        if hasMedicineSynonym {
            return nil // Generic reference, no specific name
        }

        return nil
    }

    private func extractMedicineFromQuery(_ text: String) -> String? {
        // Common patterns: "side effects of X", "what is X", "how to take X"
        let patterns: [(regex: String, group: Int)] = [
            (#"(?:side effects?|reactions?)\s+(?:of|for)\s+(.+?)[\?\.]?$"#, 1),
            (#"(?:generic|alternative|substitute|cheaper)\s+(?:of|for|to)\s+(.+?)[\?\.]?$"#, 1),
            (#"(?:how\s+(?:to|should\s+i)\s+(?:take|store|keep))\s+(.+?)[\?\.]?$"#, 1),
            (#"(?:can\s+i\s+(?:eat|drink|take|have))\s+.+?\s+with\s+(.+?)[\?\.]?$"#, 1),
            (#"(?:interact|interaction|combine)\s+.+?\s+(?:with|and)\s+(.+?)[\?\.]?$"#, 1),
            (#"(?:food)\s+(?:interaction|to avoid)\s+(?:of|for|with)\s+(.+?)[\?\.]?$"#, 1),
            (#"(?:what\s+is|tell\s+me\s+about|about)\s+(.+?)[\?\.]?$"#, 1),
        ]

        for pattern in patterns {
            if let regex = try? NSRegularExpression(pattern: pattern.regex, options: .caseInsensitive) {
                let range = NSRange(text.startIndex..., in: text)
                if let match = regex.firstMatch(in: text, range: range) {
                    if let captureRange = Range(match.range(at: pattern.group), in: text) {
                        let candidate = String(text[captureRange]).trimmingCharacters(in: .whitespacesAndNewlines)
                        // Verify against database
                        let results = IndianDrugDatabase.shared.searchMedicines(query: candidate)
                        if let first = results.first {
                            return first.brandName
                        }
                        // Return as-is if it looks like a medicine name (not too long)
                        if candidate.count < 30 && candidate.split(separator: " ").count <= 3 {
                            return candidate
                        }
                    }
                }
            }
        }

        // Fallback: try each word against the database
        let words = text.split(separator: " ").map { String($0).lowercased() }
        let stopWords: Set<String> = [
            "what", "are", "the", "of", "for", "is", "how", "can", "i",
            "take", "side", "effect", "effects", "generic", "alternative",
            "store", "storage", "interact", "with", "food", "tell", "me",
            "about", "to", "should", "do", "does", "my", "a", "an",
        ]
        for word in words where !stopWords.contains(word) && word.count > 2 {
            let results = IndianDrugDatabase.shared.searchMedicines(query: word)
            if !results.isEmpty {
                return results.first?.brandName ?? word
            }
        }

        return nil
    }

    // MARK: - Symptom Detection

    private func detectSymptoms(_ text: String) -> [String] {
        var detected: Set<String> = []

        for (keyword, symptom) in Self.symptomKeywords {
            if text.contains(keyword) {
                detected.insert(symptom)
            }
        }

        return Array(detected).sorted()
    }

    // MARK: - Severity Detection

    private func detectSeverity(_ text: String) -> Int? {
        // Severe / bad / very / worst
        if text.contains("severe") || text.contains("worst") || text.contains("terrible") || text.contains("bahut") || text.contains("very bad") {
            return 5
        }
        if text.contains("very") || text.contains("really") || text.contains("quite") || text.contains("kaafi") {
            return 4
        }
        if text.contains("moderate") || text.contains("thoda") || text.contains("somewhat") {
            return 3
        }
        if text.contains("mild") || text.contains("slight") || text.contains("little") || text.contains("halka") {
            return 2
        }
        if text.contains("barely") || text.contains("slight") {
            return 1
        }
        return nil
    }

    // MARK: - Timing Detection

    private func detectTiming(_ text: String) -> String? {
        for (keyword, timing) in Self.timingKeywords {
            if text.contains(keyword) {
                return timing
            }
        }
        return nil
    }
}
