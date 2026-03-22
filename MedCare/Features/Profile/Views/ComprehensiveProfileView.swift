import SwiftUI
import SwiftData

// MARK: - UserDefaults Storage Models

struct VaccinationRecord: Codable, Identifiable {
    var id: UUID = UUID()
    var name: String
    var dateAdministered: Date
    var notes: String
}

struct FamilyHistoryRecord: Codable, Identifiable {
    var id: UUID = UUID()
    var condition: String
    var affectedRelatives: [String]
}

struct LifestyleHabit: Codable, Identifiable {
    var id: UUID = UUID()
    var name: String
    var status: String // Never, Former, Some Days, Daily
}

struct AllergyDetail: Codable, Identifiable {
    var id: UUID = UUID()
    var substance: String
    var type: String // Allergy, Intolerance
    var severity: String // Low, Moderate, High, Very High
    var category: String // Drug, Food, Environment
    var isLifeThreatening: Bool
}

struct ConditionDetail: Codable, Identifiable {
    var id: UUID = UUID()
    var name: String
    var onsetDate: Date?
    var notes: String
    var isResolved: Bool
}

// MARK: - Comprehensive Profile View

struct ComprehensiveProfileView: View {
    let profile: UserProfile
    @Environment(\.dismiss) private var dismiss
    @Environment(DataService.self) private var dataService
    @Query private var doctors: [Doctor]

    @State private var expandedSections: Set<Int> = [0]

    // Sheet states
    @State private var showEditProfile = false
    @State private var showAddCondition = false
    @State private var showAddAllergy = false
    @State private var showAddVaccination = false
    @State private var showAddFamilyHistory = false
    @State private var showAddHabit = false

    // UserDefaults stored data
    @State private var vaccinations: [VaccinationRecord] = []
    @State private var familyHistory: [FamilyHistoryRecord] = []
    @State private var habits: [LifestyleHabit] = []
    @State private var allergyDetails: [AllergyDetail] = []
    @State private var conditionDetails: [ConditionDetail] = []

    // Health score tracking (UserDefaults)
    @State private var lastMedicalCheckup: Date?
    @State private var lastCholesterolTest: Date?
    @State private var lastGlucoseTest: Date?
    @State private var lastEyeExam: Date?

