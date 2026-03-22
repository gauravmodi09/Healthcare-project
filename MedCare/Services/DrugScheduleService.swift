import Foundation

// MARK: - Drug Schedule Classification per Indian Telemedicine Guidelines

/// Classifies drugs per NMC Telemedicine Practice Guidelines (2020) into List A/B/C
/// List A: OTC drugs — freely prescribable via teleconsultation
/// List B: Schedule H/H1 — prescribable with caution via teleconsultation
/// List C: Schedule X + NDPS — NEVER prescribable via teleconsultation
@Observable
final class DrugScheduleService {

    static let shared = DrugScheduleService()

    // MARK: - Types

    enum DrugSchedule: String, Codable {
        case listA = "List A"   // OTC — can prescribe freely via teleconsult
        case listB = "List B"   // Schedule H/H1 — prescribe with caution
        case listC = "List C"   // Schedule X + NDPS — NEVER via teleconsult
    }

    struct ScheduleWarning: Identifiable {
        let id = UUID()
        let drugName: String
        let schedule: DrugSchedule
        let reason: String
        let warning: String
    }

    // MARK: - Schedule X Drugs (BLOCKED from teleconsultation)

    /// Schedule X drugs under Drugs and Cosmetics Act — restricted substances
    private let scheduleXDrugs: Set<String> = [
        // Narcotic analgesics
        "morphine",
        "pethidine",
        "meperidine",
        "fentanyl",
        "sufentanil",
        "alfentanil",
        "remifentanil",
        // Anti-cancer (select Schedule X)
        "thalidomide",
        "lenalidomide",
        "pomalidomide",
    ]

    // MARK: - NDPS Act Substances (BLOCKED from teleconsultation)

    /// Narcotic Drugs and Psychotropic Substances Act, 1985
    private let ndpsDrugs: Set<String> = [
        // Benzodiazepines
        "alprazolam",
        "lorazepam",
        "diazepam",
        "chlordiazepoxide",
        "clonazepam",
        "nitrazepam",
        "midazolam",
        // Opioids
        "tramadol",
        "codeine",
        "buprenorphine",
        "methadone",
        // Z-drugs (non-benzodiazepine hypnotics)
        "zolpidem",
        "zopiclone",
        "zaleplon",
        // Others
        "barbiturate",
        "phenobarbital",
        "pentobarbital",
        "secobarbital",
        "ketamine",
        "modafinil",
    ]

    // MARK: - Schedule H1 Drugs (Caution required)

    /// Schedule H1 under Drugs and Cosmetics Rules — prescribable via teleconsult with caution
    private let scheduleH1Drugs: Set<String> = [
        // Antibiotics (broad-spectrum)
        "amoxicillin",
        "amoxyclav",
        "augmentin",
        "azithromycin",
        "ciprofloxacin",
        "levofloxacin",
        "ofloxacin",
        "ceftriaxone",
        "cefixime",
        "cefpodoxime",
        "cefuroxime",
        "doxycycline",
        "metronidazole",
        "clarithromycin",
        "erythromycin",
        "meropenem",
        "piperacillin",
        "tazobactam",
        "linezolid",
        "vancomycin",
        "colistin",
        "co-trimoxazole",
        "trimethoprim",
        "nitrofurantoin",
        "norfloxacin",
        "moxifloxacin",
        "gentamicin",
        "amikacin",
        "clindamycin",
        "rifampicin",
        // Antipsychotics
        "olanzapine",
        "risperidone",
        "quetiapine",
        "aripiprazole",
        "haloperidol",
        "chlorpromazine",
        "clozapine",
        // Anti-epileptics
        "phenytoin",
        "carbamazepine",
        "valproate",
        "sodium valproate",
        "valproic acid",
        "levetiracetam",
        "lamotrigine",
        "topiramate",
        "oxcarbazepine",
        "gabapentin",
        "pregabalin",
        // Hormones
        "ethinyl estradiol",
        "levonorgestrel",
        "norethisterone",
        "desogestrel",
        "oral contraceptive",
        "testosterone",
        "growth hormone",
        "somatotropin",
        "medroxyprogesterone",
        // Immunosuppressants
        "methotrexate",
        "azathioprine",
        "cyclosporine",
        "ciclosporin",
        "tacrolimus",
        "mycophenolate",
        "sirolimus",
        "everolimus",
    ]

