import SwiftUI

struct ConfirmationView: View {
    let extractionResult: AIExtractionService.ExtractionResult
    let episodeTitle: String
    @Environment(\.dismiss) private var dismiss
    @Environment(DataService.self) private var dataService
    @State private var editingMedicineIndex: Int?
    @State private var showDisclaimer = true
    @State private var confirmed = false
    @State private var includedMedicines: Set<UUID>
    @State private var editedMedicines: [UUID: EditableMedicine]
    @State private var hasReviewed = false

    struct EditableMedicine {
        var brandName: String
        var dosage: String
        var frequency: String
    }

    init(extractionResult: AIExtractionService.ExtractionResult, episodeTitle: String) {
        self.extractionResult = extractionResult
        self.episodeTitle = episodeTitle
        // All medicines included by default
        let ids = Set(extractionResult.medicines.map { $0.id })
        _includedMedicines = State(initialValue: ids)
        _editedMedicines = State(initialValue: [:])
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: MCSpacing.lg) {
                    // Disclaimer banner
                    if showDisclaimer {
                        disclaimerBanner
                    }

                    // Overall confidence
                    overallConfidenceCard

                    // Doctor & Diagnosis
                    doctorInfoCard

                    // Medicines with validation
                    medicinesSection

                    // Tasks
                    tasksSection

                    // Confirm button
                    confirmSection
                }
                .padding(.horizontal, MCSpacing.screenPadding)
                .padding(.vertical, MCSpacing.md)
            }
            .background(MCColors.backgroundLight)
            .navigationTitle("Review & Confirm")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
            .sheet(item: $editingMedicineIndex) { index in
                if index < extractionResult.medicines.count {
                    let medicine = extractionResult.medicines[index]
                    let edited = editedMedicines[medicine.id]
                    MedicineEditSheet(
                        brandName: edited?.brandName ?? medicine.brandName.value,
                        dosage: edited?.dosage ?? medicine.dosage.value,
                        frequency: edited?.frequency ?? medicine.frequency.value
                    ) { name, dosage, frequency in
                        editedMedicines[medicine.id] = EditableMedicine(
                            brandName: name,
                            dosage: dosage,
                            frequency: frequency
                        )
                        hasReviewed = true
                    }
                }
            }
        }
    }

    // MARK: - Disclaimer

    private var disclaimerBanner: some View {
        MCAccentCard(accent: MCColors.warning) {
            VStack(alignment: .leading, spacing: MCSpacing.xs) {
                HStack {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundStyle(MCColors.warning)
                    Text("Important Medical Disclaimer")
                        .font(MCTypography.bodyMedium)
                        .foregroundStyle(MCColors.textPrimary)
                    Spacer()
                    Button {
                        withAnimation { showDisclaimer = false }
                    } label: {
                        Image(systemName: "xmark")
                            .foregroundStyle(MCColors.textTertiary)
                    }
                }

                Text("AI extraction is for convenience only. Always verify with your actual prescription. This app does NOT provide medical advice or diagnosis.")
                    .font(MCTypography.footnote)
                    .foregroundStyle(MCColors.textSecondary)

                HStack {
                    Image(systemName: "paintbrush.pointed")
                        .font(.system(size: 10))
                    Text("Tap any medicine to edit its details")
                        .font(MCTypography.caption)
                }
                .foregroundStyle(MCColors.warning)
            }
        }
    }

    // MARK: - Overall Confidence

    private var overallConfidenceCard: some View {
        MCCard {
            HStack {
                VStack(alignment: .leading, spacing: MCSpacing.xxs) {
                    Text("AI Extraction Confidence")
                        .font(MCTypography.subheadline)
                        .foregroundStyle(MCColors.textSecondary)
                    Text("\(Int(extractionResult.overallConfidence * 100))% Overall")
                        .font(MCTypography.title2)
                        .foregroundStyle(MCColors.confidenceColor(extractionResult.overallConfidence))
                }

                Spacer()

                ZStack {
                    Circle()
                        .stroke(MCColors.backgroundLight, lineWidth: 6)
                        .frame(width: 60, height: 60)

                    Circle()
                        .trim(from: 0, to: extractionResult.overallConfidence)
                        .stroke(
                            MCColors.confidenceColor(extractionResult.overallConfidence),
                            style: StrokeStyle(lineWidth: 6, lineCap: .round)
                        )
                        .frame(width: 60, height: 60)
                        .rotationEffect(.degrees(-90))

                    Text("\(Int(extractionResult.overallConfidence * 100))")
                        .font(MCTypography.captionBold)
                }
            }
        }
    }

    // MARK: - Doctor Info

    private var doctorInfoCard: some View {
        MCCard {
            VStack(alignment: .leading, spacing: MCSpacing.sm) {
                Text("Prescription Details")
                    .font(MCTypography.headline)
                    .foregroundStyle(MCColors.textPrimary)

                ConfirmationField(
                    label: "Doctor",
                    value: extractionResult.doctorName.value,
                    confidence: extractionResult.doctorName.confidence,
                    icon: "stethoscope"
                )

                Divider()

                ConfirmationField(
                    label: "Hospital",
                    value: extractionResult.hospitalName.value,
                    confidence: extractionResult.hospitalName.confidence,
                    icon: "building.2"
                )

                Divider()

                ConfirmationField(
                    label: "Diagnosis",
                    value: extractionResult.diagnosis.value,
                    confidence: extractionResult.diagnosis.confidence,
                    icon: "heart.text.clipboard"
                )
            }
        }
    }

    // MARK: - Medicines with Validation UI

    private var medicinesSection: some View {
        VStack(alignment: .leading, spacing: MCSpacing.sm) {
            HStack {
                Text("Medicines (\(includedMedicines.count) of \(extractionResult.medicines.count) selected)")
                    .font(MCTypography.headline)
                    .foregroundStyle(MCColors.textPrimary)
                Spacer()
            }

            ForEach(Array(extractionResult.medicines.enumerated()), id: \.element.id) { index, medicine in
                let isIncluded = includedMedicines.contains(medicine.id)
                let edited = editedMedicines[medicine.id]

                ValidatedMedicineCard(
                    medicine: medicine,
                    index: index + 1,
                    isIncluded: isIncluded,
                    editedName: edited?.brandName,
                    editedDosage: edited?.dosage,
                    editedFrequency: edited?.frequency,
                    onToggleInclude: {
                        withAnimation {
                            if includedMedicines.contains(medicine.id) {
                                includedMedicines.remove(medicine.id)
                            } else {
                                includedMedicines.insert(medicine.id)
                            }
                            hasReviewed = true
                        }
                    },
                    onEdit: {
                        editingMedicineIndex = index
                    }
                )
            }
        }
    }

    // MARK: - Tasks

    private var tasksSection: some View {
        Group {
            if !extractionResult.tasks.isEmpty {
                VStack(alignment: .leading, spacing: MCSpacing.sm) {
                    Text("Care Tasks")
                        .font(MCTypography.headline)
                        .foregroundStyle(MCColors.textPrimary)

                    ForEach(extractionResult.tasks) { task in
                        MCCard {
                            HStack {
                                Image(systemName: task.taskType.icon)
                                    .foregroundStyle(MCColors.primaryTeal)

                                VStack(alignment: .leading) {
                                    Text(task.title)
                                        .font(MCTypography.bodyMedium)
                                    if let due = task.dueDate {
                                        Text(due, style: .date)
                                            .font(MCTypography.caption)
                                            .foregroundStyle(MCColors.textSecondary)
                                    }
                                }

                                Spacer()

                                MCConfidenceBadge(score: task.confidence)
                            }
                        }
                    }
                }
            }
        }
    }

    // MARK: - Confirm Section

    private var confirmSection: some View {
        VStack(spacing: MCSpacing.md) {
            // Warning about low confidence
            let lowConfMeds = extractionResult.medicines
                .filter { includedMedicines.contains($0.id) && $0.hasLowConfidenceField && editedMedicines[$0.id] == nil }
            if !lowConfMeds.isEmpty {
                HStack(spacing: MCSpacing.xs) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundStyle(MCColors.warning)
                    Text("\(lowConfMeds.count) medicine(s) have fields that need verification")
                        .font(MCTypography.footnote)
                        .foregroundStyle(MCColors.warning)
                }
                .padding(MCSpacing.sm)
                .background(MCColors.warning.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: MCSpacing.cornerRadiusSmall))
            }

            if !hasReviewed {
                HStack(spacing: MCSpacing.xs) {
                    Image(systemName: "eye")
                        .foregroundStyle(MCColors.info)
                    Text("Please review the medicines above before confirming")
                        .font(MCTypography.footnote)
                        .foregroundStyle(MCColors.info)
                }
                .padding(MCSpacing.sm)
                .background(MCColors.info.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: MCSpacing.cornerRadiusSmall))
            }

            MCPrimaryButton("Confirm & Save", icon: "checkmark.shield") {
                confirmAndCreatePlan()
            }
            .disabled(!hasReviewed || includedMedicines.isEmpty)
            .opacity((!hasReviewed || includedMedicines.isEmpty) ? 0.5 : 1)

            if !hasReviewed {
                Button("I've reviewed — enable confirm") {
                    hasReviewed = true
                }
                .font(MCTypography.footnote)
                .foregroundStyle(MCColors.primaryTeal)
            }

            Text("By confirming, you verify that the extracted data matches your prescription")
                .font(MCTypography.caption)
                .foregroundStyle(MCColors.textTertiary)
                .multilineTextAlignment(.center)
        }
        .padding(.vertical, MCSpacing.md)
    }

    private func confirmAndCreatePlan() {
        // Create episode and add medicines
        // In production this would call POST /episodes/:id/confirm
        dismiss()
    }
}

