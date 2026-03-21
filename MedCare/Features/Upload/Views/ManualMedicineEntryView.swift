import SwiftUI
import SwiftData

/// Manual medicine entry — creates an episode and lets user add medicines one by one
struct ManualMedicineEntryView: View {
    let episodeTitle: String
    @Environment(\.dismiss) private var dismiss
    @Environment(DataService.self) private var dataService
    @Query private var users: [User]

    @State private var medicineName = ""
    @State private var dosage = ""
    @State private var selectedDoseForm: DoseForm = .tablet
    @State private var selectedFrequency: MedicineFrequency = .onceDaily
    @State private var selectedMealTiming: MealTiming = .afterMeal
    @State private var doctorName = ""
    @State private var addedMedicines: [(name: String, dosage: String)] = []

    private let quickDoseForms: [DoseForm] = [.tablet, .capsule, .syrup, .injection]
    private let quickFrequencies: [MedicineFrequency] = [.onceDaily, .twiceDaily, .thriceDaily]

    private var isValid: Bool {
        !medicineName.trimmingCharacters(in: .whitespaces).isEmpty &&
        !dosage.trimmingCharacters(in: .whitespaces).isEmpty
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: MCSpacing.lg) {
                    // Episode info
                    MCAccentCard(accent: MCColors.primaryTeal) {
                        VStack(alignment: .leading, spacing: MCSpacing.xs) {
                            HStack {
                                Image(systemName: "pencil.and.list.clipboard")
                                    .foregroundStyle(MCColors.primaryTeal)
                                Text("Manual Entry")
                                    .font(MCTypography.bodyMedium)
                            }
                            Text("Add your medicines manually. You can always add more later.")
                                .font(MCTypography.footnote)
                                .foregroundStyle(MCColors.textSecondary)
                        }
                    }

                    // Doctor name
                    MCTextField(label: "Doctor Name (optional)", icon: "stethoscope", text: $doctorName)

                    // Added medicines list
                    if !addedMedicines.isEmpty {
                        VStack(alignment: .leading, spacing: MCSpacing.xs) {
                            Text("Added Medicines")
                                .font(MCTypography.headline)
                                .foregroundStyle(MCColors.textPrimary)

                            ForEach(addedMedicines.indices, id: \.self) { index in
                                HStack {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundStyle(MCColors.success)
                                    Text("\(addedMedicines[index].name) \(addedMedicines[index].dosage)")
                                        .font(MCTypography.body)
                                        .foregroundStyle(MCColors.textPrimary)
                                    Spacer()
                                }
                                .padding(MCSpacing.sm)
                                .background(MCColors.success.opacity(0.08))
                                .clipShape(RoundedRectangle(cornerRadius: MCSpacing.cornerRadiusSmall))
                            }
                        }
                    }

                    Divider()

                    // Medicine entry form
                    VStack(alignment: .leading, spacing: MCSpacing.sm) {
                        Text(addedMedicines.isEmpty ? "First Medicine" : "Add Another Medicine")
                            .font(MCTypography.headline)
                            .foregroundStyle(MCColors.textPrimary)

                        MCTextField(label: "Medicine Name", icon: "pills", text: $medicineName)
                        MCTextField(label: "Dosage (e.g. 500mg)", icon: "scalemass", text: $dosage)

                        // Dose form picker
                        VStack(alignment: .leading, spacing: MCSpacing.xxs) {
                            Text("Form")
                                .font(MCTypography.caption)
                                .foregroundStyle(MCColors.textSecondary)
                            HStack(spacing: MCSpacing.xs) {
                                ForEach(quickDoseForms, id: \.self) { form in
                                    Button {
                                        selectedDoseForm = form
                                    } label: {
                                        VStack(spacing: 4) {
                                            Image(systemName: form.icon)
                                                .font(.system(size: 16))
                                            Text(form.rawValue)
                                                .font(.system(size: 10))
                                        }
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, MCSpacing.xs)
                                        .background(selectedDoseForm == form ? MCColors.primaryTeal.opacity(0.15) : MCColors.backgroundLight)
                                        .clipShape(RoundedRectangle(cornerRadius: MCSpacing.cornerRadiusSmall))
                                        .overlay(
                                            selectedDoseForm == form
                                            ? RoundedRectangle(cornerRadius: MCSpacing.cornerRadiusSmall)
                                                .stroke(MCColors.primaryTeal, lineWidth: 1)
                                            : nil
                                        )
                                    }
                                    .foregroundStyle(selectedDoseForm == form ? MCColors.primaryTeal : MCColors.textSecondary)
                                }
                            }
                        }

                        // Frequency picker
                        VStack(alignment: .leading, spacing: MCSpacing.xxs) {
                            Text("Frequency")
                                .font(MCTypography.caption)
                                .foregroundStyle(MCColors.textSecondary)
                            HStack(spacing: MCSpacing.xs) {
                                ForEach(quickFrequencies, id: \.self) { freq in
                                    Button {
                                        selectedFrequency = freq
                                    } label: {
                                        Text(freq.rawValue)
                                            .font(MCTypography.caption)
                                            .frame(maxWidth: .infinity)
                                            .padding(.vertical, MCSpacing.xs)
                                            .background(selectedFrequency == freq ? MCColors.primaryTeal.opacity(0.15) : MCColors.backgroundLight)
                                            .clipShape(Capsule())
                                    }
                                    .foregroundStyle(selectedFrequency == freq ? MCColors.primaryTeal : MCColors.textSecondary)
                                }
                            }
                        }
                    }

                    // Add medicine button
                    MCPrimaryButton("Add Medicine", icon: "plus.circle.fill") {
                        addMedicine()
                    }
                    .disabled(!isValid)
                    .opacity(isValid ? 1 : 0.6)

                    // Done button (only after at least 1 medicine added)
                    if !addedMedicines.isEmpty {
                        MCCoralButton("Save & Create Episode", icon: "checkmark.circle.fill", isLoading: false) {
                            createEpisode()
                        }
                    }
                }
                .padding(.horizontal, MCSpacing.screenPadding)
                .padding(.vertical, MCSpacing.lg)
            }
            .background(MCColors.backgroundLight)
            .navigationTitle("Add Medicines")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }

    private func addMedicine() {
        addedMedicines.append((name: medicineName, dosage: dosage))
        medicineName = ""
        dosage = ""
    }

    private func createEpisode() {
        guard let profile = users.first?.activeProfile else { return }
        let episode = dataService.createEpisode(
            for: profile,
            title: episodeTitle,
            type: .acute,
            doctorName: doctorName.isEmpty ? nil : doctorName
        )
        for med in addedMedicines {
            let timings: [MedicineTiming] = {
                switch selectedFrequency {
                case .onceDaily: return [.morning]
                case .twiceDaily: return [.morning, .evening]
                case .thriceDaily: return [.morning, .afternoon, .evening]
                default: return [.morning]
                }
            }()
            let _ = dataService.addMedicine(
                to: episode,
                brandName: med.name,
                dosage: med.dosage,
                doseForm: selectedDoseForm,
                frequency: selectedFrequency,
                timing: timings,
                duration: 30,
                mealTiming: selectedMealTiming,
                source: .manual
            )
        }
        dismiss()
    }
}