    // MARK: - Indian Brand Name Mapping (common brands to generic)

    private let brandToGeneric: [String: String] = [
        // Benzodiazepines
        "trika": "alprazolam",
        "alprax": "alprazolam",
        "restyl": "alprazolam",
        "ativan": "lorazepam",
        "trapex": "lorazepam",
        "valium": "diazepam",
        "calmpose": "diazepam",
        "equilibrium": "chlordiazepoxide",
        "librium": "chlordiazepoxide",
        "rivotril": "clonazepam",
        "clonotril": "clonazepam",
        "epitril": "clonazepam",
        "nitravet": "nitrazepam",
        "dormicum": "midazolam",
        // Opioids
        "ultracet": "tramadol",
        "tramazac": "tramadol",
        "domadol": "tramadol",
        "contramal": "tramadol",
        "corex": "codeine",
        "phensedyl": "codeine",
        "addnok": "buprenorphine",
        "tidgesic": "buprenorphine",
        // Z-drugs
        "stilnoct": "zolpidem",
        "zolfresh": "zolpidem",
        "imovane": "zopiclone",
        "zonesta": "zopiclone",
        // Schedule X
        "durogesic": "fentanyl",
        "mscontin": "morphine",
        "thalix": "thalidomide",
        "revlimid": "lenalidomide",
        // Others
        "ketalar": "ketamine",
        "modalert": "modafinil",
        "modvigil": "modafinil",
        "provigil": "modafinil",
        "gardenal": "phenobarbital",
        // Antipsychotics
        "oleanz": "olanzapine",
        "olanex": "olanzapine",
        "risperdal": "risperidone",
        "risnia": "risperidone",
        "risdone": "risperidone",
        "qutan": "quetiapine",
        "quel": "quetiapine",
        "seroquel": "quetiapine",
        "abilify": "aripiprazole",
        "asprito": "aripiprazole",
        // Anti-epileptics
        "eptoin": "phenytoin",
        "dilantin": "phenytoin",
        "tegretol": "carbamazepine",
        "zen": "carbamazepine",
        "mazetol": "carbamazepine",
        "encorate": "valproate",
        "valparin": "valproate",
        "levipil": "levetiracetam",
        "keppra": "levetiracetam",
        "levera": "levetiracetam",
        "lamitor": "lamotrigine",
        "gabapin": "gabapentin",
        "lyrica": "pregabalin",
        "pregalin": "pregabalin",
        "pregastar": "pregabalin",
        // Immunosuppressants
        "folitrax": "methotrexate",
        "imutrex": "methotrexate",
        "imuran": "azathioprine",
        "azoran": "azathioprine",
        "panimun": "cyclosporine",
        "sandimmun": "cyclosporine",
        "pangraf": "tacrolimus",
        "prograf": "tacrolimus",
    ]

    // MARK: - Public API

    /// Classify a drug into List A, B, or C per telemedicine guidelines
    func classifyDrug(genericName: String) -> DrugSchedule {
        let normalized = resolveGenericName(genericName)

        if isListCDrug(normalized) {
            return .listC
        } else if isListBDrug(normalized) {
            return .listB
        } else {
            return .listA
        }
    }

    /// Whether this drug can be prescribed via teleconsultation
    func canPrescribeViaTeleconsult(genericName: String) -> Bool {
        let schedule = classifyDrug(genericName: genericName)
        return schedule != .listC
    }

