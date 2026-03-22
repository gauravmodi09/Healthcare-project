import SwiftUI
import SwiftData

/// Navigation wrapper to distinguish document UUIDs from episode UUIDs
struct DocumentNavID: Hashable {
    let id: UUID
}

struct EpisodeDetailView: View {
    let episodeId: UUID
    @Environment(DataService.self) private var dataService
    @Environment(LiveActivityService.self) private var liveActivityService
    @Query private var episodes: [Episode]
    @State private var selectedTab: EpisodeTab = .plan
    @State private var showQuickAddMedicine = false
    @State private var showSymptomLog = false
    @State private var isLoading = true
    @State private var showSnoozeOptions = false
    @State private var pendingSnoozeDose: DoseLog?

    private var episode: Episode? {
        episodes.first { $0.id == episodeId }
    }

    enum EpisodeTab: String, CaseIterable {
        case plan = "Plan"
        case reminders = "Reminders"
        case symptoms = "Symptoms"
        case files = "Files"
    }

    var body: some View {
        if let episode {
            VStack(spacing: 0) {
                if isLoading {
                    VStack(spacing: MCSpacing.md) {
                        SkeletonCardView()
                        SkeletonCardView()
                        SkeletonCardView()
                    }
                    .padding(.horizontal, MCSpacing.screenPadding)
                    .padding(.top, MCSpacing.lg)
                } else {
                    // Episode header
                    episodeHeader(episode)

                    // Tab picker
                    Picker("Tab", selection: $selectedTab) {
                        ForEach(EpisodeTab.allCases, id: \.self) { tab in
                            Text(tab.rawValue).tag(tab)
                        }
                    }
                    .pickerStyle(.segmented)
                    .padding(.horizontal, MCSpacing.screenPadding)
                    .padding(.vertical, MCSpacing.sm)

                    // Tab content
                    ScrollView {
                        switch selectedTab {
                        case .plan:
                            planTab(episode)
                        case .reminders:
                            remindersTab(episode)
                        case .symptoms:
                            symptomsTab(episode)
                        case .files:
                            EpisodeFilesTabView(episode: episode)
                        }
                    }
                }
            }
            .background(MCColors.backgroundLight)
            .navigationTitle(episode.title)
            .navigationBarTitleDisplayMode(.inline)
            .task {
                try? await Task.sleep(nanoseconds: 300_000_000)
                withAnimation(.easeOut(duration: 0.3)) {
                    isLoading = false
                }
            }
            .navigationDestination(for: DocumentNavID.self) { nav in
                DocumentDetailView(documentId: nav.id)
            }
            .sheet(isPresented: $showQuickAddMedicine) {
                QuickAddMedicineView(episode: episode)
                    .environment(dataService)
            }
            .sheet(isPresented: $showSymptomLog) {
                NavigationStack {
                    SymptomLogView(episodeId: episode.id)
                        .environment(dataService)
                }
            }
            .confirmationDialog("Snooze Duration", isPresented: $showSnoozeOptions, titleVisibility: .visible) {
                Button("5 minutes") { handleEpisodeSnooze(minutes: 5) }
                Button("10 minutes") { handleEpisodeSnooze(minutes: 10) }
                Button("15 minutes") { handleEpisodeSnooze(minutes: 15) }
                Button("30 minutes") { handleEpisodeSnooze(minutes: 30) }
                Button("1 hour") { handleEpisodeSnooze(minutes: 60) }
                Button("Cancel", role: .cancel) { pendingSnoozeDose = nil }
            }
        } else {
            ContentUnavailableView("Episode not found", systemImage: "doc.questionmark")
        }
    }

    // MARK: - Header

