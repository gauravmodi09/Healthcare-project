import Foundation
import SwiftData

@Model
final class Nudge {
    @Attribute(.unique) var id: UUID
    var type: NudgeType
    var title: String
    var body: String
    var triggerDate: Date
    var dismissed: Bool
    var actedOn: Bool
    var episodeId: UUID?
    var medicineId: UUID?
    var expiresAt: Date?
    var createdAt: Date

    init(
        type: NudgeType,
        title: String,
        body: String,
        episodeId: UUID? = nil,
        medicineId: UUID? = nil,
        expiresAfterHours: Int = 24
    ) {
        self.id = UUID()
        self.type = type
        self.title = title
        self.body = body
        self.triggerDate = Date()
        self.dismissed = false
        self.actedOn = false
        self.episodeId = episodeId
        self.medicineId = medicineId
        self.expiresAt = Calendar.current.date(byAdding: .hour, value: expiresAfterHours, to: Date())
        self.createdAt = Date()
    }

    var isActive: Bool {
        !dismissed && !actedOn && (expiresAt.map { $0 > Date() } ?? true)
    }
}

// MARK: - Nudge Types

enum NudgeType: String, Codable, CaseIterable {
    case missedDose = "missed_dose"
    case noImprovement = "no_improvement"
    case courseEnding = "course_ending"
    case courseCompleted = "course_completed"
    case adherenceDrop = "adherence_drop"
    case noSymptomLog = "no_symptom_log"
    case caregiverAlert = "caregiver_alert"
    case refillReminder = "refill_reminder"

    var icon: String {
        switch self {
        case .missedDose: return "exclamationmark.circle.fill"
        case .noImprovement: return "heart.text.square"
        case .courseEnding: return "flag.checkered"
        case .courseCompleted: return "party.popper"
        case .adherenceDrop: return "chart.line.downtrend.xyaxis"
        case .noSymptomLog: return "list.clipboard"
        case .caregiverAlert: return "person.2.fill"
        case .refillReminder: return "pills.fill"
        }
    }

    var accentColor: String {
        switch self {
        case .missedDose: return "FF6B6B"
        case .noImprovement: return "F5A623"
        case .courseEnding: return "007AFF"
        case .courseCompleted: return "34C759"
        case .adherenceDrop: return "FF3B30"
        case .noSymptomLog: return "AF52DE"
        case .caregiverAlert: return "FF9500"
        case .refillReminder: return "0A7E8C"
        }
    }

    var actionLabel: String {
        switch self {
        case .missedDose: return "Log Now"
        case .noImprovement: return "Chat with AI"
        case .courseEnding: return "View Plan"
        case .courseCompleted: return "View Summary"
        case .adherenceDrop: return "View Reminders"
        case .noSymptomLog: return "Log Symptoms"
        case .caregiverAlert: return "Check In"
        case .refillReminder: return "Order Refill"
        }
    }
}
