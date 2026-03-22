import Foundation
import SwiftUI

// MARK: - Consent Types

enum ConsentType: String, CaseIterable, Identifiable {
    case healthDataTracking = "health_data_tracking"
    case aiHealthInsights = "ai_health_insights"
    case shareWithDoctors = "share_with_doctors"
    case analyticsImprovement = "analytics_improvement"
    case pushNotifications = "push_notifications"

    var id: String { rawValue }

    var title: String {
        switch self {
        case .healthDataTracking: return "Health Data Tracking"
        case .aiHealthInsights: return "AI Health Insights"
        case .shareWithDoctors: return "Share with Doctors"
        case .analyticsImprovement: return "Analytics & Improvement"
        case .pushNotifications: return "Push Notifications"
        }
    }

    var description: String {
        switch self {
        case .healthDataTracking:
            return "Track your medications, vitals, and symptoms to provide core health management features. This is required for the app to function."
        case .aiHealthInsights:
            return "Use your health data (medications, symptoms, vitals) to generate AI-powered correlations, predictions, and personalized insights."
        case .shareWithDoctors:
            return "Share your health records, medication history, and symptom logs with doctors you link to your account."
        case .analyticsImprovement:
            return "Collect anonymized usage patterns to improve app features, fix issues, and enhance the experience for all users."
        case .pushNotifications:
            return "Receive dose reminders, health tips, weekly adherence reports, and refill alerts via push notifications."
        }
    }

    var icon: String {
        switch self {
        case .healthDataTracking: return "heart.text.clipboard"
        case .aiHealthInsights: return "brain.head.profile"
        case .shareWithDoctors: return "stethoscope"
        case .analyticsImprovement: return "chart.bar.xaxis"
        case .pushNotifications: return "bell.badge"
        }
    }

    var isRequired: Bool {
        self == .healthDataTracking
    }

    var color: Color {
        switch self {
        case .healthDataTracking: return MCColors.primaryTeal
        case .aiHealthInsights: return MCColors.info
        case .shareWithDoctors: return MCColors.accentCoral
        case .analyticsImprovement: return MCColors.warning
        case .pushNotifications: return MCColors.success
        }
    }
}

// MARK: - Consent Audit Entry

struct ConsentAuditEntry: Codable, Identifiable {
    let id: UUID
    let date: Date
    let consentType: String
    let action: String // "granted" or "withdrawn"

    init(consentType: ConsentType, action: String) {
        self.id = UUID()
        self.date = Date()
        self.consentType = consentType.rawValue
        self.action = action
    }
}

// MARK: - Consent Service

@Observable
final class ConsentService {
    // MARK: - Stored Consents

    @ObservationIgnored
    @AppStorage("consent_health_data_tracking") var healthDataTracking: Bool = true

    @ObservationIgnored
    @AppStorage("consent_ai_health_insights") var aiHealthInsights: Bool = false

    @ObservationIgnored
    @AppStorage("consent_share_with_doctors") var shareWithDoctors: Bool = false

    @ObservationIgnored
    @AppStorage("consent_analytics_improvement") var analyticsImprovement: Bool = false

    @ObservationIgnored
    @AppStorage("consent_push_notifications") var pushNotifications: Bool = false

    @ObservationIgnored
    @AppStorage("consent_last_updated") var lastUpdatedTimestamp: Double = Date().timeIntervalSince1970

    var lastUpdated: Date {
        Date(timeIntervalSince1970: lastUpdatedTimestamp)
    }

    // MARK: - Consent Methods

    func isConsentGranted(_ type: ConsentType) -> Bool {
        switch type {
        case .healthDataTracking: return healthDataTracking
        case .aiHealthInsights: return aiHealthInsights
        case .shareWithDoctors: return shareWithDoctors
        case .analyticsImprovement: return analyticsImprovement
        case .pushNotifications: return pushNotifications
        }
    }

    func grantConsent(_ type: ConsentType) {
        setConsent(type, granted: true)
        logAuditEntry(type: type, action: "granted")
    }

    func withdrawConsent(_ type: ConsentType) {
        guard !type.isRequired else { return }
        setConsent(type, granted: false)
        logAuditEntry(type: type, action: "withdrawn")
    }

    func toggleConsent(_ type: ConsentType) {
        if isConsentGranted(type) {
            withdrawConsent(type)
        } else {
            grantConsent(type)
        }
    }

    private func setConsent(_ type: ConsentType, granted: Bool) {
        switch type {
        case .healthDataTracking: healthDataTracking = granted
        case .aiHealthInsights: aiHealthInsights = granted
        case .shareWithDoctors: shareWithDoctors = granted
        case .analyticsImprovement: analyticsImprovement = granted
        case .pushNotifications: pushNotifications = granted
        }
        lastUpdatedTimestamp = Date().timeIntervalSince1970
    }

    // MARK: - Audit Log

    func getAuditLog() -> [ConsentAuditEntry] {
        guard let data = UserDefaults.standard.data(forKey: "consent_audit_log"),
              let entries = try? JSONDecoder().decode([ConsentAuditEntry].self, from: data) else {
            return []
        }
        return entries.sorted { $0.date > $1.date }
    }

    private func logAuditEntry(type: ConsentType, action: String) {
        var entries = getAuditLog()
        let entry = ConsentAuditEntry(consentType: type, action: action)
        entries.insert(entry, at: 0)
        if let data = try? JSONEncoder().encode(entries) {
            UserDefaults.standard.set(data, forKey: "consent_audit_log")
        }
    }

    // MARK: - Clear All Consents

    func clearAllConsents() {
        for type in ConsentType.allCases {
            setConsent(type, granted: type.isRequired)
        }
        UserDefaults.standard.removeObject(forKey: "consent_audit_log")
        lastUpdatedTimestamp = Date().timeIntervalSince1970
    }
}
