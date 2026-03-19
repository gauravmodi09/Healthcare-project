import Foundation
import SwiftData

@Model
final class ChatSession {
    @Attribute(.unique) var id: UUID
    var title: String
    var createdAt: Date
    var updatedAt: Date
    var profileId: UUID?
    var messageCount: Int

    init(title: String = "New Chat", profileId: UUID? = nil) {
        self.id = UUID()
        self.title = title
        self.createdAt = Date()
        self.updatedAt = Date()
        self.profileId = profileId
        self.messageCount = 0
    }
}