    private var profileKey: String { profile.id.uuidString }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: MCSpacing.sm) {
                    // Health Score Ring at top
                    healthScoreHeader

                    // 10 Expandable Sections
                    sectionCard(index: 0, icon: "person.fill", title: "Basic Info", color: MCColors.primaryTeal) {
                        basicInfoContent
                    }

                    sectionCard(index: 1, icon: "heart.text.clipboard", title: "Health Score", color: MCColors.success) {
                        healthScoreContent
                    }

                    sectionCard(index: 2, icon: "pills.fill", title: "Active Medications", color: MCColors.info, badge: activeMedicineCount) {
                        medicationsContent
                    }

                    sectionCard(index: 3, icon: "stethoscope", title: "Conditions", color: MCColors.accentCoral, badge: conditionDetails.count + profile.knownConditions.count) {
                        conditionsContent
                    }

                    sectionCard(index: 4, icon: "allergens", title: "Allergies", color: MCColors.warning, badge: allergyDetails.count + profile.allergies.count) {
                        allergiesContent
                    }

                    sectionCard(index: 5, icon: "syringe.fill", title: "Vaccinations", color: MCColors.success, badge: vaccinations.count) {
                        vaccinationsContent
                    }

                    sectionCard(index: 6, icon: "calendar.badge.clock", title: "Appointments", color: Color(hex: "A78BFA"), badge: upcomingAppointments.count) {
                        appointmentsContent
                    }

                    sectionCard(index: 7, icon: "figure.2.arms.open", title: "Family History", color: MCColors.accentCoral, badge: familyHistory.count) {
                        familyHistoryContent
                    }

                    sectionCard(index: 8, icon: "person.2.fill", title: "Care Providers", color: MCColors.primaryTeal, badge: doctors.count) {
                        careProvidersContent
                    }

                    sectionCard(index: 9, icon: "leaf.fill", title: "Lifestyle", color: MCColors.success, badge: habits.count) {
                        lifestyleContent
                    }
                }
                .padding(.horizontal, MCSpacing.screenPadding)
                .padding(.vertical, MCSpacing.md)
                .padding(.bottom, MCSpacing.xxl)
            }
            .background(MCColors.backgroundLight)
            .navigationTitle("Health Profile")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                }
            }
            .sheet(isPresented: $showEditProfile) {
                EditProfileView(profile: profile)
            }
            .sheet(isPresented: $showAddCondition) {
                AddConditionSheet(profileKey: profileKey, conditions: $conditionDetails)
            }
            .sheet(isPresented: $showAddAllergy) {
                AddAllergySheet(profileKey: profileKey, allergies: $allergyDetails)
            }
            .sheet(isPresented: $showAddVaccination) {
                AddVaccinationSheet(profileKey: profileKey, vaccinations: $vaccinations)
            }
            .sheet(isPresented: $showAddFamilyHistory) {
                AddFamilyHistorySheet(profileKey: profileKey, records: $familyHistory)
            }
            .sheet(isPresented: $showAddHabit) {
                AddHabitSheet(profileKey: profileKey, habits: $habits)
            }
        }
        .onAppear { loadPersistedData() }
    }

    // MARK: - Health Score Header

    private var healthScoreHeader: some View {
        MCCard {
            VStack(spacing: MCSpacing.sm) {
                ZStack {
                    Circle()
                        .stroke(MCColors.divider, lineWidth: 8)
                        .frame(width: 90, height: 90)

                    Circle()
                        .trim(from: 0, to: CGFloat(overallHealthScore) / 100.0)
                        .stroke(
                            healthScoreColor,
                            style: StrokeStyle(lineWidth: 8, lineCap: .round)
                        )
                        .frame(width: 90, height: 90)
                        .rotationEffect(.degrees(-90))

                    VStack(spacing: 0) {
                        Text("\(overallHealthScore)%")
                            .font(MCTypography.title)
                            .foregroundStyle(MCColors.textPrimary)
                        Text("Complete")
                            .font(MCTypography.caption)
                            .foregroundStyle(MCColors.textSecondary)
                    }
                }

                HStack(spacing: MCSpacing.md) {
                    ZStack {
                        Circle()
                            .fill(MCColors.primaryGradient)
                            .frame(width: 40, height: 40)
                        Text(profile.avatarEmoji)
                            .font(.system(size: 22))
                    }

                    VStack(alignment: .leading, spacing: 2) {
                        Text(profile.name)
                            .font(MCTypography.headline)
                            .foregroundStyle(MCColors.textPrimary)
                        HStack(spacing: MCSpacing.xxs) {
                            if let age = profile.age {
                                Text("\(age) yrs")
                            }
                            if profile.gender != nil {
                                Text("·")
                                Text(profile.gender?.rawValue ?? "")
                            }
                            if let bg = profile.bloodGroup, !bg.isEmpty {
                                Text("·")
                                Text(bg)
                            }
                        }
                        .font(MCTypography.caption)
                        .foregroundStyle(MCColors.textSecondary)
                    }

                    Spacer()
                }

                Text("Your health profile completeness")
                    .font(MCTypography.caption)
                    .foregroundStyle(MCColors.textTertiary)
            }
        }
    }

    // MARK: - Section Card Builder

    @ViewBuilder
    private func sectionCard<Content: View>(
        index: Int,
        icon: String,
        title: String,
        color: Color,
        badge: Int = 0,
        @ViewBuilder content: () -> Content
    ) -> some View {
        let isExpanded = expandedSections.contains(index)

        MCCard {
            VStack(spacing: 0) {
                // Header - always visible
                Button {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                        if isExpanded {
                            expandedSections.remove(index)
                        } else {
                            expandedSections.insert(index)
                        }
                    }
                } label: {
                    HStack(spacing: MCSpacing.sm) {
                        Image(systemName: icon)
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundStyle(color)
                            .frame(width: 32, height: 32)
                            .background(color.opacity(0.12))
                            .clipShape(RoundedRectangle(cornerRadius: MCSpacing.cornerRadiusSmall))

                        Text(title)
                            .font(MCTypography.headline)
                            .foregroundStyle(MCColors.textPrimary)

                        if badge > 0 {
                            Text("\(badge)")
                                .font(MCTypography.captionBold)
                                .foregroundStyle(.white)
                                .padding(.horizontal, 7)
                                .padding(.vertical, 2)
                                .background(color)
                                .clipShape(Capsule())
                        }

                        Spacer()

                        Image(systemName: "chevron.right")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundStyle(MCColors.textTertiary)
                            .rotationEffect(.degrees(isExpanded ? 90 : 0))
                    }
                }

                // Expandable content
                if isExpanded {
                    Divider()
                        .padding(.vertical, MCSpacing.sm)

                    content()
                }
            }
        }
    }

    // MARK: - Section 1: Basic Info

    private var basicInfoContent: some View {
        VStack(spacing: MCSpacing.sm) {
            infoRow(label: "Name", value: profile.name)
            if let age = profile.age {
                infoRow(label: "Age", value: "\(age) years")
            }
            if let gender = profile.gender {
                infoRow(label: "Sex", value: gender.rawValue)
            }
            if let bg = profile.bloodGroup, !bg.isEmpty {
                infoRow(label: "Blood Type", value: bg)
            }
            if let dob = profile.dateOfBirth {
                infoRow(label: "Date of Birth", value: dob.formatted(date: .abbreviated, time: .omitted))
            }
            infoRow(label: "Relation", value: profile.relation.rawValue)

            Button {
                showEditProfile = true
            } label: {
                HStack(spacing: MCSpacing.xs) {
                    Image(systemName: "pencil")
                        .font(.system(size: 13, weight: .medium))
                    Text("Edit Profile")
                        .font(MCTypography.subheadline)
                }
                .foregroundStyle(MCColors.primaryTeal)
                .padding(.horizontal, MCSpacing.md)
                .padding(.vertical, MCSpacing.xs)
                .background(MCColors.primaryTeal.opacity(0.1))
                .clipShape(Capsule())
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    // MARK: - Section 2: Health Score

    private var healthScoreContent: some View {
        VStack(alignment: .leading, spacing: MCSpacing.md) {
            // Prevention
            healthCategory(
                title: "Prevention",
                icon: "shield.checkered",
                items: [
                    ("Medical Checkup", checkupStatus(lastMedicalCheckup, intervalMonths: 12)),
                    ("Cholesterol Test", checkupStatus(lastCholesterolTest, intervalMonths: 12)),
                    ("Glucose Test", checkupStatus(lastGlucoseTest, intervalMonths: 6)),
                    ("Eye Exam", checkupStatus(lastEyeExam, intervalMonths: 24)),
                ]
            )

            // Monitoring
            healthCategory(
                title: "Monitoring",
                icon: "waveform.path.ecg",
                items: [
                    ("Active Episodes", profile.episodes.contains { $0.status == .active } ? .done : .overdue),
                    ("Medicines Tracked", activeMedicineCount > 0 ? .done : .overdue),
                    ("Conditions Logged", (!profile.knownConditions.isEmpty || !conditionDetails.isEmpty) ? .done : .overdue),
                    ("Allergies Logged", (!profile.allergies.isEmpty || !allergyDetails.isEmpty) ? .done : .due),
                ]
            )

            // Action
            healthCategory(
                title: "Action",
                icon: "figure.run",
                items: [
                    ("Profile Complete", isProfileComplete ? .done : .due),
                    ("Vaccinations Logged", !vaccinations.isEmpty ? .done : .due),
                    ("Family History Added", !familyHistory.isEmpty ? .done : .due),
                    ("Care Provider Added", !doctors.isEmpty ? .done : .due),
                ]
            )
        }
    }

    // MARK: - Section 3: Active Medications

    private var medicationsContent: some View {
        VStack(spacing: MCSpacing.sm) {
            let medicines = allActiveMedicines
            if medicines.isEmpty {
                emptyStateRow(icon: "pills", message: "No active medications")
            } else {
                ForEach(medicines, id: \.id) { medicine in
                    HStack(spacing: MCSpacing.sm) {
                        Image(systemName: medicine.doseForm.icon)
                            .font(.system(size: 16))
                            .foregroundStyle(MCColors.primaryTeal)
                            .frame(width: 32, height: 32)
                            .background(MCColors.primaryTeal.opacity(0.1))
                            .clipShape(Circle())

                        VStack(alignment: .leading, spacing: 2) {
                            Text(medicine.brandName)
                                .font(MCTypography.subheadline)
                                .foregroundStyle(MCColors.textPrimary)
                            if let generic = medicine.genericName, !generic.isEmpty {
                                Text(generic)
                                    .font(MCTypography.caption)
                                    .foregroundStyle(MCColors.textTertiary)
                            }
                        }

                        Spacer()

                        Text(medicine.dosage)
                            .font(MCTypography.captionBold)
                            .foregroundStyle(MCColors.primaryTeal)
                            .padding(.horizontal, MCSpacing.xs)
                            .padding(.vertical, 3)
                            .background(MCColors.primaryTeal.opacity(0.1))
                            .clipShape(Capsule())
                    }
                    .padding(.vertical, MCSpacing.xxs)

                    if medicine.id != medicines.last?.id {
                        Divider()
                    }
                }
            }
        }
    }

    // MARK: - Section 4: Conditions

    private var conditionsContent: some View {
        VStack(spacing: MCSpacing.sm) {
            // Existing simple conditions from profile
            if !profile.knownConditions.isEmpty {
                ForEach(profile.knownConditions, id: \.self) { condition in
                    HStack(spacing: MCSpacing.sm) {
                        Circle()
                            .fill(MCColors.accentCoral)
                            .frame(width: 8, height: 8)
                        Text(condition)
                            .font(MCTypography.body)
                            .foregroundStyle(MCColors.textPrimary)
                        Spacer()
                        Text("Active")
                            .font(MCTypography.caption)
                            .foregroundStyle(MCColors.warning)
                            .padding(.horizontal, MCSpacing.xs)
                            .padding(.vertical, 2)
                            .background(MCColors.warning.opacity(0.1))
                            .clipShape(Capsule())
                    }
                }
            }

            // Detailed conditions
            ForEach(conditionDetails) { condition in
                HStack(spacing: MCSpacing.sm) {
                    Circle()
                        .fill(condition.isResolved ? MCColors.success : MCColors.accentCoral)
                        .frame(width: 8, height: 8)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(condition.name)
                            .font(MCTypography.body)
                            .foregroundStyle(MCColors.textPrimary)
                        if !condition.notes.isEmpty {
                            Text(condition.notes)
                                .font(MCTypography.caption)
                                .foregroundStyle(MCColors.textTertiary)
                        }
                    }
                    Spacer()
                    Text(condition.isResolved ? "Resolved" : "Active")
                        .font(MCTypography.caption)
                        .foregroundStyle(condition.isResolved ? MCColors.success : MCColors.warning)
                        .padding(.horizontal, MCSpacing.xs)
                        .padding(.vertical, 2)
                        .background((condition.isResolved ? MCColors.success : MCColors.warning).opacity(0.1))
                        .clipShape(Capsule())
                }
            }

            if profile.knownConditions.isEmpty && conditionDetails.isEmpty {
                emptyStateRow(icon: "stethoscope", message: "No conditions recorded")
            }

            addButton("Add Condition") { showAddCondition = true }
        }
    }

    // MARK: - Section 5: Allergies

    private var allergiesContent: some View {
        VStack(spacing: MCSpacing.sm) {
            // Simple allergies from profile
            ForEach(profile.allergies, id: \.self) { allergy in
                HStack(spacing: MCSpacing.sm) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.system(size: 12))
                        .foregroundStyle(MCColors.warning)
                    Text(allergy)
                        .font(MCTypography.body)
                        .foregroundStyle(MCColors.textPrimary)
                    Spacer()
                }
            }

            // Detailed allergies
            ForEach(allergyDetails) { allergy in
                HStack(spacing: MCSpacing.sm) {
                    Image(systemName: allergy.isLifeThreatening ? "exclamationmark.octagon.fill" : "exclamationmark.triangle.fill")
                        .font(.system(size: 12))
                        .foregroundStyle(severityColor(allergy.severity))

                    VStack(alignment: .leading, spacing: 2) {
                        Text(allergy.substance)
                            .font(MCTypography.body)
                            .foregroundStyle(MCColors.textPrimary)
                        Text("\(allergy.category) · \(allergy.type)")
                            .font(MCTypography.caption)
                            .foregroundStyle(MCColors.textTertiary)
                    }

                    Spacer()

                    Text(allergy.severity)
                        .font(MCTypography.captionBold)
                        .foregroundStyle(severityColor(allergy.severity))
                        .padding(.horizontal, MCSpacing.xs)
                        .padding(.vertical, 2)
                        .background(severityColor(allergy.severity).opacity(0.12))
                        .clipShape(Capsule())
                }
            }

            if profile.allergies.isEmpty && allergyDetails.isEmpty {
                emptyStateRow(icon: "allergens", message: "No allergies recorded")
            }

            addButton("Add Allergy") { showAddAllergy = true }
        }
    }

    // MARK: - Section 6: Vaccinations

    private var vaccinationsContent: some View {
        VStack(spacing: MCSpacing.sm) {
            if vaccinations.isEmpty {
                emptyStateRow(icon: "syringe", message: "No vaccination records")
            } else {
                ForEach(vaccinations) { vax in
                    HStack(spacing: MCSpacing.sm) {
                        Image(systemName: "syringe.fill")
                            .font(.system(size: 14))
                            .foregroundStyle(MCColors.success)
                            .frame(width: 28, height: 28)
                            .background(MCColors.success.opacity(0.1))
                            .clipShape(Circle())

                        VStack(alignment: .leading, spacing: 2) {
                            Text(vax.name)
                                .font(MCTypography.subheadline)
                                .foregroundStyle(MCColors.textPrimary)
                            Text(vax.dateAdministered.formatted(date: .abbreviated, time: .omitted))
                                .font(MCTypography.caption)
                                .foregroundStyle(MCColors.textTertiary)
                        }

                        Spacer()

                        if !vax.notes.isEmpty {
                            Image(systemName: "note.text")
                                .font(.system(size: 12))
                                .foregroundStyle(MCColors.textTertiary)
                        }
                    }

                    if vax.id != vaccinations.last?.id {
                        Divider()
                    }
                }
            }

            addButton("Add Vaccination") { showAddVaccination = true }
        }
    }

    // MARK: - Section 7: Appointments

    private var appointmentsContent: some View {
        VStack(spacing: MCSpacing.sm) {
            let upcoming = upcomingAppointments
            let past = pastAppointments

            if upcoming.isEmpty && past.isEmpty {
                emptyStateRow(icon: "calendar", message: "No appointments scheduled")
            }

            if !upcoming.isEmpty {
                Text("Upcoming")
                    .font(MCTypography.captionBold)
                    .foregroundStyle(MCColors.textSecondary)
                    .textCase(.uppercase)
                    .kerning(1.0)
                    .frame(maxWidth: .infinity, alignment: .leading)

                ForEach(upcoming, id: \.id) { task in
                    appointmentRow(task, isPast: false)
                }
            }

            if !past.isEmpty {
                Text("Past")
                    .font(MCTypography.captionBold)
                    .foregroundStyle(MCColors.textSecondary)
                    .textCase(.uppercase)
                    .kerning(1.0)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.top, MCSpacing.xs)

                ForEach(past.prefix(5), id: \.id) { task in
                    appointmentRow(task, isPast: true)
                }
            }
        }
    }

    // MARK: - Section 8: Family History

    private var familyHistoryContent: some View {
        VStack(spacing: MCSpacing.sm) {
            if familyHistory.isEmpty {
                emptyStateRow(icon: "figure.2.arms.open", message: "No family history recorded")
            } else {
                ForEach(familyHistory) { record in
                    VStack(alignment: .leading, spacing: MCSpacing.xxs) {
                        Text(record.condition)
                            .font(MCTypography.subheadline)
                            .foregroundStyle(MCColors.textPrimary)

                        FlowLayout(spacing: MCSpacing.xxs) {
                            ForEach(record.affectedRelatives, id: \.self) { relative in
                                Text(relative)
                                    .font(MCTypography.caption)
                                    .foregroundStyle(MCColors.accentCoral)
                                    .padding(.horizontal, MCSpacing.xs)
                                    .padding(.vertical, 2)
                                    .background(MCColors.accentCoral.opacity(0.1))
                                    .clipShape(Capsule())
                            }
                        }
                    }
                    .padding(.vertical, MCSpacing.xxs)

                    if record.id != familyHistory.last?.id {
                        Divider()
                    }
                }
            }

            addButton("Add Family History") { showAddFamilyHistory = true }
        }
    }

    // MARK: - Section 9: Care Providers

    private var careProvidersContent: some View {
        VStack(spacing: MCSpacing.sm) {
            if doctors.isEmpty {
                emptyStateRow(icon: "person.2", message: "No care providers linked")
            } else {
                ForEach(doctors, id: \.id) { doctor in
                    HStack(spacing: MCSpacing.sm) {
                        Text(doctor.avatarEmoji)
                            .font(.system(size: 22))
                            .frame(width: 36, height: 36)
                            .background(MCColors.primaryTeal.opacity(0.1))
                            .clipShape(Circle())

                        VStack(alignment: .leading, spacing: 2) {
                            Text(doctor.name)
                                .font(MCTypography.subheadline)
                                .foregroundStyle(MCColors.textPrimary)
                            Text(doctor.specialty)
                                .font(MCTypography.caption)
                                .foregroundStyle(MCColors.textTertiary)
                        }

                        Spacer()

                        if !doctor.phone.isEmpty {
                            Button {
                                if let url = URL(string: "tel:\(doctor.phone)") {
                                    UIApplication.shared.open(url)
                                }
                            } label: {
                                Image(systemName: "phone.fill")
                                    .font(.system(size: 13))
                                    .foregroundStyle(MCColors.primaryTeal)
                                    .frame(width: 30, height: 30)
                                    .background(MCColors.primaryTeal.opacity(0.1))
                                    .clipShape(Circle())
                            }
                        }
                    }

                    if doctor.id != doctors.last?.id {
                        Divider()
                    }
                }
            }
        }
    }

    // MARK: - Section 10: Lifestyle

    private var lifestyleContent: some View {
        VStack(spacing: MCSpacing.sm) {
            if habits.isEmpty {
                emptyStateRow(icon: "leaf", message: "No lifestyle habits tracked")
            } else {
                ForEach(habits) { habit in
                    HStack(spacing: MCSpacing.sm) {
                        Image(systemName: habitIcon(habit.name))
                            .font(.system(size: 14))
                            .foregroundStyle(habitStatusColor(habit.status))
                            .frame(width: 28, height: 28)
                            .background(habitStatusColor(habit.status).opacity(0.1))
                            .clipShape(Circle())

                        Text(habit.name)
                            .font(MCTypography.body)
                            .foregroundStyle(MCColors.textPrimary)

                        Spacer()

                        Text(habit.status)
                            .font(MCTypography.captionBold)
                            .foregroundStyle(habitStatusColor(habit.status))
                            .padding(.horizontal, MCSpacing.xs)
                            .padding(.vertical, 3)
                            .background(habitStatusColor(habit.status).opacity(0.12))
                            .clipShape(Capsule())
                    }

                    if habit.id != habits.last?.id {
                        Divider()
                    }
                }
            }

            addButton("Add Habit") { showAddHabit = true }
        }
    }

    // MARK: - Helpers

    private func infoRow(label: String, value: String) -> some View {
        HStack {
            Text(label)
                .font(MCTypography.caption)
                .foregroundStyle(MCColors.textSecondary)
                .frame(width: 90, alignment: .leading)
            Text(value)
                .font(MCTypography.body)
                .foregroundStyle(MCColors.textPrimary)
            Spacer()
        }
    }

    private func emptyStateRow(icon: String, message: String) -> some View {
        HStack(spacing: MCSpacing.sm) {
            Image(systemName: icon)
                .font(.system(size: 18))
                .foregroundStyle(MCColors.textTertiary)
            Text(message)
                .font(MCTypography.footnote)
                .foregroundStyle(MCColors.textTertiary)
        }
        .frame(maxWidth: .infinity, alignment: .center)
        .padding(.vertical, MCSpacing.md)
    }

    private func addButton(_ title: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: MCSpacing.xs) {
                Image(systemName: "plus.circle.fill")
                    .font(.system(size: 15))
                Text(title)
                    .font(MCTypography.subheadline)
            }
            .foregroundStyle(MCColors.primaryTeal)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.top, MCSpacing.xxs)
    }

    private func appointmentRow(_ task: CareTask, isPast: Bool) -> some View {
        HStack(spacing: MCSpacing.sm) {
            Image(systemName: task.taskType.icon)
                .font(.system(size: 14))
                .foregroundStyle(isPast ? MCColors.textTertiary : Color(hex: "A78BFA"))
                .frame(width: 28, height: 28)
                .background((isPast ? MCColors.textTertiary : Color(hex: "A78BFA")).opacity(0.1))
                .clipShape(Circle())

            VStack(alignment: .leading, spacing: 2) {
                Text(task.title)
                    .font(MCTypography.subheadline)
                    .foregroundStyle(isPast ? MCColors.textSecondary : MCColors.textPrimary)
                if let date = task.dueDate {
                    Text(date.formatted(date: .abbreviated, time: .shortened))
                        .font(MCTypography.caption)
                        .foregroundStyle(MCColors.textTertiary)
                }
            }

            Spacer()

            if task.isCompleted {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 16))
                    .foregroundStyle(MCColors.success)
            }
        }
    }

    private var allActiveMedicines: [Medicine] {
        profile.episodes.flatMap { $0.medicines }.filter { $0.isActive }
    }

    private var activeMedicineCount: Int {
        allActiveMedicines.count
    }

    private var upcomingAppointments: [CareTask] {
        let now = Date()
        return profile.episodes
            .flatMap { $0.tasks }
            .filter { $0.taskType == .followUp && !$0.isCompleted && ($0.dueDate ?? .distantPast) >= now }
            .sorted { ($0.dueDate ?? .distantFuture) < ($1.dueDate ?? .distantFuture) }
    }

    private var pastAppointments: [CareTask] {
        let now = Date()
        return profile.episodes
            .flatMap { $0.tasks }
            .filter { $0.taskType == .followUp && ($0.isCompleted || ($0.dueDate ?? .distantFuture) < now) }
            .sorted { ($0.dueDate ?? .distantPast) > ($1.dueDate ?? .distantPast) }
    }

    private var isProfileComplete: Bool {
        profile.name.count > 0 &&
        profile.dateOfBirth != nil &&
        profile.gender != nil &&
        profile.bloodGroup != nil && !(profile.bloodGroup?.isEmpty ?? true)
    }

    // MARK: - Health Score Calculation

    private var overallHealthScore: Int {
        var total = 0
        var completed = 0

        // Prevention (4 items)
        let preventionItems: [Date?] = [lastMedicalCheckup, lastCholesterolTest, lastGlucoseTest, lastEyeExam]
        total += 4
        completed += preventionItems.compactMap { $0 }.count

        // Monitoring (4 items)
        total += 4
        if profile.episodes.contains(where: { $0.status == .active }) { completed += 1 }
        if activeMedicineCount > 0 { completed += 1 }
        if !profile.knownConditions.isEmpty || !conditionDetails.isEmpty { completed += 1 }
        if !profile.allergies.isEmpty || !allergyDetails.isEmpty { completed += 1 }

        // Action (4 items)
        total += 4
        if isProfileComplete { completed += 1 }
        if !vaccinations.isEmpty { completed += 1 }
        if !familyHistory.isEmpty { completed += 1 }
        if !doctors.isEmpty { completed += 1 }

        guard total > 0 else { return 0 }
        return Int(Double(completed) / Double(total) * 100)
    }

    private var healthScoreColor: Color {
        let score = overallHealthScore
        if score >= 75 { return MCColors.success }
        if score >= 50 { return MCColors.warning }
        return MCColors.accentCoral
    }

    enum HealthItemStatus {
        case done, due, overdue
    }

    private func checkupStatus(_ date: Date?, intervalMonths: Int) -> HealthItemStatus {
        guard let date else { return .overdue }
        let monthsSince = Calendar.current.dateComponents([.month], from: date, to: Date()).month ?? 0
        if monthsSince <= intervalMonths { return .done }
        if monthsSince <= intervalMonths + 3 { return .due }
        return .overdue
    }

    private func healthCategory(title: String, icon: String, items: [(String, HealthItemStatus)]) -> some View {
        VStack(alignment: .leading, spacing: MCSpacing.xs) {
            HStack(spacing: MCSpacing.xs) {
                Image(systemName: icon)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(MCColors.primaryTeal)
                Text(title)
                    .font(MCTypography.captionBold)
                    .foregroundStyle(MCColors.textPrimary)
                    .textCase(.uppercase)
                    .kerning(0.8)
            }

            ForEach(items, id: \.0) { item in
                HStack(spacing: MCSpacing.sm) {
                    statusIcon(item.1)
                    Text(item.0)
                        .font(MCTypography.footnote)
                        .foregroundStyle(MCColors.textPrimary)
                    Spacer()
                }
            }
        }
        .padding(MCSpacing.sm)
        .background(MCColors.backgroundLight)
        .clipShape(RoundedRectangle(cornerRadius: MCSpacing.cornerRadiusSmall))
    }

    private func statusIcon(_ status: HealthItemStatus) -> some View {
        Group {
            switch status {
            case .done:
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(MCColors.success)
            case .due:
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundStyle(MCColors.warning)
            case .overdue:
                Image(systemName: "xmark.circle.fill")
                    .foregroundStyle(MCColors.accentCoral)
            }
        }
        .font(.system(size: 14))
    }

    private func severityColor(_ severity: String) -> Color {
        switch severity {
        case "Low": return MCColors.success
        case "Moderate": return MCColors.warning
        case "High": return MCColors.accentCoral
        case "Very High": return MCColors.error
        default: return MCColors.textSecondary
        }
    }

    private func habitIcon(_ name: String) -> String {
        switch name.lowercased() {
        case "smoking": return "smoke.fill"
        case "alcohol": return "wineglass.fill"
        case "caffeine": return "cup.and.saucer.fill"
        case "exercise": return "figure.run"
        case "diet": return "fork.knife"
        case "meditation": return "figure.mind.and.body"
        case "sleep": return "bed.double.fill"
        default: return "leaf.fill"
        }
    }

    private func habitStatusColor(_ status: String) -> Color {
        switch status {
        case "Never": return MCColors.success
        case "Former": return MCColors.info
        case "Some Days": return MCColors.warning
        case "Daily": return MCColors.accentCoral
        default: return MCColors.textSecondary
        }
    }

    // MARK: - Persistence

    private func loadPersistedData() {
        let ud = UserDefaults.standard
        if let data = ud.data(forKey: "cp_vaccinations_\(profileKey)"),
           let decoded = try? JSONDecoder().decode([VaccinationRecord].self, from: data) {
            vaccinations = decoded
        }
        if let data = ud.data(forKey: "cp_family_history_\(profileKey)"),
           let decoded = try? JSONDecoder().decode([FamilyHistoryRecord].self, from: data) {
            familyHistory = decoded
        }
        if let data = ud.data(forKey: "cp_habits_\(profileKey)"),
           let decoded = try? JSONDecoder().decode([LifestyleHabit].self, from: data) {
            habits = decoded
        }
        if let data = ud.data(forKey: "cp_allergies_\(profileKey)"),
           let decoded = try? JSONDecoder().decode([AllergyDetail].self, from: data) {
            allergyDetails = decoded
        }
        if let data = ud.data(forKey: "cp_conditions_\(profileKey)"),
           let decoded = try? JSONDecoder().decode([ConditionDetail].self, from: data) {
            conditionDetails = decoded
        }
        if let ts = ud.object(forKey: "cp_last_checkup_\(profileKey)") as? Date {
            lastMedicalCheckup = ts
        }
        if let ts = ud.object(forKey: "cp_last_cholesterol_\(profileKey)") as? Date {
            lastCholesterolTest = ts
        }
        if let ts = ud.object(forKey: "cp_last_glucose_\(profileKey)") as? Date {
            lastGlucoseTest = ts
        }
        if let ts = ud.object(forKey: "cp_last_eye_\(profileKey)") as? Date {
            lastEyeExam = ts
        }
    }
}

