import SwiftUI

struct WhatsNewView: View {
    @Environment(\.dismiss) private var dismiss

    private let features: [(icon: String, title: String, description: String)] = [
        ("cross.case.fill", "Comprehensive Health Profile", "10-section medical profile covering allergies, surgeries, family history, and more — like having your full health record in your pocket."),
        ("chart.bar.xaxis.ascending", "Daily Tracking", "Track mood, water intake, sleep, activity, and symptoms all in one place with beautiful visual summaries."),
        ("stethoscope", "Doctor Dashboard", "Doctors can manage patients with real data, write e-prescriptions, and conduct video consultations."),
        ("pills.fill", "501 Indian Medicines", "Complete drug database with Jan Aushadhi generic prices, side effects, interactions, and dosage guidance."),
        ("bell.badge.fill", "Smart Reminders", "Persistent alarms that escalate until acknowledged, custom snooze durations, and caregiver missed-dose alerts."),
    ]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: MCSpacing.lg) {
                    // Header
                    VStack(spacing: MCSpacing.sm) {
                        Image(systemName: "sparkles")
                            .font(.system(size: 44))
                            .foregroundStyle(MCColors.primaryTeal)
                            .padding(.top, MCSpacing.lg)

                        Text("What's New in MedCare")
                            .font(MCTypography.title)
                            .foregroundStyle(MCColors.textPrimary)

                        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
                        Text("Version \(version)")
                            .font(MCTypography.subheadline)
                            .foregroundStyle(MCColors.textTertiary)
                    }

                    // Feature cards
                    ForEach(Array(features.enumerated()), id: \.offset) { index, feature in
                        featureCard(
                            icon: feature.icon,
                            title: feature.title,
                            description: feature.description,
                            index: index
                        )
                    }

                    // Dismiss button
                    MCPrimaryButton("Got it", icon: "checkmark") {
                        dismiss()
                    }
                    .padding(.horizontal, MCSpacing.screenPadding)
                    .padding(.bottom, MCSpacing.lg)
                }
            }
            .background(MCColors.backgroundLight)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title3)
                            .foregroundStyle(MCColors.textTertiary)
                    }
                }
            }
        }
    }

    private func featureCard(icon: String, title: String, description: String, index: Int) -> some View {
        let colors: [Color] = [MCColors.primaryTeal, MCColors.accentCoral, MCColors.info, MCColors.success, MCColors.warning]
        let accentColor = colors[index % colors.count]

        return MCCard {
            HStack(alignment: .top, spacing: MCSpacing.md) {
                Image(systemName: icon)
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundStyle(accentColor)
                    .frame(width: 44, height: 44)
                    .background(accentColor.opacity(0.12))
                    .clipShape(RoundedRectangle(cornerRadius: 10))

                VStack(alignment: .leading, spacing: MCSpacing.xxs) {
                    Text(title)
                        .font(MCTypography.headline)
                        .foregroundStyle(MCColors.textPrimary)

                    Text(description)
                        .font(MCTypography.body)
                        .foregroundStyle(MCColors.textSecondary)
                        .lineSpacing(2)
                }
            }
        }
        .padding(.horizontal, MCSpacing.screenPadding)
    }
}
