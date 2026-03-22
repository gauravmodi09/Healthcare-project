import Foundation

// MARK: - Teleconsultation Consent Service
// Per NMC Telemedicine Practice Guidelines 2020 — Section 3.7

/// Manages consent capture and logging for teleconsultation sessions
/// Patient-initiated: implied consent is sufficient
/// Doctor-initiated: explicit consent is mandatory
@Observable
final class TeleconsultConsentService {

    static let shared = TeleconsultConsentService()

    // MARK: - Types

    enum ConsentMethod: String, Codable, CaseIterable {
        case implied = "Implied"       // Patient initiated the call
        case verbal = "Verbal"         // Doctor obtained verbal consent
        case inApp = "In-App"          // Patient tapped consent button
        case sms = "SMS"               // Consent via SMS/OTP
    }

    enum ConsentType: String, Codable {
        case teleconsultation = "Teleconsultation"
        case recording = "Recording"
        case prescriptionSharing = "Prescription Sharing"
        case dataSharing = "Data Sharing"
    }

    struct ConsentLog: Identifiable, Codable {
        let id: UUID
        let patientId: UUID
        let consentType: ConsentType
        let method: ConsentMethod
        let timestamp: Date
        let initiatedBy: ConsultInitiator
        let parties: [String]      // Names/IDs of parties present
        let notes: String?
        let isValid: Bool

        init(
            patientId: UUID,
            consentType: ConsentType,
            method: ConsentMethod,
            initiatedBy: ConsultInitiator,
            parties: [String] = [],
            notes: String? = nil
        ) {
            self.id = UUID()
            self.patientId = patientId
            self.consentType = consentType
            self.method = method
            self.timestamp = Date()
            self.initiatedBy = initiatedBy
            self.parties = parties
            self.notes = notes
            self.isValid = true
        }
    }

    enum ConsultInitiator: String, Codable {
        case patient = "Patient"
        case doctor = "Doctor"
        case caregiver = "Caregiver"
    }

    // MARK: - State

    private(set) var consentLogs: [ConsentLog] = []

    // MARK: - Patient-Initiated Consent (Implied)

    /// Capture implied consent — valid when the patient initiates the teleconsultation
    /// Per NMC guidelines, when a patient initiates the call, consent is implied
    @discardableResult
    func captureImpliedConsent(patientId: UUID, parties: [String] = []) -> ConsentLog {
        let log = ConsentLog(
            patientId: patientId,
            consentType: .teleconsultation,
            method: .implied,
            initiatedBy: .patient,
            parties: parties,
            notes: "Consent implied — teleconsultation initiated by patient"
        )
        consentLogs.append(log)
        return log
    }

    // MARK: - Doctor-Initiated Consent (Explicit Required)

    /// Capture explicit consent — mandatory when the doctor initiates the teleconsultation
    /// Doctor must obtain and document explicit consent before proceeding
    @discardableResult
    func captureExplicitConsent(
        patientId: UUID,
        method: ConsentMethod,
        parties: [String] = [],
        notes: String? = nil
    ) -> ConsentLog {
        let log = ConsentLog(
            patientId: patientId,
            consentType: .teleconsultation,
            method: method,
            initiatedBy: .doctor,
            parties: parties,
            notes: notes ?? "Explicit consent obtained — teleconsultation initiated by doctor via \(method.rawValue)"
        )
        consentLogs.append(log)
        return log
    }

    // MARK: - Recording Consent (Always Explicit)

    /// Capture separate consent for recording the teleconsultation
    /// Recording consent must ALWAYS be explicit, regardless of who initiated
    @discardableResult
    func captureRecordingConsent(
        patientId: UUID,
        method: ConsentMethod = .inApp,
        parties: [String] = []
    ) -> ConsentLog {
        let log = ConsentLog(
            patientId: patientId,
            consentType: .recording,
            method: method,
            initiatedBy: .patient,
            parties: parties,
            notes: "Patient consented to teleconsultation recording"
        )
        consentLogs.append(log)
        return log
    }

    // MARK: - Prescription Sharing Consent

    /// Capture consent for sharing prescription via digital means
    @discardableResult
    func capturePrescriptionSharingConsent(
        patientId: UUID,
        method: ConsentMethod = .inApp
    ) -> ConsentLog {
        let log = ConsentLog(
            patientId: patientId,
            consentType: .prescriptionSharing,
            method: method,
            initiatedBy: .patient,
            notes: "Patient consented to receive e-prescription digitally"
        )
        consentLogs.append(log)
        return log
    }

    // MARK: - Queries

    /// Check if valid teleconsultation consent exists for a patient
    func hasValidConsent(patientId: UUID) -> Bool {
        consentLogs.contains { log in
            log.patientId == patientId &&
            log.consentType == .teleconsultation &&
            log.isValid
        }
    }

    /// Check if recording consent exists for a patient
    func hasRecordingConsent(patientId: UUID) -> Bool {
        consentLogs.contains { log in
            log.patientId == patientId &&
            log.consentType == .recording &&
            log.isValid
        }
    }

    /// Get all consent logs for a patient, sorted newest first
    func getConsentLogs(for patientId: UUID) -> [ConsentLog] {
        consentLogs
            .filter { $0.patientId == patientId }
            .sorted { $0.timestamp > $1.timestamp }
    }

    /// Get the latest consent log for a patient and type
    func latestConsent(for patientId: UUID, type: ConsentType) -> ConsentLog? {
        consentLogs
            .filter { $0.patientId == patientId && $0.consentType == type }
            .sorted { $0.timestamp > $1.timestamp }
            .first
    }

    /// Generate a consent summary string for inclusion in prescriptions
    func consentSummary(for patientId: UUID) -> String {
        let logs = getConsentLogs(for: patientId)
        guard !logs.isEmpty else {
            return "No consent recorded"
        }

        let formatter = DateFormatter()
        formatter.dateFormat = "dd/MM/yyyy HH:mm"

        var summary = "Consent Record:\n"
        for log in logs {
            summary += "- \(log.consentType.rawValue): \(log.method.rawValue) on \(formatter.string(from: log.timestamp))"
            if !log.parties.isEmpty {
                summary += " (Parties: \(log.parties.joined(separator: ", ")))"
            }
            summary += "\n"
        }
        return summary
    }

    // MARK: - Clear

    /// Clear all consent logs (e.g., on session end)
    func clearLogs() {
        consentLogs.removeAll()
    }
}
