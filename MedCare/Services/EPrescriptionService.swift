import Foundation

// MARK: - NMC-Compliant E-Prescription Service
// Per National Medical Commission (NMC) Telemedicine Practice Guidelines 2020
// and Indian Medical Council (Professional Conduct, Etiquette and Ethics) Regulations

/// Generates NMC-compliant e-prescriptions for teleconsultation
@Observable
final class EPrescriptionService {

    static let shared = EPrescriptionService()

    private let drugScheduleService = DrugScheduleService.shared
    private let consentService = TeleconsultConsentService.shared

    // MARK: - Types

    struct DoctorInfo: Codable {
        let fullName: String
        let registrationNumber: String        // NMC/State Medical Council reg number (required)
        let qualification: String             // MBBS, MD, etc. (required)
        let specialization: String?
        let clinicName: String?
        let clinicAddress: String?
        let contactNumber: String?
        let email: String?
    }

    struct PatientDemographics: Codable {
        let fullName: String                  // Required
        let age: Int                          // Required
        let gender: String                    // Required
        let patientId: UUID
        let contactNumber: String?
        let address: String?
        let knownAllergies: [String]
        let existingConditions: [String]
    }

    struct PrescriptionDrug: Codable, Identifiable {
        let id: UUID
        let brandName: String
        let genericName: String?
        let dosage: String
        let doseForm: String
        let frequency: String
        let duration: String                  // e.g., "7 days", "2 weeks"
        let mealTiming: String
        let schedule: DrugScheduleService.DrugSchedule
        let instructions: String?

        init(
            brandName: String,
            genericName: String? = nil,
            dosage: String,
            doseForm: String = "Tablet",
            frequency: String = "Once Daily",
            duration: String,
            mealTiming: String = "After Meal",
            instructions: String? = nil
        ) {
            self.id = UUID()
            self.brandName = brandName
            self.genericName = genericName
            self.dosage = dosage
            self.doseForm = doseForm
            self.frequency = frequency
            self.duration = duration
            self.mealTiming = mealTiming
            self.schedule = DrugScheduleService.shared.classifyDrug(
                genericName: genericName ?? brandName
            )
            self.instructions = instructions
        }
    }

    struct NMCPrescription: Identifiable, Codable {
        let id: UUID
        let prescriptionNumber: String
        let dateTime: Date
        let doctor: DoctorInfo
        let patient: PatientDemographics
        let diagnosis: String
        let drugs: [PrescriptionDrug]
        let generalAdvice: String?
        let followUpDate: Date?
        let isTelemedicine: Bool
        let digitalSignaturePlaceholder: String  // Placeholder for future digital signature
        let consentSummary: String

        /// Whether any drugs in this prescription are blocked (List C)
        var hasBlockedDrugs: Bool {
            drugs.contains { $0.schedule == .listC }
        }

        /// List C drugs that cannot be prescribed via teleconsult
        var blockedDrugs: [PrescriptionDrug] {
            drugs.filter { $0.schedule == .listC }
        }

        /// List B drugs that require caution
        var cautionDrugs: [PrescriptionDrug] {
            drugs.filter { $0.schedule == .listB }
        }
    }

    // MARK: - Prescription Generation

    /// Generate an NMC-compliant prescription
    /// Returns nil and populates `lastError` if validation fails
    private(set) var lastError: String?

    func generateNMCCompliantPrescription(
        doctor: DoctorInfo,
        patient: PatientDemographics,
        diagnosis: String,
        drugs: [PrescriptionDrug],
        generalAdvice: String? = nil,
        followUpDate: Date? = nil,
        isTelemedicine: Bool = true
    ) -> NMCPrescription? {
        lastError = nil

        // Validate required doctor fields
        guard !doctor.registrationNumber.trimmingCharacters(in: .whitespaces).isEmpty else {
            lastError = "Doctor's registration number is required for NMC compliance"
            return nil
        }
        guard !doctor.qualification.trimmingCharacters(in: .whitespaces).isEmpty else {
            lastError = "Doctor's qualification is required for NMC compliance"
            return nil
        }

        // Validate patient demographics
        guard !patient.fullName.trimmingCharacters(in: .whitespaces).isEmpty else {
            lastError = "Patient name is required"
            return nil
        }
        guard patient.age > 0 else {
            lastError = "Patient age is required"
            return nil
        }

        // Validate diagnosis
        guard !diagnosis.trimmingCharacters(in: .whitespaces).isEmpty else {
            lastError = "Diagnosis is required for NMC compliance"
            return nil
        }

        // Check for blocked drugs in teleconsultation
        if isTelemedicine {
            let blocked = drugs.filter { $0.schedule == .listC }
            if !blocked.isEmpty {
                let names = blocked.map { $0.brandName }.joined(separator: ", ")
                lastError = "Cannot prescribe via teleconsultation: \(names) — Schedule X/NDPS drugs require in-person consultation"
                return nil
            }
        }

        // Check consent for teleconsultation
        let consentSummary: String
        if isTelemedicine {
            consentSummary = consentService.consentSummary(for: patient.patientId)
        } else {
            consentSummary = "In-person consultation — consent implied"
        }

        let prescription = NMCPrescription(
            id: UUID(),
            prescriptionNumber: generatePrescriptionNumber(),
            dateTime: Date(),
            doctor: doctor,
            patient: patient,
            diagnosis: diagnosis,
            drugs: drugs,
            generalAdvice: generalAdvice,
            followUpDate: followUpDate,
            isTelemedicine: isTelemedicine,
            digitalSignaturePlaceholder: "--- Digital Signature Pending ---",
            consentSummary: consentSummary
        )

        return prescription
    }