// MARK: - Add Condition Sheet

struct AddConditionSheet: View {
    let profileKey: String
    @Binding var conditions: [ConditionDetail]
    @Environment(\.dismiss) private var dismiss

    @State private var name = ""
    @State private var notes = ""
    @State private var onsetDate = Date()
    @State private var hasOnsetDate = false
    @State private var isResolved = false

    private let commonConditions = [
        "Diabetes (Type 2)", "Hypertension", "Asthma", "Thyroid",
        "PCOD/PCOS", "Arthritis", "Heart Disease", "Migraine",
        "Acid Reflux (GERD)", "Anemia", "Cholesterol (High)",
        "Kidney Disease", "Liver Disease", "Depression", "Anxiety",
        "Back Pain", "Diabetes (Type 1)", "Epilepsy", "TB",
        "Dengue (History)", "Malaria (History)"
    ]

    @State private var filteredSuggestions: [String] = []

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: MCSpacing.lg) {
                    MCTextField(label: "Condition Name", icon: "stethoscope", text: $name)
                        .onChange(of: name) { _, newVal in
                            if newVal.count >= 2 {
                                filteredSuggestions = commonConditions.filter {
                                    $0.localizedCaseInsensitiveContains(newVal)
                                }
                            } else {
                                filteredSuggestions = []
                            }
                        }

                    if !filteredSuggestions.isEmpty {
                        FlowLayout(spacing: MCSpacing.xs) {
                            ForEach(filteredSuggestions, id: \.self) { suggestion in
                                Button {
                                    name = suggestion
                                    filteredSuggestions = []
                                } label: {
                                    Text(suggestion)
                                        .font(MCTypography.footnote)
                                        .foregroundStyle(MCColors.primaryTeal)
                                        .padding(.horizontal, MCSpacing.sm)
                                        .padding(.vertical, MCSpacing.xxs + 2)
                                        .background(MCColors.primaryTeal.opacity(0.08))
                                        .clipShape(Capsule())
                                }
                            }
                        }
                    }

                    Toggle(isOn: $hasOnsetDate) {
                        Text("Onset Date")
                            .font(MCTypography.subheadline)
                            .foregroundStyle(MCColors.textSecondary)
                    }
                    .tint(MCColors.primaryTeal)

                    if hasOnsetDate {
                        DatePicker("", selection: $onsetDate, displayedComponents: .date)
                            .datePickerStyle(.compact)
                            .labelsHidden()
                    }

                    MCTextField(label: "Notes (optional)", icon: "note.text", text: $notes)

                    Toggle(isOn: $isResolved) {
                        Text("Resolved")
                            .font(MCTypography.subheadline)
                            .foregroundStyle(MCColors.textSecondary)
                    }
                    .tint(MCColors.primaryTeal)

                    MCPrimaryButton("Add Condition", icon: "plus") {
                        let condition = ConditionDetail(
                            name: name.trimmingCharacters(in: .whitespaces),
                            onsetDate: hasOnsetDate ? onsetDate : nil,
                            notes: notes.trimmingCharacters(in: .whitespaces),
                            isResolved: isResolved
                        )
                        conditions.append(condition)
                        saveConditions()
                        dismiss()
                    }
                    .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
                    .opacity(name.trimmingCharacters(in: .whitespaces).isEmpty ? 0.6 : 1)
                }
                .padding(.horizontal, MCSpacing.screenPadding)
                .padding(.vertical, MCSpacing.lg)
            }
            .background(MCColors.backgroundLight)
            .navigationTitle("Add Condition")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }

    private func saveConditions() {
        if let data = try? JSONEncoder().encode(conditions) {
            UserDefaults.standard.set(data, forKey: "cp_conditions_\(profileKey)")
        }
    }
}

