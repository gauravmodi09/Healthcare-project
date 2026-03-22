import SwiftUI

/// ABHA ID linking flow — Aadhaar OTP verification
/// Accessible from ProfileManagementView settings section
struct ABHALinkingView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var aadhaarNumber = ""
    @State private var otp = ""
    @State private var txnId: String?
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var isLinked = ABDMService.shared.isLinked
    @State private var abhaNumber = ABDMService.shared.storedABHANumber
    @State private var abhaAddress = ABDMService.shared.storedABHAAddress
    @State private var showUnlinkConfirmation = false

    private enum LinkingStep {
        case enterAadhaar
        case enterOTP
        case linked
    }

    private var currentStep: LinkingStep {
        if isLinked { return .linked }
        if txnId != nil { return .enterOTP }
        return .enterAadhaar
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: MCSpacing.sectionSpacing) {
                    statusCard

                    switch currentStep {
                    case .enterAadhaar:
                        aadhaarEntrySection
                    case .enterOTP:
                        otpVerificationSection
                    case .linked:
                        linkedDetailsSection
                    }

                    if let errorMessage {
                        Text(errorMessage)
                            .font(MCTypography.caption)
                            .foregroundStyle(MCColors.error)
                            .padding(.horizontal, MCSpacing.md)
                    }

                    infoSection
                }
                .padding(.horizontal, MCSpacing.screenPadding)
                .padding(.bottom, MCSpacing.xxl)
            }
            .background(MCColors.backgroundLight)
            .navigationTitle("ABHA Linking")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
            .alert("Unlink ABHA?", isPresented: $showUnlinkConfirmation) {
                Button("Cancel", role: .cancel) {}
                Button("Unlink", role: .destructive) {
                    ABDMService.shared.unlinkABHA()
                    isLinked = false
                    abhaNumber = nil
                    abhaAddress = nil
                }
            } message: {
                Text("This will remove your ABHA ID from MedCare. You can re-link anytime.")
            }
        }
    }

    // MARK: - Status Card

    private var statusCard: some View {
        MCCard {
            HStack(spacing: MCSpacing.md) {
                Image(systemName: isLinked ? "checkmark.shield.fill" : "shield.slash")
                    .font(.system(size: 28))
                    .foregroundStyle(isLinked ? MCColors.success : MCColors.textTertiary)

                VStack(alignment: .leading, spacing: MCSpacing.xxs) {
                    Text(isLinked ? "ABHA Linked" : "ABHA Not Linked")
                        .font(MCTypography.headline)
                        .foregroundStyle(MCColors.textPrimary)
                    Text(isLinked
                         ? "Your health records are connected to ABDM"
                         : "Link your ABHA ID to share health records digitally")
                        .font(MCTypography.caption)
                        .foregroundStyle(MCColors.textSecondary)
                }

                Spacer()
            }
        }
    }

    // MARK: - Aadhaar Entry

    private var aadhaarEntrySection: some View {
        VStack(alignment: .leading, spacing: MCSpacing.md) {
            Text("Enter Aadhaar Number")
                .font(MCTypography.headline)
                .foregroundStyle(MCColors.textPrimary)

            MCTextField(label: "12-digit Aadhaar number", icon: "person.text.rectangle", text: $aadhaarNumber, keyboardType: .numberPad)

            Text("An OTP will be sent to your Aadhaar-linked mobile number")
                .font(MCTypography.caption)
                .foregroundStyle(MCColors.textSecondary)

            MCPrimaryButton("Send OTP", isLoading: isLoading) {
                Task { await sendOTP() }
            }
            .disabled(aadhaarNumber.count != 12)
        }
        .padding(.horizontal, MCSpacing.screenPadding)
    }

    // MARK: - OTP Verification

    private var otpVerificationSection: some View {
        VStack(alignment: .leading, spacing: MCSpacing.md) {
            Text("Enter OTP")
                .font(MCTypography.headline)
                .foregroundStyle(MCColors.textPrimary)

            MCTextField(label: "6-digit OTP", icon: "lock.fill", text: $otp, keyboardType: .numberPad)

            Text("Enter the OTP sent to your Aadhaar-linked mobile")
                .font(MCTypography.caption)
                .foregroundStyle(MCColors.textSecondary)

            MCPrimaryButton("Verify & Link ABHA", isLoading: isLoading) {
                Task { await verifyAndLink() }
            }
            .disabled(otp.count != 6)

            Button {
                txnId = nil
                otp = ""
                errorMessage = nil
            } label: {
                Text("Re-enter Aadhaar")
                    .font(MCTypography.subheadline)
                    .foregroundStyle(MCColors.primaryTeal)
            }
        }
        .padding(.horizontal, MCSpacing.screenPadding)
    }

    // MARK: - Linked Details

    private var linkedDetailsSection: some View {
        VStack(spacing: MCSpacing.md) {
            MCCard {
                VStack(alignment: .leading, spacing: MCSpacing.sm) {
                    detailRow(label: "ABHA Number", value: abhaNumber ?? "--")
                    Divider()
                    detailRow(label: "ABHA Address", value: abhaAddress ?? "--")
                }
            }

            Button {
                showUnlinkConfirmation = true
            } label: {
                Text("Unlink ABHA")
                    .font(MCTypography.subheadline)
                    .foregroundStyle(MCColors.error)
            }
        }
    }

    private func detailRow(label: String, value: String) -> some View {
        HStack {
            Text(label)
                .font(MCTypography.caption)
                .foregroundStyle(MCColors.textSecondary)
            Spacer()
            Text(value)
                .font(MCTypography.body)
                .foregroundStyle(MCColors.textPrimary)
        }
    }

    // MARK: - Info Section

    private var infoSection: some View {
        MCCard {
            VStack(alignment: .leading, spacing: MCSpacing.sm) {
                Label("What is ABHA?", systemImage: "info.circle.fill")
                    .font(MCTypography.subheadline)
                    .foregroundStyle(MCColors.primaryTeal)

                Text("ABHA (Ayushman Bharat Health Account) is a 14-digit health ID under India's digital health mission. It lets you securely share health records with hospitals and doctors across India.")
                    .font(MCTypography.caption)
                    .foregroundStyle(MCColors.textSecondary)
            }
        }
    }

    // MARK: - Actions

    private func sendOTP() async {
        isLoading = true
        errorMessage = nil

        do {
            let response = try await ABDMService.shared.linkABHA(aadhaarNumber: aadhaarNumber)
            txnId = response.txnId
        } catch {
            errorMessage = error.localizedDescription
        }

        isLoading = false
    }

    private func verifyAndLink() async {
        guard let txnId else { return }

        isLoading = true
        errorMessage = nil

        do {
            let response = try await ABDMService.shared.verifyOTP(txnId: txnId, otp: otp)
            abhaNumber = response.abhaNumber
            abhaAddress = response.abhaAddress
            isLinked = true
        } catch {
            errorMessage = error.localizedDescription
        }

        isLoading = false
    }
}

#Preview {
    ABHALinkingView()
}
