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
                        .foregroundColor(message.role.isUser ? .white : Color(hex: "1F2937"))
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
                                        .foregroundColor(Color(hex: "0A7E8C"))
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 6)
                                        .background(Color(hex: "0A7E8C").opacity(0.1))
                                        .clipShape(Capsule())
                                }
                            }
                        }
                    }
                }
                .padding(14)
                .background(bubbleBackground)
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(message.isEmergency ? Color.red.opacity(0.6) : Color.clear, lineWidth: 2)
                )

                if !message.role.isUser { Spacer(minLength: 60) }
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

    private var bubbleBackground: some ShapeStyle {
        if message.isEmergency {
            return Color.red.opacity(0.1)
        }
        return message.role.isUser
            ? Color(hex: "0A7E8C")
            : Color(hex: "F0F2F5")
    }
}

// MARK: - Typing Indicator

struct TypingIndicatorView: View {
    @State private var dotScale: [CGFloat] = [0.5, 0.5, 0.5]

    var body: some View {
        HStack {
            HStack(spacing: 5) {
                ForEach(0..<3, id: \.self) { index in
                    Circle()
                        .fill(Color(hex: "9CA3AF"))
                        .frame(width: 8, height: 8)
                        .scaleEffect(dotScale[index])
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(Color(hex: "F0F2F5"))
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
        .foregroundColor(Color(hex: "0A7E8C"))
        .padding(.horizontal, 8)
        .padding(.vertical, 3)
        .background(Color(hex: "0A7E8C").opacity(0.1))
        .clipShape(Capsule())
    }
}
