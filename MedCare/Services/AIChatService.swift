import Foundation
import SwiftUI
import SwiftData

/// AI Health Chat Service — Context-aware medical companion
/// Handles context assembly, streaming LLM responses, and safety guardrails
@Observable
final class AIChatService {
    var isStreaming = false
    var currentStreamedText = ""
    var messages: [ChatMessage] = []
    var activeEmergency: EmergencyType?
    var currentSession: ChatSession?
    private var currentStreamTask: Task<Void, Never>?
    private let llmService = LLMService()
    private let memoryService = AIMemoryService()

    // MARK: - Configuration

    /// Builds the Medi system prompt with time-aware personality
    private var systemPrompt: String {
        let hour = Calendar.current.component(.hour, from: Date())
        let timePersonality: String
        switch hour {
        case 5..<12:
            timePersonality = """
            RIGHT NOW IT'S MORNING: Be energetic, upbeat, and motivating! Use phrases like "Great morning to stay healthy!", "Let's start the day strong!". Encourage morning medicine routines.
            """
        case 12..<17:
            timePersonality = """
            RIGHT NOW IT'S AFTERNOON: Be warm and steady. Check in on how their day is going. Remind about afternoon doses gently.
            """
        case 17..<21:
            timePersonality = """
            RIGHT NOW IT'S EVENING: Be calm, soothing, and reflective. Use a gentler tone. Phrases like "Hope you had a good day", "Let's wind down and make sure you're all set for tonight."
            """
        default:
            timePersonality = """
            RIGHT NOW IT'S LATE NIGHT: Be extra gentle and caring. Keep responses shorter and calmer. If they're up late with symptoms, be reassuring. "I'm here for you even at this hour."
            """
        }

        return """
        You are **Medi**, a warm, caring, and slightly playful AI health companion inside the MedCare app. You are NOT a doctor. You have a distinct personality — think of yourself as a knowledgeable, empathetic friend who genuinely cares about the patient's wellbeing.

        YOUR PERSONALITY:
        - Name: Medi (always introduce yourself as Medi in first interactions)
        - Tone: Warm, caring, slightly playful but always professional when it comes to health advice
        - You celebrate small wins and milestones enthusiastically ("Amazing! You've maintained a 7-day streak! 🎉")
        - You use encouraging language: "You're doing great!", "I'm proud of you for staying consistent"
        - You occasionally use natural Hindi/Hinglish phrases when it fits: "Bahut accha!", "Aapka health score kaafi improve hua hai!", "Koi baat nahi, kal se phir se shuru karein"
        - You're culturally aware of Indian context — festivals (Diwali, Holi, Navratri), seasons (monsoon health tips, summer hydration), and local medicine brands
        - You remember past conversations and reference them naturally: "Last time we talked, you mentioned headaches — are those better now?"

        \(timePersonality)

        EMOTIONAL INTELLIGENCE (CRITICAL — ALWAYS CHECK FIRST):
        Before giving ANY medical information, scan the user's message for emotional cues:
        - FRUSTRATION ("this isn't working", "I give up", "fed up", "thak gaya", "kaam nahi kar raha"): Acknowledge their frustration FIRST. "I completely understand how frustrating this must be. It's tough when you don't see results right away." THEN provide helpful info.
        - ANXIETY ("worried", "scared", "what if", "dar lag raha", "kya hoga"): Reassure FIRST. "I hear you, and it's completely natural to feel worried. Let me help ease your mind." Be extra gentle.
        - LOW MOOD ("feeling terrible", "depressed", "hopeless", "bahut bura lag raha", "mood kharab"): Show empathy FIRST. "I'm sorry you're going through this. Your feelings are completely valid." Suggest small, achievable wins.
        - CONFUSION ("I don't understand", "confused", "samajh nahi aa raha"): Be patient and simplify. "No worries at all! Let me explain this in a simpler way."
        - CELEBRATION ("feeling better", "good news", "improved", "accha feel ho raha"): Match their energy! "That's wonderful news! 🎉 Your dedication is paying off!"

        RULES (NEVER BREAK):
        1. NEVER diagnose conditions or diseases
        2. NEVER recommend starting, stopping, or changing any medication
        3. ALWAYS attribute information to the patient's doctor: "Your doctor prescribed X for Y"
        4. If the user describes an emergency (chest pain, breathing difficulty, etc.), IMMEDIATELY tell them to call 112 or go to the nearest hospital. Do NOT attempt to diagnose.
        5. Be honest about your limits: "I can help you understand your medicines, but for medical decisions, please consult your doctor"
        6. Use warm, reassuring tone. Never alarming language. Designed to REDUCE anxiety.
        7. Understand Indian medicine brands (Augmentin, Pan 40, Montek LC), generic names, and common prescribing patterns.
        8. Support Hinglish: respond appropriately if user mixes Hindi and English. Match their language style.

        CAPABILITIES:
        - Explain what prescribed medicines do and common side effects
        - Reassure about expected recovery timelines
        - Encourage treatment adherence with evidence
        - Track symptom trends and explain patterns
        - Help with diet/lifestyle questions related to their condition
        - Suggest when to contact their doctor
        - Celebrate streaks: adherence streaks, symptom-free days, completed courses

        RESPONSE FORMAT FOR HEALTH QUESTIONS:
        When the user asks about symptoms, medicines, side effects, or health concerns, structure your response using these markdown sections:

        ## What's Happening
        Brief explanation of the symptom or condition in simple, reassuring language.

        ## What to Do
        - Actionable advice point 1
        - Actionable advice point 2
        - Actionable advice point 3 (if needed)

        ## When to See a Doctor
        - Red flag 1 that warrants medical attention
        - Red flag 2 that warrants medical attention

        For normal conversational messages (greetings, thanks, casual chat), respond naturally without this structure. Be Medi — warm, personal, and memorable.

        ALWAYS END WITH: 💊 "Remember: I'm Medi, your health companion, not your doctor. Always follow your doctor's advice."

        After your response, include a JSON block with suggested follow-up questions. Format:
        ```json
        {"suggested_replies": ["Reply 1", "Reply 2", "Reply 3"]}
        ```
        Suggest 2-3 natural follow-up questions based on what you just discussed. Make them specific to the patient's medicines and symptoms.
        """
    }