    private func episodeHeader(_ episode: Episode) -> some View {
        VStack(spacing: MCSpacing.sm) {
            HStack {
                VStack(alignment: .leading, spacing: MCSpacing.xxs) {
                    HStack(spacing: MCSpacing.xs) {
                        Image(systemName: episode.episodeType.icon)
                            .foregroundStyle(Color(hex: episode.episodeType.color))
                        MCBadge(episode.episodeType.rawValue, color: Color(hex: episode.episodeType.color))
                        MCBadge(episode.status.displayName, color: MCColors.success)
                    }

                    if let doctor = episode.doctorName {
                        Label(doctor, systemImage: "stethoscope")
                            .font(MCTypography.footnote)
                            .foregroundStyle(MCColors.textSecondary)
                            .lineLimit(2)
                            .minimumScaleFactor(0.85)
                    }

                    if let diagnosis = episode.diagnosis {
                        Label(diagnosis, systemImage: "heart.text.clipboard")
                            .font(MCTypography.footnote)
                            .foregroundStyle(MCColors.textSecondary)
                            .lineLimit(2)
                            .minimumScaleFactor(0.85)
                    }
                }

                Spacer()

                // Adherence ring
                let adherence = episode.adherencePercentage
                ZStack {
                    Circle()
                        .stroke(MCColors.backgroundLight, lineWidth: 6)
                    Circle()
                        .trim(from: 0, to: adherence)
                        .stroke(adherence > 0.7 ? MCColors.success : MCColors.warning, style: StrokeStyle(lineWidth: 6, lineCap: .round))
                        .rotationEffect(.degrees(-90))
                    VStack(spacing: 0) {
                        Text("\(Int(adherence * 100))%")
                            .font(MCTypography.captionBold)
                        Text("adherence")
                            .font(.system(size: 8))
                            .foregroundStyle(MCColors.textTertiary)
                    }
                }
                .frame(width: 60, height: 60)
            }
        }
        .padding(MCSpacing.screenPadding)
        .background(MCColors.cardBackground)
    }

    // MARK: - Plan Tab

    private func planTab(_ episode: Episode) -> some View {
        VStack(alignment: .leading, spacing: MCSpacing.lg) {
            // Medicines
            VStack(alignment: .leading, spacing: MCSpacing.sm) {
                HStack {
                    Text("Medicines (\(episode.activeMedicines.count))")
                        .font(MCTypography.headline)
                    Spacer()
                    Button {
                        showQuickAddMedicine = true
                    } label: {
                        Image(systemName: "plus.circle")
                            .foregroundStyle(MCColors.primaryTeal)
                    }
                }

                if episode.activeMedicines.isEmpty {
                    MCEmptyState.medications {
                        showQuickAddMedicine = true
                    }
                } else {
                    ForEach(episode.activeMedicines) { medicine in
                        MedicineCard(medicine: medicine)
                    }

                    // Reorder All button
                    if episode.activeMedicines.count > 1 {
                        Button {
                            let names = episode.activeMedicines.map { $0.brandName }.joined(separator: " ")
                            let query = names.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? names
                            if let url = URL(string: "https://www.1mg.com/search/all?name=\(query)") {
                                UIApplication.shared.open(url)
                            }
                        } label: {
                            HStack(spacing: 6) {
                                Image(systemName: "cart.fill")
                                Text("Reorder All on 1mg")
                            }
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(MCColors.primaryTeal)
                            .frame(maxWidth: .infinity)
                            .frame(height: 40)
                            .background(MCColors.primaryTeal.opacity(0.1))
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                        }
                    }
                }
            }

            // Tasks
            if !episode.tasks.isEmpty {
                VStack(alignment: .leading, spacing: MCSpacing.sm) {
                    Text("Care Tasks")
                        .font(MCTypography.headline)

                    ForEach(episode.tasks) { task in
                        TaskRowView(task: task) {
                            dataService.toggleTask(task)
                        }
                    }
                }
            }
        }
        .padding(.horizontal, MCSpacing.screenPadding)
        .padding(.vertical, MCSpacing.md)
    }

    // MARK: - Reminders Tab

