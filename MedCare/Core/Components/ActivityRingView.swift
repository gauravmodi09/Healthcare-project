import SwiftUI

/// Apple Watch-style animated ring showing adherence percentage
struct ActivityRingView: View {
    let progress: Double
    var size: CGFloat = 80
    var lineWidth: CGFloat = 10
    var color: Color = MCColors.primaryTeal
    var showPercentage: Bool = true

    @State private var animatedProgress: Double = 0

    var body: some View {
        ZStack {
            // Background ring
            Circle()
                .stroke(color.opacity(0.15), style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))

            // Foreground ring
            Circle()
                .trim(from: 0, to: animatedProgress)
                .stroke(color, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
                .rotationEffect(.degrees(-90))

            // Percentage text
            if showPercentage {
                Text("\(Int(animatedProgress * 100))%")
                    .font(size >= 80 ? MCTypography.headline : MCTypography.captionBold)
                    .foregroundStyle(MCColors.textPrimary)
                    .contentTransition(.numericText())
            }
        }
        .frame(width: size, height: size)
        .onAppear {
            withAnimation(.easeInOut(duration: 0.8)) {
                animatedProgress = progress
            }
        }
        .onChange(of: progress) { _, newValue in
            withAnimation(.easeInOut(duration: 0.8)) {
                animatedProgress = newValue
            }
        }
    }
}

#Preview {
    VStack(spacing: MCSpacing.lg) {
        ActivityRingView(progress: 0.85)

        ActivityRingView(progress: 0.6, size: 60, lineWidth: 8, color: MCColors.warning)

        ActivityRingView(progress: 0.3, size: 40, lineWidth: 6, color: MCColors.accentCoral, showPercentage: false)
    }
    .padding()
}
