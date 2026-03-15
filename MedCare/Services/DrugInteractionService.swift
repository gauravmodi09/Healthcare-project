import Foundation

/// Enhancement #2: Drug Interaction Checker
/// Checks for potential drug-drug interactions and alerts users
@Observable
final class DrugInteractionService {

    struct InteractionAlert: Identifiable {
        let id = UUID()
        let medicine1: String
        let medicine2: String
        let severity: InteractionSeverity
        let description: String
        let recommendation: String
    }

    enum InteractionSeverity: String, Codable {
        case minor = "Minor"
        case moderate = "Moderate"
        case major = "Major"
        case contraindicated = "Contraindicated"

        var color: String {
            switch self {
            case .minor: return "F5A623"
            case .moderate: return "FF6B6B"
            case .major: return "FF3B30"
            case .contraindicated: return "8B0000"
            }
        }

        var icon: String {
            switch self {
            case .minor: return "exclamationmark.triangle"
            case .moderate: return "exclamationmark.triangle.fill"
            case .major: return "xmark.octagon"
            case .contraindicated: return "xmark.octagon.fill"
            }
        }
    }

    // Known interaction database (simplified — in production, use a comprehensive pharma API)
    private let knownInteractions: [(String, String, InteractionSeverity, String, String)] = [
        // (drug1_keyword, drug2_keyword, severity, description, recommendation)
        ("warfarin", "aspirin", .major,
         "Increased risk of bleeding",
         "Monitor INR closely. Consult your doctor before taking together."),
        ("metformin", "alcohol", .moderate,
         "Increased risk of lactic acidosis",
         "Limit alcohol consumption while taking Metformin."),
        ("amoxicillin", "methotrexate", .major,
         "Amoxicillin may increase methotrexate levels",
         "Your doctor should monitor methotrexate levels closely."),
        ("pantoprazole", "clopidogrel", .moderate,
         "Pantoprazole may reduce the effectiveness of Clopidogrel",
         "Consider alternative PPI. Discuss with your doctor."),
        ("montelukast", "phenobarbital", .moderate,
         "Phenobarbital may decrease Montelukast effectiveness",
         "Dosage adjustment may be needed. Consult your doctor."),
        ("levocetirizine", "alcohol", .minor,
         "Enhanced sedation effect",
         "Avoid alcohol while taking Levocetirizine."),
        ("ciprofloxacin", "tizanidine", .contraindicated,
         "Dangerous increase in Tizanidine levels",
         "Do NOT take together. Contact your doctor immediately."),
        ("simvastatin", "clarithromycin", .major,
         "Increased risk of rhabdomyolysis",
         "Stop Simvastatin during Clarithromycin course. Contact your doctor."),
    ]

    /// Check interactions between a list of medicines
    func checkInteractions(medicines: [Medicine]) -> [InteractionAlert] {
        var alerts: [InteractionAlert] = []

        for i in 0..<medicines.count {
            for j in (i+1)..<medicines.count {
                let med1 = medicines[i]
                let med2 = medicines[j]

                let name1 = (med1.brandName + " " + (med1.genericName ?? "")).lowercased()
                let name2 = (med2.brandName + " " + (med2.genericName ?? "")).lowercased()

                for (drug1, drug2, severity, description, recommendation) in knownInteractions {
                    let match1 = name1.contains(drug1) && name2.contains(drug2)
                    let match2 = name1.contains(drug2) && name2.contains(drug1)

                    if match1 || match2 {
                        alerts.append(InteractionAlert(
                            medicine1: med1.brandName,
                            medicine2: med2.brandName,
                            severity: severity,
                            description: description,
                            recommendation: recommendation
                        ))
                    }
                }
            }
        }

        return alerts.sorted { severityWeight($0.severity) > severityWeight($1.severity) }
    }

    /// Check if adding a new medicine conflicts with existing ones
    func checkNewMedicine(_ newMedicine: String, against existing: [Medicine]) -> [InteractionAlert] {
        let tempMedicine = Medicine(brandName: newMedicine, dosage: "")
        return checkInteractions(medicines: existing + [tempMedicine])
    }

    private func severityWeight(_ severity: InteractionSeverity) -> Int {
        switch severity {
        case .minor: return 1
        case .moderate: return 2
        case .major: return 3
        case .contraindicated: return 4
        }
    }
}