// MARK: - Validated Medicine Card

struct ValidatedMedicineCard: View {
    let medicine: AIExtractionService.MedicineExtraction
    let index: Int
    let isIncluded: Bool
    let editedName: String?
    let editedDosage: String?
    let editedFrequency: String?
    let onToggleInclude: () -> Void
    let onEdit: () -> Void

    private var confidence: Double { medicine.overallConfidence }

    private var confidenceLevel: (color: Color, label: String) {
        if confidence > 0.85 {
            return (MCColors.success, "High confidence")
        } else if confidence >= 0.60 {
            return (MCColors.warning, "Review recommended")
        } else {
            return (MCColors.error, "Low confidence — please verify")
        }
    }

    var body: some View {
        MCCard {
            VStack(alignment: .leading, spacing: MCSpacing.sm) {
                // Header with include checkbox
                HStack {
                    Button(action: onToggleInclude) {
                        Image(systemName: isIncluded ? "checkmark.square.fill" : "square")
                            .font(.system(size: 20))
                            .foregroundStyle(isIncluded ? MCColors.primaryTeal : MCColors.textTertiary)
                    }

                    Text("#\(index)")
                        .font(MCTypography.captionBold)
                        .foregroundStyle(.white)
                        .frame(width: 24, height: 24)
                        .background(MCColors.primaryTeal)
                        .clipShape(Circle())

                    Text(editedName ?? medicine.brandName.value)
                        .font(MCTypography.bodyMedium)
                        .foregroundStyle(isIncluded ? MCColors.textPrimary : MCColors.textTertiary)
                        .strikethrough(!isIncluded)

                    Spacer()

                    Button(action: onEdit) {
                        HStack(spacing: 2) {
                            Image(systemName: "pencil")
                                .font(.system(size: 11))
                            Text("Edit")
                                .font(MCTypography.caption)
                        }
                        .foregroundStyle(MCColors.primaryTeal)
                        .padding(.horizontal, MCSpacing.xs)
                        .padding(.vertical, 4)
                        .background(MCColors.primaryTeal.opacity(0.1))
                        .clipShape(Capsule())
                    }
                }

                // Confidence bar
                VStack(alignment: .leading, spacing: MCSpacing.xxs) {
                    HStack {
                        Text(confidenceLevel.label)
                            .font(MCTypography.caption)
                            .foregroundStyle(confidenceLevel.color)
                        Spacer()
                        Text("\(Int(confidence * 100))%")
                            .font(MCTypography.captionBold)
                            .foregroundStyle(confidenceLevel.color)
                    }

                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            RoundedRectangle(cornerRadius: 3)
                                .fill(MCColors.backgroundLight)
                                .frame(height: 6)

                            RoundedRectangle(cornerRadius: 3)
                                .fill(confidenceLevel.color)
                                .frame(width: geo.size.width * confidence, height: 6)
                        }
                    }
                    .frame(height: 6)
                }

                if isIncluded {
                    // Fields
                    VStack(spacing: MCSpacing.xxs) {
                        medicineField("Generic", medicine.genericName)
                        medicineField("Dosage", editedDosage != nil
                            ? AIExtractionService.FieldResult(value: editedDosage!, confidence: 1.0)
                            : medicine.dosage)
                        medicineField("Frequency", editedFrequency != nil
                            ? AIExtractionService.FieldResult(value: editedFrequency!, confidence: 1.0)
                            : medicine.frequency)
                        medicineField("Timing", medicine.timing)
                        medicineField("Duration", medicine.duration)
                        medicineField("Instructions", medicine.instructions)
                    }

                    // Footer info
                    HStack(spacing: MCSpacing.md) {
                        if !medicine.manufacturer.value.isEmpty {
                            Label(medicine.manufacturer.value, systemImage: "building.2")
                                .font(MCTypography.caption)
                                .foregroundStyle(MCColors.textSecondary)
                        }
                        if !medicine.mrp.value.isEmpty {
                            Label(medicine.mrp.value, systemImage: "indianrupeesign")
                                .font(MCTypography.caption)
                                .foregroundStyle(MCColors.textSecondary)
                        }
                    }
                }
            }
        }
        .opacity(isIncluded ? 1.0 : 0.6)
        .overlay(
            medicine.hasLowConfidenceField && isIncluded && editedName == nil
                ? RoundedRectangle(cornerRadius: MCSpacing.cornerRadius)
                    .stroke(MCColors.warning, lineWidth: 1.5)
                : nil
        )
    }

    private func medicineField(_ label: String, _ field: AIExtractionService.FieldResult) -> some View {
        HStack {
            Text(label)
                .font(MCTypography.caption)
                .foregroundStyle(MCColors.textTertiary)
                .frame(width: 80, alignment: .leading)

            Text(field.value)
                .font(MCTypography.footnote)
                .foregroundStyle(MCColors.textPrimary)

            Spacer()

            if field.isLowConfidence {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.system(size: 10))
                    .foregroundStyle(MCColors.warning)
            }
        }
        .padding(.vertical, 2)
        .background(field.isLowConfidence ? MCColors.warning.opacity(0.06) : Color.clear)
    }
}

