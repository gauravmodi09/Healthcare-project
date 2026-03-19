import Foundation
import UserNotifications

/// Manages local push notifications for medication reminders
final class NotificationService: Sendable {
    static let shared = NotificationService()

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

        // Critical dose reminder category with urgent actions
        let criticalTakenAction = UNNotificationAction(
            identifier: "TAKEN",
            title: "✓ Taken",
            options: .foreground
        )
        let criticalCallDoctorAction = UNNotificationAction(
            identifier: "CALL_DOCTOR",
            title: "📞 Call Doctor",
            options: .foreground
        )
        let criticalCategory = UNNotificationCategory(
            identifier: "CRITICAL_DOSE_REMINDER",
            actions: [criticalTakenAction, criticalCallDoctorAction],
            intentIdentifiers: [],
            options: .customDismissAction
        )

        UNUserNotificationCenter.current().setNotificationCategories([category, criticalCategory])
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

    // MARK: - Critical Dose Reminders

    /// Schedules escalating reminders for critical medicines (blood thinners, insulin, etc.)
    /// - Initial: time-sensitive notification at scheduled time with `.critical` interruption level
    /// - 30 min follow-up: second notification with prominent sound if not yet taken
    /// - 60 min escalation: notification to emergency contact if set and still not taken
    func scheduleCriticalDoseReminder(medicine: Medicine, doseLog: DoseLog, emergencyContact: String? = nil) async {
        let medicineId = medicine.id
        let doseLogId = doseLog.id
        let medicineName = medicine.brandName
        let dosage = medicine.dosage
        let scheduledTime = doseLog.scheduledTime

        // 1. Primary critical notification at scheduled time
        let primaryContent = UNMutableNotificationContent()
        primaryContent.title = "🚨 Critical Medicine Due"
        primaryContent.body = "\(medicineName) \(dosage) — this is a critical medicine. Please take it now."
        primaryContent.sound = .defaultCritical
        primaryContent.categoryIdentifier = "CRITICAL_DOSE_REMINDER"
        primaryContent.interruptionLevel = .critical
        primaryContent.relevanceScore = 1.0
        primaryContent.userInfo = [
            "medicineId": medicineId.uuidString,
            "doseLogId": doseLogId.uuidString,
            "isCritical": true
        ]

        let primaryComponents = Calendar.current.dateComponents(
            [.year, .month, .day, .hour, .minute],
            from: scheduledTime
        )
        let primaryTrigger = UNCalendarNotificationTrigger(dateMatching: primaryComponents, repeats: false)

        let primaryRequest = UNNotificationRequest(
            identifier: "critical_\(doseLogId.uuidString)",
            content: primaryContent,
            trigger: primaryTrigger
        )
        try? await UNUserNotificationCenter.current().add(primaryRequest)

        // 2. Follow-up at 30 minutes if not taken
        let followUpContent = UNMutableNotificationContent()
        followUpContent.title = "⚠️ \(medicineName) Still Pending!"
        followUpContent.body = "It's been 30 minutes. \(medicineName) \(dosage) is a critical medicine — please take it as soon as possible."
        followUpContent.sound = UNNotificationSound.defaultCritical
        followUpContent.categoryIdentifier = "CRITICAL_DOSE_REMINDER"
        followUpContent.interruptionLevel = .critical
        followUpContent.relevanceScore = 1.0
        followUpContent.userInfo = [
            "medicineId": medicineId.uuidString,
            "doseLogId": doseLogId.uuidString,
            "isCritical": true,
            "isFollowUp": true
        ]

        guard let followUpTime = Calendar.current.date(byAdding: .minute, value: 30, to: scheduledTime) else { return }
        let followUpComponents = Calendar.current.dateComponents(
            [.year, .month, .day, .hour, .minute],
            from: followUpTime
        )
        let followUpTrigger = UNCalendarNotificationTrigger(dateMatching: followUpComponents, repeats: false)

        let followUpRequest = UNNotificationRequest(
            identifier: "critical_30m_\(doseLogId.uuidString)",
            content: followUpContent,
            trigger: followUpTrigger
        )
        try? await UNUserNotificationCenter.current().add(followUpRequest)

        // 3. Emergency contact escalation at 60 minutes if not taken
        guard let emergencyContactNumber = emergencyContact, !emergencyContactNumber.isEmpty else { return }

        let emergencyContent = UNMutableNotificationContent()
        emergencyContent.title = "🚨 Missed Critical Medicine — 1 Hour"
        emergencyContent.body = "\(medicineName) \(dosage) has not been taken for over 1 hour. Consider contacting the patient or their doctor. Emergency contact: \(emergencyContactNumber)"
        emergencyContent.sound = UNNotificationSound.defaultCritical
        emergencyContent.categoryIdentifier = "CRITICAL_DOSE_REMINDER"
        emergencyContent.interruptionLevel = .critical
        emergencyContent.relevanceScore = 1.0
        emergencyContent.userInfo = [
            "medicineId": medicineId.uuidString,
            "doseLogId": doseLogId.uuidString,
            "isCritical": true,
            "isEmergencyEscalation": true,
            "emergencyContact": emergencyContactNumber
        ]

        guard let emergencyTime = Calendar.current.date(byAdding: .minute, value: 60, to: scheduledTime) else { return }
        let emergencyComponents = Calendar.current.dateComponents(
            [.year, .month, .day, .hour, .minute],
            from: emergencyTime
        )
        let emergencyTrigger = UNCalendarNotificationTrigger(dateMatching: emergencyComponents, repeats: false)

        let emergencyRequest = UNNotificationRequest(
            identifier: "critical_60m_\(doseLogId.uuidString)",
            content: emergencyContent,
            trigger: emergencyTrigger
        )
        try? await UNUserNotificationCenter.current().add(emergencyRequest)
    }

    /// Cancels all critical dose reminder notifications (primary + follow-ups) for a given dose log
    func cancelCriticalReminders(doseLogId: UUID) {
        let identifiers = [
            "critical_\(doseLogId.uuidString)",
            "critical_30m_\(doseLogId.uuidString)",
            "critical_60m_\(doseLogId.uuidString)"
        ]
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: identifiers)
    }
}
