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
            .background(MCColors.backgroundLight)
            .navigationTitle(episode.title)
            .navigationBarTitleDisplayMode(.inline)
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
                    }

                    if let diagnosis = episode.diagnosis {
                        Label(diagnosis, systemImage: "heart.text.clipboard")
                            .font(MCTypography.footnote)
                            .foregroundStyle(MCColors.textSecondary)
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
                            UIImpactFeedbackGenerator(style: .soft).impactOccurred()
                        default:
                            break
                        }
                        dataService.logDose(dose, status: status)
                        // End or update Live Activity
                        Task {
                            if status == .taken || status == .skipped {
                                await liveActivityService.endActivity(doseLogId: dose.id)
                            } else if status == .snoozed {
                                let snoozedUntil = Date().addingTimeInterval(15 * 60)
                                await liveActivityService.updateActivity(
                                    doseLogId: dose.id,
                                    status: .snoozed,
                                    minutesRemaining: 15,
                                    snoozedUntil: snoozedUntil
                                )
                            }
                        }
                    }
                    .padding(.horizontal, MCSpacing.screenPadding)
                }
            }
        }
        .padding(.vertical, MCSpacing.md)
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

    var body: some View {
        MCCard {
            VStack(alignment: .leading, spacing: MCSpacing.xs) {
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(medicine.brandName)
                            .font(MCTypography.bodyMedium)
                            .foregroundStyle(MCColors.textPrimary)
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
                        .accessibilityHint("Double tap to snooze this reminder for 15 minutes")
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
