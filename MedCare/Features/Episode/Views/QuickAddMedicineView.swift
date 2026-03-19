import SwiftUI
import SwiftData

/// Quick-add medicine bottom sheet — add a medicine in 30 seconds
struct QuickAddMedicineView: View {
    let episode: Episode
    @Environment(DataService.self) private var dataService
    @Environment(\.dismiss) private var dismiss

    @State private var medicineName = ""
    @State private var dosage = ""
    @State private var selectedDoseForm: DoseForm = .tablet
    @State private var selectedFrequency: MedicineFrequency = .onceDaily
    @State private var selectedMealTiming: MealTiming = .afterMeal
    @State private var isAdding = false

    /// Subset of dose forms for quick-add (most common)
    private let quickDoseForms: [DoseForm] = [.tablet, .capsule, .syrup, .injection]

    /// Subset of frequencies for quick-add
    private let quickFrequencies: [MedicineFrequency] = [.onceDaily, .twiceDaily, .thriceDaily]

    /// Subset of meal timings for quick-add
    private let quickMealTimings: [MealTiming] = [.beforeMeal, .afterMeal, .withMeal]

    private var isValid: Bool {
        !medicineName.trimmingCharacters(in: .whitespaces).isEmpty &&
        !dosage.trimmingCharacters(in: .whitespaces).isEmpty
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: MCSpacing.lg) {
                    // Medicine name
                    VStack(alignment: .leading, spacing: MCSpacing.xs) {
                        Text("Medicine Name")
                            .font(MCTypography.subheadline)
                            .foregroundStyle(MCColors.textSecondary)

                        TextField("e.g. Augmentin 625", text: $medicineName)
                            .font(MCTypography.body)
                            .padding(MCSpacing.sm)
                            .background(MCColors.backgroundLight)
                            .clipShape(RoundedRectangle(cornerRadius: MCSpacing.cornerRadiusSmall))
                            .overlay(
                                RoundedRectangle(cornerRadius: MCSpacing.cornerRadiusSmall)
                                    .stroke(MCColors.divider, lineWidth: 1)
                            )
                    }

                    // Dosage
                    VStack(alignment: .leading, spacing: MCSpacing.xs) {
                        Text("Dosage")
                            .font(MCTypography.subheadline)
                            .foregroundStyle(MCColors.textSecondary)

                        TextField("e.g. 500mg", text: $dosage)
                            .font(MCTypography.body)
                            .padding(MCSpacing.sm)
                            .background(MCColors.backgroundLight)
                            .clipShape(RoundedRectangle(cornerRadius: MCSpacing.cornerRadiusSmall))
                            .overlay(
                                RoundedRectangle(cornerRadius: MCSpacing.cornerRadiusSmall)
                                    .stroke(MCColors.divider, lineWidth: 1)
                            )
                    }

                    // Dose form picker
                    VStack(alignment: .leading, spacing: MCSpacing.xs) {
                        Text("Dose Form")
                            .font(MCTypography.subheadline)
                            .foregroundStyle(MCColors.textSecondary)

                        HStack(spacing: MCSpacing.xs) {
                            ForEach(quickDoseForms, id: \.self) { form in
                                doseFormChip(form)
                            }
                        }
                    }

                    // Frequency picker
                    VStack(alignment: .leading, spacing: MCSpacing.xs) {
                        Text("Frequency")
                            .font(MCTypography.subheadline)
                            .foregroundStyle(MCColors.textSecondary)

                        HStack(spacing: MCSpacing.xs) {
                            ForEach(quickFrequencies, id: \.self) { freq in
                                frequencyChip(freq)
                            }
                        }
                    }

                    // Meal timing picker
                    VStack(alignment: .leading, spacing: MCSpacing.xs) {
                        Text("Meal Timing")
                            .font(MCTypography.subheadline)
                            .foregroundStyle(MCColors.textSecondary)

                        HStack(spacing: MCSpacing.xs) {
                            ForEach(quickMealTimings, id: \.self) { timing in
                                mealTimingChip(timing)
                            }
                        }
                    }

                    Spacer(minLength: MCSpacing.md)

                    // Add button
                    MCPrimaryButton("Add Medicine", icon: "plus.circle", isLoading: isAdding) {
                        addMedicine()
                    }
                    .disabled(!isValid)
                    .opacity(isValid ? 1.0 : 0.5)
                }
                .padding(.horizontal, MCSpacing.screenPadding)
                .padding(.vertical, MCSpacing.md)
            }
            .background(MCColors.cardBackground)
            .navigationTitle("Quick Add Medicine")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundStyle(MCColors.textSecondary)
                }
            }
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
    }

    // MARK: - Chip Views

    private func doseFormChip(_ form: DoseForm) -> some View {
        Button {
            selectedDoseForm = form
        } label: {
            VStack(spacing: MCSpacing.xxs) {
                Image(systemName: form.icon)
                    .font(.system(size: 20))
                Text(form.rawValue)
                    .font(MCTypography.caption)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, MCSpacing.sm)
            .foregroundStyle(selectedDoseForm == form ? MCColors.textOnPrimary : MCColors.textPrimary)
            .background(
                selectedDoseForm == form
                    ? AnyShapeStyle(MCColors.primaryGradient)
                    : AnyShapeStyle(MCColors.backgroundLight)
            )
            .clipShape(RoundedRectangle(cornerRadius: MCSpacing.cornerRadiusSmall))
            .overlay(
                RoundedRectangle(cornerRadius: MCSpacing.cornerRadiusSmall)
                    .stroke(selectedDoseForm == form ? Color.clear : MCColors.divider, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }

    private func frequencyChip(_ freq: MedicineFrequency) -> some View {
        Button {
            selectedFrequency = freq
        } label: {
            Text(freq.rawValue)
                .font(MCTypography.caption)
                .frame(maxWidth: .infinity)
                .padding(.vertical, MCSpacing.sm)
                .foregroundStyle(selectedFrequency == freq ? MCColors.textOnPrimary : MCColors.textPrimary)
                .background(
                    selectedFrequency == freq
                        ? AnyShapeStyle(MCColors.primaryGradient)
                        : AnyShapeStyle(MCColors.backgroundLight)
                )
                .clipShape(RoundedRectangle(cornerRadius: MCSpacing.cornerRadiusSmall))
                .overlay(
                    RoundedRectangle(cornerRadius: MCSpacing.cornerRadiusSmall)
                        .stroke(selectedFrequency == freq ? Color.clear : MCColors.divider, lineWidth: 1)
                )
        }
        .buttonStyle(.plain)
    }

    private func mealTimingChip(_ timing: MealTiming) -> some View {
        Button {
            selectedMealTiming = timing
        } label: {
            VStack(spacing: MCSpacing.xxs) {
                Image(systemName: timing.icon)
                    .font(.system(size: 16))
                Text(timing.rawValue)
                    .font(MCTypography.caption)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, MCSpacing.sm)
            .foregroundStyle(selectedMealTiming == timing ? MCColors.textOnPrimary : MCColors.textPrimary)
            .background(
                selectedMealTiming == timing
                    ? AnyShapeStyle(MCColors.primaryGradient)
                    : AnyShapeStyle(MCColors.backgroundLight)
            )
            .clipShape(RoundedRectangle(cornerRadius: MCSpacing.cornerRadiusSmall))
            .overlay(
                RoundedRectangle(cornerRadius: MCSpacing.cornerRadiusSmall)
                    .stroke(selectedMealTiming == timing ? Color.clear : MCColors.divider, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }

    // MARK: - Actions

    private func addMedicine() {
        guard isValid else { return }
        isAdding = true

        let timings = timingsForFrequency(selectedFrequency)

        let medicine = dataService.addMedicine(
            to: episode,
            brandName: medicineName.trimmingCharacters(in: .whitespaces),
            dosage: dosage.trimmingCharacters(in: .whitespaces),
            doseForm: selectedDoseForm,
            frequency: selectedFrequency,
            timing: timings,
            duration: nil,
            mealTiming: selectedMealTiming,
            source: .manual,
            confidence: 1.0
        )

        // Schedule dose logs for the next 7 days
        dataService.createDoseLogs(for: medicine, days: 7)

        // Activate episode if it's still a draft
        if episode.status == .draft {
            dataService.activateEpisode(episode)
        }

        isAdding = false
        dismiss()
    }

    /// Map frequency to default timing slots
    private func timingsForFrequency(_ freq: MedicineFrequency) -> [MedicineTiming] {
        switch freq {
        case .onceDaily:
            return [.morning]
        case .twiceDaily:
            return [.morning, .night]
        case .thriceDaily:
            return [.morning, .afternoon, .night]
        case .fourTimesDaily:
            return [.morning, .afternoon, .evening, .night]
        case .asNeeded:
            return [.morning]
        case .weekly:
            return [.morning]
        case .alternate:
            return [.morning]
        }
    }
}
