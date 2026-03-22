import SwiftUI

/// Appointment calendar showing upcoming care tasks (follow-ups, lab tests, etc.) on a calendar grid.
struct AppointmentCalendarView: View {
    let profile: UserProfile
    @Environment(\.dismiss) private var dismiss
    @State private var displayedMonth: Date = Date()
    @State private var selectedDay: Date?
    @State private var showDayDetail = false

    private let calendar = Calendar.current
    private let weekdaySymbols = ["S", "M", "T", "W", "T", "F", "S"]
    private let columns = Array(repeating: GridItem(.flexible(), spacing: MCSpacing.xxs), count: 7)

    /// All tasks with a due date across all episodes
    private var allTasks: [CareTask] {
        profile.episodes.flatMap { $0.tasks }.filter { $0.dueDate != nil }
    }

    /// Tasks grouped by start-of-day
    private var tasksByDay: [Date: [CareTask]] {
        Dictionary(grouping: allTasks) { task in
            calendar.startOfDay(for: task.dueDate!)
        }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: MCSpacing.lg) {
                    // Month header
                    monthHeader

                    // Weekday labels
                    weekdayHeader

                    // Day grid
                    dayGrid

                    // Legend
                    legendRow

                    Divider()
                        .padding(.horizontal, MCSpacing.screenPadding)

                    // Upcoming list
                    upcomingTasksList
                }
                .padding(.vertical, MCSpacing.md)
            }
            .background(MCColors.backgroundLight)
            .navigationTitle("Appointments")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                        .foregroundStyle(MCColors.primaryTeal)
                }
            }
            .sheet(isPresented: $showDayDetail) {
                if let selectedDay {
                    DayTasksSheet(tasks: tasksByDay[calendar.startOfDay(for: selectedDay)] ?? [], date: selectedDay)
                        .presentationDetents([.medium])
                        .presentationDragIndicator(.visible)
                }
            }
        }
    }

    // MARK: - Month Header

    private var monthHeader: some View {
        HStack {
            Button {
                withAnimation(.easeInOut(duration: 0.25)) {
                    displayedMonth = calendar.date(byAdding: .month, value: -1, to: displayedMonth) ?? displayedMonth
                }
            } label: {
                Image(systemName: "chevron.left")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(MCColors.primaryTeal)
                    .frame(width: 36, height: 36)
                    .background(MCColors.primaryTeal.opacity(0.1))
                    .clipShape(Circle())
            }

            Spacer()

            Text(monthYearString(displayedMonth))
                .font(MCTypography.headline)
                .foregroundStyle(MCColors.textPrimary)

            Spacer()

            Button {
                withAnimation(.easeInOut(duration: 0.25)) {
                    displayedMonth = calendar.date(byAdding: .month, value: 1, to: displayedMonth) ?? displayedMonth
                }
            } label: {
                Image(systemName: "chevron.right")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(MCColors.primaryTeal)
                    .frame(width: 36, height: 36)
                    .background(MCColors.primaryTeal.opacity(0.1))
                    .clipShape(Circle())
            }
        }
        .padding(.horizontal, MCSpacing.screenPadding)
    }

    // MARK: - Weekday Header

    private var weekdayHeader: some View {
        LazyVGrid(columns: columns, spacing: MCSpacing.xxs) {
            ForEach(weekdaySymbols, id: \.self) { symbol in
                Text(symbol)
                    .font(MCTypography.captionBold)
                    .foregroundStyle(MCColors.textTertiary)
                    .frame(maxWidth: .infinity)
            }
        }
        .padding(.horizontal, MCSpacing.screenPadding)
    }

    // MARK: - Day Grid

    private var dayGrid: some View {
        let days = daysInMonth()
        return LazyVGrid(columns: columns, spacing: MCSpacing.xxs) {
            ForEach(Array(days.enumerated()), id: \.offset) { _, date in
                if let date {
                    dayCell(date)
                } else {
                    Color.clear
                        .frame(height: 44)
                }
            }
        }
        .padding(.horizontal, MCSpacing.screenPadding)
    }

    private func dayCell(_ date: Date) -> some View {
        let startOfDay = calendar.startOfDay(for: date)
        let tasks = tasksByDay[startOfDay] ?? []
        let isToday = calendar.isDateInToday(date)
        let hasTasks = !tasks.isEmpty
        let allCompleted = hasTasks && tasks.allSatisfy { $0.isCompleted }

        return Button {
            selectedDay = date
            showDayDetail = true
        } label: {
            VStack(spacing: 2) {
                Text("\(calendar.component(.day, from: date))")
                    .font(isToday ? MCTypography.captionBold : MCTypography.caption)
                    .foregroundStyle(isToday ? MCColors.primaryTeal : MCColors.textPrimary)

                if hasTasks {
                    Circle()
                        .fill(allCompleted ? MCColors.success : MCColors.accentCoral)
                        .frame(width: 6, height: 6)
                } else {
                    Circle()
                        .fill(Color.clear)
                        .frame(width: 6, height: 6)
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: 44)
            .background(hasTasks ? (allCompleted ? MCColors.success.opacity(0.1) : MCColors.accentCoral.opacity(0.1)) : Color.clear)
            .clipShape(RoundedRectangle(cornerRadius: 6))
            .overlay(
                RoundedRectangle(cornerRadius: 6)
                    .stroke(isToday ? MCColors.primaryTeal : Color.clear, lineWidth: 2)
            )
        }
        .buttonStyle(.plain)
        .disabled(!hasTasks)
    }

    // MARK: - Legend

    private var legendRow: some View {
        HStack(spacing: MCSpacing.md) {
            legendDot(color: MCColors.accentCoral, label: "Upcoming")
            legendDot(color: MCColors.success, label: "Completed")
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, MCSpacing.screenPadding)
    }

    private func legendDot(color: Color, label: String) -> some View {
        HStack(spacing: MCSpacing.xxs) {
            Circle()
                .fill(color)
                .frame(width: 8, height: 8)
            Text(label)
                .font(.system(size: 10))
                .foregroundStyle(MCColors.textTertiary)
        }
    }

    // MARK: - Upcoming Tasks List

    private var upcomingTasksList: some View {
        VStack(alignment: .leading, spacing: MCSpacing.sm) {
            Text("Upcoming Appointments")
                .font(MCTypography.headline)
                .foregroundStyle(MCColors.textPrimary)
                .padding(.horizontal, MCSpacing.screenPadding)

            let upcoming = allTasks
                .filter { !$0.isCompleted && ($0.dueDate ?? .distantPast) >= calendar.startOfDay(for: Date()) }
                .sorted { ($0.dueDate ?? .distantFuture) < ($1.dueDate ?? .distantFuture) }

            if upcoming.isEmpty {
                MCCard {
                    VStack(spacing: MCSpacing.sm) {
                        Image(systemName: "calendar.badge.checkmark")
                            .font(.system(size: 32))
                            .foregroundStyle(MCColors.textTertiary)
                        Text("No upcoming appointments")
                            .font(MCTypography.body)
                            .foregroundStyle(MCColors.textSecondary)
                        Text("Follow-ups, lab tests, and other tasks will show up here.")
                            .font(MCTypography.caption)
                            .foregroundStyle(MCColors.textTertiary)
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, MCSpacing.md)
                }
                .padding(.horizontal, MCSpacing.screenPadding)
            } else {
                ForEach(upcoming) { task in
                    MCCard {
                        HStack(spacing: MCSpacing.sm) {
                            Image(systemName: task.taskType.icon)
                                .foregroundStyle(MCColors.primaryTeal)
                                .font(.system(size: 14))
                                .frame(width: 32, height: 32)
                                .background(MCColors.primaryTeal.opacity(0.1))
                                .clipShape(RoundedRectangle(cornerRadius: 6))

                            VStack(alignment: .leading, spacing: 2) {
                                Text(task.title)
                                    .font(MCTypography.bodyMedium)
                                    .foregroundStyle(MCColors.textPrimary)
                                if let episode = task.episode {
                                    Text(episode.title)
                                        .font(MCTypography.caption)
                                        .foregroundStyle(MCColors.textSecondary)
                                }
                            }

                            Spacer()

                            if let due = task.dueDate {
                                VStack(alignment: .trailing, spacing: 2) {
                                    Text(due, style: .date)
                                        .font(MCTypography.captionBold)
                                        .foregroundStyle(MCColors.textPrimary)
                                    Text(due, style: .relative)
                                        .font(MCTypography.caption)
                                        .foregroundStyle(MCColors.textTertiary)
                                }
                            }
                        }
                    }
                    .padding(.horizontal, MCSpacing.screenPadding)
                }
            }
        }
    }

    // MARK: - Helpers

    private func monthYearString(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        return formatter.string(from: date)
    }

    private func daysInMonth() -> [Date?] {
        guard let range = calendar.range(of: .day, in: .month, for: displayedMonth),
              let firstOfMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: displayedMonth))
        else { return [] }

        let firstWeekday = calendar.component(.weekday, from: firstOfMonth)
        let leadingBlanks = firstWeekday - 1

        var days: [Date?] = Array(repeating: nil, count: leadingBlanks)

        for day in range {
            if let date = calendar.date(byAdding: .day, value: day - 1, to: firstOfMonth) {
                days.append(date)
            }
        }

        return days
    }
}

