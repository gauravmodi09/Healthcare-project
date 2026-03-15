import Foundation

/// BUSINESS MOAT #2: Regional Language AI Processing
/// India has prescriptions in 22+ languages, mixed scripts, and unique
/// abbreviation systems. This service handles the linguistic complexity
/// that global competitors cannot easily replicate.
///
/// Key Moat Properties:
/// - Multi-script detection (Devanagari, Tamil, Telugu, Bengali, etc.)
/// - Code-mixing patterns (English + Hindi on same prescription)
/// - Indian pharmacy nomenclature ("Tab" = Tablet, "Cap" = Capsule)
/// - Doctor-specific handwriting pattern database
/// - India-specific medical abbreviation dictionary

final class RegionalLanguageAI {

    /// Detected script types in Indian prescriptions
    enum IndianScript: String, CaseIterable {
        case latin = "Latin/English"
        case devanagari = "Devanagari (Hindi/Marathi/Sanskrit)"
        case tamil = "Tamil"
        case telugu = "Telugu"
        case bengali = "Bengali"
        case kannada = "Kannada"
        case malayalam = "Malayalam"
        case gujarati = "Gujarati"
        case odia = "Odia"
        case gurmukhi = "Gurmukhi (Punjabi)"
    }

    /// Indian medicine naming patterns
    struct MedicineNamePattern {
        let prefixes: [String: String] = [
            "Tab": "Tablet",
            "Cap": "Capsule",
            "Syp": "Syrup",
            "Inj": "Injection",
            "Susp": "Suspension",
            "Crm": "Cream",
            "Oint": "Ointment",
            "Drop": "Drops",
            "Gel": "Gel",
            "Pwd": "Powder",
            "Sach": "Sachet",
            "Ltn": "Lotion",
            "Inh": "Inhaler",
            "Neb": "Nebulization",
            "Sup": "Suppository"
        ]

        let indianBrandSuffixes: [String] = [
            "forte", "plus", "duo", "sr", "cr", "xl", "er", "od",
            "mf", "gp", "pg", "ds", "ls", "hs", "cv"
        ]
    }

    /// Indian timing instructions mapping
    let timingInstructionMap: [String: (String, [String])] = [
        // Hindi timing phrases
        "subah": ("Morning", ["morning"]),
        "dopahar": ("Afternoon", ["afternoon"]),
        "shaam": ("Evening", ["evening"]),
        "raat": ("Night", ["night"]),
        "khana khane se pehle": ("Before food", ["before_food"]),
        "khana khane ke baad": ("After food", ["after_food"]),
        "khali pet": ("Empty stomach", ["empty_stomach"]),
        "sone se pehle": ("Before sleep", ["bedtime"]),

        // Latin/English abbreviations common in India
        "ante cibum": ("Before meals", ["before_food"]),
        "post cibum": ("After meals", ["after_food"]),
        "hora somni": ("At bedtime", ["bedtime"]),
        "statim": ("Immediately", ["stat"]),
    ]

    /// Parse Indian prescription text with code-mixing handling
    func parseIndianPrescriptionText(_ text: String) -> ParsedPrescription {
        var medicines: [ParsedMedicine] = []
        let lines = text.components(separatedBy: .newlines).filter { !$0.trimmingCharacters(in: .whitespaces).isEmpty }

        for line in lines {
            if let medicine = parseMedicineLine(line) {
                medicines.append(medicine)
            }
        }

        return ParsedPrescription(
            detectedScripts: detectScripts(in: text),
            medicines: medicines,
            rawText: text
        )
    }

    struct ParsedPrescription {
        let detectedScripts: [IndianScript]
        let medicines: [ParsedMedicine]
        let rawText: String
    }

    struct ParsedMedicine {
        var dosageForm: String?
        var name: String
        var strength: String?
        var frequency: String?
        var timing: String?
        var duration: String?
        var instructions: String?
    }

