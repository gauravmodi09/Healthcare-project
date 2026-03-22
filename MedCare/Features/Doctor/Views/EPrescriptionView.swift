import SwiftUI

struct EPrescriptionView: View {
    let patient: DoctorPatientData
    @Environment(\.dismiss) private var dismiss

    // Doctor info (mock)
    private let doctorName = "Dr. Anil Mehta"
    private let registrationNumber = "MCI-12345-2015"
    private let qualification = "MBBS, MD (General Medicine)"

    // Form state
    @State private var diagnosis = ""
    @State private var prescriptionDrugs: [PrescriptionEntry] = []
    @State private var notesText = ""
    @State private var showingDrugSearch = false
    @State private var showingGeneratedPrescription = false
    @State private var generatedPrescriptionText = ""

    // Drug entry state
    @State private var drugSearchQuery = ""
    @State private var selectedDrug: DrugEntry?
    @State private var drugDosage = ""
    @State private var drugFrequency: MedicineFrequency = .onceDaily
    @State private var drugDuration = ""
    @State private var drugMealTiming: MealTiming = .afterMeal
    @State private var drugInstructions = ""
    @State private var drugDoseForm: DoseForm = .tablet

    // Interaction checking
    @State private var interactionAlerts: [DrugInteractionService.InteractionAlert] = []
    private let interactionService = DrugInteractionService()
    private let drugScheduleService = DrugScheduleService.shared
    private let prescriptionService = EPrescriptionService.shared

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: MCSpacing.sectionSpacing) {
                    patientInfoHeader
                    diagnosisSection
                    medicineListSection
                    interactionWarnings
                    notesSection
                    nmcComplianceInfo
                    generateButton
                }
                .padding(.vertical, MCSpacing.md)
            }
            .background(MCColors.backgroundLight)
            .navigationTitle("E-Prescription")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
            .sheet(isPresented: $showingDrugSearch) {
                drugSearchSheet
            }
            .sheet(isPresented: $showingGeneratedPrescription) {
                generatedPrescriptionSheet
            }
        }
    }

    // MARK: - Patient Info Header

    private var patientInfoHeader: some View {
        MCAccentCard(accent: MCColors.primaryTeal) {
            VStack(alignment: .leading, spacing: MCSpacing.xs) {
                HStack(spacing: MCSpacing.sm) {
                    Text(patient.avatarEmoji)
                        .font(.system(size: 28))
                        .frame(width: 44, height: 44)
                        .background(MCColors.backgroundLight)
                        .clipShape(Circle())
                    VStack(alignment: .leading, spacing: MCSpacing.xxs) {
                        Text(patient.name)
                            .font(MCTypography.headline)
                            .foregroundStyle(MCColors.textPrimary)
                        HStack(spacing: MCSpacing.xs) {
                            Text("\(patient.age) yrs")
                            Text("\u{00B7}")
                            Text(patient.primaryCondition)
                        }
                        .font(MCTypography.caption)
                        .foregroundStyle(MCColors.textSecondary)
                    }
                }
            }
        }
        .padding(.horizontal, MCSpacing.screenPadding)
    }

    // MARK: - Diagnosis

    private var diagnosisSection: some View {
        VStack(alignment: .leading, spacing: MCSpacing.xs) {
            sectionLabel("Diagnosis")
            MCTextField(label: "Enter diagnosis", icon: "doc.text", text: $diagnosis)
                .padding(.horizontal, MCSpacing.screenPadding)
        }
    }

    // MARK: - Medicine List

    private var medicineListSection: some View {
        VStack(alignment: .leading, spacing: MCSpacing.sm) {
            sectionLabel("Prescribed Medicines")

            if prescriptionDrugs.isEmpty {
                MCCard {
                    HStack {
                        Image(systemName: "pills")
                            .foregroundStyle(MCColors.textTertiary)
                        Text("No medicines added yet")
                            .font(MCTypography.callout)
                            .foregroundStyle(MCColors.textTertiary)
                        Spacer()
                    }
                }
                .padding(.horizontal, MCSpacing.screenPadding)
            } else {
                VStack(spacing: MCSpacing.xs) {
                    ForEach(prescriptionDrugs) { drug in
                        prescriptionDrugCard(drug)
                    }
                }
                .padding(.horizontal, MCSpacing.screenPadding)
            }

            Button {
                resetDrugEntryFields()
                showingDrugSearch = true
            } label: {
                HStack(spacing: MCSpacing.xs) {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 18))
                    Text("Add Medicine")
                        .font(MCTypography.headline)
                }
                .foregroundStyle(MCColors.primaryTeal)
                .frame(maxWidth: .infinity)
                .frame(height: MCSpacing.buttonHeight)
                .background(
                    RoundedRectangle(cornerRadius: MCSpacing.cornerRadius)
                        .strokeBorder(style: StrokeStyle(lineWidth: 1.5, dash: [8, 4]))
                        .foregroundStyle(MCColors.primaryTeal.opacity(0.4))
                )
            }
            .padding(.horizontal, MCSpacing.screenPadding)
        }
    }

    private func prescriptionDrugCard(_ drug: PrescriptionEntry) -> some View {
        MCCard {
            VStack(alignment: .leading, spacing: MCSpacing.xs) {
                HStack {
                    VStack(alignment: .leading, spacing: MCSpacing.xxs) {
                        HStack(spacing: MCSpacing.xs) {
                            Text(drug.drugName)
                                .font(MCTypography.headline)
                                .foregroundStyle(MCColors.textPrimary)
                            if let genericName = drug.genericName {
                                Text("(\(genericName))")
                                    .font(MCTypography.caption)
                                    .foregroundStyle(MCColors.textTertiary)
                            }
                        }
                        Text("\(drug.dosage) \(drug.doseForm) \u{00B7} \(drug.frequency) \u{00B7} \(drug.duration)")
                            .font(MCTypography.caption)
                            .foregroundStyle(MCColors.textSecondary)
                        if !drug.mealTiming.isEmpty {
                            Text(drug.mealTiming)
                                .font(MCTypography.caption)
                                .foregroundStyle(MCColors.textTertiary)
                        }
                    }
                    Spacer()
                    Button {
                        withAnimation {
                            prescriptionDrugs.removeAll { $0.id == drug.id }
                            recheckInteractions()
                        }
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(MCColors.textTertiary)
                            .font(.system(size: 20))
                    }
                }

                // Schedule badge
                if let schedule = drug.schedule {
                    HStack(spacing: MCSpacing.xs) {
                        scheduleWarningBadge(schedule)
                        if let warning = drug.scheduleWarning {
                            Text(warning)
                                .font(.system(size: 10))
                                .foregroundStyle(scheduleColor(schedule))
                                .lineLimit(2)
                        }
                    }
                }

                if let instructions = drug.instructions, !instructions.isEmpty {
                    Text("Note: \(instructions)")
                        .font(MCTypography.caption)
                        .foregroundStyle(MCColors.textSecondary)
                        .italic()
                }
            }
        }
    }

    private func scheduleWarningBadge(_ schedule: DrugScheduleService.DrugSchedule) -> some View {
        let color = scheduleColor(schedule)
        return MCBadge(schedule.rawValue, color: color, style: schedule == .listC ? .filled : .soft)
    }

    private func scheduleColor(_ schedule: DrugScheduleService.DrugSchedule) -> Color {
        switch schedule {
        case .listA: return MCColors.success
        case .listB: return MCColors.warning
        case .listC: return MCColors.error
        }
    }

    // MARK: - Interaction Warnings

    @ViewBuilder
    private var interactionWarnings: some View {
        if !interactionAlerts.isEmpty {
            VStack(alignment: .leading, spacing: MCSpacing.sm) {
                sectionLabel("Drug Interactions")

                VStack(spacing: MCSpacing.xs) {
                    ForEach(interactionAlerts) { alert in
                        MCAccentCard(accent: interactionColor(alert.severity)) {
                            VStack(alignment: .leading, spacing: MCSpacing.xs) {
                                HStack(spacing: MCSpacing.xs) {
                                    Image(systemName: alert.severity.icon)
                                        .foregroundStyle(interactionColor(alert.severity))
                                        .font(.system(size: 14, weight: .bold))
                                    Text("\(alert.severity.rawValue): \(alert.medicine1) + \(alert.medicine2)")
                                        .font(MCTypography.captionBold)
                                        .foregroundStyle(interactionColor(alert.severity))
                                }
                                Text(alert.description)
                                    .font(MCTypography.caption)
                                    .foregroundStyle(MCColors.textSecondary)
                                Text(alert.recommendation)
                                    .font(MCTypography.caption)
                                    .foregroundStyle(MCColors.textPrimary)
                                    .italic()
                            }
                        }
                    }
                }
                .padding(.horizontal, MCSpacing.screenPadding)
            }
        }
    }

    private func interactionColor(_ severity: DrugInteractionService.InteractionSeverity) -> Color {
        switch severity {
        case .minor: return MCColors.warning
        case .moderate: return Color(hex: "FF6B6B")
        case .major: return MCColors.error
        case .contraindicated: return Color(hex: "8B0000")
        }
    }

    // MARK: - Notes

    private var notesSection: some View {
        VStack(alignment: .leading, spacing: MCSpacing.xs) {
            sectionLabel("Additional Notes / Advice")
            TextEditor(text: $notesText)
                .font(MCTypography.body)
                .frame(minHeight: 80)
                .padding(MCSpacing.xs)
                .background(MCColors.backgroundLight)
                .clipShape(RoundedRectangle(cornerRadius: MCSpacing.cornerRadius))
                .overlay(
                    RoundedRectangle(cornerRadius: MCSpacing.cornerRadius)
                        .stroke(MCColors.divider, lineWidth: 1)
                )
                .padding(.horizontal, MCSpacing.screenPadding)
        }
    }

    // MARK: - NMC Compliance Info

    private var nmcComplianceInfo: some View {
        MCAccentCard(accent: MCColors.info) {
            VStack(alignment: .leading, spacing: MCSpacing.xs) {
                HStack(spacing: MCSpacing.xs) {
                    Image(systemName: "checkmark.shield.fill")
                        .foregroundStyle(MCColors.info)
                    Text("NMC Compliance")
                        .font(MCTypography.captionBold)
                        .foregroundStyle(MCColors.info)
                }
                VStack(alignment: .leading, spacing: MCSpacing.xxs) {
                    complianceRow(label: "Doctor", value: doctorName)
                    complianceRow(label: "Reg. No.", value: registrationNumber)
                    complianceRow(label: "Qualification", value: qualification)
                    complianceRow(label: "Digital Signature", value: "Placeholder (pending integration)")
                }
                Text("Per NMC Telemedicine Practice Guidelines, 2020")
                    .font(.system(size: 10))
                    .foregroundStyle(MCColors.textTertiary)
            }
        }
        .padding(.horizontal, MCSpacing.screenPadding)
    }

    private func complianceRow(label: String, value: String) -> some View {
        HStack(spacing: MCSpacing.xs) {
            Text(label + ":")
                .font(MCTypography.caption)
                .foregroundStyle(MCColors.textTertiary)
                .frame(width: 90, alignment: .leading)
            Text(value)
                .font(MCTypography.caption)
                .foregroundStyle(MCColors.textSecondary)
        }
    }

    // MARK: - Generate Button

    private var generateButton: some View {
        VStack(spacing: MCSpacing.xs) {
            MCPrimaryButton("Generate & Send", icon: "doc.badge.arrow.up") {
                generatePrescription()
            }
            .disabled(diagnosis.isEmpty || prescriptionDrugs.isEmpty)
            .opacity(diagnosis.isEmpty || prescriptionDrugs.isEmpty ? 0.5 : 1)
            .padding(.horizontal, MCSpacing.screenPadding)

            if diagnosis.isEmpty || prescriptionDrugs.isEmpty {
                Text("Add a diagnosis and at least one medicine to generate")
                    .font(MCTypography.caption)
                    .foregroundStyle(MCColors.textTertiary)
            }
        }
        .padding(.bottom, MCSpacing.lg)
    }

    // MARK: - Drug Search Sheet

    private var drugSearchSheet: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: MCSpacing.md) {
                    // Search
                    MCTextField(label: "Search medicine name", icon: "magnifyingglass", text: $drugSearchQuery)
                        .padding(.horizontal, MCSpacing.screenPadding)

                    // Search results
                    if !drugSearchQuery.isEmpty {
                        let results = IndianDrugDatabase.shared.searchMedicines(query: drugSearchQuery)
                        if results.isEmpty {
                            Text("No results found")
                                .font(MCTypography.callout)
                                .foregroundStyle(MCColors.textTertiary)
                                .padding(.top, MCSpacing.lg)
                        } else {
                            VStack(spacing: MCSpacing.xs) {
                                ForEach(results.prefix(10)) { drug in
                                    Button {
                                        selectedDrug = drug
                                        drugDosage = drug.commonDosages.first ?? ""
                                        drugSearchQuery = drug.brandName
                                    } label: {
                                        HStack(spacing: MCSpacing.sm) {
                                            VStack(alignment: .leading, spacing: MCSpacing.xxs) {
                                                Text(drug.brandName)
                                                    .font(MCTypography.headline)
                                                    .foregroundStyle(MCColors.textPrimary)
                                                Text(drug.genericName)
                                                    .font(MCTypography.caption)
                                                    .foregroundStyle(MCColors.textSecondary)
                                                Text(drug.saltComposition)
                                                    .font(.system(size: 10))
                                                    .foregroundStyle(MCColors.textTertiary)
                                                    .lineLimit(1)
                                            }
                                            Spacer()
                                            if drug.isScheduleH {
                                                MCBadge("Sch H", color: MCColors.warning)
                                            }
                                            Image(systemName: selectedDrug?.id == drug.id ? "checkmark.circle.fill" : "circle")
                                                .foregroundStyle(selectedDrug?.id == drug.id ? MCColors.primaryTeal : MCColors.textTertiary)
                                        }
                                        .padding(.vertical, MCSpacing.xs)
                                    }
                                    Divider()
                                }
                            }
                            .padding(.horizontal, MCSpacing.screenPadding)
                        }
                    }

                    // Drug entry form (shown when a drug is selected or user types name)
                    if selectedDrug != nil || !drugSearchQuery.isEmpty {
                        Divider()
                            .padding(.horizontal, MCSpacing.screenPadding)

                        VStack(spacing: MCSpacing.sm) {
                            // Dosage
                            if let drug = selectedDrug, !drug.commonDosages.isEmpty {
                                VStack(alignment: .leading, spacing: MCSpacing.xxs) {
                                    Text("Dosage")
                                        .font(MCTypography.subheadline)
                                        .foregroundStyle(MCColors.textSecondary)
                                    ScrollView(.horizontal, showsIndicators: false) {
                                        HStack(spacing: MCSpacing.xs) {
                                            ForEach(drug.commonDosages, id: \.self) { dose in
                                                Button {
                                                    drugDosage = dose
                                                } label: {
                                                    Text(dose)
                                                        .font(MCTypography.captionBold)
                                                        .foregroundStyle(drugDosage == dose ? .white : MCColors.primaryTeal)
                                                        .padding(.horizontal, MCSpacing.sm)
                                                        .padding(.vertical, MCSpacing.xs)
                                                        .background(drugDosage == dose ? MCColors.primaryTeal : MCColors.primaryTeal.opacity(0.1))
                                                        .clipShape(Capsule())
                                                }
                                            }
                                        }
                                    }
                                }
                                .padding(.horizontal, MCSpacing.screenPadding)
                            } else {
                                MCTextField(label: "Dosage (e.g. 500mg)", icon: "scalemass", text: $drugDosage)
                                    .padding(.horizontal, MCSpacing.screenPadding)
                            }

                            // Dose form
                            VStack(alignment: .leading, spacing: MCSpacing.xxs) {
                                Text("Form")
                                    .font(MCTypography.subheadline)
                                    .foregroundStyle(MCColors.textSecondary)
                                ScrollView(.horizontal, showsIndicators: false) {
                                    HStack(spacing: MCSpacing.xs) {
                                        ForEach([DoseForm.tablet, .capsule, .syrup, .injection, .drops, .inhaler], id: \.self) { form in
                                            Button {
                                                drugDoseForm = form
                                            } label: {
                                                HStack(spacing: 4) {
                                                    Image(systemName: form.icon)
                                                        .font(.system(size: 11))
                                                    Text(form.rawValue)
                                                        .font(MCTypography.captionBold)
                                                }
                                                .foregroundStyle(drugDoseForm == form ? .white : MCColors.textPrimary)
                                                .padding(.horizontal, MCSpacing.sm)
                                                .padding(.vertical, MCSpacing.xs)
                                                .background(drugDoseForm == form ? MCColors.primaryTeal : MCColors.backgroundLight)
                                                .clipShape(Capsule())
                                            }
                                        }
                                    }
                                }
                            }
                            .padding(.horizontal, MCSpacing.screenPadding)

                            // Frequency
                            VStack(alignment: .leading, spacing: MCSpacing.xxs) {
                                Text("Frequency")
                                    .font(MCTypography.subheadline)
                                    .foregroundStyle(MCColors.textSecondary)
                                ScrollView(.horizontal, showsIndicators: false) {
                                    HStack(spacing: MCSpacing.xs) {
                                        ForEach([MedicineFrequency.onceDaily, .twiceDaily, .thriceDaily, .asNeeded], id: \.self) { freq in
                                            Button {
                                                drugFrequency = freq
                                            } label: {
                                                Text(freq.rawValue)
                                                    .font(MCTypography.captionBold)
                                                    .foregroundStyle(drugFrequency == freq ? .white : MCColors.textPrimary)
                                                    .padding(.horizontal, MCSpacing.sm)
                                                    .padding(.vertical, MCSpacing.xs)
                                                    .background(drugFrequency == freq ? MCColors.primaryTeal : MCColors.backgroundLight)
                                                    .clipShape(Capsule())
                                            }
                                        }
                                    }
                                }
                            }
                            .padding(.horizontal, MCSpacing.screenPadding)

                            // Duration
                            MCTextField(label: "Duration (e.g. 7 days, 2 weeks)", icon: "calendar", text: $drugDuration)
                                .padding(.horizontal, MCSpacing.screenPadding)

                            // Meal timing
                            VStack(alignment: .leading, spacing: MCSpacing.xxs) {
                                Text("Meal Timing")
                                    .font(MCTypography.subheadline)
                                    .foregroundStyle(MCColors.textSecondary)
                                ScrollView(.horizontal, showsIndicators: false) {
                                    HStack(spacing: MCSpacing.xs) {
                                        ForEach(MealTiming.allCases, id: \.self) { timing in
                                            Button {
                                                drugMealTiming = timing
                                            } label: {
                                                HStack(spacing: 4) {
                                                    Image(systemName: timing.icon)
                                                        .font(.system(size: 11))
                                                    Text(timing.rawValue)
                                                        .font(MCTypography.captionBold)
                                                }
                                                .foregroundStyle(drugMealTiming == timing ? .white : MCColors.textPrimary)
                                                .padding(.horizontal, MCSpacing.sm)
                                                .padding(.vertical, MCSpacing.xs)
                                                .background(drugMealTiming == timing ? MCColors.primaryTeal : MCColors.backgroundLight)
                                                .clipShape(Capsule())
                                            }
                                        }
                                    }
                                }
                            }
                            .padding(.horizontal, MCSpacing.screenPadding)

                            // Special instructions
                            MCTextField(label: "Special instructions (optional)", icon: "text.bubble", text: $drugInstructions)
                                .padding(.horizontal, MCSpacing.screenPadding)

                            // Drug schedule classification preview
                            if let drug = selectedDrug {
                                let schedule = drugScheduleService.classifyDrug(genericName: drug.genericName)
                                if schedule != .listA {
                                    MCAccentCard(accent: scheduleColor(schedule)) {
                                        HStack(spacing: MCSpacing.xs) {
                                            Image(systemName: schedule == .listC ? "xmark.octagon.fill" : "exclamationmark.triangle.fill")
                                                .foregroundStyle(scheduleColor(schedule))
                                            VStack(alignment: .leading, spacing: MCSpacing.xxs) {
                                                Text("\(schedule.rawValue) Drug")
                                                    .font(MCTypography.captionBold)
                                                    .foregroundStyle(scheduleColor(schedule))
                                                Text(drugScheduleService.getWarning(genericName: drug.genericName) ?? "")
                                                    .font(.system(size: 10))
                                                    .foregroundStyle(MCColors.textSecondary)
                                            }
                                        }
                                    }
                                    .padding(.horizontal, MCSpacing.screenPadding)
                                }
                            }

                            // Add button
                            MCPrimaryButton("Add to Prescription", icon: "plus.circle") {
                                addDrugToPrescription()
                            }
                            .disabled(drugSearchQuery.isEmpty || drugDosage.isEmpty || drugDuration.isEmpty)
                            .opacity(drugSearchQuery.isEmpty || drugDosage.isEmpty || drugDuration.isEmpty ? 0.5 : 1)
                            .padding(.horizontal, MCSpacing.screenPadding)
                        }
                    }
                }
                .padding(.vertical, MCSpacing.md)
            }
            .background(MCColors.backgroundLight)
            .navigationTitle("Add Medicine")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { showingDrugSearch = false }
                }
            }
        }
    }

    // MARK: - Generated Prescription Sheet

    private var generatedPrescriptionSheet: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: MCSpacing.md) {
                    MCCard {
                        Text(generatedPrescriptionText)
                            .font(.system(size: 12, design: .monospaced))
                            .foregroundStyle(MCColors.textPrimary)
                    }
                    .padding(.horizontal, MCSpacing.screenPadding)

                    HStack(spacing: MCSpacing.sm) {
                        MCSecondaryButton("Copy", icon: "doc.on.doc") {
                            UIPasteboard.general.string = generatedPrescriptionText
                        }
                        MCPrimaryButton("Share", icon: "square.and.arrow.up") {
                            // Placeholder for share action
                        }
                    }
                    .padding(.horizontal, MCSpacing.screenPadding)
                }
                .padding(.vertical, MCSpacing.md)
            }
            .background(MCColors.backgroundLight)
            .navigationTitle("Generated Prescription")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") {
                        showingGeneratedPrescription = false
                        dismiss()
                    }
                }
            }
        }
    }

    // MARK: - Actions

    private func addDrugToPrescription() {
        let drugName = selectedDrug?.brandName ?? drugSearchQuery
        let genericName = selectedDrug?.genericName
        let schedule = selectedDrug.map { drugScheduleService.classifyDrug(genericName: $0.genericName) }
        let scheduleWarning: String? = {
            guard let s = schedule, s != .listA else { return nil }
            return drugScheduleService.getWarning(genericName: genericName ?? drugName)
        }()

        let entry = PrescriptionEntry(
            drugName: drugName,
            genericName: genericName,
            dosage: drugDosage,
            doseForm: drugDoseForm.rawValue,
            frequency: drugFrequency.rawValue,
            duration: drugDuration,
            mealTiming: drugMealTiming.rawValue,
            instructions: drugInstructions.isEmpty ? nil : drugInstructions,
            schedule: schedule,
            scheduleWarning: scheduleWarning
        )

        withAnimation {
            prescriptionDrugs.append(entry)
        }

        recheckInteractions()
        showingDrugSearch = false
    }

    private func recheckInteractions() {
        let names = prescriptionDrugs.map { $0.genericName ?? $0.drugName }
        interactionAlerts = interactionService.checkInteractions(medicines: names)
    }

    private func resetDrugEntryFields() {
        drugSearchQuery = ""
        selectedDrug = nil
        drugDosage = ""
        drugFrequency = .onceDaily
        drugDuration = ""
        drugMealTiming = .afterMeal
        drugDoseForm = .tablet
        drugInstructions = ""
    }

    private func generatePrescription() {
        let doctorInfo = EPrescriptionService.DoctorInfo(
            fullName: doctorName.replacingOccurrences(of: "Dr. ", with: ""),
            registrationNumber: registrationNumber,
            qualification: qualification,
            specialization: "General Medicine",
            clinicName: "MedCare Virtual Clinic",
            clinicAddress: nil,
            contactNumber: nil,
            email: nil
        )

        let patientDemo = EPrescriptionService.PatientDemographics(
            fullName: patient.name,
            age: patient.age,
            gender: "Not specified",
            patientId: patient.id,
            contactNumber: nil,
            address: nil,
            knownAllergies: [],
            existingConditions: [patient.primaryCondition]
        )

        let rxDrugs = prescriptionDrugs.map { entry in
            EPrescriptionService.PrescriptionDrug(
                brandName: entry.drugName,
                genericName: entry.genericName,
                dosage: entry.dosage,
                doseForm: entry.doseForm,
                frequency: entry.frequency,
                duration: entry.duration,
                mealTiming: entry.mealTiming,
                instructions: entry.instructions
            )
        }

        if let prescription = prescriptionService.generateNMCCompliantPrescription(
            doctor: doctorInfo,
            patient: patientDemo,
            diagnosis: diagnosis,
            drugs: rxDrugs,
            generalAdvice: notesText.isEmpty ? nil : notesText,
            isTelemedicine: true
        ) {
            generatedPrescriptionText = prescriptionService.formatPrescription(prescription)
            showingGeneratedPrescription = true
        }
    }

    // MARK: - Helpers

    private func sectionLabel(_ title: String) -> some View {
        HStack(spacing: MCSpacing.xs) {
            Text(title.uppercased())
                .font(MCTypography.sectionHeader)
                .foregroundStyle(MCColors.textSecondary)
                .kerning(1.2)
        }
        .padding(.horizontal, MCSpacing.screenPadding)
    }
}

// MARK: - Prescription Entry Model

struct PrescriptionEntry: Identifiable {
    let id = UUID()
    let drugName: String
    let genericName: String?
    let dosage: String
    let doseForm: String
    let frequency: String
    let duration: String
    let mealTiming: String
    let instructions: String?
    let schedule: DrugScheduleService.DrugSchedule?
    let scheduleWarning: String?
}

#Preview {
    EPrescriptionView(patient: DoctorPatientData(
        id: UUID(),
        name: "Preview Patient",
        age: 45,
        avatarEmoji: "\u{1F468}",
        primaryCondition: "Hypertension",
        status: .warning,
        lastVitalLabel: "BP",
        lastVitalValue: "142/92",
        lastVitalTime: "2h ago",
        adherencePercent: 68,
        heartRate: 82,
        bpSystolic: 142,
        bpDiastolic: 92,
        spO2: 97,
        glucose: 110,
        hrTrend: .stable,
        bpTrend: .up,
        spO2Trend: .stable,
        glucoseTrend: .stable,
        medications: [],
        recentSymptoms: [],
        dailyAdherence7Days: [100, 67, 100, 33, 100, 67, 100]
    ))
}
