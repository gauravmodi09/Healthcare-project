import Foundation
import SwiftData

@Model
final class DoseLog {
    @Attribute(.unique) var id: UUID
    var scheduledTime: Date
    var actualTime: Date?
    var status: DoseStatus
    var skipReason: String?
    var notes: String?
    var createdAt: Date

    @Relationship(inverse: \Medicine.doseLogs) var medicine: Medicine?

    init(scheduledTime: Date, status: DoseStatus = .pending) {
        self.id = UUID()
        self.scheduledTime = scheduledTime
        self.actualTime = nil
        self.status = status
        self.skipReason = nil
        self.notes = nil
        self.createdAt = Date()
    }

    func markTaken() {
        status = .taken
        actualTime = Date()
    }

    func markSkipped(reason: String? = nil) {
        status = .skipped
        skipReason = reason
    }

    func markSnoozed() {
        status = .snoozed
    }
}

enum DoseStatus: String, Codable {
    case pending = "Pending"
    case taken = "Taken"
    case skipped = "Skipped"
    case missed = "Missed"
    case snoozed = "Snoozed"
    case outOfStock = "Out of Stock"

    var icon: String {
        switch self {
        case .pending: return "clock"
        case .taken: return "checkmark.circle.fill"
        case .skipped: return "forward.fill"
        case .missed: return "xmark.circle.fill"
        case .snoozed: return "bell.slash"
        case .outOfStock: return "exclamationmark.triangle"
        }
    }

    var color: String {
        switch self {
        case .pending: return "6B7280"
        case .taken: return "34C759"
        case .skipped: return "F5A623"
        case .missed: return "FF3B30"
        case .snoozed: return "007AFF"
        case .outOfStock: return "FF6B6B"
        }
    }
}
