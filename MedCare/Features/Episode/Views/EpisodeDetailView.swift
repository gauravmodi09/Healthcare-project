import SwiftUI
import SwiftData

/// Navigation wrapper to distinguish document UUIDs from episode UUIDs
struct DocumentNavID: Hashable {
    let id: UUID
}

struct EpisodeDetailView: View {
    let episodeId: UUID
    @Environment(DataService.self) private var dataService
    @Query private var episodes: [Episode]
    @State private var selectedTab: EpisodeTab = .plan

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
                        // Add medicine
                    } label: {
                        Image(systemName: "plus.circle")
                            .foregroundStyle(MCColors.primaryTeal)
                    }
                }

                ForEach(episode.activeMedicines) { medicine in
                    MedicineCard(medicine: medicine)
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
                        dataService.logDose(dose, status: status)
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
                NavigationLink(value: AppRouter.HomeRoute.symptomLog(episodeId: episode.id)) {
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
                                .foregroundStyle(MCColors.textSecondary)
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

                if let instructions = medicine.instructions {
                    HStack(spacing: MCSpacing.xxs) {
                        Image(systemName: "info.circle")
                        Text(instructions)
                    }
                    .font(MCTypography.caption)
                    .foregroundStyle(MCColors.info)
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
                    }

                    Spacer()

                    Text(doseLog.scheduledTime, style: .time)
                        .font(MCTypography.subheadline)

                    MCBadge(doseLog.status.rawValue, color: Color(hex: doseLog.status.color))
                }

                if doseLog.status == .pending {
                    HStack(spacing: MCSpacing.xs) {
                        Button {
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

                        Button {
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

                        Button {
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