    /// Returns a warning message for restricted drugs, nil for OTC
    func getWarning(genericName: String) -> String? {
        let normalized = resolveGenericName(genericName)
        let schedule = classifyDrug(genericName: genericName)

        switch schedule {
        case .listC:
            if scheduleXDrugs.contains(normalized) {
                return "BLOCKED: \(genericName) is a Schedule X drug. Cannot be prescribed via teleconsultation per NMC Telemedicine Guidelines. In-person consultation required."
            } else {
                return "BLOCKED: \(genericName) is an NDPS Act substance. Cannot be prescribed via teleconsultation. In-person consultation with physical prescription required."
            }
        case .listB:
            return "CAUTION: \(genericName) is a Schedule H1 drug. Can be prescribed via teleconsultation but requires documented clinical justification, follow-up plan, and prescription must be sent to a registered pharmacy."
        case .listA:
            return nil
        }
    }

    /// Check if a drug falls under NDPS Act
    func isNDPS(genericName: String) -> Bool {
        let normalized = resolveGenericName(genericName)
        return ndpsDrugs.contains(normalized)
    }

    /// Check if a drug is Schedule X
    func isScheduleX(genericName: String) -> Bool {
        let normalized = resolveGenericName(genericName)
        return scheduleXDrugs.contains(normalized)
    }

    /// Get detailed schedule warning for UI display
    func getScheduleWarning(genericName: String) -> ScheduleWarning? {
        let schedule = classifyDrug(genericName: genericName)
        guard schedule != .listA else { return nil }

        let normalized = resolveGenericName(genericName)

        let reason: String
        let warning: String

        switch schedule {
        case .listC:
            if scheduleXDrugs.contains(normalized) {
                reason = "Schedule X (Drugs and Cosmetics Act)"
                warning = "This drug is classified as Schedule X and is strictly prohibited from teleconsultation prescribing. Patient must visit a doctor in person."
            } else {
                reason = "NDPS Act, 1985"
                warning = "This substance falls under the Narcotic Drugs and Psychotropic Substances Act. Cannot be prescribed via teleconsultation. Physical prescription on special NDPS form required."
            }
        case .listB:
            reason = "Schedule H1 (Drugs and Cosmetics Rules)"
            warning = "This drug requires caution when prescribing via teleconsultation. Ensure documented clinical justification, specify duration, and arrange follow-up."
        case .listA:
            return nil
        }

        return ScheduleWarning(
            drugName: genericName,
            schedule: schedule,
            reason: reason,
            warning: warning
        )
    }

    /// Batch-classify a list of drug names — returns only those with warnings
    func classifyDrugs(_ drugNames: [String]) -> [ScheduleWarning] {
        drugNames.compactMap { getScheduleWarning(genericName: $0) }
    }

    // MARK: - Private Helpers

    /// Resolve brand name to generic, or normalize input
    private func resolveGenericName(_ name: String) -> String {
        let lowered = name.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)

        // Check brand-to-generic mapping first
        if let generic = brandToGeneric[lowered] {
            return generic
        }

        // Try resolving via IndianDrugDatabase
        if let entry = IndianDrugDatabase.shared.medicines.first(where: {
            $0.brandName.lowercased() == lowered || $0.id == lowered
        }) {
            let genericLower = entry.genericName.lowercased()
            // Check if the resolved generic maps to a known controlled substance
            if let mapped = brandToGeneric[genericLower] {
                return mapped
            }
            return genericLower
        }

        return lowered
    }

    /// Check if drug belongs to List C (Schedule X or NDPS)
    private func isListCDrug(_ normalized: String) -> Bool {
        if scheduleXDrugs.contains(normalized) || ndpsDrugs.contains(normalized) {
            return true
        }
        // Partial match for compound names (e.g., "tramadol hydrochloride")
        for drug in scheduleXDrugs where normalized.contains(drug) {
            return true
        }
        for drug in ndpsDrugs where normalized.contains(drug) {
            return true
        }
        return false
    }

    /// Check if drug belongs to List B (Schedule H1)
    private func isListBDrug(_ normalized: String) -> Bool {
        if scheduleH1Drugs.contains(normalized) {
            return true
        }
        // Partial match for compound names
        for drug in scheduleH1Drugs where normalized.contains(drug) {
            return true
        }
        return false
    }
}