    private func remindersTab(_ episode: Episode) -> some View {
        VStack(alignment: .leading, spacing: MCSpacing.md) {
            let allDoses = episode.medicines
                .flatMap { $0.doseLogs }
                .sorted { $0.scheduledTime < $1.scheduledTime }

            let todayDoses = allDoses.filter {
                Calendar.current.isDateInToday($0.scheduledTime)
            }

            Text("Today's Doses")
                .font(MCTypography.headline)
                .padding(.horizontal, MCSpacing.screenPadding)

            if todayDoses.isEmpty {
                MCCard {
                    Text("No doses scheduled for today")
                        .font(MCTypography.body)
                        .foregroundStyle(MCColors.textSecondary)
                        .frame(maxWidth: .infinity)
                }
                .padding(.horizontal, MCSpacing.screenPadding)
            } else {
                ForEach(todayDoses) { dose in
                    DoseActionCard(doseLog: dose) { status in
                        // Haptic feedback per action type
                        switch status {
                        case .taken:
                            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                        case .skipped:
                            UIImpactFeedbackGenerator(style: .light).impactOccurred()
                        case .snoozed:
                            // Show snooze duration picker instead of hardcoded 15 min
                            pendingSnoozeDose = dose
                            showSnoozeOptions = true
                            return
                        default:
                            break
                        }
                        dataService.logDose(dose, status: status)
                        Task {
                            if status == .taken || status == .skipped {
                                await liveActivityService.endActivity(doseLogId: dose.id)
                            }
                        }
                    }
                    .padding(.horizontal, MCSpacing.screenPadding)
                }
            }
        }
        .padding(.vertical, MCSpacing.md)
    }

    // MARK: - Snooze Handler

    private func handleEpisodeSnooze(minutes: Int) {
        guard let dose = pendingSnoozeDose else { return }
        pendingSnoozeDose = nil

        UIImpactFeedbackGenerator(style: .soft).impactOccurred()
        dataService.logDose(dose, status: .snoozed)

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

    // MARK: - Symptoms Tab

    private func symptomsTab(_ episode: Episode) -> some View {
        VStack(alignment: .leading, spacing: MCSpacing.md) {
            HStack {
                Text("Symptom Log")
                    .font(MCTypography.headline)
                Spacer()
                Button {
                    showSymptomLog = true
                } label: {
                    Label("Log Today", systemImage: "plus.circle")
                        .font(MCTypography.subheadline)
                        .foregroundStyle(MCColors.primaryTeal)
                }
            }
            .padding(.horizontal, MCSpacing.screenPadding)

            if episode.symptomLogs.isEmpty {
                MCCard {
                    VStack(spacing: MCSpacing.sm) {
                        Image(systemName: "chart.line.text.clipboard")
                            .font(.system(size: 36))
                            .foregroundStyle(MCColors.textTertiary)
                        Text("No symptom logs yet")
                            .font(MCTypography.body)
                            .foregroundStyle(MCColors.textSecondary)
                        Text("Track how you feel daily to monitor recovery")
                            .font(MCTypography.caption)
                            .foregroundStyle(MCColors.textTertiary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, MCSpacing.lg)
                }
                .padding(.horizontal, MCSpacing.screenPadding)
            } else {
                ForEach(episode.symptomLogs.sorted(by: { $0.date > $1.date })) { log in
                    SymptomLogCard(log: log)
                        .padding(.horizontal, MCSpacing.screenPadding)
                }
            }
        }
        .padding(.vertical, MCSpacing.md)
    }
}

// MARK: - Subviews

struct MedicineCard: View {
    let medicine: Medicine
    @State private var showEducation = false

    var body: some View {
        MCCard {
            VStack(alignment: .leading, spacing: MCSpacing.xs) {
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(medicine.brandName)
                            .font(MCTypography.bodyMedium)
                            .foregroundStyle(MCColors.textPrimary)
                            .lineLimit(2)
                            .minimumScaleFactor(0.8)
                        if let generic = medicine.genericName {
                            Text(generic)
                                .font(MCTypography.caption)
                                .foregroundStyle(MCColors.primaryTeal)
                        }
                    }

                    Spacer()

                    if medicine.source == .aiExtracted {
                        MCConfidenceBadge(score: medicine.confidenceScore)
                    }
                }

                Divider()

                HStack(spacing: MCSpacing.md) {
                    Label(medicine.dosage, systemImage: "pills")
                    Label(medicine.frequency.rawValue, systemImage: "clock")
                }
                .font(MCTypography.caption)
                .foregroundStyle(MCColors.textSecondary)

                HStack(spacing: MCSpacing.xs) {
                    ForEach(medicine.timing.sorted(), id: \.self) { time in
                        HStack(spacing: 2) {
                            Image(systemName: time.icon)
                            Text(time.displayName)
                        }
                        .font(MCTypography.caption)
                        .foregroundStyle(MCColors.primaryTeal)
                        .padding(.horizontal, MCSpacing.xs)
                        .padding(.vertical, 2)
                        .background(MCColors.primaryTeal.opacity(0.1))
                        .clipShape(Capsule())
                    }
                }

                // Jan Aushadhi savings badge
                if let jaPrice = IndianDrugDatabase.shared.findJanAushadhiPrice(for: medicine) {
                    HStack(spacing: MCSpacing.xs) {
                        Image(systemName: "indianrupeesign.circle.fill")
                            .foregroundStyle(MCColors.success)
                        Text("Save \(jaPrice.savingsPercent)% with generic")
                            .font(MCTypography.caption)
                            .foregroundStyle(MCColors.success)
                        Spacer()
                        Text("Jan Aushadhi: \u{20B9}\(Int(jaPrice.janAushadhiPrice))")
                            .font(MCTypography.caption)
                            .fontWeight(.medium)
                            .foregroundStyle(MCColors.success)
                    }
                    .padding(MCSpacing.xs)
                    .background(MCColors.success.opacity(0.08))
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                }

                if let instructions = medicine.instructions {
                    HStack(spacing: MCSpacing.xxs) {
                        Image(systemName: "info.circle")
                        Text(instructions)
                    }
                    .font(MCTypography.caption)
                    .foregroundStyle(MCColors.info)
                }

                // Action buttons row
                HStack(spacing: MCSpacing.sm) {
                    // Learn More
                    Button {
                        showEducation = true
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "book")
                                .font(.system(size: 11))
                            Text("Learn More")
                                .font(.system(size: 12, weight: .medium))
                        }
                        .foregroundStyle(MCColors.info)
                    }

                    Spacer()

                    // Reorder on 1mg
                    Button {
                        let query = medicine.brandName.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? medicine.brandName
                        if let url = URL(string: "https://www.1mg.com/search/all?name=\(query)") {
                            UIApplication.shared.open(url)
                        }
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "cart")
                                .font(.system(size: 11))
                            Text("Buy Again on 1mg")
                                .font(.system(size: 12, weight: .medium))
                        }
                        .foregroundStyle(MCColors.primaryTeal)
                    }
                }
            }
        }
        .sheet(isPresented: $showEducation) {
            MedicineEducationSheet(medicineName: medicine.brandName)
                .presentationDetents([.large])
                .presentationDragIndicator(.visible)
        }
    }
}

