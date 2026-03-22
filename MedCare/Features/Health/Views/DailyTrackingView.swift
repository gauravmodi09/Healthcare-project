import SwiftUI
import SwiftData

// MARK: - Daily Tracking View

struct DailyTrackingView: View {
    let profile: UserProfile

    @Environment(\.modelContext) private var modelContext
    @State private var selectedDate = Date()
    @State private var waterService: WaterTrackingService
    @State private var moodService: MoodTrackingService
    @State private var journalService: HealthJournalService
    @State private var healthKitService = HealthKitService()
    @State private var latestVitals: HealthKitService.LatestVitals?
    @State private var isLoadingVitals = false

    // Mood & Energy inline editing
    @State private var selectedMood: Int = 0
    @State private var selectedEnergy: Double = 3
    @State private var hasSavedMood = false

    // Sleep inline editing
    @State private var sleepHours: Double = 7
    @State private var sleepQuality: SleepQuality = .good

    // Notes inline editing
    @State private var dailyNote: String = ""
    @State private var hasSavedNote = false

    init(profile: UserProfile) {
        self.profile = profile
        let pid = profile.id.uuidString
        _waterService = State(initialValue: WaterTrackingService(profileId: pid))
        _moodService = State(initialValue: MoodTrackingService(profileId: pid))
        _journalService = State(initialValue: HealthJournalService(profileId: pid))
    }

    private var dataService: DataService {
        DataService()
    }

    private var calendar: Calendar { Calendar.current }

    private var isToday: Bool {
        calendar.isDateInToday(selectedDate)
    }

    var body: some View {
        ScrollView {
            VStack(spacing: MCSpacing.lg) {
                dateHeader
                medicationsCard
                moodEnergyCard
                waterIntakeCard
                sleepCard
                activityCard
                symptomsCard
                vitalsCard
                notesCard
                dailySummaryCard
            }
            .padding(.vertical, MCSpacing.md)
        }
        .background(MCColors.backgroundLight)
        .task {
            await loadVitals()
            loadExistingMoodData()
            loadExistingJournalData()
        }
        .onChange(of: selectedDate) { _, _ in
            waterService.refreshToday()
            Task { await loadVitals() }
            loadExistingMoodData()
            loadExistingJournalData()
        }
    }

    // MARK: - Date Header

    private var dateHeader: some View {
        HStack(spacing: MCSpacing.md) {
            Button {
                selectedDate = calendar.date(byAdding: .day, value: -1, to: selectedDate) ?? selectedDate
            } label: {
                Image(systemName: "chevron.left")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(MCColors.primaryTeal)
                    .frame(width: 36, height: 36)
                    .background(MCColors.primaryTeal.opacity(0.1))
                    .clipShape(Circle())
            }

            VStack(spacing: 2) {
                Text(selectedDate.formatted(.dateTime.weekday(.wide)))
                    .font(MCTypography.caption)
                    .foregroundStyle(MCColors.textSecondary)
                Text(selectedDate.formatted(.dateTime.month(.abbreviated).day()))
                    .font(MCTypography.headline)
                    .foregroundStyle(MCColors.textPrimary)
            }

            Button {
                let tomorrow = calendar.date(byAdding: .day, value: 1, to: selectedDate) ?? selectedDate
                if tomorrow <= Date() {
                    selectedDate = tomorrow
                }
            } label: {
                Image(systemName: "chevron.right")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(calendar.date(byAdding: .day, value: 1, to: selectedDate).map { $0 <= Date() } == true ? MCColors.primaryTeal : MCColors.textTertiary)
                    .frame(width: 36, height: 36)
                    .background(MCColors.primaryTeal.opacity(0.1))
                    .clipShape(Circle())
            }
            .disabled(!(calendar.date(byAdding: .day, value: 1, to: selectedDate).map { $0 <= Date() } == true))

            if !isToday {
                Button {
                    selectedDate = Date()
                } label: {
                    Text("Today")
                        .font(MCTypography.captionBold)
                        .foregroundStyle(.white)
                        .padding(.horizontal, MCSpacing.sm)
                        .padding(.vertical, MCSpacing.xxs)
                        .background(MCColors.primaryTeal)
                        .clipShape(Capsule())
                }
            }
        }
        .padding(.horizontal, MCSpacing.screenPadding)
    }

