import SwiftUI

struct PhoneLoginView: View {
    @Environment(AuthService.self) private var authService
    @Environment(AppRouter.self) private var router
    @State private var phoneNumber = ""
    @State private var showOTP = false
    @State private var animateIn = false

    private var isValidPhone: Bool {
        phoneNumber.count == 10 && phoneNumber.allSatisfy(\.isNumber)
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Header illustration
                ZStack {
                    MCColors.primaryGradient
                        .frame(height: 280)
                        .clipShape(
                            RoundedShape(corners: [.bottomLeft, .bottomRight], radius: 32)
                        )

                    VStack(spacing: MCSpacing.md) {
                        Image(systemName: "heart.text.clipboard")
                            .font(.system(size: 48, weight: .medium))
                            .foregroundStyle(.white)
                            .scaleEffect(animateIn ? 1 : 0.5)

                        VStack(spacing: MCSpacing.xxs) {
                            Text("Welcome to MedCare")
                                .font(MCTypography.title)
                                .foregroundStyle(.white)

                            Text("Your prescriptions, simplified")
                                .font(MCTypography.callout)
                                .foregroundStyle(.white.opacity(0.8))
                        }
                    }
                    .opacity(animateIn ? 1 : 0)
                }

                Spacer()

                // Login form
                VStack(spacing: MCSpacing.lg) {
                    VStack(alignment: .leading, spacing: MCSpacing.xs) {
                        Text("Enter your phone number")
                            .font(MCTypography.headline)
                            .foregroundStyle(MCColors.textPrimary)

                        Text("We'll send you a verification code")
                            .font(MCTypography.footnote)
                            .foregroundStyle(MCColors.textSecondary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)

                    MCPhoneField(phoneNumber: $phoneNumber, countryCode: "+91")

                    MCPrimaryButton("Continue", icon: "arrow.right", isLoading: authService.isLoading) {
                        Task {
                            try? await authService.sendOTP(to: phoneNumber)
                            showOTP = true
                        }
                    }
                    .disabled(!isValidPhone)
                    .opacity(isValidPhone ? 1 : 0.6)

                    Text("By continuing, you agree to our Terms of Service and Privacy Policy")
                        .font(MCTypography.caption)
                        .foregroundStyle(MCColors.textTertiary)
                        .multilineTextAlignment(.center)
                }
                .padding(.horizontal, MCSpacing.screenPadding)

                Spacer()
            }
            .background(MCColors.backgroundLight)
            .navigationDestination(isPresented: $showOTP) {
                OTPVerificationView(phoneNumber: phoneNumber)
            }
            .onAppear {
                withAnimation(.easeOut(duration: 0.6)) {
                    animateIn = true
                }
            }
        }
    }
}

/// Custom rounded corner shape
struct RoundedShape: Shape {
    var corners: UIRectCorner
    var radius: CGFloat

    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(
            roundedRect: rect,
            byRoundingCorners: corners,
            cornerRadii: CGSize(width: radius, height: radius)
        )
        return Path(path.cgPath)
    }
}