// MARK: - Medicine Education Sheet

struct MedicineEducationSheet: View {
    let medicineName: String
    @Environment(\.dismiss) private var dismiss

    private let drugQA = DrugQAService()
    private let drugDB = IndianDrugDatabase.shared

    private var drugEntry: DrugEntry? {
        drugDB.searchMedicines(query: medicineName).first
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: MCSpacing.lg) {
                    if let entry = drugEntry {
                        // Header
                        VStack(alignment: .leading, spacing: MCSpacing.xs) {
                            Text(entry.brandName)
                                .font(MCTypography.title)
                                .foregroundStyle(MCColors.textPrimary)
                            Text(entry.genericName)
                                .font(MCTypography.subheadline)
                                .foregroundStyle(MCColors.primaryTeal)
                            Text(entry.saltComposition)
                                .font(MCTypography.caption)
                                .foregroundStyle(MCColors.textSecondary)
                        }

                        // What it does
                        educationSection(
                            icon: "pills.circle.fill",
                            title: "What This Medicine Does",
                            color: MCColors.primaryTeal
                        ) {
                            Text(entry.description.isEmpty ? "Used for treatment as prescribed by your doctor." : entry.description)
                                .font(MCTypography.body)
                                .foregroundStyle(MCColors.textSecondary)

                            if !entry.commonDosages.isEmpty {
                                VStack(alignment: .leading, spacing: MCSpacing.xxs) {
                                    Text("Common dosages:")
                                        .font(MCTypography.captionBold)
                                        .foregroundStyle(MCColors.textPrimary)
                                    ForEach(entry.commonDosages, id: \.self) { dosage in
                                        HStack(spacing: MCSpacing.xs) {
                                            Circle()
                                                .fill(MCColors.primaryTeal)
                                                .frame(width: 4, height: 4)
                                            Text(dosage)
                                                .font(MCTypography.caption)
                                                .foregroundStyle(MCColors.textSecondary)
                                        }
                                    }
                                }
                            }
                        }

                        // Side effects
                        educationSection(
                            icon: "exclamationmark.triangle.fill",
                            title: "Common Side Effects",
                            color: MCColors.warning
                        ) {
                            if entry.commonSideEffects.isEmpty {
                                Text("No common side effects listed. Consult your doctor if you notice anything unusual.")
                                    .font(MCTypography.body)
                                    .foregroundStyle(MCColors.textSecondary)
                            } else {
                                ForEach(entry.commonSideEffects, id: \.self) { effect in
                                    HStack(spacing: MCSpacing.xs) {
                                        Circle()
                                            .fill(MCColors.warning)
                                            .frame(width: 4, height: 4)
                                        Text(effect)
                                            .font(MCTypography.body)
                                            .foregroundStyle(MCColors.textSecondary)
                                    }
                                }
                            }
                        }

                        // How to take
                        educationSection(
                            icon: "clock.fill",
                            title: "How to Take It Properly",
                            color: MCColors.success
                        ) {
                            VStack(alignment: .leading, spacing: MCSpacing.xs) {
                                infoRow(label: "Form", value: entry.typicalDoseForm)

                                if !entry.storageInstructions.isEmpty {
                                    infoRow(label: "Storage", value: entry.storageInstructions)
                                }

                                if entry.isScheduleH {
                                    HStack(spacing: MCSpacing.xs) {
                                        Image(systemName: "lock.fill")
                                            .foregroundStyle(MCColors.error)
                                            .font(.system(size: 12))
                                        Text("Schedule H drug -- prescription required")
                                            .font(MCTypography.caption)
                                            .foregroundStyle(MCColors.error)
                                    }
                                    .padding(MCSpacing.xs)
                                    .background(MCColors.error.opacity(0.08))
                                    .clipShape(RoundedRectangle(cornerRadius: 6))
                                }
                            }
                        }

                        // Food interactions
                        educationSection(
                            icon: "fork.knife",
                            title: "Interactions to Watch For",
                            color: MCColors.accentCoral
                        ) {
                            if entry.foodInteractions.isEmpty {
                                Text("No specific food or drug interactions listed. Always inform your doctor about all medicines you take.")
                                    .font(MCTypography.body)
                                    .foregroundStyle(MCColors.textSecondary)
                            } else {
                                ForEach(entry.foodInteractions, id: \.self) { interaction in
                                    HStack(alignment: .top, spacing: MCSpacing.xs) {
                                        Image(systemName: "exclamationmark.circle")
                                            .foregroundStyle(MCColors.accentCoral)
                                            .font(.system(size: 12))
                                            .padding(.top, 2)
                                        Text(interaction)
                                            .font(MCTypography.body)
                                            .foregroundStyle(MCColors.textSecondary)
                                    }
                                }
                            }
                        }

                        // Disclaimer
                        Text("This information is for educational purposes only. Always follow your doctor's instructions and consult a healthcare professional for medical advice.")
                            .font(MCTypography.caption)
                            .foregroundStyle(MCColors.textTertiary)
                            .padding(MCSpacing.sm)
                            .background(MCColors.backgroundLight)
                            .clipShape(RoundedRectangle(cornerRadius: MCSpacing.cornerRadiusSmall))

                    } else {
                        MCEmptyState(
                            icon: "book.closed",
                            title: "Info Not Available",
                            message: "Education details for \(medicineName) are not available in the database yet."
                        )
                    }
                }
                .padding(.horizontal, MCSpacing.screenPadding)
                .padding(.vertical, MCSpacing.md)
            }
            .background(MCColors.backgroundLight)
            .navigationTitle("About This Medicine")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                        .foregroundStyle(MCColors.primaryTeal)
                }
            }
        }
    }

    private func educationSection(icon: String, title: String, color: Color, @ViewBuilder content: () -> some View) -> some View {
        MCCard {
            VStack(alignment: .leading, spacing: MCSpacing.sm) {
                HStack(spacing: MCSpacing.xs) {
                    Image(systemName: icon)
                        .foregroundStyle(color)
                        .font(.system(size: 16))
                    Text(title)
                        .font(MCTypography.headline)
                        .foregroundStyle(MCColors.textPrimary)
                }

                content()
            }
        }
    }

    private func infoRow(label: String, value: String) -> some View {
        HStack(alignment: .top, spacing: MCSpacing.xs) {
            Text(label + ":")
                .font(MCTypography.captionBold)
                .foregroundStyle(MCColors.textPrimary)
                .frame(width: 70, alignment: .leading)
            Text(value)
                .font(MCTypography.body)
                .foregroundStyle(MCColors.textSecondary)
        }
    }
}

