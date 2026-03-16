import SwiftUI

/// Welcome onboarding carousel — shown to first-time users
struct OnboardingView: View {
    let onComplete: () -> Void
    @State private var currentPage = 0

    private let pages: [(icon: String, title: String, subtitle: String, color: Color)] = [
        (
            "doc.text.viewfinder",
            "Scan Your Prescription",
            "Take a photo of your prescription or medicine box — our AI reads it instantly and sets up your reminders.",
            Color(hex: "0A7E8C")
        ),
        (
            "bell.badge.fill",
            "Never Miss a Dose",
            "Smart reminders with Dynamic Island, persistent alarms for critical medicines, and before/after meal timings.",
            Color(hex: "FF6B6B")
        ),
        (
            "chart.line.uptrend.xyaxis",
            "Track Your Recovery",
            "Log symptoms, view adherence streaks, and see how your treatment is progressing over time.",
            Color(hex: "34C759")
        ),
        (
            "sparkles",
            "AI Health Companion",
            "Ask questions about your medicines, side effects, diet, and recovery. Available 24/7 in English and Hinglish.",
            Color(hex: "F5A623")
        )
    ]

    var body: some View {
        VStack(spacing: 0) {
            // Pages
            TabView(selection: $currentPage) {
                ForEach(Array(pages.enumerated()), id: \.offset) { index, page in
                    VStack(spacing: MCSpacing.lg) {
                        Spacer()

                        // Icon
                        ZStack {
                            Circle()
                                .fill(page.color.opacity(0.1))
                                .frame(width: 120, height: 120)
                            Image(systemName: page.icon)
                                .font(.system(size: 48, weight: .medium))
                                .foregroundStyle(page.color)
                        }

                        // Title
                        Text(page.title)
                            .font(MCTypography.display)
                            .foregroundStyle(MCColors.textPrimary)
                            .multilineTextAlignment(.center)

                        // Subtitle
                        Text(page.subtitle)
                            .font(MCTypography.body)
                            .foregroundStyle(MCColors.textSecondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, MCSpacing.xl)

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
