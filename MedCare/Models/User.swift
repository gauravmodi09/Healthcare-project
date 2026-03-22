import Foundation
import SwiftData

@Model
final class User {
    @Attribute(.unique) var id: UUID
    var phoneNumber: String
    var countryCode: String
    var userRole: String
    var subscriptionTier: SubscriptionTier
    var createdAt: Date
    var updatedAt: Date

    @Relationship(deleteRule: .cascade) var profiles: [UserProfile]

    var activeProfile: UserProfile? {
        profiles.first { $0.isActive }
    }

    /// Computed typed role from the stored string
    var role: UserRole {
        get { UserRole(rawValue: userRole) ?? .patient }
        set { userRole = newValue.rawValue }
    }

    init(
        phoneNumber: String,
        countryCode: String = "+91",
        userRole: String = "patient",
        subscriptionTier: SubscriptionTier = .free
    ) {
        self.id = UUID()
        self.phoneNumber = phoneNumber
        self.countryCode = countryCode
        self.userRole = userRole
        self.subscriptionTier = subscriptionTier
        self.createdAt = Date()
        self.updatedAt = Date()
        self.profiles = []
    }
}

enum UserRole: String, Codable, CaseIterable {
    case patient = "patient"
    case individualDoctor = "individual_doctor"
    case hospitalDoctor = "hospital_doctor"
    case hospitalAdmin = "hospital_admin"

    var displayName: String {
        switch self {
        case .patient: return "Patient / Family"
        case .individualDoctor: return "Independent Doctor"
        case .hospitalDoctor: return "Hospital / Clinic Doctor"
        case .hospitalAdmin: return "Hospital Administrator"
        }
    }

    var isDoctor: Bool {
        self == .individualDoctor || self == .hospitalDoctor
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
