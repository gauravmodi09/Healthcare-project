import Foundation
import SwiftData

@Model
final class SymptomLog {
    @Attribute(.unique) var id: UUID
    var date: Date
    var overallFeeling: FeelingLevel
    var symptoms: [SymptomEntry]
    var temperature: Double?
    var bloodPressureSystolic: Int?
    var bloodPressureDiastolic: Int?
    var weight: Double?
    var notes: String?
    var createdAt: Date

    @Relationship(inverse: \Episode.symptomLogs) var episode: Episode?

    init(overallFeeling: FeelingLevel = .okay, symptoms: [SymptomEntry] = []) {
        self.id = UUID()
        self.date = Date()
        self.overallFeeling = overallFeeling
        self.symptoms = symptoms
        self.temperature = nil
        self.bloodPressureSystolic = nil
        self.bloodPressureDiastolic = nil
        self.weight = nil
        self.notes = nil
        self.createdAt = Date()
    }
}

struct SymptomEntry: Codable, Hashable, Identifiable {
    var id: UUID
    var name: String
    var severity: SeverityLevel

    init(name: String, severity: SeverityLevel = .mild) {
        self.id = UUID()
        self.name = name
        self.severity = severity
    }
}

enum FeelingLevel: Int, Codable, CaseIterable {
    case terrible = 1
    case bad = 2
    case okay = 3
    case good = 4
    case great = 5

    var emoji: String {
        switch self {
        case .terrible: return "😫"
        case .bad: return "😟"
        case .okay: return "😐"
        case .good: return "🙂"
        case .great: return "😊"
        }
    }

    var label: String {
        switch self {
        case .terrible: return "Terrible"
        case .bad: return "Not Good"
        case .okay: return "Okay"
        case .good: return "Good"
        case .great: return "Great"
        }
    }
}

enum SeverityLevel: Int, Codable, CaseIterable {
    case mild = 1
    case moderate = 2
    case severe = 3
    case critical = 4

    var label: String {
        switch self {
        case .mild: return "Mild"
        case .moderate: return "Moderate"
        case .severe: return "Severe"
        case .critical: return "Critical"
        }
    }

    var color: String {
        switch self {
        case .mild: return "34C759"
        case .moderate: return "F5A623"
        case .severe: return "FF6B6B"
        case .critical: return "FF3B30"
        }
    }
}