// MARK: - Day Tasks Sheet

private struct DayTasksSheet: View {
    let tasks: [CareTask]
    let date: Date

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: MCSpacing.sm) {
                    if tasks.isEmpty {
                        MCEmptyState(
                            icon: "calendar.badge.minus",
                            title: "No Appointments",
                            message: "Nothing scheduled for this day."
                        )
                    } else {
                        ForEach(tasks) { task in
                            MCCard {
                                HStack(spacing: MCSpacing.sm) {
                                    Image(systemName: task.isCompleted ? "checkmark.circle.fill" : "circle")
                                        .font(.system(size: 20))
                                        .foregroundStyle(task.isCompleted ? MCColors.success : MCColors.textTertiary)

                                    Image(systemName: task.taskType.icon)
                                        .foregroundStyle(MCColors.primaryTeal)
                                        .font(.system(size: 14))

                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(task.title)
                                            .font(MCTypography.bodyMedium)
                                            .foregroundStyle(task.isCompleted ? MCColors.textTertiary : MCColors.textPrimary)
                                            .strikethrough(task.isCompleted)

                                        Text(task.taskType.rawValue)
                                            .font(MCTypography.caption)
                                            .foregroundStyle(MCColors.textSecondary)

                                        if let episode = task.episode {
                                            Text(episode.title)
                                                .font(MCTypography.caption)
                                                .foregroundStyle(MCColors.primaryTeal)
                                        }
                                    }

                                    Spacer()
                                }
                            }
                        }
                    }
                }
                .padding(.horizontal, MCSpacing.screenPadding)
                .padding(.vertical, MCSpacing.md)
            }
            .background(MCColors.backgroundLight)
            .navigationTitle(dateString(date))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                        .foregroundStyle(MCColors.primaryTeal)
                }
            }
        }
    }

    private func dateString(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }
}