// MARK: - Add Allergy Sheet

struct AddAllergySheet: View {
    let profileKey: String
    @Binding var allergies: [AllergyDetail]
    @Environment(\.dismiss) private var dismiss

    @State private var substance = ""
    @State private var type = "Allergy"
    @State private var severity = "Moderate"
    @State private var category = "Drug"
    @State private var isLifeThreatening = false

    private let types = ["Allergy", "Intolerance"]
    private let severities = ["Low", "Moderate", "High", "Very High"]
    private let categories = ["Drug", "Food", "Environment"]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: MCSpacing.lg) {
                    MCTextField(label: "Substance", icon: "allergens", text: $substance)

                    chipSelector(title: "Type", options: types, selection: $type)
                    chipSelector(title: "Severity", options: severities, selection: $severity)
                    chipSelector(title: "Category", options: categories, selection: $category)

                    Toggle(isOn: $isLifeThreatening) {
                        HStack(spacing: MCSpacing.xs) {
                            Image(systemName: "exclamationmark.octagon.fill")
                                .foregroundStyle(MCColors.error)
                            Text("Life-Threatening")
                                .font(MCTypography.subheadline)
                                .foregroundStyle(MCColors.textPrimary)
                        }
                    }
                    .tint(MCColors.error)

                    MCPrimaryButton("Add Allergy", icon: "plus") {
                        let allergy = AllergyDetail(
                            substance: substance.trimmingCharacters(in: .whitespaces),
                            type: type,
                            severity: severity,
                            category: category,
                            isLifeThreatening: isLifeThreatening
                        )
                        allergies.append(allergy)
                        saveAllergies()
                        dismiss()
                    }
                    .disabled(substance.trimmingCharacters(in: .whitespaces).isEmpty)
                    .opacity(substance.trimmingCharacters(in: .whitespaces).isEmpty ? 0.6 : 1)
                }
                .padding(.horizontal, MCSpacing.screenPadding)
                .padding(.vertical, MCSpacing.lg)
            }
            .background(MCColors.backgroundLight)
            .navigationTitle("Add Allergy")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }

    private func chipSelector(title: String, options: [String], selection: Binding<String>) -> some View {
        VStack(alignment: .leading, spacing: MCSpacing.xs) {
            Text(title)
                .font(MCTypography.subheadline)
                .foregroundStyle(MCColors.textSecondary)
            HStack(spacing: MCSpacing.xs) {
                ForEach(options, id: \.self) { option in
                    Button {
                        selection.wrappedValue = option
                    } label: {
                        Text(option)
                            .font(MCTypography.footnote)
                            .foregroundStyle(selection.wrappedValue == option ? .white : MCColors.textPrimary)
                            .padding(.horizontal, MCSpacing.sm)
                            .padding(.vertical, MCSpacing.xs)
                            .background(selection.wrappedValue == option ? MCColors.primaryTeal : MCColors.backgroundLight)
                            .clipShape(Capsule())
                    }
                }
            }
        }
    }

    private func saveAllergies() {
        if let data = try? JSONEncoder().encode(allergies) {
            UserDefaults.standard.set(data, forKey: "cp_allergies_\(profileKey)")
        }
    }
}

