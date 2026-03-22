import SwiftUI
import SwiftData

struct DoctorSetupView: View {
    let phoneNumber: String
    let role: UserRole
    @Environment(\.dismiss) private var dismiss
    @Environment(DataService.self) private var dataService
    @AppStorage("mc_user_role") private var storedRole = ""
    @AppStorage("mc_role_setup_complete") private var roleSetupComplete = false

    // Step tracking
    @State private var currentStep = 0

    // Step 1: Doctor Profile
    @State private var doctorName = ""
    @State private var selectedSpecialty = "General Medicine"
    @State private var registrationNumber = ""
    @State private var qualification = ""
    @State private var consultationFee = ""

    // Step 2: Hospital Association (hospital doctor only)
    @State private var hospitalSearchText = ""
    @State private var selectedHospital: HospitalInfo?
    @State private var showManualEntry = false
    @State private var manualHospitalName = ""
    @State private var manualHospitalCity = ""
    @State private var manualHospitalAddress = ""

    private var totalSteps: Int {
        role == .hospitalDoctor ? 3 : 2
    }

    private var isStep1Valid: Bool {
        !doctorName.trimmingCharacters(in: .whitespaces).isEmpty &&
        !registrationNumber.trimmingCharacters(in: .whitespaces).isEmpty
    }

    private var isStep2Valid: Bool {
        selectedHospital != nil || (!manualHospitalName.isEmpty && !manualHospitalCity.isEmpty)
    }

    static let specialties = [
        "General Medicine", "Cardiology", "Endocrinology", "Dermatology",
        "Orthopedics", "Pediatrics", "Psychiatry", "Gynecology", "ENT",
        "Ophthalmology", "Pulmonology", "Neurology", "Nephrology", "Urology",
        "Gastroenterology", "Oncology", "General Surgery", "Anesthesiology", "Other"
    ]

    private var filteredHospitals: [HospitalInfo] {
        if hospitalSearchText.isEmpty { return HospitalDirectory.hospitals }
        return HospitalDirectory.hospitals.filter {
            $0.name.localizedCaseInsensitiveContains(hospitalSearchText) ||
            $0.city.localizedCaseInsensitiveContains(hospitalSearchText)
        }
    }

