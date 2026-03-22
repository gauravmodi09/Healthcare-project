import SwiftUI

struct RoleSelectionView: View {
    let phoneNumber: String
    @Environment(DataService.self) private var dataService
    @State private var selectedRole: UserRole?
    @State private var navigateToPatientSetup = false
    @State private var navigateToDoctorSetup = false
    @State private var navigateToHospitalSetup = false
    @AppStorage("mc_user_role") private var storedRole = ""

    private let roles: [(role: UserRole, icon: String, color: Color, title: String, description: String)] = [
        (.patient, "heart.text.clipboard.fill", Color(hex: "0D9488"), "Patient / Family", "Track medicines, vitals, and health for yourself and family"),
        (.individualDoctor, "stethoscope.circle.fill", Color(hex: "3B82F6"), "Independent Doctor", "Manage your patients, prescribe, and monitor remotely"),
        (.hospitalDoctor, "building.2.crop.circle.fill", Color(hex: "6366F1"), "Hospital / Clinic Doctor", "Join your hospital's network to manage patients together"),
        (.hospitalAdmin, "building.columns.fill", Color(hex: "D97706"), "Hospital Administrator", "Set up and manage your hospital on MedCare"),
    ]

    var body: some View {
        ScrollView {
            VStack(spacing: MCSpacing.lg) {
                // Header
                VStack(spacing: MCSpacing.sm) {
                    ZStack {
                        Circle()
                            .fill(MCColors.primaryTeal.opacity(0.1))
                            .frame(width: 100, height: 100)

                        Image(systemName: "person.crop.circle.badge.checkmark")
                            .font(.system(size: 44, weight: .medium))
                            .foregroundStyle(MCColors.primaryTeal)
                    }

                    Text("How will you use MedCare?")
                        .font(MCTypography.title)
                        .foregroundStyle(MCColors.textPrimary)

                    Text("Choose your role to get started")
                        .font(MCTypography.callout)
                        .foregroundStyle(MCColors.textSecondary)
                }
                .padding(.top, MCSpacing.lg)

                // Role Cards
                VStack(spacing: MCSpacing.md) {
                    ForEach(roles, id: \.role) { item in
                        RoleCard(
                            icon: item.icon,
                            iconColor: item.color,
                            title: item.title,
                            description: item.description,
                            isSelected: selectedRole == item.role
                        ) {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                selectedRole = item.role
                            }
                        }
                    }
                }

                // Continue button
                MCPrimaryButton("Continue", icon: "arrow.right") {
                    continueWithRole()
                }
                .disabled(selectedRole == nil)
                .opacity(selectedRole != nil ? 1 : 0.5)
                .padding(.top, MCSpacing.md)
                .padding(.bottom, MCSpacing.xl)
            }
            .padding(.horizontal, MCSpacing.screenPadding)
        }
        .background(MCColors.backgroundLight)
        .navigationBarBackButtonHidden(true)
        .navigationDestination(isPresented: $navigateToPatientSetup) {
            ProfileSetupView(phoneNumber: phoneNumber)
        }
        .navigationDestination(isPresented: $navigateToDoctorSetup) {
            DoctorSetupView(phoneNumber: phoneNumber, role: selectedRole ?? .individualDoctor)
        }
        .navigationDestination(isPresented: $navigateToHospitalSetup) {
            HospitalSetupView(phoneNumber: phoneNumber)
        }
    }

    private func continueWithRole() {
        guard let role = selectedRole else { return }

        // Save role to User model and AppStorage
        let user = dataService.getOrCreateUser(phoneNumber: phoneNumber)
        user.userRole = role.rawValue
        user.updatedAt = Date()
        dataService.save()
        storedRole = role.rawValue

        switch role {
        case .patient:
            navigateToPatientSetup = true
        case .individualDoctor, .hospitalDoctor:
            navigateToDoctorSetup = true
        case .hospitalAdmin:
            navigateToHospitalSetup = true
        }
    }
}

// MARK: - Role Card

private struct RoleCard: View {
    let icon: String
    let iconColor: Color
    let title: String
    let description: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            MCGlassCard {
                HStack(spacing: MCSpacing.md) {
                    // Icon
                    ZStack {
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .fill(iconColor.opacity(0.12))
                            .frame(width: 52, height: 52)

                        Image(systemName: icon)
                            .font(.system(size: 24, weight: .semibold))
                            .foregroundStyle(iconColor)
                    }

                    // Text
                    VStack(alignment: .leading, spacing: MCSpacing.xxs) {
                        Text(title)
                            .font(MCTypography.headline)
                            .foregroundStyle(MCColors.textPrimary)

                        Text(description)
                            .font(MCTypography.footnote)
                            .foregroundStyle(MCColors.textSecondary)
                            .lineLimit(2)
                    }

                    Spacer(minLength: 0)

                    // Checkmark
                    if isSelected {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 24))
                            .foregroundStyle(MCColors.primaryTeal)
                            .transition(.scale.combined(with: .opacity))
                    }
                }
            }
            .overlay(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .stroke(isSelected ? MCColors.primaryTeal : Color.clear, lineWidth: 2)
            )
        }
        .buttonStyle(.plain)
    }
}
