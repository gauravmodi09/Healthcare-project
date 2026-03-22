import SwiftUI
import SwiftData

struct DoctorMessageView: View {
    let doctor: Doctor
    @Environment(DataService.self) private var dataService
    @Environment(\.dismiss) private var dismiss

    @State private var messageText = ""
    @State private var isUrgent = false
    @State private var messages: [Message] = []
    @FocusState private var isInputFocused: Bool
    @AppStorage("mc_demo_auto_reply") private var demoAutoReply = false

    private var threadId: UUID { doctor.id }

    var body: some View {
        VStack(spacing: 0) {
            // Doctor info header
            doctorHeader

            Divider()
                .foregroundStyle(MCColors.divider)

            // Offline auto-reply banner
            if !doctor.isOnline {
                offlineBanner
            }

            // Messages list
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(spacing: MCSpacing.sm) {
                        ForEach(messages) { message in
                            messageBubble(message)
                                .id(message.id)
                        }
                    }
                    .padding(.horizontal, MCSpacing.screenPadding)
                    .padding(.vertical, MCSpacing.sm)
                }
                .onChange(of: messages.count) { _, _ in
                    if let lastMessage = messages.last {
                        withAnimation {
                            proxy.scrollTo(lastMessage.id, anchor: .bottom)
                        }
                    }
                }
            }

            Divider()
                .foregroundStyle(MCColors.divider)

