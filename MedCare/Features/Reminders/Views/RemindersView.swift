import SwiftUI
import SwiftData

struct RemindersView: View {
    @Environment(DataService.self) private var dataService
    @Query private var users: [User]
    @State private var selectedDate = Date()
    @State private var showDatePicker = false

    private var activeProfile: UserProfile? { users.first?.activeProfile }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Date selector
                dateSelector

                ScrollView {
                    if let profile = activeProfile {
                        let doses = dosesForDate(profile: profile)

                        if doses.isEmpty {
                            emptyState
                        } else {
                            VStack(spacing: MCSpacing.md) {
                                // Summary stats
                                summaryBar(doses: doses)

                                // Time-grouped doses
                                ForEach(groupedDoses(doses), id: \.key) { group in
                                    VStack(alignment: .leading, spacing: MCSpacing.xs) {
                                        HStack {
                                            Image(systemName: group.icon)
                                                .foregroundStyle(MCColors.primaryTeal)
                                            Text(group.key)
                                                .font(MCTypography.headline)
                                                .foregroundStyle(MCColors.textPrimary)
                                        }
                                        .padding(.horizontal, MCSpacing.screenPadding)

                                        ForEach(group.doses) { dose in
                                            DoseActionCard(doseLog: dose) { status in
                                                withAnimation {
                                                    dataService.logDose(dose, status: status)
                                                }
                                                // Schedule notification if snoozed
                                                if status == .snoozed, let med = dose.medicine {
                                                    Task {
                                                        await NotificationService.shared.scheduleSnooze(
                                                            medicineId: med.id,
                                                            medicineName: med.brandName,
                                                            dosage: med.dosage,
                                                            doseLogId: dose.id
                                                        )
                                                    }
                                                }
                                            }
                                            .padding(.horizontal, MCSpacing.screenPadding)
                                        }
                                    }
                                }
                            }
                            .padding(.vertical, MCSpacing.md)
                        }
                    }
                }
            }
            .background(MCColors.backgroundLight)
            .navigationTitle("Reminders")
            .onAppear {
                Task {
                    let _ = await NotificationService.shared.requestPermission()
                }
            }
        }
    }

    // MARK: - Date Selector

    private var dateSelector: some View {
        VStack(spacing: MCSpacing.xs) {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: MCSpacing.sm) {
                    ForEach(-2..<5, id: \.self) { offset in
                        let date = Calendar.current.date(byAdding: .day, value: offset, to: Date())!
                        Button {
                            selectedDate = date
                        } label: {
                            VStack(spacing: MCSpacing.xxs) {
                                Text(dayName(date))
                                    .font(MCTypography.caption)
                                    .foregroundStyle(isSelected(date) ? .white : MCColors.textSecondary)

                                Text("\(Calendar.current.component(.day, from: date))")
                                    .font(MCTypography.headline)
                                    .foregroundStyle(isSelected(date) ? .white : MCColors.textPrimary)
                            }
                            .frame(width: 52, height: 64)
                            .background(isSelected(date) ? MCColors.primaryTeal : MCColors.cardBackground)
                            .clipShape(RoundedRectangle(cornerRadius: MCSpacing.cornerRadius))
                            .shadow(color: .black.opacity(isSelected(date) ? 0.1 : 0.03), radius: 4, y: 2)
                        }
                    }
                }
                .padding(.horizontal, MCSpacing.screenPadding)
            }
        }
        .padding(.vertical, MCSpacing.sm)
        .background(MCColors.cardBackground)
    }

    // MARK: - Summary Bar

    private func summaryBar(doses: [DoseLog]) -> some View {
        let taken = doses.filter { $0.status == .taken }.count
        let skipped = doses.filter { $0.status == .skipped }.count
        let pending = doses.filter { $0.status == .pending }.count

        return HStack(spacing: MCSpacing.md) {
            summaryItem(count: taken, label: "Taken", color: MCColors.success, icon: "checkmark.circle.fill")
            Divider().frame(height: 30)
            summaryItem(count: skipped, label: "Skipped", color: MCColors.warning, icon: "forward.fill")
            Divider().frame(height: 30)
            summaryItem(count: pending, label: "Pending", color: MCColors.textSecondary, icon: "clock")
        }
        .padding(MCSpacing.cardPadding)
        .background(MCColors.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: MCSpacing.cornerRadius))
        .padding(.horizontal, MCSpacing.screenPadding)
    }

    private func summaryItem(count: Int, label: String, color: Color, icon: String) -> some View {
        VStack(spacing: MCSpacing.xxs) {
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 14))
                Text("\(count)")
                    .font(MCTypography.title2)
            }
            .foregroundStyle(color)

            Text(label)
                .font(MCTypography.caption)
                .foregroundStyle(MCColors.textSecondary)
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: MCSpacing.md) {
            Spacer()
            Image(systemName: "bell.badge")
                .font(.system(size: 48))
                .foregroundStyle(MCColors.textTertiary)
            Text("No reminders for this day")
                .font(MCTypography.headline)
                .foregroundStyle(MCColors.textSecondary)
            Text("Upload a prescription to get started")
                .font(MCTypography.footnote)
                .foregroundStyle(MCColors.textTertiary)
            Spacer()
        }
        .frame(maxWidth: .infinity)
        .padding(.top, MCSpacing.xxl)
    }

    // MARK: - Helpers

    private func dosesForDate(profile: UserProfile) -> [DoseLog] {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: selectedDate)
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!

        return profile.episodes
            .flatMap { $0.medicines }
            .filter { $0.isActive }
            .flatMap { $0.doseLogs }
            .filter { $0.scheduledTime >= startOfDay && $0.scheduledTime < endOfDay }
            .sorted { $0.scheduledTime < $1.scheduledTime }
    }

    private struct DoseGroup {
        let key: String
        let icon: String
        let doses: [DoseLog]
    }

    private func groupedDoses(_ doses: [DoseLog]) -> [DoseGroup] {
        let grouped = Dictionary(grouping: doses) { dose -> String in
            let hour = Calendar.current.component(.hour, from: dose.scheduledTime)
            switch hour {
            case 5..<12: return "Morning"
            case 12..<17: return "Afternoon"
            case 17..<21: return "Evening"
            default: return "Night"
            }
        }

        let order = ["Morning", "Afternoon", "Evening", "Night"]

        return order.compactMap { key in
            guard let doses = grouped[key] else { return nil }
            let icon: String
            switch key {
            case "Morning": icon = "sunrise"
            case "Afternoon": icon = "sun.max"
            case "Evening": icon = "sunset"
            default: icon = "moon.stars"
            }
            return DoseGroup(key: key, icon: icon, doses: doses)
        }
    }

    private func dayName(_ date: Date) -> String {
        if Calendar.current.isDateInToday(date) { return "Today" }
        if Calendar.current.isDateInTomorrow(date) { return "Tmrw" }
        if Calendar.current.isDateInYesterday(date) { return "Ystrdy" }
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE"
        return formatter.string(from: date)
    }

    private func isSelected(_ date: Date) -> Bool {
        Calendar.current.isDate(date, inSameDayAs: selectedDate)
    }
}
