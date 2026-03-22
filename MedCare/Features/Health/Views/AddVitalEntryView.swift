import SwiftUI

// MARK: - Manual Vital Entry Sheet

struct AddVitalEntryView: View {
    let healthService: HealthKitService
    var onSave: (() -> Void)?

    @Environment(\.dismiss) private var dismiss

    @State private var selectedType: ManualVitalType = .bloodPressure
    @State private var primaryValue: String = ""
    @State private var secondaryValue: String = "" // diastolic for BP
    @State private var selectedDate: Date = Date()
    @State private var notes: String = ""
    @State private var isSaving = false
    @State private var showError = false
    @State private var errorMessage = ""

    enum ManualVitalType: String, CaseIterable, Identifiable {
        case bloodPressure = "Blood Pressure"
        case heartRate = "Heart Rate"
        case spo2 = "SpO2"
        case weight = "Weight"
        case bodyTemperature = "Temperature"
        case bloodGlucose = "Blood Glucose"

        var id: String { rawValue }

        var icon: String {
            switch self {
            case .bloodPressure: return "heart.text.square.fill"
            case .heartRate: return "heart.fill"
            case .spo2: return "lungs.fill"
            case .weight: return "scalemass.fill"
            case .bodyTemperature: return "thermometer.medium"
            case .bloodGlucose: return "drop.fill"
            }
        }

        var color: Color {
            switch self {
            case .bloodPressure: return .red
            case .heartRate: return .red
            case .spo2: return .blue
            case .weight: return MCColors.info
            case .bodyTemperature: return .orange
            case .bloodGlucose: return .purple
            }
        }

        var unit: String {
            switch self {
            case .bloodPressure: return "mmHg"
            case .heartRate: return "BPM"
            case .spo2: return "%"
            case .weight: return "kg"
            case .bodyTemperature: return "\u{00B0}F"
            case .bloodGlucose: return "mg/dL"
            }
        }

        var placeholder: String {
            switch self {
            case .bloodPressure: return "Systolic"
            case .heartRate: return "e.g. 72"
            case .spo2: return "e.g. 98"
            case .weight: return "e.g. 65.5"
            case .bodyTemperature: return "e.g. 98.6"
            case .bloodGlucose: return "e.g. 95"
            }
        }

