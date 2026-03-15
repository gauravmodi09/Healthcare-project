import SwiftUI

struct SymptomLogView: View {
    let episodeId: UUID
    @Environment(\.dismiss) private var dismiss
    @Environment(DataService.self) private var dataService
    @State private var selectedFeeling: FeelingLevel = .okay
    @State private var symptoms: [SymptomEntry] = []
    @State private var symptomInput = ""
    @State private var selectedSeverity: SeverityLevel = .mild
    @State private var temperature = ""
    @State private var bpSystolic = ""
    @State private var bpDiastolic = ""
    @State private var notes = ""

    private let commonSymptoms = [
        "Headache", "Fever", "Cough", "Cold", "Fatigue",
        "Nausea", "Body Pain", "Dizziness", "Sore Throat",
        "Breathlessness", "Diarrhea", "Loss of Appetite"
    ]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: MCSpacing.lg) {
                    // How are you feeling
                    feelingSection

                    // Symptoms
                    symptomsSection

                    // Vitals
                    vitalsSection

                    // Notes
                    notesSection

                    // Save
                    MCPrimaryButton("Save Log", icon: "checkmark") {
                        saveLog()
                    }
                }
                .padding(.horizontal, MCSpacing.screenPadding)
                .padding(.vertical, MCSpacing.md)
            }
            .background(MCColors.backgroundLight)
            .navigationTitle("Daily Check-in")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }

    // MARK: - Feeling Section

    private var feelingSection: some View {
        VStack(alignment: .leading, spacing: MCSpacing.sm) {
            Text("How are you feeling today?")
                .font(MCTypography.headline)

            HStack(spacing: MCSpacing.md) {
                ForEach(FeelingLevel.allCases, id: \.self) { level in
                    Button {
                        selectedFeeling = level
                    } label: {
                        VStack(spacing: MCSpacing.xxs) {
                            Text(level.emoji)
                                .font(.system(size: selectedFeeling == level ? 40 : 32))
                            Text(level.label)
                                .font(MCTypography.caption)
                                .foregroundStyle(selectedFeeling == level ? MCColors.primaryTeal : MCColors.textTertiary)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, MCSpacing.xs)
                        .background(selectedFeeling == level ? MCColors.primaryTeal.opacity(0.1) : Color.clear)
                        .clipShape(RoundedRectangle(cornerRadius: MCSpacing.cornerRadiusSmall))
                    }
                }
            }
        }
    }

    // MARK: - Symptoms Section

    private var symptomsSection: some View {
        VStack(alignment: .leading, spacing: MCSpacing.sm) {
            Text("Any symptoms?")
                .font(MCTypography.headline)

            // Common symptom quick-add
            FlowLayout(spacing: MCSpacing.xs) {
                ForEach(commonSymptoms, id: \.self) { symptom in
                    let isSelected = symptoms.contains { $0.name == symptom }
                    Button {
                        if isSelected {
                            symptoms.removeAll { $0.name == symptom }
                        } else {
                            symptoms.append(SymptomEntry(name: symptom, severity: selectedSeverity))
                        }
                    } label: {
                        Text(symptom)
                            .font(MCTypography.footnote)
                            .foregroundStyle(isSelected ? .white : MCColors.textPrimary)
                            .padding(.horizontal, MCSpacing.sm)
                            .padding(.vertical, MCSpacing.xs)
                            .background(isSelected ? MCColors.primaryTeal : MCColors.backgroundLight)
                            .clipShape(Capsule())
                    }
                }
            }

            // Custom symptom input
            HStack {
                TextField("Add custom symptom", text: $symptomInput)
                    .font(MCTypography.body)
                    .padding(.horizontal, MCSpacing.sm)
                    .frame(height: 40)
                    .background(MCColors.backgroundLight)
                    .clipShape(RoundedRectangle(cornerRadius: 8))

                if !symptomInput.isEmpty {
                    Button {
                        symptoms.append(SymptomEntry(name: symptomInput, severity: selectedSeverity))
                        symptomInput = ""
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 24))
                            .foregroundStyle(MCColors.primaryTeal)
                    }
                }
            }

            // Severity picker
            if !symptoms.isEmpty {
                VStack(alignment: .leading, spacing: MCSpacing.xs) {
                    Text("Severity")
                        .font(MCTypography.subheadline)
                        .foregroundStyle(MCColors.textSecondary)

                    HStack(spacing: MCSpacing.xs) {
                        ForEach(SeverityLevel.allCases, id: \.self) { level in
                            Button {
                                selectedSeverity = level
                                // Update all symptoms to this severity
                                symptoms = symptoms.map {
                                    SymptomEntry(name: $0.name, severity: level)
                                }
                            } label: {
                                Text(level.label)
                                    .font(MCTypography.caption)
                                    .foregroundStyle(selectedSeverity == level ? .white : Color(hex: level.color))
                                    .padding(.horizontal, MCSpacing.sm)
                                    .padding(.vertical, MCSpacing.xs)
                                    .background(selectedSeverity == level ? Color(hex: level.color) : Color(hex: level.color).opacity(0.1))
                                    .clipShape(Capsule())
                            }
                        }
                    }
                }
            }
        }
    }

    // MARK: - Vitals Section

    private var vitalsSection: some View {
        VStack(alignment: .leading, spacing: MCSpacing.sm) {
            Text("Vitals (optional)")
                .font(MCTypography.headline)

            HStack(spacing: MCSpacing.sm) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Temp (F)")
                        .font(MCTypography.caption)
                        .foregroundStyle(MCColors.textSecondary)
                    TextField("98.6", text: $temperature)
                        .keyboardType(.decimalPad)
                        .font(MCTypography.body)
                        .padding(.horizontal, MCSpacing.sm)
                        .frame(height: 40)
                        .background(MCColors.backgroundLight)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text("BP Systolic")
                        .font(MCTypography.caption)
                        .foregroundStyle(MCColors.textSecondary)
                    TextField("120", text: $bpSystolic)
                        .keyboardType(.numberPad)
                        .font(MCTypography.body)
                        .padding(.horizontal, MCSpacing.sm)
                        .frame(height: 40)
                        .background(MCColors.backgroundLight)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text("BP Diastolic")
                        .font(MCTypography.caption)
                        .foregroundStyle(MCColors.textSecondary)
                    TextField("80", text: $bpDiastolic)
                        .keyboardType(.numberPad)
                        .font(MCTypography.body)
                        .padding(.horizontal, MCSpacing.sm)
                        .frame(height: 40)
                        .background(MCColors.backgroundLight)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                }
            }
        }
    }

    // MARK: - Notes Section

    private var notesSection: some View {
        VStack(alignment: .leading, spacing: MCSpacing.xs) {
            Text("Notes")
                .font(MCTypography.headline)

            TextEditor(text: $notes)
                .font(MCTypography.body)
                .frame(height: 100)
                .padding(MCSpacing.xs)
                .background(MCColors.backgroundLight)
                .clipShape(RoundedRectangle(cornerRadius: MCSpacing.cornerRadius))
                .scrollContentBackground(.hidden)
        }
    }

    private func saveLog() {
        // Find episode and save
        dismiss()
    }
}