// MARK: - Add Vaccination Sheet

struct AddVaccinationSheet: View {
    let profileKey: String
    @Binding var vaccinations: [VaccinationRecord]
    @Environment(\.dismiss) private var dismiss

    @State private var name = ""
    @State private var dateAdministered = Date()
    @State private var notes = ""

    private let commonVaccines = [
        "COVID-19 (Covishield)", "COVID-19 (Covaxin)", "Flu (Influenza)",
        "Hepatitis B", "Hepatitis A", "Typhoid", "BCG",
        "Tetanus (TT)", "Polio (IPV)", "MMR", "Rabies",
        "HPV", "Pneumococcal", "Varicella (Chickenpox)",
        "Meningococcal", "Japanese Encephalitis"
    ]

    @State private var showSuggestions = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: MCSpacing.lg) {
                    MCTextField(label: "Vaccine Name", icon: "syringe", text: $name)
                        .onChange(of: name) { _, _ in
                            showSuggestions = name.count >= 1
                        }

                    if showSuggestions {
                        let filtered = commonVaccines.filter {
                            name.isEmpty || $0.localizedCaseInsensitiveContains(name)
                        }
                        if !filtered.isEmpty {
                            FlowLayout(spacing: MCSpacing.xs) {
                                ForEach(filtered, id: \.self) { vaccine in
                                    Button {
                                        name = vaccine
                                        showSuggestions = false
                                    } label: {
                                        Text(vaccine)
                                            .font(MCTypography.footnote)
                                            .foregroundStyle(MCColors.primaryTeal)
                                            .padding(.horizontal, MCSpacing.sm)
                                            .padding(.vertical, MCSpacing.xxs + 2)
                                            .background(MCColors.primaryTeal.opacity(0.08))
                                            .clipShape(Capsule())
                                    }
                                }
                            }
                        }
                    }

                    DatePicker("Date Administered", selection: $dateAdministered, displayedComponents: .date)
                        .datePickerStyle(.compact)

                    MCTextField(label: "Notes (optional)", icon: "note.text", text: $notes)

                    MCPrimaryButton("Add Vaccination", icon: "plus") {
                        let record = VaccinationRecord(
                            name: name.trimmingCharacters(in: .whitespaces),
                            dateAdministered: dateAdministered,
                            notes: notes.trimmingCharacters(in: .whitespaces)
                        )
                        vaccinations.append(record)
                        saveVaccinations()
                        dismiss()
                    }
                    .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
                    .opacity(name.trimmingCharacters(in: .whitespaces).isEmpty ? 0.6 : 1)
                }
                .padding(.horizontal, MCSpacing.screenPadding)
                .padding(.vertical, MCSpacing.lg)
            }
            .background(MCColors.backgroundLight)
            .navigationTitle("Add Vaccination")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }

    private func saveVaccinations() {
        if let data = try? JSONEncoder().encode(vaccinations) {
            UserDefaults.standard.set(data, forKey: "cp_vaccinations_\(profileKey)")
        }
    }
}

