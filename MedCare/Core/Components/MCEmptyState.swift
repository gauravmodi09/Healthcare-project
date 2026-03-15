import SwiftUI

/// Reusable empty state view
struct MCEmptyState: View {
    let icon: String
    let title: String
    let message: String
    let actionTitle: String?
    let action: (() -> Void)?

    init(
        icon: String,
        title: String,
        message: String,
        actionTitle: String? = nil,
        action: (() -> Void)? = nil
    ) {
        self.icon = icon
        self.title = title
        self.message = message
        self.actionTitle = actionTitle
        self.action = action
    }

    var body: some View {
        VStack(spacing: MCSpacing.md) {
            Image(systemName: icon)
                .font(.system(size: 48))
                .foregroundStyle(MCColors.textTertiary)

            VStack(spacing: MCSpacing.xs) {
                Text(title)
                    .font(MCTypography.headline)
                    .foregroundStyle(MCColors.textPrimary)

                Text(message)
                    .font(MCTypography.footnote)
                    .foregroundStyle(MCColors.textSecondary)
                    .multilineTextAlignment(.center)
            }

            if let actionTitle, let action {
                MCPrimaryButton(actionTitle) {
                    action()
                }
                .frame(width: 200)
            }
        }
        .padding(MCSpacing.xxl)
    }
}

/// Loading overlay
struct MCLoadingOverlay: View {
    let message: String

    var body: some View {
        ZStack {
            Color.black.opacity(0.3)
                .ignoresSafeArea()

            VStack(spacing: MCSpacing.md) {
                ProgressView()
                    .scaleEffect(1.5)
                    .tint(MCColors.primaryTeal)

                Text(message)
                    .font(MCTypography.subheadline)
                    .foregroundStyle(MCColors.textPrimary)
            }
            .padding(MCSpacing.xl)
            .background(.regularMaterial)
            .clipShape(RoundedRectangle(cornerRadius: MCSpacing.cornerRadius))
        }
    }
}
