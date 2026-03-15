import SwiftUI

struct OTPVerificationView: View {
    let phoneNumber: String
    @Environment(AuthService.self) private var authService
    @Environment(DataService.self) private var dataService
    @State private var otp = ""
    @State private var timeRemaining = 30
    @State private var canResend = false
    @State private var showProfileSetup = false
    @State private var showError = false

    private let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    var body: some View {
        VStack(spacing: MCSpacing.xl) {
            Spacer()

            // Header
            VStack(spacing: MCSpacing.sm) {
                ZStack {
                    Circle()
                        .fill(MCColors.primaryTeal.opacity(0.1))
                        .frame(width: 80, height: 80)

                    Image(systemName: "lock.shield")
                        .font(.system(size: 36, weight: .medium))
                        .foregroundStyle(MCColors.primaryTeal)
                }

                Text("Verify your number")
                    .font(MCTypography.title)
                    .foregroundStyle(MCColors.textPrimary)

                Text("Enter the 6-digit code sent to\n+91 \(formattedPhone)")
                    .font(MCTypography.body)
                    .foregroundStyle(MCColors.textSecondary)
                    .multilineTextAlignment(.center)
            }

            // OTP Input
            MCOTPField(otp: $otp, digitCount: 6)

            // Resend timer
            if canResend {
                Button("Resend Code") {
                    resendOTP()
                }
                .font(MCTypography.bodyMedium)
                .foregroundStyle(MCColors.primaryTeal)
            } else {
                Text("Resend code in \(timeRemaining)s")
                    .font(MCTypography.footnote)
                    .foregroundStyle(MCColors.textTertiary)
            }

            Spacer()

            // Verify button
            MCPrimaryButton("Verify", isLoading: authService.isLoading) {
                verifyOTP()
            }
            .disabled(otp.count < 6)
            .opacity(otp.count == 6 ? 1 : 0.6)
            .padding(.horizontal, MCSpacing.screenPadding)

            if let error = authService.errorMessage {
                Text(error)
                    .font(MCTypography.footnote)
                    .foregroundStyle(MCColors.error)
                    .padding(.bottom, MCSpacing.md)
            }
        }
        .padding(.horizontal, MCSpacing.screenPadding)
        .background(MCColors.backgroundLight)
        .navigationBarBackButtonHidden(false)
        .onReceive(timer) { _ in
            if timeRemaining > 0 {
                timeRemaining -= 1
            } else {
                canResend = true
            }
        }
        .navigationDestination(isPresented: $showProfileSetup) {
            ProfileSetupView(phoneNumber: phoneNumber)
        }
    }

    private var formattedPhone: String {
        if phoneNumber.count == 10 {
            let start = phoneNumber.prefix(5)
            let end = phoneNumber.suffix(5)
            return "\(start) \(end)"
        }
        return phoneNumber
    }

    private func verifyOTP() {
        Task {
            let success = try? await authService.verifyOTP(otp, phoneNumber: phoneNumber)
            if success == true {
                // Check if profile exists
                let user = dataService.getOrCreateUser(phoneNumber: phoneNumber)
                if user.profiles.isEmpty {
                    showProfileSetup = true
                }
                // If profiles exist, RootView will auto-switch to MainTabView
            }
        }
    }

    private func resendOTP() {
        canResend = false
        timeRemaining = 30
        Task {
            try? await authService.sendOTP(to: phoneNumber)
        }
    }
}
