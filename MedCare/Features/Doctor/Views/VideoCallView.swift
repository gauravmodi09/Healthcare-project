import SwiftUI

// MARK: - Contact Options View (replaces mock video call)

struct VideoCallView: View {
    let patientName: String
    let doctorName: String
    let patientSummary: String
    var phoneNumber: String

    @Environment(\.dismiss) private var dismiss
    @State private var showWhatsAppAlert = false

    init(
        patientName: String = "Ramesh Kumar",
        doctorName: String = "Dr. Anil Mehta",
        patientSummary: String = "Hypertension, 58y, BP: 162/98",
        phoneNumber: String = ""
    ) {
        self.patientName = patientName
        self.doctorName = doctorName
        self.patientSummary = patientSummary
        self.phoneNumber = phoneNumber
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: MCSpacing.sectionSpacing) {
                    // Header
                    contactHeader

                    // Patient summary
                    patientCard

                    // Contact options
                    contactOptions

                    // Info note
                    infoNote
                }
                .padding(.vertical, MCSpacing.md)
            }
            .background(MCColors.backgroundLight)
            .navigationTitle("Contact Options")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                }
            }
            .alert("WhatsApp Not Available", isPresented: $showWhatsAppAlert) {
                Button("OK", role: .cancel) {}
            } message: {
                Text("WhatsApp is not installed on this device. Please install it from the App Store to make WhatsApp calls.")
            }
        }
    }

    // MARK: - Header

    private var contactHeader: some View {
        VStack(spacing: MCSpacing.sm) {
            ZStack {
                Circle()
                    .fill(MCColors.primaryTeal.opacity(0.15))
                    .frame(width: 80, height: 80)
                Image(systemName: "person.fill")
                    .font(.system(size: 32, weight: .semibold))
                    .foregroundStyle(MCColors.primaryTeal)
            }

            Text(doctorName.isEmpty ? patientName : doctorName)
                .font(MCTypography.title2)
                .foregroundStyle(MCColors.textPrimary)

            Text("Choose how to connect")
                .font(MCTypography.subheadline)
                .foregroundStyle(MCColors.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, MCSpacing.screenPadding)
    }

    // MARK: - Patient Card

    private var patientCard: some View {
        MCCard {
            VStack(alignment: .leading, spacing: MCSpacing.xs) {
                HStack(spacing: MCSpacing.xs) {
                    Image(systemName: "person.text.rectangle")
                        .foregroundStyle(MCColors.primaryTeal)
                        .font(.system(size: 14))
                    Text("PATIENT INFO")
                        .font(MCTypography.sectionHeader)
                        .foregroundStyle(MCColors.textSecondary)
                        .kerning(1.2)
                }
                Text(patientName)
                    .font(MCTypography.headline)
                    .foregroundStyle(MCColors.textPrimary)
                if !patientSummary.isEmpty {
                    Text(patientSummary)
                        .font(MCTypography.caption)
                        .foregroundStyle(MCColors.textSecondary)
                }
            }
        }
        .padding(.horizontal, MCSpacing.screenPadding)
    }

    // MARK: - Contact Options

    private var contactOptions: some View {
        VStack(spacing: MCSpacing.sm) {
            // Phone call
            contactOptionButton(
                icon: "phone.fill",
                title: "Call \(doctorName.isEmpty ? "Patient" : "Doctor")",
                subtitle: phoneNumber.isEmpty ? "Phone number not available" : "Direct phone call",
                color: MCColors.success,
                disabled: phoneNumber.isEmpty
            ) {
                makePhoneCall()
            }

            // WhatsApp call
            contactOptionButton(
                icon: "bubble.left.and.bubble.right.fill",
                title: "WhatsApp Call",
                subtitle: phoneNumber.isEmpty ? "Phone number not available" : "Audio or video via WhatsApp",
                color: Color(hex: "25D366"),
                disabled: phoneNumber.isEmpty
            ) {
                makeWhatsAppCall()
            }

            // Video call (coming soon)
            contactOptionButton(
                icon: "video.fill",
                title: "Video Call",
                subtitle: "Coming soon -- requires WebRTC integration",
                color: MCColors.textTertiary,
                disabled: true
            ) {
                // No action
            }
        }
        .padding(.horizontal, MCSpacing.screenPadding)
    }

    private func contactOptionButton(
        icon: String,
        title: String,
        subtitle: String,
        color: Color,
        disabled: Bool,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            MCCard {
                HStack(spacing: MCSpacing.sm) {
                    Image(systemName: icon)
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundStyle(disabled ? MCColors.textTertiary : color)
                        .frame(width: 48, height: 48)
                        .background((disabled ? MCColors.textTertiary : color).opacity(0.12))
                        .clipShape(Circle())

                    VStack(alignment: .leading, spacing: MCSpacing.xxs) {
                        Text(title)
                            .font(MCTypography.headline)
                            .foregroundStyle(disabled ? MCColors.textTertiary : MCColors.textPrimary)
                        Text(subtitle)
                            .font(MCTypography.caption)
                            .foregroundStyle(MCColors.textSecondary)
                    }

                    Spacer()

                    if disabled {
                        Text("N/A")
                            .font(MCTypography.captionBold)
                            .foregroundStyle(MCColors.textTertiary)
                            .padding(.horizontal, MCSpacing.xs)
                            .padding(.vertical, MCSpacing.xxs)
                            .background(MCColors.textTertiary.opacity(0.1))
                            .clipShape(Capsule())
                    } else {
                        Image(systemName: "chevron.right")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundStyle(color)
                    }
                }
            }
        }
        .disabled(disabled)
    }

    // MARK: - Info Note

    private var infoNote: some View {
        MCCard {
            HStack(alignment: .top, spacing: MCSpacing.sm) {
                Image(systemName: "info.circle.fill")
                    .foregroundStyle(MCColors.info)
                    .font(.system(size: 16))

                VStack(alignment: .leading, spacing: MCSpacing.xxs) {
                    Text("About Calling")
                        .font(MCTypography.captionBold)
                        .foregroundStyle(MCColors.textPrimary)
                    Text("Phone and WhatsApp calls use your device's native calling. Video consultations via the app will be available in a future update.")
                        .font(MCTypography.caption)
                        .foregroundStyle(MCColors.textSecondary)
                }
            }
        }
        .padding(.horizontal, MCSpacing.screenPadding)
        .padding(.bottom, MCSpacing.lg)
    }

    // MARK: - Actions

    private func makePhoneCall() {
        let cleaned = phoneNumber.replacingOccurrences(of: " ", with: "")
        guard let url = URL(string: "tel://\(cleaned)"),
              UIApplication.shared.canOpenURL(url) else { return }
        UIApplication.shared.open(url)
    }

    private func makeWhatsAppCall() {
        let cleaned = phoneNumber.replacingOccurrences(of: " ", with: "")
        // Try WhatsApp URL scheme
        if let url = URL(string: "whatsapp://send?phone=\(cleaned)"),
           UIApplication.shared.canOpenURL(url) {
            UIApplication.shared.open(url)
        } else {
            showWhatsAppAlert = true
        }
    }
}

#Preview {
    VideoCallView(phoneNumber: "9876543210")
}
