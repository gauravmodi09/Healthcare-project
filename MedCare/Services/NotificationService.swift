import Foundation
import UserNotifications

/// Manages local push notifications for medication reminders
final class NotificationService: Sendable {
    static nonisolated(unsafe) let shared = NotificationService()

    private init() {}

    func requestPermission() async -> Bool {
        do {
            let granted = try await UNUserNotificationCenter.current()
                .requestAuthorization(options: [.alert, .badge, .sound])
            if granted {
                await registerCategories()
            }
            return granted
        } catch {
            return false
        }
    }

    private func registerCategories() async {
        let takenAction = UNNotificationAction(
            identifier: "TAKEN",
            title: "✓ Taken",
            options: .foreground
        )
        let skipAction = UNNotificationAction(
            identifier: "SKIP",
            title: "Skip",
            options: .destructive
        )
        let snoozeAction = UNNotificationAction(
            identifier: "SNOOZE",
            title: "Snooze 15 min",
            options: []
        )

        let category = UNNotificationCategory(
            identifier: "DOSE_REMINDER",
            actions: [takenAction, skipAction, snoozeAction],
            intentIdentifiers: [],
            options: .customDismissAction
        )

        UNUserNotificationCenter.current().setNotificationCategories([category])
    }

    func scheduleDoseReminder(
        medicineId: UUID,
        medicineName: String,
        dosage: String,
        scheduledTime: Date,
        doseLogId: UUID
    ) async {
        let content = UNMutableNotificationContent()
        content.title = "Time for your medicine 💊"
        content.body = "\(medicineName) \(dosage)"
        content.sound = .default
        content.categoryIdentifier = "DOSE_REMINDER"
        content.interruptionLevel = .timeSensitive
        content.relevanceScore = 1.0
        content.userInfo = [
            "medicineId": medicineId.uuidString,
            "doseLogId": doseLogId.uuidString
        ]

        let components = Calendar.current.dateComponents(
            [.year, .month, .day, .hour, .minute],
            from: scheduledTime
        )
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)

        let request = UNNotificationRequest(
            identifier: doseLogId.uuidString,
            content: content,
            trigger: trigger
        )

        try? await UNUserNotificationCenter.current().add(request)
    }

    func cancelReminder(doseLogId: UUID) {
        UNUserNotificationCenter.current()
            .removePendingNotificationRequests(withIdentifiers: [doseLogId.uuidString])
    }

    func cancelAllReminders(for medicineId: UUID) {
        UNUserNotificationCenter.current().getPendingNotificationRequests { requests in
            let ids = requests
                .filter { ($0.content.userInfo["medicineId"] as? String) == medicineId.uuidString }
                .map { $0.identifier }
            UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: ids)
        }
    }

    func scheduleSnooze(
        medicineId: UUID,
        medicineName: String,
        dosage: String,
        doseLogId: UUID,
        minutes: Int = 15
    ) async {
        let content = UNMutableNotificationContent()
        content.title = "Snoozed reminder 💊"
        content.body = "\(medicineName) \(dosage) — take it now!"
        content.sound = .default
        content.categoryIdentifier = "DOSE_REMINDER"
        content.interruptionLevel = .timeSensitive
        content.relevanceScore = 1.0
        content.userInfo = [
            "medicineId": medicineId.uuidString,
            "doseLogId": doseLogId.uuidString
        ]

        let trigger = UNTimeIntervalNotificationTrigger(
            timeInterval: TimeInterval(minutes * 60),
            repeats: false
        )

        let request = UNNotificationRequest(
            identifier: "snooze_\(doseLogId.uuidString)",
            content: content,
            trigger: trigger
        )

        try? await UNUserNotificationCenter.current().add(request)
    }
}