// MARK: - Medicine Edit Sheet

struct MedicineEditSheet: View {
    @Environment(\.dismiss) private var dismiss
    @State var brandName: String
    @State var dosage: String
    @State var frequency: String
    let onSave: (String, String, String) -> Void

    init(brandName: String, dosage: String, frequency: String, onSave: @escaping (String, String, String) -> Void) {
        _brandName = State(initialValue: brandName)
        _dosage = State(initialValue: dosage)
        _frequency = State(initialValue: frequency)
        self.onSave = onSave
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: MCSpacing.lg) {
                MCTextField(label: "Medicine Name", icon: "pills", text: $brandName)
                MCTextField(label: "Dosage", icon: "scalemass", text: $dosage)
                MCTextField(label: "Frequency", icon: "clock", text: $frequency)

                Spacer()

                MCPrimaryButton("Save Changes", icon: "checkmark") {
                    onSave(brandName, dosage, frequency)
                    dismiss()
                }
                .disabled(brandName.isEmpty || dosage.isEmpty)
            }
            .padding(MCSpacing.screenPadding)
            .background(MCColors.backgroundLight)
            .navigationTitle("Edit Medicine")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
        .presentationDetents([.medium])
    }
}

// MARK: - Int Identifiable for sheet binding

extension Int: @retroactive Identifiable {
    public var id: Int { self }
}

// MARK: - Subviews

struct ConfirmationField: View {
    let label: String
    let value: String
    let confidence: Double
    let icon: String

    var body: some View {
        HStack(spacing: MCSpacing.sm) {
            Image(systemName: icon)
                .foregroundStyle(MCColors.textSecondary)
                .frame(width: 24)

            VStack(alignment: .leading, spacing: 2) {
                Text(label)
                    .font(MCTypography.caption)
                    .foregroundStyle(MCColors.textTertiary)
                Text(value)
                    .font(MCTypography.body)
                    .foregroundStyle(MCColors.textPrimary)
            }

            Spacer()

            MCConfidenceBadge(score: confidence)
        }
        .padding(.vertical, MCSpacing.xxs)
        .background(
            confidence < 0.70
                ? MCColors.warning.opacity(0.08)
                : Color.clear
        )
        .clipShape(RoundedRectangle(cornerRadius: 4))
    }
}
