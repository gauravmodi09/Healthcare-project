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

        // 4. Stream AI response
        isStreaming = true
        currentStreamedText = ""

        let assistantMessage = ChatMessage(role: .assistant, content: "")
        messages.append(assistantMessage)

        // Use mock streaming for now — replace with real API call later
        let response = await generateMockResponse(for: text, context: context)

        // Simulate token-by-token streaming
        for char in response {
            currentStreamedText += String(char)
            assistantMessage.content = currentStreamedText

            // Pace the streaming (~30ms per character for natural feel)
            try? await Task.sleep(nanoseconds: 30_000_000)
        }

        // 5. Add action buttons based on content
        assistantMessage.actionButtons = suggestActions(for: text, response: response)

        // 6. Persist
        modelContext.insert(assistantMessage)
        try? modelContext.save()

        isStreaming = false
        currentStreamedText = ""
    }

    // MARK: - Action Suggestions

    private func suggestActions(for userText: String, response: String) -> [ChatAction] {
        var actions: [ChatAction] = []
        let lower = userText.lowercased()

        if lower.contains("symptom") || lower.contains("feeling") || lower.contains("pain") {
            actions.append(ChatAction(title: "📝 Log Symptom", type: .logSymptom))
        }
        if lower.contains("doctor") || lower.contains("appointment") || lower.contains("consult") {
            actions.append(ChatAction(title: "👨‍⚕️ Talk to Doctor", type: .callDoctor))
        }
        if lower.contains("progress") || lower.contains("how long") || lower.contains("timeline") {
            actions.append(ChatAction(title: "📊 View Timeline", type: .viewTimeline))
        }

        return actions
    }

    // MARK: - Mock Response Generator

    /// Generates contextual mock responses until real API is connected
    private func generateMockResponse(for userText: String, context: String) async -> String {
        let lower = userText.lowercased()

        // Add a small delay to simulate network
        try? await Task.sleep(nanoseconds: 500_000_000)

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

        // Default supportive response
        return """
        Thank you for sharing that with me. I want you to know that I'm here to help you understand your treatment better.

        Based on your current care plan, you're on the right track. Your adherence has been consistent, and that's the most important thing for recovery.

        Here are a few things that might help:
        • Keep taking your medicines at the scheduled times
        • Log your symptoms daily so we can track your progress
        • Stay hydrated and get adequate rest

        Is there anything specific about your treatment you'd like to know more about?

        💊 Remember: I'm your health companion, not your doctor. Always follow your doctor's advice.
        """
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