// MARK: - Add Family History Sheet

struct AddFamilyHistorySheet: View {
    let profileKey: String
    @Binding var records: [FamilyHistoryRecord]
    @Environment(\.dismiss) private var dismiss

    @State private var condition = ""
    @State private var selectedRelatives: Set<String> = []

    private let relatives = ["Mother", "Father", "Sibling", "Grandparent", "Uncle", "Aunt"]
    private let commonConditions = [
        "Diabetes", "Hypertension", "Heart Disease", "Cancer",
        "Asthma", "Thyroid", "Arthritis", "Kidney Disease",
        "Stroke", "Alzheimer's", "Depression"
    ]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: MCSpacing.lg) {
                    MCTextField(label: "Condition", icon: "stethoscope", text: $condition)

                    FlowLayout(spacing: MCSpacing.xs) {
                        ForEach(commonConditions, id: \.self) { c in
                            Button {
                                condition = c
                            } label: {
                                Text(c)
                                    .font(MCTypography.footnote)
                                    .foregroundStyle(condition == c ? .white : MCColors.textPrimary)
                                    .padding(.horizontal, MCSpacing.sm)
                                    .padding(.vertical, MCSpacing.xxs + 2)
                                    .background(condition == c ? MCColors.primaryTeal : MCColors.backgroundLight)
                                    .clipShape(Capsule())
                            }
                        }
                    }

                    VStack(alignment: .leading, spacing: MCSpacing.xs) {
                        Text("Affected Relatives")
                            .font(MCTypography.subheadline)
                            .foregroundStyle(MCColors.textSecondary)

                        FlowLayout(spacing: MCSpacing.xs) {
                            ForEach(relatives, id: \.self) { relative in
                                Button {
                                    if selectedRelatives.contains(relative) {
                                        selectedRelatives.remove(relative)
                                    } else {
                                        selectedRelatives.insert(relative)
                                    }
                                } label: {
                                    Text(relative)
                                        .font(MCTypography.footnote)
                                        .foregroundStyle(selectedRelatives.contains(relative) ? .white : MCColors.textPrimary)
                                        .padding(.horizontal, MCSpacing.sm)
                                        .padding(.vertical, MCSpacing.xs)
                                        .background(selectedRelatives.contains(relative) ? MCColors.accentCoral : MCColors.backgroundLight)
                                        .clipShape(Capsule())
                                }
                            }
                        }
                    }

                    MCPrimaryButton("Add Family History", icon: "plus") {
                        let record = FamilyHistoryRecord(
                            condition: condition.trimmingCharacters(in: .whitespaces),
                            affectedRelatives: Array(selectedRelatives).sorted()
                        )
                        records.append(record)
                        saveRecords()
                        dismiss()
                    }
                    .disabled(condition.trimmingCharacters(in: .whitespaces).isEmpty || selectedRelatives.isEmpty)
                    .opacity(condition.trimmingCharacters(in: .whitespaces).isEmpty || selectedRelatives.isEmpty ? 0.6 : 1)
                }
                .padding(.horizontal, MCSpacing.screenPadding)
                .padding(.vertical, MCSpacing.lg)
            }
            .background(MCColors.backgroundLight)
            .navigationTitle("Add Family History")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }

    private func saveRecords() {
        if let data = try? JSONEncoder().encode(records) {
            UserDefaults.standard.set(data, forKey: "cp_family_history_\(profileKey)")
        }
    }
}

