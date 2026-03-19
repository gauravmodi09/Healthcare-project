import SwiftUI

/// Reusable empty state view
struct MCEmptyState: View {
    let icon: String
    let title: String
    let message: String
    let actionTitle: String?
    let action: (() -> Void)?
    var iconColor: Color

    init(
        icon: String,
        title: String,
        message: String,
        actionTitle: String? = nil,
        iconColor: Color = MCColors.textTertiary,
        action: (() -> Void)? = nil
    ) {
        self.icon = icon
        self.title = title
        self.message = message
        self.actionTitle = actionTitle
        self.iconColor = iconColor
        self.action = action
    }

    var body: some View {
        VStack(spacing: MCSpacing.md) {
            // Icon with subtle background circle
            ZStack {
                Circle()
                    .fill(iconColor.opacity(0.1))
                    .frame(width: 88, height: 88)

                Image(systemName: icon)
                    .font(.system(size: 36, weight: .light))
                    .foregroundStyle(iconColor)
            }

            VStack(spacing: MCSpacing.xs) {
                Text(title)
                    .font(MCTypography.headline)
                    .foregroundStyle(MCColors.textPrimary)

                Text(message)
                    .font(MCTypography.footnote)
                    .foregroundStyle(MCColors.textSecondary)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
            }

            if let actionTitle, let action {
                MCPrimaryButton(actionTitle) {
                    action()
                }
                .frame(width: 220)
            }
        }
        .padding(MCSpacing.xxl)
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Preset Empty States

extension MCEmptyState {

    /// Home screen — no episodes yet
    static func home(action: (() -> Void)? = nil) -> MCEmptyState {
        MCEmptyState(
            icon: "camera.viewfinder",
            title: "Upload your first prescription",
            message: "Take a photo of your prescription and we'll create a care plan for you automatically.",
            actionTitle: "Scan Prescription",
            iconColor: MCColors.primaryTeal,
            action: action
        )
    }

    /// Episodes list — no active care plans
    static func episodes(action: (() -> Void)? = nil) -> MCEmptyState {
        MCEmptyState(
            icon: "heart.text.clipboard",
            title: "No active care plans",
            message: "Create an episode to start tracking your medications, symptoms, and follow-ups.",
            actionTitle: "Create Episode",
            iconColor: MCColors.accentCoral,
            action: action
        )
    }

    /// Medications list — no medicines added
    static func medications(action: (() -> Void)? = nil) -> MCEmptyState {
        MCEmptyState(
            icon: "pills",
            title: "Add your first medicine",
            message: "Manually add a medicine or scan a prescription to get started with dose reminders.",
            actionTitle: "Add Medicine",
            iconColor: MCColors.primaryTeal,
            action: action
        )
    }

    /// History screen — no tracking data
    static func history() -> MCEmptyState {
        MCEmptyState(
            icon: "chart.line.uptrend.xyaxis",
            title: "Start tracking to see your progress",
            message: "Once you begin logging doses, your adherence history and trends will appear here.",
            iconColor: MCColors.info
        )
    }

    /// Symptoms — no symptom logs
    static func symptoms(action: (() -> Void)? = nil) -> MCEmptyState {
        MCEmptyState(
            icon: "chart.line.text.clipboard",
            title: "No symptom logs yet",
            message: "Track how you feel daily to monitor your recovery and share insights with your doctor.",
            actionTitle: "Log Symptoms",
            iconColor: MCColors.warning,
            action: action
        )
    }

    /// Files/Documents — no documents
    static func documents(action: (() -> Void)? = nil) -> MCEmptyState {
        MCEmptyState(
            icon: "doc.text.image",
            title: "No documents yet",
            message: "Upload prescriptions, lab reports, bills, and other medical documents for safekeeping.",
            actionTitle: "Upload Document",
            iconColor: MCColors.info,
            action: action
        )
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
