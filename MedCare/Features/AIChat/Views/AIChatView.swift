import SwiftUI
import SwiftData

/// Main AI Chat screen — the core Phase 2.5 feature
struct AIChatView: View {
    @Environment(AIChatService.self) private var chatService
    @Environment(\.modelContext) private var modelContext
    @State private var speechService = SpeechService()
    @State private var messageText = ""
    @FocusState private var isInputFocused: Bool
    @Environment(\.dismiss) private var dismiss
    @State private var showSymptomLog = false
    @State private var showTimeline = false

    let profile: UserProfile

    var body: some View {
        ZStack {
            Color(hex: "F7F9FC")
                .ignoresSafeArea()

            VStack(spacing: 0) {
                // Header
                chatHeader

                // Disclaimer banner
                disclaimerBanner

                // Greeting banner (only when chat is fresh)
                if chatService.messages.count <= 1 {
                    mediGreetingBanner
                }

                // Messages
                messagesList

                // Quick action chips at start, dynamic chips after conversation
                if !chatService.isStreaming {
                    if chatService.messages.count <= 1 {
                        quickActionChips
                    } else {
                        quickReplyChips
                    }
                }

                // Input bar
                inputBar
            }

            // Emergency overlay
            if let emergency = chatService.activeEmergency {
                EmergencyAlertView(emergencyType: emergency) {
                    chatService.activeEmergency = nil
                }
                .transition(.opacity)
                .zIndex(100)
            }
        }
        .navigationBarHidden(true)
        .dynamicTypeSize(.xSmall ... .accessibility3)
        .sheet(isPresented: $showSymptomLog) {
            if let episode = profile.episodes.first(where: { $0.status == .active }) {
                SymptomLogView(episodeId: episode.id)
            }
        }
        .sheet(isPresented: $showTimeline) {
            if let episode = profile.episodes.first(where: { $0.status == .active }) {
                NavigationStack {
                    TreatmentTimelineView(episode: episode)
                        .toolbar {
                            ToolbarItem(placement: .topBarTrailing) {
                                Button("Done") { showTimeline = false }
                            }
                        }
                }
            }
        }
        .onAppear {
            chatService.loadHistory(modelContext: modelContext, profileId: profile.id)
            if chatService.messages.isEmpty {
                addWelcomeMessage()
            }
        }
    }

    // MARK: - Header