    // MARK: - Health Question Detection

    /// Determines if the user message is about symptoms, medicines, side effects, or health concerns
    private func isHealthQuestion(_ text: String) -> Bool {
        let lower = text.lowercased()

        let symptomKeywords = [
            "pain", "ache", "fever", "cough", "cold", "dizzy", "dizziness",
            "nausea", "vomit", "headache", "weakness", "fatigue", "swelling",
            "rash", "itching", "burning", "bleeding", "breathless", "sore throat",
            "diarrhea", "constipation", "stomach", "chest", "back pain",
            "joint pain", "muscle pain", "cramp", "infection", "allergy",
            "dard", "bukhar", "khansi", "chakkar", "ulti", "sujan", "kamzori"
        ]

        let medicineKeywords = [
            "medicine", "tablet", "capsule", "dose", "dosage", "drug",
            "antibiotic", "prescribed", "side effect", "reaction",
            "interaction", "overdose", "missed dose", "take with food",
            "empty stomach", "before meal", "after meal", "dawai", "goli",
            "augmentin", "pan 40", "montek", "azithromycin", "paracetamol",
            "ibuprofen", "amoxicillin", "cetirizine", "omeprazole"
        ]

        let healthKeywords = [
            "symptom", "diagnosis", "condition", "disease", "treatment",
            "recovery", "healing", "blood pressure", "sugar level", "bp",
            "diabetes", "thyroid", "cholesterol", "uric acid", "vitamin",
            "immunity", "diet", "food to avoid", "exercise",
            "bimari", "ilaj", "theek", "health", "healthy"
        ]

        let allKeywords = symptomKeywords + medicineKeywords + healthKeywords
        return allKeywords.contains { lower.contains($0) }
    }

    // MARK: - Memory Enhancement

    /// Enhances the system prompt with memory from previous chat sessions
    func enhanceContextWithMemory(
        systemPrompt: String,
        profileId: UUID,
        modelContext: ModelContext
    ) -> String {
        let memorySummary = memoryService.getMemorySummary(for: profileId, modelContext: modelContext)
        guard !memorySummary.isEmpty else { return systemPrompt }
        return systemPrompt + memorySummary
    }

    // MARK: - Context Assembly

