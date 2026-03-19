import Foundation

// MARK: - Models

struct DrugEntry: Identifiable, Codable {
    let id: String
    let brandName: String
    let genericName: String
    let saltComposition: String
    let category: DrugCategory
    let manufacturer: String
    let commonDosages: [String]
    let typicalDoseForm: String
    let priceRange: String
    let genericAlternatives: [GenericAlternative]
    let foodInteractions: [String]
    let commonSideEffects: [String]
    let storageInstructions: String
    let description: String
    let isScheduleH: Bool
}

struct GenericAlternative: Codable {
    let brandName: String
    let manufacturer: String
    let priceRange: String
}

enum DrugCategory: String, Codable, CaseIterable {
    case antibiotic = "Antibiotic"
    case antidiabetic = "Antidiabetic"
    case antihypertensive = "Antihypertensive"
    case analgesic = "Analgesic"
    case antiAcid = "Anti-acid"
    case antiAllergy = "Anti-allergy"
    case cardiovascular = "Cardiovascular"
    case cholesterol = "Cholesterol"
    case thyroid = "Thyroid"
    case vitamin = "Vitamin/Supplement"
    case respiratory = "Respiratory"
    case antiDepressant = "Anti-depressant"
    case antiInfective = "Anti-infective"
    case skinCare = "Skin Care"
    case other = "Other"
}

// MARK: - Database

@Observable
final class IndianDrugDatabase {

    static let shared = IndianDrugDatabase()

    let medicines: [DrugEntry]

    private init() {
        medicines = Self.buildDatabase()
    }

    // MARK: - Search

    func searchMedicines(query: String) -> [DrugEntry] {
        let q = query.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
        guard !q.isEmpty else { return [] }

        // Exact prefix matches first, then contains, then phonetic
        var exact: [DrugEntry] = []
        var contains: [DrugEntry] = []
        var phonetic: [DrugEntry] = []

        for entry in medicines {
            let brand = entry.brandName.lowercased()
            let generic = entry.genericName.lowercased()
            let salt = entry.saltComposition.lowercased()

            if brand.hasPrefix(q) || generic.hasPrefix(q) {
                exact.append(entry)
            } else if brand.contains(q) || generic.contains(q) || salt.contains(q) {
                contains.append(entry)
            } else if Self.phoneticMatch(q, brand) || Self.phoneticMatch(q, generic) {
                phonetic.append(entry)
            }
        }

        return exact + contains + phonetic
    }

    func findByGenericName(_ genericName: String) -> [DrugEntry] {
        let q = genericName.lowercased()
        return medicines.filter {
            $0.genericName.lowercased().contains(q) || $0.saltComposition.lowercased().contains(q)
        }
    }

    func findAlternatives(for brandName: String) -> [GenericAlternative] {
        let q = brandName.lowercased()
        guard let entry = medicines.first(where: { $0.brandName.lowercased() == q }) else {
            return []
        }
        return entry.genericAlternatives
    }

    func getFoodInteractions(for brandName: String) -> [String] {
        let q = brandName.lowercased()
        guard let entry = medicines.first(where: { $0.brandName.lowercased() == q || $0.id == q }) else {
            return []
        }
        return entry.foodInteractions
    }

    func findByCategory(_ category: DrugCategory) -> [DrugEntry] {
        medicines.filter { $0.category == category }
    }

    // MARK: - Phonetic Matching

    /// Simple phonetic similarity for Indian medicine names
    /// Handles common misspellings: c/k/ck, ph/f, z/s, ee/i, ou/u
    private static func phoneticMatch(_ query: String, _ target: String) -> Bool {
        let normalizedQuery = phoneticNormalize(query)
        let normalizedTarget = phoneticNormalize(target)
        return normalizedTarget.contains(normalizedQuery)
    }

    private static func phoneticNormalize(_ input: String) -> String {
        var s = input.lowercased()
        let replacements: [(String, String)] = [
            ("ph", "f"),
            ("ck", "k"),
            ("ee", "i"),
            ("oo", "u"),
            ("ou", "u"),
            ("th", "t"),
            ("sh", "s"),
            ("ch", "k"),
            ("igh", "i"),
            ("x", "ks"),
        ]
        for (from, to) in replacements {
            s = s.replacingOccurrences(of: from, with: to)
        }
        // Remove doubled consonants
        var result = ""
        for char in s {
            if char != result.last || "aeiou".contains(char) {
                result.append(char)
            }
        }
        return result
    }

    // MARK: - Database Builder

