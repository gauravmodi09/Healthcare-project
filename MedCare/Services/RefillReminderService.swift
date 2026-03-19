import Foundation
import UserNotifications

// MARK: - Input/Output Structs

struct MedicineStockInfo {
    let id: UUID
    let brandName: String
    let totalPillCount: Int
    let dosesPerDay: Int
    let dosesTaken: Int
    let startDate: Date
}

struct LowStockAlert: Identifiable {
    let id: UUID
    let medicineName: String
    let remainingPills: Int
    let estimatedDaysLeft: Int
    let urgency: RefillUrgency
    let reorderSuggestion: String
}

enum RefillUrgency: String {
    case urgent = "Urgent"        // <= 2 days
    case soon = "Refill Soon"     // 3-5 days
    case ok = "OK"                // > 5 days
}

// MARK: - Refill Reminder Service

/// Tracks pill counts and alerts when medicines are running low
@Observable
final class RefillReminderService {
    static let shared = RefillReminderService()

    var lowStockMedicines: [LowStockAlert] = []

    init() {}

    // MARK: - Stock Check

    /// Checks stock levels for all provided medicines and returns alerts sorted by urgency
    func checkStock(medicines: [MedicineStockInfo]) -> [LowStockAlert] {
        let alerts = medicines.compactMap { medicine -> LowStockAlert? in
            let remaining = medicine.totalPillCount - medicine.dosesTaken
            guard remaining >= 0 else {
                // Already depleted
                return LowStockAlert(
                    id: medicine.id,
                    medicineName: medicine.brandName,
                    remainingPills: 0,
                    estimatedDaysLeft: 0,
                    urgency: .urgent,
                    reorderSuggestion: "\(medicine.brandName) is completely out of stock. Reorder immediately."
                )
            }

            guard medicine.dosesPerDay > 0 else { return nil }

            let estimatedDaysLeft = remaining / medicine.dosesPerDay

            let urgency: RefillUrgency
            switch estimatedDaysLeft {
            case ...2:
                urgency = .urgent
            case 3...5:
                urgency = .soon
            default:
                urgency = .ok
            }

            let suggestion: String
            switch urgency {
            case .urgent:
                suggestion = "\(medicine.brandName) will run out in \(estimatedDaysLeft) day\(estimatedDaysLeft == 1 ? "" : "s"). Reorder immediately."
            case .soon:
                suggestion = "\(medicine.brandName) has about \(estimatedDaysLeft) days left. Consider reordering soon."
            case .ok:
                suggestion = "\(medicine.brandName) stock is sufficient for \(estimatedDaysLeft) days."
            }

            return LowStockAlert(
                id: medicine.id,
                medicineName: medicine.brandName,
                remainingPills: remaining,
                estimatedDaysLeft: estimatedDaysLeft,
                urgency: urgency,
                reorderSuggestion: suggestion
            )
        }

        // Sort: urgent first, then soon, then ok
        let sorted = alerts.sorted { lhs, rhs in
            lhs.estimatedDaysLeft < rhs.estimatedDaysLeft
        }

        lowStockMedicines = sorted.filter { $0.urgency != .ok }
        return sorted
    }

    /// Returns only medicines that need attention (urgent or soon)
    func alertsNeedingAttention(from medicines: [MedicineStockInfo]) -> [LowStockAlert] {
        checkStock(medicines: medicines).filter { $0.urgency != .ok }
    }

    // MARK: - Refill Notifications

    /// Schedule a refill reminder notification for a low-stock medicine
    func scheduleRefillReminder(alert: LowStockAlert) async {
        guard alert.urgency != .ok else { return }

        let content = UNMutableNotificationContent()
        content.title = "Refill Reminder"
        content.body = "\(alert.medicineName) is running low — \(alert.remainingPills) pills left (~\(alert.estimatedDaysLeft) days). Time to refill!"
        content.sound = .default
        content.categoryIdentifier = "REFILL_REMINDER"
        content.interruptionLevel = alert.urgency == .urgent ? .timeSensitive : .active
        content.relevanceScore = alert.urgency == .urgent ? 1.0 : 0.8
        content.userInfo = [
            "medicineId": alert.id.uuidString,
            "type": "refill"
        ]

        // Fire tomorrow at 10 AM
        var dateComponents = DateComponents()
        dateComponents.hour = 10
        dateComponents.minute = 0
        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: false)

        let request = UNNotificationRequest(
            identifier: "refill_\(alert.id.uuidString)",
            content: content,
            trigger: trigger
        )

        try? await UNUserNotificationCenter.current().add(request)
    }

    /// Cancel a pending refill reminder
    func cancelRefillReminder(for medicineId: UUID) {
        UNUserNotificationCenter.current()
            .removePendingNotificationRequests(withIdentifiers: ["refill_\(medicineId.uuidString)"])
    }

    /// Check all medicines and schedule refill reminders where needed
    func checkAllAndScheduleReminders(medicines: [MedicineStockInfo]) async {
        let alerts = checkStock(medicines: medicines)
        for alert in alerts where alert.urgency != .ok {
            await scheduleRefillReminder(alert: alert)
        }
    }
}
