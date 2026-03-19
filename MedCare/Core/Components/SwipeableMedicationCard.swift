import SwiftUI

/// Enhanced medication card with swipe actions
struct SwipeableMedicationCard: View {
    let medicineName: String
    let dosage: String
    let scheduledTime: Date
    let doseFormIcon: String
    let mealTiming: String?
    let status: String
    let statusColor: Color
    let onTake: () -> Void
    let onSkip: () -> Void
    let onSnooze: () -> Void

    @State private var didTriggerTake = false
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        MCAccentCard(accent: statusColor) {
            HStack(spacing: MCSpacing.sm) {
                // Pill icon circle
                ZStack {
                    Circle()
                        .fill(statusColor.opacity(0.12))
                        .frame(width: MCSpacing.avatarSize, height: MCSpacing.avatarSize)

                    Image(systemName: doseFormIcon)
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundStyle(statusColor)
                }

                // Details
                VStack(alignment: .leading, spacing: MCSpacing.xxs) {
                    Text(medicineName)
                        .font(MCTypography.headline)
                        .foregroundStyle(MCColors.textPrimary)

                    Text(dosage)
                        .font(MCTypography.subheadline)
                        .foregroundStyle(MCColors.textSecondary)

                    HStack(spacing: MCSpacing.xs) {
                        if let mealTiming {
                            Label(mealTiming, systemImage: "fork.knife")
                                .font(MCTypography.caption)
                                .foregroundStyle(MCColors.textTertiary)
                        }

                        Label(scheduledTime.formatted(date: .omitted, time: .shortened), systemImage: "clock")
                            .font(MCTypography.caption)
                            .foregroundStyle(MCColors.textTertiary)
                    }
                }

                Spacer()

                // Status badge
                MCBadge(status, color: statusColor)
            }
        }
        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
            Button(role: .destructive) {
                onSkip()
            } label: {
                Label("Skip", systemImage: "xmark")
            }
            .tint(MCColors.error)

            Button {
                onSnooze()
            } label: {
                Label("Snooze", systemImage: "bell.and.waves.left.and.right")
            }
            .tint(Color.purple)
        }
        .swipeActions(edge: .leading, allowsFullSwipe: true) {
            Button {
                didTriggerTake.toggle()
                onTake()
            } label: {
                Label("Take", systemImage: "checkmark")
            }
            .tint(MCColors.success)
        }
        .sensoryFeedback(.success, trigger: didTriggerTake)
    }
}

#Preview {
    List {
        SwipeableMedicationCard(
            medicineName: "Metformin",
            dosage: "500mg",
            scheduledTime: Date(),
            doseFormIcon: "pills.fill",
            mealTiming: "After food",
            status: "Pending",
            statusColor: MCColors.warning,
            onTake: {},
            onSkip: {},
            onSnooze: {}
        )

        SwipeableMedicationCard(
            medicineName: "Amlodipine",
            dosage: "5mg",
            scheduledTime: Date().addingTimeInterval(-3600),
            doseFormIcon: "capsule.fill",
            mealTiming: nil,
            status: "Taken",
            statusColor: MCColors.success,
            onTake: {},
            onSkip: {},
            onSnooze: {}
        )
    }
    .listStyle(.plain)
}