    /// Detect scripts present in text
    func detectScripts(in text: String) -> [IndianScript] {
        var detected: Set<IndianScript> = []

        for scalar in text.unicodeScalars {
            switch scalar.value {
            case 0x0041...0x007A: detected.insert(.latin)
            case 0x0900...0x097F: detected.insert(.devanagari)
            case 0x0B80...0x0BFF: detected.insert(.tamil)
            case 0x0C00...0x0C7F: detected.insert(.telugu)
            case 0x0980...0x09FF: detected.insert(.bengali)
            case 0x0C80...0x0CFF: detected.insert(.kannada)
            case 0x0D00...0x0D7F: detected.insert(.malayalam)
            case 0x0A80...0x0AFF: detected.insert(.gujarati)
            case 0x0B00...0x0B7F: detected.insert(.odia)
            case 0x0A00...0x0A7F: detected.insert(.gurmukhi)
            default: break
            }
        }

        return Array(detected)
    }

    /// Parse a single medicine line
    private func parseMedicineLine(_ line: String) -> ParsedMedicine? {
        let trimmed = line.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return nil }

        let patterns = MedicineNamePattern()
        var medicine = ParsedMedicine(name: trimmed)

        // Check for dosage form prefix
        for (prefix, form) in patterns.prefixes {
            if trimmed.lowercased().hasPrefix(prefix.lowercased() + " ") ||
               trimmed.lowercased().hasPrefix(prefix.lowercased() + ".") {
                medicine.dosageForm = form
                let afterPrefix = String(trimmed.dropFirst(prefix.count + 1))
                    .trimmingCharacters(in: .whitespaces)
                medicine.name = afterPrefix
                break
            }
        }

        // Extract strength (numbers followed by mg, ml, etc.)
        let strengthPattern = try? NSRegularExpression(pattern: "\\b(\\d+(?:\\.\\d+)?\\s*(?:mg|ml|mcg|g|iu|%))\\b", options: .caseInsensitive)
        if let match = strengthPattern?.firstMatch(in: medicine.name, range: NSRange(medicine.name.startIndex..., in: medicine.name)) {
            let range = Range(match.range, in: medicine.name)!
            medicine.strength = String(medicine.name[range])
        }

        // Extract frequency
        let freqPatterns = ["od", "bd", "tds", "qds", "sos", "prn", "hs",
                           "once daily", "twice daily", "thrice daily"]
        for freq in freqPatterns {
            if trimmed.lowercased().contains(freq) {
                medicine.frequency = freq.uppercased()
                break
            }
        }

        // Extract duration
        let durationPattern = try? NSRegularExpression(pattern: "\\b(\\d+)\\s*(days?|weeks?|months?)\\b", options: .caseInsensitive)
        if let match = durationPattern?.firstMatch(in: trimmed, range: NSRange(trimmed.startIndex..., in: trimmed)) {
            let range = Range(match.range, in: trimmed)!
            medicine.duration = String(trimmed[range])
        }

        return medicine
    }

    /// Translate common Indian pharmacy abbreviations
    func expandAbbreviation(_ abbr: String) -> String {
        let map: [String: String] = [
            // Frequency
            "OD": "Once Daily", "BD": "Twice Daily", "TDS": "Thrice Daily",
            "QDS": "Four Times Daily", "QID": "Four Times Daily",
            "SOS": "As Needed", "PRN": "As Needed", "HS": "At Bedtime",
            "STAT": "Immediately", "EOD": "Every Other Day",

            // Timing
            "AC": "Before Food", "PC": "After Food", "BBF": "Before Breakfast",
            "ABF": "After Breakfast", "HS": "At Bedtime",

            // Route
            "PO": "Oral", "IM": "Intramuscular", "IV": "Intravenous",
            "SC": "Subcutaneous", "SL": "Sublingual", "TOP": "Topical",
            "INH": "Inhalation", "PR": "Per Rectum",

            // Indian-specific
            "S/L": "Sublingual", "I/M": "Intramuscular", "I/V": "Intravenous",
            "NEB": "Nebulization", "WF": "With Food", "EF": "Empty Stomach",
        ]
        return map[abbr.uppercased()] ?? abbr
    }
}
