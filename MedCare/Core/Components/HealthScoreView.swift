import SwiftUI

/// Composite health score display (0-100)
struct HealthScoreView: View {
    let score: Int
    var compact: Bool = false

    @State private var animatedScore: Int = 0

    private var scoreColor: Color {
        switch score {
        case 0..<40: return MCColors.error
        case 40..<70: return MCColors.warning
        default: return MCColors.success
        }
    }

    var body: some View {
        if compact {
            compactView
        } else {
            fullView
        }
    }

    // MARK: - Full View

    private var fullView: some View {
        VStack(spacing: MCSpacing.xs) {
            ActivityRingView(
                progress: Double(score) / 100.0,
                size: 100,
                lineWidth: 12,
                color: scoreColor,
                showPercentage: false
            )
            .overlay {
                Text("\(animatedScore)")
                    .font(MCTypography.display)
                    .foregroundStyle(MCColors.textPrimary)
                    .contentTransition(.numericText())
            }

            Text("Health Score")
                .font(MCTypography.subheadline)
                .foregroundStyle(MCColors.textSecondary)
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 0.8)) {
                animatedScore = score
            }
        }
        .onChange(of: score) { _, newValue in
            withAnimation(.easeInOut(duration: 0.8)) {
                animatedScore = newValue
            }
        }
    }

    // MARK: - Compact View

    private var compactView: some View {
        HStack(spacing: MCSpacing.xxs) {
            Circle()
                .fill(scoreColor)
                .frame(width: 8, height: 8)

            Text("\(animatedScore)")
                .font(MCTypography.captionBold)
                .foregroundStyle(scoreColor)
                .contentTransition(.numericText())
        }
        .padding(.horizontal, MCSpacing.xs)
        .padding(.vertical, MCSpacing.xxs)
        .background(scoreColor.opacity(0.12))
        .clipShape(Capsule())
        .onAppear {
            withAnimation(.easeInOut(duration: 0.8)) {
                animatedScore = score
            }
        }
        .onChange(of: score) { _, newValue in
            withAnimation(.easeInOut(duration: 0.8)) {
                animatedScore = newValue
            }
        }
    }
}

#Preview {
    VStack(spacing: MCSpacing.xl) {
        HealthScoreView(score: 85)

        HealthScoreView(score: 55)

        HealthScoreView(score: 25)

        HStack(spacing: MCSpacing.md) {
            HealthScoreView(score: 85, compact: true)
            HealthScoreView(score: 55, compact: true)
            HealthScoreView(score: 25, compact: true)
        }
    }
    .padding()
}
