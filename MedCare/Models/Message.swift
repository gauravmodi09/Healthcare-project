import Foundation
import SwiftData

@Model
final class Message {
    @Attribute(.unique) var id: UUID
    var threadId: UUID
    var senderTypeRawValue: String
    var senderId: UUID
    var receiverId: UUID
    var content: String
    var messageTypeRawValue: String
    var attachmentURL: String?
    var isRead: Bool
    var isUrgent: Bool
    var createdAt: Date

    @Transient var senderType: SenderType {
        get { SenderType(rawValue: senderTypeRawValue) ?? .patient }
        set { senderTypeRawValue = newValue.rawValue }
    }

    @Transient var messageType: MessageType {
        get { MessageType(rawValue: messageTypeRawValue) ?? .text }
        set { messageTypeRawValue = newValue.rawValue }
    }

    init(
        threadId: UUID,
        senderType: SenderType,
        senderId: UUID,
        receiverId: UUID,
        content: String,
        messageType: MessageType = .text,
        attachmentURL: String? = nil,
        isUrgent: Bool = false
    ) {
        self.id = UUID()
        self.threadId = threadId
        self.senderTypeRawValue = senderType.rawValue
        self.senderId = senderId
        self.receiverId = receiverId
        self.content = content
        self.messageTypeRawValue = messageType.rawValue
        self.attachmentURL = attachmentURL
        self.isRead = false
        self.isUrgent = isUrgent
        self.createdAt = Date()
    }
}

// MARK: - Enums

enum SenderType: String, Codable, CaseIterable {
    case patient = "patient"
    case doctor = "doctor"
}

enum MessageType: String, Codable, CaseIterable {
    case text = "text"
    case image = "image"
    case document = "document"
    case voice = "voice"

    var icon: String {
        switch self {
        case .text: return "text.bubble"
        case .image: return "photo"
        case .document: return "doc.fill"
        case .voice: return "mic.fill"
        }
    }
}

// MARK: - Doctor Info (local struct for UI)

struct DoctorInfo: Identifiable, Hashable {
    let id: UUID
    var name: String
    var specialty: String
    var avatarEmoji: String
    var isOnline: Bool
    var inviteCode: String
    var lastMessagePreview: String?
    var lastMessageDate: Date?
    var unreadCount: Int

    static let sampleDoctors: [DoctorInfo] = [
        DoctorInfo(
            id: UUID(),
            name: "Dr. Ananya Mehta",
            specialty: "General Physician",
            avatarEmoji: "👩‍⚕️",
            isOnline: true,
            inviteCode: "MEHTA2024",
            lastMessagePreview: "Your blood work looks good. Continue the same dosage.",
            lastMessageDate: Calendar.current.date(byAdding: .hour, value: -2, to: Date()),
            unreadCount: 1
        ),
        DoctorInfo(
            id: UUID(),
            name: "Dr. Rajesh Kumar",
            specialty: "Cardiologist",
            avatarEmoji: "👨‍⚕️",
            isOnline: false,
            inviteCode: "KUMAR2024",
            lastMessagePreview: "Please upload your latest ECG report.",
            lastMessageDate: Calendar.current.date(byAdding: .day, value: -1, to: Date()),
            unreadCount: 0
        ),
    ]
}