    var body: some View {
        ScrollView {
            VStack(spacing: MCSpacing.lg) {
                // Progress indicator
                stepProgressView

                // Step content
                switch currentStep {
                case 0:
                    doctorProfileStep
                case 1:
                    if role == .hospitalDoctor {
                        hospitalAssociationStep
                    } else {
                        confirmationStep
                    }
                case 2:
                    confirmationStep
                default:
                    EmptyView()
                }
            }
            .padding(.horizontal, MCSpacing.screenPadding)
        }
        .background(MCColors.backgroundLight)
        .navigationBarBackButtonHidden(true)
        .navigationTitle("Doctor Setup")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                if currentStep > 0 {
                    Button {
                        withAnimation { currentStep -= 1 }
                    } label: {
                        Image(systemName: "chevron.left")
                            .foregroundStyle(MCColors.textSecondary)
                    }
                }
            }
        }
    }

    // MARK: - Step Progress

    private var stepProgressView: some View {
        VStack(spacing: MCSpacing.sm) {
            HStack(spacing: MCSpacing.xs) {
                ForEach(0..<totalSteps, id: \.self) { step in
                    Capsule()
                        .fill(step <= currentStep ? MCColors.primaryTeal : MCColors.divider)
                        .frame(height: 4)
                }
            }

            Text("Step \(currentStep + 1) of \(totalSteps)")
                .font(MCTypography.caption)
                .foregroundStyle(MCColors.textTertiary)
        }
        .padding(.top, MCSpacing.md)
    }

    // MARK: - Step 1: Doctor Profile

    private var doctorProfileStep: some View {
        VStack(spacing: MCSpacing.lg) {
            // Header
            VStack(spacing: MCSpacing.sm) {
                ZStack {
                    Circle()
                        .fill(Color(hex: "3B82F6").opacity(0.1))
                        .frame(width: 80, height: 80)

                    Image(systemName: "stethoscope")
                        .font(.system(size: 36, weight: .medium))
                        .foregroundStyle(Color(hex: "3B82F6"))
                }

                Text("Doctor Profile")
                    .font(MCTypography.title)
                    .foregroundStyle(MCColors.textPrimary)

                Text("Tell us about your medical practice")
                    .font(MCTypography.callout)
                    .foregroundStyle(MCColors.textSecondary)
            }

            // Form fields
            VStack(spacing: MCSpacing.md) {
                MCTextField(label: "Full Name", icon: "person", text: $doctorName)

                // Specialty picker
                VStack(alignment: .leading, spacing: MCSpacing.xs) {
                    Text("Specialty")
                        .font(MCTypography.subheadline)
                        .foregroundStyle(MCColors.textSecondary)

                    Menu {
                        ForEach(Self.specialties, id: \.self) { specialty in
                            Button(specialty) {
                                selectedSpecialty = specialty
                            }
                        }
                    } label: {
                        HStack {
                            Image(systemName: "cross.case")
                                .foregroundStyle(MCColors.textSecondary)
                                .frame(width: MCSpacing.iconSize)
                            Text(selectedSpecialty)
                                .font(MCTypography.body)
                                .foregroundStyle(MCColors.textPrimary)
                            Spacer()
                            Image(systemName: "chevron.up.chevron.down")
                                .font(.system(size: 12))
                                .foregroundStyle(MCColors.textTertiary)
                        }
                        .padding(.horizontal, MCSpacing.md)
                        .frame(height: MCSpacing.inputHeight)
                        .background(MCColors.backgroundLight)
                        .clipShape(RoundedRectangle(cornerRadius: MCSpacing.cornerRadius))
                        .overlay(
                            RoundedRectangle(cornerRadius: MCSpacing.cornerRadius)
                                .stroke(MCColors.primaryTeal.opacity(0.3), lineWidth: 1)
                        )
                    }
                }

                MCTextField(label: "Medical Council Reg. Number", icon: "number", text: $registrationNumber)

                MCTextField(label: "Qualification (e.g., MBBS, MD)", icon: "graduationcap", text: $qualification)

                MCTextField(label: "Consultation Fee (INR)", icon: "indianrupeesign", text: $consultationFee, keyboardType: .numberPad)

                // Phone (pre-filled, read-only display)
                HStack(spacing: MCSpacing.sm) {
                    Image(systemName: "phone")
                        .foregroundStyle(MCColors.textSecondary)
                        .frame(width: MCSpacing.iconSize)
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Phone")
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

            // Next button
            MCPrimaryButton("Next", icon: "arrow.right") {
                withAnimation { currentStep += 1 }
            }
            .disabled(!isStep1Valid)
            .opacity(isStep1Valid ? 1 : 0.5)
            .padding(.top, MCSpacing.sm)
            .padding(.bottom, MCSpacing.xl)
        }
    }

    // MARK: - Step 2: Hospital Association

    private var hospitalAssociationStep: some View {
        VStack(spacing: MCSpacing.lg) {
            // Header
            VStack(spacing: MCSpacing.sm) {
                ZStack {
                    Circle()
                        .fill(Color(hex: "6366F1").opacity(0.1))
                        .frame(width: 80, height: 80)

                    Image(systemName: "building.2.crop.circle")
                        .font(.system(size: 36, weight: .medium))
                        .foregroundStyle(Color(hex: "6366F1"))
                }

                Text("Hospital Association")
                    .font(MCTypography.title)
                    .foregroundStyle(MCColors.textPrimary)

                Text("Link your profile to a hospital")
                    .font(MCTypography.callout)
                    .foregroundStyle(MCColors.textSecondary)
            }

            if !showManualEntry {
                // Search
                MCTextField(label: "Search Hospital", icon: "magnifyingglass", text: $hospitalSearchText)

                // Hospital list
                LazyVStack(spacing: MCSpacing.sm) {
                    ForEach(filteredHospitals) { hospital in
                        HospitalSelectionCard(
                            hospital: hospital,
                            isSelected: selectedHospital?.id == hospital.id
                        ) {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                selectedHospital = hospital
                            }
                        }
                    }
                }

                // My hospital isn't listed
                Button {
                    withAnimation { showManualEntry = true }
                } label: {
                    HStack(spacing: MCSpacing.xs) {
                        Image(systemName: "plus.circle")
                            .font(.system(size: 16, weight: .medium))
                        Text("My hospital isn't listed")
                            .font(MCTypography.bodyMedium)
                    }
                    .foregroundStyle(MCColors.primaryTeal)
                    .frame(maxWidth: .infinity)
                    .frame(height: MCSpacing.buttonHeight)
                    .background(MCColors.primaryTeal.opacity(0.08))
                    .clipShape(RoundedRectangle(cornerRadius: MCSpacing.cornerRadius))
                }
            } else {
                // Manual entry
                VStack(spacing: MCSpacing.md) {
                    MCTextField(label: "Hospital Name", icon: "building.2", text: $manualHospitalName)
                    MCTextField(label: "City", icon: "mappin", text: $manualHospitalCity)
                    MCTextField(label: "Address", icon: "map", text: $manualHospitalAddress)

                    Button {
                        withAnimation { showManualEntry = false }
                    } label: {
                        Text("Back to search")
                            .font(MCTypography.footnote)
                            .foregroundStyle(MCColors.textSecondary)
                    }
                }
            }

            // Next button
            MCPrimaryButton("Next", icon: "arrow.right") {
                withAnimation { currentStep += 1 }
            }
            .disabled(!isStep2Valid)
            .opacity(isStep2Valid ? 1 : 0.5)
            .padding(.top, MCSpacing.sm)
            .padding(.bottom, MCSpacing.xl)
        }
    }

    // MARK: - Confirmation Step

    private var confirmationStep: some View {
        VStack(spacing: MCSpacing.lg) {
            // Header
            VStack(spacing: MCSpacing.sm) {
                ZStack {
                    Circle()
                        .fill(MCColors.success.opacity(0.1))
                        .frame(width: 80, height: 80)

                    Image(systemName: "checkmark.seal.fill")
                        .font(.system(size: 36, weight: .medium))
                        .foregroundStyle(MCColors.success)
                }

                Text("Confirm Your Profile")
                    .font(MCTypography.title)
                    .foregroundStyle(MCColors.textPrimary)

                Text("Review and confirm your details")
                    .font(MCTypography.callout)
                    .foregroundStyle(MCColors.textSecondary)
            }

            // Summary card
            MCGlassCard {
                VStack(alignment: .leading, spacing: MCSpacing.md) {
                    summaryRow(icon: "person.fill", label: "Name", value: doctorName)
                    summaryRow(icon: "cross.case.fill", label: "Specialty", value: selectedSpecialty)
                    summaryRow(icon: "number", label: "Registration", value: registrationNumber)

                    if !qualification.isEmpty {
                        summaryRow(icon: "graduationcap.fill", label: "Qualification", value: qualification)
                    }
                    if !consultationFee.isEmpty {
                        summaryRow(icon: "indianrupeesign", label: "Consultation Fee", value: "Rs. \(consultationFee)")
                    }

                    summaryRow(icon: "phone.fill", label: "Phone", value: "+91 \(phoneNumber)")

                    if role == .hospitalDoctor {
                        Divider()
                        if let hospital = selectedHospital {
                            summaryRow(icon: "building.2.fill", label: "Hospital", value: hospital.name)
                            summaryRow(icon: "mappin.circle.fill", label: "City", value: hospital.city)
                        } else if !manualHospitalName.isEmpty {
                            summaryRow(icon: "building.2.fill", label: "Hospital", value: manualHospitalName)
                            summaryRow(icon: "mappin.circle.fill", label: "City", value: manualHospitalCity)
                        }
                    }
                }
            }

            // Complete button
            MCPrimaryButton("Start Using MedCare", icon: "checkmark") {
                completeSetup()
            }
            .padding(.top, MCSpacing.md)
            .padding(.bottom, MCSpacing.xl)
        }
    }

    private func summaryRow(icon: String, label: String, value: String) -> some View {
        HStack(spacing: MCSpacing.sm) {
            Image(systemName: icon)
                .font(.system(size: 14))
                .foregroundStyle(MCColors.primaryTeal)
                .frame(width: 20)

            Text(label)
                .font(MCTypography.subheadline)
                .foregroundStyle(MCColors.textSecondary)
                .frame(width: 100, alignment: .leading)

            Text(value)
                .font(MCTypography.bodyMedium)
                .foregroundStyle(MCColors.textPrimary)

            Spacer()
        }
    }

    // MARK: - Complete Setup

    private func completeSetup() {
        let context = dataService.modelContext

        // Create Doctor record
        let fee = Double(consultationFee) ?? 0
        let doctor = Doctor(
            name: doctorName,
            specialty: selectedSpecialty,
            phone: phoneNumber,
            email: "",
            registrationNumber: registrationNumber,
            consultationFee: fee
        )
        doctor.avatarEmoji = role == .hospitalDoctor ? "🏥" : "👨‍⚕️"
        context.insert(doctor)

        // Update the user record
        let user = dataService.getOrCreateUser(phoneNumber: phoneNumber)
        user.userRole = role.rawValue
        user.updatedAt = Date()

        // Create a profile for the doctor as well
        let profile = dataService.createProfile(
            for: user,
            name: doctorName,
            relation: .myself,
            dob: nil,
            gender: nil
        )
        _ = profile

        dataService.save()

        storedRole = role.rawValue
        roleSetupComplete = true
        dismiss()
    }
}

