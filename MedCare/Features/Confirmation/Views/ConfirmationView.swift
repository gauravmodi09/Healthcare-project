import SwiftUI

struct ConfirmationView: View {
    let extractionResult: AIExtractionService.ExtractionResult
    let episodeTitle: String
    @Environment(\.dismiss) private var dismiss
    @Environment(DataService.self) private var dataService
    @State private var editingMedicineIndex: Int?
    @State private var showDisclaimer = true
    @State private var confirmed = false

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

                    // Medicines
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
                    Text("Fields highlighted in amber need your attention")
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

    // MARK: - Medicines

    private var medicinesSection: some View {
        VStack(alignment: .leading, spacing: MCSpacing.sm) {
            HStack {
                Text("Medicines (\(extractionResult.medicines.count))")
                    .font(MCTypography.headline)
                    .foregroundStyle(MCColors.textPrimary)
                Spacer()
            }

            ForEach(Array(extractionResult.medicines.enumerated()), id: \.element.id) { index, medicine in
                MedicineConfirmationCard(medicine: medicine, index: index + 1)
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
            let lowConfMeds = extractionResult.medicines.filter { $0.hasLowConfidenceField }
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

            MCPrimaryButton("Confirm & Start Plan", icon: "checkmark.shield") {
                confirmAndCreatePlan()
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

struct MedicineConfirmationCard: View {
    let medicine: AIExtractionService.MedicineExtraction
    let index: Int

    var body: some View {
        MCCard {
            VStack(alignment: .leading, spacing: MCSpacing.sm) {
                // Header
                HStack {
                    Text("#\(index)")
                        .font(MCTypography.captionBold)
                        .foregroundStyle(.white)
                        .frame(width: 24, height: 24)
                        .background(MCColors.primaryTeal)
                        .clipShape(Circle())

                    Text(medicine.brandName.value)
                        .font(MCTypography.bodyMedium)
                        .foregroundStyle(MCColors.textPrimary)

                    Spacer()

                    MCConfidenceBadge(score: medicine.overallConfidence)
                }

                // Fields
                VStack(spacing: MCSpacing.xxs) {
                    medicineField("Generic", medicine.genericName)
                    medicineField("Dosage", medicine.dosage)
                    medicineField("Frequency", medicine.frequency)
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
        .overlay(
            medicine.hasLowConfidenceField
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
