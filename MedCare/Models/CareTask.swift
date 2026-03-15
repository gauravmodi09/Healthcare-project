import Foundation
import SwiftData

@Model
final class CareTask {
    @Attribute(.unique) var id: UUID
    var title: String
    var taskType: CareTaskType
    var isCompleted: Bool
    var dueDate: Date?
    var notes: String?
    var priority: TaskPriority
    var createdAt: Date

    @Relationship(inverse: \Episode.tasks) var episode: Episode?

    init(
        title: String,
        taskType: CareTaskType,
        dueDate: Date? = nil,
        priority: TaskPriority = .medium
    ) {
        self.id = UUID()
        self.title = title
        self.taskType = taskType
        self.isCompleted = false
        self.dueDate = dueDate
        self.notes = nil
        self.priority = priority
        self.createdAt = Date()
    }
}

enum CareTaskType: String, Codable, CaseIterable {
    case labTest = "Lab Test"
    case followUp = "Follow-Up"
    case physio = "Physiotherapy"
    case woundCare = "Wound Care"
    case lifestyle = "Lifestyle"
    case diet = "Diet"
    case exercise = "Exercise"
    case other = "Other"

    var icon: String {
        switch self {
        case .labTest: return "testtube.2"
        case .followUp: return "calendar.badge.clock"
        case .physio: return "figure.walk"
        case .woundCare: return "bandage"
        case .lifestyle: return "heart.text.square"
        case .diet: return "fork.knife"
        case .exercise: return "figure.run"
        case .other: return "checklist"
        }
    }
}

enum TaskPriority: String, Codable {
    case low, medium, high, critical
}