    private var chatHeader: some View {
        HStack {
            Button {
                dismiss()
            } label: {
                Image(systemName: "chevron.left")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(Color(hex: "1F2937"))
            }

            Spacer()

            VStack(spacing: 2) {
                HStack(spacing: 6) {
                    Image(systemName: "stethoscope.circle.fill")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(MCColors.primaryTeal)
                    Text("Medi")
                        .font(.headline)
                        .foregroundColor(MCColors.textPrimary)
                }
                Text("Your Health Companion")
                    .font(.caption)
                    .foregroundColor(MCColors.textSecondary)
            }

            Spacer()

            // Clear chat
            Menu {
                Button(role: .destructive) {
                    chatService.clearHistory(modelContext: modelContext)
                    addWelcomeMessage()
                } label: {
                    Label("Clear Chat", systemImage: "trash")
                }
            } label: {
                Image(systemName: "ellipsis.circle")
                    .font(.system(size: 20))
                    .foregroundColor(.secondary)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(.ultraThinMaterial)
    }

    // MARK: - Disclaimer

    private var disclaimerBanner: some View {
        HStack(spacing: 6) {
            Image(systemName: "info.circle.fill")
                .font(.system(size: 12))
            Text("I'm your health companion, not your doctor. Always follow your doctor's advice.")
                .font(.caption2.weight(.medium))
        }
        .foregroundColor(Color(hex: "0A7E8C"))
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .frame(maxWidth: .infinity)
        .background(Color(hex: "0A7E8C").opacity(0.08))
    }

    // MARK: - Messages List

    private var messagesList: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(spacing: 12) {
                    ForEach(Array(chatService.messages.enumerated()), id: \.element.id) { index, message in
                        if message.role != .system {
                            VStack(alignment: .leading, spacing: 4) {
                                if !message.role.isUser && (index == 0 || chatService.messages[index - 1].role.isUser) {
                                    MediAvatarBadge()
                                        .padding(.leading, 4)
                                }
                                ChatBubbleView(message: message) { action in
                                    handleAction(action)
                                }
                            }
                            .id(message.id)
                        }
                    }

                    // Typing indicator
                    if chatService.isStreaming {
                        VStack(alignment: .leading, spacing: 4) {
                            MediAvatarBadge()
                                .padding(.leading, 4)

                            if !chatService.currentStreamedText.isEmpty {
                                // Show streaming text
                                HStack {
                                    Text(LocalizedStringKey(chatService.currentStreamedText))
                                        .font(.body)
                                        .foregroundColor(MCColors.textPrimary)
                                        .lineSpacing(3)
                                        .padding(14)
                                        .background(MCColors.surface)
                                        .clipShape(RoundedRectangle(cornerRadius: 16))

                                    Spacer(minLength: 60)
                                }
                            } else {
                                MediTypingIndicator()
                            }
                        }
                        .id("typing")
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
            }
            .onChange(of: chatService.messages.count) {
                withAnimation(.easeOut(duration: 0.3)) {
                    proxy.scrollTo(chatService.messages.last?.id, anchor: .bottom)
                }
            }
            .onChange(of: chatService.currentStreamedText) {
                proxy.scrollTo("typing", anchor: .bottom)
            }
        }
    }

    // MARK: - Quick Reply Chips

    /// Dynamic chips sourced from the last assistant message's suggestedReplies, with fallback defaults
    private var dynamicChips: [String] {
        if let lastAssistant = chatService.messages.last(where: { $0.role == .assistant }),
           !lastAssistant.suggestedReplies.isEmpty {
            return lastAssistant.suggestedReplies
        }
        return ["My medicines", "My progress", "Side effects?"]
    }

    private var quickReplyChips: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(Array(dynamicChips.enumerated()), id: \.offset) { index, chip in
                    quickChip(chip, query: chip)
                        .transition(.asymmetric(
                            insertion: .opacity.combined(with: .move(edge: .bottom)),
                            removal: .opacity
                        ))
                        .animation(
                            .easeOut(duration: 0.35).delay(Double(index) * 0.08),
                            value: dynamicChips
                        )
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 6)
        }
        .background(Color(hex: "F7F9FC").opacity(0.9))
    }

    private func quickChip(_ label: String, query: String) -> some View {
        Button {
            messageText = query
            sendMessage()
        } label: {
            Text(label)
                .font(.caption.weight(.medium))
                .foregroundColor(Color(hex: "0A7E8C"))
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(Color(hex: "0A7E8C").opacity(0.08))
                .clipShape(Capsule())
                .overlay(Capsule().stroke(Color(hex: "0A7E8C").opacity(0.15), lineWidth: 1))
        }
    }

    // MARK: - Input Bar

    private var inputBar: some View {
        HStack(spacing: 10) {
            if speechService.isRecording {
                // Recording overlay replacing the text field
                recordingOverlay
            } else {
                // Text field
                TextField("Ask about your health...", text: $messageText, axis: .vertical)
                    .font(.body)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(Color(hex: "F0F2F5"))
                    .clipShape(RoundedRectangle(cornerRadius: 22))
                    .lineLimit(1...4)
                    .focused($isInputFocused)
            }

            // Send / Mic / Stop button
            if speechService.isRecording {
                Button {
                    finishRecording()
                } label: {
                    Image(systemName: "stop.circle.fill")
                        .font(.system(size: 30))
                        .foregroundColor(Color(hex: "EF4444"))
                }
            } else if messageText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                Button {
                    startVoiceInput()
                } label: {
                    Image(systemName: "mic.fill")
                        .font(.system(size: 30))
                        .foregroundColor(Color(hex: "9CA3AF"))
                }
            } else {
                Button {
                    sendMessage()
                } label: {
                    Image(systemName: "arrow.up.circle.fill")
                        .font(.system(size: 30))
                        .foregroundColor(Color(hex: "0A7E8C"))
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(.ultraThinMaterial)
        .alert("Voice Input Error", isPresented: .init(
            get: { speechService.error != nil },
            set: { if !$0 { speechService.error = nil } }
        )) {
            Button("OK", role: .cancel) { speechService.error = nil }
        } message: {
            Text(speechService.error ?? "")
        }
    }

    // MARK: - Recording Overlay

    private var recordingOverlay: some View {
        HStack(spacing: 8) {
            // Waveform bars
            waveformBars

            VStack(alignment: .leading, spacing: 2) {
                Text("Listening...")
                    .font(.caption.weight(.semibold))
                    .foregroundColor(Color(hex: "EF4444"))

                if !speechService.transcribedText.isEmpty {
                    Text(speechService.transcribedText)
                        .font(.subheadline)
                        .foregroundColor(Color(hex: "1F2937"))
                        .lineLimit(2)
                }
            }

            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(Color(hex: "FEF2F2"))
        .clipShape(RoundedRectangle(cornerRadius: 22))
    }

    private var waveformBars: some View {
        HStack(spacing: 3) {
            ForEach(0..<5, id: \.self) { index in
                RoundedRectangle(cornerRadius: 2)
                    .fill(Color(hex: "EF4444"))
                    .frame(width: 3, height: waveformBarHeight(for: index))
                    .animation(.easeInOut(duration: 0.15), value: speechService.audioLevel)
            }
        }
        .frame(height: 24)
    }

    private func waveformBarHeight(for index: Int) -> CGFloat {
        let base: CGFloat = 6.0
        let maxExtra: CGFloat = 18.0
        // Each bar uses a different multiplier for visual variety
        let multipliers: [CGFloat] = [0.5, 0.8, 1.0, 0.7, 0.4]
        let level = CGFloat(speechService.audioLevel) * multipliers[index]
        return base + maxExtra * level
    }

    // MARK: - Voice Input

    private func startVoiceInput() {
        speechService.requestAuthorization()
        do {
            try speechService.startRecording()
        } catch {
            speechService.error = "Could not start recording: \(error.localizedDescription)"
        }
    }

    private func finishRecording() {
        speechService.stopRecording()
        let text = speechService.transcribedText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return }

        let voiceActionService = VoiceActionService()
        let action = voiceActionService.parseUtterance(text)

        switch action {
        case .logDose, .logSymptom, .drugQuery, .queryHealth:
            // Structured action detected — auto-send as chat message with action context
            messageText = text
            sendMessage()
        case .unknown:
            // No structured action — put text in field for user to review/edit
            messageText = text
            isInputFocused = true
        }
    }

    // MARK: - Actions

    private func sendMessage() {
        let text = messageText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return }
        messageText = ""
        isInputFocused = false

        let activeEpisodes = profile.episodes.filter { $0.status == .active }

        Task {
            await chatService.sendMessage(
                text,
                profile: profile,
                activeEpisodes: activeEpisodes,
                modelContext: modelContext
            )
        }
    }

    private func addWelcomeMessage() {
        // Prevent duplicate welcome messages — skip if the last message is already an assistant welcome
        if let lastMessage = chatService.messages.last,
           lastMessage.role == .assistant,
           chatService.messages.count == 1 {
            return
        }

        let hour = Calendar.current.component(.hour, from: Date())
        let timeGreeting: String
        switch hour {
        case 5..<12: timeGreeting = "Good morning"
        case 12..<17: timeGreeting = "Good afternoon"
        case 17..<21: timeGreeting = "Good evening"
        default: timeGreeting = "Hey there"
        }

        let welcome = ChatMessage(
            role: .assistant,
            content: """
            \(timeGreeting), \(profile.name)! I'm **Medi**, your health companion.

            I'm here to help you with:
            • Understanding your medicines
            • Tracking your recovery progress
            • Answering health questions
            • Managing your care plan

            Aapko kisi bhi cheez mein help chahiye toh bas pooch lijiye!
            """,
            profileId: profile.id
        )
        chatService.messages.append(welcome)
        modelContext.insert(welcome)
        try? modelContext.save()
    }

    // MARK: - Medi Greeting Banner

    private var mediGreetingBanner: some View {
        HStack(spacing: 10) {
            Image(systemName: "stethoscope.circle.fill")
                .font(.system(size: 28))
                .foregroundStyle(.white)
                .background(
                    Circle()
                        .fill(MCColors.primaryTeal)
                        .frame(width: 36, height: 36)
                )

            Text("Hi \(profile.name)! I'm Medi, your health companion 💚")
                .font(.subheadline.weight(.semibold))
                .foregroundColor(MCColors.textPrimary)

            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(MCColors.primaryTeal.opacity(0.08))
    }

    // MARK: - Quick Action Chips (shown at start)

    private var quickActionChips: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                quickActionChip("How am I doing?", icon: "chart.line.uptrend.xyaxis")
                quickActionChip("Side effects?", icon: "exclamationmark.triangle")
                quickActionChip("My medicines", icon: "pills")
                quickActionChip("Feel unwell", icon: "heart.text.square")
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
        }
        .background(MCColors.backgroundLight.opacity(0.9))
    }

    private func quickActionChip(_ label: String, icon: String) -> some View {
        Button {
            messageText = label
            sendMessage()
        } label: {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.caption2.weight(.semibold))
                Text(label)
                    .font(.caption.weight(.medium))
            }
            .foregroundColor(MCColors.primaryTeal)
            .padding(.horizontal, 14)
            .padding(.vertical, 9)
            .background(MCColors.primaryTeal.opacity(0.08))
            .clipShape(Capsule())
            .overlay(Capsule().stroke(MCColors.primaryTeal.opacity(0.15), lineWidth: 1))
        }
    }

    private func handleAction(_ action: ChatAction) {
        switch action.type {
        case .logSymptom:
            showSymptomLog = true
        case .callDoctor:
            if let url = URL(string: "tel://1800112233") {
                UIApplication.shared.open(url)
            }
        case .viewTimeline:
            showTimeline = true
        case .viewEpisode:
            showTimeline = true
        case .callEmergency:
            if let url = URL(string: "tel://112") {
                UIApplication.shared.open(url)
            }
        case .openURL:
            if let payload = action.payload, let url = URL(string: payload) {
                UIApplication.shared.open(url)
            }
        case .missedDoseChat:
            messageText = "I missed my dose, what should I do?"
            sendMessage()
        }
    }
}

