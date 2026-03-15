import SwiftUI

/// Full-screen emergency alert overlay
struct EmergencyAlertView: View {
    let emergencyType: EmergencyType
    var onDismiss: () -> Void

    @State private var pulseScale: CGFloat = 1.0

    var body: some View {
        ZStack {
            // Backdrop
            Color.black.opacity(0.7)
                .ignoresSafeArea()

            VStack(spacing: 24) {
                Spacer()

                // Pulsing warning icon
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.system(size: 64))
                    .foregroundColor(.white)
                    .scaleEffect(pulseScale)
                    .onAppear {
                        withAnimation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true)) {
                            pulseScale = 1.15
                        }
                    }

                // Title
                Text(emergencyType.displayTitle)
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)

                // Warning text
                Text("This sounds like it could be a medical emergency.\nPlease seek immediate help.")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.white.opacity(0.9))
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
                    .padding(.horizontal, 32)

                // Emergency actions
                VStack(spacing: 12) {
                    // Call 112
                    Button {
                        if let url = URL(string: "tel://112") {
                            UIApplication.shared.open(url)
                        }
                    } label: {
                        HStack(spacing: 10) {
                            Image(systemName: "phone.fill")
                                .font(.system(size: 20, weight: .bold))
                            Text("Call 112 (Emergency)")
                                .font(.system(size: 18, weight: .bold))
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(Color.red)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                    }

                    // Nearest Hospital
                    Button {
                        if let url = URL(string: "maps://?q=hospital+near+me") {
                            UIApplication.shared.open(url)
                        }
                    } label: {
                        HStack(spacing: 10) {
                            Image(systemName: "cross.case.fill")
                                .font(.system(size: 18, weight: .bold))
                            Text("Nearest Hospital")
                                .font(.system(size: 16, weight: .semibold))
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(Color.white.opacity(0.2))
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                    }
                }
                .padding(.horizontal, 24)

                // Disclaimer
                Text("⚠️ DO NOT rely on this app in an emergency.\nAlways call emergency services immediately.")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.white.opacity(0.6))
                    .multilineTextAlignment(.center)
                    .padding(.top, 8)

                Spacer()

                // Dismiss
                Button {
                    onDismiss()
                } label: {
                    Text("I understand, dismiss")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.white.opacity(0.5))
                        .padding(.bottom, 16)
                }
            }
        }
    }
}