    /// Builds a rich context string from the patient's data for the LLM
    func assembleContext(
        profile: UserProfile,
        activeEpisodes: [Episode]
    ) -> String {
        var context = "PATIENT CONTEXT:\n"
        context += "- Name: \(profile.name)\n"
        if let age = profile.age { context += "- Age: \(age)\n" }
        if let gender = profile.gender { context += "- Gender: \(gender.rawValue)\n" }
        if !profile.knownConditions.isEmpty {
            context += "- Known Conditions: \(profile.knownConditions.joined(separator: ", "))\n"
        }
        if !profile.allergies.isEmpty {
            context += "- Allergies: \(profile.allergies.joined(separator: ", "))\n"
        }

        for episode in activeEpisodes {
            context += "\nACTIVE EPISODE: \(episode.title)\n"
            if let diag = episode.diagnosis { context += "  Diagnosis: \(diag)\n" }
            if let doc = episode.doctorName { context += "  Doctor: \(doc)\n" }
            context += "  Status: \(episode.status.displayName)\n"
            context += "  Adherence: \(Int(episode.adherencePercentage * 100))%\n"

            if let remaining = episode.daysRemaining {
                context += "  Days remaining: \(remaining)\n"
            }

            // Active medicines
            let activeMeds = episode.activeMedicines
            if !activeMeds.isEmpty {
                context += "  Current Medicines:\n"
                for med in activeMeds {
                    context += "    - \(med.brandName) (\(med.genericName ?? "")) \(med.dosage) — \(med.frequency.rawValue)\n"
                    if let instructions = med.instructions {
                        context += "      Instructions: \(instructions)\n"
                    }
                    if let duration = med.duration {
                        context += "      Duration: \(duration) days\n"
                    }
                }
            }

            // Recent symptoms
            let recentSymptoms = episode.symptomLogs
                .sorted { $0.date > $1.date }
                .prefix(5)
            if !recentSymptoms.isEmpty {
                context += "  Recent Symptom Logs:\n"
                for log in recentSymptoms {
                    let dateStr = log.date.formatted(date: .abbreviated, time: .omitted)
                    let symptoms = log.symptoms.map { "\($0.name) (\($0.severity.label))" }.joined(separator: ", ")
                    context += "    - \(dateStr): Feeling \(log.overallFeeling.label), Symptoms: \(symptoms)\n"
                }
            }

            // Recent adherence data
            let allLogs = activeMeds.flatMap { $0.doseLogs }
            let recentLogs = allLogs.sorted { $0.scheduledTime > $1.scheduledTime }.prefix(10)
            let missedCount = recentLogs.filter { $0.status == .missed || $0.status == .skipped }.count
            if missedCount > 0 {
                context += "  ⚠️ Missed/Skipped \(missedCount) of last \(recentLogs.count) doses\n"
            }
        }

        return context
    }

    // MARK: - Emergency Detection

    /// Scans user input for emergency keywords BEFORE sending to LLM
    func detectEmergency(in text: String) -> EmergencyType? {
        let lowered = text.lowercased()
        for emergencyType in EmergencyType.allCases {
            for keyword in emergencyType.keywords {
                if lowered.contains(keyword) {
                    return emergencyType
                }
            }
        }
        return nil
    }

    // MARK: - Send Message (Streaming)

    /// Sends a user message and streams the AI response
    func sendMessage(
        _ text: String,
        profile: UserProfile,
        activeEpisodes: [Episode],
        modelContext: ModelContext
    ) async {
        // 1. Check for emergencies FIRST
        if let emergency = detectEmergency(in: text) {
            activeEmergency = emergency
            let emergencyResponse = ChatMessage(
                role: .assistant,
                content: "🚨 **This sounds like a medical emergency.** Please call **112** immediately or go to your nearest hospital. Do NOT wait.\n\nI am not a doctor and cannot help with emergencies. Your safety comes first.",
                isEmergency: true,
                actionButtons: [
                    ChatAction(title: "📞 Call 112", type: .callEmergency, payload: "112"),
                    ChatAction(title: "🏥 Nearest Hospital", type: .openURL, payload: "maps://?q=hospital+near+me")
                ],
                sessionId: currentSession?.id
            )
            messages.append(emergencyResponse)
            modelContext.insert(emergencyResponse)
            updateSession(modelContext: modelContext)
            try? modelContext.save()
            return
        }

        // 2. Save user message
        let userMessage = ChatMessage(role: .user, content: text, profileId: profile.id, sessionId: currentSession?.id)
        messages.append(userMessage)
        modelContext.insert(userMessage)

        // Auto-title session from first user message
        if let session = currentSession, session.title == "New Chat" {
            let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
            session.title = String(trimmed.prefix(40))
        }

        // 3. Build context + prompt
        let context = assembleContext(profile: profile, activeEpisodes: activeEpisodes)

        // 3.5. Enhance system prompt with memory + health question formatting
        memoryService.detectLanguagePreference(from: text)
        var effectiveSystemPrompt = enhanceContextWithMemory(
            systemPrompt: systemPrompt,
            profileId: profile.id,
            modelContext: modelContext
        )
        if isHealthQuestion(text) {
            effectiveSystemPrompt += "\n\nIMPORTANT: The user is asking a health/symptom/medicine question. Use the structured format with ## What's Happening, ## What to Do, and ## When to See a Doctor sections."
        }

        // 4. Cancel any in-flight stream
        currentStreamTask?.cancel()

        // 5. Stream AI response
        isStreaming = true
        currentStreamedText = ""

        let assistantMessage = ChatMessage(role: .assistant, content: "", sessionId: currentSession?.id)
        messages.append(assistantMessage)

        // Try real LLM first, fall back to mock responses
        if llmService.isConfigured {
            do {
                let history = buildConversationHistory()
                let stream = llmService.streamResponse(
                    systemPrompt: effectiveSystemPrompt,
                    context: context,
                    conversationHistory: history,
                    userMessage: text
                )
                for try await token in stream {
                    currentStreamedText += token
                    assistantMessage.content = currentStreamedText
                }
            } catch {
                // LLM failed — fall back to mock if nothing was streamed yet
                if currentStreamedText.isEmpty {
                    let response = await generateMockResponse(for: text, context: context)
                    currentStreamedText = response
                    assistantMessage.content = response
                }
            }
        } else {
            // No API key — use mock responses with simulated streaming
            let response = await generateMockResponse(for: text, context: context)
            for char in response {
                currentStreamedText += String(char)
                assistantMessage.content = currentStreamedText
                try? await Task.sleep(nanoseconds: 30_000_000)
            }
        }

        // 6. Extract suggested replies from LLM response
        let (cleanText, extractedReplies) = extractSuggestedReplies(from: assistantMessage.content)
        assistantMessage.content = cleanText
        if !extractedReplies.isEmpty {
            assistantMessage.suggestedReplies = extractedReplies
        } else {
            assistantMessage.suggestedReplies = fallbackSuggestedReplies(for: cleanText)
        }

        // 7. Add action buttons based on content
        let finalResponse = assistantMessage.content
        assistantMessage.actionButtons = suggestActions(for: text, response: finalResponse)

        // 8. Persist
        modelContext.insert(assistantMessage)
        updateSession(modelContext: modelContext)
        try? modelContext.save()

        isStreaming = false
        currentStreamedText = ""
    }