// MARK: - Medi Avatar Badge

/// Replaces the old AIBadgeView with a Medi-branded avatar + label
struct MediAvatarBadge: View {
    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: "stethoscope.circle.fill")
                .font(.system(size: 18))
                .foregroundStyle(.white, MCColors.primaryTeal)
            Text("Medi")
                .font(.system(size: 11, weight: .bold))
                .foregroundColor(MCColors.primaryTeal)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 3)
        .background(MCColors.primaryTeal.opacity(0.1))
        .clipShape(Capsule())
    }
}

// MARK: - Medi Typing Indicator (3 bouncing dots with Medi branding)

struct MediTypingIndicator: View {
    @State private var dotOffset: [CGFloat] = [0, 0, 0]

    var body: some View {
        HStack {
            HStack(spacing: 5) {
                ForEach(0..<3, id: \.self) { index in
                    Circle()
                        .fill(MCColors.primaryTeal.opacity(0.6))
                        .frame(width: 8, height: 8)
                        .offset(y: dotOffset[index])
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(MCColors.surface)
            .clipShape(RoundedRectangle(cornerRadius: 16))

            Spacer()
        }
        .onAppear {
            animateDots()
        }
    }

    private func animateDots() {
        for i in 0..<3 {
            withAnimation(
                .easeInOut(duration: 0.5)
                .repeatForever(autoreverses: true)
                .delay(Double(i) * 0.15)
            ) {
                dotOffset[i] = -6
            }
        }
    }
}
