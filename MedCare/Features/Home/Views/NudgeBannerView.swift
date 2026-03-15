import SwiftUI

/// Dismissable nudge banner card shown on the Home screen
struct NudgeBannerView: View {
    let nudge: Nudge
    var onAction: () -> Void
    var onDismiss: () -> Void

    @State private var isVisible = false

    var body: some View {
        if isVisible {
            HStack(spacing: 12) {
                // Icon
                Image(systemName: nudge.type.icon)
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundColor(Color(hex: nudge.type.accentColor))
                    .frame(width: 40, height: 40)
                    .background(Color(hex: nudge.type.accentColor).opacity(0.12))
                    .clipShape(Circle())

                // Content
                VStack(alignment: .leading, spacing: 3) {
                    Text(nudge.title)
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(Color(hex: "1F2937"))

                    Text(nudge.body)
                        .font(.system(size: 13))
                        .foregroundColor(Color(hex: "6B7280"))
                        .lineLimit(2)
                }

                Spacer()

                // Dismiss
                Button {
                    withAnimation(.spring(response: 0.3)) {
                        isVisible = false
                    }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        onDismiss()
                    }
                } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(Color(hex: "9CA3AF"))
                        .frame(width: 24, height: 24)
                }
            }
            .padding(14)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(.white)
                    .shadow(color: .black.opacity(0.06), radius: 8, x: 0, y: 2)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(Color(hex: nudge.type.accentColor).opacity(0.2), lineWidth: 1)
            )
            // Action button at bottom
            .overlay(alignment: .bottomTrailing) {
                Button {
                    onAction()
                } label: {
                    Text(nudge.type.actionLabel)
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(Color(hex: nudge.type.accentColor))
                        .padding(.horizontal, 12)
                        .padding(.vertical, 5)
                        .background(Color(hex: nudge.type.accentColor).opacity(0.1))
                        .clipShape(Capsule())
                }
                .padding(.trailing, 14)
                .padding(.bottom, -8)
            }
            .padding(.bottom, 8)
            .transition(.move(edge: .top).combined(with: .opacity))
        }
    }

    // Custom initializer to animate in on appear
    init(nudge: Nudge, onAction: @escaping () -> Void, onDismiss: @escaping () -> Void) {
        self.nudge = nudge
        self.onAction = onAction
        self.onDismiss = onDismiss
        self._isVisible = State(initialValue: true)
    }
}
