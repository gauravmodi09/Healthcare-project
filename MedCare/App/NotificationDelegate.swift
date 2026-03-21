import Foundation
import UserNotifications
import SwiftData

/// Handles notification action responses (Take Now, Snooze, Skip) and foreground presentation.
/// Wired up via MedCareApp on launch.
final class NotificationDelegate: NSObject, UNUserNotificationCenterDelegate, @unchecked Sendable {

    let modelContainer: ModelContainer

    init(modelContainer: ModelContainer) {
        self.modelContainer = modelContainer
        super.init()
    }

    // MARK: - Show notifications even when app is in foreground

    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification
    ) async -> UNNotificationPresentationOptions {
        [.banner, .sound, .badge]
    }

    // MARK: - Handle notification action responses

    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse
    ) async {
        let userInfo = response.notification.request.content.userInfo
        guard let doseLogIdString = userInfo["doseLogId"] as? String,
              let doseLogId = UUID(uuidString: doseLogIdString)
        else { return }

        let medicineId = (userInfo["medicineId"] as? String).flatMap(UUID.init)
        let medicineName = userInfo["medicineName"] as? String

        // Handle custom reminder actions separately
        let isCustomReminder = userInfo["isCustomReminder"] as? Bool ?? false
        if isCustomReminder {
            if let reminderIdString = userInfo["customReminderId"] as? String,
               let reminderId = UUID(uuidString: reminderIdString) {
                switch response.actionIdentifier {
                case "CUSTOM_REMINDER_DONE":
                    await handleCustomReminderDone(reminderId: reminderId)
                case "CUSTOM_REMINDER_SNOOZE":
                    await handleCustomReminderSnooze(reminderId: reminderId)
                default:
                    break
                }
            }
            return
        }

        switch response.actionIdentifier {
        case "TAKE_NOW", "TAKEN":
            await handleTakeNow(doseLogId: doseLogId)

        case "SNOOZE":
            await handleSnooze(doseLogId: doseLogId, medicineId: medicineId)

        case "SKIP":
            await handleSkip(doseLogId: doseLogId)

        case UNNotificationDefaultActionIdentifier:
            // User tapped the notification body — no special handling, app opens naturally
            break

        case UNNotificationDismissActionIdentifier:
            // User dismissed — do nothing, follow-up notifications will still fire
            break

        default:
            break
        }
    }

    // MARK: - Action Handlers

    @MainActor
    private func handleTakeNow(doseLogId: UUID) async {
        guard let doseLog = fetchDoseLog(id: doseLogId) else { return }
        doseLog.markTaken()
        try? modelContainer.mainContext.save()

        // Cancel any remaining persistent/critical follow-up notifications
        NotificationService.shared.cancelPersistentReminders(doseLogId: doseLogId)
        NotificationService.shared.cancelCriticalReminders(doseLogId: doseLogId)
        NotificationService.shared.cancelReminder(doseLogId: doseLogId)
    }

    @MainActor
    private func handleSnooze(doseLogId: UUID, medicineId: UUID?) async {
        guard let doseLog = fetchDoseLog(id: doseLogId) else { return }
        doseLog.markSnoozed()

        // Cancel pending follow-ups — the snooze replaces them
        NotificationService.shared.cancelPersistentReminders(doseLogId: doseLogId)
        NotificationService.shared.cancelCriticalReminders(doseLogId: doseLogId)

        // Schedule a new snooze reminder in 15 minutes
        if let medicine = doseLog.medicine {
            let snoozedDose = DoseLog(scheduledTime: Date().addingTimeInterval(15 * 60))
            medicine.doseLogs.append(snoozedDose)
            modelContainer.mainContext.insert(snoozedDose)

            // Schedule notification for the snoozed dose
            await NotificationService.shared.scheduleSnooze(
                medicineId: medicine.id,
                medicineName: medicine.brandName,
                dosage: medicine.dosage,
                doseLogId: snoozedDose.id
            )

            // If medicine is critical, also schedule persistent follow-ups for the snoozed dose
            if medicine.isCritical {
                let snoozeTime = Date().addingTimeInterval(15 * 60)
                await NotificationService.shared.schedulePersistentDoseReminder(
                    medicineId: medicine.id,
                    medicineName: medicine.brandName,
                    dosage: medicine.dosage,
                    scheduledTime: snoozeTime,
                    doseLogId: snoozedDose.id
                )
            }
        }

        try? modelContainer.mainContext.save()
    }

    @MainActor
    private func handleSkip(doseLogId: UUID) async {
        guard let doseLog = fetchDoseLog(id: doseLogId) else { return }
        doseLog.markSkipped(reason: "Skipped from notification")
        try? modelContainer.mainContext.save()

        // Cancel any remaining follow-up notifications
        NotificationService.shared.cancelPersistentReminders(doseLogId: doseLogId)
        NotificationService.shared.cancelCriticalReminders(doseLogId: doseLogId)
        NotificationService.shared.cancelReminder(doseLogId: doseLogId)
    }

    // MARK: - Custom Reminder Handlers

    @MainActor
    private func handleCustomReminderDone(reminderId: UUID) async {
        guard let reminder = fetchCustomReminder(id: reminderId) else { return }
        reminder.isCompleted = true
        try? modelContainer.mainContext.save()
        NotificationService.shared.cancelCustomReminder(id: reminderId)
    }

    @MainActor
    private func handleCustomReminderSnooze(reminderId: UUID) async {
        guard let reminder = fetchCustomReminder(id: reminderId) else { return }
        await NotificationService.shared.snoozeCustomReminder(
            id: reminderId,
            title: reminder.title,
            notes: reminder.notes
        )
    }

    // MARK: - Helpers

    @MainActor
    private func fetchDoseLog(id: UUID) -> DoseLog? {
        let descriptor = FetchDescriptor<DoseLog>()
        guard let doseLogs = try? modelContainer.mainContext.fetch(descriptor) else { return nil }
        return doseLogs.first(where: { $0.id == id })
    }

    @MainActor
    private func fetchCustomReminder(id: UUID) -> CustomReminder? {
        let descriptor = FetchDescriptor<CustomReminder>()
        guard let reminders = try? modelContainer.mainContext.fetch(descriptor) else { return nil }
        return reminders.first(where: { $0.id == id })
    }
}