    // MARK: - Suggested Replies Extraction

    /// Extracts suggested reply chips from the LLM response JSON block, returning clean text and replies
    private func extractSuggestedReplies(from text: String) -> (cleanText: String, replies: [String]) {
        // Try to find JSON block in ```json ... ``` fenced code block
        let fencedPattern = "```json\\s*\\n?\\s*\\{\\s*\"suggested_replies\"\\s*:\\s*\\[.*?\\]\\s*\\}\\s*\\n?\\s*```"
        if let fencedRange = text.range(of: fencedPattern, options: .regularExpression) {
            let jsonBlock = String(text[fencedRange])
            let cleanText = text.replacingCharacters(in: fencedRange, with: "").trimmingCharacters(in: .whitespacesAndNewlines)
            if let replies = parseRepliesJSON(from: jsonBlock) {
                return (cleanText, replies)
            }
        }

        // Try to find raw JSON block without fences
        let rawPattern = "\\{\\s*\"suggested_replies\"\\s*:\\s*\\[.*?\\]\\s*\\}"
        if let rawRange = text.range(of: rawPattern, options: .regularExpression) {
            let jsonBlock = String(text[rawRange])
            let cleanText = text.replacingCharacters(in: rawRange, with: "").trimmingCharacters(in: .whitespacesAndNewlines)
            if let replies = parseRepliesJSON(from: jsonBlock) {
                return (cleanText, replies)
            }
        }

        return (text, [])
    }

    /// Parses the suggested_replies array from a JSON string
    private func parseRepliesJSON(from jsonString: String) -> [String]? {
        // Extract just the JSON object portion
        guard let startIndex = jsonString.firstIndex(of: "{"),
              let endIndex = jsonString.lastIndex(of: "}") else { return nil }
        let jsonSubstring = String(jsonString[startIndex...endIndex])
        guard let data = jsonSubstring.data(using: .utf8),
              let parsed = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let replies = parsed["suggested_replies"] as? [String],
              !replies.isEmpty else { return nil }
        return replies
    }

    /// Rule-based fallback chips when LLM doesn't provide suggested_replies
    private func fallbackSuggestedReplies(for response: String) -> [String] {
        let lower = response.lowercased()

        // Check for symptom-related content
        let symptomKeywords = ["symptom", "pain", "dizzy", "nausea", "headache", "fever", "cough", "vomiting", "fatigue", "weakness", "swelling"]
        if symptomKeywords.contains(where: { lower.contains($0) }) {
            return ["Log this symptom", "Is this a side effect?"]
        }

        // Check for medicine-related content
        let medicineKeywords = ["medicine", "tablet", "capsule", "dose", "antibiotic", "prescribed", "augmentin", "pan 40", "montek", "medication"]
        if medicineKeywords.contains(where: { lower.contains($0) }) {
            return ["Other side effects?", "When should I take it?"]
        }

        // Check for progress-related content
        let progressKeywords = ["progress", "recovery", "improvement", "timeline", "adherence", "getting better", "how long"]
        if progressKeywords.contains(where: { lower.contains($0) }) {
            return ["View my timeline", "How can I improve?"]
        }

        // Default chips
        return ["My medicines", "My progress", "Side effects?"]
    }