    // MARK: - Medications Card

    private var todaysDoses: [DoseLog] {
        let startOfDay = calendar.startOfDay(for: selectedDate)
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!
        return profile.episodes
            .flatMap { $0.medicines }
            .filter { $0.isActive }
            .flatMap { $0.doseLogs }
            .filter { $0.scheduledTime >= startOfDay && $0.scheduledTime < endOfDay }
            .sorted { $0.scheduledTime < $1.scheduledTime }
    }

    private var medicationsCard: some View {
        MCCard {
            VStack(alignment: .leading, spacing: MCSpacing.sm) {
                trackingCardHeader(
                    icon: "pills.fill",
                    title: "Medications",
                    color: MCColors.primaryTeal,
                    badge: dosesBadge
                )

                let doses = todaysDoses
                if doses.isEmpty {
                    emptyModuleText("No medications scheduled")
                } else {
                    ForEach(doses, id: \.id) { dose in
                        HStack(spacing: MCSpacing.sm) {
                            Image(systemName: dose.status.icon)
                                .font(.system(size: 14))
                                .foregroundStyle(MCColors.statusColor(dose.status))
                                .frame(width: 28, height: 28)
                                .background(MCColors.statusColor(dose.status).opacity(0.12))
                                .clipShape(RoundedRectangle(cornerRadius: 6))

                            VStack(alignment: .leading, spacing: 1) {
                                Text(dose.medicine?.brandName ?? "Medicine")
                                    .font(MCTypography.bodyMedium)
                                    .foregroundStyle(MCColors.textPrimary)
                                Text(dose.scheduledTime.formatted(date: .omitted, time: .shortened))
                                    .font(MCTypography.caption)
                                    .foregroundStyle(MCColors.textSecondary)
                            }

                            Spacer()

                            if dose.status == .pending && isToday {
                                Button {
                                    dose.markTaken()
                                    try? modelContext.save()
                                } label: {
                                    Text("Take")
                                        .font(MCTypography.captionBold)
                                        .foregroundStyle(.white)
                                        .padding(.horizontal, MCSpacing.sm)
                                        .padding(.vertical, MCSpacing.xxs)
                                        .background(MCColors.success)
                                        .clipShape(Capsule())
                                }
                            } else {
                                Text(dose.status.rawValue)
                                    .font(MCTypography.caption)
                                    .foregroundStyle(MCColors.statusColor(dose.status))
                            }
                        }

                        if dose.id != doses.last?.id {
                            Divider()
                        }
                    }
                }
            }
        }
        .padding(.horizontal, MCSpacing.screenPadding)
    }

    private var dosesBadge: String? {
        let doses = todaysDoses
        guard !doses.isEmpty else { return nil }
        let taken = doses.filter { $0.status == .taken }.count
        return "\(taken)/\(doses.count)"
    }

    // MARK: - Mood & Energy Card

    private let moodEmojis = ["😫", "😟", "😐", "🙂", "😊"]