struct TaskRowView: View {
    let task: CareTask
    let onToggle: () -> Void

    var body: some View {
        MCCard {
            HStack(spacing: MCSpacing.sm) {
                Button(action: onToggle) {
                    Image(systemName: task.isCompleted ? "checkmark.circle.fill" : "circle")
                        .font(.system(size: 22))
                        .foregroundStyle(task.isCompleted ? MCColors.success : MCColors.textTertiary)
                }

                Image(systemName: task.taskType.icon)
                    .foregroundStyle(MCColors.primaryTeal)

                VStack(alignment: .leading, spacing: 2) {
                    Text(task.title)
                        .font(MCTypography.body)
                        .foregroundStyle(task.isCompleted ? MCColors.textTertiary : MCColors.textPrimary)
                        .strikethrough(task.isCompleted)

                    if let due = task.dueDate {
                        Text(due, style: .date)
                            .font(MCTypography.caption)
                            .foregroundStyle(MCColors.textSecondary)
                    }
                }

                Spacer()
            }
        }
    }
}

struct DoseActionCard: View {
    let doseLog: DoseLog
    let onAction: (DoseStatus) -> Void
    @Environment(DataService.self) private var dataService
    @Environment(\.elderModeService) private var elderMode
    @Environment(\.localization) private var l10n
    @State private var showDuplicateAlert = false
    @State private var duplicateTime: Date?