// MARK: - Hospital Selection Card

private struct HospitalSelectionCard: View {
    let hospital: HospitalInfo
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: MCSpacing.md) {
                Text(hospital.logoEmoji)
                    .font(.system(size: 28))
                    .frame(width: 44, height: 44)
                    .background(Color(hex: "6366F1").opacity(0.08))
                    .clipShape(RoundedRectangle(cornerRadius: 10))

                VStack(alignment: .leading, spacing: 2) {
                    Text(hospital.name)
                        .font(MCTypography.bodyMedium)
                        .foregroundStyle(MCColors.textPrimary)

                    HStack(spacing: MCSpacing.xs) {
                        Text(hospital.city)
                            .font(MCTypography.caption)
                            .foregroundStyle(MCColors.textSecondary)

                        Text("·")
                            .foregroundStyle(MCColors.textTertiary)

                        Text("\(hospital.specialtyCount) specialties")
                            .font(MCTypography.caption)
                            .foregroundStyle(MCColors.textTertiary)

                        Text("·")
                            .foregroundStyle(MCColors.textTertiary)

                        Text("\(hospital.doctorCount) doctors")
                            .font(MCTypography.caption)
                            .foregroundStyle(MCColors.textTertiary)
                    }
                }

                Spacer()

                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 22))
                        .foregroundStyle(MCColors.primaryTeal)
                }
            }
            .padding(MCSpacing.sm)
            .background(MCColors.cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: MCSpacing.cornerRadius))
            .overlay(
                RoundedRectangle(cornerRadius: MCSpacing.cornerRadius)
                    .stroke(isSelected ? MCColors.primaryTeal : MCColors.divider, lineWidth: isSelected ? 2 : 1)
            )
        }
        .buttonStyle(.plain)
    }
}
