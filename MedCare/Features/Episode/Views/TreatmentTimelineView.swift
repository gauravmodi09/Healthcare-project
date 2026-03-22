import SwiftUI

/// Treatment Timeline — shows treatment progress, milestones, and adherence streak
struct TreatmentTimelineView: View {
    let episode: Episode

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
            HStack {
                Image(systemName: "chart.line.uptrend.xyaxis")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(Color(hex: "0A7E8C"))
                Text("Treatment Progress")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(Color(hex: "1F2937"))
                Spacer()
            }

            // Progress bar
            progressSection

            // Stats row
            statsRow

            // Milestones
            if !milestones.isEmpty {
                VStack(alignment: .leading, spacing: 0) {
                    Text("Milestones")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(Color(hex: "6B7280"))
                        .padding(.bottom, 8)

                    ForEach(Array(milestones.enumerated()), id: \.offset) { index, milestone in
                        TimelineMilestoneCard(
                            milestone: milestone,
                            isLast: index == milestones.count - 1
                        )
                    }
                }
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.white)
                .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
        )
    }

    // MARK: - Progress Bar

    private var progressSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Day counter
            HStack {
                Text(dayLabel)
                    .font(.system(size: 22, weight: .bold))
                    .foregroundColor(Color(hex: "0A7E8C"))

                Spacer()

                // Streak
                if adherenceStreak > 0 {
                    HStack(spacing: 4) {
                        Text("🔥")
                        Text("\(adherenceStreak)-day streak!")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundColor(Color(hex: "F5A623"))
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(Color(hex: "F5A623").opacity(0.12))
                    .clipShape(Capsule())
                }
            }

            // Progress track
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    // Background track
                    RoundedRectangle(cornerRadius: 6)
                        .fill(Color(hex: "EEF1F6"))
                        .frame(height: 10)

                    // Fill
                    RoundedRectangle(cornerRadius: 6)
                        .fill(progressGradient)
                        .frame(width: max(0, geo.size.width * progressPercentage), height: 10)
                        .animation(.spring(response: 0.8), value: progressPercentage)
                }
            }
            .frame(height: 10)

            // Sub-label
            Text(progressSubLabel)
                .font(.system(size: 12))
                .foregroundColor(Color(hex: "9CA3AF"))
        }
    }

    // MARK: - Stats Row

    private var statsRow: some View {
        HStack(spacing: 12) {
            StatPill(
                icon: "pills.fill",
                label: "Adherence",
                value: "\(Int(episode.adherencePercentage * 100))%",
                color: adherenceColor
            )

            StatPill(
                icon: "heart.text.square",
                label: "Medicines",
                value: "\(episode.activeMedicines.count) active",
                color: "007AFF"
            )

            if let latest = episode.symptomLogs.sorted(by: { $0.date > $1.date }).first {
                StatPill(
                    icon: "face.smiling",
                    label: "Feeling",
                    value: latest.overallFeeling.emoji,
                    color: "34C759"
                )
            }
        }
    }

    // MARK: - Computed Properties

    private var totalDays: Int {
        guard let end = episode.endDate else {
            // For chronic/ongoing episodes, use 30 days as a cycle
            return 30
        }
        return max(1, Calendar.current.dateComponents([.day], from: episode.startDate, to: end).day ?? 1)
    }

    private var elapsedDays: Int {
        max(0, Calendar.current.dateComponents([.day], from: episode.startDate, to: Date()).day ?? 0)
    }

    private var progressPercentage: Double {
        min(1.0, max(0, Double(elapsedDays) / Double(totalDays)))
    }

    private var dayLabel: String {
        if let remaining = episode.daysRemaining, remaining > 0 {
            return "Day \(elapsedDays + 1) of \(totalDays)"
        } else if episode.endDate != nil {
            return "Course Complete ✓"
        } else {
            return "Day \(elapsedDays + 1)"
        }
    }

    private var progressSubLabel: String {
        if let remaining = episode.daysRemaining, remaining > 0 {
            return "\(remaining) day\(remaining == 1 ? "" : "s") remaining — you're \(Int(progressPercentage * 100))% through!"
        } else if episode.endDate != nil {
            return "You've completed the full course. Great job! 🎉"
        }
        return "Ongoing treatment — keep it up!"
    }

    private var adherenceStreak: Int {
        let allLogs = episode.medicines.flatMap { $0.doseLogs }
            .sorted { $0.scheduledTime > $1.scheduledTime }

        var streak = 0
        for log in allLogs {
            if log.status == .taken {
                streak += 1
            } else if log.status == .missed || log.status == .skipped {
                break
            }
        }
        return streak
    }

    private var adherenceColor: String {
        let pct = episode.adherencePercentage
        if pct >= 0.8 { return "34C759" }
        if pct >= 0.5 { return "F5A623" }
        return "FF3B30"
    }

    private var progressGradient: LinearGradient {
        let pct = episode.adherencePercentage
        if pct >= 0.8 {
            return LinearGradient(colors: [Color(hex: "0A7E8C"), Color(hex: "34C759")], startPoint: .leading, endPoint: .trailing)
        } else if pct >= 0.5 {
            return LinearGradient(colors: [Color(hex: "0A7E8C"), Color(hex: "F5A623")], startPoint: .leading, endPoint: .trailing)
        }
        return LinearGradient(colors: [Color(hex: "FF6B6B"), Color(hex: "FF3B30")], startPoint: .leading, endPoint: .trailing)
    }

    // MARK: - Milestones

    private var milestones: [Milestone] {
        var items: [Milestone] = []

        // Course start
        items.append(Milestone(
            title: "Treatment Started",
            date: episode.startDate,
            icon: "play.circle.fill",
            status: .completed
        ))

        // 50% point
        let halfDate = Calendar.current.date(byAdding: .day, value: totalDays / 2, to: episode.startDate) ?? Date()
        items.append(Milestone(
            title: "50% Course Complete",
            date: halfDate,
            icon: "flag.fill",
            status: halfDate <= Date() ? .completed : .upcoming
        ))

        // Follow-up
        if let followUp = episode.followUpDate {
            items.append(Milestone(
                title: "Follow-up Appointment",
                date: followUp,
                icon: "stethoscope",
                status: followUp <= Date() ? (followUp < Date() ? .overdue : .completed) : .upcoming
            ))
        }

        // Course end
        if let endDate = episode.endDate {
            items.append(Milestone(
                title: "Treatment Completion",
                date: endDate,
                icon: "checkmark.circle.fill",
                status: endDate <= Date() ? .completed : .upcoming
            ))
        }

        return items.sorted { $0.date < $1.date }
    }
}

// MARK: - Milestone Model

struct Milestone {
    let title: String
    let date: Date
    let icon: String
    let status: MilestoneStatus
}

enum MilestoneStatus {
    case completed, upcoming, overdue

    var color: String {
        switch self {
        case .completed: return "34C759"
        case .upcoming: return "007AFF"
        case .overdue: return "FF3B30"
        }
    }
}

// MARK: - Stat Pill

struct StatPill: View {
    let icon: String
    let label: String
    let value: String
    let color: String

    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.system(size: 14))
                .foregroundColor(Color(hex: color))
            Text(value)
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(Color(hex: "1F2937"))
            Text(label)
                .font(.system(size: 10))
                .foregroundColor(Color(hex: "9CA3AF"))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 10)
        .background(Color(hex: color).opacity(0.06))
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }
}
