import SwiftUI

struct SplashScreen: View {
    @State private var scale: CGFloat = 0.8
    @State private var opacity: Double = 0
    @State private var taglineOpacity: Double = 0

    var body: some View {
        ZStack {
            MCColors.primaryGradient
                .ignoresSafeArea()

            VStack(spacing: MCSpacing.lg) {
                // App icon
                ZStack {
                    Circle()
                        .fill(.white.opacity(0.2))
                        .frame(width: 120, height: 120)

                    Image(systemName: "heart.text.clipboard")
                        .font(.system(size: 52, weight: .medium))
                        .foregroundStyle(.white)
                }
                .scaleEffect(scale)

                VStack(spacing: MCSpacing.xs) {
                    Text("MedCare")
                        .font(.system(size: 36, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)

                    Text("Your Smart Health Companion")
                        .font(MCTypography.callout)
                        .foregroundStyle(.white.opacity(0.8))
                        .opacity(taglineOpacity)
                }
            }
            .opacity(opacity)
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.6)) {
                scale = 1.0
                opacity = 1.0
            }
            withAnimation(.easeOut(duration: 0.6).delay(0.4)) {
                taglineOpacity = 1.0
            }
        }
    }
}