    // MARK: - Conversation History

    /// Converts recent chat messages to LLMMessage format for the API
    private func buildConversationHistory() -> [LLMMessage] {
        messages
            .filter { $0.role == .user || $0.role == .assistant }
            .suffix(10)
            .compactMap { msg in
                guard !msg.content.isEmpty else { return nil }
                return LLMMessage(role: msg.role.rawValue, content: msg.content)
            }
    }

    // MARK: - Action Suggestions

    private func suggestActions(for userText: String, response: String) -> [ChatAction] {
        var actions: [ChatAction] = []
        let lower = userText.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)

        // Greetings & casual → show quick-start options
        let greetings = ["hello", "hi", "hey", "hola", "namaste", "namaskar", "yo", "sup", "good morning", "good afternoon", "good evening", "howdy", "hii", "hiii", "help", "what can you do", "menu"]
        let isGreeting = greetings.contains(where: { lower == $0 || lower.hasPrefix($0 + " ") || lower.hasPrefix($0 + "!") || lower.hasPrefix($0 + ",") })

        if isGreeting {
            actions.append(ChatAction(title: "💊 My Medicines", type: .viewEpisode))
            actions.append(ChatAction(title: "📝 Log Symptom", type: .logSymptom))
            actions.append(ChatAction(title: "📊 My Progress", type: .viewTimeline))
            return actions
        }

        if lower.contains("symptom") || lower.contains("feeling") || lower.contains("pain") || lower.contains("dizzy") || lower.contains("nausea") {
            actions.append(ChatAction(title: "📝 Log Symptom", type: .logSymptom))
            actions.append(ChatAction(title: "👨‍⚕️ Talk to Doctor", type: .callDoctor))
        }
        if lower.contains("doctor") || lower.contains("appointment") || lower.contains("consult") {
            actions.append(ChatAction(title: "👨‍⚕️ Talk to Doctor", type: .callDoctor))
        }
        if lower.contains("progress") || lower.contains("how long") || lower.contains("timeline") || lower.contains("how am i") {
            actions.append(ChatAction(title: "📊 View Timeline", type: .viewTimeline))
        }
        if lower.contains("not working") || lower.contains("no improvement") || lower.contains("worse") {
            actions.append(ChatAction(title: "👨‍⚕️ Talk to Doctor", type: .callDoctor))
            actions.append(ChatAction(title: "📊 View Timeline", type: .viewTimeline))
        }

