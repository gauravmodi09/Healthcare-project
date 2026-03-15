import SwiftUI
import SwiftData

/// Main AI Chat screen — the core Phase 2.5 feature
struct AIChatView: View {
    @Environment(AIChatService.self) private var chatService
    @Environment(\.modelContext) private var modelContext
    @State private var messageText = ""
    @FocusState private var isInputFocused: Bool

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

                // Messages
                messagesList

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
            // Back button placeholder (for NavigationStack)
            Button(action: {}) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(Color(hex: "1F2937"))
            }

            Spacer()

            VStack(spacing: 2) {
                HStack(spacing: 6) {
                    Image(systemName: "sparkles")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(Color(hex: "0A7E8C"))
                    Text("MedCare AI")
                        .font(.system(size: 17, weight: .bold))
                        .foregroundColor(Color(hex: "1F2937"))
                }
                Text("Health Companion")
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
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
                .font(.system(size: 11, weight: .medium))
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
                                    AIBadgeView()
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
                            AIBadgeView()
                                .padding(.leading, 4)

                            if !chatService.currentStreamedText.isEmpty {
                                // Show streaming text
                                HStack {
                                    Text(LocalizedStringKey(chatService.currentStreamedText))
                                        .font(.system(size: 15))
                                        .foregroundColor(Color(hex: "1F2937"))
                                        .lineSpacing(3)
                                        .padding(14)
                                        .background(Color(hex: "F0F2F5"))
                                        .clipShape(RoundedRectangle(cornerRadius: 16))

                                    Spacer(minLength: 60)
                                }
                            } else {
                                TypingIndicatorView()
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

    // MARK: - Input Bar

    private var inputBar: some View {
        HStack(spacing: 10) {
            // Text field
            TextField("Ask about your health...", text: $messageText, axis: .vertical)
                .font(.system(size: 15))
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(Color(hex: "F0F2F5"))
                .clipShape(RoundedRectangle(cornerRadius: 22))
                .lineLimit(1...4)
                .focused($isInputFocused)

            // Send button
            Button {
                sendMessage()
            } label: {
                Image(systemName: messageText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? "mic.fill" : "arrow.up.circle.fill")
                    .font(.system(size: 30))
                    .foregroundColor(
                        messageText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                            ? Color(hex: "9CA3AF")
                            : Color(hex: "0A7E8C")
                    )
            }
            .disabled(messageText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && !chatService.isStreaming)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(.ultraThinMaterial)
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
        let welcome = ChatMessage(
            role: .assistant,
            content: """
            Hi \(profile.name)! 👋 I'm your MedCare AI health companion.

            I can help you with:
            • 💊 Understanding your medicines
            • 📊 Tracking your recovery progress
            • ❓ Answering health questions about your treatment
            • 🔔 Managing your care plan

            How can I help you today?
            """,
            profileId: profile.id
        )
        chatService.messages.append(welcome)
        modelContext.insert(welcome)
        try? modelContext.save()
    }

    private func handleAction(_ action: ChatAction) {
        switch action.type {
        case .logSymptom:
            break // Navigate to symptom log
        case .callDoctor:
            if let url = URL(string: "tel://") {
                UIApplication.shared.open(url)
            }
        case .viewTimeline:
            break // Navigate to timeline
        case .viewEpisode:
            break // Navigate to episode
        case .callEmergency:
            if let url = URL(string: "tel://112") {
                UIApplication.shared.open(url)
            }
        case .openURL:
            if let payload = action.payload, let url = URL(string: payload) {
                UIApplication.shared.open(url)
            }
        }
    }
}

// MARK: - Color Hex Extension

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default: (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}
