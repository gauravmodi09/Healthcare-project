import SwiftUI
import SwiftData

/// Displays a list of past chat sessions, sorted by most recent
struct ChatHistoryView: View {
    @Environment(\.modelContext) var modelContext
    @Environment(AIChatService.self) private var chatService
    @Environment(\.dismiss) private var dismiss

    let profile: UserProfile

    @Query private var sessions: [ChatSession]

    init(profile: UserProfile) {
        self.profile = profile
        let profileId = profile.id
        _sessions = Query(
            filter: #Predicate<ChatSession> { session in
                session.profileId == profileId
            },
            sort: [SortDescriptor(\.updatedAt, order: .reverse)]
        )
    }

    @State private var navigateToChat = false

    var body: some View {
        ZStack {
            MCColors.backgroundLight
                .ignoresSafeArea()

            VStack(spacing: 0) {
                // Header
                header

                if sessions.isEmpty {
                    emptyState
                } else {
                    sessionList
                }
            }
        }
        .navigationBarHidden(true)
        .navigationDestination(isPresented: $navigateToChat) {
            AIChatView(profile: profile)
        }
    }

    // MARK: - Header

    private var header: some View {
        HStack {
            Button {
                dismiss()
            } label: {
                Image(systemName: "chevron.left")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(MCColors.textPrimary)
            }

            Spacer()

            Text("Chat History")
                .font(.system(size: 17, weight: .bold))
                .foregroundColor(MCColors.textPrimary)

            Spacer()

            Button {
                chatService.startNewSession(profileId: profile.id, modelContext: modelContext)
                navigateToChat = true
            } label: {
                Image(systemName: "square.and.pencil")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(MCColors.primaryTeal)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(.ultraThinMaterial)
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: 16) {
            Spacer()

            Image(systemName: "bubble.left.and.bubble.right")
                .font(.system(size: 48))
                .foregroundColor(MCColors.textTertiary)

            Text("No chat sessions yet")
                .font(.system(size: 17, weight: .semibold))
                .foregroundColor(MCColors.textPrimary)

            Text("Start a new conversation with MedCare AI")
                .font(.system(size: 14))
                .foregroundColor(MCColors.textSecondary)
                .multilineTextAlignment(.center)

            Button {
                chatService.startNewSession(profileId: profile.id, modelContext: modelContext)
                navigateToChat = true
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "plus.bubble.fill")
                    Text("New Chat")
                }
                .font(.system(size: 15, weight: .semibold))
                .foregroundColor(.white)
                .padding(.horizontal, 24)
                .padding(.vertical, 12)
                .background(MCColors.primaryTeal)
                .clipShape(Capsule())
            }
            .padding(.top, 8)

            Spacer()
        }
        .padding(.horizontal, 32)
    }

    // MARK: - Session List

    private var sessionList: some View {
        List {
            ForEach(sessions) { session in
                sessionRow(session)
                    .listRowBackground(MCColors.cardBackground)
                    .listRowSeparatorTint(MCColors.divider)
                    .contentShape(Rectangle())
                    .onTapGesture {
                        chatService.loadSession(session, modelContext: modelContext)
                        navigateToChat = true
                    }
            }
            .onDelete(perform: deleteSessions)
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
    }

    // MARK: - Session Row

    private func sessionRow(_ session: ChatSession) -> some View {
        HStack(spacing: 12) {
            // Icon
            ZStack {
                Circle()
                    .fill(MCColors.primaryTeal.opacity(0.12))
                    .frame(width: 40, height: 40)

                Image(systemName: "bubble.left.fill")
                    .font(.system(size: 16))
                    .foregroundColor(MCColors.primaryTeal)
            }

            // Title + metadata
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 8) {
                    Text(session.title)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(MCColors.textPrimary)
                        .lineLimit(1)

                    if isActiveSession(session) {
                        Text("Active")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(.white)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(MCColors.primaryTeal)
                            .clipShape(Capsule())
                    }
                }

                HStack(spacing: 6) {
                    Text("\(session.messageCount) messages")
                        .font(.system(size: 12))
                        .foregroundColor(MCColors.textSecondary)

                    Text("·")
                        .font(.system(size: 12))
                        .foregroundColor(MCColors.textTertiary)

                    Text(relativeDate(session.updatedAt))
                        .font(.system(size: 12))
                        .foregroundColor(MCColors.textSecondary)
                }
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(MCColors.textTertiary)
        }
        .padding(.vertical, 4)
    }

    // MARK: - Helpers

    private func isActiveSession(_ session: ChatSession) -> Bool {
        chatService.currentSession?.id == session.id
    }

    private func relativeDate(_ date: Date) -> String {
        let calendar = Calendar.current
        let now = Date()

        if calendar.isDateInToday(date) {
            let minutes = Int(now.timeIntervalSince(date) / 60)
            if minutes < 1 { return "Just now" }
            if minutes < 60 { return "\(minutes)m ago" }
            let hours = minutes / 60
            return "\(hours)h ago"
        }

        if calendar.isDateInYesterday(date) {
            return "Yesterday"
        }

        let days = calendar.dateComponents([.day], from: date, to: now).day ?? 0
        if days < 7 {
            let formatter = DateFormatter()
            formatter.dateFormat = "EEEE"
            return formatter.string(from: date)
        }

        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        return formatter.string(from: date)
    }

    private func deleteSessions(at offsets: IndexSet) {
        for index in offsets {
            let session = sessions[index]

            // Delete all messages belonging to this session
            let sessionId = session.id
            let messageDescriptor = FetchDescriptor<ChatMessage>(
                predicate: #Predicate<ChatMessage> { message in
                    message.sessionId == sessionId
                }
            )
            if let sessionMessages = try? modelContext.fetch(messageDescriptor) {
                for message in sessionMessages {
                    modelContext.delete(message)
                }
            }

            // Clear current session if it's being deleted
            if chatService.currentSession?.id == session.id {
                chatService.currentSession = nil
                chatService.messages = []
            }

            modelContext.delete(session)
        }
        try? modelContext.save()
    }
}
