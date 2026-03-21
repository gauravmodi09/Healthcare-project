import Foundation
import SwiftData

@Model
final class CustomReminder {
    @Attribute(.unique) var id: UUID
    var title: String
    var notes: String?
    var reminderTime: Date
    var repeatOptionRawValue: String
    var isCompleted: Bool
    var createdAt: Date
    var profileId: UUID?

    @Transient var repeatOption: ReminderRepeat {
        get { ReminderRepeat(rawValue: repeatOptionRawValue) ?? .never }
        set { repeatOptionRawValue = newValue.rawValue }
    }

    init(
        title: String,
        notes: String? = nil,
        reminderTime: Date,
        repeatOption: ReminderRepeat = .never,
        profileId: UUID? = nil
    ) {
        self.id = UUID()
        self.title = title
        self.notes = notes
        self.reminderTime = reminderTime
        self.repeatOptionRawValue = repeatOption.rawValue
        self.isCompleted = false
        self.createdAt = Date()
        self.profileId = profileId
    }
}

// MARK: - Repeat Options

enum ReminderRepeat: String, Codable, CaseIterable {
    case never = "Never"
    case daily = "Daily"
    case weekly = "Weekly"
    case monthly = "Monthly"

    var icon: String {
        switch self {
        case .never: return "bell"
        case .daily: return "arrow.clockwise"
        case .weekly: return "calendar.badge.clock"
        case .monthly: return "calendar"
        }
    }
}
