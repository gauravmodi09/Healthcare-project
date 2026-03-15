import Foundation
import SwiftData
import SwiftUI

@Model
final class EpisodeImage {
    @Attribute(.unique) var id: UUID
    var imageType: ImageType
    var localPath: String?
    var remoteURL: String?
    var uploadStatus: UploadStatus
    var createdAt: Date

    // File management additions
    var title: String?
    var notes: String?
    var fileSize: Int64?
    var thumbnailPath: String?

    @Relationship(inverse: \Episode.images) var episode: Episode?

    var displayTitle: String {
        title ?? imageType.rawValue
    }

    init(imageType: ImageType, localPath: String? = nil, title: String? = nil) {
        self.id = UUID()
        self.imageType = imageType
        self.localPath = localPath
        self.remoteURL = nil
        self.uploadStatus = .pending
        self.createdAt = Date()
        self.title = title
        self.notes = nil
        self.fileSize = nil
        self.thumbnailPath = nil
    }
}

enum ImageType: String, Codable, CaseIterable {
    case prescription = "Prescription"
    case medicinePackaging = "Medicine Packaging"
    case labReport = "Lab Report"
    case scan = "Scan"
    case doctorNote = "Doctor Note"
    case insuranceDoc = "Insurance"
    case bill = "Bill"
    case discharge = "Discharge Summary"
    case other = "Other"

    var icon: String {
        switch self {
        case .prescription: return "doc.text"
        case .medicinePackaging: return "pills"
        case .labReport: return "chart.bar.doc.horizontal"
        case .scan: return "photo.on.rectangle"
        case .doctorNote: return "note.text"
        case .insuranceDoc: return "shield.checkered"
        case .bill: return "indianrupeesign.circle"
        case .discharge: return "doc.badge.arrow.up"
        case .other: return "photo"
        }
    }

    var displayColor: String {
        switch self {
        case .prescription: return "#0A7E8C"
        case .medicinePackaging: return "#34C759"
        case .labReport: return "#007AFF"
        case .scan: return "#AF52DE"
        case .doctorNote: return "#FF9500"
        case .insuranceDoc: return "#5856D6"
        case .bill: return "#FF6B6B"
        case .discharge: return "#30B0C7"
        case .other: return "#8E8E93"
        }
    }
}

enum UploadStatus: String, Codable {
    case pending
    case uploading
    case uploaded
    case failed
}
