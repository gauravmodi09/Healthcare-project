import Foundation
import SwiftData

@Model
final class Doctor {
    @Attribute(.unique) var id: UUID
    var name: String
    var specialty: String
    var phone: String
    var email: String
    var registrationNumber: String
    var avatarEmoji: String
    var consultationFee: Double
    var createdAt: Date

    init(
        name: String,
        specialty: String = "General Physician",
        phone: String = "",
        email: String = "",
        registrationNumber: String = "",
        avatarEmoji: String = "\u{1FA7A}",
        consultationFee: Double = 0
    ) {
        self.id = UUID()
        self.name = name
        self.specialty = specialty
        self.phone = phone
        self.email = email
        self.registrationNumber = registrationNumber
        self.avatarEmoji = avatarEmoji
        self.consultationFee = consultationFee
        self.createdAt = Date()
    }

    /// Computed -- doctors are always shown as offline in local-only mode
    var isOnline: Bool { false }
}
