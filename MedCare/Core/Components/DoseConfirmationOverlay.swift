import SwiftUI

/// Satisfying full-screen overlay animation when a dose is confirmed as taken
struct DoseConfirmationOverlay: View {
    let medicineName: String
    var streakCount: Int = 0
    let onDismiss: () -> Void

    @State private var showCheck = false
    @State private var showText = false
    @State private var showStreak = false
    @State private var circleScale: CGFloat = 0
    @State private var checkTrim: CGFloat = 0
    @State private var bounceScale: CGFloat = 0.8

    /// Streak milestones that trigger the celebration text
    private var isStreakMilestone: Bool {
        let milestones = [3, 7, 14, 21, 30, 60, 90, 100]
        return milestones.contains(streakCount)
    }

    var body: some View {
        ZStack {
            // Backdrop
            Color.black.opacity(0.3)
                .ignoresSafeArea()
                .onTapGesture { onDismiss() }

            VStack(spacing: 16) {
                // Animated checkmark circle
                ZStack {
                    // Outer ring pulse
                    Circle()
                        .stroke(MCColors.success.opacity(0.3), lineWidth: 3)
                        .frame(width: 100, height: 100)
                        .scaleEffect(circleScale * 1.3)
                        .opacity(showCheck ? 0.0 : 0.5)

                    // Inner filled circle with bounce
                    Circle()
                        .fill(MCColors.success)
                        .frame(width: 80, height: 80)
                        .scaleEffect(bounceScale)

                    // Animated checkmark that draws itself (stroke animation)
                    CheckmarkShape()
                        .trim(from: 0, to: checkTrim)
                        .stroke(.white, style: StrokeStyle(lineWidth: 4, lineCap: .round, lineJoin: .round))
                        .frame(width: 36, height: 36)
                        .scaleEffect(bounceScale)
                }

                // "Taken!" text fades in below
                if showText {
                    VStack(spacing: 4) {
                        Text("Taken!")
                            .font(MCTypography.title)
                            .foregroundStyle(.white)
                        Text(medicineName)
                            .font(MCTypography.callout)
                            .foregroundStyle(.white.opacity(0.8))
                    }
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                }

                // Streak milestone celebration
                if showStreak && isStreakMilestone {
                    Text("\u{1F525} \(streakCount) day streak!")
                        .font(.system(size: 18, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 8)
                        .background(
                            Capsule()
                                .fill(
                                    LinearGradient(
                                        colors: [Color.orange, Color.red.opacity(0.8)],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                        )
                        .transition(.scale.combined(with: .opacity))
                }
            }
        }
        .onAppear {
            performAnimationSequence()
        }
    }

    private func performAnimationSequence() {
        // 1. Circle scale-in with bounce: 0.8 -> 1.1 -> 1.0
        withAnimation(.spring(response: 0.4, dampingFraction: 0.6)) {
            circleScale = 1
            bounceScale = 1.1
        }

        // Settle bounce to 1.0
        withAnimation(.spring(response: 0.2, dampingFraction: 0.7).delay(0.25)) {
            bounceScale = 1.0
        }

        // 2. Checkmark stroke draws itself
        withAnimation(.easeOut(duration: 0.4).delay(0.15)) {
            checkTrim = 1.0
            showCheck = true
        }

        // 3. Haptic feedback — success notification
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            let notif = UINotificationFeedbackGenerator()
            notif.notificationOccurred(.success)
        }

        // 4. "Taken!" text fades in
        withAnimation(.easeOut(duration: 0.3).delay(0.4)) {
            showText = true
        }

        // 5. Streak milestone appears (if applicable)
        if isStreakMilestone {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.65).delay(0.7)) {
                showStreak = true
            }

            // Extra haptic for streak milestone
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.7) {
                let impact = UIImpactFeedbackGenerator(style: .heavy)
                impact.impactOccurred()
            }
        }

        // 6. Auto-dismiss after 1.5 seconds
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            withAnimation(.easeOut(duration: 0.2)) {
                onDismiss()
            }
        }
    }
}

// MARK: - Custom Checkmark Shape for Stroke Animation

/// A custom shape that draws a checkmark path, enabling trim-based stroke animation
private struct CheckmarkShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        // Start from lower-left area, go to bottom-center, then up to top-right
        let startPoint = CGPoint(x: rect.width * 0.15, y: rect.height * 0.55)
        let midPoint = CGPoint(x: rect.width * 0.40, y: rect.height * 0.80)
        let endPoint = CGPoint(x: rect.width * 0.85, y: rect.height * 0.20)

        path.move(to: startPoint)
        path.addLine(to: midPoint)
        path.addLine(to: endPoint)

        return path
    }
}