    private var moodEnergyCard: some View {
        MCCard {
            VStack(alignment: .leading, spacing: MCSpacing.sm) {
                trackingCardHeader(
                    icon: "face.smiling.inverse",
                    title: "Mood & Energy",
                    color: Color(hex: "A78BFA")
                )

                if hasSavedMood {
                    HStack(spacing: MCSpacing.md) {
                        VStack(spacing: 2) {
                            Text(moodEmojis[safe: selectedMood - 1] ?? "😐")
                                .font(.system(size: 28))
                            Text("Mood")
                                .font(MCTypography.caption)
                                .foregroundStyle(MCColors.textSecondary)
                        }
                        VStack(spacing: 2) {
                            Text("\(Int(selectedEnergy))/5")
                                .font(MCTypography.headline)
                                .foregroundStyle(MCColors.textPrimary)
                            Text("Energy")
                                .font(MCTypography.caption)
                                .foregroundStyle(MCColors.textSecondary)
                        }
                        Spacer()
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(MCColors.success)
                    }
                } else if isToday {
                    // Mood selector
                    Text("How are you feeling?")
                        .font(MCTypography.caption)
                        .foregroundStyle(MCColors.textSecondary)

                    HStack(spacing: MCSpacing.sm) {
                        ForEach(1...5, id: \.self) { score in
                            Button {
                                selectedMood = score
                            } label: {
                                Text(moodEmojis[score - 1])
                                    .font(.system(size: selectedMood == score ? 32 : 24))
                                    .padding(MCSpacing.xxs)
                                    .background(
                                        selectedMood == score
                                            ? Color(hex: "A78BFA").opacity(0.15)
                                            : Color.clear
                                    )
                                    .clipShape(RoundedRectangle(cornerRadius: 8))
                            }
                        }
                    }

                    // Energy slider
                    VStack(alignment: .leading, spacing: MCSpacing.xxs) {
                        Text("Energy Level: \(Int(selectedEnergy))/5")
                            .font(MCTypography.caption)
                            .foregroundStyle(MCColors.textSecondary)
                        Slider(value: $selectedEnergy, in: 1...5, step: 1)
                            .tint(Color(hex: "A78BFA"))
                    }

                    if selectedMood > 0 {
                        Button {
                            moodService.logMood(
                                mood: selectedMood,
                                energy: Int(selectedEnergy),
                                anxiety: 3,
                                sleep: 3
                            )
                            hasSavedMood = true
                        } label: {
                            Text("Save")
                                .font(MCTypography.captionBold)
                                .foregroundStyle(.white)
                                .padding(.horizontal, MCSpacing.md)
                                .padding(.vertical, MCSpacing.xs)
                                .background(Color(hex: "A78BFA"))
                                .clipShape(Capsule())
                        }
                    }
                } else {
                    emptyModuleText("No mood logged")
                }
            }
        }
        .padding(.horizontal, MCSpacing.screenPadding)
    }

    // MARK: - Water Intake Card

