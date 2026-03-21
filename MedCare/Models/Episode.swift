import Foundation
import SwiftData

@Model
final class Episode {
    @Attribute(.unique) var id: UUID
    var title: String
    var episodeType: EpisodeType
    var status: EpisodeStatus
    var doctorName: String?
    var hospitalName: String?
    var diagnosis: String?
    var notes: String?
    var followUpDate: Date?
    var startDate: Date
    var endDate: Date?
    var createdAt: Date
    var updatedAt: Date

    @Relationship(inverse: \UserProfile.episodes) var profile: UserProfile?
    @Relationship(deleteRule: .cascade) var medicines: [Medicine]
    @Relationship(deleteRule: .cascade) var tasks: [CareTask]
    @Relationship(deleteRule: .cascade) var symptomLogs: [SymptomLog]
    @Relationship(deleteRule: .cascade) var images: [EpisodeImage]

    init(
        title: String,
        episodeType: EpisodeType = .acute,
        doctorName: String? = nil,
        hospitalName: String? = nil,
        diagnosis: String? = nil
    ) {
        self.id = UUID()
        self.title = title
        self.episodeType = episodeType
        self.status = .draft
        self.doctorName = doctorName
        self.hospitalName = hospitalName
        self.diagnosis = diagnosis
        self.notes = nil
        self.followUpDate = nil
        self.startDate = Date()
        self.endDate = nil
        self.createdAt = Date()
        self.updatedAt = Date()
        self.medicines = []
        self.tasks = []
        self.symptomLogs = []
        self.images = []
    }

    var activeMedicines: [Medicine] {
        medicines.filter { $0.isActive }
    }

    var adherencePercentage: Double {
        let now = Date()
        let pastLogs = medicines.flatMap { $0.doseLogs }.filter { $0.scheduledTime <= now }
        guard !pastLogs.isEmpty else { return 0 }
        let taken = pastLogs.filter { $0.status == .taken }.count
        return Double(taken) / Double(pastLogs.count)
    }

    var daysRemaining: Int? {
        guard let end = endDate else { return nil }
        return Calendar.current.dateComponents([.day], from: Date(), to: end).day
    }

    /// Consecutive days with 100% adherence (all doses taken) going backwards from today
    var adherenceStreak: Int {
        let calendar = Calendar.current
        let allLogs = activeMedicines.flatMap { $0.doseLogs }
        guard !allLogs.isEmpty else { return 0 }

        var streak = 0
        var checkDate = calendar.startOfDay(for: Date())

        // Go backwards day by day
        for _ in 0..<365 {
            let dayEnd = calendar.date(byAdding: .day, value: 1, to: checkDate)!
            let dayLogs = allLogs.filter {
                $0.scheduledTime >= checkDate && $0.scheduledTime < dayEnd
            }

            // Skip days with no scheduled doses
            if dayLogs.isEmpty {
                checkDate = calendar.date(byAdding: .day, value: -1, to: checkDate)!
                continue
            }

            // Check if all doses for this day were taken
            let allTaken = dayLogs.allSatisfy { $0.status == .taken }
            if allTaken {
                streak += 1
                checkDate = calendar.date(byAdding: .day, value: -1, to: checkDate)!
            } else {
                break
            }
        }

        return streak
    }
}

enum EpisodeType: String, Codable, CaseIterable {
    case acute = "Acute"
    case chronic = "Chronic"
    case postDischarge = "Post-Discharge"
    case preventive = "Preventive"

    var icon: String {
        switch self {
        case .acute: return "bolt.heart"
        case .chronic: return "arrow.triangle.2.circlepath"
        case .postDischarge: return "cross.case"
        case .preventive: return "shield.checkered"
        }
    }

    var color: String {
        switch self {
        case .acute: return "FF6B6B"
        case .chronic: return "F5A623"
        case .postDischarge: return "007AFF"
        case .preventive: return "34C759"
        }
    }
}

enum EpisodeStatus: String, Codable {
    case draft = "Draft"
    case pendingConfirmation = "Pending Confirmation"
    case active = "Active"
    case completed = "Completed"
    case archived = "Archived"

    var displayName: String { rawValue }
}
