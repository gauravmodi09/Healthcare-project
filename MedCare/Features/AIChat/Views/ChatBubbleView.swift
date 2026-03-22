import SwiftUI

/// Individual chat message bubble
struct ChatBubbleView: View {
    let message: ChatMessage
    var onActionTap: ((ChatAction) -> Void)?

    @State private var showTimestamp = false

    var body: some View {
        VStack(alignment: message.role.isUser ? .trailing : .leading, spacing: 4) {
            HStack {
                if message.role.isUser { Spacer(minLength: 60) }

                VStack(alignment: .leading, spacing: 8) {
                    // Message content
                    Text(LocalizedStringKey(message.content))
                        .font(.system(size: 15, weight: .regular))
                        .foregroundColor(message.role.isUser ? .white : MCColors.textPrimary)
                        .lineSpacing(3)

                    // Action buttons (if any)
                    if !message.actionButtons.isEmpty {
                        HStack(spacing: 8) {
                            ForEach(message.actionButtons) { action in
                                Button {
                                    onActionTap?(action)
                                } label: {
                                    Text(action.title)
                                        .font(.system(size: 12, weight: .semibold))
                                        .foregroundColor(MCColors.primaryTeal)
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 6)
                                        .background(MCColors.primaryTeal.opacity(0.1))
                                        .clipShape(Capsule())
                                }
                            }
                        }
                    }
                }
                .padding(14)
                .background {
                    if message.isEmergency {
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .fill(Color.red.opacity(0.1))
                    } else if message.role.isUser {
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .fill(LinearGradient(
                                colors: [MCColors.primaryTeal, MCColors.primaryTealDark],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ))
                    } else {
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .fill(.ultraThinMaterial)
                    }
                }
                .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .stroke(message.isEmergency ? Color.red.opacity(0.6) : Color.clear, lineWidth: 2)
                )

                if !message.role.isUser { Spacer(minLength: 60) }
            }

            // AI disclaimer footer for assistant messages
            if !message.role.isUser {
                HStack(spacing: 3) {
                    Image(systemName: "info.circle")
                        .font(.system(size: 9))
                    Text("AI-generated \u{00B7} Not medical advice")
                        .font(.system(size: 10, weight: .regular))
                }
                .foregroundStyle(MCColors.textTertiary)
                .padding(.leading, 4)
            }

            // Timestamp (shown on tap)
            if showTimestamp {
                Text(message.timestamp.formatted(date: .omitted, time: .shortened))
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 4)
                    .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .onTapGesture {
            withAnimation(.easeInOut(duration: 0.2)) {
                showTimestamp.toggle()
            }
        }
    }

    // bubbleBackground now handled inline in the body via .background { } builder
}

// MARK: - Typing Indicator

struct TypingIndicatorView: View {
    @State private var dotScale: [CGFloat] = [0.5, 0.5, 0.5]

    var body: some View {
        HStack {
            HStack(spacing: 5) {
                ForEach(0..<3, id: \.self) { index in
                    Circle()
                        .fill(MCColors.textTertiary)
                        .frame(width: 8, height: 8)
                        .scaleEffect(dotScale[index])
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
                .easeInOut(duration: 0.6)
                .repeatForever(autoreverses: true)
                .delay(Double(i) * 0.2)
            ) {
                dotScale[i] = 1.0
            }
        }
    }
}

// MARK: - AI Label Badge

struct AIBadgeView: View {
    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: "sparkles")
                .font(.system(size: 10, weight: .bold))
            Text("MedCare AI")
                .font(.system(size: 11, weight: .bold))
        }
        .foregroundColor(MCColors.primaryTeal)
        .padding(.horizontal, 8)
        .padding(.vertical, 3)
        .background(MCColors.primaryTeal.opacity(0.1))
        .clipShape(Capsule())
    }
}
