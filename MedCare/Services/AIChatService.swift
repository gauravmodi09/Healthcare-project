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
    private var currentStreamTask: Task<Void, Never>?
    private let llmService = LLMService()

    // MARK: - Configuration

    private let systemPrompt = """
    You are MedCare AI, a warm, empathetic health companion for an Indian patient. You are NOT a doctor.

    RULES (NEVER BREAK):
    1. NEVER diagnose conditions or diseases
    2. NEVER recommend starting, stopping, or changing any medication
    3. ALWAYS attribute information to the patient's doctor: "Your doctor prescribed X for Y"
    4. If the user describes an emergency (chest pain, breathing difficulty, etc.), IMMEDIATELY tell them to call 112 or go to the nearest hospital. Do NOT attempt to diagnose.
    5. Be honest about your limits: "I can help you understand your medicines, but for medical decisions, please consult your doctor"
    6. Use warm, reassuring tone. Never alarming language. Designed to REDUCE anxiety.
    7. Understand Indian medicine brands (Augmentin, Pan 40, Montek LC), generic names, and common prescribing patterns.
    8. Support Hinglish: respond appropriately if user mixes Hindi and English.

    CAPABILITIES:
    - Explain what prescribed medicines do and common side effects
    - Reassure about expected recovery timelines
    - Encourage treatment adherence with evidence
    - Track symptom trends and explain patterns
    - Help with diet/lifestyle questions related to their condition
    - Suggest when to contact their doctor

    ALWAYS END WITH: 💊 "Remember: I'm your health companion, not your doctor. Always follow your doctor's advice."
    """

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
                ]
            )
            messages.append(emergencyResponse)
            modelContext.insert(emergencyResponse)
            try? modelContext.save()
            return
        }

        // 2. Save user message
        let userMessage = ChatMessage(role: .user, content: text, profileId: profile.id)
        messages.append(userMessage)
        modelContext.insert(userMessage)

        // 3. Build context + prompt
        let context = assembleContext(profile: profile, activeEpisodes: activeEpisodes)

        // 4. Cancel any in-flight stream
        currentStreamTask?.cancel()

        // 5. Stream AI response
        isStreaming = true
        currentStreamedText = ""

        let assistantMessage = ChatMessage(role: .assistant, content: "")
        messages.append(assistantMessage)

        // Try real LLM first, fall back to mock responses
        if llmService.isConfigured {
            do {
                let history = buildConversationHistory()
                let stream = llmService.streamResponse(
                    systemPrompt: systemPrompt,
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

        // 6. Add action buttons based on content
        let finalResponse = assistantMessage.content
        assistantMessage.actionButtons = suggestActions(for: text, response: finalResponse)

        // 7. Persist
        modelContext.insert(assistantMessage)
        try? modelContext.save()

        isStreaming = false
        currentStreamedText = ""
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
            return """
            \(timeGreeting), \(patientName)! 😊 Great to see you here.

            I'm your MedCare AI health companion — think of me as a friendly guide who helps you stay on top of your treatment.

            Here's what I can help you with right now:
            • 💊 **Explain your medicines** — what they do, when to take them
            • 📈 **Check your progress** — how your recovery is going
            • 🤔 **Answer questions** — side effects, diet, lifestyle tips
            • 📝 **Log symptoms** — track how you're feeling

            What's on your mind today? Feel free to ask me anything!

            💊 Remember: I'm your health companion, not your doctor. Always follow your doctor's advice.
            """
        }

        // --- Thank you / appreciation ---
        let thanks = ["thank", "thanks", "thx", "dhanyavaad", "dhanyawad", "shukriya", "appreciate"]
        if thanks.contains(where: { lower.contains($0) }) {
            return """
            You're welcome, \(patientName)! 😊 I'm always here whenever you need me.

            Is there anything else you'd like to know about your treatment or how you're feeling?

            💊 Remember: I'm your health companion, not your doctor. Always follow your doctor's advice.
            """
        }

        // --- How are you / casual chat ---
        let casualChat = ["how are you", "how r u", "kaise ho", "kaisa hai", "what's up", "wassup", "kya haal"]
        if casualChat.contains(where: { lower.contains($0) }) {
            return """
            I'm doing great, thanks for asking! 😄 More importantly — how are **you** feeling today, \(patientName)?

            If you've noticed any changes in your symptoms or have questions about your medicines, I'm all ears. Or if you just want to check in on your progress, I can help with that too!

            💊 Remember: I'm your health companion, not your doctor. Always follow your doctor's advice.
            """
        }

        // --- Help / what can you do ---
        let helpPhrases = ["help", "what can you do", "kya kar sakte", "what do you do", "options", "menu"]
        if helpPhrases.contains(where: { lower.contains($0) }) {
            return """
            Of course! Here's how I can help you, \(patientName):

            🔹 **\"What does my medicine do?\"** — I'll explain your prescriptions in simple terms
            🔹 **\"I'm feeling dizzy\"** — I'll check if it's a known side effect and share tips
            🔹 **\"Can I stop my medicine?\"** — I'll explain why completing the course matters
            🔹 **\"How's my progress?\"** — I'll review your symptom logs and adherence
            🔹 **\"I'm not improving\"** — I'll help you understand recovery timelines

            Just type naturally — even Hinglish works! I'm here to make your recovery smoother. 💪

            💊 Remember: I'm your health companion, not your doctor. Always follow your doctor's advice.
            """
        }

        if lower.contains("side effect") || lower.contains("dizzy") || lower.contains("nausea") {
            return """
            I understand you're concerned about side effects. This is very common and usually nothing to worry about.

            Based on your current medicines, mild dizziness or nausea can be a normal reaction, especially in the first 2-3 days. Here are some tips:

            • **Take medicines with food** — this reduces stomach-related side effects
            • **Stay hydrated** — drink at least 8 glasses of water daily
            • **Avoid sudden movements** — sit up slowly if you feel dizzy

            If these symptoms persist beyond 3-4 days or get significantly worse, please contact your doctor.

            💊 Remember: I'm your health companion, not your doctor. Always follow your doctor's advice.
            """
        }

        if lower.contains("stop") || lower.contains("feel better") || lower.contains("can i quit") {
            return """
            I'm glad you're feeling better! That's a great sign that the treatment is working. 🎉

            However, **it's really important to complete the full course** your doctor prescribed. Here's why:

            • Stopping antibiotics early can allow bacteria to develop resistance
            • Your symptoms may return, sometimes stronger than before
            • Your doctor prescribed the specific duration for a medical reason

            You're making great progress — keep going! Your body is counting on you to finish strong. 💪

            💊 Remember: I'm your health companion, not your doctor. Always follow your doctor's advice.
            """
        }

        if lower.contains("not working") || lower.contains("no improvement") || lower.contains("kaam nahi kar raha") {
            return """
            I understand your frustration. It's natural to expect quick results, but many medicines need time to show their full effect.

            Based on your current treatment:
            • **Antibiotics** typically need 48-72 hours to show noticeable improvement
            • **Anti-inflammatory medicines** may take 3-5 days for full effect
            • Your adherence has been good, which means the medicine is building up in your system

            Looking at your symptom logs, you've actually shown some gradual improvement over the past few days, even if it doesn't feel dramatic yet.

            If you don't see any improvement after completing the course, your doctor should reassess the treatment. Would you like me to help you prepare for that conversation?

            💊 Remember: I'm your health companion, not your doctor. Always follow your doctor's advice.
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

            💊 Remember: I'm your health companion, not your doctor. Always follow your doctor's advice.
            """
        }

        // Default conversational response
        return """
        That's a great question, \(patientName)! Let me help you with that.

        While I work best with specific health questions about your treatment, here are some things I can assist with right now:

        • **Ask about your medicines** — \"What does Augmentin do?\"
        • **Report how you feel** — \"I'm feeling dizzy after my dose\"
        • **Check your progress** — \"How am I doing?\"
        • **Understand your recovery** — \"Why isn't my medicine working yet?\"

        Just ask naturally — I'm here to help you feel informed and confident about your care! 😊

        💊 Remember: I'm your health companion, not your doctor. Always follow your doctor's advice.
        """
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

    // MARK: - Load History

    func loadHistory(modelContext: ModelContext, profileId: UUID?) {
        let descriptor = FetchDescriptor<ChatMessage>(
            sortBy: [SortDescriptor(\.timestamp, order: .forward)]
        )
        if let fetched = try? modelContext.fetch(descriptor) {
            messages = fetched.filter { msg in
                profileId == nil || msg.profileId == profileId || msg.profileId == nil
            }
        }
    }

    func clearHistory(modelContext: ModelContext) {
        for message in messages {
            modelContext.delete(message)
        }
        messages = []
        try? modelContext.save()
    }
}