    private static func buildDatabase() -> [DrugEntry] {
        var db: [DrugEntry] = []

        // ────────────────────────────────────────────
        // ANTIBIOTICS
        // ────────────────────────────────────────────

        db.append(DrugEntry(
            id: "augmentin", brandName: "Augmentin", genericName: "Amoxicillin + Clavulanic Acid",
            saltComposition: "Amoxicillin 500mg + Clavulanic Acid 125mg",
            category: .antibiotic, manufacturer: "GSK Pharmaceuticals",
            commonDosages: ["375mg", "625mg", "1000mg"], typicalDoseForm: "tablet",
            priceRange: "₹120-220",
            genericAlternatives: [
                GenericAlternative(brandName: "Amoxyclav", manufacturer: "Cipla", priceRange: "₹80-150"),
                GenericAlternative(brandName: "Moxikind-CV", manufacturer: "Mankind", priceRange: "₹70-130"),
                GenericAlternative(brandName: "Clavam", manufacturer: "Alkem", priceRange: "₹85-140")
            ],
            foodInteractions: ["Take with food to reduce stomach upset", "Avoid alcohol during course"],
            commonSideEffects: ["Diarrhoea", "Nausea", "Skin rash", "Vomiting", "Stomach pain"],
            storageInstructions: "Store below 25°C in a dry place. Keep away from moisture.",
            description: "Broad-spectrum antibiotic used for bacterial infections of the ear, nose, throat, urinary tract, and skin.",
            isScheduleH: true
        ))

        db.append(DrugEntry(
            id: "azithral", brandName: "Azithral", genericName: "Azithromycin",
            saltComposition: "Azithromycin 500mg",
            category: .antibiotic, manufacturer: "Alembic Pharmaceuticals",
            commonDosages: ["250mg", "500mg"], typicalDoseForm: "tablet",
            priceRange: "₹70-120",
            genericAlternatives: [
                GenericAlternative(brandName: "Azee", manufacturer: "Cipla", priceRange: "₹65-100"),
                GenericAlternative(brandName: "Azibact", manufacturer: "Micro Labs", priceRange: "₹55-90")
            ],
            foodInteractions: ["Take on empty stomach, 1 hour before or 2 hours after food", "Avoid antacids within 2 hours"],
            commonSideEffects: ["Nausea", "Diarrhoea", "Stomach pain", "Headache", "Vomiting"],
            storageInstructions: "Store below 30°C. Protect from light and moisture.",
            description: "Macrolide antibiotic used for respiratory, skin, ear and sexually transmitted infections.",
            isScheduleH: true
        ))

        db.append(DrugEntry(
            id: "cifran", brandName: "Cifran", genericName: "Ciprofloxacin",
            saltComposition: "Ciprofloxacin 500mg",
            category: .antibiotic, manufacturer: "Sun Pharmaceutical",
            commonDosages: ["250mg", "500mg", "750mg"], typicalDoseForm: "tablet",
            priceRange: "₹40-90",
            genericAlternatives: [
                GenericAlternative(brandName: "Ciplox", manufacturer: "Cipla", priceRange: "₹30-70"),
                GenericAlternative(brandName: "Ciprobid", manufacturer: "Zydus", priceRange: "₹35-75")
            ],
            foodInteractions: ["Avoid dairy products within 2 hours", "Avoid antacids with aluminium/magnesium", "Do not take with caffeine"],
            commonSideEffects: ["Nausea", "Diarrhoea", "Dizziness", "Headache", "Tendon pain"],
            storageInstructions: "Store below 30°C in a dry place. Protect from light.",
            description: "Fluoroquinolone antibiotic for urinary tract, respiratory, skin and bone infections.",
            isScheduleH: true
        ))

        db.append(DrugEntry(
            id: "monocef", brandName: "Monocef", genericName: "Ceftriaxone",
            saltComposition: "Ceftriaxone 1g",
            category: .antibiotic, manufacturer: "Aristo Pharmaceuticals",
            commonDosages: ["250mg", "500mg", "1g"], typicalDoseForm: "injection",
            priceRange: "₹60-150",
            genericAlternatives: [
                GenericAlternative(brandName: "Oritaxim", manufacturer: "Mankind", priceRange: "₹45-120"),
                GenericAlternative(brandName: "Ceftriaxone", manufacturer: "Cipla", priceRange: "₹40-100")
            ],
            foodInteractions: ["Injectable - no direct food interactions", "Avoid alcohol during treatment"],
            commonSideEffects: ["Pain at injection site", "Diarrhoea", "Rash", "Nausea", "Elevated liver enzymes"],
            storageInstructions: "Store below 25°C. Protect from light. Use reconstituted solution within 6 hours.",
            description: "Third-generation cephalosporin antibiotic for severe bacterial infections.",
            isScheduleH: true
        ))

        db.append(DrugEntry(
            id: "amoxyclav", brandName: "Amoxyclav", genericName: "Amoxicillin + Clavulanic Acid",
            saltComposition: "Amoxicillin 500mg + Clavulanic Acid 125mg",
            category: .antibiotic, manufacturer: "Cipla",
            commonDosages: ["375mg", "625mg"], typicalDoseForm: "tablet",
            priceRange: "₹80-150",
            genericAlternatives: [
                GenericAlternative(brandName: "Augmentin", manufacturer: "GSK", priceRange: "₹120-220"),
                GenericAlternative(brandName: "Moxikind-CV", manufacturer: "Mankind", priceRange: "₹70-130")
            ],
            foodInteractions: ["Take with food to reduce stomach upset", "Avoid alcohol"],
            commonSideEffects: ["Diarrhoea", "Nausea", "Vomiting", "Skin rash", "Abdominal discomfort"],
            storageInstructions: "Store below 25°C. Keep in original packaging.",
            description: "Combination antibiotic for bacterial infections resistant to amoxicillin alone.",
            isScheduleH: true
        ))

        db.append(DrugEntry(
            id: "cefixime", brandName: "Cefixime", genericName: "Cefixime",
            saltComposition: "Cefixime 200mg",
            category: .antibiotic, manufacturer: "Various",
            commonDosages: ["100mg", "200mg", "400mg"], typicalDoseForm: "tablet",
            priceRange: "₹80-160",
            genericAlternatives: [
                GenericAlternative(brandName: "Taxim-O", manufacturer: "Alkem", priceRange: "₹90-170"),
                GenericAlternative(brandName: "Cefix", manufacturer: "Cipla", priceRange: "₹75-140")
            ],
            foodInteractions: ["Can be taken with or without food", "Avoid alcohol"],
            commonSideEffects: ["Diarrhoea", "Nausea", "Stomach pain", "Headache", "Flatulence"],
            storageInstructions: "Store below 30°C. Keep away from moisture.",
            description: "Third-generation oral cephalosporin for ear, throat, urinary and respiratory infections.",
            isScheduleH: true
        ))

        db.append(DrugEntry(
            id: "levoflox", brandName: "Levoflox", genericName: "Levofloxacin",
            saltComposition: "Levofloxacin 500mg",
            category: .antibiotic, manufacturer: "Cipla",
            commonDosages: ["250mg", "500mg", "750mg"], typicalDoseForm: "tablet",
            priceRange: "₹60-130",
            genericAlternatives: [
                GenericAlternative(brandName: "Levomac", manufacturer: "Macleods", priceRange: "₹50-100"),
                GenericAlternative(brandName: "Levoday", manufacturer: "Hetero", priceRange: "₹45-95")
            ],
            foodInteractions: ["Avoid dairy and antacids within 2 hours", "Do not take with iron supplements"],
            commonSideEffects: ["Nausea", "Headache", "Diarrhoea", "Dizziness", "Insomnia"],
            storageInstructions: "Store below 30°C. Protect from light.",
            description: "Fluoroquinolone antibiotic for respiratory, urinary, and skin infections.",
            isScheduleH: true
        ))

        db.append(DrugEntry(
            id: "metrogyl", brandName: "Metrogyl", genericName: "Metronidazole",
            saltComposition: "Metronidazole 400mg",
            category: .antibiotic, manufacturer: "J.B. Chemicals",
            commonDosages: ["200mg", "400mg"], typicalDoseForm: "tablet",
            priceRange: "₹15-35",
            genericAlternatives: [
                GenericAlternative(brandName: "Flagyl", manufacturer: "Abbott", priceRange: "₹20-40"),
                GenericAlternative(brandName: "Metro", manufacturer: "Micro Labs", priceRange: "₹12-30")
            ],
            foodInteractions: ["Strictly avoid alcohol — causes severe nausea and vomiting (disulfiram reaction)", "Take with food"],
            commonSideEffects: ["Metallic taste", "Nausea", "Headache", "Dark urine", "Dizziness"],
            storageInstructions: "Store below 25°C. Protect from light.",
            description: "Antibiotic and antiprotozoal for dental, abdominal, and parasitic infections.",
            isScheduleH: true
        ))

        db.append(DrugEntry(
            id: "doxycycline", brandName: "Doxylab", genericName: "Doxycycline",
            saltComposition: "Doxycycline 100mg",
            category: .antibiotic, manufacturer: "Laborate Pharmaceuticals",
            commonDosages: ["100mg"], typicalDoseForm: "capsule",
            priceRange: "₹40-80",
            genericAlternatives: [
                GenericAlternative(brandName: "Doxycap", manufacturer: "Cipla", priceRange: "₹35-70"),
                GenericAlternative(brandName: "Microdox", manufacturer: "Micro Labs", priceRange: "₹30-60")
            ],
            foodInteractions: ["Take with food and plenty of water", "Avoid dairy within 2 hours", "Avoid antacids and iron supplements"],
            commonSideEffects: ["Nausea", "Photosensitivity", "Oesophageal irritation", "Diarrhoea", "Abdominal pain"],
            storageInstructions: "Store below 25°C. Protect from light and moisture.",
            description: "Tetracycline antibiotic for acne, respiratory, urinary, and tick-borne infections.",
            isScheduleH: true
        ))

        // ────────────────────────────────────────────
        // ANTIDIABETIC
        // ────────────────────────────────────────────

        db.append(DrugEntry(
            id: "glycomet", brandName: "Glycomet", genericName: "Metformin",
            saltComposition: "Metformin Hydrochloride 500mg",
            category: .antidiabetic, manufacturer: "USV Private Limited",
            commonDosages: ["250mg", "500mg", "850mg", "1000mg"], typicalDoseForm: "tablet",
            priceRange: "₹20-70",
            genericAlternatives: [
                GenericAlternative(brandName: "Obimet", manufacturer: "Abbott", priceRange: "₹25-80"),
                GenericAlternative(brandName: "Gluconorm", manufacturer: "Lupin", priceRange: "₹18-65")
            ],
            foodInteractions: ["Take with meals to reduce GI upset", "Avoid excessive alcohol — risk of lactic acidosis"],
            commonSideEffects: ["Nausea", "Diarrhoea", "Metallic taste", "Stomach cramps", "Vitamin B12 deficiency (long term)"],
            storageInstructions: "Store below 30°C. Keep away from moisture.",
            description: "First-line oral medication for Type 2 diabetes. Reduces glucose production in the liver.",
            isScheduleH: true
        ))

        db.append(DrugEntry(
            id: "januvia", brandName: "Januvia", genericName: "Sitagliptin",
            saltComposition: "Sitagliptin 100mg",
            category: .antidiabetic, manufacturer: "MSD Pharmaceuticals",
            commonDosages: ["25mg", "50mg", "100mg"], typicalDoseForm: "tablet",
            priceRange: "₹350-600",
            genericAlternatives: [
                GenericAlternative(brandName: "Istavel", manufacturer: "Sun Pharma", priceRange: "₹250-450"),
                GenericAlternative(brandName: "Zita", manufacturer: "Glenmark", priceRange: "₹200-400")
            ],
            foodInteractions: ["Can be taken with or without food", "Avoid excessive sugar intake"],
            commonSideEffects: ["Upper respiratory infection", "Headache", "Nasopharyngitis", "Joint pain", "Nausea"],
            storageInstructions: "Store below 30°C. Protect from moisture.",
            description: "DPP-4 inhibitor for Type 2 diabetes. Enhances insulin secretion after meals.",
            isScheduleH: true
        ))

        db.append(DrugEntry(
            id: "amaryl", brandName: "Amaryl", genericName: "Glimepiride",
            saltComposition: "Glimepiride 2mg",
            category: .antidiabetic, manufacturer: "Sanofi India",
            commonDosages: ["1mg", "2mg", "3mg", "4mg"], typicalDoseForm: "tablet",
            priceRange: "₹70-150",
            genericAlternatives: [
                GenericAlternative(brandName: "Glimisave", manufacturer: "Mankind", priceRange: "₹40-90"),
                GenericAlternative(brandName: "Glimy", manufacturer: "USV", priceRange: "₹45-100")
            ],
            foodInteractions: ["Take with breakfast or first main meal", "Avoid skipping meals — risk of hypoglycemia"],
            commonSideEffects: ["Hypoglycemia", "Weight gain", "Dizziness", "Nausea", "Headache"],
            storageInstructions: "Store below 30°C. Protect from light.",
            description: "Sulfonylurea that stimulates insulin release from pancreas for Type 2 diabetes.",
            isScheduleH: true
        ))

        db.append(DrugEntry(
            id: "galvus", brandName: "Galvus", genericName: "Vildagliptin",
            saltComposition: "Vildagliptin 50mg",
            category: .antidiabetic, manufacturer: "Novartis India",
            commonDosages: ["50mg"], typicalDoseForm: "tablet",
            priceRange: "₹250-400",
            genericAlternatives: [
                GenericAlternative(brandName: "Jalra", manufacturer: "USV", priceRange: "₹180-300"),
                GenericAlternative(brandName: "Vildapride", manufacturer: "Micro Labs", priceRange: "₹150-250")
            ],
            foodInteractions: ["Can be taken with or without food"],
            commonSideEffects: ["Headache", "Dizziness", "Tremor", "Nausea", "Hypoglycemia (with sulfonylurea)"],
            storageInstructions: "Store below 30°C. Keep in original packaging.",
            description: "DPP-4 inhibitor for Type 2 diabetes, often used in combination with Metformin.",
            isScheduleH: true
        ))

        db.append(DrugEntry(
            id: "trajenta", brandName: "Trajenta", genericName: "Linagliptin",
            saltComposition: "Linagliptin 5mg",
            category: .antidiabetic, manufacturer: "Boehringer Ingelheim",
            commonDosages: ["5mg"], typicalDoseForm: "tablet",
            priceRange: "₹350-500",
            genericAlternatives: [
                GenericAlternative(brandName: "Linares", manufacturer: "USV", priceRange: "₹250-380"),
                GenericAlternative(brandName: "Linagard", manufacturer: "Sun Pharma", priceRange: "₹220-350")
            ],
            foodInteractions: ["Can be taken with or without food"],
            commonSideEffects: ["Nasopharyngitis", "Cough", "Hypoglycemia (with other diabetes drugs)", "Pancreatitis (rare)"],
            storageInstructions: "Store below 30°C. Protect from moisture.",
            description: "DPP-4 inhibitor safe in kidney disease. Does not require dose adjustment for renal impairment.",
            isScheduleH: true
        ))

        db.append(DrugEntry(
            id: "gliclazide", brandName: "Diamicron", genericName: "Gliclazide",
            saltComposition: "Gliclazide 80mg",
            category: .antidiabetic, manufacturer: "Serdia Pharmaceuticals",
            commonDosages: ["40mg", "80mg", "30mg MR", "60mg MR"], typicalDoseForm: "tablet",
            priceRange: "₹40-120",
            genericAlternatives: [
                GenericAlternative(brandName: "Glizid", manufacturer: "Sun Pharma", priceRange: "₹30-90"),
                GenericAlternative(brandName: "Glyclad", manufacturer: "Cipla", priceRange: "₹25-80")
            ],
            foodInteractions: ["Take with breakfast", "Avoid skipping meals", "Limit alcohol consumption"],
            commonSideEffects: ["Hypoglycemia", "Weight gain", "Nausea", "Abdominal pain", "Diarrhoea"],
            storageInstructions: "Store below 30°C. Protect from moisture and light.",
            description: "Sulfonylurea for Type 2 diabetes with additional vascular protective properties.",
            isScheduleH: true
        ))

        db.append(DrugEntry(
            id: "glycomet-gp", brandName: "Glycomet-GP", genericName: "Metformin + Glimepiride",
            saltComposition: "Metformin 500mg + Glimepiride 1mg",
            category: .antidiabetic, manufacturer: "USV Private Limited",
            commonDosages: ["500/1mg", "500/2mg", "1000/1mg", "1000/2mg"], typicalDoseForm: "tablet",
            priceRange: "₹60-140",
            genericAlternatives: [
                GenericAlternative(brandName: "Gliminyle-M", manufacturer: "Mankind", priceRange: "₹40-100"),
                GenericAlternative(brandName: "Gluconorm-G", manufacturer: "Lupin", priceRange: "₹45-110")
            ],
            foodInteractions: ["Take with meals", "Do not skip meals — hypoglycemia risk", "Avoid alcohol"],
            commonSideEffects: ["Hypoglycemia", "Nausea", "Diarrhoea", "Weight gain", "Metallic taste"],
            storageInstructions: "Store below 30°C. Keep away from moisture.",
            description: "Combination of Metformin and Glimepiride for better blood sugar control in Type 2 diabetes.",
            isScheduleH: true
        ))

        // ────────────────────────────────────────────
        // ANTIHYPERTENSIVE (BP)
        // ────────────────────────────────────────────

        db.append(DrugEntry(
            id: "telma", brandName: "Telma", genericName: "Telmisartan",
            saltComposition: "Telmisartan 40mg",
            category: .antihypertensive, manufacturer: "Glenmark Pharmaceuticals",
            commonDosages: ["20mg", "40mg", "80mg"], typicalDoseForm: "tablet",
            priceRange: "₹80-180",
            genericAlternatives: [
                GenericAlternative(brandName: "Telmikind", manufacturer: "Mankind", priceRange: "₹50-120"),
                GenericAlternative(brandName: "Telsar", manufacturer: "Unichem", priceRange: "₹55-130")
            ],
            foodInteractions: ["Can be taken with or without food", "Avoid potassium-rich salt substitutes"],
            commonSideEffects: ["Dizziness", "Back pain", "Diarrhoea", "Upper respiratory infection", "Fatigue"],
            storageInstructions: "Store below 30°C. Protect from moisture.",
            description: "ARB for high blood pressure and cardiovascular protection.",
            isScheduleH: true
        ))

        db.append(DrugEntry(
            id: "amlodipine", brandName: "Amlong", genericName: "Amlodipine",
            saltComposition: "Amlodipine 5mg",
            category: .antihypertensive, manufacturer: "Micro Labs",
            commonDosages: ["2.5mg", "5mg", "10mg"], typicalDoseForm: "tablet",
            priceRange: "₹30-80",
            genericAlternatives: [
                GenericAlternative(brandName: "Amlip", manufacturer: "Cipla", priceRange: "₹25-60"),
                GenericAlternative(brandName: "Stamlo", manufacturer: "Dr. Reddy's", priceRange: "₹35-70")
            ],
            foodInteractions: ["Avoid grapefruit juice — increases drug levels", "Can be taken with or without food"],
            commonSideEffects: ["Ankle swelling", "Headache", "Flushing", "Dizziness", "Fatigue"],
            storageInstructions: "Store below 30°C. Protect from light and moisture.",
            description: "Calcium channel blocker for high blood pressure and angina.",
            isScheduleH: true
        ))

        db.append(DrugEntry(
            id: "aten", brandName: "Aten", genericName: "Atenolol",
            saltComposition: "Atenolol 50mg",
            category: .antihypertensive, manufacturer: "Zydus Cadila",
            commonDosages: ["25mg", "50mg", "100mg"], typicalDoseForm: "tablet",
            priceRange: "₹20-50",
            genericAlternatives: [
                GenericAlternative(brandName: "Betacard", manufacturer: "Torrent", priceRange: "₹18-45"),
                GenericAlternative(brandName: "Atelol", manufacturer: "Ipca", priceRange: "₹15-40")
            ],
            foodInteractions: ["Take on empty stomach for best absorption", "Limit caffeine intake"],
            commonSideEffects: ["Fatigue", "Cold extremities", "Bradycardia", "Dizziness", "Depression"],
            storageInstructions: "Store below 30°C. Protect from light.",
            description: "Beta-blocker for high blood pressure, angina, and heart rate control.",
            isScheduleH: true
        ))

        db.append(DrugEntry(
            id: "ramipril", brandName: "Cardace", genericName: "Ramipril",
            saltComposition: "Ramipril 5mg",
            category: .antihypertensive, manufacturer: "Sanofi India",
            commonDosages: ["1.25mg", "2.5mg", "5mg", "10mg"], typicalDoseForm: "capsule",
            priceRange: "₹50-120",
            genericAlternatives: [
                GenericAlternative(brandName: "Ramistar", manufacturer: "Lupin", priceRange: "₹35-90"),
                GenericAlternative(brandName: "Ramcor", manufacturer: "Cipla", priceRange: "₹30-85")
            ],
            foodInteractions: ["Can be taken with or without food", "Avoid potassium supplements and salt substitutes"],
            commonSideEffects: ["Dry cough", "Dizziness", "Hypotension", "Hyperkalemia", "Headache"],
            storageInstructions: "Store below 25°C. Protect from moisture.",
            description: "ACE inhibitor for hypertension, heart failure, and post-heart attack protection.",
            isScheduleH: true
        ))

        db.append(DrugEntry(
            id: "losartan", brandName: "Losacar", genericName: "Losartan",
            saltComposition: "Losartan Potassium 50mg",
            category: .antihypertensive, manufacturer: "Cadila Healthcare",
            commonDosages: ["25mg", "50mg", "100mg"], typicalDoseForm: "tablet",
            priceRange: "₹50-130",
            genericAlternatives: [
                GenericAlternative(brandName: "Losar", manufacturer: "Cipla", priceRange: "₹40-100"),
                GenericAlternative(brandName: "Repace", manufacturer: "Sun Pharma", priceRange: "₹45-110")
            ],
            foodInteractions: ["Can be taken with or without food", "Avoid potassium-rich salt substitutes"],
            commonSideEffects: ["Dizziness", "Upper respiratory infection", "Back pain", "Diarrhoea", "Fatigue"],
            storageInstructions: "Store below 30°C. Protect from light.",
            description: "ARB for high blood pressure and diabetic kidney disease.",
            isScheduleH: true
        ))

        db.append(DrugEntry(
            id: "olmesartan", brandName: "Olmetrack", genericName: "Olmesartan",
            saltComposition: "Olmesartan Medoxomil 20mg",
            category: .antihypertensive, manufacturer: "Lupin",
            commonDosages: ["10mg", "20mg", "40mg"], typicalDoseForm: "tablet",
            priceRange: "₹80-180",
            genericAlternatives: [
                GenericAlternative(brandName: "Olmezest", manufacturer: "Sun Pharma", priceRange: "₹60-140"),
                GenericAlternative(brandName: "Olmy", manufacturer: "Micro Labs", priceRange: "₹55-130")
            ],
            foodInteractions: ["Can be taken with or without food", "Avoid potassium supplements"],
            commonSideEffects: ["Dizziness", "Diarrhoea", "Headache", "Back pain", "Bronchitis"],
            storageInstructions: "Store below 30°C. Keep in original packaging.",
            description: "ARB for hypertension, particularly effective in resistant hypertension.",
            isScheduleH: true
        ))

        db.append(DrugEntry(
            id: "telma-h", brandName: "Telma-H", genericName: "Telmisartan + Hydrochlorothiazide",
            saltComposition: "Telmisartan 40mg + Hydrochlorothiazide 12.5mg",
            category: .antihypertensive, manufacturer: "Glenmark Pharmaceuticals",
            commonDosages: ["40/12.5mg", "80/12.5mg"], typicalDoseForm: "tablet",
            priceRange: "₹100-200",
            genericAlternatives: [
                GenericAlternative(brandName: "Telmikind-H", manufacturer: "Mankind", priceRange: "₹60-140"),
                GenericAlternative(brandName: "Telsar-H", manufacturer: "Unichem", priceRange: "₹65-150")
            ],
            foodInteractions: ["Can be taken with or without food", "Avoid potassium-rich salt substitutes", "Stay hydrated"],
            commonSideEffects: ["Dizziness", "Fatigue", "Frequent urination", "Low potassium", "Dehydration"],
            storageInstructions: "Store below 30°C. Protect from moisture.",
            description: "Combination of ARB and diuretic for better blood pressure control.",
            isScheduleH: true
        ))

        db.append(DrugEntry(
            id: "metoprolol", brandName: "Met XL", genericName: "Metoprolol Succinate",
            saltComposition: "Metoprolol Succinate 25mg",
            category: .antihypertensive, manufacturer: "Cipla",
            commonDosages: ["12.5mg", "25mg", "50mg", "100mg"], typicalDoseForm: "tablet",
            priceRange: "₹40-100",
            genericAlternatives: [
                GenericAlternative(brandName: "Revelol-XL", manufacturer: "Lupin", priceRange: "₹30-80"),
                GenericAlternative(brandName: "Metolar XR", manufacturer: "Cipla", priceRange: "₹35-85")
            ],
            foodInteractions: ["Take with food", "Avoid alcohol", "Limit caffeine"],
            commonSideEffects: ["Fatigue", "Dizziness", "Bradycardia", "Cold hands/feet", "Shortness of breath"],
            storageInstructions: "Store below 30°C. Protect from moisture.",
            description: "Selective beta-1 blocker for hypertension, heart failure, and post-MI protection.",
            isScheduleH: true
        ))

        // ────────────────────────────────────────────
        // ANALGESICS (PAIN)
        // ────────────────────────────────────────────

        db.append(DrugEntry(
            id: "combiflam", brandName: "Combiflam", genericName: "Ibuprofen + Paracetamol",
            saltComposition: "Ibuprofen 400mg + Paracetamol 325mg",
            category: .analgesic, manufacturer: "Sanofi India",
            commonDosages: ["400/325mg"], typicalDoseForm: "tablet",
            priceRange: "₹25-45",
            genericAlternatives: [
                GenericAlternative(brandName: "Ibugesic Plus", manufacturer: "Cipla", priceRange: "₹18-35"),
                GenericAlternative(brandName: "Brufen Plus", manufacturer: "Abbott", priceRange: "₹20-38")
            ],
            foodInteractions: ["Take with or after food to reduce stomach irritation", "Avoid alcohol"],
            commonSideEffects: ["Stomach pain", "Nausea", "Heartburn", "Dizziness", "Rash"],
            storageInstructions: "Store below 30°C. Protect from moisture.",
            description: "Combination pain reliever and anti-inflammatory for headaches, dental pain, body aches, and fever.",
            isScheduleH: false
        ))

        db.append(DrugEntry(
            id: "crocin", brandName: "Crocin", genericName: "Paracetamol",
            saltComposition: "Paracetamol 500mg",
            category: .analgesic, manufacturer: "GSK Consumer Healthcare",
            commonDosages: ["500mg", "650mg"], typicalDoseForm: "tablet",
            priceRange: "₹15-30",
            genericAlternatives: [
                GenericAlternative(brandName: "Calpol", manufacturer: "GSK", priceRange: "₹12-25"),
                GenericAlternative(brandName: "Pacimol", manufacturer: "Ipca", priceRange: "₹10-20")
            ],
            foodInteractions: ["Can be taken with or without food", "Avoid alcohol — risk of liver damage"],
            commonSideEffects: ["Nausea (rare)", "Allergic skin reaction (rare)", "Liver damage (overdose)"],
            storageInstructions: "Store below 30°C. Keep away from moisture.",
            description: "Widely used OTC pain reliever and fever reducer. Safe in recommended doses.",
            isScheduleH: false
        ))

        db.append(DrugEntry(
            id: "dolo-650", brandName: "Dolo 650", genericName: "Paracetamol",
            saltComposition: "Paracetamol 650mg",
            category: .analgesic, manufacturer: "Micro Labs",
            commonDosages: ["650mg"], typicalDoseForm: "tablet",
            priceRange: "₹25-40",
            genericAlternatives: [
                GenericAlternative(brandName: "Crocin Advance", manufacturer: "GSK", priceRange: "₹25-38"),
                GenericAlternative(brandName: "Calpol 650", manufacturer: "GSK", priceRange: "₹20-35")
            ],
            foodInteractions: ["Can be taken with or without food", "Strictly avoid alcohol"],
            commonSideEffects: ["Nausea (rare)", "Skin rash (rare)", "Liver damage (overdose)"],
            storageInstructions: "Store below 30°C. Keep away from moisture.",
            description: "Higher-strength paracetamol for moderate pain and fever. Very popular during COVID-19.",
            isScheduleH: false
        ))

        db.append(DrugEntry(
            id: "voveran", brandName: "Voveran", genericName: "Diclofenac",
            saltComposition: "Diclofenac Sodium 50mg",
            category: .analgesic, manufacturer: "Novartis India",
            commonDosages: ["25mg", "50mg", "75mg SR", "100mg SR"], typicalDoseForm: "tablet",
            priceRange: "₹20-60",
            genericAlternatives: [
                GenericAlternative(brandName: "Dynapar", manufacturer: "Troikaa", priceRange: "₹15-50"),
                GenericAlternative(brandName: "Diclogesic", manufacturer: "Jagsonpal", priceRange: "₹12-40")
            ],
            foodInteractions: ["Take with food to reduce stomach upset", "Avoid alcohol"],
            commonSideEffects: ["Stomach pain", "Nausea", "Gastric ulcer", "Dizziness", "Headache"],
            storageInstructions: "Store below 30°C. Protect from light.",
            description: "NSAID for musculoskeletal pain, arthritis, dental pain, and post-operative pain.",
            isScheduleH: true
        ))

        db.append(DrugEntry(
            id: "zerodol", brandName: "Zerodol", genericName: "Aceclofenac",
            saltComposition: "Aceclofenac 100mg",
            category: .analgesic, manufacturer: "Ipca Laboratories",
            commonDosages: ["100mg"], typicalDoseForm: "tablet",
            priceRange: "₹40-80",
            genericAlternatives: [
                GenericAlternative(brandName: "Hifenac", manufacturer: "Intas", priceRange: "₹30-60"),
                GenericAlternative(brandName: "Acemiz", manufacturer: "Lupin", priceRange: "₹25-55")
            ],
            foodInteractions: ["Take after food", "Avoid alcohol"],
            commonSideEffects: ["Stomach pain", "Nausea", "Diarrhoea", "Dizziness", "Headache"],
            storageInstructions: "Store below 30°C. Protect from moisture.",
            description: "NSAID for pain relief in arthritis, dental, and musculoskeletal conditions.",
            isScheduleH: true
        ))

        db.append(DrugEntry(
            id: "brufen", brandName: "Brufen", genericName: "Ibuprofen",
            saltComposition: "Ibuprofen 400mg",
            category: .analgesic, manufacturer: "Abbott India",
            commonDosages: ["200mg", "400mg", "600mg"], typicalDoseForm: "tablet",
            priceRange: "₹15-35",
            genericAlternatives: [
                GenericAlternative(brandName: "Ibugesic", manufacturer: "Cipla", priceRange: "₹12-28"),
                GenericAlternative(brandName: "Ibuprofen", manufacturer: "Various", priceRange: "₹8-20")
            ],
            foodInteractions: ["Take with or after food", "Avoid alcohol"],
            commonSideEffects: ["Stomach pain", "Nausea", "Heartburn", "Headache", "Dizziness"],
            storageInstructions: "Store below 30°C.",
            description: "NSAID for pain, inflammation, and fever. OTC in lower doses.",
            isScheduleH: false
        ))

        db.append(DrugEntry(
            id: "saridon", brandName: "Saridon", genericName: "Propyphenazone + Paracetamol + Caffeine",
            saltComposition: "Propyphenazone 150mg + Paracetamol 250mg + Caffeine 50mg",
            category: .analgesic, manufacturer: "Bayer",
            commonDosages: ["Standard"], typicalDoseForm: "tablet",
            priceRange: "₹20-35",
            genericAlternatives: [
                GenericAlternative(brandName: "Dart", manufacturer: "Reckitt", priceRange: "₹15-25"),
                GenericAlternative(brandName: "Disprin Plus", manufacturer: "Reckitt", priceRange: "₹18-30")
            ],
            foodInteractions: ["Take with water", "Avoid alcohol", "Contains caffeine — avoid late night use"],
            commonSideEffects: ["Nausea", "Stomach upset", "Dizziness", "Insomnia (caffeine)", "Allergic reaction (rare)"],
            storageInstructions: "Store below 30°C. Protect from moisture.",
            description: "Triple-action headache relief with analgesic and caffeine.",
            isScheduleH: false
        ))

        db.append(DrugEntry(
            id: "ultracet", brandName: "Ultracet", genericName: "Tramadol + Paracetamol",
            saltComposition: "Tramadol 37.5mg + Paracetamol 325mg",
            category: .analgesic, manufacturer: "Johnson & Johnson",
            commonDosages: ["37.5/325mg"], typicalDoseForm: "tablet",
            priceRange: "₹60-100",
            genericAlternatives: [
                GenericAlternative(brandName: "Tramazac-P", manufacturer: "Zydus", priceRange: "₹40-70"),
                GenericAlternative(brandName: "Domadol Plus", manufacturer: "Dr. Reddy's", priceRange: "₹35-65")
            ],
            foodInteractions: ["Can be taken with or without food", "Strictly avoid alcohol — risk of respiratory depression"],
            commonSideEffects: ["Drowsiness", "Nausea", "Constipation", "Dizziness", "Headache"],
            storageInstructions: "Store below 30°C. Protect from light.",
            description: "Opioid analgesic combination for moderate to severe pain. Controlled substance.",
            isScheduleH: true
        ))

        // ────────────────────────────────────────────
        // ANTI-ACID / GI
        // ────────────────────────────────────────────

        db.append(DrugEntry(
            id: "pan-40", brandName: "Pan 40", genericName: "Pantoprazole",
            saltComposition: "Pantoprazole 40mg",
            category: .antiAcid, manufacturer: "Alkem Laboratories",
            commonDosages: ["20mg", "40mg"], typicalDoseForm: "tablet",
            priceRange: "₹40-80",
            genericAlternatives: [
                GenericAlternative(brandName: "Pantop", manufacturer: "Aristo", priceRange: "₹35-70"),
                GenericAlternative(brandName: "Pantodac", manufacturer: "Zydus", priceRange: "₹30-65")
            ],
            foodInteractions: ["Take on empty stomach, 30-60 min before meals", "Avoid spicy food and citrus"],
            commonSideEffects: ["Headache", "Diarrhoea", "Nausea", "Abdominal pain", "Vitamin B12 deficiency (long term)"],
            storageInstructions: "Store below 30°C. Protect from moisture.",
            description: "Proton pump inhibitor for acid reflux (GERD), gastric ulcers, and Zollinger-Ellison syndrome.",
            isScheduleH: true
        ))

        db.append(DrugEntry(
            id: "rantac", brandName: "Rantac", genericName: "Ranitidine",
            saltComposition: "Ranitidine 150mg",
            category: .antiAcid, manufacturer: "J.B. Chemicals",
            commonDosages: ["150mg", "300mg"], typicalDoseForm: "tablet",
            priceRange: "₹20-50",
            genericAlternatives: [
                GenericAlternative(brandName: "Zinetac", manufacturer: "GSK", priceRange: "₹25-55"),
                GenericAlternative(brandName: "Aciloc", manufacturer: "Cadila", priceRange: "₹18-40")
            ],
            foodInteractions: ["Can be taken with or without food", "Avoid excessive tea/coffee"],
            commonSideEffects: ["Headache", "Constipation", "Diarrhoea", "Nausea", "Dizziness"],
            storageInstructions: "Store below 30°C. Protect from light and moisture.",
            description: "H2 blocker for acidity, gastric ulcers, and heartburn. Note: Some brands recalled for NDMA contamination.",
            isScheduleH: true
        ))

        db.append(DrugEntry(
            id: "omez", brandName: "Omez", genericName: "Omeprazole",
            saltComposition: "Omeprazole 20mg",
            category: .antiAcid, manufacturer: "Dr. Reddy's Laboratories",
            commonDosages: ["10mg", "20mg", "40mg"], typicalDoseForm: "capsule",
            priceRange: "₹40-90",
            genericAlternatives: [
                GenericAlternative(brandName: "Ocid", manufacturer: "Zydus", priceRange: "₹30-70"),
                GenericAlternative(brandName: "Omecip", manufacturer: "Cipla", priceRange: "₹25-60")
            ],
            foodInteractions: ["Take on empty stomach, before breakfast", "Avoid spicy and acidic foods"],
            commonSideEffects: ["Headache", "Nausea", "Diarrhoea", "Abdominal pain", "Flatulence"],
            storageInstructions: "Store below 25°C. Protect from moisture. Do not crush capsules.",
            description: "Proton pump inhibitor for GERD, peptic ulcers, and H. pylori eradication.",
            isScheduleH: true
        ))

        db.append(DrugEntry(
            id: "razo", brandName: "Razo", genericName: "Rabeprazole",
            saltComposition: "Rabeprazole 20mg",
            category: .antiAcid, manufacturer: "Dr. Reddy's Laboratories",
            commonDosages: ["10mg", "20mg"], typicalDoseForm: "tablet",
            priceRange: "₹60-120",
            genericAlternatives: [
                GenericAlternative(brandName: "Rablet", manufacturer: "Lupin", priceRange: "₹50-100"),
                GenericAlternative(brandName: "Rabiloz", manufacturer: "Sun Pharma", priceRange: "₹45-90")
            ],
            foodInteractions: ["Take on empty stomach before meals", "Swallow whole — do not crush"],
            commonSideEffects: ["Headache", "Diarrhoea", "Nausea", "Flatulence", "Abdominal pain"],
            storageInstructions: "Store below 30°C. Protect from moisture.",
            description: "PPI for acid reflux, ulcers, and erosive esophagitis.",
            isScheduleH: true
        ))

        db.append(DrugEntry(
            id: "pantop", brandName: "Pantop", genericName: "Pantoprazole",
            saltComposition: "Pantoprazole 40mg",
            category: .antiAcid, manufacturer: "Aristo Pharmaceuticals",
            commonDosages: ["20mg", "40mg"], typicalDoseForm: "tablet",
            priceRange: "₹35-70",
            genericAlternatives: [
                GenericAlternative(brandName: "Pan 40", manufacturer: "Alkem", priceRange: "₹40-80"),
                GenericAlternative(brandName: "Pantodac", manufacturer: "Zydus", priceRange: "₹30-65")
            ],
            foodInteractions: ["Take on empty stomach before meals"],
            commonSideEffects: ["Headache", "Diarrhoea", "Nausea", "Abdominal pain", "Flatulence"],
            storageInstructions: "Store below 30°C. Protect from moisture.",
            description: "PPI for acid-related disorders. Generic alternative to Pan 40.",
            isScheduleH: true
        ))

        db.append(DrugEntry(
            id: "zantac", brandName: "Zantac", genericName: "Ranitidine",
            saltComposition: "Ranitidine 150mg",
            category: .antiAcid, manufacturer: "GSK (discontinued in many markets)",
            commonDosages: ["150mg", "300mg"], typicalDoseForm: "tablet",
            priceRange: "₹30-60",
            genericAlternatives: [
                GenericAlternative(brandName: "Rantac", manufacturer: "J.B. Chemicals", priceRange: "₹20-50"),
                GenericAlternative(brandName: "Aciloc", manufacturer: "Cadila", priceRange: "₹18-40")
            ],
            foodInteractions: ["Can be taken with or without food"],
            commonSideEffects: ["Headache", "Constipation", "Nausea", "Dizziness"],
            storageInstructions: "Store below 30°C. Protect from light.",
            description: "H2 blocker for acidity. Note: Recalled in many countries due to NDMA concerns.",
            isScheduleH: true
        ))

        db.append(DrugEntry(
            id: "domperidone", brandName: "Domstal", genericName: "Domperidone",
            saltComposition: "Domperidone 10mg",
            category: .antiAcid, manufacturer: "Torrent Pharmaceuticals",
            commonDosages: ["10mg"], typicalDoseForm: "tablet",
            priceRange: "₹20-45",
            genericAlternatives: [
                GenericAlternative(brandName: "Vomistop", manufacturer: "Cipla", priceRange: "₹15-35"),
                GenericAlternative(brandName: "Domperi", manufacturer: "Mankind", priceRange: "₹12-30")
            ],
            foodInteractions: ["Take 15-30 minutes before meals"],
            commonSideEffects: ["Dry mouth", "Headache", "Diarrhoea", "Drowsiness", "Breast tenderness"],
            storageInstructions: "Store below 30°C. Protect from light.",
            description: "Anti-emetic for nausea, vomiting, and bloating. Promotes stomach emptying.",
            isScheduleH: true
        ))

        // ────────────────────────────────────────────
        // ANTI-ALLERGY
        // ────────────────────────────────────────────

        db.append(DrugEntry(
            id: "cetirizine", brandName: "Cetzine", genericName: "Cetirizine",
            saltComposition: "Cetirizine Hydrochloride 10mg",
            category: .antiAllergy, manufacturer: "GSK Consumer Healthcare",
            commonDosages: ["5mg", "10mg"], typicalDoseForm: "tablet",
            priceRange: "₹15-40",
            genericAlternatives: [
                GenericAlternative(brandName: "Okacet", manufacturer: "Cipla", priceRange: "₹12-30"),
                GenericAlternative(brandName: "Alerid", manufacturer: "Cipla", priceRange: "₹10-25")
            ],
            foodInteractions: ["Can be taken with or without food", "Avoid alcohol — increased sedation"],
            commonSideEffects: ["Drowsiness", "Dry mouth", "Headache", "Fatigue", "Dizziness"],
            storageInstructions: "Store below 30°C. Protect from moisture.",
            description: "Second-generation antihistamine for allergic rhinitis, urticaria, and itching.",
            isScheduleH: false
        ))

        db.append(DrugEntry(
            id: "allegra", brandName: "Allegra", genericName: "Fexofenadine",
            saltComposition: "Fexofenadine Hydrochloride 120mg",
            category: .antiAllergy, manufacturer: "Sanofi India",
            commonDosages: ["30mg", "60mg", "120mg", "180mg"], typicalDoseForm: "tablet",
            priceRange: "₹80-160",
            genericAlternatives: [
                GenericAlternative(brandName: "Fexova", manufacturer: "Micro Labs", priceRange: "₹50-100"),
                GenericAlternative(brandName: "Fexorich", manufacturer: "Alkem", priceRange: "₹45-90")
            ],
            foodInteractions: ["Avoid grapefruit juice", "Avoid fruit juices within 4 hours — reduces absorption"],
            commonSideEffects: ["Headache", "Nausea", "Dizziness", "Drowsiness (rare)", "Back pain"],
            storageInstructions: "Store below 30°C. Protect from moisture.",
            description: "Non-drowsy antihistamine for seasonal allergies and chronic urticaria.",
            isScheduleH: true
        ))

        db.append(DrugEntry(
            id: "montair-lc", brandName: "Montair LC", genericName: "Montelukast + Levocetirizine",
            saltComposition: "Montelukast 10mg + Levocetirizine 5mg",
            category: .antiAllergy, manufacturer: "Cipla",
            commonDosages: ["10/5mg"], typicalDoseForm: "tablet",
            priceRange: "₹100-180",
            genericAlternatives: [
                GenericAlternative(brandName: "Montek LC", manufacturer: "Sun Pharma", priceRange: "₹80-140"),
                GenericAlternative(brandName: "L-Montus", manufacturer: "Glenmark", priceRange: "₹70-130")
            ],
            foodInteractions: ["Take in the evening", "Can be taken with or without food", "Avoid alcohol — drowsiness"],
            commonSideEffects: ["Drowsiness", "Dry mouth", "Headache", "Fatigue", "Abdominal pain"],
            storageInstructions: "Store below 30°C. Protect from moisture and light.",
            description: "Combination anti-allergy for allergic rhinitis, asthma, and urticaria.",
            isScheduleH: true
        ))

        db.append(DrugEntry(
            id: "levocetrizine", brandName: "Xyzal", genericName: "Levocetirizine",
            saltComposition: "Levocetirizine Dihydrochloride 5mg",
            category: .antiAllergy, manufacturer: "UCB India",
            commonDosages: ["5mg"], typicalDoseForm: "tablet",
            priceRange: "₹30-70",
            genericAlternatives: [
                GenericAlternative(brandName: "Levocet", manufacturer: "Sun Pharma", priceRange: "₹20-50"),
                GenericAlternative(brandName: "Vozet", manufacturer: "Mankind", priceRange: "₹15-40")
            ],
            foodInteractions: ["Can be taken with or without food", "Avoid alcohol"],
            commonSideEffects: ["Drowsiness", "Dry mouth", "Headache", "Fatigue", "Nausea"],
            storageInstructions: "Store below 30°C. Protect from light.",
            description: "Potent antihistamine with less sedation. Active isomer of cetirizine.",
            isScheduleH: false
        ))

        db.append(DrugEntry(
            id: "montelukast", brandName: "Montair", genericName: "Montelukast",
            saltComposition: "Montelukast Sodium 10mg",
            category: .antiAllergy, manufacturer: "Cipla",
            commonDosages: ["4mg", "5mg", "10mg"], typicalDoseForm: "tablet",
            priceRange: "₹80-160",
            genericAlternatives: [
                GenericAlternative(brandName: "Montek", manufacturer: "Sun Pharma", priceRange: "₹60-120"),
                GenericAlternative(brandName: "Romilast", manufacturer: "Ranbaxy", priceRange: "₹55-110")
            ],
            foodInteractions: ["Take in the evening", "Can be taken with or without food"],
            commonSideEffects: ["Headache", "Abdominal pain", "Fatigue", "Mood changes (rare)", "Upper respiratory infection"],
            storageInstructions: "Store below 30°C. Protect from light and moisture.",
            description: "Leukotriene receptor antagonist for asthma prevention and allergic rhinitis.",
            isScheduleH: true
        ))

        // ────────────────────────────────────────────
        // CHOLESTEROL
        // ────────────────────────────────────────────

        db.append(DrugEntry(
            id: "atorva", brandName: "Atorva", genericName: "Atorvastatin",
            saltComposition: "Atorvastatin Calcium 10mg",
            category: .cholesterol, manufacturer: "Zydus Cadila",
            commonDosages: ["5mg", "10mg", "20mg", "40mg", "80mg"], typicalDoseForm: "tablet",
            priceRange: "₹50-150",
            genericAlternatives: [
                GenericAlternative(brandName: "Lipitor", manufacturer: "Pfizer", priceRange: "₹80-200"),
                GenericAlternative(brandName: "Atocor", manufacturer: "Dr. Reddy's", priceRange: "₹40-120")
            ],
            foodInteractions: ["Avoid grapefruit and grapefruit juice", "Can be taken with or without food", "Take at bedtime for best effect"],
            commonSideEffects: ["Muscle pain", "Joint pain", "Diarrhoea", "Nausea", "Elevated liver enzymes"],
            storageInstructions: "Store below 30°C. Protect from moisture and light.",
            description: "Statin for high cholesterol and cardiovascular risk reduction. Most prescribed statin in India.",
            isScheduleH: true
        ))

        db.append(DrugEntry(
            id: "rosuvas", brandName: "Rosuvas", genericName: "Rosuvastatin",
            saltComposition: "Rosuvastatin Calcium 10mg",
            category: .cholesterol, manufacturer: "Sun Pharmaceutical",
            commonDosages: ["5mg", "10mg", "20mg", "40mg"], typicalDoseForm: "tablet",
            priceRange: "₹80-200",
            genericAlternatives: [
                GenericAlternative(brandName: "Rozavel", manufacturer: "Sun Pharma", priceRange: "₹70-180"),
                GenericAlternative(brandName: "Rosulip", manufacturer: "Cipla", priceRange: "₹60-150")
            ],
            foodInteractions: ["Can be taken with or without food", "Avoid excessive grapefruit", "Avoid excessive alcohol"],
            commonSideEffects: ["Headache", "Muscle pain", "Nausea", "Weakness", "Abdominal pain"],
            storageInstructions: "Store below 30°C. Protect from moisture.",
            description: "Potent statin for high cholesterol. More effective than atorvastatin at lower doses.",
            isScheduleH: true
        ))

        db.append(DrugEntry(
            id: "crestor", brandName: "Crestor", genericName: "Rosuvastatin",
            saltComposition: "Rosuvastatin Calcium 10mg",
            category: .cholesterol, manufacturer: "AstraZeneca",
            commonDosages: ["5mg", "10mg", "20mg", "40mg"], typicalDoseForm: "tablet",
            priceRange: "₹200-400",
            genericAlternatives: [
                GenericAlternative(brandName: "Rosuvas", manufacturer: "Sun Pharma", priceRange: "₹80-200"),
                GenericAlternative(brandName: "Rozavel", manufacturer: "Sun Pharma", priceRange: "₹70-180")
            ],
            foodInteractions: ["Can be taken with or without food", "Avoid grapefruit"],
            commonSideEffects: ["Headache", "Muscle pain", "Nausea", "Constipation", "Weakness"],
            storageInstructions: "Store below 30°C. Protect from moisture and light.",
            description: "Brand-name rosuvastatin. Premium-priced but identical to generics.",
            isScheduleH: true
        ))

        db.append(DrugEntry(
            id: "ezentia", brandName: "Ezentia", genericName: "Ezetimibe",
            saltComposition: "Ezetimibe 10mg",
            category: .cholesterol, manufacturer: "Sun Pharma",
            commonDosages: ["10mg"], typicalDoseForm: "tablet",
            priceRange: "₹120-200",
            genericAlternatives: [
                GenericAlternative(brandName: "Zetia", manufacturer: "MSD", priceRange: "₹250-400"),
                GenericAlternative(brandName: "Ezetrol", manufacturer: "MSD", priceRange: "₹200-350")
            ],
            foodInteractions: ["Can be taken with or without food"],
            commonSideEffects: ["Diarrhoea", "Joint pain", "Fatigue", "Upper respiratory infection", "Sinusitis"],
            storageInstructions: "Store below 30°C.",
            description: "Cholesterol absorption inhibitor, often used with statins for additional LDL lowering.",
            isScheduleH: true
        ))

        // ────────────────────────────────────────────
        // THYROID
        // ────────────────────────────────────────────

        db.append(DrugEntry(
            id: "thyronorm", brandName: "Thyronorm", genericName: "Levothyroxine",
            saltComposition: "Levothyroxine Sodium 50mcg",
            category: .thyroid, manufacturer: "Abbott India",
            commonDosages: ["12.5mcg", "25mcg", "50mcg", "75mcg", "100mcg", "125mcg", "150mcg"], typicalDoseForm: "tablet",
            priceRange: "₹80-150",
            genericAlternatives: [
                GenericAlternative(brandName: "Eltroxin", manufacturer: "GSK", priceRange: "₹90-160"),
                GenericAlternative(brandName: "Thyrox", manufacturer: "Macleods", priceRange: "₹60-110")
            ],
            foodInteractions: ["Take on empty stomach, 30-60 min before breakfast",
                              "Avoid calcium, iron, antacids within 4 hours",
                              "Avoid soy products close to dose time"],
            commonSideEffects: ["Palpitations (if overdosed)", "Weight loss (if overdosed)", "Tremor", "Insomnia", "Headache"],
            storageInstructions: "Store below 25°C. Protect from light and moisture.",
            description: "Thyroid hormone replacement for hypothyroidism. Lifelong medication for most patients.",
            isScheduleH: true
        ))

        db.append(DrugEntry(
            id: "eltroxin", brandName: "Eltroxin", genericName: "Levothyroxine",
            saltComposition: "Levothyroxine Sodium 50mcg",
            category: .thyroid, manufacturer: "GSK Pharmaceuticals",
            commonDosages: ["25mcg", "50mcg", "75mcg", "100mcg"], typicalDoseForm: "tablet",
            priceRange: "₹90-160",
            genericAlternatives: [
                GenericAlternative(brandName: "Thyronorm", manufacturer: "Abbott", priceRange: "₹80-150"),
                GenericAlternative(brandName: "Thyrox", manufacturer: "Macleods", priceRange: "₹60-110")
            ],
            foodInteractions: ["Take on empty stomach, 30-60 min before breakfast",
                              "Avoid calcium and iron supplements within 4 hours"],
            commonSideEffects: ["Palpitations", "Weight changes", "Tremor", "Insomnia", "Headache"],
            storageInstructions: "Store below 25°C. Protect from light and moisture.",
            description: "Thyroid hormone replacement. One of the oldest levothyroxine brands in India.",
            isScheduleH: true
        ))

        // ────────────────────────────────────────────
        // VITAMINS / SUPPLEMENTS
        // ────────────────────────────────────────────

        db.append(DrugEntry(
            id: "shelcal", brandName: "Shelcal", genericName: "Calcium + Vitamin D3",
            saltComposition: "Calcium Carbonate 500mg + Vitamin D3 250IU",
            category: .vitamin, manufacturer: "Torrent Pharmaceuticals",
            commonDosages: ["500mg"], typicalDoseForm: "tablet",
            priceRange: "₹80-150",
            genericAlternatives: [
                GenericAlternative(brandName: "Calcimax", manufacturer: "Meyer Organics", priceRange: "₹90-160"),
                GenericAlternative(brandName: "CCM", manufacturer: "Cadila", priceRange: "₹60-100")
            ],
            foodInteractions: ["Take with meals for better absorption", "Avoid taking with spinach or high-oxalate foods"],
            commonSideEffects: ["Constipation", "Bloating", "Gas", "Stomach upset"],
            storageInstructions: "Store below 30°C. Keep in original container.",
            description: "Calcium and Vitamin D supplement for bone health and osteoporosis prevention.",
            isScheduleH: false
        ))

        db.append(DrugEntry(
            id: "becosules", brandName: "Becosules", genericName: "B-Complex + Vitamin C",
            saltComposition: "Vitamin B-Complex + Folic Acid + Vitamin C",
            category: .vitamin, manufacturer: "Pfizer",
            commonDosages: ["Standard"], typicalDoseForm: "capsule",
            priceRange: "₹25-50",
            genericAlternatives: [
                GenericAlternative(brandName: "Polybion", manufacturer: "Abbott", priceRange: "₹30-55"),
                GenericAlternative(brandName: "B-Complex", manufacturer: "Various", priceRange: "₹15-30")
            ],
            foodInteractions: ["Take with or after meals"],
            commonSideEffects: ["Nausea (rare)", "Yellow urine (normal)", "Stomach upset (rare)"],
            storageInstructions: "Store below 25°C. Protect from light and moisture.",
            description: "Multivitamin for B-vitamin deficiency, mouth ulcers, and general wellness.",
            isScheduleH: false
        ))

        db.append(DrugEntry(
            id: "neurobion", brandName: "Neurobion Forte", genericName: "Vitamin B1 + B6 + B12",
            saltComposition: "Thiamine 10mg + Pyridoxine 3mg + Cyanocobalamin 15mcg",
            category: .vitamin, manufacturer: "P&G Health (Merck)",
            commonDosages: ["Standard"], typicalDoseForm: "tablet",
            priceRange: "₹30-60",
            genericAlternatives: [
                GenericAlternative(brandName: "Meconerv", manufacturer: "Aristo", priceRange: "₹25-50"),
                GenericAlternative(brandName: "Tricobal", manufacturer: "Biochem", priceRange: "₹20-40")
            ],
            foodInteractions: ["Take after meals"],
            commonSideEffects: ["Nausea (rare)", "Diarrhoea (rare)", "Skin rash (rare)"],
            storageInstructions: "Store below 30°C. Protect from light.",
            description: "B-vitamin supplement for peripheral neuropathy, tingling, and numbness.",
            isScheduleH: false
        ))

        db.append(DrugEntry(
            id: "zincovit", brandName: "Zincovit", genericName: "Multivitamin + Multimineral + Zinc",
            saltComposition: "Zinc + Vitamins A, B, C, D, E + Minerals",
            category: .vitamin, manufacturer: "Apex Laboratories",
            commonDosages: ["Standard"], typicalDoseForm: "tablet",
            priceRange: "₹60-110",
            genericAlternatives: [
                GenericAlternative(brandName: "Supradyn", manufacturer: "Abbott", priceRange: "₹70-130"),
                GenericAlternative(brandName: "A to Z", manufacturer: "Alkem", priceRange: "₹50-90")
            ],
            foodInteractions: ["Take with or after meals", "Avoid with tea/coffee — reduces iron absorption"],
            commonSideEffects: ["Nausea", "Stomach upset", "Constipation", "Metallic taste"],
            storageInstructions: "Store below 30°C. Protect from moisture.",
            description: "Complete multivitamin and mineral supplement with added zinc for immunity.",
            isScheduleH: false
        ))

        db.append(DrugEntry(
            id: "revital", brandName: "Revital H", genericName: "Multivitamin + Ginseng",
            saltComposition: "Multivitamins + Minerals + Ginseng Extract",
            category: .vitamin, manufacturer: "Sun Pharma",
            commonDosages: ["Standard"], typicalDoseForm: "capsule",
            priceRange: "₹150-250",
            genericAlternatives: [
                GenericAlternative(brandName: "Supradyn", manufacturer: "Abbott", priceRange: "₹70-130"),
                GenericAlternative(brandName: "Zincovit", manufacturer: "Apex", priceRange: "₹60-110")
            ],
            foodInteractions: ["Take with meals", "Avoid on empty stomach"],
            commonSideEffects: ["Nausea", "Insomnia (ginseng)", "Headache", "Stomach upset"],
            storageInstructions: "Store below 30°C. Protect from moisture.",
            description: "Daily multivitamin with ginseng for energy and vitality.",
            isScheduleH: false
        ))

        db.append(DrugEntry(
            id: "supradyn", brandName: "Supradyn", genericName: "Multivitamin + Multimineral",
            saltComposition: "Vitamins A, B1, B2, B6, B12, C, D3, E + Iron, Zinc, Copper, Manganese",
            category: .vitamin, manufacturer: "Abbott India",
            commonDosages: ["Standard"], typicalDoseForm: "tablet",
            priceRange: "₹70-130",
            genericAlternatives: [
                GenericAlternative(brandName: "Zincovit", manufacturer: "Apex", priceRange: "₹60-110"),
                GenericAlternative(brandName: "A to Z", manufacturer: "Alkem", priceRange: "₹50-90")
            ],
            foodInteractions: ["Take after meals", "Avoid tea/coffee 1 hour before/after"],
            commonSideEffects: ["Nausea", "Constipation", "Dark stool (iron)", "Stomach upset"],
            storageInstructions: "Store below 30°C. Protect from moisture.",
            description: "Comprehensive daily multivitamin-mineral supplement.",
            isScheduleH: false
        ))

        db.append(DrugEntry(
            id: "limcee", brandName: "Limcee", genericName: "Ascorbic Acid (Vitamin C)",
            saltComposition: "Ascorbic Acid 500mg",
            category: .vitamin, manufacturer: "Abbott India",
            commonDosages: ["100mg", "500mg"], typicalDoseForm: "tablet",
            priceRange: "₹15-35",
            genericAlternatives: [
                GenericAlternative(brandName: "Celin", manufacturer: "GSK", priceRange: "₹12-28"),
                GenericAlternative(brandName: "Vitamin C", manufacturer: "Various", priceRange: "₹8-20")
            ],
            foodInteractions: ["Can be taken with or without food", "High doses may upset stomach"],
            commonSideEffects: ["Stomach upset (high doses)", "Diarrhoea (high doses)", "Kidney stones (prolonged high doses)"],
            storageInstructions: "Store below 30°C. Protect from light and moisture.",
            description: "Vitamin C supplement for immunity, wound healing, and antioxidant support.",
            isScheduleH: false
        ))

        db.append(DrugEntry(
            id: "methylcobalamin", brandName: "Mecobalamin", genericName: "Methylcobalamin",
            saltComposition: "Methylcobalamin 1500mcg",
            category: .vitamin, manufacturer: "Various",
            commonDosages: ["500mcg", "1500mcg"], typicalDoseForm: "tablet",
            priceRange: "₹50-120",
            genericAlternatives: [
                GenericAlternative(brandName: "Methycobal", manufacturer: "Eisai", priceRange: "₹100-200"),
                GenericAlternative(brandName: "Meconeuron", manufacturer: "Aristo", priceRange: "₹60-130")
            ],
            foodInteractions: ["Can be taken with or without food"],
            commonSideEffects: ["Nausea (rare)", "Diarrhoea (rare)", "Headache (rare)"],
            storageInstructions: "Store below 30°C. Protect from light.",
            description: "Active form of Vitamin B12 for neuropathy and B12 deficiency.",
            isScheduleH: false
        ))

        db.append(DrugEntry(
            id: "iron-folic", brandName: "Autrin", genericName: "Iron + Folic Acid",
            saltComposition: "Ferrous Fumarate 300mg + Folic Acid 1.5mg",
            category: .vitamin, manufacturer: "GSK",
            commonDosages: ["Standard"], typicalDoseForm: "capsule",
            priceRange: "₹30-60",
            genericAlternatives: [
                GenericAlternative(brandName: "Fefol", manufacturer: "GSK", priceRange: "₹25-50"),
                GenericAlternative(brandName: "Dexorange", manufacturer: "Franco-Indian", priceRange: "₹100-180 (syrup)")
            ],
            foodInteractions: ["Take on empty stomach with Vitamin C for better absorption", "Avoid tea, coffee, milk within 2 hours"],
            commonSideEffects: ["Constipation", "Black stools", "Nausea", "Stomach cramps", "Metallic taste"],
            storageInstructions: "Store below 30°C. Keep away from moisture.",
            description: "Iron and folic acid supplement for anaemia, especially during pregnancy.",
            isScheduleH: false
        ))

        // ────────────────────────────────────────────
        // CARDIOVASCULAR
        // ────────────────────────────────────────────

        db.append(DrugEntry(
            id: "ecosprin", brandName: "Ecosprin", genericName: "Aspirin",
            saltComposition: "Aspirin (Acetylsalicylic Acid) 75mg",
            category: .cardiovascular, manufacturer: "USV Private Limited",
            commonDosages: ["75mg", "150mg", "325mg"], typicalDoseForm: "tablet",
            priceRange: "₹10-30",
            genericAlternatives: [
                GenericAlternative(brandName: "Disprin", manufacturer: "Reckitt", priceRange: "₹8-20"),
                GenericAlternative(brandName: "Aspirin", manufacturer: "Various", priceRange: "₹5-15")
            ],
            foodInteractions: ["Take with food to reduce stomach irritation", "Avoid alcohol"],
            commonSideEffects: ["Gastric irritation", "Heartburn", "Nausea", "Easy bruising", "GI bleeding (long term)"],
            storageInstructions: "Store below 30°C. Protect from moisture.",
            description: "Low-dose aspirin for heart attack and stroke prevention (antiplatelet).",
            isScheduleH: false
        ))

        db.append(DrugEntry(
            id: "clopidogrel", brandName: "Clopilet", genericName: "Clopidogrel",
            saltComposition: "Clopidogrel Bisulfate 75mg",
            category: .cardiovascular, manufacturer: "Sun Pharmaceutical",
            commonDosages: ["75mg"], typicalDoseForm: "tablet",
            priceRange: "₹60-130",
            genericAlternatives: [
                GenericAlternative(brandName: "Plavix", manufacturer: "Sanofi", priceRange: "₹120-250"),
                GenericAlternative(brandName: "Clopigrel", manufacturer: "Cipla", priceRange: "₹50-100")
            ],
            foodInteractions: ["Can be taken with or without food"],
            commonSideEffects: ["Bleeding", "Bruising", "Diarrhoea", "Stomach pain", "Rash"],
            storageInstructions: "Store below 30°C. Protect from moisture.",
            description: "Antiplatelet drug to prevent blood clots after heart attack, stent, or stroke.",
            isScheduleH: true
        ))

        db.append(DrugEntry(
            id: "prasugrel", brandName: "Prasita", genericName: "Prasugrel",
            saltComposition: "Prasugrel 10mg",
            category: .cardiovascular, manufacturer: "USV Private Limited",
            commonDosages: ["5mg", "10mg"], typicalDoseForm: "tablet",
            priceRange: "₹150-300",
            genericAlternatives: [
                GenericAlternative(brandName: "Effient", manufacturer: "Daiichi Sankyo", priceRange: "₹200-400"),
                GenericAlternative(brandName: "Prasuvas", manufacturer: "Sun Pharma", priceRange: "₹120-250")
            ],
            foodInteractions: ["Can be taken with or without food"],
            commonSideEffects: ["Bleeding", "Bruising", "Headache", "Back pain", "Dyspnoea"],
            storageInstructions: "Store below 30°C. Protect from moisture.",
            description: "Newer antiplatelet, more potent than clopidogrel. Used after coronary stenting.",
            isScheduleH: true
        ))

        db.append(DrugEntry(
            id: "ticagrelor", brandName: "Brilinta", genericName: "Ticagrelor",
            saltComposition: "Ticagrelor 90mg",
            category: .cardiovascular, manufacturer: "AstraZeneca",
            commonDosages: ["60mg", "90mg"], typicalDoseForm: "tablet",
            priceRange: "₹200-450",
            genericAlternatives: [
                GenericAlternative(brandName: "Ticagrel", manufacturer: "Sun Pharma", priceRange: "₹150-300"),
                GenericAlternative(brandName: "Axcer", manufacturer: "Cipla", priceRange: "₹140-280")
            ],
            foodInteractions: ["Can be taken with or without food", "Avoid grapefruit juice"],
            commonSideEffects: ["Dyspnoea", "Bleeding", "Headache", "Nausea", "Diarrhoea"],
            storageInstructions: "Store below 30°C. Protect from moisture.",
            description: "Reversible antiplatelet for acute coronary syndrome.",
            isScheduleH: true
        ))

        db.append(DrugEntry(
            id: "warfarin", brandName: "Warf", genericName: "Warfarin",
            saltComposition: "Warfarin Sodium 5mg",
            category: .cardiovascular, manufacturer: "Cipla",
            commonDosages: ["1mg", "2mg", "3mg", "5mg"], typicalDoseForm: "tablet",
            priceRange: "₹15-40",
            genericAlternatives: [
                GenericAlternative(brandName: "Acitrom (Acenocoumarol)", manufacturer: "Abbott", priceRange: "₹30-60"),
                GenericAlternative(brandName: "Coumadin", manufacturer: "Various", priceRange: "₹20-50")
            ],
            foodInteractions: ["Maintain consistent Vitamin K intake (green leafy vegetables)",
                              "Avoid cranberry juice",
                              "Avoid alcohol — increases bleeding risk"],
            commonSideEffects: ["Bleeding", "Bruising", "Nausea", "Rash", "Hair loss"],
            storageInstructions: "Store below 30°C. Protect from light.",
            description: "Anticoagulant (blood thinner) for DVT, pulmonary embolism, and atrial fibrillation.",
            isScheduleH: true
        ))

        // ────────────────────────────────────────────
        // RESPIRATORY
        // ────────────────────────────────────────────

        db.append(DrugEntry(
            id: "asthalin", brandName: "Asthalin", genericName: "Salbutamol",
            saltComposition: "Salbutamol 100mcg/puff",
            category: .respiratory, manufacturer: "Cipla",
            commonDosages: ["100mcg", "200mcg"], typicalDoseForm: "inhaler",
            priceRange: "₹100-180",
            genericAlternatives: [
                GenericAlternative(brandName: "Ventolin", manufacturer: "GSK", priceRange: "₹120-200"),
                GenericAlternative(brandName: "Salbair", manufacturer: "Lupin", priceRange: "₹80-150")
            ],
            foodInteractions: ["No significant food interactions", "Caffeine may worsen tremors"],
            commonSideEffects: ["Tremor", "Palpitations", "Headache", "Throat irritation", "Muscle cramps"],
            storageInstructions: "Store below 30°C. Do not puncture or burn canister. Protect from sunlight.",
            description: "Short-acting bronchodilator (SABA) for acute asthma relief and bronchospasm.",
            isScheduleH: true
        ))

        db.append(DrugEntry(
            id: "deriphyllin", brandName: "Deriphyllin", genericName: "Etophylline + Theophylline",
            saltComposition: "Etophylline 77mg + Theophylline 23mg",
            category: .respiratory, manufacturer: "Zydus Cadila",
            commonDosages: ["Standard", "Retard 300mg"], typicalDoseForm: "tablet",
            priceRange: "₹20-50",
            genericAlternatives: [
                GenericAlternative(brandName: "Theodrip", manufacturer: "Cipla", priceRange: "₹15-40"),
                GenericAlternative(brandName: "Unicontin", manufacturer: "Cipla", priceRange: "₹30-60")
            ],
            foodInteractions: ["Avoid caffeine — additive effects", "Take with food to reduce stomach upset"],
            commonSideEffects: ["Nausea", "Palpitations", "Insomnia", "Headache", "Stomach upset"],
            storageInstructions: "Store below 30°C. Protect from moisture.",
            description: "Bronchodilator combination for asthma and COPD.",
            isScheduleH: true
        ))

        db.append(DrugEntry(
            id: "seroflo", brandName: "Seroflo", genericName: "Salmeterol + Fluticasone",
            saltComposition: "Salmeterol 25mcg + Fluticasone 125mcg",
            category: .respiratory, manufacturer: "Cipla",
            commonDosages: ["25/50mcg", "25/125mcg", "25/250mcg"], typicalDoseForm: "inhaler",
            priceRange: "₹250-500",
            genericAlternatives: [
                GenericAlternative(brandName: "Seretide", manufacturer: "GSK", priceRange: "₹350-650"),
                GenericAlternative(brandName: "Salmeter-F", manufacturer: "Sun Pharma", priceRange: "₹200-400")
            ],
            foodInteractions: ["Rinse mouth after use to prevent thrush", "No direct food interactions"],
            commonSideEffects: ["Oral thrush", "Hoarse voice", "Throat irritation", "Headache", "Tremor"],
            storageInstructions: "Store below 30°C. Do not freeze. Protect from sunlight.",
            description: "Combination ICS/LABA inhaler for asthma and COPD maintenance therapy.",
            isScheduleH: true
        ))

        db.append(DrugEntry(
            id: "foracort", brandName: "Foracort", genericName: "Formoterol + Budesonide",
            saltComposition: "Formoterol 6mcg + Budesonide 200mcg",
            category: .respiratory, manufacturer: "Cipla",
            commonDosages: ["6/100mcg", "6/200mcg", "6/400mcg"], typicalDoseForm: "inhaler",
            priceRange: "₹300-600",
            genericAlternatives: [
                GenericAlternative(brandName: "Symbicort", manufacturer: "AstraZeneca", priceRange: "₹400-750"),
                GenericAlternative(brandName: "Budamate", manufacturer: "Lupin", priceRange: "₹250-500")
            ],
            foodInteractions: ["Rinse mouth after use", "No direct food interactions"],
            commonSideEffects: ["Oral thrush", "Hoarse voice", "Headache", "Tremor", "Palpitations"],
            storageInstructions: "Store below 30°C. Protect from moisture.",
            description: "ICS/LABA combination for asthma and COPD. Available as Rotacaps and MDI.",
            isScheduleH: true
        ))

        db.append(DrugEntry(
            id: "budecort", brandName: "Budecort", genericName: "Budesonide",
            saltComposition: "Budesonide 200mcg",
            category: .respiratory, manufacturer: "Cipla",
            commonDosages: ["100mcg", "200mcg", "400mcg"], typicalDoseForm: "inhaler",
            priceRange: "₹150-350",
            genericAlternatives: [
                GenericAlternative(brandName: "Pulmicort", manufacturer: "AstraZeneca", priceRange: "₹200-450"),
                GenericAlternative(brandName: "Budesal", manufacturer: "Sun Pharma", priceRange: "₹120-280")
            ],
            foodInteractions: ["Rinse mouth after inhalation", "No direct food interactions"],
            commonSideEffects: ["Oral thrush", "Hoarse voice", "Cough", "Headache", "Throat irritation"],
            storageInstructions: "Store below 30°C. Protect from moisture and light.",
            description: "Inhaled corticosteroid for asthma prevention and COPD.",
            isScheduleH: true
        ))

        db.append(DrugEntry(
            id: "montelukast-resp", brandName: "Montair", genericName: "Montelukast",
            saltComposition: "Montelukast Sodium 10mg",
            category: .respiratory, manufacturer: "Cipla",
            commonDosages: ["4mg", "5mg", "10mg"], typicalDoseForm: "tablet",
            priceRange: "₹80-160",
            genericAlternatives: [
                GenericAlternative(brandName: "Montek", manufacturer: "Sun Pharma", priceRange: "₹60-120"),
                GenericAlternative(brandName: "Montelo", manufacturer: "Torrent", priceRange: "₹55-110")
            ],
            foodInteractions: ["Take in the evening", "Can be taken with or without food"],
            commonSideEffects: ["Headache", "Abdominal pain", "Cough", "Diarrhoea", "Mood changes (rare)"],
            storageInstructions: "Store below 30°C. Protect from light and moisture.",
            description: "Leukotriene antagonist for asthma prevention and exercise-induced bronchoconstriction.",
            isScheduleH: true
        ))

        // ────────────────────────────────────────────
        // ANTI-DEPRESSANT
        // ────────────────────────────────────────────

        db.append(DrugEntry(
            id: "nexito", brandName: "Nexito", genericName: "Escitalopram",
            saltComposition: "Escitalopram Oxalate 10mg",
            category: .antiDepressant, manufacturer: "Sun Pharmaceutical",
            commonDosages: ["5mg", "10mg", "20mg"], typicalDoseForm: "tablet",
            priceRange: "₹60-140",
            genericAlternatives: [
                GenericAlternative(brandName: "S Citadep", manufacturer: "Cipla", priceRange: "₹45-100"),
                GenericAlternative(brandName: "Stalopam", manufacturer: "Lupin", priceRange: "₹40-90")
            ],
            foodInteractions: ["Can be taken with or without food", "Avoid alcohol — worsens depression and sedation"],
            commonSideEffects: ["Nausea", "Headache", "Insomnia", "Drowsiness", "Sexual dysfunction"],
            storageInstructions: "Store below 30°C. Protect from moisture.",
            description: "SSRI antidepressant for depression, anxiety, and panic disorder. Most prescribed SSRI in India.",
            isScheduleH: true
        ))

        db.append(DrugEntry(
            id: "prodep", brandName: "Prodep", genericName: "Fluoxetine",
            saltComposition: "Fluoxetine Hydrochloride 20mg",
            category: .antiDepressant, manufacturer: "Sun Pharmaceutical",
            commonDosages: ["10mg", "20mg", "40mg", "60mg"], typicalDoseForm: "capsule",
            priceRange: "₹30-80",
            genericAlternatives: [
                GenericAlternative(brandName: "Fludac", manufacturer: "Cadila", priceRange: "₹25-65"),
                GenericAlternative(brandName: "Flunil", manufacturer: "Intas", priceRange: "₹20-55")
            ],
            foodInteractions: ["Can be taken with or without food", "Avoid alcohol"],
            commonSideEffects: ["Nausea", "Headache", "Insomnia", "Anxiety (initial)", "Weight loss/gain"],
            storageInstructions: "Store below 30°C. Protect from light.",
            description: "SSRI antidepressant (Prozac). For depression, OCD, bulimia, and panic disorder.",
            isScheduleH: true
        ))

        db.append(DrugEntry(
            id: "venlafaxine", brandName: "Venlor XR", genericName: "Venlafaxine",
            saltComposition: "Venlafaxine 75mg",
            category: .antiDepressant, manufacturer: "Cipla",
            commonDosages: ["37.5mg", "75mg", "150mg"], typicalDoseForm: "capsule",
            priceRange: "₹80-180",
            genericAlternatives: [
                GenericAlternative(brandName: "Veniz XR", manufacturer: "Sun Pharma", priceRange: "₹60-140"),
                GenericAlternative(brandName: "Ventab XL", manufacturer: "Torrent", priceRange: "₹55-130")
            ],
            foodInteractions: ["Take with food", "Avoid alcohol", "Do not stop abruptly — taper gradually"],
            commonSideEffects: ["Nausea", "Headache", "Dizziness", "Insomnia", "Dry mouth"],
            storageInstructions: "Store below 30°C. Protect from moisture.",
            description: "SNRI antidepressant for depression, generalized anxiety, and social anxiety disorder.",
            isScheduleH: true
        ))

        db.append(DrugEntry(
            id: "clonazepam", brandName: "Rivotril", genericName: "Clonazepam",
            saltComposition: "Clonazepam 0.5mg",
            category: .antiDepressant, manufacturer: "Abbott India",
            commonDosages: ["0.25mg", "0.5mg", "1mg", "2mg"], typicalDoseForm: "tablet",
            priceRange: "₹20-50",
            genericAlternatives: [
                GenericAlternative(brandName: "Clonotril", manufacturer: "Torrent", priceRange: "₹15-40"),
                GenericAlternative(brandName: "Zapiz", manufacturer: "Intas", priceRange: "₹12-35")
            ],
            foodInteractions: ["Can be taken with or without food", "Strictly avoid alcohol — respiratory depression risk"],
            commonSideEffects: ["Drowsiness", "Dizziness", "Memory problems", "Fatigue", "Dependence (long-term)"],
            storageInstructions: "Store below 30°C. Protect from light.",
            description: "Benzodiazepine for anxiety, panic disorder, and seizures. High dependence potential.",
            isScheduleH: true
        ))

        // ────────────────────────────────────────────
        // SKIN CARE
        // ────────────────────────────────────────────

        db.append(DrugEntry(
            id: "betnovate", brandName: "Betnovate", genericName: "Betamethasone",
            saltComposition: "Betamethasone Valerate 0.1%",
            category: .skinCare, manufacturer: "GSK Pharmaceuticals",
            commonDosages: ["0.1%"], typicalDoseForm: "cream",
            priceRange: "₹40-80",
            genericAlternatives: [
                GenericAlternative(brandName: "Betaderm", manufacturer: "Glenmark", priceRange: "₹30-60"),
                GenericAlternative(brandName: "Beta-C", manufacturer: "Cipla", priceRange: "₹25-50")
            ],
            foodInteractions: ["Topical — no food interactions"],
            commonSideEffects: ["Skin thinning", "Stretch marks (prolonged use)", "Burning sensation", "Itching", "Acne"],
            storageInstructions: "Store below 30°C. Do not freeze.",
            description: "Topical corticosteroid for eczema, dermatitis, psoriasis, and allergic skin conditions.",
            isScheduleH: true
        ))

        db.append(DrugEntry(
            id: "clobetasol", brandName: "Tenovate", genericName: "Clobetasol",
            saltComposition: "Clobetasol Propionate 0.05%",
            category: .skinCare, manufacturer: "GSK Pharmaceuticals",
            commonDosages: ["0.05%"], typicalDoseForm: "cream",
            priceRange: "₹50-100",
            genericAlternatives: [
                GenericAlternative(brandName: "Clobeta", manufacturer: "Cipla", priceRange: "₹35-70"),
                GenericAlternative(brandName: "Dermovate", manufacturer: "GSK", priceRange: "₹60-120")
            ],
            foodInteractions: ["Topical — no food interactions"],
            commonSideEffects: ["Skin thinning", "Burning", "Stretch marks", "Folliculitis", "Skin atrophy"],
            storageInstructions: "Store below 30°C. Do not freeze.",
            description: "Super-potent topical steroid for severe eczema, psoriasis, and dermatitis. Use short-term only.",
            isScheduleH: true
        ))

        db.append(DrugEntry(
            id: "t-bact", brandName: "T-Bact", genericName: "Mupirocin",
            saltComposition: "Mupirocin 2%",
            category: .skinCare, manufacturer: "GSK Pharmaceuticals",
            commonDosages: ["2%"], typicalDoseForm: "cream",
            priceRange: "₹100-180",
            genericAlternatives: [
                GenericAlternative(brandName: "Mupiderm", manufacturer: "Glenmark", priceRange: "₹80-140"),
                GenericAlternative(brandName: "Mupiban", manufacturer: "Cipla", priceRange: "₹70-120")
            ],
            foodInteractions: ["Topical — no food interactions"],
            commonSideEffects: ["Burning at application site", "Itching", "Redness", "Dry skin"],
            storageInstructions: "Store below 25°C. Do not freeze.",
            description: "Topical antibiotic for impetigo, infected wounds, and skin infections (including MRSA).",
            isScheduleH: true
        ))

        db.append(DrugEntry(
            id: "candid-b", brandName: "Candid-B", genericName: "Clotrimazole + Beclomethasone",
            saltComposition: "Clotrimazole 1% + Beclomethasone 0.025%",
            category: .skinCare, manufacturer: "Glenmark",
            commonDosages: ["Standard"], typicalDoseForm: "cream",
            priceRange: "₹60-100",
            genericAlternatives: [
                GenericAlternative(brandName: "Canesten", manufacturer: "Bayer", priceRange: "₹80-130"),
                GenericAlternative(brandName: "Ring Guard", manufacturer: "Various", priceRange: "₹40-70")
            ],
            foodInteractions: ["Topical — no food interactions"],
            commonSideEffects: ["Skin irritation", "Burning", "Redness", "Itching"],
            storageInstructions: "Store below 30°C.",
            description: "Antifungal + steroid cream for fungal infections with inflammation (ringworm, jock itch).",
            isScheduleH: true
        ))

        // ────────────────────────────────────────────
        // ANTI-INFECTIVE
        // ────────────────────────────────────────────

        db.append(DrugEntry(
            id: "fluconazole", brandName: "Zocon", genericName: "Fluconazole",
            saltComposition: "Fluconazole 150mg",
            category: .antiInfective, manufacturer: "Sun Pharma",
            commonDosages: ["50mg", "150mg", "200mg"], typicalDoseForm: "tablet",
            priceRange: "₹30-80",
            genericAlternatives: [
                GenericAlternative(brandName: "Forcan", manufacturer: "Cipla", priceRange: "₹25-65"),
                GenericAlternative(brandName: "Flucos", manufacturer: "Intas", priceRange: "₹20-55")
            ],
            foodInteractions: ["Can be taken with or without food"],
            commonSideEffects: ["Headache", "Nausea", "Abdominal pain", "Diarrhoea", "Rash"],
            storageInstructions: "Store below 30°C. Protect from moisture.",
            description: "Antifungal for vaginal candidiasis, oral thrush, and systemic fungal infections.",
            isScheduleH: true
        ))

        db.append(DrugEntry(
            id: "albendazole", brandName: "Zentel", genericName: "Albendazole",
            saltComposition: "Albendazole 400mg",
            category: .antiInfective, manufacturer: "GSK",
            commonDosages: ["200mg", "400mg"], typicalDoseForm: "tablet",
            priceRange: "₹8-20",
            genericAlternatives: [
                GenericAlternative(brandName: "Bandy", manufacturer: "Mankind", priceRange: "₹5-15"),
                GenericAlternative(brandName: "Noworm", manufacturer: "Cipla", priceRange: "₹6-18")
            ],
            foodInteractions: ["Take with fatty food for better absorption"],
            commonSideEffects: ["Nausea", "Abdominal pain", "Headache", "Dizziness", "Elevated liver enzymes (rare)"],
            storageInstructions: "Store below 30°C.",
            description: "Deworming tablet for roundworm, hookworm, tapeworm, and other parasitic infections.",
            isScheduleH: false
        ))

        db.append(DrugEntry(
            id: "acyclovir", brandName: "Zovirax", genericName: "Acyclovir",
            saltComposition: "Acyclovir 400mg",
            category: .antiInfective, manufacturer: "GSK",
            commonDosages: ["200mg", "400mg", "800mg"], typicalDoseForm: "tablet",
            priceRange: "₹40-100",
            genericAlternatives: [
                GenericAlternative(brandName: "Acivir", manufacturer: "Cipla", priceRange: "₹30-80"),
                GenericAlternative(brandName: "Herpex", manufacturer: "Torrent", priceRange: "₹25-70")
            ],
            foodInteractions: ["Can be taken with or without food", "Drink plenty of water"],
            commonSideEffects: ["Nausea", "Headache", "Diarrhoea", "Dizziness", "Fatigue"],
            storageInstructions: "Store below 25°C. Protect from moisture and light.",
            description: "Antiviral for herpes simplex (cold sores, genital herpes), chickenpox, and shingles.",
            isScheduleH: true
        ))

        // ────────────────────────────────────────────
        // OTHER COMMON MEDICINES
        // ────────────────────────────────────────────

        db.append(DrugEntry(
            id: "ondansetron", brandName: "Emeset", genericName: "Ondansetron",
            saltComposition: "Ondansetron 4mg",
            category: .other, manufacturer: "Cipla",
            commonDosages: ["4mg", "8mg"], typicalDoseForm: "tablet",
            priceRange: "₹30-70",
            genericAlternatives: [
                GenericAlternative(brandName: "Ondem", manufacturer: "Alkem", priceRange: "₹25-55"),
                GenericAlternative(brandName: "Vomikind", manufacturer: "Mankind", priceRange: "₹20-45")
            ],
            foodInteractions: ["Can be taken with or without food"],
            commonSideEffects: ["Headache", "Constipation", "Fatigue", "Dizziness"],
            storageInstructions: "Store below 30°C. Protect from light.",
            description: "Anti-nausea medication for chemotherapy, surgery, and severe vomiting.",
            isScheduleH: true
        ))

        db.append(DrugEntry(
            id: "sildenafil", brandName: "Manforce", genericName: "Sildenafil",
            saltComposition: "Sildenafil Citrate 50mg",
            category: .other, manufacturer: "Mankind",
            commonDosages: ["25mg", "50mg", "100mg"], typicalDoseForm: "tablet",
            priceRange: "₹60-200",
            genericAlternatives: [
                GenericAlternative(brandName: "Penegra", manufacturer: "Zydus", priceRange: "₹100-250"),
                GenericAlternative(brandName: "Vigora", manufacturer: "German Remedies", priceRange: "₹80-180")
            ],
            foodInteractions: ["Avoid high-fat meals — delays absorption", "Avoid grapefruit juice", "Do NOT combine with nitrates"],
            commonSideEffects: ["Headache", "Flushing", "Dyspepsia", "Visual disturbance", "Nasal congestion"],
            storageInstructions: "Store below 30°C. Protect from moisture.",
            description: "PDE5 inhibitor for erectile dysfunction. Also used for pulmonary arterial hypertension.",
            isScheduleH: true
        ))

        db.append(DrugEntry(
            id: "metoclopramide", brandName: "Perinorm", genericName: "Metoclopramide",
            saltComposition: "Metoclopramide 10mg",
            category: .other, manufacturer: "Ipca",
            commonDosages: ["5mg", "10mg"], typicalDoseForm: "tablet",
            priceRange: "₹10-25",
            genericAlternatives: [
                GenericAlternative(brandName: "Reglan", manufacturer: "Various", priceRange: "₹8-20"),
                GenericAlternative(brandName: "Metacin", manufacturer: "Sun Pharma", priceRange: "₹8-18")
            ],
            foodInteractions: ["Take 30 minutes before meals"],
            commonSideEffects: ["Drowsiness", "Restlessness", "Fatigue", "Diarrhoea", "Tardive dyskinesia (prolonged use)"],
            storageInstructions: "Store below 30°C. Protect from light.",
            description: "Anti-emetic and prokinetic for nausea, vomiting, and gastroparesis.",
            isScheduleH: true
        ))

        db.append(DrugEntry(
            id: "pregabalin", brandName: "Pregabalin", genericName: "Pregabalin",
            saltComposition: "Pregabalin 75mg",
            category: .other, manufacturer: "Various",
            commonDosages: ["50mg", "75mg", "150mg", "300mg"], typicalDoseForm: "capsule",
            priceRange: "₹60-150",
            genericAlternatives: [
                GenericAlternative(brandName: "Lyrica", manufacturer: "Pfizer", priceRange: "₹200-400"),
                GenericAlternative(brandName: "Pregalin", manufacturer: "Torrent", priceRange: "₹50-120")
            ],
            foodInteractions: ["Can be taken with or without food", "Avoid alcohol — increased sedation"],
            commonSideEffects: ["Dizziness", "Drowsiness", "Weight gain", "Dry mouth", "Blurred vision"],
            storageInstructions: "Store below 30°C. Protect from moisture.",
            description: "For neuropathic pain, fibromyalgia, and epilepsy. Controlled substance.",
            isScheduleH: true
        ))

        db.append(DrugEntry(
            id: "gabapentin", brandName: "Gabapin", genericName: "Gabapentin",
            saltComposition: "Gabapentin 300mg",
            category: .other, manufacturer: "Intas",
            commonDosages: ["100mg", "300mg", "400mg", "600mg", "800mg"], typicalDoseForm: "capsule",
            priceRange: "₹50-120",
            genericAlternatives: [
                GenericAlternative(brandName: "Neurontin", manufacturer: "Pfizer", priceRange: "₹150-300"),
                GenericAlternative(brandName: "Gabantin", manufacturer: "Sun Pharma", priceRange: "₹40-100")
            ],
            foodInteractions: ["Can be taken with or without food", "Avoid antacids within 2 hours"],
            commonSideEffects: ["Drowsiness", "Dizziness", "Fatigue", "Ataxia", "Peripheral oedema"],
            storageInstructions: "Store below 30°C.",
            description: "Anticonvulsant for neuropathic pain, seizures, and restless leg syndrome.",
            isScheduleH: true
        ))

        db.append(DrugEntry(
            id: "tadalafil", brandName: "Megalis", genericName: "Tadalafil",
            saltComposition: "Tadalafil 10mg",
            category: .other, manufacturer: "Macleods",
            commonDosages: ["5mg", "10mg", "20mg"], typicalDoseForm: "tablet",
            priceRange: "₹80-250",
            genericAlternatives: [
                GenericAlternative(brandName: "Cialis", manufacturer: "Eli Lilly", priceRange: "₹300-600"),
                GenericAlternative(brandName: "Tadacip", manufacturer: "Cipla", priceRange: "₹70-200")
            ],
            foodInteractions: ["Can be taken with or without food", "Avoid grapefruit juice", "Do NOT combine with nitrates"],
            commonSideEffects: ["Headache", "Back pain", "Myalgia", "Nasal congestion", "Flushing"],
            storageInstructions: "Store below 30°C. Protect from moisture.",
            description: "PDE5 inhibitor for ED and benign prostatic hyperplasia. Longer-acting than sildenafil.",
            isScheduleH: true
        ))

        db.append(DrugEntry(
            id: "tamsulosin", brandName: "Urimax", genericName: "Tamsulosin",
            saltComposition: "Tamsulosin Hydrochloride 0.4mg",
            category: .other, manufacturer: "Cipla",
            commonDosages: ["0.2mg", "0.4mg"], typicalDoseForm: "capsule",
            priceRange: "₹60-130",
            genericAlternatives: [
                GenericAlternative(brandName: "Contiflo", manufacturer: "Sun Pharma", priceRange: "₹50-100"),
                GenericAlternative(brandName: "Flomax", manufacturer: "Boehringer", priceRange: "₹120-200")
            ],
            foodInteractions: ["Take 30 minutes after the same meal each day"],
            commonSideEffects: ["Dizziness", "Retrograde ejaculation", "Runny nose", "Headache", "Orthostatic hypotension"],
            storageInstructions: "Store below 30°C. Protect from moisture and light.",
            description: "Alpha-blocker for benign prostatic hyperplasia (BPH) and urinary retention.",
            isScheduleH: true
        ))

        db.append(DrugEntry(
            id: "hydroxychloroquine", brandName: "HCQS", genericName: "Hydroxychloroquine",
            saltComposition: "Hydroxychloroquine Sulfate 200mg",
            category: .other, manufacturer: "Ipca",
            commonDosages: ["200mg", "300mg", "400mg"], typicalDoseForm: "tablet",
            priceRange: "₹40-100",
            genericAlternatives: [
                GenericAlternative(brandName: "Plaquenil", manufacturer: "Sanofi", priceRange: "₹80-160"),
                GenericAlternative(brandName: "HCQ", manufacturer: "Cipla", priceRange: "₹35-80")
            ],
            foodInteractions: ["Take with food or milk to reduce stomach upset"],
            commonSideEffects: ["Nausea", "Stomach cramps", "Headache", "Dizziness", "Retinal toxicity (long-term)"],
            storageInstructions: "Store below 30°C. Protect from light.",
            description: "Disease-modifying drug for rheumatoid arthritis, lupus (SLE), and malaria prophylaxis.",
            isScheduleH: true
        ))

        db.append(DrugEntry(
            id: "methotrexate", brandName: "Folitrax", genericName: "Methotrexate",
            saltComposition: "Methotrexate 10mg",
            category: .other, manufacturer: "Ipca",
            commonDosages: ["2.5mg", "5mg", "7.5mg", "10mg", "15mg"], typicalDoseForm: "tablet",
            priceRange: "₹30-80",
            genericAlternatives: [
                GenericAlternative(brandName: "Imutrex", manufacturer: "Cipla", priceRange: "₹25-65"),
                GenericAlternative(brandName: "Mexate", manufacturer: "Zydus", priceRange: "₹20-55")
            ],
            foodInteractions: ["Take on empty stomach with water", "Avoid alcohol strictly", "Take folic acid supplements as directed"],
            commonSideEffects: ["Nausea", "Fatigue", "Mouth sores", "Liver toxicity", "Low blood counts"],
            storageInstructions: "Store below 25°C. Protect from light.",
            description: "Immunosuppressant for rheumatoid arthritis, psoriasis, and some cancers. Weekly dosing.",
            isScheduleH: true
        ))

        db.append(DrugEntry(
            id: "prednisolone", brandName: "Wysolone", genericName: "Prednisolone",
            saltComposition: "Prednisolone 10mg",
            category: .other, manufacturer: "Pfizer",
            commonDosages: ["5mg", "10mg", "20mg", "40mg"], typicalDoseForm: "tablet",
            priceRange: "₹15-40",
            genericAlternatives: [
                GenericAlternative(brandName: "Omnacortil", manufacturer: "Macleods", priceRange: "₹10-30"),
                GenericAlternative(brandName: "Hostacortin", manufacturer: "Sanofi", priceRange: "₹12-35")
            ],
            foodInteractions: ["Take with food to reduce stomach irritation", "Avoid alcohol"],
            commonSideEffects: ["Weight gain", "Mood changes", "Increased appetite", "Insomnia", "Elevated blood sugar"],
            storageInstructions: "Store below 30°C. Protect from moisture.",
            description: "Corticosteroid for inflammation, allergies, asthma, and autoimmune conditions.",
            isScheduleH: true
        ))

        db.append(DrugEntry(
            id: "insulin-glargine", brandName: "Lantus", genericName: "Insulin Glargine",
            saltComposition: "Insulin Glargine 100 IU/ml",
            category: .antidiabetic, manufacturer: "Sanofi",
            commonDosages: ["100 IU/ml"], typicalDoseForm: "injection",
            priceRange: "₹800-1500",
            genericAlternatives: [
                GenericAlternative(brandName: "Basalog", manufacturer: "Biocon", priceRange: "₹600-1000"),
                GenericAlternative(brandName: "Glaritus", manufacturer: "Wockhardt", priceRange: "₹550-950")
            ],
            foodInteractions: ["Inject at the same time daily", "Monitor carbohydrate intake", "Avoid alcohol — hypoglycemia risk"],
            commonSideEffects: ["Hypoglycemia", "Weight gain", "Injection site reactions", "Lipodystrophy", "Oedema"],
            storageInstructions: "Store unopened in fridge (2-8°C). In-use pen at room temperature for up to 28 days.",
            description: "Long-acting basal insulin for Type 1 and Type 2 diabetes.",
            isScheduleH: true
        ))

        db.append(DrugEntry(
            id: "glipizide", brandName: "Glynase", genericName: "Glipizide",
            saltComposition: "Glipizide 5mg",
            category: .antidiabetic, manufacturer: "USV",
            commonDosages: ["2.5mg", "5mg", "10mg"], typicalDoseForm: "tablet",
            priceRange: "₹15-40",
            genericAlternatives: [
                GenericAlternative(brandName: "Glucotrol", manufacturer: "Pfizer", priceRange: "₹25-60"),
                GenericAlternative(brandName: "Glide", manufacturer: "Various", priceRange: "₹12-30")
            ],
            foodInteractions: ["Take 30 minutes before meals", "Do not skip meals"],
            commonSideEffects: ["Hypoglycemia", "Weight gain", "Nausea", "Dizziness", "Headache"],
            storageInstructions: "Store below 30°C.",
            description: "Sulfonylurea for Type 2 diabetes. Stimulates insulin secretion.",
            isScheduleH: true
        ))

        db.append(DrugEntry(
            id: "pioglitazone", brandName: "Pioz", genericName: "Pioglitazone",
            saltComposition: "Pioglitazone 15mg",
            category: .antidiabetic, manufacturer: "USV",
            commonDosages: ["15mg", "30mg", "45mg"], typicalDoseForm: "tablet",
            priceRange: "₹40-100",
            genericAlternatives: [
                GenericAlternative(brandName: "Piozone", manufacturer: "Sun Pharma", priceRange: "₹30-80"),
                GenericAlternative(brandName: "Pioglar", manufacturer: "Glenmark", priceRange: "₹25-70")
            ],
            foodInteractions: ["Can be taken with or without food"],
            commonSideEffects: ["Weight gain", "Oedema", "Fractures", "Headache", "Upper respiratory infection"],
            storageInstructions: "Store below 30°C.",
            description: "Thiazolidinedione (insulin sensitizer) for Type 2 diabetes.",
            isScheduleH: true
        ))

        db.append(DrugEntry(
            id: "empagliflozin", brandName: "Jardiance", genericName: "Empagliflozin",
            saltComposition: "Empagliflozin 10mg",
            category: .antidiabetic, manufacturer: "Boehringer Ingelheim",
            commonDosages: ["10mg", "25mg"], typicalDoseForm: "tablet",
            priceRange: "₹400-600",
            genericAlternatives: [
                GenericAlternative(brandName: "Gibtulio", manufacturer: "Sun Pharma", priceRange: "₹250-400"),
                GenericAlternative(brandName: "Empaone", manufacturer: "Mankind", priceRange: "₹200-350")
            ],
            foodInteractions: ["Can be taken with or without food", "Increase water intake"],
            commonSideEffects: ["Urinary tract infection", "Genital fungal infection", "Frequent urination", "Dehydration", "Hypotension"],
            storageInstructions: "Store below 30°C. Protect from moisture.",
            description: "SGLT2 inhibitor for Type 2 diabetes with cardiovascular and kidney benefits.",
            isScheduleH: true
        ))

        db.append(DrugEntry(
            id: "dapagliflozin", brandName: "Forxiga", genericName: "Dapagliflozin",
            saltComposition: "Dapagliflozin 10mg",
            category: .antidiabetic, manufacturer: "AstraZeneca",
            commonDosages: ["5mg", "10mg"], typicalDoseForm: "tablet",
            priceRange: "₹350-550",
            genericAlternatives: [
                GenericAlternative(brandName: "Dapavel", manufacturer: "Sun Pharma", priceRange: "₹200-350"),
                GenericAlternative(brandName: "Oxra", manufacturer: "Intas", priceRange: "₹180-300")
            ],
            foodInteractions: ["Can be taken with or without food", "Increase water intake"],
            commonSideEffects: ["Genital infections", "Urinary tract infection", "Frequent urination", "Back pain", "Nausea"],
            storageInstructions: "Store below 30°C.",
            description: "SGLT2 inhibitor for diabetes, heart failure, and chronic kidney disease.",
            isScheduleH: true
        ))

        db.append(DrugEntry(
            id: "nitroglycerin", brandName: "Sorbitrate", genericName: "Isosorbide Dinitrate",
            saltComposition: "Isosorbide Dinitrate 5mg",
            category: .cardiovascular, manufacturer: "Sun Pharma",
            commonDosages: ["5mg", "10mg"], typicalDoseForm: "tablet",
            priceRange: "₹10-30",
            genericAlternatives: [
                GenericAlternative(brandName: "Isoket", manufacturer: "Samarth", priceRange: "₹15-35"),
                GenericAlternative(brandName: "Angised", manufacturer: "GSK", priceRange: "₹8-20")
            ],
            foodInteractions: ["Place sublingual tablet under tongue", "Avoid alcohol — severe hypotension"],
            commonSideEffects: ["Headache", "Dizziness", "Flushing", "Hypotension", "Nausea"],
            storageInstructions: "Store below 25°C. Protect from light. Keep in original container.",
            description: "Nitrate vasodilator for angina (chest pain) relief and prevention.",
            isScheduleH: true
        ))

        db.append(DrugEntry(
            id: "digoxin", brandName: "Lanoxin", genericName: "Digoxin",
            saltComposition: "Digoxin 0.25mg",
            category: .cardiovascular, manufacturer: "Abbott (GSK legacy)",
            commonDosages: ["0.125mg", "0.25mg"], typicalDoseForm: "tablet",
            priceRange: "₹10-25",
            genericAlternatives: [
                GenericAlternative(brandName: "Digox", manufacturer: "Cipla", priceRange: "₹8-20"),
                GenericAlternative(brandName: "Cardioxin", manufacturer: "Various", priceRange: "₹7-18")
            ],
            foodInteractions: ["Take on empty stomach or consistently with food", "High-fibre meals may reduce absorption"],
            commonSideEffects: ["Nausea", "Visual disturbances", "Arrhythmias (toxicity)", "Dizziness", "Fatigue"],
            storageInstructions: "Store below 25°C. Protect from light.",
            description: "Cardiac glycoside for atrial fibrillation and heart failure. Narrow therapeutic index.",
            isScheduleH: true
        ))

        db.append(DrugEntry(
            id: "furosemide", brandName: "Lasix", genericName: "Furosemide",
            saltComposition: "Furosemide 40mg",
            category: .cardiovascular, manufacturer: "Sanofi",
            commonDosages: ["20mg", "40mg", "80mg"], typicalDoseForm: "tablet",
            priceRange: "₹8-20",
            genericAlternatives: [
                GenericAlternative(brandName: "Fruselac", manufacturer: "Micro Labs", priceRange: "₹5-15"),
                GenericAlternative(brandName: "Frusemide", manufacturer: "Various", priceRange: "₹4-12")
            ],
            foodInteractions: ["Take in the morning to avoid nighttime urination", "Eat potassium-rich foods (bananas, oranges)"],
            commonSideEffects: ["Frequent urination", "Dehydration", "Low potassium", "Dizziness", "Muscle cramps"],
            storageInstructions: "Store below 30°C. Protect from light.",
            description: "Loop diuretic for oedema in heart failure, liver cirrhosis, and kidney disease.",
            isScheduleH: true
        ))

        db.append(DrugEntry(
            id: "spironolactone", brandName: "Aldactone", genericName: "Spironolactone",
            saltComposition: "Spironolactone 25mg",
            category: .cardiovascular, manufacturer: "RPG Life Sciences",
            commonDosages: ["25mg", "50mg", "100mg"], typicalDoseForm: "tablet",
            priceRange: "₹30-80",
            genericAlternatives: [
                GenericAlternative(brandName: "Spiromide", manufacturer: "Cipla", priceRange: "₹20-60"),
                GenericAlternative(brandName: "Spiro", manufacturer: "Various", priceRange: "₹15-50")
            ],
            foodInteractions: ["Take with food for better absorption", "Avoid potassium-rich foods and salt substitutes"],
            commonSideEffects: ["Hyperkalemia", "Gynecomastia", "Dizziness", "Nausea", "Menstrual irregularities"],
            storageInstructions: "Store below 25°C. Protect from light.",
            description: "Potassium-sparing diuretic for heart failure, ascites, and hypertension.",
            isScheduleH: true
        ))

        db.append(DrugEntry(
            id: "enalapril", brandName: "Envas", genericName: "Enalapril",
            saltComposition: "Enalapril Maleate 5mg",
            category: .antihypertensive, manufacturer: "Cadila Healthcare",
            commonDosages: ["2.5mg", "5mg", "10mg", "20mg"], typicalDoseForm: "tablet",
            priceRange: "₹20-60",
            genericAlternatives: [
                GenericAlternative(brandName: "Enapril", manufacturer: "Cipla", priceRange: "₹15-45"),
                GenericAlternative(brandName: "Vasotec", manufacturer: "Various", priceRange: "₹25-50")
            ],
            foodInteractions: ["Can be taken with or without food", "Avoid potassium supplements"],
            commonSideEffects: ["Dry cough", "Dizziness", "Headache", "Fatigue", "Hyperkalemia"],
            storageInstructions: "Store below 30°C. Protect from moisture.",
            description: "ACE inhibitor for hypertension and heart failure.",
            isScheduleH: true
        ))

        db.append(DrugEntry(
            id: "nifedipine", brandName: "Adalat", genericName: "Nifedipine",
            saltComposition: "Nifedipine 10mg",
            category: .antihypertensive, manufacturer: "Bayer",
            commonDosages: ["5mg", "10mg", "20mg", "30mg Retard"], typicalDoseForm: "tablet",
            priceRange: "₹20-60",
            genericAlternatives: [
                GenericAlternative(brandName: "Depin", manufacturer: "Zydus", priceRange: "₹15-45"),
                GenericAlternative(brandName: "Calcigard", manufacturer: "Torrent", priceRange: "₹12-40")
            ],
            foodInteractions: ["Avoid grapefruit juice", "Can be taken with or without food"],
            commonSideEffects: ["Headache", "Flushing", "Ankle oedema", "Dizziness", "Palpitations"],
            storageInstructions: "Store below 25°C. Protect from light.",
            description: "Calcium channel blocker for hypertension and angina.",
            isScheduleH: true
        ))

        db.append(DrugEntry(
            id: "diltiazem", brandName: "Dilzem", genericName: "Diltiazem",
            saltComposition: "Diltiazem 30mg",
            category: .antihypertensive, manufacturer: "Torrent",
            commonDosages: ["30mg", "60mg", "90mg", "120mg"], typicalDoseForm: "tablet",
            priceRange: "₹30-80",
            genericAlternatives: [
                GenericAlternative(brandName: "Herbesser", manufacturer: "Sanofi", priceRange: "₹40-100"),
                GenericAlternative(brandName: "DTM", manufacturer: "Cipla", priceRange: "₹25-60")
            ],
            foodInteractions: ["Avoid grapefruit juice", "Take with food"],
            commonSideEffects: ["Headache", "Dizziness", "Bradycardia", "Ankle oedema", "Nausea"],
            storageInstructions: "Store below 30°C. Protect from light and moisture.",
            description: "Calcium channel blocker for hypertension, angina, and atrial fibrillation.",
            isScheduleH: true
        ))

        db.append(DrugEntry(
            id: "ofloxacin", brandName: "Oflox", genericName: "Ofloxacin",
            saltComposition: "Ofloxacin 200mg",
            category: .antibiotic, manufacturer: "Cipla",
            commonDosages: ["200mg", "400mg"], typicalDoseForm: "tablet",
            priceRange: "₹30-70",
            genericAlternatives: [
                GenericAlternative(brandName: "Zanocin", manufacturer: "Sun Pharma", priceRange: "₹25-60"),
                GenericAlternative(brandName: "Ofx", manufacturer: "Various", priceRange: "₹20-50")
            ],
            foodInteractions: ["Avoid dairy and antacids within 2 hours", "Take with plenty of water"],
            commonSideEffects: ["Nausea", "Diarrhoea", "Headache", "Dizziness", "Insomnia"],
            storageInstructions: "Store below 30°C. Protect from light.",
            description: "Fluoroquinolone antibiotic for UTI, respiratory, and GI infections.",
            isScheduleH: true
        ))

        db.append(DrugEntry(
            id: "nitrofurantoin", brandName: "Nicardia", genericName: "Nitrofurantoin",
            saltComposition: "Nitrofurantoin 100mg",
            category: .antibiotic, manufacturer: "J.B. Chemicals",
            commonDosages: ["50mg", "100mg"], typicalDoseForm: "capsule",
            priceRange: "₹30-70",
            genericAlternatives: [
                GenericAlternative(brandName: "Furadantin", manufacturer: "Sun Pharma", priceRange: "₹25-55"),
                GenericAlternative(brandName: "Urifast", manufacturer: "Mankind", priceRange: "₹20-45")
            ],
            foodInteractions: ["Take with food for better absorption and less nausea"],
            commonSideEffects: ["Nausea", "Headache", "Brown urine", "Diarrhoea", "Lung toxicity (rare, prolonged use)"],
            storageInstructions: "Store below 30°C. Protect from light.",
            description: "Antibiotic specifically for urinary tract infections.",
            isScheduleH: true
        ))

        db.append(DrugEntry(
            id: "orlistat", brandName: "Obelit", genericName: "Orlistat",
            saltComposition: "Orlistat 120mg",
            category: .other, manufacturer: "Intas",
            commonDosages: ["60mg", "120mg"], typicalDoseForm: "capsule",
            priceRange: "₹200-400",
            genericAlternatives: [
                GenericAlternative(brandName: "Xenical", manufacturer: "Roche", priceRange: "₹400-700"),
                GenericAlternative(brandName: "Slim Trim", manufacturer: "Mankind", priceRange: "₹150-300")
            ],
            foodInteractions: ["Take with each main meal containing fat", "Take multivitamin at bedtime separately"],
            commonSideEffects: ["Oily stool", "Flatulence", "Fecal urgency", "Abdominal pain", "Fat-soluble vitamin deficiency"],
            storageInstructions: "Store below 30°C.",
            description: "Lipase inhibitor for obesity management. Blocks fat absorption by 30%.",
            isScheduleH: true
        ))

        return db
    }
}
