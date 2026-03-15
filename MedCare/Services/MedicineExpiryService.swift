import Foundation
import UserNotifications

/// Enhancement #3: Medicine Expiry Tracker
/// Tracks medicine expiry dates and alerts users before medicines expire
@Observable
final class MedicineExpiryService {

    struct ExpiryAlert: Identifiable {
        let id = UUID()
        let medicineName: String
        let expiryDate: Date
        let daysUntilExpiry: Int
        let urgency: ExpiryUrgency
    }

    enum ExpiryUrgency: String {
        case safe = "Safe"
        case approaching = "Approaching"
        case warning = "Warning"
        case expired = "Expired"

        var color: String {
            switch self {
            case .safe: return "34C759"
            case .approaching: return "F5A623"
            case .warning: return "FF6B6B"
            case .expired: return "FF3B30"
            }
        }

        var icon: String {
            switch self {
            case .safe: return "checkmark.shield"
            case .approaching: return "clock.badge.exclamationmark"
            case .warning: return "exclamationmark.triangle"
            case .expired: return "xmark.circle.fill"
            }
        }
    }

    /// Check all medicines for expiry status
    func checkExpiry(medicines: [Medicine]) -> [ExpiryAlert] {
        let now = Date()
        return medicines
            .compactMap { medicine -> ExpiryAlert? in
                guard let expiryDate = medicine.expiryDate else { return nil }

                let days = Calendar.current.dateComponents([.day], from: now, to: expiryDate).day ?? 0
                let urgency: ExpiryUrgency
                switch days {
                case ...0: urgency = .expired
                case 1...30: urgency = .warning
                case 31...90: urgency = .approaching
                default: urgency = .safe
                }

                return ExpiryAlert(
                    medicineName: medicine.brandName,
                    expiryDate: expiryDate,
                    daysUntilExpiry: days,
                    urgency: urgency
                )
            }
            .sorted { $0.daysUntilExpiry < $1.daysUntilExpiry }
    }

    /// Schedule expiry reminder notifications
    func scheduleExpiryReminders(for medicine: Medicine) async {
        guard let expiryDate = medicine.expiryDate else { return }

        // Remind 30 days before
        let thirtyDaysBefore = Calendar.current.date(byAdding: .day, value: -30, to: expiryDate)!
        if thirtyDaysBefore > Date() {
            await scheduleNotification(
                id: "expiry_30_\(medicine.id.uuidString)",
                title: "Medicine expiring soon",
                body: "\(medicine.brandName) expires in 30 days. Consider getting a refill.",
                date: thirtyDaysBefore
            )
        }

        // Remind 7 days before
        let sevenDaysBefore = Calendar.current.date(byAdding: .day, value: -7, to: expiryDate)!
        if sevenDaysBefore > Date() {
            await scheduleNotification(
                id: "expiry_7_\(medicine.id.uuidString)",
                title: "Medicine expiring in 1 week",
                body: "\(medicine.brandName) expires in 7 days. Please get a replacement.",
                date: sevenDaysBefore
            )
        }

        // Remind on expiry day
        if expiryDate > Date() {
            await scheduleNotification(
                id: "expiry_0_\(medicine.id.uuidString)",
                title: "Medicine expired today",
                body: "\(medicine.brandName) has expired. Do not use expired medicines.",
                date: expiryDate
            )
        }
    }

    private func scheduleNotification(id: String, title: String, body: String, date: Date) async {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default

        let components = Calendar.current.dateComponents([.year, .month, .day, .hour], from: date)
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
        let request = UNNotificationRequest(identifier: id, content: content, trigger: trigger)

        try? await UNUserNotificationCenter.current().add(request)
    }
}
