import SwiftUI

/// Badge levels for adherence streaks
enum StreakLevel: Comparable {
    case none
    case bronze   // 3+ days
    case silver   // 7+ days
    case gold     // 14+ days
    case diamond  // 30+ days
    case platinum // 100+ days

    init(streak: Int) {
        switch streak {
        case 100...: self = .platinum
        case 30...:  self = .diamond
        case 14...:  self = .gold
        case 7...:   self = .silver
        case 3...:   self = .bronze
        default:     self = .none
        }
    }

    var label: String {
        switch self {
        case .none:     return "Starting"
        case .bronze:   return "Bronze"
        case .silver:   return "Silver"
        case .gold:     return "Gold"
        case .diamond:  return "Diamond"
        case .platinum: return "Platinum"
        }
    }

    var icon: String {
        switch self {
        case .none:     return "flame"
        case .bronze:   return "flame.fill"
        case .silver:   return "flame.fill"
        case .gold:     return "flame.fill"
        case .diamond:  return "sparkle"
        case .platinum: return "crown.fill"
        }
    }

    var color: Color {
        switch self {
        case .none:     return MCColors.textTertiary
        case .bronze:   return Color(hex: "CD7F32")
        case .silver:   return Color(hex: "8E9AAF")
        case .gold:     return Color(hex: "DAA520")
        case .diamond:  return Color(hex: "6EC6E6")
        case .platinum: return Color(hex: "9B59B6")
        }
    }

    var gradientColors: [Color] {
        switch self {
        case .none:     return [MCColors.textTertiary, MCColors.textTertiary]
        case .bronze:   return [Color(hex: "CD7F32"), Color(hex: "B87333")]
        case .silver:   return [Color(hex: "C0C0C0"), Color(hex: "8E9AAF")]
        case .gold:     return [Color(hex: "FFD700"), Color(hex: "DAA520")]
        case .diamond:  return [Color(hex: "6EC6E6"), Color(hex: "4FA8D5")]
        case .platinum: return [Color(hex: "9B59B6"), Color(hex: "8E44AD")]
        }
    }

    /// Milestones that trigger celebration
    static let milestones: [Int] = [3, 7, 14, 30, 100]
}

/// Reusable streak badge showing current adherence streak
struct StreakBadgeView: View {
    let streak: Int
    var compact: Bool = false
    var showCelebration: Bool = false

    @State private var animateFlame = false
    @State private var showConfetti = false

    private var level: StreakLevel { StreakLevel(streak: streak) }

    var body: some View {
        ZStack {
            if compact {
                compactBadge
            } else {
                fullBadge
            }

            if showConfetti {
                ConfettiView()
                    .allowsHitTesting(false)
            }
        }
        .onAppear {
            if showCelebration && StreakLevel.milestones.contains(streak) {
                withAnimation(.spring(response: 0.5, dampingFraction: 0.6)) {
                    animateFlame = true
                }
                showConfetti = true
                DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
                    showConfetti = false
                }
            }
        }
    }

    // MARK: - Compact Badge (inline use)

    private var compactBadge: some View {
        HStack(spacing: MCSpacing.xxs) {
            Image(systemName: level.icon)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(level.color)
                .scaleEffect(animateFlame ? 1.2 : 1.0)

            Text("\(streak)")
                .font(MCTypography.captionBold)
                .foregroundStyle(level.color)
        }
        .padding(.horizontal, MCSpacing.xs)
        .padding(.vertical, MCSpacing.xxs)
        .background(level.color.opacity(0.12))
        .clipShape(Capsule())
    }

    // MARK: - Full Badge (standalone use)

    private var fullBadge: some View {
        VStack(spacing: MCSpacing.xs) {
            // Badge circle
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: level.gradientColors,
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 64, height: 64)
                    .shadow(color: level.color.opacity(0.3), radius: 8, y: 4)

                VStack(spacing: 0) {
                    Image(systemName: level.icon)
                        .font(.system(size: 20, weight: .bold))
                        .foregroundStyle(.white)
                        .scaleEffect(animateFlame ? 1.3 : 1.0)
                        .animation(
                            animateFlame
                                ? .easeInOut(duration: 0.4).repeatCount(3, autoreverses: true)
                                : .default,
                            value: animateFlame
                        )

                    Text("\(streak)")
                        .font(.system(size: 16, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                }
            }

            // Level label
            Text(level.label)
                .font(MCTypography.captionBold)
                .foregroundStyle(level.color)

            // Streak description
            Text("\(streak) day streak")
                .font(MCTypography.caption)
                .foregroundStyle(MCColors.textSecondary)
        }
    }
}

// MARK: - Preview Helpers

#Preview("Streak Badges") {
    VStack(spacing: MCSpacing.lg) {
        HStack(spacing: MCSpacing.lg) {
            StreakBadgeView(streak: 1)
            StreakBadgeView(streak: 5)
            StreakBadgeView(streak: 10)
        }
        HStack(spacing: MCSpacing.lg) {
            StreakBadgeView(streak: 20)
            StreakBadgeView(streak: 45)
            StreakBadgeView(streak: 120)
        }
        Divider()
        HStack(spacing: MCSpacing.sm) {
            StreakBadgeView(streak: 7, compact: true)
            StreakBadgeView(streak: 14, compact: true)
            StreakBadgeView(streak: 30, compact: true)
            StreakBadgeView(streak: 100, compact: true)
        }
    }
    .padding()
}