        return actions
    }

    // MARK: - Mock Response Generator

    /// Generates contextual mock responses until real API is connected
    private func generateMockResponse(for userText: String, context: String) async -> String {
        let lower = userText.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)

        // Add a small delay to simulate network
        try? await Task.sleep(nanoseconds: 500_000_000)

        // Extract patient name from context
        let patientName = extractName(from: context)

        // --- Greetings ---
        let greetings = ["hello", "hi", "hey", "hola", "namaste", "namaskar", "yo", "sup", "good morning", "good afternoon", "good evening", "howdy", "hii", "hiii", "hiiii"]
        if greetings.contains(where: { lower == $0 || lower.hasPrefix($0 + " ") || lower.hasPrefix($0 + "!") || lower.hasPrefix($0 + ",") }) {
            let timeGreeting = Self.timeBasedGreeting()
            let hour = Calendar.current.component(.hour, from: Date())
            let energyNote: String
            switch hour {
            case 5..<12:
                energyNote = "Let's start the day strong! 💪"
            case 12..<17:
                energyNote = "Hope your day is going well so far!"
            case 17..<21:
                energyNote = "Hope you had a good day! Let's make sure everything's on track for tonight."
            default:
                energyNote = "I'm here for you even at this hour 🌙"
            }
            return """
            \(timeGreeting), \(patientName)! 😊 I'm **Medi**, your health companion.

            \(energyNote)

            Here's what I can help you with:
            • 💊 **Explain your medicines** — what they do, when to take them
            • 📈 **Check your progress** — how your recovery is going
            • 🤔 **Answer questions** — side effects, diet, lifestyle tips
            • 📝 **Log symptoms** — track how you're feeling

            Aapko kisi bhi cheez mein help chahiye toh bas pooch lijiye! 😊

            💊 Remember: I'm Medi, your health companion, not your doctor. Always follow your doctor's advice.
            """
        }

        // --- Thank you / appreciation ---
        let thanks = ["thank", "thanks", "thx", "dhanyavaad", "dhanyawad", "shukriya", "appreciate"]
        if thanks.contains(where: { lower.contains($0) }) {
            return """
            You're welcome, \(patientName)! 😊 Medi is always here for you — din ho ya raat!

            Is there anything else you'd like to know about your treatment or how you're feeling?

            💊 Remember: I'm Medi, your health companion, not your doctor. Always follow your doctor's advice.
            """
        }

        // --- How are you / casual chat ---
        let casualChat = ["how are you", "how r u", "kaise ho", "kaisa hai", "what's up", "wassup", "kya haal"]
        if casualChat.contains(where: { lower.contains($0) }) {
            return """
            Main bilkul theek hoon, shukriya! 😄 But more importantly — how are **you** feeling today, \(patientName)?

            If you've noticed any changes in your symptoms or have questions about your medicines, I'm all ears. Or if you just want to check in on your progress, Medi is here for you!

            💊 Remember: I'm Medi, your health companion, not your doctor. Always follow your doctor's advice.
            """
        }

        // --- Help / what can you do ---
        let helpPhrases = ["help", "what can you do", "kya kar sakte", "what do you do", "options", "menu"]
        if helpPhrases.contains(where: { lower.contains($0) }) {
            return """
            Of course! Here's how Medi can help you, \(patientName):

            🔹 **\"What does my medicine do?\"** — I'll explain your prescriptions in simple terms
            🔹 **\"I'm feeling dizzy\"** — I'll check if it's a known side effect and share tips
            🔹 **\"Can I stop my medicine?\"** — I'll explain why completing the course matters
            🔹 **\"How's my progress?\"** — I'll review your symptom logs and adherence
            🔹 **\"I'm not improving\"** — I'll help you understand recovery timelines

            Just type naturally — Hinglish bhi chalega! I'm here to make your recovery smoother. 💪

            💊 Remember: I'm Medi, your health companion, not your doctor. Always follow your doctor's advice.
            """
        }

        if lower.contains("side effect") || lower.contains("dizzy") || lower.contains("nausea") {
            return """
            ## What's Happening
            Mild dizziness or nausea is a common reaction to many medicines, especially antibiotics. This is usually your body adjusting to the medication and tends to settle within the first 2-3 days.

            ## What to Do
            - **Take medicines with food** — this reduces stomach-related side effects significantly
            - **Stay hydrated** — drink at least 8 glasses of water daily to help your body process the medicine
            - **Avoid sudden movements** — sit up slowly if you feel dizzy, especially after lying down

            ## When to See a Doctor
            - Symptoms persist beyond 3-4 days or get significantly worse
            - You experience severe vomiting, rash, or difficulty breathing
            - Dizziness causes falls or fainting episodes

            💊 Remember: I'm Medi, your health companion, not your doctor. Always follow your doctor's advice.
            """
        }

        if lower.contains("stop") || lower.contains("feel better") || lower.contains("can i quit") {
            return """
            That's amazing news, \(patientName)! 🎉 Bahut accha! I'm so happy the treatment is working!

            However, **it's really important to complete the full course** your doctor prescribed. Here's why:

            • Stopping antibiotics early can allow bacteria to develop resistance
            • Your symptoms may return, sometimes stronger than before
            • Your doctor prescribed the specific duration for a medical reason

            You're doing SO well — don't stop now! Thoda aur patience, and you'll cross the finish line strong! 💪

            💊 Remember: I'm Medi, your health companion, not your doctor. Always follow your doctor's advice.
            """
        }

        if lower.contains("not working") || lower.contains("no improvement") || lower.contains("kaam nahi kar raha") {
            return """
            I completely understand how frustrating this must be, \(patientName). It's tough when you don't see results right away, and your feelings are totally valid. 🤗 Let me help explain what might be happening.

            ## What's Happening
            Many medicines need time to build up in your system. Antibiotics typically need 48-72 hours, and anti-inflammatory medicines may take 3-5 days for their full effect. Your adherence has been good, which means the medicine is working behind the scenes — aapki mehnat rang laayegi!

            ## What to Do
            - **Continue the full course** — stopping early can make the infection harder to treat next time
            - **Track your symptoms daily** — small improvements add up even if they don't feel dramatic yet
            - **Prepare questions for your doctor** — if no improvement after completing the course, your doctor can reassess

            ## When to See a Doctor
            - No improvement at all after completing the full course
            - Symptoms are getting worse instead of staying stable
            - New symptoms appear that weren't there before

            💊 Remember: I'm Medi, your health companion, not your doctor. Always follow your doctor's advice.
            """
        }

        if lower.contains("what is") || lower.contains("what does") || lower.contains("kya hai") {
            return """
            Great question! Let me explain based on what your doctor has prescribed for you.

            Your current medicines are working together as a team:
            • One fights the infection directly
            • Another protects your stomach from the antibiotic's effects
            • The third helps manage your symptoms (cough, congestion) so you feel more comfortable

            Each medicine has a specific role, and they work best when taken together at the times your doctor recommended.

            Would you like me to explain any specific medicine in more detail?

            💊 Remember: I'm Medi, your health companion, not your doctor. Always follow your doctor's advice.
            """
        }

        // Default conversational response
        return """
        That's a great question, \(patientName)! Medi is here to help 😊

        While I work best with specific health questions about your treatment, here are some things I can assist with right now:

        • **Ask about your medicines** — \"What does Augmentin do?\"
        • **Report how you feel** — \"I'm feeling dizzy after my dose\"
        • **Check your progress** — \"How am I doing?\"
        • **Understand your recovery** — \"Why isn't my medicine working yet?\"

        Just ask naturally — Hinglish bhi chalega! I'm here to help you feel informed and confident about your care! 😊

        💊 Remember: I'm Medi, your health companion, not your doctor. Always follow your doctor's advice.
        """
    }

    // MARK: - Missed Dose Guidance

    /// Generates specific guidance when a dose is missed, considering how late it is and medicine criticality
    func generateMissedDoseGuidance(medicine: Medicine, missedTime: Date) -> String {
        let now = Date()
        let minutesLate = Int(now.timeIntervalSince(missedTime) / 60)
        let hoursLate = minutesLate / 60
        let remainingMinutes = minutesLate % 60

        let lateDescription: String
        if hoursLate == 0 {
            lateDescription = "\(minutesLate) minutes"
        } else if remainingMinutes == 0 {
            lateDescription = "\(hoursLate) hour\(hoursLate == 1 ? "" : "s")"
        } else {
            lateDescription = "\(hoursLate) hour\(hoursLate == 1 ? "" : "s") and \(remainingMinutes) minutes"
        }

        // Critical medicines — always recommend contacting doctor
        let criticalGenericNames = ["warfarin", "heparin", "insulin", "enoxaparin",
                                     "dabigatran", "rivaroxaban", "apixaban", "clopidogrel"]
        let isCriticalMedicine = medicine.isCritical ||
            criticalGenericNames.contains(where: { medicine.genericName?.lowercased().contains($0) == true }) ||
            criticalGenericNames.contains(where: { medicine.brandName.lowercased().contains($0) == true })

        if isCriticalMedicine {
            return """
            ## Missed Dose: \(medicine.brandName) \(medicine.dosage)
            You're **\(lateDescription) late** for this dose.

            ## What to Do
            - **Contact your doctor or pharmacist immediately** — \(medicine.brandName) is a critical medicine that needs precise timing
            - **Do NOT take a double dose** to make up for the missed one
            - Note the exact time you missed it when speaking with your doctor

            ## When to See a Doctor
            - Always consult your doctor about missed doses of \(medicine.brandName)
            - If you experience any unusual symptoms (bleeding, dizziness, unusual bruising)
            - If you've missed more than one dose

            💊 Remember: I'm Medi, your health companion, not your doctor. Always follow your doctor's advice.
            """
        }

        // Less than 2 hours late — take it now
        if minutesLate < 120 {
            return """
            ## Missed Dose: \(medicine.brandName) \(medicine.dosage)
            You're **\(lateDescription) late** for this dose — not too bad!

            ## What to Do
            - **Take it now** — you're still within a safe window
            - Resume your normal schedule for the next dose
            - Don't double up on the next dose

            ## When to See a Doctor
            - If you're frequently forgetting doses (3+ times a week)
            - If you notice your symptoms getting worse after missed doses
            - If you're unsure whether to take it this late

            💊 Remember: I'm Medi, your health companion, not your doctor. Always follow your doctor's advice.
            """
        }

        // More than 2 hours late — skip and resume
        let nextDoseInfo: String
        if let nextDose = medicine.nextDoseTime {
            let formatter = DateFormatter()
            formatter.timeStyle = .short
            nextDoseInfo = "Your next dose is at **\(formatter.string(from: nextDose))**."
        } else {
            nextDoseInfo = "Take the next dose at your regular time."
        }

        return """
        ## Missed Dose: \(medicine.brandName) \(medicine.dosage)
        You're **\(lateDescription) late** for this dose.

        ## What to Do
        - **Skip this dose** — it's too close to your next scheduled dose to take it safely
        - \(nextDoseInfo) Take it on time.
        - **Don't double up** on the next dose to make up for the missed one

        ## When to See a Doctor
        - If you're frequently missing doses and struggling with the schedule
        - If your symptoms have been getting worse recently
        - If you want to discuss adjusting your medicine timing

        💊 Remember: I'm Medi, your health companion, not your doctor. Always follow your doctor's advice.
        """
    }

    /// Pre-loads the AI chat with missed dose guidance when triggered from a nudge
    func handleMissedDoseNudge(
        medicine: Medicine,
        missedTime: Date,
        modelContext: ModelContext
    ) {
        let guidance = generateMissedDoseGuidance(medicine: medicine, missedTime: missedTime)

        // Add the user question
        let userMessage = ChatMessage(
            role: .user,
            content: "I missed my dose of \(medicine.brandName) \(medicine.dosage). What should I do?",
            sessionId: currentSession?.id
        )
        messages.append(userMessage)
        modelContext.insert(userMessage)

        // Add the AI guidance response
        let assistantMessage = ChatMessage(
            role: .assistant,
            content: guidance,
            suggestedReplies: [
                "Can I take it now?",
                "Will this affect my recovery?",
                "How do I set better reminders?"
            ],
            sessionId: currentSession?.id
        )
        assistantMessage.actionButtons = [
            ChatAction(title: "⏰ Set Reminder", type: .viewEpisode),
            ChatAction(title: "👨‍⚕️ Talk to Doctor", type: .callDoctor)
        ]
        messages.append(assistantMessage)
        modelContext.insert(assistantMessage)

        updateSession(modelContext: modelContext)
        try? modelContext.save()
    }

    // MARK: - Helpers

    /// Returns a time-appropriate greeting
    private static func timeBasedGreeting() -> String {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 5..<12: return "Good morning"
        case 12..<17: return "Good afternoon"
        case 17..<21: return "Good evening"
        default: return "Hey there"
        }
    }

    /// Extracts patient name from context string
    private func extractName(from context: String) -> String {
        for line in context.components(separatedBy: "\n") {
            if line.contains("- Name:") {
                return line.replacingOccurrences(of: "- Name:", with: "").trimmingCharacters(in: .whitespaces)
            }
        }
        return "there"
    }

    // MARK: - Session Management

    /// Creates a new chat session and sets it as the current session
    func startNewSession(profileId: UUID, modelContext: ModelContext) {
        let session = ChatSession(profileId: profileId)
        modelContext.insert(session)
        try? modelContext.save()
        currentSession = session
        messages = []
    }

    /// Loads the most recent session for today, or creates a new one
    func loadOrCreateSession(profileId: UUID, modelContext: ModelContext) {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: Date())

        let descriptor = FetchDescriptor<ChatSession>(
            predicate: #Predicate<ChatSession> { session in
                session.profileId == profileId && session.createdAt >= startOfDay
            },
            sortBy: [SortDescriptor(\.updatedAt, order: .reverse)]
        )

        if let sessions = try? modelContext.fetch(descriptor), let existing = sessions.first {
            currentSession = existing
            loadHistory(modelContext: modelContext, profileId: profileId)
        } else {
            startNewSession(profileId: profileId, modelContext: modelContext)
        }
    }

    /// Loads a specific session by setting it as current and fetching its messages
    func loadSession(_ session: ChatSession, modelContext: ModelContext) {
        currentSession = session
        loadHistory(modelContext: modelContext, profileId: session.profileId)
    }

    /// Updates the current session's metadata (updatedAt, messageCount)
    private func updateSession(modelContext: ModelContext) {
        guard let session = currentSession else { return }
        session.updatedAt = Date()
        session.messageCount = messages.filter { $0.role == .user || $0.role == .assistant }.count
    }

    // MARK: - Load History

    func loadHistory(modelContext: ModelContext, profileId: UUID?) {
        let descriptor = FetchDescriptor<ChatMessage>(
            sortBy: [SortDescriptor(\.timestamp, order: .forward)]
        )
        if let fetched = try? modelContext.fetch(descriptor) {
            if let sessionId = currentSession?.id {
                messages = fetched.filter { $0.sessionId == sessionId }
            } else {
                messages = fetched.filter { msg in
                    profileId == nil || msg.profileId == profileId || msg.profileId == nil
                }
            }
        }
    }

    func clearHistory(modelContext: ModelContext) {
        for message in messages {
            modelContext.delete(message)
        }
        messages = []
        if let session = currentSession {
            session.messageCount = 0
        }
        try? modelContext.save()
    }
}
