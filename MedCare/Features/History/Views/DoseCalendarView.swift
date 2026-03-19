import SwiftUI
import SwiftData

/// Monthly calendar view showing dose adherence per day
struct DoseCalendarView: View {
    let profile: UserProfile

    @State private var displayedMonth: Date = Date()
    @State private var selectedDay: Date?
    @State private var showDayDetail = false

    private let calendar = Calendar.current
    private let weekdaySymbols = ["S", "M", "T", "W", "T", "F", "S"]
    private let columns = Array(repeating: GridItem(.flexible(), spacing: MCSpacing.xxs), count: 7)

    var body: some View {
        VStack(spacing: MCSpacing.md) {
            // Month header with navigation
            monthHeader

            // Weekday labels
            weekdayHeader

            // Day grid
            dayGrid

            // Legend
            legendRow
        }
        .padding(MCSpacing.cardPadding)
        .background(MCColors.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: MCSpacing.cornerRadius))
        .sheet(isPresented: $showDayDetail) {
            if let selectedDay {
                DayDoseDetailSheet(profile: profile, date: selectedDay)
                    .presentationDetents([.medium])
                    .presentationDragIndicator(.visible)
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
    }

    // MARK: - Day Grid

    private var dayGrid: some View {
        let days = daysInMonth()
        return LazyVGrid(columns: columns, spacing: MCSpacing.xxs) {
            ForEach(days, id: \.self) { date in
                if let date {
                    dayCell(date)
                } else {
                    Color.clear
                        .frame(height: 40)
                }
            }
        }
    }

    // MARK: - Day Cell

    private func dayCell(_ date: Date) -> some View {
        let adherence = adherenceForDay(date)
        let isToday = calendar.isDateInToday(date)
        let isFuture = date > Date()

        return Button {
            selectedDay = date
            showDayDetail = true
        } label: {
            Text("\(calendar.component(.day, from: date))")
                .font(isToday ? MCTypography.captionBold : MCTypography.caption)
                .foregroundStyle(cellTextColor(adherence: adherence, isFuture: isFuture))
                .frame(maxWidth: .infinity)
                .frame(height: 40)
                .background(cellBackgroundColor(adherence: adherence, isFuture: isFuture))
                .clipShape(RoundedRectangle(cornerRadius: 6))
                .overlay(
                    RoundedRectangle(cornerRadius: 6)
                        .stroke(isToday ? MCColors.primaryTeal : Color.clear, lineWidth: 2)
                )
        }
        .buttonStyle(.plain)
        .disabled(isFuture)
    }

    // MARK: - Legend

    private var legendRow: some View {
        HStack(spacing: MCSpacing.md) {
            legendDot(color: MCColors.success, label: "100%")
            legendDot(color: MCColors.warning, label: "50-99%")
            legendDot(color: MCColors.error, label: "<50%")
            legendDot(color: MCColors.divider, label: "No data")
        }
        .frame(maxWidth: .infinity)
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

    // MARK: - Helpers

    private func monthYearString(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        return formatter.string(from: date)
    }

    /// Returns array of optional Dates representing the calendar grid (nil = empty leading cells)
    private func daysInMonth() -> [Date?] {
        guard let range = calendar.range(of: .day, in: .month, for: displayedMonth),
              let firstOfMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: displayedMonth))
        else { return [] }

        let firstWeekday = calendar.component(.weekday, from: firstOfMonth) // 1=Sun
        let leadingBlanks = firstWeekday - 1

        var days: [Date?] = Array(repeating: nil, count: leadingBlanks)

        for day in range {
            if let date = calendar.date(byAdding: .day, value: day - 1, to: firstOfMonth) {
                days.append(date)
            }
        }

        return days
    }

    /// Calculate adherence percentage for a given day
    private func adherenceForDay(_ date: Date) -> Double? {
        let startOfDay = calendar.startOfDay(for: date)
        guard let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay) else { return nil }

        let doses = profile.episodes
            .flatMap { $0.medicines }
            .flatMap { $0.doseLogs }
            .filter { $0.scheduledTime >= startOfDay && $0.scheduledTime < endOfDay }

        guard !doses.isEmpty else { return nil }

        let taken = doses.filter { $0.status == .taken }.count
        return Double(taken) / Double(doses.count)
    }

    private func cellBackgroundColor(adherence: Double?, isFuture: Bool) -> Color {
        if isFuture { return MCColors.backgroundLight }
        guard let adherence else { return MCColors.backgroundLight }
        if adherence >= 1.0 { return MCColors.success.opacity(0.2) }
        if adherence >= 0.5 { return MCColors.warning.opacity(0.2) }
        return MCColors.error.opacity(0.2)
    }

    private func cellTextColor(adherence: Double?, isFuture: Bool) -> Color {
        if isFuture { return MCColors.textTertiary }
        guard let adherence else { return MCColors.textSecondary }
        if adherence >= 1.0 { return Color(hex: "1B7A3D") }
        if adherence >= 0.5 { return Color(hex: "9A6600") }
        return Color(hex: "CC2D25") }
}

// MARK: - Day Dose Detail Sheet

struct DayDoseDetailSheet: View {
    let profile: UserProfile
    let date: Date

    @Environment(\.dismiss) private var dismiss

    private var dayDoses: [DoseLog] {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: date)
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!

        return profile.episodes
            .flatMap { $0.medicines }
            .flatMap { $0.doseLogs }
            .filter { $0.scheduledTime >= startOfDay && $0.scheduledTime < endOfDay }
            .sorted { $0.scheduledTime < $1.scheduledTime }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: MCSpacing.sm) {
                    if dayDoses.isEmpty {
                        MCEmptyState(
                            icon: "calendar.badge.minus",
                            title: "No Doses",
                            message: "No doses were scheduled for this day."
                        )
                    } else {
                        ForEach(dayDoses) { dose in
                            doseRow(dose)
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

    private func doseRow(_ dose: DoseLog) -> some View {
        MCCard {
            HStack(spacing: MCSpacing.sm) {
                Image(systemName: dose.medicine?.doseForm.icon ?? "pills")
                    .font(.system(size: 16))
                    .foregroundStyle(MCColors.primaryTeal)
                    .frame(width: 32, height: 32)
                    .background(MCColors.primaryTeal.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: 6))

                VStack(alignment: .leading, spacing: 2) {
                    Text(dose.medicine?.brandName ?? "Medicine")
                        .font(MCTypography.bodyMedium)
                        .foregroundStyle(MCColors.textPrimary)
                    Text(dose.medicine?.dosage ?? "")
                        .font(MCTypography.caption)
                        .foregroundStyle(MCColors.textSecondary)
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 2) {
                    Text(dose.scheduledTime, style: .time)
                        .font(MCTypography.subheadline)
                        .foregroundStyle(MCColors.textPrimary)
                    MCBadge(dose.status.rawValue, color: Color(hex: dose.status.color))
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