    private var waterIntakeCard: some View {
        let glasses = waterService.getGlasses(for: selectedDate)
        let goal = waterService.getDailyGoal()
        let progress = min(Double(glasses) / Double(goal), 1.0)

        return MCCard {
            VStack(alignment: .leading, spacing: MCSpacing.sm) {
                trackingCardHeader(
                    icon: "drop.fill",
                    title: "Water Intake",
                    color: MCColors.info,
                    badge: "\(glasses)/\(goal)"
                )

                // Progress bar
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(MCColors.divider)
                            .frame(height: 8)
                        RoundedRectangle(cornerRadius: 4)
                            .fill(MCColors.info)
                            .frame(width: geo.size.width * progress, height: 8)
                    }
                }
                .frame(height: 8)

                // Glass icons
                HStack(spacing: 4) {
                    ForEach(0..<goal, id: \.self) { idx in
                        Image(systemName: idx < glasses ? "drop.fill" : "drop")
                            .font(.system(size: 12))
                            .foregroundStyle(idx < glasses ? MCColors.info : MCColors.textTertiary)
                    }
                    Spacer()
                }

                if isToday {
                    HStack(spacing: MCSpacing.sm) {
                        Button {
                            waterService.removeGlass(for: selectedDate)
                        } label: {
                            Image(systemName: "minus.circle.fill")
                                .font(.system(size: 28))
                                .foregroundStyle(glasses > 0 ? MCColors.error : MCColors.textTertiary)
                        }
                        .disabled(glasses <= 0)

                        Text("\(glasses) glasses")
                            .font(MCTypography.bodyMedium)
                            .foregroundStyle(MCColors.textPrimary)

                        Button {
                            waterService.addGlass(for: selectedDate)
                        } label: {
                            Image(systemName: "plus.circle.fill")
                                .font(.system(size: 28))
                                .foregroundStyle(glasses < 12 ? MCColors.info : MCColors.textTertiary)
                        }
                        .disabled(glasses >= 12)

                        Spacer()

                        if glasses >= goal {
                            Label("Goal met!", systemImage: "checkmark.circle.fill")
                                .font(MCTypography.captionBold)
                                .foregroundStyle(MCColors.success)
                        }
                    }
                }
            }
        }
        .padding(.horizontal, MCSpacing.screenPadding)
    }

    // MARK: - Sleep Card

    private var sleepCard: some View {
        MCCard {
            VStack(alignment: .leading, spacing: MCSpacing.sm) {
                trackingCardHeader(
                    icon: "moon.zzz.fill",
                    title: "Sleep",
                    color: Color(hex: "6366F1")
                )

                if let sleepData = latestVitals?.sleep {
                    HStack(spacing: MCSpacing.lg) {
                        VStack(spacing: 2) {
                            Text(String(format: "%.1f", sleepData.value))
                                .font(MCTypography.metric)
                                .foregroundStyle(MCColors.textPrimary)
                            Text("hours")
                                .font(MCTypography.caption)
                                .foregroundStyle(MCColors.textSecondary)
                        }

                        VStack(alignment: .leading, spacing: 2) {
                            Text("Source: \(sleepData.sourceDisplayName)")
                                .font(MCTypography.caption)
                                .foregroundStyle(MCColors.textTertiary)
                            Text(sleepData.date.formatted(date: .omitted, time: .shortened))
                                .font(MCTypography.caption)
                                .foregroundStyle(MCColors.textTertiary)
                        }

                        Spacer()

                        sleepQualityBadge(hours: sleepData.value)
                    }
                } else {
                    // Manual entry
                    HStack(spacing: MCSpacing.lg) {
                        VStack(spacing: 2) {
                            Text(String(format: "%.1f", sleepHours))
                                .font(MCTypography.metric)
                                .foregroundStyle(MCColors.textPrimary)
                            Text("hours")
                                .font(MCTypography.caption)
                                .foregroundStyle(MCColors.textSecondary)
                        }

                        if isToday {
                            VStack(alignment: .leading, spacing: MCSpacing.xxs) {
                                Slider(value: $sleepHours, in: 0...12, step: 0.5)
                                    .tint(Color(hex: "6366F1"))

                                Picker("Quality", selection: $sleepQuality) {
                                    ForEach(SleepQuality.allCases, id: \.self) { quality in
                                        Text(quality.rawValue).tag(quality)
                                    }
                                }
                                .pickerStyle(.segmented)
                            }
                        } else {
                            Spacer()
                            emptyModuleText("No sleep data")
                        }
                    }
                }
            }
        }
        .padding(.horizontal, MCSpacing.screenPadding)
    }

    private func sleepQualityBadge(hours: Double) -> some View {
        let quality: String
        let color: Color
        if hours >= 8 {
            quality = "Excellent"
            color = MCColors.success
        } else if hours >= 7 {
            quality = "Good"
            color = MCColors.info
        } else if hours >= 5 {
            quality = "Fair"
            color = MCColors.warning
        } else {
            quality = "Poor"
            color = MCColors.error
        }

        return Text(quality)
            .font(MCTypography.captionBold)
            .foregroundStyle(color)
            .padding(.horizontal, MCSpacing.xs)
            .padding(.vertical, MCSpacing.xxs)
            .background(color.opacity(0.12))
            .clipShape(Capsule())
    }

    // MARK: - Activity Card

    private var activityCard: some View {
        MCCard {
            VStack(alignment: .leading, spacing: MCSpacing.sm) {
                trackingCardHeader(
                    icon: "figure.walk",
                    title: "Activity",
                    color: MCColors.success
                )

                if let stepsData = latestVitals?.steps {
                    let steps = Int(stepsData.value)
                    let goal = 8000
                    let progress = min(Double(steps) / Double(goal), 1.0)

                    HStack(spacing: MCSpacing.lg) {
                        VStack(spacing: 2) {
                            Text("\(steps)")
                                .font(MCTypography.metric)
                                .foregroundStyle(MCColors.textPrimary)
                            Text("steps")
                                .font(MCTypography.caption)
                                .foregroundStyle(MCColors.textSecondary)
                        }

                        VStack(alignment: .leading, spacing: MCSpacing.xxs) {
                            GeometryReader { geo in
                                ZStack(alignment: .leading) {
                                    RoundedRectangle(cornerRadius: 4)
                                        .fill(MCColors.divider)
                                        .frame(height: 8)
                                    RoundedRectangle(cornerRadius: 4)
                                        .fill(MCColors.success)
                                        .frame(width: geo.size.width * progress, height: 8)
                                }
                            }
                            .frame(height: 8)

                            Text("\(Int(progress * 100))% of \(goal) step goal")
                                .font(MCTypography.caption)
                                .foregroundStyle(MCColors.textSecondary)
                        }
                    }
                } else {
                    emptyModuleText("Connect Apple Health to track steps")
                }
            }
        }
        .padding(.horizontal, MCSpacing.screenPadding)
    }

    // MARK: - Symptoms Card

    private var todaysSymptomLogs: [SymptomLog] {
        let startOfDay = calendar.startOfDay(for: selectedDate)
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!
        return profile.episodes
            .flatMap { $0.symptomLogs }
            .filter { $0.date >= startOfDay && $0.date < endOfDay }
            .sorted { $0.date > $1.date }
    }

    private var symptomsCard: some View {
        MCCard {
            VStack(alignment: .leading, spacing: MCSpacing.sm) {
                trackingCardHeader(
                    icon: "heart.text.square.fill",
                    title: "Symptoms",
                    color: MCColors.accentCoral,
                    badge: todaysSymptomLogs.isEmpty ? nil : "\(todaysSymptomLogs.count)"
                )

                let logs = todaysSymptomLogs
                if logs.isEmpty {
                    emptyModuleText("No symptoms logged")
                } else {
                    ForEach(logs, id: \.id) { log in
                        VStack(alignment: .leading, spacing: MCSpacing.xxs) {
                            HStack(spacing: MCSpacing.xs) {
                                Text(log.overallFeeling.emoji)
                                    .font(.system(size: 18))
                                Text(log.overallFeeling.label)
                                    .font(MCTypography.bodyMedium)
                                    .foregroundStyle(MCColors.textPrimary)
                                Spacer()
                                Text(log.date.formatted(date: .omitted, time: .shortened))
                                    .font(MCTypography.caption)
                                    .foregroundStyle(MCColors.textTertiary)
                            }

                            // Symptom badges
                            let symptoms = log.symptoms
                            if !symptoms.isEmpty {
                                FlowLayout(spacing: MCSpacing.xxs) {
                                    ForEach(symptoms, id: \.id) { symptom in
                                        HStack(spacing: 4) {
                                            Text(symptom.name)
                                                .font(MCTypography.caption)
                                            Text(symptom.severity.label)
                                                .font(.system(size: 10, weight: .semibold))
                                                .foregroundStyle(Color(hex: symptom.severity.color))
                                        }
                                        .foregroundStyle(MCColors.textPrimary)
                                        .padding(.horizontal, MCSpacing.xs)
                                        .padding(.vertical, 3)
                                        .background(Color(hex: symptom.severity.color).opacity(0.1))
                                        .clipShape(Capsule())
                                    }
                                }
                            }
                        }

                        if log.id != logs.last?.id {
                            Divider()
                        }
                    }
                }
            }
        }
        .padding(.horizontal, MCSpacing.screenPadding)
    }

    // MARK: - Vitals Card

    private var vitalsCard: some View {
        MCCard {
            VStack(alignment: .leading, spacing: MCSpacing.sm) {
                trackingCardHeader(
                    icon: "waveform.path.ecg",
                    title: "Vitals",
                    color: MCColors.error
                )

                if isLoadingVitals {
                    HStack {
                        Spacer()
                        ProgressView()
                            .padding(.vertical, MCSpacing.md)
                        Spacer()
                    }
                } else if let vitals = latestVitals {
                    LazyVGrid(columns: [
                        GridItem(.flexible()),
                        GridItem(.flexible())
                    ], spacing: MCSpacing.sm) {
                        if let bp = vitals.bloodPressure {
                            vitalItem(
                                icon: "heart.text.square.fill",
                                label: "Blood Pressure",
                                value: "\(Int(bp.systolic))/\(Int(bp.diastolic))",
                                unit: "mmHg",
                                date: bp.date
                            )
                        }

                        if let hr = vitals.heartRate {
                            vitalItem(
                                icon: "heart.fill",
                                label: "Heart Rate",
                                value: "\(Int(hr.value))",
                                unit: "BPM",
                                date: hr.date
                            )
                        }

                        if let spo2 = vitals.spo2 {
                            vitalItem(
                                icon: "lungs.fill",
                                label: "SpO2",
                                value: "\(Int(spo2.value))",
                                unit: "%",
                                date: spo2.date
                            )
                        }

                        if let glucose = vitals.bloodGlucose {
                            vitalItem(
                                icon: "drop.fill",
                                label: "Glucose",
                                value: "\(Int(glucose.value))",
                                unit: "mg/dL",
                                date: glucose.date
                            )
                        }
                    }

                    let hasAnyVital = vitals.bloodPressure != nil || vitals.heartRate != nil || vitals.spo2 != nil || vitals.bloodGlucose != nil
                    if !hasAnyVital {
                        emptyModuleText("No vitals recorded. Connect Apple Health or add manually.")
                    }
                } else {
                    emptyModuleText("Connect Apple Health to see vitals")
                }
            }
        }
        .padding(.horizontal, MCSpacing.screenPadding)
    }

    private func vitalItem(icon: String, label: String, value: String, unit: String, date: Date) -> some View {
        VStack(alignment: .leading, spacing: MCSpacing.xxs) {
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 10))
                    .foregroundStyle(MCColors.error)
                Text(label)
                    .font(MCTypography.caption)
                    .foregroundStyle(MCColors.textSecondary)
            }
            HStack(alignment: .firstTextBaseline, spacing: 2) {
                Text(value)
                    .font(MCTypography.headline)
                    .foregroundStyle(MCColors.textPrimary)
                Text(unit)
                    .font(.system(size: 10))
                    .foregroundStyle(MCColors.textTertiary)
            }
            Text(date.formatted(date: .omitted, time: .shortened))
                .font(.system(size: 10))
                .foregroundStyle(MCColors.textTertiary)
        }
        .padding(MCSpacing.xs)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(MCColors.error.opacity(0.04))
        .clipShape(RoundedRectangle(cornerRadius: MCSpacing.cornerRadiusSmall))
    }

    // MARK: - Notes Card

    private var notesCard: some View {
        MCCard {
            VStack(alignment: .leading, spacing: MCSpacing.sm) {
                trackingCardHeader(
                    icon: "note.text",
                    title: "Notes / Journal",
                    color: MCColors.warning
                )

                if hasSavedNote && !dailyNote.isEmpty {
                    Text(dailyNote)
                        .font(MCTypography.body)
                        .foregroundStyle(MCColors.textPrimary)

                    Label("Saved", systemImage: "checkmark.circle.fill")
                        .font(MCTypography.caption)
                        .foregroundStyle(MCColors.success)
                } else if isToday {
                    TextField("How was your day? Any observations...", text: $dailyNote, axis: .vertical)
                        .font(MCTypography.body)
                        .lineLimit(3...6)
                        .textFieldStyle(.plain)
                        .foregroundStyle(MCColors.textPrimary)

                    if !dailyNote.isEmpty {
                        Button {
                            let doseLogs = todaysDoses
                            let symptomLogs = todaysSymptomLogs
                            _ = journalService.createDailyEntry(
                                mood: moodFromScore(selectedMood),
                                energy: Int(selectedEnergy),
                                note: dailyNote,
                                doseLogs: doseLogs,
                                symptomLogs: symptomLogs
                            )
                            hasSavedNote = true
                        } label: {
                            Text("Save Note")
                                .font(MCTypography.captionBold)
                                .foregroundStyle(.white)
                                .padding(.horizontal, MCSpacing.md)
                                .padding(.vertical, MCSpacing.xs)
                                .background(MCColors.warning)
                                .clipShape(Capsule())
                        }
                    }
                } else {
                    // Show existing journal entry for past date
                    let entry = journalEntryForDate(selectedDate)
                    if let entry {
                        Text(entry.quickNote)
                            .font(MCTypography.body)
                            .foregroundStyle(MCColors.textPrimary)
                    } else {
                        emptyModuleText("No notes for this day")
                    }
                }
            }
        }
        .padding(.horizontal, MCSpacing.screenPadding)
    }

    // MARK: - Daily Summary Card

    private var completedModules: Int {
        var count = 0
        if !todaysDoses.isEmpty && todaysDoses.allSatisfy({ $0.status == .taken }) { count += 1 }
        if hasSavedMood || moodEntryExists(for: selectedDate) { count += 1 }
        if waterService.getGlasses(for: selectedDate) >= waterService.getDailyGoal() { count += 1 }
        if latestVitals?.sleep != nil { count += 1 }
        if latestVitals?.steps != nil { count += 1 }
        if !todaysSymptomLogs.isEmpty { count += 1 }
        if latestVitals?.heartRate != nil || latestVitals?.bloodPressure != nil { count += 1 }
        if hasSavedNote || journalEntryForDate(selectedDate) != nil { count += 1 }
        return count
    }

    private let totalModules = 8

    private var dailySummaryCard: some View {
        let completed = completedModules
        let score = totalModules > 0 ? Double(completed) / Double(totalModules) : 0

        return MCAccentCard(accent: MCColors.primaryTeal) {
            VStack(spacing: MCSpacing.sm) {
                HStack {
                    VStack(alignment: .leading, spacing: MCSpacing.xxs) {
                        Text("Today's Score")
                            .font(MCTypography.headline)
                            .foregroundStyle(MCColors.textPrimary)
                        Text("\(completed)/\(totalModules) modules complete")
                            .font(MCTypography.caption)
                            .foregroundStyle(MCColors.textSecondary)
                    }

                    Spacer()

                    Text("\(Int(score * 100))%")
                        .font(MCTypography.metric)
                        .foregroundStyle(scoreColor(score))
                }

                // Progress bar
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 6)
                            .fill(MCColors.divider)
                            .frame(height: 10)
                        RoundedRectangle(cornerRadius: 6)
                            .fill(scoreColor(score))
                            .frame(width: geo.size.width * score, height: 10)
                    }
                }
                .frame(height: 10)

                Text(motivationalMessage(score: score))
                    .font(MCTypography.caption)
                    .foregroundStyle(MCColors.textSecondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .padding(.horizontal, MCSpacing.screenPadding)
    }

    // MARK: - Helpers

    private func trackingCardHeader(icon: String, title: String, color: Color, badge: String? = nil) -> some View {
        HStack(spacing: MCSpacing.xs) {
            Image(systemName: icon)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(color)
                .frame(width: 28, height: 28)
                .background(color.opacity(0.12))
                .clipShape(RoundedRectangle(cornerRadius: 6))

            Text(title)
                .font(MCTypography.headline)
                .foregroundStyle(MCColors.textPrimary)

            Spacer()

            if let badge {
                Text(badge)
                    .font(MCTypography.captionBold)
                    .foregroundStyle(color)
                    .padding(.horizontal, MCSpacing.xs)
                    .padding(.vertical, 2)
                    .background(color.opacity(0.12))
                    .clipShape(Capsule())
            }
        }
    }

    private func emptyModuleText(_ text: String) -> some View {
        Text(text)
            .font(MCTypography.caption)
            .foregroundStyle(MCColors.textTertiary)
            .frame(maxWidth: .infinity, alignment: .center)
            .padding(.vertical, MCSpacing.xs)
    }

    private func scoreColor(_ score: Double) -> Color {
        if score >= 0.75 { return MCColors.success }
        if score >= 0.5 { return MCColors.info }
        if score >= 0.25 { return MCColors.warning }
        return MCColors.error
    }

    private func motivationalMessage(score: Double) -> String {
        if score >= 0.875 { return "Outstanding! You're taking great care of your health today." }
        if score >= 0.75 { return "Great job! Almost everything tracked. Keep it up!" }
        if score >= 0.5 { return "Good progress! A few more modules to complete." }
        if score >= 0.25 { return "You've started tracking. Keep going to get a full picture." }
        return "Start logging to build your daily health snapshot."
    }

    private func moodFromScore(_ score: Int) -> JournalMood {
        switch score {
        case 1: return .terrible
        case 2: return .bad
        case 3: return .okay
        case 4: return .good
        case 5: return .great
        default: return .okay
        }
    }

    private func moodEntryExists(for date: Date) -> Bool {
        let entries = moodService.getMoodHistory(days: 1)
        let startOfDay = calendar.startOfDay(for: date)
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!
        return entries.contains { $0.date >= startOfDay && $0.date < endOfDay }
    }

    private func journalEntryForDate(_ date: Date) -> JournalEntry? {
        let startOfDay = calendar.startOfDay(for: date)
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!
        return journalService.entries.first { $0.date >= startOfDay && $0.date < endOfDay }
    }

    private func loadExistingMoodData() {
        let entries = moodService.getMoodHistory(days: 30)
        let startOfDay = calendar.startOfDay(for: selectedDate)
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!
        if let existing = entries.first(where: { $0.date >= startOfDay && $0.date < endOfDay }) {
            selectedMood = existing.moodScore
            selectedEnergy = Double(existing.energyLevel)
            hasSavedMood = true
        } else {
            selectedMood = 0
            selectedEnergy = 3
            hasSavedMood = false
        }
    }

    private func loadExistingJournalData() {
        if let entry = journalEntryForDate(selectedDate) {
            dailyNote = entry.quickNote
            hasSavedNote = true
        } else {
            dailyNote = ""
            hasSavedNote = false
        }
    }

    private func loadVitals() async {
        isLoadingVitals = true
        do {
            try await healthKitService.requestAuthorization()
            latestVitals = await healthKitService.fetchLatestVitals()
        } catch {
            // HealthKit not available — that's fine, show empty states
        }
        isLoadingVitals = false
    }
}

// MARK: - Sleep Quality

enum SleepQuality: String, CaseIterable {
    case poor = "Poor"
    case fair = "Fair"
    case good = "Good"
    case excellent = "Excellent"
}

// MARK: - Safe Array Subscript

private extension Array {
    subscript(safe index: Int) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}

// FlowLayout is defined in ProfileSetupView.swift and reused here
