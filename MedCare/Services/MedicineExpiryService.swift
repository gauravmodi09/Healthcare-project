import Foundation
import UserNotifications

// MARK: - Input/Output Structs

struct MedicineExpiryInfo {
    let id: UUID
    let brandName: String
    let expiryDate: Date?
}

struct ExpiryAlert: Identifiable {
    let id: UUID
    let medicineName: String
    let expiryDate: Date
    let status: ExpiryStatus
    let message: String
}

enum ExpiryStatus: String {
    case expired = "Expired"
    case expiringThisMonth = "Expiring Soon"
    case expiringNextMonth = "Expiring"
    case ok = "OK"

    var color: String {
        switch self {
        case .expired: return "FF3B30"
        case .expiringThisMonth: return "FF6B6B"
        case .expiringNextMonth: return "F5A623"
        case .ok: return "34C759"
        }
    }

    var icon: String {
        switch self {
        case .expired: return "xmark.circle.fill"
        case .expiringThisMonth: return "exclamationmark.triangle"
        case .expiringNextMonth: return "clock.badge.exclamationmark"
        case .ok: return "checkmark.shield"
        }
    }
}

// MARK: - Medicine Expiry Service

/// Tracks medicine expiry dates and alerts users before medicines expire
@Observable
final class MedicineExpiryService {

    var expiryAlerts: [ExpiryAlert] = []

    init() {}

    // MARK: - Expiry Check

    /// Check all medicines for expiry status and return sorted alerts
    func checkExpiry(medicines: [MedicineExpiryInfo]) -> [ExpiryAlert] {
        let now = Date()
        let calendar = Calendar.current

        // End of current month
        guard let endOfThisMonth = calendar.date(
            from: calendar.dateComponents([.year, .month], from: now)
        ).flatMap({ calendar.date(byAdding: DateComponents(month: 1, day: -1), to: $0) }),
        // End of next month
        let endOfNextMonth = calendar.date(byAdding: .month, value: 1, to: endOfThisMonth) else {
            return []
        }

        let alerts = medicines.compactMap { medicine -> ExpiryAlert? in
            guard let expiryDate = medicine.expiryDate else { return nil }

            let status: ExpiryStatus
            let message: String

            if expiryDate < now {
                status = .expired
                let daysPast = calendar.dateComponents([.day], from: expiryDate, to: now).day ?? 0
                message = "\(medicine.brandName) expired \(daysPast) day\(daysPast == 1 ? "" : "s") ago. Do not use expired medicines."
            } else if expiryDate <= endOfThisMonth {
                status = .expiringThisMonth
                let daysLeft = calendar.dateComponents([.day], from: now, to: expiryDate).day ?? 0
                message = "\(medicine.brandName) expires in \(daysLeft) day\(daysLeft == 1 ? "" : "s"). Consider getting a replacement soon."
            } else if expiryDate <= endOfNextMonth {
                status = .expiringNextMonth
                let daysLeft = calendar.dateComponents([.day], from: now, to: expiryDate).day ?? 0
                message = "\(medicine.brandName) expires in \(daysLeft) days. Plan to get a replacement."
            } else {
                status = .ok
                let daysLeft = calendar.dateComponents([.day], from: now, to: expiryDate).day ?? 0
                message = "\(medicine.brandName) is valid for \(daysLeft) more days."
            }

            return ExpiryAlert(
                id: medicine.id,
                medicineName: medicine.brandName,
                expiryDate: expiryDate,
                status: status,
                message: message
            )
        }

        // Sort: expired first, then expiring this month, next month, then ok
        let sorted = alerts.sorted { lhs, rhs in
            let order: [ExpiryStatus] = [.expired, .expiringThisMonth, .expiringNextMonth, .ok]
            let lhsIndex = order.firstIndex(of: lhs.status) ?? 3
            let rhsIndex = order.firstIndex(of: rhs.status) ?? 3
            if lhsIndex != rhsIndex { return lhsIndex < rhsIndex }
            return lhs.expiryDate < rhs.expiryDate
        }

        expiryAlerts = sorted.filter { $0.status != .ok }
        return sorted
    }

    /// Returns only medicines that need attention (not ok)
    func alertsNeedingAttention(from medicines: [MedicineExpiryInfo]) -> [ExpiryAlert] {
        checkExpiry(medicines: medicines).filter { $0.status != .ok }
    }

    // MARK: - Expiry Notifications

    /// Schedule expiry reminder notifications for a medicine
    func scheduleExpiryReminders(for medicine: MedicineExpiryInfo) async {
        guard let expiryDate = medicine.expiryDate else { return }

        // Remind 30 days before
        if let thirtyDaysBefore = Calendar.current.date(byAdding: .day, value: -30, to: expiryDate),
           thirtyDaysBefore > Date() {
            await scheduleNotification(
                id: "expiry_30_\(medicine.id.uuidString)",
                title: "Medicine expiring soon",
                body: "\(medicine.brandName) expires in 30 days. Consider getting a refill.",
                date: thirtyDaysBefore
            )
        }

        // Remind 7 days before
        if let sevenDaysBefore = Calendar.current.date(byAdding: .day, value: -7, to: expiryDate),
           sevenDaysBefore > Date() {
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
