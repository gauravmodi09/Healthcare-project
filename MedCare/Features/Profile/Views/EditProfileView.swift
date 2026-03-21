import SwiftUI
import SwiftData

struct EditProfileView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(DataService.self) private var dataService

    let profile: UserProfile

    @State private var name: String
    @State private var dateOfBirth: Date
    @State private var hasDOB: Bool
    @State private var gender: Gender?
    @State private var bloodGroup: String
    @State private var knownConditions: [String]
    @State private var allergies: [String]
    @State private var caregiverName: String
    @State private var caregiverPhone: String
    @State private var newCondition: String = ""
    @State private var newAllergy: String = ""

    private let bloodGroups = ["", "A+", "A-", "B+", "B-", "AB+", "AB-", "O+", "O-"]

    init(profile: UserProfile) {
        self.profile = profile
        _name = State(initialValue: profile.name)
        _dateOfBirth = State(initialValue: profile.dateOfBirth ?? Calendar.current.date(byAdding: .year, value: -30, to: Date())!)
        _hasDOB = State(initialValue: profile.dateOfBirth != nil)
        _gender = State(initialValue: profile.gender)
        _bloodGroup = State(initialValue: profile.bloodGroup ?? "")
        _knownConditions = State(initialValue: profile.knownConditions)
        _allergies = State(initialValue: profile.allergies)
        _caregiverName = State(initialValue: profile.caregiverName ?? "")
        _caregiverPhone = State(initialValue: profile.caregiverPhoneNumber ?? "")
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: MCSpacing.lg) {
                    // Avatar
                    Text(profile.avatarEmoji)
                        .font(.system(size: 56))
                        .frame(width: 100, height: 100)
                        .background(MCColors.primaryTeal.opacity(0.1))
                        .clipShape(Circle())

                    // Name
                    MCTextField(label: "Name", icon: "person", text: $name)

                    // Date of Birth
                    VStack(alignment: .leading, spacing: MCSpacing.xs) {
                        Toggle(isOn: $hasDOB) {
                            Text("Date of Birth")
                                .font(MCTypography.subheadline)
                                .foregroundStyle(MCColors.textSecondary)
                        }
                        .tint(MCColors.primaryTeal)

                        if hasDOB {
                            DatePicker("", selection: $dateOfBirth, displayedComponents: .date)
                                .datePickerStyle(.compact)
                                .labelsHidden()
                        }
                    }
                    .padding(MCSpacing.md)
                    .background(MCColors.backgroundLight)
                    .clipShape(RoundedRectangle(cornerRadius: MCSpacing.cornerRadius))

                    // Gender
                    VStack(alignment: .leading, spacing: MCSpacing.xs) {
                        Text("Gender")
                            .font(MCTypography.subheadline)
                            .foregroundStyle(MCColors.textSecondary)

                        HStack(spacing: MCSpacing.xs) {
                            ForEach(Gender.allCases, id: \.self) { g in
                                Button {
                                    gender = gender == g ? nil : g
                                } label: {
                                    Text(g.rawValue)
                                        .font(MCTypography.footnote)
                                        .foregroundStyle(gender == g ? .white : MCColors.textPrimary)
                                        .padding(.horizontal, MCSpacing.sm)
                                        .padding(.vertical, MCSpacing.xs)
                                        .background(gender == g ? MCColors.primaryTeal : MCColors.backgroundLight)
                                        .clipShape(Capsule())
                                }
                            }
                        }
                    }

                    // Blood Group
                    VStack(alignment: .leading, spacing: MCSpacing.xs) {
                        Text("Blood Group")
                            .font(MCTypography.subheadline)
                            .foregroundStyle(MCColors.textSecondary)

                        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: MCSpacing.xs) {
                            ForEach(bloodGroups.filter { !$0.isEmpty }, id: \.self) { bg in
                                Button {
                                    bloodGroup = bloodGroup == bg ? "" : bg
                                } label: {
                                    Text(bg)
                                        .font(MCTypography.footnote)
                                        .foregroundStyle(bloodGroup == bg ? .white : MCColors.textPrimary)
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, MCSpacing.xs)
                                        .background(bloodGroup == bg ? MCColors.primaryTeal : MCColors.backgroundLight)
                                        .clipShape(RoundedRectangle(cornerRadius: MCSpacing.cornerRadiusSmall))
                                }
                            }
                        }
                    }

                    // Known Conditions
                    VStack(alignment: .leading, spacing: MCSpacing.xs) {
                        Text("Known Conditions")
                            .font(MCTypography.subheadline)
                            .foregroundStyle(MCColors.textSecondary)

                        chipList(items: $knownConditions)

                        HStack(spacing: MCSpacing.xs) {
                            MCTextField(label: "Add condition", icon: "heart.text.clipboard", text: $newCondition)
                            Button {
                                let trimmed = newCondition.trimmingCharacters(in: .whitespaces)
                                guard !trimmed.isEmpty else { return }
                                knownConditions.append(trimmed)
                                newCondition = ""
                            } label: {
                                Image(systemName: "plus.circle.fill")
                                    .font(.system(size: 28))
                                    .foregroundStyle(MCColors.primaryTeal)
                            }
                        }
                    }

                    // Allergies
                    VStack(alignment: .leading, spacing: MCSpacing.xs) {
                        Text("Allergies")
                            .font(MCTypography.subheadline)
                            .foregroundStyle(MCColors.textSecondary)

                        chipList(items: $allergies)

                        HStack(spacing: MCSpacing.xs) {
                            MCTextField(label: "Add allergy", icon: "allergens", text: $newAllergy)
                            Button {
                                let trimmed = newAllergy.trimmingCharacters(in: .whitespaces)
                                guard !trimmed.isEmpty else { return }
                                allergies.append(trimmed)
                                newAllergy = ""
                            } label: {
                                Image(systemName: "plus.circle.fill")
                                    .font(.system(size: 28))
                                    .foregroundStyle(MCColors.primaryTeal)
                            }
                        }
                    }

                    // Caregiver Contact
                    VStack(alignment: .leading, spacing: MCSpacing.xs) {
                        Text("Caregiver Contact")
                            .font(MCTypography.subheadline)
                            .foregroundStyle(MCColors.textSecondary)

                        Text("Get notified when this person misses a dose")
                            .font(MCTypography.caption)
                            .foregroundStyle(MCColors.textTertiary)

                        MCTextField(label: "Caregiver Name (e.g. Rahul)", icon: "person.2", text: $caregiverName)

                        MCTextField(label: "Caregiver Phone", icon: "phone", text: $caregiverPhone, keyboardType: .phonePad)
                    }

                    // Save Button
                    MCPrimaryButton("Save Changes", icon: "checkmark") {
                        saveProfile()
                    }
                    .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
                    .opacity(name.trimmingCharacters(in: .whitespaces).isEmpty ? 0.6 : 1)
                }
                .padding(.horizontal, MCSpacing.screenPadding)
                .padding(.vertical, MCSpacing.lg)
            }
            .background(MCColors.backgroundLight)
            .navigationTitle("Edit Profile")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }

    // MARK: - Chip List

    private func chipList(items: Binding<[String]>) -> some View {
        FlowLayout(spacing: MCSpacing.xs) {
            ForEach(Array(items.wrappedValue.enumerated()), id: \.offset) { index, item in
                HStack(spacing: MCSpacing.xxs) {
                    Text(item)
                        .font(MCTypography.footnote)
                        .foregroundStyle(MCColors.textPrimary)

                    Button {
                        items.wrappedValue.remove(at: index)
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 14))
                            .foregroundStyle(MCColors.textTertiary)
                    }
                }
                .padding(.horizontal, MCSpacing.sm)
                .padding(.vertical, MCSpacing.xxs + 2)
                .background(MCColors.primaryTeal.opacity(0.08))
                .clipShape(Capsule())
            }
        }
    }

    // MARK: - Save

    private func saveProfile() {
        profile.name = name.trimmingCharacters(in: .whitespaces)
        profile.dateOfBirth = hasDOB ? dateOfBirth : nil
        profile.gender = gender
        profile.bloodGroup = bloodGroup.isEmpty ? nil : bloodGroup
        profile.knownConditions = knownConditions
        profile.allergies = allergies
        profile.caregiverName = caregiverName.trimmingCharacters(in: .whitespaces).isEmpty ? nil : caregiverName.trimmingCharacters(in: .whitespaces)
        profile.caregiverPhoneNumber = caregiverPhone.trimmingCharacters(in: .whitespaces).isEmpty ? nil : caregiverPhone.trimmingCharacters(in: .whitespaces)
        dataService.save()
        dismiss()
    }
}

// FlowLayout is defined in ProfileSetupView.swift and shared across the app