            // Input bar
            inputBar
        }
        .background(MCColors.backgroundLight)
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            loadMessages()
        }
    }

    // MARK: - Doctor Header

    private var doctorHeader: some View {
        HStack(spacing: MCSpacing.sm) {
            // Avatar
            Text(doctor.avatarEmoji)
                .font(.system(size: 32))
                .frame(width: MCSpacing.avatarSize, height: MCSpacing.avatarSize)
                .background(MCColors.primaryTeal.opacity(0.1))
                .clipShape(Circle())

            VStack(alignment: .leading, spacing: MCSpacing.xxs) {
                Text(doctor.name)
                    .font(MCTypography.headline)
                    .foregroundStyle(MCColors.textPrimary)

                Text(doctor.specialty)
                    .font(MCTypography.caption)
                    .foregroundStyle(MCColors.textSecondary)
            }

            Spacer()

            // Online status
            HStack(spacing: MCSpacing.xxs) {
                Circle()
                    .fill(doctor.isOnline ? MCColors.success : MCColors.textTertiary)
                    .frame(width: 8, height: 8)

                Text(doctor.isOnline ? "Online" : "Offline")
                    .font(MCTypography.caption)
                    .foregroundStyle(doctor.isOnline ? MCColors.success : MCColors.textTertiary)
            }
            .padding(.horizontal, MCSpacing.xs)
            .padding(.vertical, MCSpacing.xxs)
            .background(
                (doctor.isOnline ? MCColors.success : MCColors.textTertiary)
                    .opacity(0.1)
            )
            .clipShape(Capsule())
        }
        .padding(.horizontal, MCSpacing.screenPadding)
        .padding(.vertical, MCSpacing.sm)
        .background(MCColors.cardBackground)
    }

    // MARK: - Offline Banner

    private var offlineBanner: some View {
        HStack(spacing: MCSpacing.xs) {
            Image(systemName: "clock.fill")
                .font(.system(size: 14))
                .foregroundStyle(MCColors.warning)

            Text("\(doctor.name.components(separatedBy: " ").prefix(2).joined(separator: " ")) typically responds within 4 hours")
                .font(MCTypography.caption)
                .foregroundStyle(MCColors.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, MCSpacing.xs)
        .padding(.horizontal, MCSpacing.screenPadding)
        .background(MCColors.warning.opacity(0.08))
    }

    // MARK: - Message Bubble

    private func messageBubble(_ message: Message) -> some View {
        let isPatient = message.senderType == .patient

        return HStack {
            if isPatient { Spacer(minLength: 60) }

            VStack(alignment: isPatient ? .trailing : .leading, spacing: MCSpacing.xxs) {
                // Urgent badge
                if message.isUrgent {
                    HStack(spacing: 4) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .font(.system(size: 10))
                        Text("URGENT")
                            .font(.system(size: 10, weight: .bold))
                    }
                    .foregroundStyle(MCColors.error)
                }

                // Attachment indicator
                if message.messageType != .text {
                    HStack(spacing: 4) {
                        Image(systemName: message.messageType.icon)
                            .font(.system(size: 12))
                        Text(message.messageTypeRawValue.capitalized)
                            .font(MCTypography.caption)
                    }
                    .foregroundStyle(isPatient ? .white.opacity(0.8) : MCColors.textSecondary)
                    .padding(.bottom, 2)
                }

                // Content
                Text(message.content)
                    .font(MCTypography.body)
                    .foregroundStyle(isPatient ? .white : MCColors.textPrimary)

                // Timestamp + read receipt
                HStack(spacing: 4) {
                    Text(message.createdAt, style: .time)
                        .font(.system(size: 11))

                    if isPatient && message.isRead {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 10))
                    }
                }
                .foregroundStyle(isPatient ? .white.opacity(0.7) : MCColors.textTertiary)
            }
            .padding(.horizontal, MCSpacing.sm)
            .padding(.vertical, MCSpacing.xs)
            .background(
                isPatient
                    ? MCColors.primaryTeal
                    : MCColors.cardBackground
            )
            .clipShape(RoundedRectangle(cornerRadius: MCSpacing.cornerRadius))
            .shadow(color: .black.opacity(0.04), radius: 4, y: 2)

            if !isPatient { Spacer(minLength: 60) }
        }
    }

    // MARK: - Input Bar

    private var inputBar: some View {
        VStack(spacing: MCSpacing.xs) {
            // Urgent toggle
            if !messageText.isEmpty {
                HStack {
                    Toggle(isOn: $isUrgent) {
                        HStack(spacing: 4) {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .font(.system(size: 12))
                                .foregroundStyle(isUrgent ? MCColors.error : MCColors.textTertiary)
                            Text("Mark as Urgent")
                                .font(MCTypography.caption)
                                .foregroundStyle(isUrgent ? MCColors.error : MCColors.textSecondary)
                        }
                    }
                    .toggleStyle(.switch)
                    .tint(MCColors.error)

                    Spacer()
                }
                .padding(.horizontal, MCSpacing.screenPadding)
            }

            // Text field + buttons
            HStack(spacing: MCSpacing.xs) {
                // Attachment button
                Menu {
                    Button {
                        // Photo attachment placeholder
                    } label: {
                        Label("Photo", systemImage: "photo")
                    }
                    Button {
                        // Document attachment placeholder
                    } label: {
                        Label("Document", systemImage: "doc.fill")
                    }
                    Button {
                        // Voice note placeholder
                    } label: {
                        Label("Voice Note", systemImage: "mic.fill")
                    }
                } label: {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 28))
                        .foregroundStyle(MCColors.primaryTeal)
                }

                // Text input
                TextField("Type a message...", text: $messageText, axis: .vertical)
                    .font(MCTypography.body)
                    .lineLimit(1...4)
                    .padding(.horizontal, MCSpacing.sm)
                    .padding(.vertical, MCSpacing.xs)
                    .background(MCColors.surface)
                    .clipShape(RoundedRectangle(cornerRadius: 20))
                    .focused($isInputFocused)

                // Send button
                Button {
                    sendMessage()
                } label: {
                    Image(systemName: "arrow.up.circle.fill")
                        .font(.system(size: 32))
                        .foregroundStyle(messageText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                            ? MCColors.textTertiary
                            : MCColors.primaryTeal)
                }
                .disabled(messageText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
            .padding(.horizontal, MCSpacing.screenPadding)
            .padding(.vertical, MCSpacing.xs)
        }
        .background(MCColors.cardBackground)
    }

    // MARK: - Actions

    private func sendMessage() {
        let trimmed = messageText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        let message = Message(
            threadId: threadId,
            senderType: .patient,
            senderId: UUID(), // would be current user ID
            receiverId: doctor.id,
            content: trimmed,
            isUrgent: isUrgent
        )

        dataService.modelContext.insert(message)
        try? dataService.modelContext.save()

        messages.append(message)
        messageText = ""
        isUrgent = false

        UIImpactFeedbackGenerator(style: .light).impactOccurred()

        // Simulate doctor auto-reply only in demo mode
        if demoAutoReply && doctor.isOnline {
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                let reply = Message(
                    threadId: threadId,
                    senderType: .doctor,
                    senderId: doctor.id,
                    receiverId: UUID(),
                    content: autoReplyText(for: trimmed)
                )
                dataService.modelContext.insert(reply)
                try? dataService.modelContext.save()
                messages.append(reply)
            }
        }
    }

    private func loadMessages() {
        let tid = threadId
        let descriptor = FetchDescriptor<Message>(
            predicate: #Predicate<Message> { $0.threadId == tid },
            sortBy: [SortDescriptor(\.createdAt, order: .forward)]
        )
        messages = (try? dataService.modelContext.fetch(descriptor)) ?? []
    }

    private func autoReplyText(for input: String) -> String {
        let lowered = input.lowercased()
        if lowered.contains("report") || lowered.contains("test") {
            return "Thanks for sharing. I'll review and get back to you shortly."
        } else if lowered.contains("pain") || lowered.contains("hurt") || lowered.contains("worse") {
            return "I understand your concern. Can you describe the severity on a scale of 1-10?"
        } else if lowered.contains("thank") {
            return "You're welcome! Don't hesitate to reach out if you have more questions."
        } else {
            return "Got it. I'll review this and respond with my recommendation."
        }
    }
}