        var vitalType: VitalType {
            switch self {
            case .bloodPressure: return .bloodPressure
            case .heartRate: return .heartRate
            case .spo2: return .spo2
            case .weight: return .weight
            case .bodyTemperature: return .bodyTemperature
            case .bloodGlucose: return .bloodGlucose
            }
        }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: MCSpacing.lg) {
                    // Type Picker
                    typePicker

                    // Value Input
                    valueInput

                    // Date/Time
                    dateTimePicker

                    // Notes
                    notesField

                    // Save Button
                    saveButton
                }
                .padding(.vertical, MCSpacing.md)
            }
            .background(MCColors.backgroundLight)
            .navigationTitle("Add Vital Entry")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                        .foregroundStyle(MCColors.textSecondary)
                }
            }
            .alert("Error", isPresented: $showError) {
                Button("OK") {}
            } message: {
                Text(errorMessage)
            }
        }
    }

    // MARK: - Type Picker

    private var typePicker: some View {
        VStack(alignment: .leading, spacing: MCSpacing.sm) {
            Text("Vital Type")
                .font(MCTypography.headline)
                .foregroundStyle(MCColors.textPrimary)
                .padding(.horizontal, MCSpacing.screenPadding)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: MCSpacing.xs) {
                    ForEach(ManualVitalType.allCases) { type in
                        Button {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                selectedType = type
                                primaryValue = ""
                                secondaryValue = ""
                            }
                        } label: {
                            VStack(spacing: MCSpacing.xxs) {
                                Image(systemName: type.icon)
                                    .font(.system(size: 20))
                                    .foregroundStyle(selectedType == type ? .white : type.color)
                                    .frame(width: 40, height: 40)
                                    .background(selectedType == type ? type.color : type.color.opacity(0.12))
                                    .clipShape(Circle())

                                Text(type.rawValue)
                                    .font(.system(size: 10, weight: .medium))
                                    .foregroundStyle(selectedType == type ? MCColors.textPrimary : MCColors.textSecondary)
                                    .multilineTextAlignment(.center)
                                    .lineLimit(2)
                            }
                            .frame(width: 72)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, MCSpacing.screenPadding)
            }
        }
    }

    // MARK: - Value Input

    private var valueInput: some View {
        MCCard {
            VStack(alignment: .leading, spacing: MCSpacing.md) {
                HStack(spacing: MCSpacing.xs) {
                    Image(systemName: selectedType.icon)
                        .foregroundStyle(selectedType.color)
                    Text("Enter \(selectedType.rawValue)")
                        .font(MCTypography.bodyMedium)
                        .foregroundStyle(MCColors.textPrimary)
                }

                if selectedType == .bloodPressure {
                    HStack(spacing: MCSpacing.sm) {
                        VStack(alignment: .leading, spacing: MCSpacing.xxs) {
                            Text("Systolic")
                                .font(MCTypography.caption)
                                .foregroundStyle(MCColors.textSecondary)
                            TextField("120", text: $primaryValue)
                                .keyboardType(.numberPad)
                                .font(.system(size: 28, weight: .bold, design: .rounded))
                                .foregroundStyle(MCColors.textPrimary)
                                .padding(MCSpacing.sm)
                                .background(MCColors.backgroundLight)
                                .clipShape(RoundedRectangle(cornerRadius: MCSpacing.cornerRadiusSmall))
                        }

                        Text("/")
                            .font(.system(size: 28, weight: .bold))
                            .foregroundStyle(MCColors.textTertiary)

                        VStack(alignment: .leading, spacing: MCSpacing.xxs) {
                            Text("Diastolic")
                                .font(MCTypography.caption)
                                .foregroundStyle(MCColors.textSecondary)
                            TextField("80", text: $secondaryValue)
                                .keyboardType(.numberPad)
                                .font(.system(size: 28, weight: .bold, design: .rounded))
                                .foregroundStyle(MCColors.textPrimary)
                                .padding(MCSpacing.sm)
                                .background(MCColors.backgroundLight)
                                .clipShape(RoundedRectangle(cornerRadius: MCSpacing.cornerRadiusSmall))
                        }
                    }

                    Text(selectedType.unit)
                        .font(MCTypography.caption)
                        .foregroundStyle(MCColors.textTertiary)
                } else {
                    HStack(alignment: .firstTextBaseline, spacing: MCSpacing.xs) {
                        TextField(selectedType.placeholder, text: $primaryValue)
                            .keyboardType(selectedType == .weight ? .decimalPad : .numberPad)
                            .font(.system(size: 36, weight: .bold, design: .rounded))
                            .foregroundStyle(MCColors.textPrimary)

                        Text(selectedType.unit)
                            .font(MCTypography.subheadline)
                            .foregroundStyle(MCColors.textTertiary)
                    }
                }

                // Contextual hint
                contextualHint
            }
        }
        .padding(.horizontal, MCSpacing.screenPadding)
    }

    @ViewBuilder
    private var contextualHint: some View {
        let hint: String? = {
            switch selectedType {
            case .bloodPressure:
                return "Normal: <120/80 | Elevated: 120-129/<80 | High: 130+/80+"
            case .heartRate:
                return "Normal resting: 60-100 BPM"
            case .spo2:
                return "Normal: 95-100% | Low: <95%"
            case .weight:
                return nil
            case .bodyTemperature:
                return "Normal: 97.0-99.0\u{00B0}F | Fever: >100.4\u{00B0}F"
            case .bloodGlucose:
                return "Normal fasting: 70-100 mg/dL | Pre-diabetic: 100-125"
            }
        }()

        if let hint {
            Text(hint)
                .font(.system(size: 11))
                .foregroundStyle(MCColors.textTertiary)
                .padding(MCSpacing.xs)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(MCColors.primaryTeal.opacity(0.06))
                .clipShape(RoundedRectangle(cornerRadius: MCSpacing.cornerRadiusSmall))
        }
    }

    // MARK: - Date/Time

    private var dateTimePicker: some View {
        MCCard {
            DatePicker(
                "Date & Time",
                selection: $selectedDate,
                in: ...Date(),
                displayedComponents: [.date, .hourAndMinute]
            )
            .font(MCTypography.bodyMedium)
            .foregroundStyle(MCColors.textPrimary)
            .tint(MCColors.primaryTeal)
        }
        .padding(.horizontal, MCSpacing.screenPadding)
    }

    // MARK: - Notes

    private var notesField: some View {
        MCCard {
            VStack(alignment: .leading, spacing: MCSpacing.xs) {
                Text("Notes (optional)")
                    .font(MCTypography.subheadline)
                    .foregroundStyle(MCColors.textSecondary)

                TextField("e.g. After meal, feeling dizzy", text: $notes, axis: .vertical)
                    .font(MCTypography.body)
                    .foregroundStyle(MCColors.textPrimary)
                    .lineLimit(3...5)
            }
        }
        .padding(.horizontal, MCSpacing.screenPadding)
    }

    // MARK: - Save Button

    private var saveButton: some View {
        Button {
            Task { await saveVital() }
        } label: {
            HStack(spacing: MCSpacing.xs) {
                if isSaving {
                    ProgressView()
                        .tint(.white)
                } else {
                    Image(systemName: "checkmark.circle.fill")
                    Text("Save to Apple Health")
                }
            }
            .font(MCTypography.bodyMedium)
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .frame(height: MCSpacing.buttonHeight)
            .background(isValid ? MCColors.primaryTeal : MCColors.textTertiary)
            .clipShape(RoundedRectangle(cornerRadius: MCSpacing.cornerRadius))
        }
        .disabled(!isValid || isSaving)
        .padding(.horizontal, MCSpacing.screenPadding)
    }

    // MARK: - Validation & Save

    private var isValid: Bool {
        guard let value = Double(primaryValue), value > 0 else { return false }
        if selectedType == .bloodPressure {
            guard let dia = Double(secondaryValue), dia > 0 else { return false }
        }
        return true
    }

    private func saveVital() async {
        isSaving = true
        defer { isSaving = false }

        do {
            if selectedType == .bloodPressure {
                guard let sys = Double(primaryValue), let dia = Double(secondaryValue) else { return }
                try await healthService.writeBloodPressure(systolic: sys, diastolic: dia, date: selectedDate)
            } else {
                guard let value = Double(primaryValue) else { return }
                try await healthService.writeToHealthKit(type: selectedType.vitalType, value: value, date: selectedDate)
            }

            onSave?()
            dismiss()
        } catch {
            errorMessage = error.localizedDescription
            showError = true
        }
    }
}