// MARK: - Add Habit Sheet

struct AddHabitSheet: View {
    let profileKey: String
    @Binding var habits: [LifestyleHabit]
    @Environment(\.dismiss) private var dismiss

    @State private var name = ""
    @State private var status = "Never"

    private let commonHabits = ["Smoking", "Alcohol", "Caffeine", "Exercise", "Diet", "Meditation", "Sleep"]
    private let statuses = ["Never", "Former", "Some Days", "Daily"]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: MCSpacing.lg) {
                    VStack(alignment: .leading, spacing: MCSpacing.xs) {
                        Text("Habit")
                            .font(MCTypography.subheadline)
                            .foregroundStyle(MCColors.textSecondary)

                        FlowLayout(spacing: MCSpacing.xs) {
                            ForEach(commonHabits, id: \.self) { habit in
                                Button {
                                    name = habit
                                } label: {
                                    Text(habit)
                                        .font(MCTypography.footnote)
                                        .foregroundStyle(name == habit ? .white : MCColors.textPrimary)
                                        .padding(.horizontal, MCSpacing.sm)
                                        .padding(.vertical, MCSpacing.xs)
                                        .background(name == habit ? MCColors.primaryTeal : MCColors.backgroundLight)
                                        .clipShape(Capsule())
                                }
                            }
                        }

                        MCTextField(label: "Or type custom habit", icon: "leaf", text: $name)
                    }

                    VStack(alignment: .leading, spacing: MCSpacing.xs) {
                        Text("Status")
                            .font(MCTypography.subheadline)
                            .foregroundStyle(MCColors.textSecondary)

                        HStack(spacing: MCSpacing.xs) {
                            ForEach(statuses, id: \.self) { s in
                                Button {
                                    status = s
                                } label: {
                                    Text(s)
                                        .font(MCTypography.footnote)
                                        .foregroundStyle(status == s ? .white : MCColors.textPrimary)
                                        .padding(.horizontal, MCSpacing.sm)
                                        .padding(.vertical, MCSpacing.xs)
                                        .background(status == s ? MCColors.primaryTeal : MCColors.backgroundLight)
                                        .clipShape(Capsule())
                                }
                            }
                        }
                    }

                    MCPrimaryButton("Add Habit", icon: "plus") {
                        let habit = LifestyleHabit(
                            name: name.trimmingCharacters(in: .whitespaces),
                            status: status
                        )
                        habits.append(habit)
                        saveHabits()
                        dismiss()
                    }
                    .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
                    .opacity(name.trimmingCharacters(in: .whitespaces).isEmpty ? 0.6 : 1)
                }
                .padding(.horizontal, MCSpacing.screenPadding)
                .padding(.vertical, MCSpacing.lg)
            }
            .background(MCColors.backgroundLight)
            .navigationTitle("Add Habit")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }

    private func saveHabits() {
        if let data = try? JSONEncoder().encode(habits) {
            UserDefaults.standard.set(data, forKey: "cp_habits_\(profileKey)")
        }
    }
}
