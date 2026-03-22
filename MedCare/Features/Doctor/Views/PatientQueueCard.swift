import SwiftUI

struct PatientQueueCard: View {
    let entry: QueueEntry
    let estimatedWaitMinutes: Int
    let onCall: () -> Void
    let onNoShow: () -> Void

    private static let timeFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "h:mm a"
        return f
    }()

    var body: some View {
        MCCard {
            HStack(spacing: MCSpacing.sm) {
                // Position badge
                positionBadge

                // Patient info
                VStack(alignment: .leading, spacing: MCSpacing.xxs) {
                    Text(entry.name)
                        .font(MCTypography.headline)
                        .foregroundStyle(MCColors.textPrimary)
                    Text(entry.reason)
                        .font(MCTypography.caption)
                        .foregroundStyle(MCColors.textSecondary)
                        .lineLimit(1)
                    HStack(spacing: MCSpacing.xs) {
                        HStack(spacing: MCSpacing.xxs) {
                            Image(systemName: "clock")
                                .font(.system(size: 10))
                            Text(Self.timeFormatter.string(from: entry.arrivalTime))
                                .font(MCTypography.caption)
                        }
                        .foregroundStyle(MCColors.textTertiary)

                        Text("~\(estimatedWaitMinutes) min wait")
                            .font(MCTypography.captionBold)
                            .foregroundStyle(waitColor)
                    }
                }

                Spacer()

                // Status badge
                MCBadge(entry.status.rawValue, color: entry.status.color, style: .soft)
            }
        }
        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
            Button(role: .destructive) {
                onNoShow()
            } label: {
                Label("No-Show", systemImage: "person.fill.xmark")
            }
            .tint(MCColors.textTertiary)
        }
        .swipeActions(edge: .leading, allowsFullSwipe: true) {
            Button {
                onCall()
            } label: {
                Label("Call In", systemImage: "stethoscope")
            }
            .tint(MCColors.primaryTeal)
        }
    }

    private var positionBadge: some View {
        ZStack {
            Circle()
                .fill(MCColors.warning.opacity(0.15))
                .frame(width: 40, height: 40)
            Text("#\(entry.position)")
                .font(MCTypography.captionBold)
                .foregroundStyle(MCColors.warning)
        }
    }

    private var waitColor: Color {
        switch estimatedWaitMinutes {
        case 0..<10: return MCColors.success
        case 10..<20: return MCColors.warning
        default: return MCColors.error
        }
    }
}

#Preview {
    PatientQueueCard(
        entry: QueueEntry(
            name: "Rahul Gupta",
            phone: "9123456789",
            reason: "Follow-up BP check",
            arrivalTime: Date().addingTimeInterval(-1800),
            status: .waiting,
            position: 2
        ),
        estimatedWaitMinutes: 10,
        onCall: {},
        onNoShow: {}
    )
    .padding()
}