    // MARK: - Formatted Output

    /// Generate formatted prescription text for display/printing
    func formatPrescription(_ rx: NMCPrescription) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "dd/MM/yyyy hh:mm a"

        var output = ""

        // Header — Telemedicine watermark
        if rx.isTelemedicine {
            output += "═══════════════════════════════════════════\n"
            output += "    *** GENERATED VIA TELECONSULTATION ***\n"
            output += "═══════════════════════════════════════════\n\n"
        }

        // Prescription number and date
        output += "Rx No: \(rx.prescriptionNumber)\n"
        output += "Date: \(dateFormatter.string(from: rx.dateTime))\n\n"

        // Doctor details
        output += "DOCTOR:\n"
        output += "Dr. \(rx.doctor.fullName)\n"
        output += "Reg. No: \(rx.doctor.registrationNumber)\n"
        output += "Qualification: \(rx.doctor.qualification)\n"
        if let spec = rx.doctor.specialization {
            output += "Specialization: \(spec)\n"
        }
        if let clinic = rx.doctor.clinicName {
            output += "Clinic: \(clinic)\n"
        }
        if let address = rx.doctor.clinicAddress {
            output += "Address: \(address)\n"
        }
        if let phone = rx.doctor.contactNumber {
            output += "Contact: \(phone)\n"
        }
        output += "\n"

        // Patient details
        output += "PATIENT:\n"
        output += "Name: \(rx.patient.fullName)\n"
        output += "Age: \(rx.patient.age) years\n"
        output += "Gender: \(rx.patient.gender)\n"
        if let phone = rx.patient.contactNumber {
            output += "Contact: \(phone)\n"
        }
        if !rx.patient.knownAllergies.isEmpty {
            output += "Allergies: \(rx.patient.knownAllergies.joined(separator: ", "))\n"
        }
        output += "\n"

        // Diagnosis
        output += "DIAGNOSIS: \(rx.diagnosis)\n\n"

        // Rx symbol
        output += "℞\n"
        output += "───────────────────────────────────────────\n"

        // Drug list
        for (index, drug) in rx.drugs.enumerated() {
            output += "\(index + 1). \(drug.brandName)"
            if let generic = drug.genericName, !generic.isEmpty {
                output += " (\(generic))"
            }
            output += "\n"
            output += "   \(drug.dosage) \(drug.doseForm) — \(drug.frequency)\n"
            output += "   Duration: \(drug.duration) | \(drug.mealTiming)\n"

            // Schedule classification
            switch drug.schedule {
            case .listB:
                output += "   [Schedule H1 — Caution]\n"
            case .listC:
                output += "   [Schedule X/NDPS — BLOCKED]\n"
            case .listA:
                break
            }

            if let instructions = drug.instructions, !instructions.isEmpty {
                output += "   Note: \(instructions)\n"
            }
            output += "\n"
        }

        output += "───────────────────────────────────────────\n\n"

        // General advice
        if let advice = rx.generalAdvice, !advice.isEmpty {
            output += "ADVICE:\n\(advice)\n\n"
        }

        // Follow-up
        if let followUp = rx.followUpDate {
            let followUpFormatter = DateFormatter()
            followUpFormatter.dateFormat = "dd/MM/yyyy"
            output += "FOLLOW-UP: \(followUpFormatter.string(from: followUp))\n\n"
        }

        // Consent
        if rx.isTelemedicine {
            output += "CONSENT:\n\(rx.consentSummary)\n\n"
        }

        // Digital signature placeholder
        output += "SIGNATURE:\n"
        output += "\(rx.digitalSignaturePlaceholder)\n"
        output += "Dr. \(rx.doctor.fullName)\n"
        output += "Reg. No: \(rx.doctor.registrationNumber)\n\n"

        // Footer
        if rx.isTelemedicine {
            output += "═══════════════════════════════════════════\n"
            output += "This prescription was generated during a\n"
            output += "teleconsultation session per NMC Telemedicine\n"
            output += "Practice Guidelines, 2020.\n"
            output += "═══════════════════════════════════════════\n"
        }

        return output
    }

    // MARK: - Helpers

    /// Build PrescriptionDrug entries from Medicine models and episode context
    func buildPrescriptionDrugs(from medicines: [Medicine]) -> [PrescriptionDrug] {
        medicines.map { med in
            PrescriptionDrug(
                brandName: med.brandName,
                genericName: med.genericName,
                dosage: med.dosage,
                doseForm: med.doseForm.rawValue,
                frequency: med.frequency.rawValue,
                duration: med.duration.map { "\($0) days" } ?? "As directed",
                mealTiming: med.mealTiming.rawValue,
                instructions: med.instructions
            )
        }
    }

    /// Build PatientDemographics from UserProfile
    func buildPatientDemographics(from profile: UserProfile) -> PatientDemographics {
        PatientDemographics(
            fullName: profile.name,
            age: profile.age ?? 0,
            gender: profile.gender?.rawValue ?? "Not specified",
            patientId: profile.id,
            contactNumber: profile.emergencyContact,
            address: nil,
            knownAllergies: profile.allergies,
            existingConditions: profile.knownConditions
        )
    }

    /// Generate a unique prescription number
    private func generatePrescriptionNumber() -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyyMMdd"
        let datePart = dateFormatter.string(from: Date())
        let randomPart = String(format: "%06d", Int.random(in: 0...999999))
        return "RX-\(datePart)-\(randomPart)"
    }
}
