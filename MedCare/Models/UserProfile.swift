import Foundation
import SwiftData

@Model
final class UserProfile {
    @Attribute(.unique) var id: UUID
    var name: String
    var relation: ProfileRelation
    var dateOfBirth: Date?
    var gender: Gender?
    var bloodGroup: String?
    var knownConditions: [String]
    var allergies: [String]
    var emergencyContact: String?
    var isActive: Bool
    var avatarEmoji: String
    var createdAt: Date

    @Relationship(inverse: \User.profiles) var user: User?
    @Relationship(deleteRule: .cascade) var episodes: [Episode]

    init(
        name: String,
        relation: ProfileRelation = .myself,
        dateOfBirth: Date? = nil,
        gender: Gender? = nil,
        avatarEmoji: String = "👤"
    ) {
        self.id = UUID()
        self.name = name
        self.relation = relation
        self.dateOfBirth = dateOfBirth
        self.gender = gender
        self.bloodGroup = nil
        self.knownConditions = []
        self.allergies = []
        self.emergencyContact = nil
        self.isActive = true
        self.avatarEmoji = avatarEmoji
        self.createdAt = Date()
        self.episodes = []
    }

    var age: Int? {
        guard let dob = dateOfBirth else { return nil }
        return Calendar.current.dateComponents([.year], from: dob, to: Date()).year
    }
}

enum ProfileRelation: String, Codable, CaseIterable {
    case myself = "Myself"
    case spouse = "Spouse"
    case parent = "Parent"
    case child = "Child"
    case sibling = "Sibling"
    case other = "Other"

    var emoji: String {
        switch self {
        case .myself: return "👤"
        case .spouse: return "💑"
        case .parent: return "👨‍👩‍👦"
        case .child: return "👶"
        case .sibling: return "👫"
        case .other: return "🧑"
        }
    }
}

enum Gender: String, Codable, CaseIterable {
    case male = "Male"
    case female = "Female"
    case other = "Other"
    case preferNotToSay = "Prefer not to say"
}
