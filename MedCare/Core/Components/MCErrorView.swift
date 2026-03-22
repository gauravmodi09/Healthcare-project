import SwiftUI

/// Reusable error state view with optional retry action
struct MCErrorView: View {
    let title: String
    let message: String
    let retryAction: (() -> Void)?

    init(
        _ title: String = "Something went wrong",
        message: String = "Please try again",
        retryAction: (() -> Void)? = nil
    ) {
        self.title = title
        self.message = message
        self.retryAction = retryAction
    }

    var body: some View {
        VStack(spacing: MCSpacing.md) {
            // Warning icon with amber background circle
            ZStack {
                Circle()
                    .fill(MCColors.warning.opacity(0.12))
                    .frame(width: 72, height: 72)

                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.system(size: 32, weight: .medium))
                    .foregroundStyle(MCColors.warning)
            }

            VStack(spacing: MCSpacing.xs) {
                Text(title)
                    .font(MCTypography.headline)
                    .foregroundStyle(MCColors.textPrimary)
                    .multilineTextAlignment(.center)

                Text(message)
                    .font(MCTypography.footnote)
                    .foregroundStyle(MCColors.textSecondary)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
            }

            if let retryAction {
                Button {
                    retryAction()
                } label: {
                    HStack(spacing: MCSpacing.xs) {
                        Image(systemName: "arrow.clockwise")
                            .font(.system(size: 14, weight: .semibold))
                        Text("Try Again")
                            .font(MCTypography.bodyMedium)
                    }
                    .foregroundStyle(.white)
                    .frame(width: 180)
                    .frame(height: 44)
                    .background(MCColors.primaryGradient)
                    .clipShape(RoundedRectangle(cornerRadius: MCSpacing.cornerRadius))
                }
            }
        }
        .padding(MCSpacing.xl)
        .frame(maxWidth: .infinity)
    }
}

/// Inline error banner for use within lists/chats (compact variant)
struct MCInlineErrorView: View {
    let message: String
    let retryAction: (() -> Void)?

    var body: some View {
        HStack(spacing: MCSpacing.sm) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 16))
                .foregroundStyle(MCColors.warning)

            Text(message)
                .font(MCTypography.footnote)
                .foregroundStyle(MCColors.textSecondary)
                .lineLimit(3)

            Spacer()

            if let retryAction {
                Button {
                    retryAction()
                } label: {
                    Text("Retry")
                        .font(MCTypography.captionBold)
                        .foregroundStyle(MCColors.primaryTeal)
                        .padding(.horizontal, MCSpacing.sm)
                        .padding(.vertical, MCSpacing.xs)
                        .background(MCColors.primaryTeal.opacity(0.1))
                        .clipShape(Capsule())
                }
            }
        }
        .padding(MCSpacing.sm)
        .background(MCColors.warning.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: MCSpacing.cornerRadius))
    }
}

#Preview("MCErrorView") {
    VStack(spacing: 24) {
        MCErrorView(
            "Connection Failed",
            message: "Could not reach the server. Check your internet and try again.",
            retryAction: {}
        )

        Divider()

        MCInlineErrorView(
            message: "Failed to generate response. Please try again.",
            retryAction: {}
        )
        .padding(.horizontal)
    }
}
