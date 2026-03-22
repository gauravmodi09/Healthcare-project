import SwiftUI
import SwiftData

struct RemindersView: View {
    @Environment(DataService.self) private var dataService
    @Environment(LiveActivityService.self) private var liveActivityService
    @Query private var users: [User]
    @Query(sort: \CustomReminder.reminderTime) private var customReminders: [CustomReminder]
    @State private var selectedDate = Date()
    @State private var showDatePicker = false
    @State private var confirmedMedicineName: String?
    @State private var showAddReminder = false
    @State private var showSnoozeOptions = false
    @State private var pendingSnoozeDose: DoseLog?

    private var activeProfile: UserProfile? { users.first?.activeProfile }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Date selector
                dateSelector

                ScrollView {
                    // MARK: - My Reminders Section
                    if !activeCustomReminders.isEmpty {
                        customRemindersSection
                    }

                    if let profile = activeProfile {
                        let doses = dosesForDate(profile: profile)

                        if doses.isEmpty && activeCustomReminders.isEmpty {
                            emptyState
                        } else if !doses.isEmpty {
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

                                        // Pending doses: swipeable cards in a List for gesture support
                                        let pendingDoses = group.doses.filter { $0.status == .pending }
                                        let actionedDoses = group.doses.filter { $0.status != .pending }

                                        if !pendingDoses.isEmpty {
                                            List {
                                                ForEach(pendingDoses) { dose in
                                                    SwipeableMedicationCard(
                                                        medicineName: dose.medicine?.brandName ?? "Medicine",
                                                        dosage: dose.medicine?.dosage ?? "",
                                                        scheduledTime: dose.scheduledTime,
                                                        doseFormIcon: dose.medicine?.doseForm.icon ?? "pills",
                                                        mealTiming: dose.medicine.flatMap { $0.mealTiming != .noPreference ? $0.mealTiming.shortLabel : nil },
                                                        status: dose.status.rawValue,
                                                        statusColor: Color(hex: dose.status.color),
                                                        onTake: {
                                                            handleDoseAction(dose, status: .taken)
                                                        },
                                                        onSkip: {
                                                            handleDoseAction(dose, status: .skipped)
                                                        },
                                                        onSnooze: {
                                                            pendingSnoozeDose = dose
                                                            showSnoozeOptions = true
                                                        }
                                                    )
                                                    .listRowInsets(EdgeInsets(top: 4, leading: MCSpacing.screenPadding, bottom: 4, trailing: MCSpacing.screenPadding))
                                                    .listRowSeparator(.hidden)
                                                    .listRowBackground(Color.clear)
                                                }
                                            }
                                            .listStyle(.plain)
                                            .scrollDisabled(true)
                                            .frame(height: CGFloat(pendingDoses.count) * 88)
                                        }

                                        // Already actioned doses: standard card
                                        ForEach(actionedDoses) { dose in
                                            DoseActionCard(doseLog: dose) { status in
                                                handleDoseAction(dose, status: status)
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
            .refreshable {
                // Re-evaluate dose data for current date
                try? await Task.sleep(for: .milliseconds(300))
            }
            .background(MCColors.backgroundLight)
            .dynamicTypeSize(.xSmall ... .accessibility3)
            .navigationTitle("Reminders")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showAddReminder = true
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .font(.title3)
                            .foregroundStyle(MCColors.primaryTeal)
                    }
                    .accessibilityLabel("Add custom reminder")
                }
            }
            .sheet(isPresented: $showAddReminder) {
                AddReminderView()
            }
            .overlay {
                if let name = confirmedMedicineName {
                    DoseConfirmationOverlay(medicineName: name) {
                        confirmedMedicineName = nil
                    }
                }
            }
            .confirmationDialog("Snooze Duration", isPresented: $showSnoozeOptions, titleVisibility: .visible) {
                Button("5 minutes") { handleSnooze(minutes: 5) }
                Button("10 minutes") { handleSnooze(minutes: 10) }
                Button("15 minutes") { handleSnooze(minutes: 15) }
                Button("30 minutes") { handleSnooze(minutes: 30) }
                Button("1 hour") { handleSnooze(minutes: 60) }
                Button("Cancel", role: .cancel) { pendingSnoozeDose = nil }
            }
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
                        let date = Calendar.current.date(byAdding: .day, value: offset, to: Date()) ?? Date()
                        Button {
                            withAnimation(.spring(response: 0.35, dampingFraction: 0.7)) {
                                selectedDate = date
                            }
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
                            .background {
                                if isSelected(date) {
                                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                                        .fill(LinearGradient(
                                            colors: [MCColors.primaryTeal, MCColors.primaryTealDark],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        ))
                                } else {
                                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                                        .fill(.ultraThinMaterial)
                                }
                            }
                            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                            .shadow(color: .black.opacity(isSelected(date) ? 0.12 : 0.03), radius: isSelected(date) ? 6 : 3, y: isSelected(date) ? 3 : 1)
                            .scaleEffect(isSelected(date) ? 1.08 : 1.0)
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
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: MCSpacing.cornerRadius, style: .continuous))
        .shadow(color: .black.opacity(0.04), radius: 3, y: 1)
        .shadow(color: .black.opacity(0.06), radius: 8, y: 4)
        .padding(.horizontal, MCSpacing.screenPadding)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Today's summary: \(taken) taken, \(skipped) skipped, \(pending) pending")
    }

