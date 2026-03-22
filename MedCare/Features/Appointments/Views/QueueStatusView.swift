import SwiftUI

struct QueueStatusView: View {
    @Environment(\.dismiss) private var dismiss

    let position: Int
    let estimatedWaitMinutes: Int
    let totalAhead: Int

    init(position: Int = 3, estimatedWaitMinutes: Int = 20, totalAhead: Int = 2) {
        self.position = position
        self.estimatedWaitMinutes = estimatedWaitMinutes
        self.totalAhead = totalAhead
    }

    private var progress: Double {
        guard totalAhead + 1 > 0 else { return 1.0 }
        return 1.0 - (Double(position - 1) / Double(totalAhead + 1))
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: MCSpacing.sectionSpacing) {
                Spacer()

                // Position circle
                ZStack {
                    Circle()
                        .stroke(MCColors.divider, lineWidth: 6)
                        .frame(width: 160, height: 160)

                    Circle()
                        .trim(from: 0, to: progress)
                        .stroke(MCColors.primaryTeal, style: StrokeStyle(lineWidth: 6, lineCap: .round))
                        .frame(width: 160, height: 160)
                        .rotationEffect(.degrees(-90))

                    VStack(spacing: MCSpacing.xxs) {
                        Text("Your Position")
                            .font(MCTypography.caption)
                            .foregroundStyle(MCColors.textSecondary)
                        Text("#\(position)")
                            .font(MCTypography.heroMetric)
                            .foregroundStyle(MCColors.primaryTeal)
                    }
                }

                // Estimated wait
                VStack(spacing: MCSpacing.xs) {
                    Text("Estimated Wait")
                        .font(MCTypography.subheadline)
                        .foregroundStyle(MCColors.textSecondary)
                    Text("~\(estimatedWaitMinutes) minutes")
                        .font(MCTypography.title)
                        .foregroundStyle(MCColors.textPrimary)
                }

                // Progress bar
                VStack(alignment: .leading, spacing: MCSpacing.xs) {
                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            RoundedRectangle(cornerRadius: 4)
                                .fill(MCColors.divider)
                                .frame(height: 8)

                            RoundedRectangle(cornerRadius: 4)
                                .fill(MCColors.primaryGradient)
                                .frame(width: geo.size.width * progress, height: 8)
                        }
                    }
                    .frame(height: 8)

                    HStack {
                        Text("\(totalAhead) patients ahead")
                            .font(MCTypography.caption)
                            .foregroundStyle(MCColors.textTertiary)
                        Spacer()
                        Text("Your turn")
                            .font(MCTypography.caption)
                            .foregroundStyle(MCColors.primaryTeal)
                    }
                }
                .padding(.horizontal, MCSpacing.xl)

                // Notification info
                MCAccentCard(accent: MCColors.info) {
                    HStack(spacing: MCSpacing.sm) {
                        Image(systemName: "bell.badge.fill")
                            .font(.system(size: 20))
                            .foregroundStyle(MCColors.info)

                        VStack(alignment: .leading, spacing: MCSpacing.xxs) {
                            Text("Notifications Enabled")
                                .font(MCTypography.headline)
                                .foregroundStyle(MCColors.textPrimary)
                            Text("You'll be notified when it's almost your turn")
                                .font(MCTypography.caption)
                                .foregroundStyle(MCColors.textSecondary)
                        }
                    }
                }
                .padding(.horizontal, MCSpacing.screenPadding)

                Spacer()

                // Status details
                MCCard {
                    VStack(spacing: MCSpacing.sm) {
                        statusRow(icon: "building.2", label: "Clinic", value: "MedCare Clinic")
                        Divider()
                        statusRow(icon: "stethoscope", label: "Doctor", value: "Dr. Anil Mehta")
                        Divider()
                        statusRow(icon: "clock", label: "Arrived At", value: arrivalTimeString)
                    }
                }
                .padding(.horizontal, MCSpacing.screenPadding)
                .padding(.bottom, MCSpacing.lg)
            }
            .background(MCColors.backgroundLight)
            .navigationTitle("Queue Status")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                }
            }
        }
    }

    private func statusRow(icon: String, label: String, value: String) -> some View {
        HStack(spacing: MCSpacing.sm) {
            Image(systemName: icon)
                .font(.system(size: 14))
                .foregroundStyle(MCColors.primaryTeal)
                .frame(width: 24)
            Text(label)
                .font(MCTypography.subheadline)
                .foregroundStyle(MCColors.textSecondary)
            Spacer()
            Text(value)
                .font(MCTypography.subheadline)
                .foregroundStyle(MCColors.textPrimary)
        }
    }

    private var arrivalTimeString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        return formatter.string(from: Date())
    }
}

#Preview {
    QueueStatusView(position: 3, estimatedWaitMinutes: 20, totalAhead: 4)
}
