import SwiftUI

/// Individual milestone card in the treatment timeline
struct TimelineMilestoneCard: View {
    let milestone: Milestone
    let isLast: Bool

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            // Vertical connector
            VStack(spacing: 0) {
                // Dot
                Circle()
                    .fill(Color(hex: milestone.status.color))
                    .frame(width: 12, height: 12)
                    .overlay(
                        Circle()
                            .fill(.white)
                            .frame(width: 6, height: 6)
                            .opacity(milestone.status == .upcoming ? 1 : 0)
                    )

                // Line connector
                if !isLast {
                    Rectangle()
                        .fill(Color(hex: "EEF1F6"))
                        .frame(width: 2)
                        .frame(maxHeight: .infinity)
                }
            }
            .frame(width: 12)

            // Content
            HStack(spacing: 10) {
                Image(systemName: milestone.icon)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(Color(hex: milestone.status.color))
                    .frame(width: 28, height: 28)
                    .background(Color(hex: milestone.status.color).opacity(0.1))
                    .clipShape(Circle())

                VStack(alignment: .leading, spacing: 2) {
                    Text(milestone.title)
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(Color(hex: "1F2937"))
                        .strikethrough(milestone.status == .completed, color: Color(hex: "34C759"))

                    Text(milestone.date.formatted(date: .abbreviated, time: .omitted))
                        .font(.system(size: 11))
                        .foregroundColor(Color(hex: "9CA3AF"))
                }

                Spacer()

                // Status badge
                statusBadge
            }
            .padding(.vertical, 8)
            .padding(.horizontal, 10)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color(hex: milestone.status.color).opacity(0.04))
            )
        }
        .frame(minHeight: 50)
    }

    @ViewBuilder
    private var statusBadge: some View {
        switch milestone.status {
        case .completed:
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 16))
                .foregroundColor(Color(hex: "34C759"))
        case .upcoming:
            Text(daysUntil)
                .font(.system(size: 11, weight: .semibold))
                .foregroundColor(Color(hex: "007AFF"))
                .padding(.horizontal, 8)
                .padding(.vertical, 3)
                .background(Color(hex: "007AFF").opacity(0.1))
                .clipShape(Capsule())
        case .overdue:
            Text("Overdue")
                .font(.system(size: 11, weight: .bold))
                .foregroundColor(Color(hex: "FF3B30"))
                .padding(.horizontal, 8)
                .padding(.vertical, 3)
                .background(Color(hex: "FF3B30").opacity(0.1))
                .clipShape(Capsule())
        }
    }

    private var daysUntil: String {
        let days = Calendar.current.dateComponents([.day], from: Date(), to: milestone.date).day ?? 0
        if days == 0 { return "Today" }
        if days == 1 { return "Tomorrow" }
        return "In \(days) days"
    }
}
