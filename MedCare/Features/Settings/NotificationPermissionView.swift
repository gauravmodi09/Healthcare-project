import SwiftUI
import UserNotifications

/// Pre-permission primer sheet shown before requesting iOS notification authorization.
/// Displayed on first launch (via @AppStorage flag) or from Notification settings when permission is denied.
struct NotificationPermissionView: View {
    @Environment(\.dismiss) private var dismiss
    @AppStorage("mc_has_shown_notification_primer") private var hasShownPrimer = false
    @State private var permissionGranted = false

    var body: some View {
        VStack(spacing: 28) {
            Spacer()

            // Icon
            Image(systemName: "bell.badge.fill")
                .font(.system(size: 56, weight: .light))
                .foregroundStyle(MCColors.primaryTeal)
                .symbolRenderingMode(.hierarchical)

            // Title
            Text("Never Miss a Dose")
                .font(.system(size: 26, weight: .bold))
                .foregroundStyle(MCColors.textPrimary)
                .multilineTextAlignment(.center)

            // Description
            Text("MedCare sends reminders when it\u{2019}s time for your medicine. You\u{2019}ll get:")
                .font(.system(size: 15))
                .foregroundStyle(MCColors.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 24)

            // Bullet points
            VStack(alignment: .leading, spacing: 16) {
                bulletRow(emoji: "\u{1F48A}", text: "Dose reminders at the right time")
                bulletRow(emoji: "\u{1F514}", text: "Refill alerts when stock is low")
                bulletRow(emoji: "\u{1F468}\u{200D}\u{2695}\u{FE0F}", text: "Messages from your doctor")
                bulletRow(emoji: "\u{1F4CA}", text: "Weekly health reports")
            }
            .padding(.horizontal, 32)

            Spacer()

            // Primary button
            Button {
                Task {
                    let granted = await requestNotificationPermission()
                    permissionGranted = granted
                    hasShownPrimer = true
                    dismiss()
                }
            } label: {
                Text("Allow Notifications")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 52)
                    .background(
                        LinearGradient(
                            colors: [MCColors.primaryTeal, MCColors.primaryTealDark],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            }
            .padding(.horizontal, 24)

            // Secondary button
            Button {
                hasShownPrimer = true
                dismiss()
            } label: {
                Text("Maybe Later")
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(MCColors.textSecondary)
            }
            .padding(.bottom, 16)
        }
        .padding(.vertical, 20)
        .background(MCColors.backgroundLight)
        .interactiveDismissDisabled()
    }

    // MARK: - Bullet Row

    private func bulletRow(emoji: String, text: String) -> some View {
        HStack(spacing: 12) {
            Text(emoji)
                .font(.system(size: 22))
            Text(text)
                .font(.system(size: 15, weight: .medium))
                .foregroundStyle(MCColors.textPrimary)
        }
    }

    // MARK: - Request Permission

    private func requestNotificationPermission() async -> Bool {
        do {
            let granted = try await UNUserNotificationCenter.current()
                .requestAuthorization(options: [.alert, .badge, .sound])
            if granted {
                await NotificationService.shared.registerCategories()
            }
            return granted
        } catch {
            return false
        }
    }
}

#Preview {
    NotificationPermissionView()
}
