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
        let allLogs = medicines.flatMap { $0.doseLogs }
        guard !allLogs.isEmpty else { return 0 }
        let taken = allLogs.filter { $0.status == .taken }.count
        return Double(taken) / Double(allLogs.count)
    }

    var daysRemaining: Int? {
        guard let end = endDate else { return nil }
        return Calendar.current.dateComponents([.day], from: Date(), to: end).day
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
