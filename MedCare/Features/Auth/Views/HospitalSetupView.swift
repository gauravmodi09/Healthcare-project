import SwiftUI
import SwiftData

struct HospitalSetupView: View {
    let phoneNumber: String
    @Environment(\.dismiss) private var dismiss
    @Environment(DataService.self) private var dataService
    @AppStorage("mc_user_role") private var storedRole = ""
    @AppStorage("mc_role_setup_complete") private var roleSetupComplete = false

    @State private var hospitalName = ""
    @State private var city = ""
    @State private var address = ""
    @State private var selectedType = "Hospital"
    @State private var adminName = ""
    @State private var selectedSpecialties: Set<String> = []
    @State private var isComplete = false

    private let hospitalTypes = ["Hospital", "Clinic", "Polyclinic", "Nursing Home"]

    private let availableSpecialties = [
        "General Medicine", "Cardiology", "Endocrinology", "Dermatology",
        "Orthopedics", "Pediatrics", "Psychiatry", "Gynecology", "ENT",
        "Ophthalmology", "Pulmonology", "Neurology", "Nephrology", "Urology",
        "Gastroenterology", "Oncology", "General Surgery", "Anesthesiology",
        "Emergency Medicine", "Radiology", "Pathology", "Physiotherapy"
    ]

    private var isFormValid: Bool {
        !hospitalName.trimmingCharacters(in: .whitespaces).isEmpty &&
        !city.trimmingCharacters(in: .whitespaces).isEmpty &&
        !adminName.trimmingCharacters(in: .whitespaces).isEmpty
    }

    var body: some View {
        ScrollView {
            VStack(spacing: MCSpacing.lg) {
                // Header
                VStack(spacing: MCSpacing.sm) {
                    ZStack {
                        Circle()
                            .fill(Color(hex: "D97706").opacity(0.1))
                            .frame(width: 100, height: 100)

                        Image(systemName: "building.columns.fill")
                            .font(.system(size: 44, weight: .medium))
                            .foregroundStyle(Color(hex: "D97706"))
                    }

                    Text("Register Your Hospital")
                        .font(MCTypography.title)
                        .foregroundStyle(MCColors.textPrimary)

                    Text("Set up your hospital on MedCare")
                        .font(MCTypography.callout)
                        .foregroundStyle(MCColors.textSecondary)
                }
                .padding(.top, MCSpacing.lg)

                // Form
                VStack(spacing: MCSpacing.md) {
                    // Hospital Details Section
                    sectionHeader("Hospital Details")

                    MCTextField(label: "Hospital Name", icon: "building.2", text: $hospitalName)
                    MCTextField(label: "City", icon: "mappin", text: $city)
                    MCTextField(label: "Address", icon: "map", text: $address)

                    // Type picker
                    VStack(alignment: .leading, spacing: MCSpacing.xs) {
                        Text("Type")
                            .font(MCTypography.subheadline)
                            .foregroundStyle(MCColors.textSecondary)

                        HStack(spacing: MCSpacing.xs) {
                            ForEach(hospitalTypes, id: \.self) { type in
                                Button {
                                    selectedType = type
                                } label: {
                                    Text(type)
                                        .font(MCTypography.footnote)
                                        .foregroundStyle(selectedType == type ? .white : MCColors.textPrimary)
                                        .padding(.horizontal, MCSpacing.sm)
                                        .padding(.vertical, MCSpacing.xs)
                                        .background(
                                            selectedType == type
                                                ? Color(hex: "D97706")
                                                : MCColors.backgroundLight
                                        )
                                        .clipShape(Capsule())
                                }
                            }
                        }
                    }

                    // Specialties
                    sectionHeader("Specialties")

                    FlowLayout(spacing: MCSpacing.xs) {
                        ForEach(availableSpecialties, id: \.self) { specialty in
                            Button {
                                if selectedSpecialties.contains(specialty) {
                                    selectedSpecialties.remove(specialty)
                                } else {
                                    selectedSpecialties.insert(specialty)
                                }
                            } label: {
                                HStack(spacing: MCSpacing.xxs) {
                                    if selectedSpecialties.contains(specialty) {
                                        Image(systemName: "checkmark")
                                            .font(.system(size: 10, weight: .bold))
                                    }
                                    Text(specialty)
                                        .font(MCTypography.caption)
                                }
                                .foregroundStyle(
                                    selectedSpecialties.contains(specialty)
                                        ? .white
                                        : MCColors.textPrimary
                                )
                                .padding(.horizontal, MCSpacing.sm)
                                .padding(.vertical, MCSpacing.xs)
                                .background(
                                    selectedSpecialties.contains(specialty)
                                        ? MCColors.primaryTeal
                                        : MCColors.backgroundLight
                                )
                                .clipShape(Capsule())
                            }
                        }
                    }

                    // Admin Details Section
                    sectionHeader("Admin Details")

                    MCTextField(label: "Admin Name", icon: "person", text: $adminName)

                    // Phone (pre-filled)
                    HStack(spacing: MCSpacing.sm) {
                        Image(systemName: "phone")
                            .foregroundStyle(MCColors.textSecondary)
                            .frame(width: MCSpacing.iconSize)
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Admin Phone")
                                .font(MCTypography.caption)
                                .foregroundStyle(MCColors.primaryTeal)
                            Text("+91 \(phoneNumber)")
                                .font(MCTypography.body)
                                .foregroundStyle(MCColors.textPrimary)
                        }
                        Spacer()
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(MCColors.success)
                    }
                    .padding(.horizontal, MCSpacing.md)
                    .frame(height: MCSpacing.inputHeight)
                    .background(MCColors.backgroundLight)
                    .clipShape(RoundedRectangle(cornerRadius: MCSpacing.cornerRadius))
                }

                // Register button
                MCPrimaryButton("Register Hospital", icon: "checkmark") {
                    registerHospital()
                }
                .disabled(!isFormValid)
                .opacity(isFormValid ? 1 : 0.5)
                .padding(.top, MCSpacing.md)
                .padding(.bottom, MCSpacing.xl)
            }
            .padding(.horizontal, MCSpacing.screenPadding)
        }
        .background(MCColors.backgroundLight)
        .navigationBarBackButtonHidden(true)
        .navigationTitle("Hospital Setup")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button {
                    dismiss()
                } label: {
                    Image(systemName: "chevron.left")
                        .foregroundStyle(MCColors.textSecondary)
                }
            }
        }
    }

    private func sectionHeader(_ title: String) -> some View {
        Text(title)
            .font(MCTypography.sectionHeader)
            .foregroundStyle(MCColors.textSecondary)
            .textCase(.uppercase)
            .kerning(1.2)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.top, MCSpacing.sm)
    }

    private func registerHospital() {
        // Update user role
        let user = dataService.getOrCreateUser(phoneNumber: phoneNumber)
        user.userRole = UserRole.hospitalAdmin.rawValue
        user.updatedAt = Date()

        // Create admin profile
        let profile = dataService.createProfile(
            for: user,
            name: adminName,
            relation: .myself,
            dob: nil,
            gender: nil
        )
        _ = profile

        dataService.save()

        storedRole = UserRole.hospitalAdmin.rawValue
        roleSetupComplete = true
        dismiss()
    }
}
