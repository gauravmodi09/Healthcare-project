import ActivityKit
import Foundation

/// ActivityAttributes for the dose reminder Live Activity (Dynamic Island)
/// Shared between the main app and the widget extension
struct DoseReminderAttributes: ActivityAttributes {
    /// Dynamic content that updates during the activity
    public struct ContentState: Codable, Hashable {
        var status: DoseActivityStatus
        var minutesRemaining: Int
        var snoozedUntil: Date?
    }

    // Static data — set once when the activity starts
    var medicineId: String
    var doseLogId: String
    var medicineName: String
    var dosage: String
    var scheduledTime: Date
    var timingIcon: String       // SF Symbol: "sunrise", "sun.max", "sunset", "moon.stars"
    var timingLabel: String      // "Morning", "Afternoon", "Evening", "Night"
    var instructions: String?    // "After food", "Before meals", etc.
}

/// Status of a dose in the Live Activity lifecycle
enum DoseActivityStatus: String, Codable, Hashable {
    case upcoming       // 15 min before scheduled time
    case due            // at scheduled time
    case overdue        // past scheduled time
    case snoozed        // user tapped snooze
    case completed      // taken or skipped — activity ends shortly
}
