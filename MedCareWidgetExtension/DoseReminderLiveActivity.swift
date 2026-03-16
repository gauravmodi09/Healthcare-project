import ActivityKit
import SwiftUI
import WidgetKit

/// Dynamic Island + Lock Screen Live Activity for dose reminders
/// Shows medicine name, countdown, and quick actions (Take/Snooze/Skip)
struct DoseReminderLiveActivity: Widget {
    private let teal = Color(red: 10/255, green: 126/255, blue: 140/255)     // #0A7E8C
    private let darkText = Color(red: 31/255, green: 41/255, blue: 55/255)   // #1F2937

    var body: some WidgetConfiguration {
        ActivityConfiguration(for: DoseReminderAttributes.self) { context in
            // MARK: - Lock Screen Banner
            lockScreenView(context: context)
        } dynamicIsland: { context in
            DynamicIsland {
                // MARK: - Expanded Dynamic Island
                DynamicIslandExpandedRegion(.leading) {
                    Image(systemName: context.attributes.timingIcon)
                        .font(.system(size: 22, weight: .semibold))
                        .foregroundStyle(teal)
                        .frame(width: 36, height: 36)
                        .background(teal.opacity(0.15))
                        .clipShape(Circle())
                }

                DynamicIslandExpandedRegion(.trailing) {
                    countdownBadge(state: context.state, scheduledTime: context.attributes.scheduledTime)
                }

                DynamicIslandExpandedRegion(.center) {
                    VStack(spacing: 2) {
                        Text(context.attributes.medicineName)
                            .font(.system(size: 15, weight: .bold))
                            .lineLimit(1)
                        Text(context.attributes.dosage)
                            .font(.system(size: 13))
                            .foregroundStyle(.secondary)
                    }
                }

                DynamicIslandExpandedRegion(.bottom) {
                    VStack(spacing: 8) {
                        if let instructions = context.attributes.instructions {
                            Text(instructions)
                                .font(.system(size: 12))
                                .foregroundStyle(.secondary)
                        }

                        HStack(spacing: 12) {
                            // Take button
                            Link(destination: URL(string: "medcare://dose/take/\(context.attributes.doseLogId)")!) {
                                HStack(spacing: 4) {
                                    Image(systemName: "checkmark")
                                        .font(.system(size: 12, weight: .bold))
                                    Text("Take")
                                        .font(.system(size: 13, weight: .semibold))
                                }
                                .foregroundStyle(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 8)
                                .background(teal)
                                .clipShape(Capsule())
                            }

                            // Snooze button
                            Link(destination: URL(string: "medcare://dose/snooze/\(context.attributes.doseLogId)")!) {
                                HStack(spacing: 4) {
                                    Image(systemName: "clock.arrow.circlepath")
                                        .font(.system(size: 12, weight: .medium))
                                    Text("15 min")
                                        .font(.system(size: 13, weight: .medium))
                                }
                                .foregroundStyle(.white.opacity(0.9))
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 8)
                                .background(.white.opacity(0.2))
                                .clipShape(Capsule())
                            }
                        }
                    }
                }
            } compactLeading: {
                // MARK: - Compact Leading (left pill)
                Image(systemName: "pills.fill")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(teal)
            } compactTrailing: {
                // MARK: - Compact Trailing (right pill)
                compactCountdown(state: context.state, scheduledTime: context.attributes.scheduledTime)
            } minimal: {
                // MARK: - Minimal (when multiple Live Activities)
                Image(systemName: "pills.fill")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(teal)
            }
        }
    }

    // MARK: - Lock Screen View

    @ViewBuilder
    private func lockScreenView(context: ActivityViewContext<DoseReminderAttributes>) -> some View {
        VStack(spacing: 12) {
            // Header
            HStack {
                Image(systemName: context.attributes.timingIcon)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(teal)
                    .frame(width: 32, height: 32)
                    .background(teal.opacity(0.12))
                    .clipShape(Circle())

                VStack(alignment: .leading, spacing: 2) {
                    Text("Time for your medicine")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(darkText)
                    Text("\(context.attributes.timingLabel) dose")
                        .font(.system(size: 12))
                        .foregroundStyle(.secondary)
                }

                Spacer()

                countdownBadge(state: context.state, scheduledTime: context.attributes.scheduledTime)
            }

            // Medicine info
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(context.attributes.medicineName)
                        .font(.system(size: 17, weight: .bold))
                        .foregroundStyle(darkText)

                    HStack(spacing: 8) {
                        Text(context.attributes.dosage)
                            .font(.system(size: 14))
                            .foregroundStyle(.secondary)

                        if let instructions = context.attributes.instructions {
                            Text("•")
                                .foregroundStyle(.secondary)
                            Text(instructions)
                                .font(.system(size: 14))
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                Spacer()
            }

            // Action buttons
            HStack(spacing: 10) {
                Link(destination: URL(string: "medcare://dose/take/\(context.attributes.doseLogId)")!) {
                    HStack(spacing: 6) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 14))
                        Text("Take")
                            .font(.system(size: 14, weight: .semibold))
                    }
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(teal)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                }

                Link(destination: URL(string: "medcare://dose/snooze/\(context.attributes.doseLogId)")!) {
                    HStack(spacing: 6) {
                        Image(systemName: "clock.arrow.circlepath")
                            .font(.system(size: 14))
                        Text("Snooze")
                            .font(.system(size: 14, weight: .medium))
                    }
                    .foregroundStyle(teal)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(teal.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                }

                Link(destination: URL(string: "medcare://dose/skip/\(context.attributes.doseLogId)")!) {
                    HStack(spacing: 6) {
                        Image(systemName: "forward.fill")
                            .font(.system(size: 12))
                        Text("Skip")
                            .font(.system(size: 14, weight: .medium))
                    }
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(Color(.systemGray5))
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                }
            }
        }
        .padding(16)
        .activityBackgroundTint(Color(.systemBackground))
    }

    // MARK: - Countdown Helpers

    @ViewBuilder
    private func countdownBadge(state: DoseReminderAttributes.ContentState, scheduledTime: Date) -> some View {
        let text = countdownText(state: state)
        let color = countdownColor(state: state)

        Text(text)
            .font(.system(size: 12, weight: .bold))
            .foregroundStyle(color)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(color.opacity(0.12))
            .clipShape(Capsule())
    }

    @ViewBuilder
    private func compactCountdown(state: DoseReminderAttributes.ContentState, scheduledTime: Date) -> some View {
        let text = countdownText(state: state)
        let color = countdownColor(state: state)

        Text(text)
            .font(.system(size: 12, weight: .bold))
            .monospacedDigit()
            .foregroundStyle(color)
    }

    private func countdownText(state: DoseReminderAttributes.ContentState) -> String {
        switch state.status {
        case .upcoming:
            return "in \(state.minutesRemaining)m"
        case .due:
            return "NOW"
        case .overdue:
            return "\(abs(state.minutesRemaining))m late"
        case .snoozed:
            return "Snoozed"
        case .completed:
            return "Done"
        }
    }

    private func countdownColor(state: DoseReminderAttributes.ContentState) -> Color {
        switch state.status {
        case .upcoming: return teal
        case .due: return .orange
        case .overdue: return .red
        case .snoozed: return .blue
        case .completed: return .green
        }
    }
}