    var body: some View {
        MCCard {
            VStack(spacing: MCSpacing.sm) {
                HStack {
                    Image(systemName: doseLog.medicine?.doseForm.icon ?? "pills")
                        .font(.system(size: 16))
                        .foregroundStyle(MCColors.primaryTeal)
                        .frame(width: 32, height: 32)
                        .background(MCColors.primaryTeal.opacity(0.1))
                        .clipShape(RoundedRectangle(cornerRadius: 6))

                    VStack(alignment: .leading, spacing: 2) {
                        Text(doseLog.medicine?.brandName ?? "Medicine")
                            .font(MCTypography.bodyMedium)
                            .lineLimit(2)
                            .minimumScaleFactor(0.8)
                        if let generic = doseLog.medicine?.genericName {
                            Text(generic)
                                .font(MCTypography.caption)
                                .foregroundStyle(MCColors.primaryTeal)
                        }
                        HStack(spacing: 4) {
                            Text(doseLog.medicine?.dosage ?? "")
                                .font(MCTypography.caption)
                                .foregroundStyle(MCColors.textSecondary)
                            if let med = doseLog.medicine, med.mealTiming != .noPreference {
                                Text("·")
                                    .foregroundStyle(MCColors.textTertiary)
                                Text(med.mealTiming.shortLabel)
                                    .font(MCTypography.caption)
                                    .foregroundStyle(MCColors.warning)
                            }
                        }

                        // Regional dosage instruction for elder accessibility
                        if elderMode.isElderModeEnabled && elderMode.dosageLanguage != .english,
                           let med = doseLog.medicine {
                            let regionalLine = l10n.regionalInstructionLine(
                                mealTiming: med.mealTiming != .noPreference ? med.mealTiming.shortLabel : nil,
                                doseForm: med.doseForm.rawValue,
                                language: elderMode.dosageLanguage
                            )
                            if let translated = regionalLine {
                                Text(translated)
                                    .font(.system(size: 15, weight: .medium))
                                    .foregroundStyle(MCColors.primaryTeal.opacity(0.85))
                            }
                        }
                    }

                    Spacer()

                    Text(doseLog.scheduledTime, style: .time)
                        .font(MCTypography.subheadline)

                    MCBadge(doseLog.status.rawValue, color: Color(hex: doseLog.status.color))
                }

                if doseLog.status == .pending {
                    HStack(spacing: MCSpacing.xs) {
                        Button {
                            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                            let check = dataService.isDuplicateDose(for: doseLog)
                            if check.isDuplicate {
                                duplicateTime = check.lastTakenTime
                                showDuplicateAlert = true
                            } else {
                                onAction(.taken)
                            }
                        } label: {
                            HStack(spacing: MCSpacing.xxs) {
                                Image(systemName: "checkmark")
                                Text("Taken")
                            }
                            .font(MCTypography.subheadline)
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 36)
                            .background(MCColors.success)
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                        }
                        .accessibilityLabel("Mark \(doseLog.medicine?.brandName ?? "medicine") as taken")
                        .accessibilityHint("Double tap to confirm you took this dose")

                        Button {
                            UIImpactFeedbackGenerator(style: .light).impactOccurred()
                            onAction(.skipped)
                        } label: {
                            HStack(spacing: MCSpacing.xxs) {
                                Image(systemName: "forward")
                                Text("Skip")
                            }
                            .font(MCTypography.subheadline)
                            .foregroundStyle(MCColors.warning)
                            .frame(maxWidth: .infinity)
                            .frame(height: 36)
                            .background(MCColors.warning.opacity(0.1))
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                        }
                        .accessibilityLabel("Skip \(doseLog.medicine?.brandName ?? "medicine")")
                        .accessibilityHint("Double tap to skip this dose")

                        Button {
                            UIImpactFeedbackGenerator(style: .soft).impactOccurred()
                            onAction(.snoozed)
                        } label: {
                            HStack(spacing: MCSpacing.xxs) {
                                Image(systemName: "bell.slash")
                                Text("Snooze")
                            }
                            .font(MCTypography.subheadline)
                            .foregroundStyle(MCColors.info)
                            .frame(maxWidth: .infinity)
                            .frame(height: 36)
                            .background(MCColors.info.opacity(0.1))
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                        }
                        .accessibilityLabel("Snooze \(doseLog.medicine?.brandName ?? "medicine")")
                        .accessibilityHint("Double tap to choose a snooze duration")
                    }
                }
            }
        }
        .alert("Duplicate Dose Warning", isPresented: $showDuplicateAlert) {
            Button("Take Anyway", role: .destructive) {
                onAction(.taken)
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            if let time = duplicateTime {
                Text("You already took \(doseLog.medicine?.brandName ?? "this medicine") at \(time.formatted(date: .omitted, time: .shortened)). Taking another dose this soon could be harmful.")
            } else {
                Text("You may have already taken this dose recently. Are you sure?")
            }
        }
    }
}

