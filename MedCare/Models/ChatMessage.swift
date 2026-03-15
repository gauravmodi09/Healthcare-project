import Foundation
import SwiftData

@Model
final class ChatMessage {
    @Attribute(.unique) var id: UUID
    var role: MessageRole
    var content: String
    var timestamp: Date
    var episodeId: UUID?
    var profileId: UUID?
    var isEmergency: Bool
    var actionButtons: [ChatAction]

    init(
        role: MessageRole,
        content: String,
        episodeId: UUID? = nil,
        profileId: UUID? = nil,
        isEmergency: Bool = false,
        actionButtons: [ChatAction] = []
    ) {
        self.id = UUID()
        self.role = role
        self.content = content
        self.timestamp = Date()
        self.episodeId = episodeId
        self.profileId = profileId
        self.isEmergency = isEmergency
        self.actionButtons = actionButtons
    }
}

// MARK: - Supporting Types

enum MessageRole: String, Codable {
    case user = "user"
    case assistant = "assistant"
    case system = "system"

    var isUser: Bool { self == .user }
    var isAssistant: Bool { self == .assistant }
}

struct ChatAction: Codable, Hashable, Identifiable {
    var id: UUID
    var title: String
    var type: ChatActionType
    var payload: String? // e.g., episodeId for navigation

    init(title: String, type: ChatActionType, payload: String? = nil) {
        self.id = UUID()
        self.title = title
        self.type = type
        self.payload = payload
    }
}

enum ChatActionType: String, Codable {
    case logSymptom = "log_symptom"
    case callDoctor = "call_doctor"
    case viewTimeline = "view_timeline"
    case viewEpisode = "view_episode"
    case callEmergency = "call_emergency"
    case openURL = "open_url"
}

// MARK: - Emergency Detection

enum EmergencyType: String, CaseIterable {
    case chestPain = "chest_pain"
    case breathingDifficulty = "breathing_difficulty"
    case suicidal = "suicidal"
    case severeAllergy = "severe_allergy"
    case stroke = "stroke"
    case unconscious = "unconscious"

    var displayTitle: String {
        switch self {
        case .chestPain: return "Possible Chest Pain Emergency"
        case .breathingDifficulty: return "Possible Breathing Emergency"
        case .suicidal: return "Crisis Support Needed"
        case .severeAllergy: return "Possible Severe Allergic Reaction"
        case .stroke: return "Possible Stroke Emergency"
        case .unconscious: return "Possible Loss of Consciousness"
        }
    }

    var keywords: [String] {
        switch self {
        case .chestPain:
            return ["chest pain", "heart attack", "chest tightness", "crushing pain in chest", "seene mein dard"]
        case .breathingDifficulty:
            return ["can't breathe", "breathing difficulty", "saans nahi aa rahi", "choking", "breathless", "suffocating"]
        case .suicidal:
            return ["want to die", "kill myself", "suicidal", "end my life", "no reason to live", "marna chahta"]
        case .severeAllergy:
            return ["throat swelling", "anaphylaxis", "face swollen", "hives all over", "can't swallow"]
        case .stroke:
            return ["face drooping", "arm weakness", "slurred speech", "sudden numbness", "stroke"]
        case .unconscious:
            return ["unconscious", "fainted", "not responding", "collapsed", "behosh"]
        }
    }
}
