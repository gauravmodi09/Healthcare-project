import SwiftUI

/// Satisfying full-screen overlay animation when a dose is confirmed as taken
struct DoseConfirmationOverlay: View {
    let medicineName: String
    let onDismiss: () -> Void

    @State private var showCheck = false
    @State private var showText = false
    @State private var circleScale: CGFloat = 0

    var body: some View {
        ZStack {
            // Backdrop
            Color.black.opacity(0.3)
                .ignoresSafeArea()
                .onTapGesture { onDismiss() }

            VStack(spacing: MCSpacing.md) {
                // Animated checkmark circle
                ZStack {
                    // Outer ring pulse
                    Circle()
                        .stroke(MCColors.success.opacity(0.3), lineWidth: 3)
                        .frame(width: 100, height: 100)
                        .scaleEffect(circleScale * 1.3)
                        .opacity(showCheck ? 0.0 : 0.5)

                    // Inner filled circle
                    Circle()
                        .fill(MCColors.success)
                        .frame(width: 80, height: 80)
                        .scaleEffect(circleScale)

                    // Checkmark
                    Image(systemName: "checkmark")
                        .font(.system(size: 36, weight: .bold))
                        .foregroundStyle(.white)
                        .scaleEffect(showCheck ? 1 : 0)
                        .rotationEffect(.degrees(showCheck ? 0 : -30))
                }

                // Medicine name
                if showText {
                    VStack(spacing: MCSpacing.xxs) {
                        Text("Dose Taken!")
                            .font(MCTypography.title)
                            .foregroundStyle(.white)
                        Text(medicineName)
                            .font(MCTypography.callout)
                            .foregroundStyle(.white.opacity(0.8))
                    }
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }
        }
        .onAppear {
            // Haptic feedback
            let impact = UIImpactFeedbackGenerator(style: .medium)
            impact.impactOccurred()

            withAnimation(.spring(response: 0.4, dampingFraction: 0.6)) {
                circleScale = 1
            }

            withAnimation(.spring(response: 0.3, dampingFraction: 0.5).delay(0.15)) {
                showCheck = true
            }

            // Success haptic
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                let notif = UINotificationFeedbackGenerator()
                notif.notificationOccurred(.success)
            }

            withAnimation(.easeOut(duration: 0.3).delay(0.3)) {
                showText = true
            }

            // Auto-dismiss
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                withAnimation(.easeOut(duration: 0.2)) {
                    onDismiss()
                }
            }
        }
    }
}
