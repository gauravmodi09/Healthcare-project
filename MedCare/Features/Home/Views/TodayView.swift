import SwiftUI
import SwiftData

/// Consolidated daily schedule — all doses, tasks, and care activities for today
struct TodayView: View {
    @Environment(DataService.self) private var dataService
    @Query private var users: [User]

    private var activeProfile: UserProfile? { users.first?.activeProfile }

    var body: some View {
        NavigationStack {
            ScrollView {
                if let profile = activeProfile {
                    let doses = dataService.todaysDoses(for: profile)
                    let tasks = todaysTasks(for: profile)
                    let totalItems = doses.count + tasks.count

                    VStack(spacing: MCSpacing.md) {
                        // Today's summary header
                        todaySummary(doses: doses, tasks: tasks)

                        if totalItems == 0 {
                            emptyState
                        } else {
                            // Timeline
                            timelineSection(doses: doses, tasks: tasks)
                        }
                    }
                    .padding(.horizontal, MCSpacing.screenPadding)
                    .padding(.vertical, MCSpacing.md)
                }
            }
            .background(MCColors.backgroundLight)
            .navigationTitle("Today")
        }
    }

    // MARK: - Summary Card

    private func todaySummary(doses: [DoseLog], tasks: [CareTask]) -> some View {
        let taken = doses.filter { $0.status == .taken }.count
        let pending = doses.filter { $0.status == .pending }.count
        let completedTasks = tasks.filter { $0.isCompleted }.count
        let adherence = doses.isEmpty ? 1.0 : Double(taken) / Double(doses.count)

        return MCCard {
            VStack(spacing: MCSpacing.sm) {
                HStack {
                    VStack(alignment: .leading, spacing: MCSpacing.xxs) {
                        Text(Date(), format: .dateTime.weekday(.wide).month(.wide).day())
                            .font(MCTypography.headline)
                            .foregroundStyle(MCColors.textPrimary)
                        Text("\(taken)/\(doses.count) doses taken · \(completedTasks)/\(tasks.count) tasks done")
                            .font(MCTypography.caption)
                            .foregroundStyle(MCColors.textSecondary)
                    }
                    Spacer()
                    // Circular progress
                    ZStack {
                        Circle()
                            .stroke(MCColors.primaryTeal.opacity(0.15), lineWidth: 4)
                            .frame(width: 44, height: 44)
                        Circle()
                            .trim(from: 0, to: adherence)
                            .stroke(MCColors.primaryTeal, style: StrokeStyle(lineWidth: 4, lineCap: .round))
                            .frame(width: 44, height: 44)
                            .rotationEffect(.degrees(-90))
                        Text("\(Int(adherence * 100))%")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundStyle(MCColors.primaryTeal)
                    }
                }

                // Progress bar
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Capsule()
                            .fill(MCColors.primaryTeal.opacity(0.1))
                            .frame(height: 6)
                        Capsule()
                            .fill(MCColors.primaryTeal)
                            .frame(width: geo.size.width * adherence, height: 6)
                    }
                }
                .frame(height: 6)

                if pending > 0 {
                    HStack(spacing: MCSpacing.xxs) {
                        Image(systemName: "clock")
                            .font(.system(size: 12))
                        Text("\(pending) doses remaining today")
                            .font(MCTypography.caption)
                    }
                    .foregroundStyle(MCColors.warning)
                }
            }
        }
    }

    // MARK: - Timeline

    private func timelineSection(doses: [DoseLog], tasks: [CareTask]) -> some View {
        let timeSlots = buildTimeline(doses: doses, tasks: tasks)

        return VStack(alignment: .leading, spacing: 0) {
            Text("Schedule")
                .font(MCTypography.headline)
                .foregroundStyle(MCColors.textPrimary)
                .padding(.bottom, MCSpacing.sm)

            ForEach(Array(timeSlots.enumerated()), id: \.element.id) { index, slot in
                HStack(alignment: .top, spacing: MCSpacing.sm) {
                    // Time column
                    VStack {
                        Text(slot.timeLabel)
                            .font(MCTypography.captionBold)
                            .foregroundStyle(slot.isPast ? MCColors.textTertiary : MCColors.primaryTeal)
                            .frame(width: 50, alignment: .trailing)
                    }

                    // Timeline line
                    VStack(spacing: 0) {
                        Circle()
                            .fill(slot.dotColor)
                            .frame(width: 10, height: 10)
                            .padding(.top, 4)
                        if index < timeSlots.count - 1 {
                            Rectangle()
                                .fill(MCColors.divider)
                                .frame(width: 2)
                                .frame(minHeight: 50)
                        }
                    }

                    // Content
                    VStack(alignment: .leading, spacing: MCSpacing.xxs) {
                        Text(slot.title)
                            .font(MCTypography.bodyMedium)
                            .foregroundStyle(slot.isPast ? MCColors.textSecondary : MCColors.textPrimary)
                            .strikethrough(slot.isCompleted && slot.isPast)
                        Text(slot.subtitle)
                            .font(MCTypography.caption)
                            .foregroundStyle(MCColors.textTertiary)
                        if let badge = slot.badge {
                            MCBadge(badge, color: slot.badgeColor)
                        }
                    }
                    .padding(.bottom, MCSpacing.md)

                    Spacer()
                }
            }
        }
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: MCSpacing.md) {
            Spacer()
            Image(systemName: "calendar.badge.checkmark")
                .font(.system(size: 48))
                .foregroundStyle(MCColors.textTertiary)
            Text("Nothing scheduled today")
                .font(MCTypography.headline)
                .foregroundStyle(MCColors.textSecondary)
            Text("Upload a prescription to start tracking")
                .font(MCTypography.footnote)
                .foregroundStyle(MCColors.textTertiary)
            Spacer()
        }
        .frame(maxWidth: .infinity)
        .padding(.top, MCSpacing.xxl)
    }

    // MARK: - Helpers

    private func todaysTasks(for profile: UserProfile) -> [CareTask] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let tomorrow = calendar.date(byAdding: .day, value: 1, to: today)!

        return profile.episodes
            .flatMap { $0.tasks }
            .filter { task in
                guard let due = task.dueDate else { return false }
                return due >= today && due < tomorrow
            }
            .sorted { ($0.dueDate ?? .distantFuture) < ($1.dueDate ?? .distantFuture) }
    }

    private struct TimelineSlot: Identifiable {
        let id = UUID()
        let timeLabel: String
        let title: String
        let subtitle: String
        let badge: String?
        let badgeColor: Color
        let dotColor: Color
        let isPast: Bool
        let isCompleted: Bool
        let sortDate: Date
    }

    private func buildTimeline(doses: [DoseLog], tasks: [CareTask]) -> [TimelineSlot] {
        var slots: [TimelineSlot] = []
        let now = Date()

        for dose in doses {
            let isPast = dose.scheduledTime < now
            let statusText: String
            let dotColor: Color
            let badge: String?
            let badgeColor: Color

            switch dose.status {
            case .taken:
                statusText = "Taken"
                dotColor = MCColors.success
                badge = "Taken"
                badgeColor = MCColors.success
            case .skipped:
                statusText = "Skipped"
                dotColor = MCColors.warning
                badge = "Skipped"
                badgeColor = MCColors.warning
            case .missed:
                statusText = "Missed"
                dotColor = MCColors.error
                badge = "Missed"
                badgeColor = MCColors.error
            case .pending:
                statusText = "Pending"
                dotColor = isPast ? MCColors.warning : MCColors.primaryTeal
                badge = isPast ? "Overdue" : nil
                badgeColor = MCColors.warning
            case .snoozed:
                statusText = "Snoozed"
                dotColor = MCColors.info
                badge = "Snoozed"
                badgeColor = MCColors.info
            case .outOfStock:
                statusText = "Out of Stock"
                dotColor = MCColors.error
                badge = "Out of Stock"
                badgeColor = MCColors.error
            }

            let mealLabel = dose.medicine?.mealTiming != .noPreference
                ? " · \(dose.medicine?.mealTiming.shortLabel ?? "")" : ""
            let genericLabel = dose.medicine?.genericName.map { " (\($0))" } ?? ""

            slots.append(TimelineSlot(
                timeLabel: dose.scheduledTime.formatted(date: .omitted, time: .shortened),
                title: "\(dose.medicine?.brandName ?? "Medicine") \(dose.medicine?.dosage ?? "")",
                subtitle: "\(dose.medicine?.doseForm.rawValue ?? "Tablet")\(mealLabel)\(genericLabel)",
                badge: badge,
                badgeColor: badgeColor,
                dotColor: dotColor,
                isPast: isPast,
                isCompleted: dose.status == .taken,
                sortDate: dose.scheduledTime
            ))
        }

        for task in tasks {
            let dueDate = task.dueDate ?? Date()
            slots.append(TimelineSlot(
                timeLabel: dueDate.formatted(date: .omitted, time: .shortened),
                title: task.title,
                subtitle: task.taskType.rawValue,
                badge: task.isCompleted ? "Done" : nil,
                badgeColor: MCColors.success,
                dotColor: task.isCompleted ? MCColors.success : MCColors.info,
                isPast: dueDate < now,
                isCompleted: task.isCompleted,
                sortDate: dueDate
            ))
        }

        return slots.sorted { $0.sortDate < $1.sortDate }
    }
}