struct SymptomLogCard: View {
    let log: SymptomLog

    var body: some View {
        MCCard {
            VStack(alignment: .leading, spacing: MCSpacing.xs) {
                HStack {
                    Text(log.overallFeeling.emoji)
                        .font(.system(size: 28))
                    VStack(alignment: .leading) {
                        Text(log.overallFeeling.label)
                            .font(MCTypography.bodyMedium)
                        Text(log.date, style: .date)
                            .font(MCTypography.caption)
                            .foregroundStyle(MCColors.textSecondary)
                    }
                    Spacer()
                }

                if !log.symptoms.isEmpty {
                    FlowLayout(spacing: MCSpacing.xxs) {
                        ForEach(log.symptoms) { symptom in
                            HStack(spacing: 2) {
                                Circle()
                                    .fill(Color(hex: symptom.severity.color))
                                    .frame(width: 6, height: 6)
                                Text(symptom.name)
                                    .font(MCTypography.caption)
                            }
                            .padding(.horizontal, MCSpacing.xs)
                            .padding(.vertical, 2)
                            .background(Color(hex: symptom.severity.color).opacity(0.1))
                            .clipShape(Capsule())
                        }
                    }
                }

                if let notes = log.notes, !notes.isEmpty {
                    Text(notes)
                        .font(MCTypography.footnote)
                        .foregroundStyle(MCColors.textSecondary)
                }
            }
        }
    }
}
