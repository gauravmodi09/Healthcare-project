import Foundation
import SwiftData

@Model
final class User {
    @Attribute(.unique) var id: UUID
    var phoneNumber: String
    var countryCode: String
    var subscriptionTier: SubscriptionTier
    var createdAt: Date
    var updatedAt: Date

    @Relationship(deleteRule: .cascade) var profiles: [UserProfile]

    var activeProfile: UserProfile? {
        profiles.first { $0.isActive }
    }

    init(
        phoneNumber: String,
        countryCode: String = "+91",
        subscriptionTier: SubscriptionTier = .free
    ) {
        self.id = UUID()
        self.phoneNumber = phoneNumber
        self.countryCode = countryCode
        self.subscriptionTier = subscriptionTier
        self.createdAt = Date()
        self.updatedAt = Date()
        self.profiles = []
    }
}

enum SubscriptionTier: String, Codable {
    case free
    case pro
    case premium

    var displayName: String {
        switch self {
        case .free: return "Free"
        case .pro: return "Pro"
        case .premium: return "Premium"
        }
    }

    var maxProfiles: Int {
        switch self {
        case .free: return 1
        case .pro: return 5
        case .premium: return 10
        }
    }

    var maxEpisodes: Int {
        switch self {
        case .free: return 1
        case .pro, .premium: return .max
        }
    }

    var hasAIExtraction: Bool {
        self != .free
    }
}
