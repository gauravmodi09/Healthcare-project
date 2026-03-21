import SwiftUI

/// Welcome onboarding carousel — shown to first-time users
struct OnboardingView: View {
    let onComplete: () -> Void
    @State private var currentPage = 0

    private let pages: [(icon: String, title: String, subtitle: String, color: Color)] = [
        (
            "heart.circle.fill",
            "Your Family's Medicine Companion",
            "Track medicines, doses, and health records for your whole family — all in one secure place.",
            Color(hex: "0A7E8C")
        ),
        (
            "bell.badge.fill",
            "Never Miss a Dose",
            "Smart reminders, streaks, and gentle nudges keep you and your loved ones on track every single day.",
            Color(hex: "FF6B6B")
        ),
        (
            "sparkles",
            "AI-Powered Health Insights",
            "Chat with Medi for medicine info, symptom correlation, and doctor-ready reports — in English or Hinglish.",
            Color(hex: "F5A623")
        ),
        (
            "indianrupeesign.circle.fill",
            "Built for India",
            "Hindi medicine instructions, Jan Aushadhi generic savings, and Ayurvedic supplement support — designed for you.",
            Color(hex: "34C759")
        )
    ]

    var body: some View {
        VStack(spacing: 0) {
            // Pages
            TabView(selection: $currentPage) {
                ForEach(Array(pages.enumerated()), id: \.offset) { index, page in
                    VStack(spacing: MCSpacing.lg) {
                        Spacer()

                        // Icon with animated ring
                        ZStack {
                            Circle()
                                .fill(page.color.opacity(0.06))
                                .frame(width: 160, height: 160)
                            Circle()
                                .fill(page.color.opacity(0.12))
                                .frame(width: 120, height: 120)
                            Image(systemName: page.icon)
                                .font(.system(size: 52, weight: .medium))
                                .foregroundStyle(page.color)
                                .symbolEffect(.pulse, options: .repeating, value: currentPage == index)
                        }

                        // Title
                        Text(page.title)
                            .font(MCTypography.display)
                            .foregroundStyle(MCColors.textPrimary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, MCSpacing.md)

                        // Subtitle
                        Text(page.subtitle)
                            .font(MCTypography.body)
                            .foregroundStyle(MCColors.textSecondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, MCSpacing.xl)
                            .lineSpacing(4)

                        Spacer()
                        Spacer()
                    }
                    .tag(index)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .never))

            // Bottom section
            VStack(spacing: MCSpacing.md) {
                // Page indicators
                HStack(spacing: 8) {
                    ForEach(0..<pages.count, id: \.self) { index in
                        Capsule()
                            .fill(index == currentPage ? MCColors.primaryTeal : MCColors.primaryTeal.opacity(0.2))
                            .frame(width: index == currentPage ? 24 : 8, height: 8)
                            .animation(.spring(response: 0.3), value: currentPage)
                    }
                }

                // Button
                Button {
                    if currentPage < pages.count - 1 {
                        withAnimation(.spring(response: 0.4)) {
                            currentPage += 1
                        }
                    } else {
                        onComplete()
                    }
                } label: {
                    Text(currentPage < pages.count - 1 ? "Next" : "Get Started")
                        .font(MCTypography.bodyMedium)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: MCSpacing.buttonHeight)
                        .background(MCColors.primaryTeal)
                        .clipShape(RoundedRectangle(cornerRadius: MCSpacing.cornerRadius))
                }

                // Skip button
                if currentPage < pages.count - 1 {
                    Button {
                        onComplete()
                    } label: {
                        Text("Skip")
                            .font(MCTypography.callout)
                            .foregroundStyle(MCColors.textSecondary)
                    }
                }
            }
            .padding(.horizontal, MCSpacing.screenPadding)
            .padding(.bottom, MCSpacing.xl)
        }
        .background(MCColors.backgroundLight)
    }
}