    private func summaryItem(count: Int, label: String, color: Color, icon: String) -> some View {
        VStack(spacing: MCSpacing.xxs) {
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.footnote)
                Text("\(count)")
                    .font(MCTypography.title2)
                    .contentTransition(.numericText())
                    .animation(.spring(response: 0.4, dampingFraction: 0.8), value: count)
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
                .font(.system(size: 48).weight(.light))
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

    // MARK: - Dose Action Handler

    private func handleDoseAction(_ dose: DoseLog, status: DoseStatus) {
        // Haptic feedback per action type
        switch status {
        case .taken:
            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        case .skipped:
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
        case .snoozed:
            UIImpactFeedbackGenerator(style: .soft).impactOccurred()
        default:
            break
        }

        withAnimation {
            dataService.logDose(dose, status: status)
        }
        if status == .taken {
            confirmedMedicineName = dose.medicine?.brandName ?? "Medicine"
        }
        // Update Live Activity based on action
        Task {
            if status == .taken || status == .skipped {
                await liveActivityService.endActivity(doseLogId: dose.id)
            }
        }
    }

    private func handleSnooze(minutes: Int) {
        guard let dose = pendingSnoozeDose else { return }
        pendingSnoozeDose = nil

        UIImpactFeedbackGenerator(style: .soft).impactOccurred()
        withAnimation {
            dataService.logDose(dose, status: .snoozed)
        }

        Task {
            if let med = dose.medicine {
                await NotificationService.shared.scheduleSnooze(
                    medicineId: med.id,
                    medicineName: med.brandName,
                    dosage: med.dosage,
                    doseLogId: dose.id,
                    minutes: minutes
                )
            }
            let snoozedUntil = Date().addingTimeInterval(Double(minutes) * 60)
            await liveActivityService.updateActivity(
                doseLogId: dose.id,
                status: .snoozed,
                minutesRemaining: minutes,
                snoozedUntil: snoozedUntil
            )
        }
    }

    // MARK: - Helpers

    private func dosesForDate(profile: UserProfile) -> [DoseLog] {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: selectedDate)
        guard let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay) else { return [] }

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

    // MARK: - Custom Reminders

    private var activeCustomReminders: [CustomReminder] {
        customReminders.filter { !$0.isCompleted }
    }

    private var customRemindersSection: some View {
        VStack(alignment: .leading, spacing: MCSpacing.xs) {
            HStack {
                Image(systemName: "bell.badge.fill")
                    .foregroundStyle(MCColors.accentCoral)
                Text("My Reminders")
                    .font(MCTypography.headline)
                    .foregroundStyle(MCColors.textPrimary)

                Spacer()

                Text("\(activeCustomReminders.count)")
                    .font(MCTypography.captionBold)
                    .foregroundStyle(.white)
                    .padding(.horizontal, MCSpacing.xs)
                    .padding(.vertical, MCSpacing.xxs)
                    .background(MCColors.accentCoral)
                    .clipShape(Capsule())
            }
            .padding(.horizontal, MCSpacing.screenPadding)

            ForEach(activeCustomReminders) { reminder in
                customReminderCard(reminder)
                    .padding(.horizontal, MCSpacing.screenPadding)
            }
        }
        .padding(.vertical, MCSpacing.md)
    }

    private func customReminderCard(_ reminder: CustomReminder) -> some View {
        MCAccentCard(accent: MCColors.accentCoral) {
            HStack(spacing: MCSpacing.sm) {
                VStack(alignment: .leading, spacing: MCSpacing.xxs) {
                    Text(reminder.title)
                        .font(MCTypography.headline)
                        .foregroundStyle(MCColors.textPrimary)
                        .lineLimit(2)
                        .minimumScaleFactor(0.85)

                    HStack(spacing: MCSpacing.xs) {
                        Image(systemName: "clock")
                            .font(.caption2)
                        Text(reminder.reminderTime, style: .relative)
                            .font(MCTypography.caption)

                        if reminder.repeatOption != .never {
                            Text("·")
                            Image(systemName: reminder.repeatOption.icon)
                                .font(.caption2)
                            Text(reminder.repeatOption.rawValue)
                                .font(MCTypography.captionBold)
                        }
                    }
                    .foregroundStyle(MCColors.textSecondary)

                    if let notes = reminder.notes, !notes.isEmpty {
                        Text(notes)
                            .font(MCTypography.caption)
                            .foregroundStyle(MCColors.textTertiary)
                            .lineLimit(1)
                    }
                }

                Spacer()

                Button {
                    UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                    withAnimation {
                        completeReminder(reminder)
                    }
                } label: {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.title2)
                        .foregroundStyle(MCColors.success)
                }
                .accessibilityLabel("Mark \(reminder.title) as done")
                .buttonStyle(.mcBounce)
            }
        }
    }

    @MainActor
    private func completeReminder(_ reminder: CustomReminder) {
        reminder.isCompleted = true
        try? dataService.modelContainer.mainContext.save()
        NotificationService.shared.cancelCustomReminder(id: reminder.id)
    }
}
