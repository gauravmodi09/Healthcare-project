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

    // MARK: - Generic Equivalents

    /// Find all brand equivalents for a given brand name (same generic/salt composition)
    func findGenericEquivalents(for brandName: String) -> [DrugEntry] {
        let q = brandName.lowercased()
        guard let entry = medicines.first(where: { $0.brandName.lowercased() == q }) else {
            return []
        }
        let generic = entry.genericName.lowercased()
        let salt = entry.saltComposition.lowercased()
        return medicines.filter {
            $0.id != entry.id &&
            ($0.genericName.lowercased() == generic || $0.saltComposition.lowercased() == salt)
        }
    }

    // MARK: - Indian Food-Drug Interactions Database

    struct FoodDrugInteraction {
        let foodItem: String
        let affectedDrugs: [String]
        let interactionType: String // "avoid", "caution", "timing"
        let description: String
        let severity: String // "high", "moderate", "low"
    }

    static let indianFoodDrugInteractions: [FoodDrugInteraction] = [
        FoodDrugInteraction(
            foodItem: "Grapefruit / Grapefruit juice",
            affectedDrugs: ["Atorvastatin", "Rosuvastatin", "Simvastatin", "Amlodipine", "Nifedipine", "Felodipine", "Cyclosporine", "Sildenafil", "Tadalafil", "Ticagrelor"],
            interactionType: "avoid",
            description: "Grapefruit inhibits CYP3A4 enzyme, dramatically increasing drug levels in blood. Can cause severe muscle pain (statins), dangerously low BP (calcium channel blockers), or toxicity.",
            severity: "high"
        ),
        FoodDrugInteraction(
            foodItem: "Milk / Dahi (Curd) / Paneer / Calcium-rich foods",
            affectedDrugs: ["Ciprofloxacin", "Levofloxacin", "Ofloxacin", "Tetracycline", "Doxycycline", "Levothyroxine", "Iron supplements", "Alendronate"],
            interactionType: "timing",
            description: "Calcium binds to these medicines forming insoluble complexes, reducing absorption by 50-90%. Take medicine 2 hours before or 4 hours after dairy products. Especially important for thyroid patients taking Thyronorm/Eltroxin.",
            severity: "high"
        ),
        FoodDrugInteraction(
            foodItem: "Palak (Spinach) / Methi (Fenugreek) / Green leafy vegetables",
            affectedDrugs: ["Warfarin", "Acenocoumarol (Acitrom)"],
            interactionType: "caution",
            description: "Green leafy vegetables are rich in Vitamin K which counteracts blood thinners. Do not stop eating them — maintain CONSISTENT daily intake. Sudden changes in intake can make INR unstable and increase bleeding or clotting risk.",
            severity: "high"
        ),
        FoodDrugInteraction(
            foodItem: "Haldi (Turmeric) / Curcumin supplements",
            affectedDrugs: ["Warfarin", "Acenocoumarol", "Clopidogrel", "Aspirin", "Rivaroxaban", "Apixaban"],
            interactionType: "caution",
            description: "Turmeric has antiplatelet and anticoagulant properties. Normal cooking amounts are generally safe, but concentrated curcumin supplements can increase bleeding risk significantly when combined with blood thinners.",
            severity: "moderate"
        ),
        FoodDrugInteraction(
            foodItem: "Banana / Coconut water / Potassium-rich foods",
            affectedDrugs: ["Ramipril", "Enalapril", "Lisinopril", "Losartan", "Telmisartan", "Spironolactone"],
            interactionType: "caution",
            description: "ACE inhibitors and ARBs reduce potassium excretion. Excessive potassium from bananas, coconut water, oranges, and salt substitutes (sendha namak) can cause dangerously high potassium levels (hyperkalemia), leading to heart rhythm problems.",
            severity: "moderate"
        ),
        FoodDrugInteraction(
            foodItem: "Alcohol (Sharab)",
            affectedDrugs: ["Metformin", "Paracetamol", "Metronidazole", "Tinidazole", "Benzodiazepines", "Warfarin", "Insulin", "Glimepiride"],
            interactionType: "avoid",
            description: "Alcohol + Metformin: risk of fatal lactic acidosis. Alcohol + Paracetamol: severe liver damage. Alcohol + Metronidazole: violent vomiting (disulfiram reaction). Alcohol + diabetes medicines: severe hypoglycemia. Alcohol + blood thinners: increased bleeding.",
            severity: "high"
        ),
        FoodDrugInteraction(
            foodItem: "Chai (Tea) / Coffee",
            affectedDrugs: ["Iron supplements (Autrin, Fefol, Dexorange)", "Levothyroxine", "Ciprofloxacin", "Theophylline"],
            interactionType: "timing",
            description: "Tannins in tea and coffee reduce iron absorption by up to 80%. Take iron supplements 2 hours away from tea/coffee. Caffeine can increase theophylline side effects. Tea/coffee reduce thyroid medicine absorption.",
            severity: "moderate"
        ),
        FoodDrugInteraction(
            foodItem: "Amla (Indian Gooseberry) / Vitamin C supplements",
            affectedDrugs: ["Warfarin", "Acenocoumarol", "Clopidogrel", "Aspirin", "Aluminium-based antacids"],
            interactionType: "caution",
            description: "High-dose Vitamin C (above 1000mg) can reduce warfarin effectiveness and alter INR. Normal dietary amla is usually safe. Vitamin C increases aluminium absorption from antacids — avoid combining.",
            severity: "moderate"
        ),
        FoodDrugInteraction(
            foodItem: "Soy products / Soy milk",
            affectedDrugs: ["Levothyroxine", "Warfarin", "Tamoxifen"],
            interactionType: "timing",
            description: "Soy interferes with thyroid hormone absorption. Take levothyroxine 4 hours away from soy products. Soy isoflavones may reduce effectiveness of tamoxifen.",
            severity: "moderate"
        ),
        FoodDrugInteraction(
            foodItem: "Ajwain (Carom seeds) / Jeera (Cumin) in excess",
            affectedDrugs: ["Antidiabetic medicines", "Blood thinners"],
            interactionType: "caution",
            description: "Large medicinal amounts of ajwain and jeera can lower blood sugar and have mild blood-thinning effects. Normal cooking amounts are safe. Avoid concentrated extracts with diabetes or blood-thinning medicines.",
            severity: "low"
        ),
        FoodDrugInteraction(
            foodItem: "High-fat meals (Ghee, fried foods)",
            affectedDrugs: ["Sildenafil", "Tadalafil", "Orlistat"],
            interactionType: "timing",
            description: "High-fat meals delay absorption of ED medicines by 1-2 hours. With Orlistat, high-fat meals cause oily stool and GI discomfort. Take ED medicines on lighter stomach for faster action.",
            severity: "low"
        ),
        FoodDrugInteraction(
            foodItem: "Karela (Bitter gourd) juice",
            affectedDrugs: ["Metformin", "Glimepiride", "Insulin", "Gliclazide"],
            interactionType: "caution",
            description: "Karela has natural blood sugar lowering properties. Combining with diabetes medicines can cause excessive blood sugar drop (hypoglycemia). Monitor blood sugar closely if consuming regularly.",
            severity: "moderate"
        ),
    ]

    /// Find food-drug interactions for a given medicine
    func findFoodInteractions(forGenericName genericName: String) -> [FoodDrugInteraction] {
        let q = genericName.lowercased()
        return Self.indianFoodDrugInteractions.filter { interaction in
            interaction.affectedDrugs.contains { $0.lowercased().contains(q) || q.contains($0.lowercased()) }
        }
    }

    // MARK: - Jan Aushadhi Price Comparison

    struct JanAushadhiPrice {
        let genericName: String
        let dosage: String
        let brandMRP: Double
        let janAushadhiPrice: Double

        var savingsPercent: Int {
            guard brandMRP > 0 else { return 0 }
            return Int(((brandMRP - janAushadhiPrice) / brandMRP) * 100)
        }

        var savingsAmount: Double {
            brandMRP - janAushadhiPrice
        }
    }

    /// Common Jan Aushadhi generic prices vs typical brand MRPs (per strip/unit)
    private static let janAushadhiPrices: [(generic: String, dosage: String, brandMRP: Double, jaPrice: Double)] = [
        ("Metformin", "500mg", 185, 18),
        ("Metformin", "1000mg", 260, 28),
        ("Atorvastatin", "10mg", 135, 12),
        ("Atorvastatin", "20mg", 155, 17),
        ("Atorvastatin", "40mg", 178, 22),
        ("Pantoprazole", "40mg", 115, 12),
        ("Telmisartan", "40mg", 135, 15),
        ("Telmisartan", "80mg", 195, 22),
        ("Clopidogrel", "75mg", 92, 8),
        ("Amlodipine", "5mg", 85, 8),
        ("Amlodipine", "10mg", 120, 12),
        ("Losartan", "50mg", 105, 10),
        ("Rosuvastatin", "10mg", 165, 18),
        ("Rosuvastatin", "20mg", 210, 25),
        ("Omeprazole", "20mg", 95, 10),
        ("Rabeprazole", "20mg", 130, 14),
        ("Glimepiride", "1mg", 75, 7),
        ("Glimepiride", "2mg", 110, 11),
        ("Ciprofloxacin", "500mg", 98, 12),
        ("Azithromycin", "500mg", 105, 15),
        ("Amoxicillin", "500mg", 85, 10),
        ("Paracetamol", "500mg", 30, 5),
        ("Ibuprofen", "400mg", 45, 6),
        ("Aspirin", "75mg", 35, 4),
        ("Cetirizine", "10mg", 55, 6),
        ("Montelukast", "10mg", 145, 16),
        ("Levothyroxine", "50mcg", 75, 8),
        ("Levothyroxine", "100mcg", 95, 11),
        ("Escitalopram", "10mg", 115, 14),
        ("Dapagliflozin", "10mg", 450, 55),
        ("Sitagliptin", "100mg", 520, 65),
        ("Empagliflozin", "25mg", 480, 58),
        // Expanded Jan Aushadhi prices
        ("Metformin", "850mg", 220, 22),
        ("Glimepiride", "4mg", 150, 15),
        ("Gliclazide", "80mg", 90, 9),
        ("Gliclazide", "40mg", 55, 6),
        ("Vildagliptin", "50mg", 350, 40),
        ("Linagliptin", "5mg", 420, 50),
        ("Teneligliptin", "20mg", 180, 22),
        ("Pioglitazone", "15mg", 65, 7),
        ("Pioglitazone", "30mg", 95, 10),
        ("Dapagliflozin", "5mg", 350, 42),
        ("Empagliflozin", "10mg", 420, 48),
        ("Canagliflozin", "100mg", 380, 45),
        ("Voglibose", "0.2mg", 120, 14),
        ("Voglibose", "0.3mg", 150, 18),
        ("Sitagliptin", "50mg", 380, 45),
        // Cardiac / Hypertension
        ("Amlodipine", "2.5mg", 60, 5),
        ("Telmisartan", "20mg", 85, 10),
        ("Losartan", "25mg", 70, 7),
        ("Losartan", "100mg", 160, 16),
        ("Ramipril", "2.5mg", 55, 6),
        ("Ramipril", "5mg", 80, 8),
        ("Ramipril", "10mg", 110, 12),
        ("Enalapril", "5mg", 35, 4),
        ("Enalapril", "10mg", 50, 5),
        ("Metoprolol", "25mg", 45, 5),
        ("Metoprolol", "50mg", 65, 7),
        ("Metoprolol", "100mg", 95, 10),
        ("Atenolol", "25mg", 22, 3),
        ("Atenolol", "50mg", 35, 4),
        ("Bisoprolol", "2.5mg", 55, 6),
        ("Bisoprolol", "5mg", 85, 9),
        ("Clopidogrel", "75mg", 92, 8),
        ("Aspirin", "150mg", 25, 3),
        ("Aspirin", "325mg", 15, 2),
        ("Atorvastatin", "80mg", 220, 28),
        ("Rosuvastatin", "5mg", 120, 12),
        ("Rosuvastatin", "40mg", 280, 32),
        ("Isosorbide Mononitrate", "10mg", 30, 3),
        ("Isosorbide Mononitrate", "20mg", 45, 5),
        ("Nitroglycerin", "2.6mg", 35, 4),
        ("Diltiazem", "30mg", 35, 4),
        ("Diltiazem", "60mg", 55, 6),
        ("Verapamil", "40mg", 25, 3),
        ("Verapamil", "80mg", 40, 4),
        ("Furosemide", "40mg", 12, 2),
        ("Spironolactone", "25mg", 40, 4),
        ("Spironolactone", "50mg", 65, 7),
        ("Hydrochlorothiazide", "12.5mg", 15, 2),
        ("Hydrochlorothiazide", "25mg", 22, 3),
        ("Digoxin", "0.25mg", 18, 2),
        ("Warfarin", "2mg", 22, 3),
        ("Warfarin", "5mg", 28, 3),
        ("Rivaroxaban", "10mg", 280, 35),
        ("Rivaroxaban", "15mg", 350, 42),
        ("Rivaroxaban", "20mg", 400, 48),
        ("Prasugrel", "10mg", 220, 25),
        ("Ticagrelor", "90mg", 350, 40),
        // Antibiotics
        ("Amoxicillin", "250mg", 55, 6),
        ("Cefixime", "200mg", 110, 12),
        ("Cephalexin", "500mg", 85, 9),
        ("Ciprofloxacin", "250mg", 55, 6),
        ("Levofloxacin", "500mg", 80, 9),
        ("Levofloxacin", "250mg", 50, 6),
        ("Ofloxacin", "200mg", 40, 5),
        ("Ofloxacin", "400mg", 65, 7),
        ("Doxycycline", "100mg", 55, 6),
        ("Metronidazole", "400mg", 22, 3),
        ("Nitrofurantoin", "100mg", 45, 5),
        ("Clindamycin", "300mg", 120, 14),
        ("Cotrimoxazole", "480mg", 18, 2),
        ("Linezolid", "600mg", 280, 32),
        ("Azithromycin", "250mg", 65, 8),
        ("Meropenem", "1g", 450, 55),
        // GI / Acid
        ("Pantoprazole", "20mg", 70, 8),
        ("Omeprazole", "40mg", 120, 14),
        ("Esomeprazole", "20mg", 95, 10),
        ("Esomeprazole", "40mg", 140, 16),
        ("Domperidone", "10mg", 30, 3),
        ("Ondansetron", "4mg", 35, 4),
        ("Ondansetron", "8mg", 55, 6),
        ("Ranitidine", "150mg", 30, 3),
        ("Ranitidine", "300mg", 50, 5),
        ("Sucralfate", "1g", 65, 7),
        ("Loperamide", "2mg", 25, 3),
        ("Bisacodyl", "5mg", 15, 2),
        ("Lactulose", "10ml", 85, 10),
        // Pain / Anti-inflammatory
        ("Paracetamol", "650mg", 35, 6),
        ("Ibuprofen", "200mg", 25, 3),
        ("Diclofenac", "50mg", 28, 3),
        ("Aceclofenac", "100mg", 55, 6),
        ("Naproxen", "250mg", 40, 4),
        ("Naproxen", "500mg", 65, 7),
        ("Tramadol", "50mg", 35, 4),
        ("Piroxicam", "20mg", 30, 3),
        ("Etoricoxib", "90mg", 120, 14),
        ("Nimesulide", "100mg", 30, 3),
        // Respiratory
        ("Montelukast", "5mg", 110, 12),
        ("Montelukast", "4mg", 95, 10),
        ("Levocetirizine", "5mg", 35, 4),
        ("Fexofenadine", "120mg", 95, 10),
        ("Fexofenadine", "180mg", 130, 15),
        ("Salbutamol", "2mg", 20, 2),
        ("Theophylline", "200mg", 35, 4),
        ("Ambroxol", "30mg", 30, 3),
        // Thyroid
        ("Levothyroxine", "12.5mcg", 55, 6),
        ("Levothyroxine", "25mcg", 65, 7),
        ("Levothyroxine", "75mcg", 85, 9),
        ("Levothyroxine", "125mcg", 105, 12),
        ("Levothyroxine", "150mcg", 120, 14),
        // Mental Health
        ("Escitalopram", "5mg", 75, 8),
        ("Escitalopram", "20mg", 160, 18),
        ("Sertraline", "50mg", 80, 9),
        ("Sertraline", "100mg", 130, 15),
        ("Fluoxetine", "20mg", 45, 5),
        ("Duloxetine", "20mg", 65, 7),
        ("Duloxetine", "30mg", 85, 9),
        ("Duloxetine", "60mg", 130, 15),
        ("Amitriptyline", "25mg", 18, 2),
        ("Olanzapine", "5mg", 55, 6),
        ("Olanzapine", "10mg", 85, 9),
        ("Risperidone", "2mg", 35, 4),
        ("Lithium", "300mg", 18, 2),
        ("Pregabalin", "75mg", 95, 10),
        ("Pregabalin", "150mg", 160, 18),
        // Vitamins/Supplements
        ("Vitamin D3", "60000IU", 120, 15),
        ("Calcium + D3", "500mg", 110, 12),
        ("Methylcobalamin", "1500mcg", 95, 10),
        ("Methylcobalamin", "500mcg", 65, 7),
        ("Zinc", "20mg", 35, 4),
    ]

    /// Find Jan Aushadhi pricing for a medicine based on its generic/salt name and dosage
    func findJanAushadhiPrice(genericName: String?, dosage: String) -> JanAushadhiPrice? {
        guard let generic = genericName?.lowercased() else { return nil }
        let dosageLower = dosage.lowercased()

        for entry in Self.janAushadhiPrices {
            if generic.contains(entry.generic.lowercased()) && dosageLower.contains(entry.dosage.lowercased()) {
                return JanAushadhiPrice(
                    genericName: entry.generic,
                    dosage: entry.dosage,
                    brandMRP: entry.brandMRP,
                    janAushadhiPrice: entry.jaPrice
                )
            }
        }
        return nil
    }

    /// Find Jan Aushadhi pricing for a Medicine model object
    func findJanAushadhiPrice(for medicine: Medicine) -> JanAushadhiPrice? {
        // Try genericName first, then look up from drug database
        let generic = medicine.genericName ?? {
            let entry = medicines.first { $0.brandName.lowercased() == medicine.brandName.lowercased() }
            return entry?.genericName
        }()
        return findJanAushadhiPrice(genericName: generic, dosage: medicine.dosage)
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

        // ════════════════════════════════════════════
        // EXPANDED DATABASE — 400+ NEW ENTRIES
        // ════════════════════════════════════════════

        // ────────────────────────────────────────────
        // DIABETES (EXPANDED)
        // ────────────────────────────────────────────

        db.append(DrugEntry(
            id: "metformin-850", brandName: "Glycomet 850", genericName: "Metformin",
            saltComposition: "Metformin Hydrochloride 850mg",
            category: .antidiabetic, manufacturer: "USV Private Limited",
            commonDosages: ["850mg"], typicalDoseForm: "tablet",
            priceRange: "₹30-80",
            genericAlternatives: [
                GenericAlternative(brandName: "Obimet 850", manufacturer: "Abbott", priceRange: "₹35-90"),
                GenericAlternative(brandName: "Gluconorm 850", manufacturer: "Lupin", priceRange: "₹25-75")
            ],
            foodInteractions: ["Take with meals to reduce GI upset", "Avoid excessive alcohol — risk of lactic acidosis"],
            commonSideEffects: ["Nausea", "Diarrhoea", "Metallic taste", "Stomach cramps", "Vitamin B12 deficiency (long term)"],
            storageInstructions: "Store below 30°C. Keep away from moisture.",
            description: "Metformin 850mg strength for Type 2 diabetes when 500mg is insufficient.",
            isScheduleH: true
        ))

        db.append(DrugEntry(
            id: "metformin-1000", brandName: "Glycomet 1000 SR", genericName: "Metformin",
            saltComposition: "Metformin Hydrochloride 1000mg SR",
            category: .antidiabetic, manufacturer: "USV Private Limited",
            commonDosages: ["1000mg"], typicalDoseForm: "tablet",
            priceRange: "₹40-100",
            genericAlternatives: [
                GenericAlternative(brandName: "Obimet SR 1000", manufacturer: "Abbott", priceRange: "₹45-110"),
                GenericAlternative(brandName: "Gluconorm SR 1000", manufacturer: "Lupin", priceRange: "₹35-90")
            ],
            foodInteractions: ["Take with dinner", "Do not crush SR tablets", "Avoid alcohol"],
            commonSideEffects: ["Nausea", "Diarrhoea", "Abdominal pain", "Metallic taste"],
            storageInstructions: "Store below 30°C.",
            description: "Sustained-release metformin 1000mg for once-daily dosing in Type 2 diabetes.",
            isScheduleH: true
        ))

        db.append(DrugEntry(
            id: "teneligliptin", brandName: "Tenli", genericName: "Teneligliptin",
            saltComposition: "Teneligliptin 20mg",
            category: .antidiabetic, manufacturer: "Glenmark",
            commonDosages: ["20mg"], typicalDoseForm: "tablet",
            priceRange: "₹100-200",
            genericAlternatives: [
                GenericAlternative(brandName: "Tenepure", manufacturer: "Mankind", priceRange: "₹80-150"),
                GenericAlternative(brandName: "Teneglyn", manufacturer: "USV", priceRange: "₹70-140")
            ],
            foodInteractions: ["Can be taken with or without food"],
            commonSideEffects: ["Hypoglycemia (with SU)", "Nasopharyngitis", "Constipation", "Headache"],
            storageInstructions: "Store below 30°C.",
            description: "DPP-4 inhibitor popular in India for Type 2 diabetes. Cost-effective option.",
            isScheduleH: true
        ))

        db.append(DrugEntry(
            id: "voglibose", brandName: "Vogli", genericName: "Voglibose",
            saltComposition: "Voglibose 0.2mg",
            category: .antidiabetic, manufacturer: "USV",
            commonDosages: ["0.2mg", "0.3mg"], typicalDoseForm: "tablet",
            priceRange: "₹60-120",
            genericAlternatives: [
                GenericAlternative(brandName: "Volibo", manufacturer: "Mankind", priceRange: "₹45-90"),
                GenericAlternative(brandName: "PPG", manufacturer: "Sun Pharma", priceRange: "₹50-100")
            ],
            foodInteractions: ["Take with the first bite of each main meal"],
            commonSideEffects: ["Flatulence", "Bloating", "Diarrhoea", "Abdominal pain"],
            storageInstructions: "Store below 30°C.",
            description: "Alpha-glucosidase inhibitor to control post-meal blood sugar spikes.",
            isScheduleH: true
        ))

        db.append(DrugEntry(
            id: "canagliflozin", brandName: "Invokana", genericName: "Canagliflozin",
            saltComposition: "Canagliflozin 100mg",
            category: .antidiabetic, manufacturer: "Johnson & Johnson",
            commonDosages: ["100mg", "300mg"], typicalDoseForm: "tablet",
            priceRange: "₹350-550",
            genericAlternatives: [
                GenericAlternative(brandName: "Canastar", manufacturer: "Sun Pharma", priceRange: "₹200-380"),
                GenericAlternative(brandName: "Canaflo", manufacturer: "Mankind", priceRange: "₹180-350")
            ],
            foodInteractions: ["Take before first meal of the day", "Increase water intake"],
            commonSideEffects: ["Genital fungal infection", "Urinary tract infection", "Frequent urination", "Thirst", "Hypotension"],
            storageInstructions: "Store below 30°C.",
            description: "SGLT2 inhibitor for Type 2 diabetes with cardiovascular benefits.",
            isScheduleH: true
        ))

        db.append(DrugEntry(
            id: "insulin-aspart", brandName: "NovoRapid", genericName: "Insulin Aspart",
            saltComposition: "Insulin Aspart 100 IU/ml",
            category: .antidiabetic, manufacturer: "Novo Nordisk",
            commonDosages: ["100 IU/ml"], typicalDoseForm: "injection",
            priceRange: "₹600-1200",
            genericAlternatives: [
                GenericAlternative(brandName: "Insugen-R", manufacturer: "Biocon", priceRange: "₹350-700"),
                GenericAlternative(brandName: "Eglucent Rapid", manufacturer: "Cipla", priceRange: "₹400-800")
            ],
            foodInteractions: ["Inject just before meals", "Coordinate with carbohydrate intake"],
            commonSideEffects: ["Hypoglycemia", "Injection site reactions", "Weight gain", "Lipodystrophy"],
            storageInstructions: "Store unopened in fridge (2-8°C). In-use pen at room temperature for up to 28 days.",
            description: "Rapid-acting mealtime insulin for Type 1 and Type 2 diabetes.",
            isScheduleH: true
        ))

        db.append(DrugEntry(
            id: "insulin-regular", brandName: "Actrapid", genericName: "Insulin Human Regular",
            saltComposition: "Regular Human Insulin 40 IU/ml",
            category: .antidiabetic, manufacturer: "Novo Nordisk",
            commonDosages: ["40 IU/ml", "100 IU/ml"], typicalDoseForm: "injection",
            priceRange: "₹150-400",
            genericAlternatives: [
                GenericAlternative(brandName: "Insugen-R", manufacturer: "Biocon", priceRange: "₹120-300"),
                GenericAlternative(brandName: "Wosulin-R", manufacturer: "Wockhardt", priceRange: "₹100-280")
            ],
            foodInteractions: ["Inject 30 minutes before meals", "Consistent meal timing important"],
            commonSideEffects: ["Hypoglycemia", "Weight gain", "Injection site reactions", "Lipodystrophy"],
            storageInstructions: "Store in fridge. In-use vial at room temperature for 28 days.",
            description: "Short-acting human insulin for diabetes management.",
            isScheduleH: true
        ))

        db.append(DrugEntry(
            id: "insulin-mixtard", brandName: "Mixtard 30", genericName: "Insulin Human 30/70",
            saltComposition: "Soluble Insulin 30% + Isophane Insulin 70%",
            category: .antidiabetic, manufacturer: "Novo Nordisk",
            commonDosages: ["40 IU/ml", "100 IU/ml"], typicalDoseForm: "injection",
            priceRange: "₹150-400",
            genericAlternatives: [
                GenericAlternative(brandName: "Insugen 30/70", manufacturer: "Biocon", priceRange: "₹120-300"),
                GenericAlternative(brandName: "Wosulin 30/70", manufacturer: "Wockhardt", priceRange: "₹100-280")
            ],
            foodInteractions: ["Inject 30 minutes before meals", "Do not skip meals after injection"],
            commonSideEffects: ["Hypoglycemia", "Weight gain", "Injection site reactions"],
            storageInstructions: "Store in fridge. Gently roll before use — do not shake.",
            description: "Premixed insulin (30% regular + 70% NPH) for twice-daily diabetes management.",
            isScheduleH: true
        ))

        db.append(DrugEntry(
            id: "glimepiride-1", brandName: "Amaryl 1", genericName: "Glimepiride",
            saltComposition: "Glimepiride 1mg",
            category: .antidiabetic, manufacturer: "Sanofi India",
            commonDosages: ["1mg"], typicalDoseForm: "tablet",
            priceRange: "₹40-80",
            genericAlternatives: [
                GenericAlternative(brandName: "Glimisave 1", manufacturer: "Mankind", priceRange: "₹25-55"),
                GenericAlternative(brandName: "Glimy 1", manufacturer: "USV", priceRange: "₹20-50")
            ],
            foodInteractions: ["Take with breakfast", "Do not skip meals"],
            commonSideEffects: ["Hypoglycemia", "Weight gain", "Dizziness", "Nausea"],
            storageInstructions: "Store below 30°C.",
            description: "Low-dose glimepiride for initial Type 2 diabetes therapy.",
            isScheduleH: true
        ))

        db.append(DrugEntry(
            id: "glimepiride-4", brandName: "Amaryl 4", genericName: "Glimepiride",
            saltComposition: "Glimepiride 4mg",
            category: .antidiabetic, manufacturer: "Sanofi India",
            commonDosages: ["4mg"], typicalDoseForm: "tablet",
            priceRange: "₹100-180",
            genericAlternatives: [
                GenericAlternative(brandName: "Glimisave 4", manufacturer: "Mankind", priceRange: "₹60-120"),
                GenericAlternative(brandName: "Glimy 4", manufacturer: "USV", priceRange: "₹55-110")
            ],
            foodInteractions: ["Take with breakfast", "Do not skip meals — high hypoglycemia risk"],
            commonSideEffects: ["Hypoglycemia", "Weight gain", "Dizziness", "Nausea", "Headache"],
            storageInstructions: "Store below 30°C.",
            description: "High-dose glimepiride for uncontrolled Type 2 diabetes.",
            isScheduleH: true
        ))

        db.append(DrugEntry(
            id: "sitagliptin-50", brandName: "Januvia 50", genericName: "Sitagliptin",
            saltComposition: "Sitagliptin 50mg",
            category: .antidiabetic, manufacturer: "MSD Pharmaceuticals",
            commonDosages: ["50mg"], typicalDoseForm: "tablet",
            priceRange: "₹250-450",
            genericAlternatives: [
                GenericAlternative(brandName: "Istavel 50", manufacturer: "Sun Pharma", priceRange: "₹180-320"),
                GenericAlternative(brandName: "Zita 50", manufacturer: "Glenmark", priceRange: "₹150-280")
            ],
            foodInteractions: ["Can be taken with or without food"],
            commonSideEffects: ["Upper respiratory infection", "Headache", "Nausea"],
            storageInstructions: "Store below 30°C.",
            description: "Mid-dose sitagliptin, often used for moderate renal impairment.",
            isScheduleH: true
        ))

        db.append(DrugEntry(
            id: "metformin-glimepiride-2", brandName: "Glycomet-GP 2", genericName: "Metformin + Glimepiride",
            saltComposition: "Metformin 500mg + Glimepiride 2mg",
            category: .antidiabetic, manufacturer: "USV Private Limited",
            commonDosages: ["500/2mg"], typicalDoseForm: "tablet",
            priceRange: "₹70-150",
            genericAlternatives: [
                GenericAlternative(brandName: "Gliminyle-M2", manufacturer: "Mankind", priceRange: "₹45-100"),
                GenericAlternative(brandName: "Gluconorm-G2", manufacturer: "Lupin", priceRange: "₹50-110")
            ],
            foodInteractions: ["Take with meals", "Do not skip meals", "Avoid alcohol"],
            commonSideEffects: ["Hypoglycemia", "Nausea", "Diarrhoea", "Weight gain"],
            storageInstructions: "Store below 30°C.",
            description: "Higher-strength combination for uncontrolled Type 2 diabetes.",
            isScheduleH: true
        ))

        db.append(DrugEntry(
            id: "metformin-vildagliptin", brandName: "Galvus Met", genericName: "Metformin + Vildagliptin",
            saltComposition: "Metformin 500mg + Vildagliptin 50mg",
            category: .antidiabetic, manufacturer: "Novartis India",
            commonDosages: ["500/50mg", "1000/50mg"], typicalDoseForm: "tablet",
            priceRange: "₹280-450",
            genericAlternatives: [
                GenericAlternative(brandName: "Jalra-M", manufacturer: "USV", priceRange: "₹200-350"),
                GenericAlternative(brandName: "Vysov-M", manufacturer: "Micro Labs", priceRange: "₹180-320")
            ],
            foodInteractions: ["Take with meals"],
            commonSideEffects: ["Nausea", "Diarrhoea", "Headache", "Dizziness", "Tremor"],
            storageInstructions: "Store below 30°C.",
            description: "Combination of Metformin + DPP-4 inhibitor for better glycemic control.",
            isScheduleH: true
        ))

        db.append(DrugEntry(
            id: "metformin-sitagliptin", brandName: "Janumet", genericName: "Metformin + Sitagliptin",
            saltComposition: "Metformin 500mg + Sitagliptin 50mg",
            category: .antidiabetic, manufacturer: "MSD Pharmaceuticals",
            commonDosages: ["500/50mg", "1000/50mg"], typicalDoseForm: "tablet",
            priceRange: "₹350-600",
            genericAlternatives: [
                GenericAlternative(brandName: "Istamet", manufacturer: "Sun Pharma", priceRange: "₹250-450"),
                GenericAlternative(brandName: "Sitazit-M", manufacturer: "Glenmark", priceRange: "₹220-400")
            ],
            foodInteractions: ["Take with meals"],
            commonSideEffects: ["Nausea", "Diarrhoea", "Headache", "Upper respiratory infection"],
            storageInstructions: "Store below 30°C.",
            description: "Combination of Metformin + Sitagliptin for comprehensive diabetes control.",
            isScheduleH: true
        ))

        db.append(DrugEntry(
            id: "metformin-dapagliflozin", brandName: "Xigduo", genericName: "Metformin + Dapagliflozin",
            saltComposition: "Metformin 500mg + Dapagliflozin 5mg",
            category: .antidiabetic, manufacturer: "AstraZeneca",
            commonDosages: ["500/5mg", "1000/5mg", "500/10mg", "1000/10mg"], typicalDoseForm: "tablet",
            priceRange: "₹350-550",
            genericAlternatives: [
                GenericAlternative(brandName: "Dapavel-M", manufacturer: "Sun Pharma", priceRange: "₹200-380"),
                GenericAlternative(brandName: "Oxramet", manufacturer: "Intas", priceRange: "₹180-350")
            ],
            foodInteractions: ["Take with meals", "Increase water intake"],
            commonSideEffects: ["Nausea", "Genital infections", "Urinary tract infection", "Diarrhoea"],
            storageInstructions: "Store below 30°C.",
            description: "Metformin + SGLT2 inhibitor combination for diabetes with cardio-renal benefits.",
            isScheduleH: true
        ))

        db.append(DrugEntry(
            id: "metformin-teneligliptin", brandName: "Tenli-M", genericName: "Metformin + Teneligliptin",
            saltComposition: "Metformin 500mg + Teneligliptin 20mg",
            category: .antidiabetic, manufacturer: "Glenmark",
            commonDosages: ["500/20mg", "1000/20mg"], typicalDoseForm: "tablet",
            priceRange: "₹120-220",
            genericAlternatives: [
                GenericAlternative(brandName: "Tenepure-M", manufacturer: "Mankind", priceRange: "₹90-170"),
                GenericAlternative(brandName: "Teneglyn-M", manufacturer: "USV", priceRange: "₹80-160")
            ],
            foodInteractions: ["Take with meals"],
            commonSideEffects: ["Nausea", "Diarrhoea", "Hypoglycemia (with SU)", "Headache"],
            storageInstructions: "Store below 30°C.",
            description: "Affordable Metformin + DPP-4 inhibitor combination widely used in India.",
            isScheduleH: true
        ))

        db.append(DrugEntry(
            id: "insulin-degludec", brandName: "Tresiba", genericName: "Insulin Degludec",
            saltComposition: "Insulin Degludec 100 IU/ml",
            category: .antidiabetic, manufacturer: "Novo Nordisk",
            commonDosages: ["100 IU/ml", "200 IU/ml"], typicalDoseForm: "injection",
            priceRange: "₹1200-2500",
            genericAlternatives: [
                GenericAlternative(brandName: "Semglee Ultra", manufacturer: "Biocon", priceRange: "₹800-1600")
            ],
            foodInteractions: ["Can be injected at any time of day", "Consistent timing preferred"],
            commonSideEffects: ["Hypoglycemia", "Injection site reactions", "Weight gain"],
            storageInstructions: "Store unopened in fridge. In-use pen at room temperature for up to 56 days.",
            description: "Ultra-long-acting basal insulin with 42+ hour duration. Flexible dosing time.",
            isScheduleH: true
        ))

        db.append(DrugEntry(
            id: "glipizide-xl", brandName: "Glynase XL", genericName: "Glipizide",
            saltComposition: "Glipizide 5mg XL",
            category: .antidiabetic, manufacturer: "USV",
            commonDosages: ["2.5mg", "5mg", "10mg"], typicalDoseForm: "tablet",
            priceRange: "₹20-50",
            genericAlternatives: [
                GenericAlternative(brandName: "Glide XL", manufacturer: "Various", priceRange: "₹15-35")
            ],
            foodInteractions: ["Take with breakfast", "Do not skip meals"],
            commonSideEffects: ["Hypoglycemia", "Weight gain", "Nausea"],
            storageInstructions: "Store below 30°C.",
            description: "Extended-release glipizide sulfonylurea for Type 2 diabetes.",
            isScheduleH: true
        ))

        // ────────────────────────────────────────────
        // CARDIAC / HYPERTENSION (EXPANDED)
        // ────────────────────────────────────────────

        db.append(DrugEntry(
            id: "bisoprolol", brandName: "Concor", genericName: "Bisoprolol",
            saltComposition: "Bisoprolol Fumarate 5mg",
            category: .antihypertensive, manufacturer: "Merck",
            commonDosages: ["1.25mg", "2.5mg", "5mg", "10mg"], typicalDoseForm: "tablet",
            priceRange: "₹50-120",
            genericAlternatives: [
                GenericAlternative(brandName: "Biselect", manufacturer: "Intas", priceRange: "₹35-80"),
                GenericAlternative(brandName: "Corbis", manufacturer: "Torrent", priceRange: "₹30-70")
            ],
            foodInteractions: ["Can be taken with or without food", "Limit caffeine"],
            commonSideEffects: ["Fatigue", "Bradycardia", "Dizziness", "Cold extremities", "Headache"],
            storageInstructions: "Store below 30°C.",
            description: "Highly selective beta-1 blocker for hypertension and heart failure.",
            isScheduleH: true
        ))

        db.append(DrugEntry(
            id: "nebivolol", brandName: "Nebicard", genericName: "Nebivolol",
            saltComposition: "Nebivolol 5mg",
            category: .antihypertensive, manufacturer: "Torrent",
            commonDosages: ["2.5mg", "5mg", "10mg"], typicalDoseForm: "tablet",
            priceRange: "₹60-140",
            genericAlternatives: [
                GenericAlternative(brandName: "Nebula", manufacturer: "Micro Labs", priceRange: "₹45-100"),
                GenericAlternative(brandName: "Nebistol", manufacturer: "Cipla", priceRange: "₹50-110")
            ],
            foodInteractions: ["Can be taken with or without food"],
            commonSideEffects: ["Headache", "Fatigue", "Dizziness", "Nausea", "Bradycardia"],
            storageInstructions: "Store below 30°C.",
            description: "Third-generation beta-blocker with vasodilating properties.",
            isScheduleH: true
        ))

        db.append(DrugEntry(
            id: "carvedilol", brandName: "Cardivas", genericName: "Carvedilol",
            saltComposition: "Carvedilol 6.25mg",
            category: .antihypertensive, manufacturer: "Sun Pharma",
            commonDosages: ["3.125mg", "6.25mg", "12.5mg", "25mg"], typicalDoseForm: "tablet",
            priceRange: "₹30-80",
            genericAlternatives: [
                GenericAlternative(brandName: "Carloc", manufacturer: "Cipla", priceRange: "₹25-60"),
                GenericAlternative(brandName: "Carca", manufacturer: "Intas", priceRange: "₹20-55")
            ],
            foodInteractions: ["Take with food to slow absorption", "Avoid alcohol"],
            commonSideEffects: ["Dizziness", "Fatigue", "Diarrhoea", "Bradycardia", "Weight gain"],
            storageInstructions: "Store below 30°C. Protect from moisture.",
            description: "Alpha/beta blocker for heart failure and hypertension.",
            isScheduleH: true
        ))

        db.append(DrugEntry(
            id: "verapamil", brandName: "Calaptin", genericName: "Verapamil",
            saltComposition: "Verapamil 40mg",
            category: .antihypertensive, manufacturer: "Abbott",
            commonDosages: ["40mg", "80mg", "120mg", "240mg SR"], typicalDoseForm: "tablet",
            priceRange: "₹20-60",
            genericAlternatives: [
                GenericAlternative(brandName: "Isoptin", manufacturer: "Abbott", priceRange: "₹25-70"),
                GenericAlternative(brandName: "Veramil", manufacturer: "Cipla", priceRange: "₹15-45")
            ],
            foodInteractions: ["Take with food", "Avoid grapefruit juice"],
            commonSideEffects: ["Constipation", "Dizziness", "Headache", "Bradycardia", "Ankle oedema"],
            storageInstructions: "Store below 30°C. Protect from light.",
            description: "Calcium channel blocker for hypertension, angina, and supraventricular tachycardia.",
            isScheduleH: true
        ))

        db.append(DrugEntry(
            id: "hydrochlorothiazide", brandName: "Aquazide", genericName: "Hydrochlorothiazide",
            saltComposition: "Hydrochlorothiazide 12.5mg",
            category: .antihypertensive, manufacturer: "Sun Pharma",
            commonDosages: ["12.5mg", "25mg"], typicalDoseForm: "tablet",
            priceRange: "₹10-25",
            genericAlternatives: [
                GenericAlternative(brandName: "Hydrazide", manufacturer: "Cipla", priceRange: "₹8-20"),
                GenericAlternative(brandName: "HCTZ", manufacturer: "Various", priceRange: "₹5-15")
            ],
            foodInteractions: ["Take in the morning", "Eat potassium-rich foods"],
            commonSideEffects: ["Frequent urination", "Low potassium", "Dizziness", "Increased blood sugar", "Gout"],
            storageInstructions: "Store below 30°C.",
            description: "Thiazide diuretic for hypertension and edema. Often used in combination.",
            isScheduleH: true
        ))

        db.append(DrugEntry(
            id: "chlorthalidone", brandName: "Clorpres", genericName: "Chlorthalidone",
            saltComposition: "Chlorthalidone 12.5mg",
            category: .antihypertensive, manufacturer: "Various",
            commonDosages: ["6.25mg", "12.5mg", "25mg"], typicalDoseForm: "tablet",
            priceRange: "₹15-35",
            genericAlternatives: [
                GenericAlternative(brandName: "Thalitone", manufacturer: "Various", priceRange: "₹12-30")
            ],
            foodInteractions: ["Take in the morning", "Eat potassium-rich foods"],
            commonSideEffects: ["Low potassium", "Dizziness", "Frequent urination", "Elevated blood sugar"],
            storageInstructions: "Store below 30°C.",
            description: "Long-acting thiazide-like diuretic, preferred over HCTZ in some guidelines.",
            isScheduleH: true
        ))

        db.append(DrugEntry(
            id: "rivaroxaban", brandName: "Xarelto", genericName: "Rivaroxaban",
            saltComposition: "Rivaroxaban 10mg",
            category: .cardiovascular, manufacturer: "Bayer",
            commonDosages: ["10mg", "15mg", "20mg"], typicalDoseForm: "tablet",
            priceRange: "₹200-500",
            genericAlternatives: [
                GenericAlternative(brandName: "Xaban", manufacturer: "Sun Pharma", priceRange: "₹120-300"),
                GenericAlternative(brandName: "Rivamer", manufacturer: "Cipla", priceRange: "₹100-280")
            ],
            foodInteractions: ["Take 15mg and 20mg doses with food", "10mg can be with or without food"],
            commonSideEffects: ["Bleeding", "Bruising", "Nausea", "Anaemia", "Dizziness"],
            storageInstructions: "Store below 30°C.",
            description: "Direct oral anticoagulant (DOAC) for DVT, PE, AF. No INR monitoring needed.",
            isScheduleH: true
        ))

        db.append(DrugEntry(
            id: "apixaban", brandName: "Eliquis", genericName: "Apixaban",
            saltComposition: "Apixaban 5mg",
            category: .cardiovascular, manufacturer: "Pfizer/BMS",
            commonDosages: ["2.5mg", "5mg"], typicalDoseForm: "tablet",
            priceRange: "₹200-450",
            genericAlternatives: [
                GenericAlternative(brandName: "Apigat", manufacturer: "Natco", priceRange: "₹120-280"),
                GenericAlternative(brandName: "Apixa", manufacturer: "Dr. Reddy's", priceRange: "₹130-300")
            ],
            foodInteractions: ["Can be taken with or without food"],
            commonSideEffects: ["Bleeding", "Bruising", "Nausea", "Anaemia"],
            storageInstructions: "Store below 30°C.",
            description: "DOAC with lowest bleeding risk in class. For atrial fibrillation and DVT/PE.",
            isScheduleH: true
        ))

        db.append(DrugEntry(
            id: "amlodipine-atenolol", brandName: "Stamlo-D", genericName: "Amlodipine + Atenolol",
            saltComposition: "Amlodipine 5mg + Atenolol 50mg",
            category: .antihypertensive, manufacturer: "Dr. Reddy's",
            commonDosages: ["5/50mg", "5/25mg"], typicalDoseForm: "tablet",
            priceRange: "₹40-90",
            genericAlternatives: [
                GenericAlternative(brandName: "Amlopress-AT", manufacturer: "Cipla", priceRange: "₹30-70"),
                GenericAlternative(brandName: "Amlokind-AT", manufacturer: "Mankind", priceRange: "₹25-60")
            ],
            foodInteractions: ["Can be taken with or without food", "Avoid grapefruit juice"],
            commonSideEffects: ["Fatigue", "Ankle swelling", "Dizziness", "Bradycardia", "Cold extremities"],
            storageInstructions: "Store below 30°C.",
            description: "Combination of CCB + beta-blocker for hypertension.",
            isScheduleH: true
        ))

        db.append(DrugEntry(
            id: "aspirin-clopidogrel", brandName: "Deplatt-A", genericName: "Aspirin + Clopidogrel",
            saltComposition: "Aspirin 75mg + Clopidogrel 75mg",
            category: .cardiovascular, manufacturer: "Torrent",
            commonDosages: ["75/75mg", "150/75mg"], typicalDoseForm: "tablet",
            priceRange: "₹60-120",
            genericAlternatives: [
                GenericAlternative(brandName: "Ecosprin-AV", manufacturer: "USV", priceRange: "₹50-100"),
                GenericAlternative(brandName: "Clopilet-A", manufacturer: "Sun Pharma", priceRange: "₹45-90")
            ],
            foodInteractions: ["Take with food to reduce stomach irritation"],
            commonSideEffects: ["Bleeding", "Bruising", "Stomach pain", "Heartburn", "Diarrhoea"],
            storageInstructions: "Store below 30°C.",
            description: "Dual antiplatelet therapy (DAPT) after heart attack or stent placement.",
            isScheduleH: true
        ))

        db.append(DrugEntry(
            id: "aspirin-atorvastatin", brandName: "Ecosprin-AV", genericName: "Aspirin + Atorvastatin",
            saltComposition: "Aspirin 75mg + Atorvastatin 10mg",
            category: .cardiovascular, manufacturer: "USV",
            commonDosages: ["75/10mg", "75/20mg", "75/40mg"], typicalDoseForm: "capsule",
            priceRange: "₹50-120",
            genericAlternatives: [
                GenericAlternative(brandName: "Atorsave-ASP", manufacturer: "Cipla", priceRange: "₹40-100")
            ],
            foodInteractions: ["Take with food", "Avoid grapefruit juice"],
            commonSideEffects: ["Stomach pain", "Muscle pain", "Heartburn", "Nausea"],
            storageInstructions: "Store below 30°C.",
            description: "Combination for cardiovascular risk reduction — antiplatelet + statin.",
            isScheduleH: true
        ))

        db.append(DrugEntry(
            id: "telmisartan-amlodipine", brandName: "Telma-AM", genericName: "Telmisartan + Amlodipine",
            saltComposition: "Telmisartan 40mg + Amlodipine 5mg",
            category: .antihypertensive, manufacturer: "Glenmark",
            commonDosages: ["40/5mg", "80/5mg"], typicalDoseForm: "tablet",
            priceRange: "₹100-200",
            genericAlternatives: [
                GenericAlternative(brandName: "Telmikind-AM", manufacturer: "Mankind", priceRange: "₹60-130"),
                GenericAlternative(brandName: "Telsar-AM", manufacturer: "Unichem", priceRange: "₹65-140")
            ],
            foodInteractions: ["Can be taken with or without food", "Avoid grapefruit juice"],
            commonSideEffects: ["Dizziness", "Ankle swelling", "Headache", "Fatigue"],
            storageInstructions: "Store below 30°C.",
            description: "ARB + CCB combination for hypertension not controlled with monotherapy.",
            isScheduleH: true
        ))

        db.append(DrugEntry(
            id: "losartan-hctz", brandName: "Losar-H", genericName: "Losartan + Hydrochlorothiazide",
            saltComposition: "Losartan 50mg + Hydrochlorothiazide 12.5mg",
            category: .antihypertensive, manufacturer: "Cipla",
            commonDosages: ["50/12.5mg", "100/25mg"], typicalDoseForm: "tablet",
            priceRange: "₹60-130",
            genericAlternatives: [
                GenericAlternative(brandName: "Repace-H", manufacturer: "Sun Pharma", priceRange: "₹50-110"),
                GenericAlternative(brandName: "Losacar-H", manufacturer: "Cadila", priceRange: "₹45-100")
            ],
            foodInteractions: ["Can be taken with or without food", "Stay hydrated"],
            commonSideEffects: ["Dizziness", "Fatigue", "Frequent urination", "Low potassium"],
            storageInstructions: "Store below 30°C.",
            description: "ARB + diuretic combination for hypertension.",
            isScheduleH: true
        ))

        db.append(DrugEntry(
            id: "ramipril-amlodipine", brandName: "Cardace-AM", genericName: "Ramipril + Amlodipine",
            saltComposition: "Ramipril 5mg + Amlodipine 5mg",
            category: .antihypertensive, manufacturer: "Sanofi India",
            commonDosages: ["2.5/5mg", "5/5mg"], typicalDoseForm: "capsule",
            priceRange: "₹80-160",
            genericAlternatives: [
                GenericAlternative(brandName: "Ramistar-AM", manufacturer: "Lupin", priceRange: "₹55-120")
            ],
            foodInteractions: ["Can be taken with or without food", "Avoid potassium supplements"],
            commonSideEffects: ["Dry cough", "Ankle swelling", "Dizziness", "Headache"],
            storageInstructions: "Store below 30°C.",
            description: "ACE inhibitor + CCB combination for hypertension.",
            isScheduleH: true
        ))

        db.append(DrugEntry(
            id: "isosorbide-mono", brandName: "Monotrate", genericName: "Isosorbide Mononitrate",
            saltComposition: "Isosorbide Mononitrate 20mg",
            category: .cardiovascular, manufacturer: "Sun Pharma",
            commonDosages: ["10mg", "20mg", "30mg SR", "60mg SR"], typicalDoseForm: "tablet",
            priceRange: "₹20-50",
            genericAlternatives: [
                GenericAlternative(brandName: "Ismo", manufacturer: "Cipla", priceRange: "₹15-40"),
                GenericAlternative(brandName: "Imdur", manufacturer: "AstraZeneca", priceRange: "₹30-70")
            ],
            foodInteractions: ["Avoid alcohol — severe hypotension"],
            commonSideEffects: ["Headache", "Dizziness", "Flushing", "Nausea"],
            storageInstructions: "Store below 30°C. Protect from light.",
            description: "Long-acting nitrate for angina prevention. Nitrate-free interval needed.",
            isScheduleH: true
        ))

        db.append(DrugEntry(
            id: "nitroglycerin-patch", brandName: "Nitroderm TTS", genericName: "Nitroglycerin",
            saltComposition: "Nitroglycerin 2.6mg SR",
            category: .cardiovascular, manufacturer: "Novartis",
            commonDosages: ["2.6mg", "6.4mg"], typicalDoseForm: "tablet",
            priceRange: "₹20-50",
            genericAlternatives: [
                GenericAlternative(brandName: "NTG", manufacturer: "Various", priceRange: "₹15-35")
            ],
            foodInteractions: ["Avoid alcohol", "Do NOT combine with sildenafil/tadalafil"],
            commonSideEffects: ["Headache", "Flushing", "Dizziness", "Hypotension"],
            storageInstructions: "Store below 25°C. Protect from light.",
            description: "Sustained-release nitroglycerin for angina prophylaxis.",
            isScheduleH: true
        ))

        db.append(DrugEntry(
            id: "fenofibrate", brandName: "Lipanthyl", genericName: "Fenofibrate",
            saltComposition: "Fenofibrate 145mg",
            category: .cholesterol, manufacturer: "Abbott",
            commonDosages: ["67mg", "145mg", "160mg", "200mg"], typicalDoseForm: "tablet",
            priceRange: "₹80-180",
            genericAlternatives: [
                GenericAlternative(brandName: "Fibator", manufacturer: "Sun Pharma", priceRange: "₹50-120"),
                GenericAlternative(brandName: "Fenolip", manufacturer: "Cipla", priceRange: "₹45-110")
            ],
            foodInteractions: ["Take with meals"],
            commonSideEffects: ["Stomach pain", "Nausea", "Muscle pain", "Headache", "Elevated liver enzymes"],
            storageInstructions: "Store below 30°C.",
            description: "Fibrate for high triglycerides and mixed dyslipidemia.",
            isScheduleH: true
        ))

        db.append(DrugEntry(
            id: "atorvastatin-fenofibrate", brandName: "Atorva-F", genericName: "Atorvastatin + Fenofibrate",
            saltComposition: "Atorvastatin 10mg + Fenofibrate 145mg",
            category: .cholesterol, manufacturer: "Zydus Cadila",
            commonDosages: ["10/145mg", "10/160mg"], typicalDoseForm: "tablet",
            priceRange: "₹120-220",
            genericAlternatives: [
                GenericAlternative(brandName: "Fibator-AV", manufacturer: "Sun Pharma", priceRange: "₹80-160")
            ],
            foodInteractions: ["Take with meals", "Avoid grapefruit juice", "Avoid alcohol"],
            commonSideEffects: ["Muscle pain", "Stomach pain", "Nausea", "Elevated liver enzymes"],
            storageInstructions: "Store below 30°C.",
            description: "Statin + fibrate combination for mixed dyslipidemia (high cholesterol + triglycerides).",
            isScheduleH: true
        ))

        db.append(DrugEntry(
            id: "atorvastatin-ezetimibe", brandName: "Atorva-EZ", genericName: "Atorvastatin + Ezetimibe",
            saltComposition: "Atorvastatin 10mg + Ezetimibe 10mg",
            category: .cholesterol, manufacturer: "Zydus Cadila",
            commonDosages: ["10/10mg", "20/10mg", "40/10mg"], typicalDoseForm: "tablet",
            priceRange: "₹100-200",
            genericAlternatives: [
                GenericAlternative(brandName: "Atozet", manufacturer: "MSD", priceRange: "₹200-380"),
                GenericAlternative(brandName: "Rosutor-EZ", manufacturer: "Torrent", priceRange: "₹80-160")
            ],
            foodInteractions: ["Can be taken with or without food", "Avoid grapefruit juice"],
            commonSideEffects: ["Muscle pain", "Headache", "Diarrhoea", "Elevated liver enzymes"],
            storageInstructions: "Store below 30°C.",
            description: "Statin + cholesterol absorption inhibitor for aggressive LDL lowering.",
            isScheduleH: true
        ))

        db.append(DrugEntry(
            id: "torsemide", brandName: "Dytor", genericName: "Torsemide",
            saltComposition: "Torsemide 10mg",
            category: .cardiovascular, manufacturer: "Cipla",
            commonDosages: ["5mg", "10mg", "20mg", "40mg", "100mg"], typicalDoseForm: "tablet",
            priceRange: "₹20-60",
            genericAlternatives: [
                GenericAlternative(brandName: "Torsinex", manufacturer: "Glenmark", priceRange: "₹15-45"),
                GenericAlternative(brandName: "Tide", manufacturer: "Lupin", priceRange: "₹12-40")
            ],
            foodInteractions: ["Take in the morning", "Eat potassium-rich foods"],
            commonSideEffects: ["Frequent urination", "Dizziness", "Dehydration", "Low potassium"],
            storageInstructions: "Store below 30°C.",
            description: "Loop diuretic, longer-acting than furosemide. For heart failure and edema.",
            isScheduleH: true
        ))

        db.append(DrugEntry(
            id: "ivabradine", brandName: "Coralan", genericName: "Ivabradine",
            saltComposition: "Ivabradine 5mg",
            category: .cardiovascular, manufacturer: "Serdia (Servier)",
            commonDosages: ["2.5mg", "5mg", "7.5mg"], typicalDoseForm: "tablet",
            priceRange: "₹100-250",
            genericAlternatives: [
                GenericAlternative(brandName: "Ivabid", manufacturer: "Cipla", priceRange: "₹60-150"),
                GenericAlternative(brandName: "Bradia", manufacturer: "Sun Pharma", priceRange: "₹55-140")
            ],
            foodInteractions: ["Take with meals"],
            commonSideEffects: ["Visual disturbances (phosphenes)", "Bradycardia", "Headache", "Dizziness"],
            storageInstructions: "Store below 25°C. Protect from light.",
            description: "Heart rate reducer for stable angina and heart failure. Not a beta-blocker.",
            isScheduleH: true
        ))

        db.append(DrugEntry(
            id: "sacubitril-valsartan", brandName: "Entresto", genericName: "Sacubitril + Valsartan",
            saltComposition: "Sacubitril 49mg + Valsartan 51mg",
            category: .cardiovascular, manufacturer: "Novartis",
            commonDosages: ["24/26mg", "49/51mg", "97/103mg"], typicalDoseForm: "tablet",
            priceRange: "₹300-600",
            genericAlternatives: [
                GenericAlternative(brandName: "Vymada", manufacturer: "Sun Pharma", priceRange: "₹200-400"),
                GenericAlternative(brandName: "Sacuval", manufacturer: "Cipla", priceRange: "₹180-380")
            ],
            foodInteractions: ["Can be taken with or without food", "Do not use with ACE inhibitors"],
            commonSideEffects: ["Hypotension", "Hyperkalemia", "Cough", "Dizziness", "Renal impairment"],
            storageInstructions: "Store below 30°C. Protect from moisture.",
            description: "ARNI for heart failure with reduced ejection fraction. Superior to ACE inhibitors.",
            isScheduleH: true
        ))

        db.append(DrugEntry(
            id: "cilnidipine", brandName: "Cilacar", genericName: "Cilnidipine",
            saltComposition: "Cilnidipine 10mg",
            category: .antihypertensive, manufacturer: "Sun Pharma",
            commonDosages: ["5mg", "10mg", "20mg"], typicalDoseForm: "tablet",
            priceRange: "₹60-130",
            genericAlternatives: [
                GenericAlternative(brandName: "Cilny", manufacturer: "USV", priceRange: "₹40-90"),
                GenericAlternative(brandName: "Cinod", manufacturer: "Cipla", priceRange: "₹35-80")
            ],
            foodInteractions: ["Take after food"],
            commonSideEffects: ["Headache", "Dizziness", "Flushing", "Palpitations"],
            storageInstructions: "Store below 30°C.",
            description: "N+L type calcium channel blocker. Less ankle oedema than amlodipine.",
            isScheduleH: true
        ))

        db.append(DrugEntry(
            id: "prazosin", brandName: "Minipress", genericName: "Prazosin",
            saltComposition: "Prazosin 2.5mg",
            category: .antihypertensive, manufacturer: "Pfizer",
            commonDosages: ["1mg", "2mg", "2.5mg", "5mg"], typicalDoseForm: "tablet",
            priceRange: "₹20-50",
            genericAlternatives: [
                GenericAlternative(brandName: "Prazopress", manufacturer: "Cipla", priceRange: "₹15-35")
            ],
            foodInteractions: ["Take at bedtime to avoid first-dose hypotension"],
            commonSideEffects: ["Dizziness", "Drowsiness", "Headache", "Palpitations", "First-dose syncope"],
            storageInstructions: "Store below 30°C.",
            description: "Alpha-blocker for hypertension. Used first-dose at bedtime due to orthostatic hypotension.",
            isScheduleH: true
        ))

        db.append(DrugEntry(
            id: "clonidine", brandName: "Arkamin", genericName: "Clonidine",
            saltComposition: "Clonidine 0.1mg",
            category: .antihypertensive, manufacturer: "Torrent",
            commonDosages: ["0.1mg", "0.2mg", "0.3mg"], typicalDoseForm: "tablet",
            priceRange: "₹10-30",
            genericAlternatives: [
                GenericAlternative(brandName: "Catapres", manufacturer: "Boehringer", priceRange: "₹15-40")
            ],
            foodInteractions: ["Can be taken with or without food", "Avoid alcohol"],
            commonSideEffects: ["Drowsiness", "Dry mouth", "Constipation", "Dizziness", "Rebound hypertension if stopped"],
            storageInstructions: "Store below 30°C.",
            description: "Central-acting antihypertensive. Do NOT stop abruptly.",
            isScheduleH: true
        ))

        db.append(DrugEntry(
            id: "trimetazidine", brandName: "Flavedon MR", genericName: "Trimetazidine",
            saltComposition: "Trimetazidine 35mg MR",
            category: .cardiovascular, manufacturer: "Serdia (Servier)",
            commonDosages: ["20mg", "35mg MR"], typicalDoseForm: "tablet",
            priceRange: "₹50-120",
            genericAlternatives: [
                GenericAlternative(brandName: "Trivedon", manufacturer: "Cipla", priceRange: "₹35-80"),
                GenericAlternative(brandName: "TMZ", manufacturer: "USV", priceRange: "₹30-70")
            ],
            foodInteractions: ["Take with meals"],
            commonSideEffects: ["Stomach pain", "Nausea", "Headache", "Dizziness"],
            storageInstructions: "Store below 30°C.",
            description: "Metabolic anti-ischemic agent for stable angina. Adjunct to standard therapy.",
            isScheduleH: true
        ))

        db.append(DrugEntry(
            id: "ranolazine", brandName: "Ranexa", genericName: "Ranolazine",
            saltComposition: "Ranolazine 500mg",
            category: .cardiovascular, manufacturer: "Sun Pharma",
            commonDosages: ["500mg", "1000mg"], typicalDoseForm: "tablet",
            priceRange: "₹100-220",
            genericAlternatives: [
                GenericAlternative(brandName: "Ranozex", manufacturer: "Cipla", priceRange: "₹70-160")
            ],
            foodInteractions: ["Can be taken with or without food", "Avoid grapefruit juice"],
            commonSideEffects: ["Dizziness", "Nausea", "Constipation", "Headache"],
            storageInstructions: "Store below 30°C.",
            description: "Anti-anginal for chronic stable angina when beta-blockers/CCBs are inadequate.",
            isScheduleH: true
        ))

        // ────────────────────────────────────────────
        // ANTIBIOTICS (EXPANDED)
        // ────────────────────────────────────────────

        db.append(DrugEntry(
            id: "amoxicillin-plain", brandName: "Novamox", genericName: "Amoxicillin",
            saltComposition: "Amoxicillin 500mg",
            category: .antibiotic, manufacturer: "Cipla",
            commonDosages: ["250mg", "500mg"], typicalDoseForm: "capsule",
            priceRange: "₹30-65",
            genericAlternatives: [
                GenericAlternative(brandName: "Mox", manufacturer: "Ranbaxy", priceRange: "₹25-55"),
                GenericAlternative(brandName: "Amoxil", manufacturer: "GSK", priceRange: "₹35-70")
            ],
            foodInteractions: ["Can be taken with or without food"],
            commonSideEffects: ["Diarrhoea", "Nausea", "Skin rash", "Vomiting"],
            storageInstructions: "Store below 25°C. Keep dry.",
            description: "Basic penicillin antibiotic for ear, throat, urinary, and respiratory infections.",
            isScheduleH: true
        ))

        db.append(DrugEntry(
            id: "cephalexin", brandName: "Sporidex", genericName: "Cephalexin",
            saltComposition: "Cephalexin 500mg",
            category: .antibiotic, manufacturer: "Sun Pharma",
            commonDosages: ["250mg", "500mg"], typicalDoseForm: "capsule",
            priceRange: "₹40-90",
            genericAlternatives: [
                GenericAlternative(brandName: "Phexin", manufacturer: "GSK", priceRange: "₹50-100"),
                GenericAlternative(brandName: "Keflex", manufacturer: "Various", priceRange: "₹35-80")
            ],
            foodInteractions: ["Can be taken with or without food"],
            commonSideEffects: ["Diarrhoea", "Nausea", "Stomach pain", "Headache", "Rash"],
            storageInstructions: "Store below 25°C.",
            description: "First-generation cephalosporin for skin, soft tissue, and urinary infections.",
            isScheduleH: true
        ))

        db.append(DrugEntry(
            id: "clindamycin", brandName: "Dalacin C", genericName: "Clindamycin",
            saltComposition: "Clindamycin 300mg",
            category: .antibiotic, manufacturer: "Pfizer",
            commonDosages: ["150mg", "300mg"], typicalDoseForm: "capsule",
            priceRange: "₹80-160",
            genericAlternatives: [
                GenericAlternative(brandName: "Clincin", manufacturer: "Cipla", priceRange: "₹60-120"),
                GenericAlternative(brandName: "Clindasol", manufacturer: "Sun Pharma", priceRange: "₹55-110")
            ],
            foodInteractions: ["Take with a full glass of water", "Can be taken with or without food"],
            commonSideEffects: ["Diarrhoea", "Nausea", "Abdominal pain", "C. difficile colitis (rare)", "Rash"],
            storageInstructions: "Store below 30°C.",
            description: "Lincosamide antibiotic for anaerobic and gram-positive infections. Good bone penetration.",
            isScheduleH: true
        ))

        db.append(DrugEntry(
            id: "cotrimoxazole", brandName: "Septran", genericName: "Cotrimoxazole (Sulfamethoxazole + Trimethoprim)",
            saltComposition: "Sulfamethoxazole 400mg + Trimethoprim 80mg",
            category: .antibiotic, manufacturer: "GSK",
            commonDosages: ["400/80mg", "800/160mg DS"], typicalDoseForm: "tablet",
            priceRange: "₹10-25",
            genericAlternatives: [
                GenericAlternative(brandName: "Bactrim", manufacturer: "Abbott", priceRange: "₹15-30"),
                GenericAlternative(brandName: "Oriprim", manufacturer: "Various", priceRange: "₹8-20")
            ],
            foodInteractions: ["Take with plenty of water", "Can be taken with or without food"],
            commonSideEffects: ["Nausea", "Vomiting", "Rash", "Photosensitivity", "Blood disorders (rare)"],
            storageInstructions: "Store below 30°C. Protect from light.",
            description: "Combination antibiotic for UTI, PCP, and various bacterial infections.",
            isScheduleH: true
        ))

        db.append(DrugEntry(
            id: "linezolid", brandName: "Lizolid", genericName: "Linezolid",
            saltComposition: "Linezolid 600mg",
            category: .antibiotic, manufacturer: "Glenmark",
            commonDosages: ["600mg"], typicalDoseForm: "tablet",
            priceRange: "₹150-350",
            genericAlternatives: [
                GenericAlternative(brandName: "Linospan", manufacturer: "Cipla", priceRange: "₹120-280"),
                GenericAlternative(brandName: "Linox", manufacturer: "Alkem", priceRange: "₹100-250")
            ],
            foodInteractions: ["Avoid tyramine-rich foods (aged cheese, cured meats, soy sauce)", "Can be taken with or without food"],
            commonSideEffects: ["Diarrhoea", "Nausea", "Headache", "Thrombocytopenia", "Peripheral neuropathy (prolonged use)"],
            storageInstructions: "Store below 30°C.",
            description: "Oxazolidinone antibiotic for MRSA and VRE infections. Reserve antibiotic.",
            isScheduleH: true
        ))

        db.append(DrugEntry(
            id: "meropenem", brandName: "Meronem", genericName: "Meropenem",
            saltComposition: "Meropenem 1g",
            category: .antibiotic, manufacturer: "AstraZeneca",
            commonDosages: ["500mg", "1g"], typicalDoseForm: "injection",
            priceRange: "₹300-700",
            genericAlternatives: [
                GenericAlternative(brandName: "Merosol", manufacturer: "Sun Pharma", priceRange: "₹200-500"),
                GenericAlternative(brandName: "Merofit", manufacturer: "Mankind", priceRange: "₹180-450")
            ],
            foodInteractions: ["Injectable — no direct food interactions"],
            commonSideEffects: ["Diarrhoea", "Nausea", "Headache", "Injection site inflammation", "Rash"],
            storageInstructions: "Store below 30°C. Use reconstituted solution promptly.",
            description: "Carbapenem antibiotic for severe multi-drug resistant infections. Last-line therapy.",
            isScheduleH: true
        ))

        db.append(DrugEntry(
            id: "cefpodoxime", brandName: "Cepodem", genericName: "Cefpodoxime",
            saltComposition: "Cefpodoxime Proxetil 200mg",
            category: .antibiotic, manufacturer: "Cipla",
            commonDosages: ["100mg", "200mg"], typicalDoseForm: "tablet",
            priceRange: "₹80-160",
            genericAlternatives: [
                GenericAlternative(brandName: "Cefoprox", manufacturer: "Sun Pharma", priceRange: "₹60-120"),
                GenericAlternative(brandName: "Podoxim", manufacturer: "Mankind", priceRange: "₹55-110")
            ],
            foodInteractions: ["Take with food for better absorption"],
            commonSideEffects: ["Diarrhoea", "Nausea", "Headache", "Abdominal pain", "Rash"],
            storageInstructions: "Store below 30°C.",
            description: "Third-generation oral cephalosporin for respiratory and urinary tract infections.",
            isScheduleH: true
        ))

        db.append(DrugEntry(
            id: "cefuroxime", brandName: "Ceftum", genericName: "Cefuroxime",
            saltComposition: "Cefuroxime Axetil 500mg",
            category: .antibiotic, manufacturer: "GSK",
            commonDosages: ["250mg", "500mg"], typicalDoseForm: "tablet",
            priceRange: "₹120-250",
            genericAlternatives: [
                GenericAlternative(brandName: "Altacef", manufacturer: "Orchid", priceRange: "₹80-170"),
                GenericAlternative(brandName: "Xima", manufacturer: "Cipla", priceRange: "₹75-160")
            ],
            foodInteractions: ["Take with food for better absorption"],
            commonSideEffects: ["Diarrhoea", "Nausea", "Headache", "Vomiting", "Rash"],
            storageInstructions: "Store below 30°C.",
            description: "Second-generation cephalosporin for ENT, respiratory, and urinary infections.",
            isScheduleH: true
        ))

        db.append(DrugEntry(
            id: "clarithromycin", brandName: "Claribid", genericName: "Clarithromycin",
            saltComposition: "Clarithromycin 500mg",
            category: .antibiotic, manufacturer: "Abbott",
            commonDosages: ["250mg", "500mg"], typicalDoseForm: "tablet",
            priceRange: "₹100-200",
            genericAlternatives: [
                GenericAlternative(brandName: "Biaxin", manufacturer: "Abbott", priceRange: "₹120-220"),
                GenericAlternative(brandName: "Klaricid", manufacturer: "Abbott", priceRange: "₹110-210")
            ],
            foodInteractions: ["Can be taken with or without food", "Avoid grapefruit juice"],
            commonSideEffects: ["Diarrhoea", "Nausea", "Abnormal taste", "Abdominal pain", "Headache"],
            storageInstructions: "Store below 30°C.",
            description: "Macrolide antibiotic for respiratory infections and H. pylori eradication.",
            isScheduleH: true
        ))

        db.append(DrugEntry(
            id: "norfloxacin", brandName: "Norflox", genericName: "Norfloxacin",
            saltComposition: "Norfloxacin 400mg",
            category: .antibiotic, manufacturer: "Cipla",
            commonDosages: ["400mg"], typicalDoseForm: "tablet",
            priceRange: "₹20-50",
            genericAlternatives: [
                GenericAlternative(brandName: "Uroflox", manufacturer: "Sun Pharma", priceRange: "₹15-40"),
                GenericAlternative(brandName: "Norbactin", manufacturer: "Various", priceRange: "₹12-35")
            ],
            foodInteractions: ["Take on empty stomach with plenty of water", "Avoid dairy and antacids"],
            commonSideEffects: ["Nausea", "Headache", "Dizziness", "Abdominal pain"],
            storageInstructions: "Store below 30°C. Protect from light.",
            description: "Fluoroquinolone for urinary tract and GI infections.",
            isScheduleH: true
        ))

        db.append(DrugEntry(
            id: "ornidazole", brandName: "Dazolic", genericName: "Ornidazole",
            saltComposition: "Ornidazole 500mg",
            category: .antibiotic, manufacturer: "Sun Pharma",
            commonDosages: ["500mg"], typicalDoseForm: "tablet",
            priceRange: "₹30-70",
            genericAlternatives: [
                GenericAlternative(brandName: "Ornof", manufacturer: "Cipla", priceRange: "₹25-55"),
                GenericAlternative(brandName: "Orniday", manufacturer: "Mankind", priceRange: "₹20-50")
            ],
            foodInteractions: ["Take with food", "Avoid alcohol"],
            commonSideEffects: ["Nausea", "Headache", "Dizziness", "Metallic taste", "Drowsiness"],
            storageInstructions: "Store below 30°C.",
            description: "Nitroimidazole for anaerobic and protozoal infections. Alternative to metronidazole.",
            isScheduleH: true
        ))

        db.append(DrugEntry(
            id: "tinidazole", brandName: "Fasigyn", genericName: "Tinidazole",
            saltComposition: "Tinidazole 500mg",
            category: .antibiotic, manufacturer: "Pfizer",
            commonDosages: ["300mg", "500mg"], typicalDoseForm: "tablet",
            priceRange: "₹15-35",
            genericAlternatives: [
                GenericAlternative(brandName: "Tiniba", manufacturer: "Zydus", priceRange: "₹10-25"),
                GenericAlternative(brandName: "Tinvista", manufacturer: "Various", priceRange: "₹8-22")
            ],
            foodInteractions: ["Take with food", "Strictly avoid alcohol for 72 hours after course"],
            commonSideEffects: ["Metallic taste", "Nausea", "Headache", "Dizziness"],
            storageInstructions: "Store below 30°C.",
            description: "Antiprotozoal for amoebiasis, giardiasis, and trichomoniasis.",
            isScheduleH: true
        ))

        db.append(DrugEntry(
            id: "ofloxacin-ornidazole", brandName: "O2", genericName: "Ofloxacin + Ornidazole",
            saltComposition: "Ofloxacin 200mg + Ornidazole 500mg",
            category: .antibiotic, manufacturer: "Cipla",
            commonDosages: ["200/500mg"], typicalDoseForm: "tablet",
            priceRange: "₹40-90",
            genericAlternatives: [
                GenericAlternative(brandName: "Zenflox-OZ", manufacturer: "Mankind", priceRange: "₹30-70"),
                GenericAlternative(brandName: "Normet", manufacturer: "Sun Pharma", priceRange: "₹25-60")
            ],
            foodInteractions: ["Take after food", "Avoid dairy and antacids within 2 hours", "Avoid alcohol"],
            commonSideEffects: ["Nausea", "Diarrhoea", "Headache", "Dizziness", "Metallic taste"],
            storageInstructions: "Store below 30°C.",
            description: "Antibiotic + antiprotozoal combination for diarrhoea, dysentery, and GI infections.",
            isScheduleH: true
        ))

        db.append(DrugEntry(
            id: "rifaximin", brandName: "Rcifax", genericName: "Rifaximin",
            saltComposition: "Rifaximin 400mg",
            category: .antibiotic, manufacturer: "Sun Pharma",
            commonDosages: ["200mg", "400mg", "550mg"], typicalDoseForm: "tablet",
            priceRange: "₹80-200",
            genericAlternatives: [
                GenericAlternative(brandName: "Rifagut", manufacturer: "Sun Pharma", priceRange: "₹70-180"),
                GenericAlternative(brandName: "Xifaxan", manufacturer: "Salix", priceRange: "₹120-250")
            ],
            foodInteractions: ["Can be taken with or without food"],
            commonSideEffects: ["Nausea", "Abdominal pain", "Flatulence", "Headache"],
            storageInstructions: "Store below 30°C.",
            description: "Non-absorbable antibiotic for traveller's diarrhoea and hepatic encephalopathy.",
            isScheduleH: true
        ))

        // ────────────────────────────────────────────
        // GI / ACID (EXPANDED)
        // ────────────────────────────────────────────

        db.append(DrugEntry(
            id: "esomeprazole", brandName: "Neksium", genericName: "Esomeprazole",
            saltComposition: "Esomeprazole 40mg",
            category: .antiAcid, manufacturer: "AstraZeneca",
            commonDosages: ["20mg", "40mg"], typicalDoseForm: "capsule",
            priceRange: "₹80-160",
            genericAlternatives: [
                GenericAlternative(brandName: "Sompraz", manufacturer: "Sun Pharma", priceRange: "₹50-100"),
                GenericAlternative(brandName: "Raciper", manufacturer: "Cipla", priceRange: "₹45-90")
            ],
            foodInteractions: ["Take on empty stomach, 30-60 min before meals"],
            commonSideEffects: ["Headache", "Diarrhoea", "Nausea", "Abdominal pain", "Flatulence"],
            storageInstructions: "Store below 30°C.",
            description: "S-isomer of omeprazole PPI. For GERD, ulcers, and erosive esophagitis.",
            isScheduleH: true
        ))

        db.append(DrugEntry(
            id: "pan-d", brandName: "Pan-D", genericName: "Pantoprazole + Domperidone",
            saltComposition: "Pantoprazole 40mg + Domperidone 30mg SR",
            category: .antiAcid, manufacturer: "Alkem",
            commonDosages: ["40/30mg"], typicalDoseForm: "capsule",
            priceRange: "₹60-120",
            genericAlternatives: [
                GenericAlternative(brandName: "Pantop-D", manufacturer: "Aristo", priceRange: "₹50-100"),
                GenericAlternative(brandName: "P2", manufacturer: "Cipla", priceRange: "₹45-90")
            ],
            foodInteractions: ["Take on empty stomach, before meals"],
            commonSideEffects: ["Headache", "Diarrhoea", "Dry mouth", "Abdominal pain"],
            storageInstructions: "Store below 30°C.",
            description: "PPI + prokinetic combination for GERD with bloating and nausea.",
            isScheduleH: true
        ))

        db.append(DrugEntry(
            id: "sucralfate", brandName: "Sucrafil", genericName: "Sucralfate",
            saltComposition: "Sucralfate 1g",
            category: .antiAcid, manufacturer: "Sun Pharma",
            commonDosages: ["500mg", "1g"], typicalDoseForm: "tablet",
            priceRange: "₹30-70",
            genericAlternatives: [
                GenericAlternative(brandName: "Ulcigard", manufacturer: "Cipla", priceRange: "₹25-55"),
                GenericAlternative(brandName: "Sucral", manufacturer: "Various", priceRange: "₹20-45")
            ],
            foodInteractions: ["Take on empty stomach, 1 hour before meals", "Separate from other medicines by 2 hours"],
            commonSideEffects: ["Constipation", "Dry mouth", "Nausea", "Stomach discomfort"],
            storageInstructions: "Store below 30°C.",
            description: "Mucosal protectant for gastric and duodenal ulcers.",
            isScheduleH: true
        ))

        db.append(DrugEntry(
            id: "antacid-gel", brandName: "Digene", genericName: "Aluminium Hydroxide + Magnesium Hydroxide",
            saltComposition: "Dried Aluminium Hydroxide Gel + Magnesium Hydroxide + Simethicone",
            category: .antiAcid, manufacturer: "Abbott",
            commonDosages: ["Standard"], typicalDoseForm: "syrup/tablet",
            priceRange: "₹40-80",
            genericAlternatives: [
                GenericAlternative(brandName: "Gelusil MPS", manufacturer: "Pfizer", priceRange: "₹35-70"),
                GenericAlternative(brandName: "Mucaine", manufacturer: "Abbott", priceRange: "₹50-95")
            ],
            foodInteractions: ["Take after meals and at bedtime"],
            commonSideEffects: ["Constipation (aluminium)", "Diarrhoea (magnesium)", "Belching"],
            storageInstructions: "Store below 30°C. Shake well before use.",
            description: "OTC antacid for heartburn, acidity, and gas. Immediate symptomatic relief.",
            isScheduleH: false
        ))

        db.append(DrugEntry(
            id: "loperamide", brandName: "Eldoper", genericName: "Loperamide",
            saltComposition: "Loperamide 2mg",
            category: .antiAcid, manufacturer: "Elder",
            commonDosages: ["2mg"], typicalDoseForm: "capsule",
            priceRange: "₹15-35",
            genericAlternatives: [
                GenericAlternative(brandName: "Imodium", manufacturer: "Johnson & Johnson", priceRange: "₹20-45"),
                GenericAlternative(brandName: "Lopamide", manufacturer: "Cipla", priceRange: "₹12-28")
            ],
            foodInteractions: ["Can be taken with or without food", "Drink plenty of fluids"],
            commonSideEffects: ["Constipation", "Abdominal cramps", "Dizziness", "Nausea"],
            storageInstructions: "Store below 30°C.",
            description: "Anti-diarrheal for acute non-infectious diarrhoea. Not for dysentery.",
            isScheduleH: false
        ))

        db.append(DrugEntry(
            id: "ors", brandName: "Electral", genericName: "ORS (Oral Rehydration Salts)",
            saltComposition: "Sodium Chloride + Potassium Chloride + Sodium Citrate + Glucose",
            category: .antiAcid, manufacturer: "FDC",
            commonDosages: ["Standard sachet"], typicalDoseForm: "powder",
            priceRange: "₹15-30",
            genericAlternatives: [
                GenericAlternative(brandName: "Enerzal", manufacturer: "FDC", priceRange: "₹20-40"),
                GenericAlternative(brandName: "Walyte", manufacturer: "Wallace", priceRange: "₹12-25")
            ],
            foodInteractions: ["Dissolve in 1 litre of clean water", "Sip frequently"],
            commonSideEffects: ["Vomiting (if drunk too fast)", "Generally very safe"],
            storageInstructions: "Store below 30°C. Use within 24 hours of preparation.",
            description: "WHO-formula oral rehydration for diarrhoea-related dehydration. Essential medicine.",
            isScheduleH: false
        ))

        db.append(DrugEntry(
            id: "lactulose", brandName: "Duphalac", genericName: "Lactulose",
            saltComposition: "Lactulose 3.35g/5ml",
            category: .antiAcid, manufacturer: "Abbott",
            commonDosages: ["10ml", "15ml", "30ml"], typicalDoseForm: "syrup",
            priceRange: "₹80-180",
            genericAlternatives: [
                GenericAlternative(brandName: "Laxolac", manufacturer: "Sun Pharma", priceRange: "₹55-120"),
                GenericAlternative(brandName: "Looz", manufacturer: "Various", priceRange: "₹50-110")
            ],
            foodInteractions: ["Can be taken with or without food", "Drink plenty of water"],
            commonSideEffects: ["Bloating", "Flatulence", "Abdominal cramps", "Diarrhoea (high doses)"],
            storageInstructions: "Store below 30°C. Do not freeze.",
            description: "Osmotic laxative for constipation and hepatic encephalopathy.",
            isScheduleH: false
        ))

        db.append(DrugEntry(
            id: "bisacodyl", brandName: "Dulcolax", genericName: "Bisacodyl",
            saltComposition: "Bisacodyl 5mg",
            category: .antiAcid, manufacturer: "Sanofi",
            commonDosages: ["5mg", "10mg"], typicalDoseForm: "tablet",
            priceRange: "₹10-25",
            genericAlternatives: [
                GenericAlternative(brandName: "Bicolax", manufacturer: "Various", priceRange: "₹8-18")
            ],
            foodInteractions: ["Take at bedtime", "Do not take with milk or antacids", "Do not crush"],
            commonSideEffects: ["Abdominal cramps", "Diarrhoea", "Nausea"],
            storageInstructions: "Store below 30°C.",
            description: "Stimulant laxative for constipation and bowel preparation.",
            isScheduleH: false
        ))

        db.append(DrugEntry(
            id: "esomeprazole-20", brandName: "Sompraz 20", genericName: "Esomeprazole",
            saltComposition: "Esomeprazole 20mg",
            category: .antiAcid, manufacturer: "Sun Pharma",
            commonDosages: ["20mg"], typicalDoseForm: "capsule",
            priceRange: "₹50-100",
            genericAlternatives: [
                GenericAlternative(brandName: "Raciper 20", manufacturer: "Cipla", priceRange: "₹35-70"),
                GenericAlternative(brandName: "Neksium 20", manufacturer: "AstraZeneca", priceRange: "₹60-120")
            ],
            foodInteractions: ["Take on empty stomach, before breakfast"],
            commonSideEffects: ["Headache", "Nausea", "Diarrhoea", "Abdominal pain"],
            storageInstructions: "Store below 30°C.",
            description: "Lower-dose esomeprazole for mild GERD and maintenance therapy.",
            isScheduleH: true
        ))

        db.append(DrugEntry(
            id: "drotaverine", brandName: "Drotin", genericName: "Drotaverine",
            saltComposition: "Drotaverine 40mg",
            category: .other, manufacturer: "Walter Bushnell",
            commonDosages: ["40mg", "80mg"], typicalDoseForm: "tablet",
            priceRange: "₹20-50",
            genericAlternatives: [
                GenericAlternative(brandName: "Meftal-Spas", manufacturer: "Blue Cross", priceRange: "₹25-55"),
                GenericAlternative(brandName: "Spasmo", manufacturer: "Various", priceRange: "₹15-35")
            ],
            foodInteractions: ["Can be taken with or without food"],
            commonSideEffects: ["Nausea", "Dizziness", "Headache", "Palpitations"],
            storageInstructions: "Store below 30°C.",
            description: "Antispasmodic for abdominal cramps, menstrual pain, and renal colic.",
            isScheduleH: true
        ))

        db.append(DrugEntry(
            id: "dicyclomine", brandName: "Cyclopam", genericName: "Dicyclomine",
            saltComposition: "Dicyclomine 20mg",
            category: .other, manufacturer: "Sun Pharma",
            commonDosages: ["10mg", "20mg"], typicalDoseForm: "tablet",
            priceRange: "₹15-35",
            genericAlternatives: [
                GenericAlternative(brandName: "Colimex", manufacturer: "Abbott", priceRange: "₹18-40"),
                GenericAlternative(brandName: "Spas", manufacturer: "Various", priceRange: "₹12-28")
            ],
            foodInteractions: ["Take 30 minutes before meals"],
            commonSideEffects: ["Dry mouth", "Drowsiness", "Blurred vision", "Constipation"],
            storageInstructions: "Store below 30°C.",
            description: "Anticholinergic antispasmodic for IBS, abdominal cramps, and colic.",
            isScheduleH: true
        ))

        // ────────────────────────────────────────────
        // PAIN / ANTI-INFLAMMATORY (EXPANDED)
        // ────────────────────────────────────────────

        db.append(DrugEntry(
            id: "naproxen", brandName: "Naprosyn", genericName: "Naproxen",
            saltComposition: "Naproxen 250mg",
            category: .analgesic, manufacturer: "RPG Life Sciences",
            commonDosages: ["250mg", "500mg"], typicalDoseForm: "tablet",
            priceRange: "₹25-60",
            genericAlternatives: [
                GenericAlternative(brandName: "Naxdom", manufacturer: "Mankind", priceRange: "₹18-45"),
                GenericAlternative(brandName: "Napra-D", manufacturer: "Various", priceRange: "₹15-40")
            ],
            foodInteractions: ["Take with food to reduce stomach upset", "Avoid alcohol"],
            commonSideEffects: ["Stomach pain", "Heartburn", "Nausea", "Headache", "Dizziness"],
            storageInstructions: "Store below 30°C.",
            description: "Long-acting NSAID for arthritis, menstrual pain, and musculoskeletal conditions.",
            isScheduleH: true
        ))

        db.append(DrugEntry(
            id: "tramadol", brandName: "Ultram", genericName: "Tramadol",
            saltComposition: "Tramadol 50mg",
            category: .analgesic, manufacturer: "Various",
            commonDosages: ["50mg", "100mg"], typicalDoseForm: "capsule",
            priceRange: "₹20-50",
            genericAlternatives: [
                GenericAlternative(brandName: "Tramazac", manufacturer: "Zydus", priceRange: "₹15-40"),
                GenericAlternative(brandName: "Contramal", manufacturer: "Abbott", priceRange: "₹25-55")
            ],
            foodInteractions: ["Can be taken with or without food", "Avoid alcohol strictly"],
            commonSideEffects: ["Nausea", "Dizziness", "Drowsiness", "Constipation", "Headache"],
            storageInstructions: "Store below 30°C.",
            description: "Opioid analgesic for moderate to severe pain. Controlled substance — dependence risk.",
            isScheduleH: true
        ))

        db.append(DrugEntry(
            id: "piroxicam", brandName: "Pirox", genericName: "Piroxicam",
            saltComposition: "Piroxicam 20mg",
            category: .analgesic, manufacturer: "Various",
            commonDosages: ["10mg", "20mg"], typicalDoseForm: "capsule",
            priceRange: "₹15-35",
            genericAlternatives: [
                GenericAlternative(brandName: "Dolonex", manufacturer: "Pfizer", priceRange: "₹20-45"),
                GenericAlternative(brandName: "Piroxicam-DT", manufacturer: "Various", priceRange: "₹12-28")
            ],
            foodInteractions: ["Take with food", "Avoid alcohol"],
            commonSideEffects: ["Stomach pain", "Nausea", "Dizziness", "Headache", "Oedema"],
            storageInstructions: "Store below 30°C.",
            description: "Long-acting NSAID for arthritis and musculoskeletal pain. Once-daily dosing.",
            isScheduleH: true
        ))

        db.append(DrugEntry(
            id: "etoricoxib", brandName: "Nucoxia", genericName: "Etoricoxib",
            saltComposition: "Etoricoxib 90mg",
            category: .analgesic, manufacturer: "Dr. Reddy's",
            commonDosages: ["60mg", "90mg", "120mg"], typicalDoseForm: "tablet",
            priceRange: "₹80-180",
            genericAlternatives: [
                GenericAlternative(brandName: "Etody", manufacturer: "Mankind", priceRange: "₹50-120"),
                GenericAlternative(brandName: "Etoxib", manufacturer: "Sun Pharma", priceRange: "₹45-110")
            ],
            foodInteractions: ["Can be taken with or without food"],
            commonSideEffects: ["Headache", "Dizziness", "Hypertension", "Oedema", "Heartburn"],
            storageInstructions: "Store below 30°C.",
            description: "Selective COX-2 inhibitor for arthritis, gout, and dental pain. Less GI side effects.",
            isScheduleH: true
        ))

        db.append(DrugEntry(
            id: "nimesulide", brandName: "Nimulid", genericName: "Nimesulide",
            saltComposition: "Nimesulide 100mg",
            category: .analgesic, manufacturer: "Panacea Biotec",
            commonDosages: ["100mg"], typicalDoseForm: "tablet",
            priceRange: "₹15-35",
            genericAlternatives: [
                GenericAlternative(brandName: "Nice", manufacturer: "Micro Labs", priceRange: "₹12-28"),
                GenericAlternative(brandName: "Nise", manufacturer: "Dr. Reddy's", priceRange: "₹10-25")
            ],
            foodInteractions: ["Take after food", "Avoid alcohol"],
            commonSideEffects: ["Stomach pain", "Nausea", "Diarrhoea", "Headache", "Liver toxicity (rare)"],
            storageInstructions: "Store below 30°C.",
            description: "NSAID for pain and fever. Restricted to max 15 days use. Not for children under 12.",
            isScheduleH: true
        ))

        db.append(DrugEntry(
            id: "zerodol-sp", brandName: "Zerodol-SP", genericName: "Aceclofenac + Paracetamol + Serratiopeptidase",
            saltComposition: "Aceclofenac 100mg + Paracetamol 325mg + Serratiopeptidase 15mg",
            category: .analgesic, manufacturer: "Ipca Laboratories",
            commonDosages: ["Standard"], typicalDoseForm: "tablet",
            priceRange: "₹50-100",
            genericAlternatives: [
                GenericAlternative(brandName: "Hifenac-SP", manufacturer: "Intas", priceRange: "₹35-70"),
                GenericAlternative(brandName: "Ace-Proxyvon SP", manufacturer: "Wockhardt", priceRange: "₹40-80")
            ],
            foodInteractions: ["Take after food"],
            commonSideEffects: ["Stomach pain", "Nausea", "Diarrhoea", "Dizziness"],
            storageInstructions: "Store below 30°C.",
            description: "Triple-action pain relief: anti-inflammatory + analgesic + anti-swelling enzyme.",
            isScheduleH: true
        ))

        db.append(DrugEntry(
            id: "diclofenac-gel", brandName: "Voveran Emulgel", genericName: "Diclofenac",
            saltComposition: "Diclofenac Diethylamine 1.16%",
            category: .analgesic, manufacturer: "Novartis",
            commonDosages: ["1.16%"], typicalDoseForm: "gel",
            priceRange: "₹50-100",
            genericAlternatives: [
                GenericAlternative(brandName: "Dynapar QPS", manufacturer: "Troikaa", priceRange: "₹45-85"),
                GenericAlternative(brandName: "Voltaren Emulgel", manufacturer: "GSK", priceRange: "₹60-110")
            ],
            foodInteractions: ["Topical — no food interactions"],
            commonSideEffects: ["Skin irritation", "Redness", "Rash", "Itching"],
            storageInstructions: "Store below 30°C.",
            description: "Topical NSAID gel for localized joint and muscle pain.",
            isScheduleH: false
        ))

        db.append(DrugEntry(
            id: "aceclofenac-para", brandName: "Zerodol-P", genericName: "Aceclofenac + Paracetamol",
            saltComposition: "Aceclofenac 100mg + Paracetamol 325mg",
            category: .analgesic, manufacturer: "Ipca Laboratories",
            commonDosages: ["100/325mg"], typicalDoseForm: "tablet",
            priceRange: "₹30-70",
            genericAlternatives: [
                GenericAlternative(brandName: "Hifenac-P", manufacturer: "Intas", priceRange: "₹22-50"),
                GenericAlternative(brandName: "Acemiz-P", manufacturer: "Lupin", priceRange: "₹20-45")
            ],
            foodInteractions: ["Take after food", "Avoid alcohol"],
            commonSideEffects: ["Stomach pain", "Nausea", "Diarrhoea", "Dizziness"],
            storageInstructions: "Store below 30°C.",
            description: "NSAID + paracetamol combination for pain, inflammation, and fever.",
            isScheduleH: true
        ))

        db.append(DrugEntry(
            id: "mefenamic-acid", brandName: "Meftal", genericName: "Mefenamic Acid",
            saltComposition: "Mefenamic Acid 500mg",
            category: .analgesic, manufacturer: "Blue Cross",
            commonDosages: ["250mg", "500mg"], typicalDoseForm: "tablet",
            priceRange: "₹20-45",
            genericAlternatives: [
                GenericAlternative(brandName: "Ponstan", manufacturer: "Pfizer", priceRange: "₹25-50"),
                GenericAlternative(brandName: "Meftal Spas", manufacturer: "Blue Cross", priceRange: "₹25-55")
            ],
            foodInteractions: ["Take with food", "Avoid alcohol"],
            commonSideEffects: ["Stomach pain", "Nausea", "Diarrhoea", "Headache", "Dizziness"],
            storageInstructions: "Store below 30°C.",
            description: "NSAID particularly popular for menstrual pain (dysmenorrhoea).",
            isScheduleH: true
        ))

        db.append(DrugEntry(
            id: "trypsin-chymotrypsin", brandName: "Chymoral Forte", genericName: "Trypsin + Chymotrypsin",
            saltComposition: "Trypsin 48mg + Chymotrypsin 2mg",
            category: .analgesic, manufacturer: "Torrent",
            commonDosages: ["Standard"], typicalDoseForm: "tablet",
            priceRange: "₹50-100",
            genericAlternatives: [
                GenericAlternative(brandName: "Enzomac", manufacturer: "Macleods", priceRange: "₹35-70")
            ],
            foodInteractions: ["Take on empty stomach for best absorption"],
            commonSideEffects: ["Nausea", "Diarrhoea", "Allergic reactions (rare)"],
            storageInstructions: "Store below 30°C.",
            description: "Proteolytic enzymes to reduce post-operative/post-injury swelling and inflammation.",
            isScheduleH: true
        ))

        // ────────────────────────────────────────────
        // RESPIRATORY (EXPANDED)
        // ────────────────────────────────────────────

        db.append(DrugEntry(
            id: "salbutamol-oral", brandName: "Asthalin", genericName: "Salbutamol",
            saltComposition: "Salbutamol 2mg",
            category: .respiratory, manufacturer: "Cipla",
            commonDosages: ["2mg", "4mg"], typicalDoseForm: "tablet",
            priceRange: "₹15-30",
            genericAlternatives: [
                GenericAlternative(brandName: "Salbetol", manufacturer: "Various", priceRange: "₹10-22")
            ],
            foodInteractions: ["Can be taken with or without food"],
            commonSideEffects: ["Tremor", "Palpitations", "Headache", "Muscle cramps"],
            storageInstructions: "Store below 30°C.",
            description: "Oral bronchodilator for mild asthma and wheezing.",
            isScheduleH: true
        ))

        db.append(DrugEntry(
            id: "theophylline", brandName: "Theodrip", genericName: "Theophylline",
            saltComposition: "Theophylline 200mg",
            category: .respiratory, manufacturer: "Cipla",
            commonDosages: ["100mg", "200mg", "300mg", "400mg SR"], typicalDoseForm: "tablet",
            priceRange: "₹15-40",
            genericAlternatives: [
                GenericAlternative(brandName: "Uniphyllin", manufacturer: "Various", priceRange: "₹12-35")
            ],
            foodInteractions: ["Avoid caffeine — additive effects", "Take consistently with or without food"],
            commonSideEffects: ["Nausea", "Palpitations", "Insomnia", "Headache", "Tremor"],
            storageInstructions: "Store below 30°C.",
            description: "Methylxanthine bronchodilator for asthma and COPD. Narrow therapeutic index.",
            isScheduleH: true
        ))

        db.append(DrugEntry(
            id: "dextromethorphan", brandName: "Benylin", genericName: "Dextromethorphan",
            saltComposition: "Dextromethorphan 10mg/5ml",
            category: .respiratory, manufacturer: "Johnson & Johnson",
            commonDosages: ["5ml", "10ml"], typicalDoseForm: "syrup",
            priceRange: "₹40-80",
            genericAlternatives: [
                GenericAlternative(brandName: "Tusq-DX", manufacturer: "Micro Labs", priceRange: "₹30-60"),
                GenericAlternative(brandName: "Zedex", manufacturer: "Wockhardt", priceRange: "₹35-65")
            ],
            foodInteractions: ["Can be taken with or without food"],
            commonSideEffects: ["Drowsiness", "Dizziness", "Nausea", "Stomach upset"],
            storageInstructions: "Store below 30°C.",
            description: "Non-narcotic cough suppressant (antitussive) for dry cough.",
            isScheduleH: false
        ))

        db.append(DrugEntry(
            id: "ambroxol", brandName: "Ambrodil", genericName: "Ambroxol",
            saltComposition: "Ambroxol Hydrochloride 30mg",
            category: .respiratory, manufacturer: "Aristo",
            commonDosages: ["15mg", "30mg", "75mg SR"], typicalDoseForm: "tablet/syrup",
            priceRange: "₹20-50",
            genericAlternatives: [
                GenericAlternative(brandName: "Mucolite", manufacturer: "Sun Pharma", priceRange: "₹15-40"),
                GenericAlternative(brandName: "Ambrolite", manufacturer: "Various", priceRange: "₹12-30")
            ],
            foodInteractions: ["Take after meals"],
            commonSideEffects: ["Nausea", "Diarrhoea", "Stomach upset", "Allergic reactions (rare)"],
            storageInstructions: "Store below 30°C.",
            description: "Mucolytic for productive cough — thins mucus for easier expulsion.",
            isScheduleH: false
        ))

        db.append(DrugEntry(
            id: "guaifenesin", brandName: "Glycodin", genericName: "Guaifenesin",
            saltComposition: "Guaifenesin 100mg/5ml",
            category: .respiratory, manufacturer: "FDC",
            commonDosages: ["5ml", "10ml"], typicalDoseForm: "syrup",
            priceRange: "₹30-60",
            genericAlternatives: [
                GenericAlternative(brandName: "Ascoril", manufacturer: "Glenmark", priceRange: "₹60-120"),
                GenericAlternative(brandName: "Grilinctus", manufacturer: "Franco-Indian", priceRange: "₹40-80")
            ],
            foodInteractions: ["Drink plenty of water"],
            commonSideEffects: ["Nausea", "Vomiting", "Stomach pain", "Drowsiness"],
            storageInstructions: "Store below 30°C.",
            description: "Expectorant to loosen and thin mucus in productive cough.",
            isScheduleH: false
        ))

        db.append(DrugEntry(
            id: "ipratropium", brandName: "Ipravent", genericName: "Ipratropium Bromide",
            saltComposition: "Ipratropium Bromide 20mcg/puff",
            category: .respiratory, manufacturer: "Cipla",
            commonDosages: ["20mcg", "40mcg", "500mcg nebuliser"], typicalDoseForm: "inhaler",
            priceRange: "₹80-160",
            genericAlternatives: [
                GenericAlternative(brandName: "Atrovent", manufacturer: "Boehringer", priceRange: "₹100-200")
            ],
            foodInteractions: ["No food interactions"],
            commonSideEffects: ["Dry mouth", "Cough", "Headache", "Nausea"],
            storageInstructions: "Store below 30°C.",
            description: "Anticholinergic bronchodilator for COPD and severe asthma.",
            isScheduleH: true
        ))

        db.append(DrugEntry(
            id: "tiotropium", brandName: "Tiova", genericName: "Tiotropium",
            saltComposition: "Tiotropium Bromide 18mcg",
            category: .respiratory, manufacturer: "Cipla",
            commonDosages: ["9mcg", "18mcg"], typicalDoseForm: "inhaler",
            priceRange: "₹200-450",
            genericAlternatives: [
                GenericAlternative(brandName: "Spiriva", manufacturer: "Boehringer", priceRange: "₹350-650"),
                GenericAlternative(brandName: "Breva", manufacturer: "Sun Pharma", priceRange: "₹180-380")
            ],
            foodInteractions: ["No food interactions", "Rinse mouth after inhalation"],
            commonSideEffects: ["Dry mouth", "Constipation", "Urinary retention", "Cough"],
            storageInstructions: "Store below 30°C. Protect from moisture.",
            description: "Long-acting anticholinergic inhaler for COPD maintenance.",
            isScheduleH: true
        ))

        db.append(DrugEntry(
            id: "fluticasone-nasal", brandName: "Flonase", genericName: "Fluticasone",
            saltComposition: "Fluticasone Propionate 50mcg/spray",
            category: .respiratory, manufacturer: "GSK",
            commonDosages: ["50mcg/spray"], typicalDoseForm: "nasal spray",
            priceRange: "₹150-300",
            genericAlternatives: [
                GenericAlternative(brandName: "Fluticone", manufacturer: "Cipla", priceRange: "₹100-200"),
                GenericAlternative(brandName: "Flutivate", manufacturer: "Sun Pharma", priceRange: "₹90-180")
            ],
            foodInteractions: ["No food interactions"],
            commonSideEffects: ["Nasal irritation", "Nosebleed", "Headache", "Throat irritation"],
            storageInstructions: "Store below 30°C. Shake well before use.",
            description: "Intranasal corticosteroid for allergic rhinitis and nasal polyps.",
            isScheduleH: true
        ))

        db.append(DrugEntry(
            id: "montelukast-lc", brandName: "Montek-LC", genericName: "Montelukast + Levocetirizine",
            saltComposition: "Montelukast 10mg + Levocetirizine 5mg",
            category: .respiratory, manufacturer: "Sun Pharma",
            commonDosages: ["10/5mg"], typicalDoseForm: "tablet",
            priceRange: "₹80-140",
            genericAlternatives: [
                GenericAlternative(brandName: "Montair LC", manufacturer: "Cipla", priceRange: "₹100-180"),
                GenericAlternative(brandName: "L-Montus", manufacturer: "Glenmark", priceRange: "₹70-130")
            ],
            foodInteractions: ["Take in the evening", "Avoid alcohol"],
            commonSideEffects: ["Drowsiness", "Headache", "Dry mouth", "Fatigue"],
            storageInstructions: "Store below 30°C.",
            description: "Combination for allergic rhinitis and asthma symptoms.",
            isScheduleH: true
        ))

        // ────────────────────────────────────────────
        // THYROID (EXPANDED)
        // ────────────────────────────────────────────

        db.append(DrugEntry(
            id: "thyrox", brandName: "Thyrox", genericName: "Levothyroxine",
            saltComposition: "Levothyroxine Sodium 50mcg",
            category: .thyroid, manufacturer: "Macleods",
            commonDosages: ["12.5mcg", "25mcg", "50mcg", "75mcg", "100mcg", "125mcg", "150mcg"], typicalDoseForm: "tablet",
            priceRange: "₹60-110",
            genericAlternatives: [
                GenericAlternative(brandName: "Thyronorm", manufacturer: "Abbott", priceRange: "₹80-150"),
                GenericAlternative(brandName: "Eltroxin", manufacturer: "GSK", priceRange: "₹90-160")
            ],
            foodInteractions: ["Take on empty stomach, 30-60 min before breakfast",
                              "Avoid calcium, iron, antacids within 4 hours"],
            commonSideEffects: ["Palpitations (if overdosed)", "Weight changes", "Tremor", "Insomnia"],
            storageInstructions: "Store below 25°C. Protect from light.",
            description: "Affordable levothyroxine brand for hypothyroidism.",
            isScheduleH: true
        ))

        db.append(DrugEntry(
            id: "carbimazole", brandName: "Neo-Mercazole", genericName: "Carbimazole",
            saltComposition: "Carbimazole 5mg",
            category: .thyroid, manufacturer: "Abbott",
            commonDosages: ["5mg", "10mg", "20mg"], typicalDoseForm: "tablet",
            priceRange: "₹20-50",
            genericAlternatives: [
                GenericAlternative(brandName: "Thyrocab", manufacturer: "Abbott", priceRange: "₹15-40"),
                GenericAlternative(brandName: "CBZ", manufacturer: "Various", priceRange: "₹12-30")
            ],
            foodInteractions: ["Can be taken with or without food"],
            commonSideEffects: ["Nausea", "Rash", "Joint pain", "Agranulocytosis (rare but serious)", "Headache"],
            storageInstructions: "Store below 30°C.",
            description: "Antithyroid drug for hyperthyroidism (Graves' disease). Regular blood tests needed.",
            isScheduleH: true
        ))

        db.append(DrugEntry(
            id: "propylthiouracil", brandName: "PTU", genericName: "Propylthiouracil",
            saltComposition: "Propylthiouracil 50mg",
            category: .thyroid, manufacturer: "Various",
            commonDosages: ["50mg", "100mg"], typicalDoseForm: "tablet",
            priceRange: "₹15-35",
            genericAlternatives: [],
            foodInteractions: ["Can be taken with or without food"],
            commonSideEffects: ["Nausea", "Rash", "Liver toxicity (rare)", "Agranulocytosis (rare)", "Joint pain"],
            storageInstructions: "Store below 30°C.",
            description: "Antithyroid drug, preferred in first trimester of pregnancy and thyroid storm.",
            isScheduleH: true
        ))

        // ────────────────────────────────────────────
        // MENTAL HEALTH (EXPANDED)
        // ────────────────────────────────────────────

        db.append(DrugEntry(
            id: "sertraline", brandName: "Daxid", genericName: "Sertraline",
            saltComposition: "Sertraline Hydrochloride 50mg",
            category: .antiDepressant, manufacturer: "Pfizer",
            commonDosages: ["25mg", "50mg", "100mg"], typicalDoseForm: "tablet",
            priceRange: "₹50-120",
            genericAlternatives: [
                GenericAlternative(brandName: "Serta", manufacturer: "Mankind", priceRange: "₹30-70"),
                GenericAlternative(brandName: "Serlift", manufacturer: "Torrent", priceRange: "₹35-80")
            ],
            foodInteractions: ["Can be taken with or without food", "Avoid alcohol"],
            commonSideEffects: ["Nausea", "Diarrhoea", "Insomnia", "Sexual dysfunction", "Dry mouth"],
            storageInstructions: "Store below 30°C.",
            description: "SSRI antidepressant for depression, OCD, PTSD, and social anxiety.",
            isScheduleH: true
        ))

        db.append(DrugEntry(
            id: "duloxetine", brandName: "Cymbalta", genericName: "Duloxetine",
            saltComposition: "Duloxetine 30mg",
            category: .antiDepressant, manufacturer: "Eli Lilly",
            commonDosages: ["20mg", "30mg", "60mg"], typicalDoseForm: "capsule",
            priceRange: "₹60-150",
            genericAlternatives: [
                GenericAlternative(brandName: "Duzela", manufacturer: "Sun Pharma", priceRange: "₹40-100"),
                GenericAlternative(brandName: "Dulot", manufacturer: "Mankind", priceRange: "₹35-90")
            ],
            foodInteractions: ["Can be taken with or without food", "Avoid alcohol", "Do not crush capsule"],
            commonSideEffects: ["Nausea", "Dry mouth", "Drowsiness", "Constipation", "Dizziness"],
            storageInstructions: "Store below 30°C.",
            description: "SNRI for depression, anxiety, diabetic neuropathy, and fibromyalgia.",
            isScheduleH: true
        ))

        db.append(DrugEntry(
            id: "amitriptyline", brandName: "Tryptomer", genericName: "Amitriptyline",
            saltComposition: "Amitriptyline Hydrochloride 25mg",
            category: .antiDepressant, manufacturer: "Merck",
            commonDosages: ["10mg", "25mg", "50mg", "75mg"], typicalDoseForm: "tablet",
            priceRange: "₹10-30",
            genericAlternatives: [
                GenericAlternative(brandName: "Elavil", manufacturer: "Various", priceRange: "₹8-25"),
                GenericAlternative(brandName: "Sarotena", manufacturer: "Lundbeck", priceRange: "₹15-35")
            ],
            foodInteractions: ["Can be taken with or without food", "Avoid alcohol strictly"],
            commonSideEffects: ["Drowsiness", "Dry mouth", "Constipation", "Weight gain", "Blurred vision"],
            storageInstructions: "Store below 30°C. Protect from light.",
            description: "Tricyclic antidepressant also used for neuropathic pain, migraine prevention, and insomnia.",
            isScheduleH: true
        ))

        db.append(DrugEntry(
            id: "alprazolam", brandName: "Alprax", genericName: "Alprazolam",
            saltComposition: "Alprazolam 0.25mg",
            category: .antiDepressant, manufacturer: "Torrent",
            commonDosages: ["0.25mg", "0.5mg", "1mg"], typicalDoseForm: "tablet",
            priceRange: "₹15-40",
            genericAlternatives: [
                GenericAlternative(brandName: "Restyl", manufacturer: "Sun Pharma", priceRange: "₹12-30"),
                GenericAlternative(brandName: "Trika", manufacturer: "Cipla", priceRange: "₹10-28")
            ],
            foodInteractions: ["Can be taken with or without food", "Strictly avoid alcohol", "Avoid grapefruit juice"],
            commonSideEffects: ["Drowsiness", "Dizziness", "Memory impairment", "Fatigue", "Dependence"],
            storageInstructions: "Store below 30°C.",
            description: "Benzodiazepine for acute anxiety and panic disorder. High dependence potential — short-term use only.",
            isScheduleH: true
        ))

        db.append(DrugEntry(
            id: "olanzapine", brandName: "Oleanz", genericName: "Olanzapine",
            saltComposition: "Olanzapine 5mg",
            category: .antiDepressant, manufacturer: "Sun Pharma",
            commonDosages: ["2.5mg", "5mg", "10mg", "15mg", "20mg"], typicalDoseForm: "tablet",
            priceRange: "₹30-80",
            genericAlternatives: [
                GenericAlternative(brandName: "Olanex", manufacturer: "Mankind", priceRange: "₹20-60"),
                GenericAlternative(brandName: "Zyprexa", manufacturer: "Eli Lilly", priceRange: "₹100-250")
            ],
            foodInteractions: ["Can be taken with or without food", "Avoid alcohol"],
            commonSideEffects: ["Weight gain", "Drowsiness", "Increased blood sugar", "Dyslipidemia", "Dry mouth"],
            storageInstructions: "Store below 30°C.",
            description: "Atypical antipsychotic for schizophrenia, bipolar disorder, and treatment-resistant depression.",
            isScheduleH: true
        ))

        db.append(DrugEntry(
            id: "risperidone", brandName: "Risperdal", genericName: "Risperidone",
            saltComposition: "Risperidone 2mg",
            category: .antiDepressant, manufacturer: "Janssen",
            commonDosages: ["0.5mg", "1mg", "2mg", "3mg", "4mg"], typicalDoseForm: "tablet",
            priceRange: "₹20-60",
            genericAlternatives: [
                GenericAlternative(brandName: "Risdone", manufacturer: "Sun Pharma", priceRange: "₹15-45"),
                GenericAlternative(brandName: "Sizodon", manufacturer: "Sun Pharma", priceRange: "₹12-40")
            ],
            foodInteractions: ["Can be taken with or without food"],
            commonSideEffects: ["Weight gain", "Drowsiness", "Parkinsonism", "Elevated prolactin", "Dizziness"],
            storageInstructions: "Store below 30°C.",
            description: "Atypical antipsychotic for schizophrenia, bipolar disorder, and irritability in autism.",
            isScheduleH: true
        ))

        db.append(DrugEntry(
            id: "lithium", brandName: "Licab", genericName: "Lithium Carbonate",
            saltComposition: "Lithium Carbonate 300mg",
            category: .antiDepressant, manufacturer: "Sun Pharma",
            commonDosages: ["300mg", "450mg"], typicalDoseForm: "tablet",
            priceRange: "₹10-25",
            genericAlternatives: [
                GenericAlternative(brandName: "Intalith CR", manufacturer: "Various", priceRange: "₹8-20")
            ],
            foodInteractions: ["Take with food", "Maintain consistent salt and water intake", "Avoid dehydration"],
            commonSideEffects: ["Tremor", "Thirst", "Frequent urination", "Weight gain", "Hypothyroidism"],
            storageInstructions: "Store below 30°C.",
            description: "Mood stabiliser for bipolar disorder. Regular blood level monitoring essential.",
            isScheduleH: true
        ))

        db.append(DrugEntry(
            id: "quetiapine", brandName: "Qutan", genericName: "Quetiapine",
            saltComposition: "Quetiapine 100mg",
            category: .antiDepressant, manufacturer: "Sun Pharma",
            commonDosages: ["25mg", "50mg", "100mg", "200mg", "300mg"], typicalDoseForm: "tablet",
            priceRange: "₹40-120",
            genericAlternatives: [
                GenericAlternative(brandName: "Seroquel", manufacturer: "AstraZeneca", priceRange: "₹100-300"),
                GenericAlternative(brandName: "Q-Mind", manufacturer: "Mankind", priceRange: "₹30-90")
            ],
            foodInteractions: ["Can be taken with or without food", "Avoid alcohol", "Avoid grapefruit juice"],
            commonSideEffects: ["Drowsiness", "Weight gain", "Dry mouth", "Dizziness", "Elevated blood sugar"],
            storageInstructions: "Store below 30°C.",
            description: "Atypical antipsychotic for schizophrenia, bipolar disorder, and treatment-resistant depression.",
            isScheduleH: true
        ))

        db.append(DrugEntry(
            id: "lorazepam", brandName: "Ativan", genericName: "Lorazepam",
            saltComposition: "Lorazepam 1mg",
            category: .antiDepressant, manufacturer: "Abbott",
            commonDosages: ["0.5mg", "1mg", "2mg"], typicalDoseForm: "tablet",
            priceRange: "₹10-30",
            genericAlternatives: [
                GenericAlternative(brandName: "Lopez", manufacturer: "Intas", priceRange: "₹8-22"),
                GenericAlternative(brandName: "Trapex", manufacturer: "Cipla", priceRange: "₹7-20")
            ],
            foodInteractions: ["Can be taken with or without food", "Strictly avoid alcohol"],
            commonSideEffects: ["Drowsiness", "Dizziness", "Weakness", "Memory impairment", "Dependence"],
            storageInstructions: "Store below 30°C.",
            description: "Benzodiazepine for anxiety, insomnia, and seizures. Short-term use recommended.",
            isScheduleH: true
        ))

        db.append(DrugEntry(
            id: "paroxetine", brandName: "Paxidep", genericName: "Paroxetine",
            saltComposition: "Paroxetine 12.5mg CR",
            category: .antiDepressant, manufacturer: "Sun Pharma",
            commonDosages: ["12.5mg", "25mg", "37.5mg CR"], typicalDoseForm: "tablet",
            priceRange: "₹40-100",
            genericAlternatives: [
                GenericAlternative(brandName: "Parotin", manufacturer: "Mankind", priceRange: "₹25-70"),
                GenericAlternative(brandName: "Pari CR", manufacturer: "Cipla", priceRange: "₹30-80")
            ],
            foodInteractions: ["Take with food", "Avoid alcohol"],
            commonSideEffects: ["Nausea", "Sexual dysfunction", "Weight gain", "Drowsiness", "Dry mouth"],
            storageInstructions: "Store below 30°C.",
            description: "SSRI for depression, anxiety, OCD, and PTSD. Do NOT stop abruptly.",
            isScheduleH: true
        ))

        db.append(DrugEntry(
            id: "mirtazapine", brandName: "Mirtaz", genericName: "Mirtazapine",
            saltComposition: "Mirtazapine 15mg",
            category: .antiDepressant, manufacturer: "Sun Pharma",
            commonDosages: ["7.5mg", "15mg", "30mg", "45mg"], typicalDoseForm: "tablet",
            priceRange: "₹30-80",
            genericAlternatives: [
                GenericAlternative(brandName: "Mirap", manufacturer: "Cipla", priceRange: "₹20-60")
            ],
            foodInteractions: ["Can be taken with or without food", "Avoid alcohol"],
            commonSideEffects: ["Drowsiness", "Increased appetite", "Weight gain", "Dry mouth"],
            storageInstructions: "Store below 30°C.",
            description: "NaSSA antidepressant useful for depression with insomnia and poor appetite.",
            isScheduleH: true
        ))

        db.append(DrugEntry(
            id: "valproate", brandName: "Encorate", genericName: "Sodium Valproate",
            saltComposition: "Sodium Valproate 200mg",
            category: .antiDepressant, manufacturer: "Sun Pharma",
            commonDosages: ["200mg", "300mg", "500mg"], typicalDoseForm: "tablet",
            priceRange: "₹15-40",
            genericAlternatives: [
                GenericAlternative(brandName: "Valparin", manufacturer: "Sanofi", priceRange: "₹12-35"),
                GenericAlternative(brandName: "Epilex", manufacturer: "Various", priceRange: "₹10-30")
            ],
            foodInteractions: ["Take with food to reduce stomach upset", "Avoid alcohol"],
            commonSideEffects: ["Nausea", "Weight gain", "Tremor", "Hair loss", "Liver toxicity (rare)"],
            storageInstructions: "Store below 30°C.",
            description: "Mood stabiliser and anticonvulsant for epilepsy, bipolar disorder, and migraine prevention.",
            isScheduleH: true
        ))

        // ────────────────────────────────────────────
        // VITAMINS / SUPPLEMENTS (EXPANDED)
        // ────────────────────────────────────────────

        db.append(DrugEntry(
            id: "vitamin-d3", brandName: "Arachitol", genericName: "Cholecalciferol (Vitamin D3)",
            saltComposition: "Cholecalciferol 60000 IU",
            category: .vitamin, manufacturer: "Abbott",
            commonDosages: ["1000 IU daily", "60000 IU weekly"], typicalDoseForm: "sachet/capsule",
            priceRange: "₹60-120",
            genericAlternatives: [
                GenericAlternative(brandName: "D-Rise", manufacturer: "USV", priceRange: "₹45-90"),
                GenericAlternative(brandName: "Uprise D3", manufacturer: "Alkem", priceRange: "₹40-80")
            ],
            foodInteractions: ["Take with fatty food for better absorption"],
            commonSideEffects: ["Nausea (high doses)", "Constipation", "Weakness", "Hypercalcemia (overdose)"],
            storageInstructions: "Store below 30°C. Protect from light.",
            description: "Vitamin D3 for deficiency, bone health, and immunity. Very common deficiency in India.",
            isScheduleH: false
        ))

        db.append(DrugEntry(
            id: "vitamin-d3-1000", brandName: "D-Rise 1000", genericName: "Cholecalciferol (Vitamin D3)",
            saltComposition: "Cholecalciferol 1000 IU",
            category: .vitamin, manufacturer: "USV",
            commonDosages: ["1000 IU"], typicalDoseForm: "tablet",
            priceRange: "₹100-200",
            genericAlternatives: [
                GenericAlternative(brandName: "Uprise D3 1000", manufacturer: "Alkem", priceRange: "₹80-160")
            ],
            foodInteractions: ["Take with fatty food"],
            commonSideEffects: ["Generally well-tolerated at this dose"],
            storageInstructions: "Store below 30°C.",
            description: "Daily Vitamin D3 supplement for maintenance after correction of deficiency.",
            isScheduleH: false
        ))

        db.append(DrugEntry(
            id: "calcium-d3", brandName: "Shelcal-HD", genericName: "Calcium + Vitamin D3",
            saltComposition: "Calcium Carbonate 500mg + Vitamin D3 250IU",
            category: .vitamin, manufacturer: "Torrent",
            commonDosages: ["500mg+250IU", "500mg+500IU"], typicalDoseForm: "tablet",
            priceRange: "₹90-170",
            genericAlternatives: [
                GenericAlternative(brandName: "Calcimax Forte", manufacturer: "Meyer Organics", priceRange: "₹100-180"),
                GenericAlternative(brandName: "Gemcal", manufacturer: "GSK", priceRange: "₹80-150")
            ],
            foodInteractions: ["Take with meals", "Avoid taking with spinach or tea"],
            commonSideEffects: ["Constipation", "Bloating", "Gas"],
            storageInstructions: "Store below 30°C.",
            description: "Calcium + D3 for bone health, osteoporosis prevention, especially post-menopausal women.",
            isScheduleH: false
        ))

        db.append(DrugEntry(
            id: "iron-folic-new", brandName: "Fefol-Z", genericName: "Iron + Folic Acid + Zinc",
            saltComposition: "Ferrous Sulfate 150mg + Folic Acid 0.5mg + Zinc 22.5mg",
            category: .vitamin, manufacturer: "GSK",
            commonDosages: ["Standard"], typicalDoseForm: "capsule",
            priceRange: "₹35-65",
            genericAlternatives: [
                GenericAlternative(brandName: "Orofer-XT", manufacturer: "Emcure", priceRange: "₹60-110"),
                GenericAlternative(brandName: "Livogen", manufacturer: "Pfizer", priceRange: "₹40-75")
            ],
            foodInteractions: ["Take on empty stomach with Vitamin C for better absorption", "Avoid tea, coffee, milk within 2 hours"],
            commonSideEffects: ["Constipation", "Black stools", "Nausea", "Metallic taste"],
            storageInstructions: "Store below 30°C.",
            description: "Iron + Folic Acid + Zinc for anaemia with zinc for immunity.",
            isScheduleH: false
        ))

        db.append(DrugEntry(
            id: "omega3", brandName: "Maxepa", genericName: "Omega-3 Fatty Acids",
            saltComposition: "EPA 180mg + DHA 120mg",
            category: .vitamin, manufacturer: "Merck",
            commonDosages: ["Standard"], typicalDoseForm: "capsule",
            priceRange: "₹100-200",
            genericAlternatives: [
                GenericAlternative(brandName: "Mega-3", manufacturer: "Various", priceRange: "₹60-130"),
                GenericAlternative(brandName: "Evion LC", manufacturer: "Various", priceRange: "₹80-150")
            ],
            foodInteractions: ["Take with meals"],
            commonSideEffects: ["Fishy aftertaste", "Bloating", "Diarrhoea", "Nausea"],
            storageInstructions: "Store below 25°C. Protect from light.",
            description: "Fish oil supplement for heart health, joint inflammation, and brain health.",
            isScheduleH: false
        ))

        db.append(DrugEntry(
            id: "zinc", brandName: "Zinconia", genericName: "Zinc Acetate",
            saltComposition: "Zinc Acetate 20mg",
            category: .vitamin, manufacturer: "Various",
            commonDosages: ["10mg", "20mg", "50mg"], typicalDoseForm: "tablet",
            priceRange: "₹20-50",
            genericAlternatives: [
                GenericAlternative(brandName: "Z&D", manufacturer: "Various", priceRange: "₹15-35")
            ],
            foodInteractions: ["Take on empty stomach or with food", "Avoid taking with iron supplements"],
            commonSideEffects: ["Nausea", "Metallic taste", "Stomach upset"],
            storageInstructions: "Store below 30°C.",
            description: "Zinc supplement for immunity, wound healing, and diarrhoea management in children.",
            isScheduleH: false
        ))

        db.append(DrugEntry(
            id: "vitamin-e", brandName: "Evion", genericName: "Vitamin E (Tocopherol)",
            saltComposition: "Tocopheryl Acetate 400mg",
            category: .vitamin, manufacturer: "Merck",
            commonDosages: ["200mg", "400mg"], typicalDoseForm: "capsule",
            priceRange: "₹50-100",
            genericAlternatives: [
                GenericAlternative(brandName: "E-Vit", manufacturer: "Various", priceRange: "₹30-60")
            ],
            foodInteractions: ["Take with fatty food for better absorption"],
            commonSideEffects: ["Nausea", "Diarrhoea", "Stomach cramps", "Fatigue"],
            storageInstructions: "Store below 30°C.",
            description: "Antioxidant vitamin for skin health, fertility, and neurological function.",
            isScheduleH: false
        ))

        db.append(DrugEntry(
            id: "biotin", brandName: "Biotin", genericName: "Biotin (Vitamin B7)",
            saltComposition: "Biotin 10mg",
            category: .vitamin, manufacturer: "Various",
            commonDosages: ["5mg", "10mg"], typicalDoseForm: "tablet",
            priceRange: "₹100-200",
            genericAlternatives: [
                GenericAlternative(brandName: "Hairjoy", manufacturer: "Various", priceRange: "₹80-160")
            ],
            foodInteractions: ["Can be taken with or without food"],
            commonSideEffects: ["Generally well-tolerated", "Acne (rare at high doses)"],
            storageInstructions: "Store below 30°C.",
            description: "B7 vitamin for hair, skin, and nail health. Popular for hair fall.",
            isScheduleH: false
        ))

        // ────────────────────────────────────────────
        // COMMON COMBINATIONS (EXPANDED)
        // ────────────────────────────────────────────

        db.append(DrugEntry(
            id: "augmentin-625", brandName: "Augmentin 625 Duo", genericName: "Amoxicillin + Clavulanic Acid",
            saltComposition: "Amoxicillin 500mg + Clavulanic Acid 125mg",
            category: .antibiotic, manufacturer: "GSK",
            commonDosages: ["625mg"], typicalDoseForm: "tablet",
            priceRange: "₹140-250",
            genericAlternatives: [
                GenericAlternative(brandName: "Amoxyclav 625", manufacturer: "Cipla", priceRange: "₹90-160"),
                GenericAlternative(brandName: "Moxikind-CV 625", manufacturer: "Mankind", priceRange: "₹80-150"),
                GenericAlternative(brandName: "Clavam 625", manufacturer: "Alkem", priceRange: "₹95-170")
            ],
            foodInteractions: ["Take at the start of a meal", "Avoid alcohol"],
            commonSideEffects: ["Diarrhoea", "Nausea", "Vomiting", "Skin rash"],
            storageInstructions: "Store below 25°C.",
            description: "Higher-strength amoxicillin-clavulanate for moderate to severe infections.",
            isScheduleH: true
        ))

        db.append(DrugEntry(
            id: "norfloxacin-tz", brandName: "Norflox-TZ", genericName: "Norfloxacin + Tinidazole",
            saltComposition: "Norfloxacin 400mg + Tinidazole 600mg",
            category: .antibiotic, manufacturer: "Cipla",
            commonDosages: ["400/600mg"], typicalDoseForm: "tablet",
            priceRange: "₹30-65",
            genericAlternatives: [
                GenericAlternative(brandName: "N-TZ", manufacturer: "Various", priceRange: "₹20-45")
            ],
            foodInteractions: ["Take on empty stomach", "Strictly avoid alcohol for 72 hours"],
            commonSideEffects: ["Nausea", "Metallic taste", "Headache", "Dizziness", "Diarrhoea"],
            storageInstructions: "Store below 30°C.",
            description: "Antibiotic + antiprotozoal for diarrhoea, dysentery, and GI infections.",
            isScheduleH: true
        ))

        db.append(DrugEntry(
            id: "cefixime-ofloxacin", brandName: "Mahacef Plus", genericName: "Cefixime + Ofloxacin",
            saltComposition: "Cefixime 200mg + Ofloxacin 200mg",
            category: .antibiotic, manufacturer: "Mankind",
            commonDosages: ["200/200mg"], typicalDoseForm: "tablet",
            priceRange: "₹80-160",
            genericAlternatives: [
                GenericAlternative(brandName: "Taxim-OF", manufacturer: "Alkem", priceRange: "₹70-140"),
                GenericAlternative(brandName: "Cefix-O", manufacturer: "Cipla", priceRange: "₹65-130")
            ],
            foodInteractions: ["Take with food", "Avoid dairy and antacids within 2 hours"],
            commonSideEffects: ["Diarrhoea", "Nausea", "Headache", "Dizziness", "Rash"],
            storageInstructions: "Store below 30°C.",
            description: "Cephalosporin + fluoroquinolone combination for mixed infections.",
            isScheduleH: true
        ))

        db.append(DrugEntry(
            id: "atorvastatin-clopidogrel", brandName: "Atorva-C", genericName: "Atorvastatin + Clopidogrel",
            saltComposition: "Atorvastatin 10mg + Clopidogrel 75mg",
            category: .cardiovascular, manufacturer: "Zydus Cadila",
            commonDosages: ["10/75mg", "20/75mg"], typicalDoseForm: "capsule",
            priceRange: "₹80-160",
            genericAlternatives: [
                GenericAlternative(brandName: "Clavix-AS", manufacturer: "Sun Pharma", priceRange: "₹60-130"),
                GenericAlternative(brandName: "Deplatt-CV", manufacturer: "Torrent", priceRange: "₹65-140")
            ],
            foodInteractions: ["Can be taken with or without food", "Avoid grapefruit juice"],
            commonSideEffects: ["Bleeding", "Muscle pain", "Headache", "Nausea"],
            storageInstructions: "Store below 30°C.",
            description: "Statin + antiplatelet combination for post-stent or post-MI patients.",
            isScheduleH: true
        ))

        db.append(DrugEntry(
            id: "metformin-empagliflozin", brandName: "Jardiance Met", genericName: "Metformin + Empagliflozin",
            saltComposition: "Metformin 500mg + Empagliflozin 5mg",
            category: .antidiabetic, manufacturer: "Boehringer Ingelheim",
            commonDosages: ["500/5mg", "500/12.5mg", "1000/5mg", "1000/12.5mg"], typicalDoseForm: "tablet",
            priceRange: "₹350-550",
            genericAlternatives: [
                GenericAlternative(brandName: "Gibtulio-Met", manufacturer: "Sun Pharma", priceRange: "₹220-400")
            ],
            foodInteractions: ["Take with meals", "Increase water intake"],
            commonSideEffects: ["Nausea", "Genital infections", "UTI", "Diarrhoea", "Frequent urination"],
            storageInstructions: "Store below 30°C.",
            description: "Metformin + SGLT2 inhibitor for diabetes with cardiovascular and renal benefits.",
            isScheduleH: true
        ))

        db.append(DrugEntry(
            id: "glimepiride-metformin-voglibose", brandName: "Glycomet Trio", genericName: "Glimepiride + Metformin + Voglibose",
            saltComposition: "Glimepiride 1mg + Metformin 500mg + Voglibose 0.2mg",
            category: .antidiabetic, manufacturer: "USV",
            commonDosages: ["1/500/0.2mg", "2/500/0.2mg"], typicalDoseForm: "tablet",
            priceRange: "₹80-160",
            genericAlternatives: [
                GenericAlternative(brandName: "PPG Trio", manufacturer: "Sun Pharma", priceRange: "₹60-120")
            ],
            foodInteractions: ["Take with the first bite of a meal", "Do not skip meals"],
            commonSideEffects: ["Hypoglycemia", "Nausea", "Flatulence", "Diarrhoea"],
            storageInstructions: "Store below 30°C.",
            description: "Triple combination for uncontrolled Type 2 diabetes — SU + biguanide + AGI.",
            isScheduleH: true
        ))

        db.append(DrugEntry(
            id: "telmisartan-chlorthalidone", brandName: "Telma-CT", genericName: "Telmisartan + Chlorthalidone",
            saltComposition: "Telmisartan 40mg + Chlorthalidone 12.5mg",
            category: .antihypertensive, manufacturer: "Glenmark",
            commonDosages: ["40/12.5mg", "80/12.5mg"], typicalDoseForm: "tablet",
            priceRange: "₹100-200",
            genericAlternatives: [
                GenericAlternative(brandName: "Telmikind-CT", manufacturer: "Mankind", priceRange: "₹60-130")
            ],
            foodInteractions: ["Can be taken with or without food", "Stay hydrated"],
            commonSideEffects: ["Dizziness", "Fatigue", "Frequent urination", "Low potassium"],
            storageInstructions: "Store below 30°C.",
            description: "ARB + thiazide-like diuretic for hypertension not controlled with monotherapy.",
            isScheduleH: true
        ))

        db.append(DrugEntry(
            id: "rosuvastatin-clopidogrel", brandName: "Rosave-C", genericName: "Rosuvastatin + Clopidogrel",
            saltComposition: "Rosuvastatin 10mg + Clopidogrel 75mg",
            category: .cardiovascular, manufacturer: "Sun Pharma",
            commonDosages: ["10/75mg", "20/75mg"], typicalDoseForm: "capsule",
            priceRange: "₹100-200",
            genericAlternatives: [
                GenericAlternative(brandName: "Rosufit-C", manufacturer: "Mankind", priceRange: "₹70-140")
            ],
            foodInteractions: ["Can be taken with or without food"],
            commonSideEffects: ["Bleeding", "Muscle pain", "Headache", "Nausea"],
            storageInstructions: "Store below 30°C.",
            description: "Rosuvastatin + antiplatelet for post-cardiac event management.",
            isScheduleH: true
        ))

        db.append(DrugEntry(
            id: "telmisartan-metoprolol", brandName: "Telma-MT", genericName: "Telmisartan + Metoprolol",
            saltComposition: "Telmisartan 40mg + Metoprolol 25mg",
            category: .antihypertensive, manufacturer: "Glenmark",
            commonDosages: ["40/25mg", "40/50mg"], typicalDoseForm: "tablet",
            priceRange: "₹80-160",
            genericAlternatives: [
                GenericAlternative(brandName: "Telmikind-Beta", manufacturer: "Mankind", priceRange: "₹50-110")
            ],
            foodInteractions: ["Take with food", "Avoid alcohol", "Limit caffeine"],
            commonSideEffects: ["Dizziness", "Fatigue", "Bradycardia", "Cold extremities"],
            storageInstructions: "Store below 30°C.",
            description: "ARB + beta-blocker combination for hypertension with tachycardia.",
            isScheduleH: true
        ))

        // ────────────────────────────────────────────
        // SKIN CARE (EXPANDED)
        // ────────────────────────────────────────────

        db.append(DrugEntry(
            id: "ketoconazole", brandName: "Nizoral", genericName: "Ketoconazole",
            saltComposition: "Ketoconazole 2%",
            category: .skinCare, manufacturer: "Janssen",
            commonDosages: ["2%"], typicalDoseForm: "cream/shampoo",
            priceRange: "₹80-160",
            genericAlternatives: [
                GenericAlternative(brandName: "Ketomac", manufacturer: "Torrent", priceRange: "₹50-100"),
                GenericAlternative(brandName: "KZ Cream", manufacturer: "Hegde & Hegde", priceRange: "₹40-80")
            ],
            foodInteractions: ["Topical — no food interactions"],
            commonSideEffects: ["Skin irritation", "Burning", "Itching", "Dryness"],
            storageInstructions: "Store below 30°C.",
            description: "Antifungal for dandruff, tinea versicolor, and fungal skin infections.",
            isScheduleH: true
        ))

        db.append(DrugEntry(
            id: "terbinafine", brandName: "Lamisil", genericName: "Terbinafine",
            saltComposition: "Terbinafine 1%",
            category: .skinCare, manufacturer: "Novartis",
            commonDosages: ["1%", "250mg tablet"], typicalDoseForm: "cream/tablet",
            priceRange: "₹60-120",
            genericAlternatives: [
                GenericAlternative(brandName: "Zimig", manufacturer: "GSK", priceRange: "₹50-100"),
                GenericAlternative(brandName: "Terbicip", manufacturer: "Cipla", priceRange: "₹40-80")
            ],
            foodInteractions: ["Oral: can be taken with or without food"],
            commonSideEffects: ["Cream: skin irritation. Oral: nausea, headache, taste changes, liver toxicity (rare)"],
            storageInstructions: "Store below 30°C.",
            description: "Antifungal for ringworm, athlete's foot, and nail fungus.",
            isScheduleH: true
        ))

        db.append(DrugEntry(
            id: "fusidic-acid", brandName: "Fucidin", genericName: "Fusidic Acid",
            saltComposition: "Fusidic Acid 2%",
            category: .skinCare, manufacturer: "Leo Pharma",
            commonDosages: ["2%"], typicalDoseForm: "cream",
            priceRange: "₹100-200",
            genericAlternatives: [
                GenericAlternative(brandName: "Fusicip", manufacturer: "Cipla", priceRange: "₹70-140"),
                GenericAlternative(brandName: "Fucibet", manufacturer: "Leo Pharma", priceRange: "₹120-220")
            ],
            foodInteractions: ["Topical — no food interactions"],
            commonSideEffects: ["Mild irritation", "Redness", "Itching"],
            storageInstructions: "Store below 30°C.",
            description: "Topical antibiotic for staphylococcal skin infections, impetigo, and infected eczema.",
            isScheduleH: true
        ))

        db.append(DrugEntry(
            id: "adapalene", brandName: "Deriva", genericName: "Adapalene",
            saltComposition: "Adapalene 0.1%",
            category: .skinCare, manufacturer: "Glenmark",
            commonDosages: ["0.1%", "0.3%"], typicalDoseForm: "gel",
            priceRange: "₹150-300",
            genericAlternatives: [
                GenericAlternative(brandName: "Adaferin", manufacturer: "Sun Pharma", priceRange: "₹120-250"),
                GenericAlternative(brandName: "Differin", manufacturer: "Galderma", priceRange: "₹200-400")
            ],
            foodInteractions: ["Topical — no food interactions"],
            commonSideEffects: ["Skin dryness", "Peeling", "Redness", "Burning", "Photosensitivity"],
            storageInstructions: "Store below 30°C. Protect from light.",
            description: "Retinoid gel for acne vulgaris. Apply at night. Use sunscreen during treatment.",
            isScheduleH: true
        ))

        db.append(DrugEntry(
            id: "permethrin", brandName: "Scabper", genericName: "Permethrin",
            saltComposition: "Permethrin 5%",
            category: .skinCare, manufacturer: "Healing Pharma",
            commonDosages: ["5%"], typicalDoseForm: "cream/lotion",
            priceRange: "₹40-80",
            genericAlternatives: [
                GenericAlternative(brandName: "Permithin", manufacturer: "Various", priceRange: "₹30-60")
            ],
            foodInteractions: ["Topical — no food interactions"],
            commonSideEffects: ["Mild burning", "Itching", "Stinging", "Redness"],
            storageInstructions: "Store below 30°C.",
            description: "Topical insecticide for scabies and lice. Apply head to toe, wash after 8-14 hours.",
            isScheduleH: false
        ))

        db.append(DrugEntry(
            id: "calamine", brandName: "Lacto Calamine", genericName: "Calamine",
            saltComposition: "Calamine 8% + Zinc Oxide",
            category: .skinCare, manufacturer: "Piramal",
            commonDosages: ["Standard"], typicalDoseForm: "lotion",
            priceRange: "₹80-160",
            genericAlternatives: [
                GenericAlternative(brandName: "Caladerm", manufacturer: "Various", priceRange: "₹40-80")
            ],
            foodInteractions: ["Topical — no food interactions"],
            commonSideEffects: ["Generally well-tolerated", "Mild dryness"],
            storageInstructions: "Store below 30°C. Shake well before use.",
            description: "Soothing lotion for itching, sunburn, insect bites, and mild skin irritation.",
            isScheduleH: false
        ))

        // ────────────────────────────────────────────
        // ANTI-INFECTIVE (EXPANDED)
        // ────────────────────────────────────────────

        db.append(DrugEntry(
            id: "ivermectin", brandName: "Ivermectol", genericName: "Ivermectin",
            saltComposition: "Ivermectin 12mg",
            category: .antiInfective, manufacturer: "USV",
            commonDosages: ["3mg", "6mg", "12mg"], typicalDoseForm: "tablet",
            priceRange: "₹20-50",
            genericAlternatives: [
                GenericAlternative(brandName: "Iver", manufacturer: "Various", priceRange: "₹15-35"),
                GenericAlternative(brandName: "Vermact", manufacturer: "Mankind", priceRange: "₹12-30")
            ],
            foodInteractions: ["Take on empty stomach with water"],
            commonSideEffects: ["Dizziness", "Nausea", "Diarrhoea", "Itching (Mazzotti reaction in filariasis)"],
            storageInstructions: "Store below 30°C.",
            description: "Antiparasitic for scabies, filariasis, strongyloidiasis, and head lice.",
            isScheduleH: true
        ))

        db.append(DrugEntry(
            id: "secnidazole", brandName: "Secnil", genericName: "Secnidazole",
            saltComposition: "Secnidazole 1g",
            category: .antiInfective, manufacturer: "Abbott",
            commonDosages: ["1g", "2g"], typicalDoseForm: "tablet",
            priceRange: "₹20-50",
            genericAlternatives: [
                GenericAlternative(brandName: "Secgyl", manufacturer: "Various", priceRange: "₹15-35")
            ],
            foodInteractions: ["Take with food", "Avoid alcohol for 72 hours"],
            commonSideEffects: ["Nausea", "Metallic taste", "Headache", "Dizziness"],
            storageInstructions: "Store below 30°C.",
            description: "Single-dose antiprotozoal for amoebiasis and giardiasis.",
            isScheduleH: true
        ))

        db.append(DrugEntry(
            id: "itraconazole", brandName: "Canditral", genericName: "Itraconazole",
            saltComposition: "Itraconazole 100mg",
            category: .antiInfective, manufacturer: "Glenmark",
            commonDosages: ["100mg", "200mg"], typicalDoseForm: "capsule",
            priceRange: "₹80-200",
            genericAlternatives: [
                GenericAlternative(brandName: "Itaspor", manufacturer: "Sun Pharma", priceRange: "₹60-150"),
                GenericAlternative(brandName: "Sporanox", manufacturer: "Janssen", priceRange: "₹120-280")
            ],
            foodInteractions: ["Take with food or cola for better absorption", "Avoid antacids"],
            commonSideEffects: ["Nausea", "Headache", "Abdominal pain", "Liver toxicity (rare)", "Heart failure (rare)"],
            storageInstructions: "Store below 25°C. Protect from moisture.",
            description: "Systemic antifungal for nail fungus, ringworm, and systemic fungal infections.",
            isScheduleH: true
        ))

        db.append(DrugEntry(
            id: "valacyclovir", brandName: "Valcivir", genericName: "Valacyclovir",
            saltComposition: "Valacyclovir 500mg",
            category: .antiInfective, manufacturer: "Cipla",
            commonDosages: ["500mg", "1000mg"], typicalDoseForm: "tablet",
            priceRange: "₹100-250",
            genericAlternatives: [
                GenericAlternative(brandName: "Valtrex", manufacturer: "GSK", priceRange: "₹200-400"),
                GenericAlternative(brandName: "Vaclov", manufacturer: "Sun Pharma", priceRange: "₹80-200")
            ],
            foodInteractions: ["Can be taken with or without food", "Drink plenty of water"],
            commonSideEffects: ["Headache", "Nausea", "Abdominal pain", "Dizziness"],
            storageInstructions: "Store below 30°C.",
            description: "Prodrug of acyclovir for herpes simplex, herpes zoster, and cold sore prevention.",
            isScheduleH: true
        ))

        // ────────────────────────────────────────────
        // OTHER / MISCELLANEOUS (EXPANDED)
        // ────────────────────────────────────────────

        db.append(DrugEntry(
            id: "pantoprazole-levosulpiride", brandName: "Pantocid-L", genericName: "Pantoprazole + Levosulpiride",
            saltComposition: "Pantoprazole 40mg + Levosulpiride 75mg",
            category: .antiAcid, manufacturer: "Sun Pharma",
            commonDosages: ["40/75mg"], typicalDoseForm: "capsule",
            priceRange: "₹70-140",
            genericAlternatives: [
                GenericAlternative(brandName: "Pan-LS", manufacturer: "Alkem", priceRange: "₹55-110"),
                GenericAlternative(brandName: "Levosulpan", manufacturer: "Cipla", priceRange: "₹50-100")
            ],
            foodInteractions: ["Take on empty stomach"],
            commonSideEffects: ["Headache", "Breast tenderness", "Menstrual changes", "Drowsiness"],
            storageInstructions: "Store below 30°C.",
            description: "PPI + prokinetic for GERD with functional dyspepsia.",
            isScheduleH: true
        ))

        db.append(DrugEntry(
            id: "deflazacort", brandName: "Defcort", genericName: "Deflazacort",
            saltComposition: "Deflazacort 6mg",
            category: .other, manufacturer: "Cipla",
            commonDosages: ["6mg", "12mg", "24mg", "30mg"], typicalDoseForm: "tablet",
            priceRange: "₹40-100",
            genericAlternatives: [
                GenericAlternative(brandName: "Monocortil", manufacturer: "Sun Pharma", priceRange: "₹30-80"),
                GenericAlternative(brandName: "Decdan", manufacturer: "Various", priceRange: "₹25-65")
            ],
            foodInteractions: ["Take with food"],
            commonSideEffects: ["Weight gain", "Increased appetite", "Mood changes", "Insomnia", "Blood sugar elevation"],
            storageInstructions: "Store below 30°C.",
            description: "Corticosteroid with less bone and metabolic side effects than prednisolone.",
            isScheduleH: true
        ))

        db.append(DrugEntry(
            id: "methylprednisolone", brandName: "Medrol", genericName: "Methylprednisolone",
            saltComposition: "Methylprednisolone 4mg",
            category: .other, manufacturer: "Pfizer",
            commonDosages: ["4mg", "8mg", "16mg"], typicalDoseForm: "tablet",
            priceRange: "₹30-80",
            genericAlternatives: [
                GenericAlternative(brandName: "Solumedrol", manufacturer: "Pfizer", priceRange: "₹50-120")
            ],
            foodInteractions: ["Take with food"],
            commonSideEffects: ["Weight gain", "Mood changes", "Insomnia", "Blood sugar elevation", "Stomach upset"],
            storageInstructions: "Store below 30°C.",
            description: "Corticosteroid for inflammation, allergies, and autoimmune conditions.",
            isScheduleH: true
        ))

        db.append(DrugEntry(
            id: "montelukast-chew", brandName: "Montair 4", genericName: "Montelukast",
            saltComposition: "Montelukast 4mg",
            category: .respiratory, manufacturer: "Cipla",
            commonDosages: ["4mg"], typicalDoseForm: "chewable tablet",
            priceRange: "₹60-120",
            genericAlternatives: [
                GenericAlternative(brandName: "Montek 4", manufacturer: "Sun Pharma", priceRange: "₹45-90")
            ],
            foodInteractions: ["Take in the evening", "Can be taken with or without food"],
            commonSideEffects: ["Headache", "Abdominal pain", "Thirst", "Hyperactivity (children)"],
            storageInstructions: "Store below 30°C.",
            description: "Chewable montelukast for asthma and allergies in children aged 2-5 years.",
            isScheduleH: true
        ))

        db.append(DrugEntry(
            id: "cetirizine-paracetamol", brandName: "Cetcip Plus", genericName: "Cetirizine + Paracetamol + Phenylephrine",
            saltComposition: "Cetirizine 5mg + Paracetamol 325mg + Phenylephrine 10mg",
            category: .antiAllergy, manufacturer: "Cipla",
            commonDosages: ["Standard"], typicalDoseForm: "tablet",
            priceRange: "₹30-60",
            genericAlternatives: [
                GenericAlternative(brandName: "Sinarest", manufacturer: "Centaur", priceRange: "₹20-45"),
                GenericAlternative(brandName: "Crocin Cold", manufacturer: "GSK", priceRange: "₹25-50")
            ],
            foodInteractions: ["Can be taken with or without food"],
            commonSideEffects: ["Drowsiness", "Dry mouth", "Nausea", "Headache"],
            storageInstructions: "Store below 30°C.",
            description: "Combination for cold, flu, and allergic symptoms — antihistamine + decongestant + analgesic.",
            isScheduleH: false
        ))

        db.append(DrugEntry(
            id: "phenylephrine-chlor", brandName: "Sinarest", genericName: "Paracetamol + Phenylephrine + Chlorpheniramine",
            saltComposition: "Paracetamol 500mg + Phenylephrine 10mg + Chlorpheniramine 2mg",
            category: .antiAllergy, manufacturer: "Centaur",
            commonDosages: ["Standard"], typicalDoseForm: "tablet",
            priceRange: "₹20-45",
            genericAlternatives: [
                GenericAlternative(brandName: "Coldact", manufacturer: "Cipla", priceRange: "₹25-50"),
                GenericAlternative(brandName: "Vicks Action 500", manufacturer: "P&G", priceRange: "₹15-30")
            ],
            foodInteractions: ["Can be taken with or without food"],
            commonSideEffects: ["Drowsiness", "Dry mouth", "Dizziness", "Constipation"],
            storageInstructions: "Store below 30°C.",
            description: "OTC cold and flu relief — reduces fever, unblocks nose, stops runny nose.",
            isScheduleH: false
        ))

        db.append(DrugEntry(
            id: "doxylamine-pyridoxine", brandName: "Doxinate", genericName: "Doxylamine + Pyridoxine",
            saltComposition: "Doxylamine Succinate 10mg + Pyridoxine 10mg",
            category: .other, manufacturer: "Various",
            commonDosages: ["10/10mg"], typicalDoseForm: "tablet",
            priceRange: "₹30-60",
            genericAlternatives: [],
            foodInteractions: ["Take at bedtime"],
            commonSideEffects: ["Drowsiness", "Dry mouth", "Headache"],
            storageInstructions: "Store below 30°C.",
            description: "Safe anti-emetic for morning sickness (nausea and vomiting in pregnancy).",
            isScheduleH: true
        ))

        db.append(DrugEntry(
            id: "alendronate", brandName: "Fosamax", genericName: "Alendronate",
            saltComposition: "Alendronate Sodium 70mg",
            category: .other, manufacturer: "MSD",
            commonDosages: ["35mg", "70mg"], typicalDoseForm: "tablet",
            priceRange: "₹80-200",
            genericAlternatives: [
                GenericAlternative(brandName: "Osteofos", manufacturer: "Cipla", priceRange: "₹50-120"),
                GenericAlternative(brandName: "Alendromax", manufacturer: "Mankind", priceRange: "₹40-100")
            ],
            foodInteractions: ["Take on empty stomach with plain water only", "Do not eat/drink for 30 min after", "Sit upright for 30 min"],
            commonSideEffects: ["Stomach pain", "Heartburn", "Oesophageal irritation", "Joint pain", "Jaw osteonecrosis (very rare)"],
            storageInstructions: "Store below 30°C.",
            description: "Bisphosphonate for osteoporosis. Once-weekly dosing. Strict dosing instructions.",
            isScheduleH: true
        ))

        db.append(DrugEntry(
            id: "finasteride", brandName: "Finpecia", genericName: "Finasteride",
            saltComposition: "Finasteride 1mg",
            category: .other, manufacturer: "Cipla",
            commonDosages: ["1mg", "5mg"], typicalDoseForm: "tablet",
            priceRange: "₹80-200",
            genericAlternatives: [
                GenericAlternative(brandName: "Propecia", manufacturer: "MSD", priceRange: "₹200-400"),
                GenericAlternative(brandName: "Finax", manufacturer: "Dr. Reddy's", priceRange: "₹60-150")
            ],
            foodInteractions: ["Can be taken with or without food"],
            commonSideEffects: ["Decreased libido", "Erectile dysfunction", "Depression", "Breast tenderness"],
            storageInstructions: "Store below 30°C. Women should not handle crushed tablets.",
            description: "5-alpha reductase inhibitor for male pattern hair loss (1mg) and BPH (5mg).",
            isScheduleH: true
        ))

        db.append(DrugEntry(
            id: "minoxidil-topical", brandName: "Mintop", genericName: "Minoxidil",
            saltComposition: "Minoxidil 5%",
            category: .skinCare, manufacturer: "Dr. Reddy's",
            commonDosages: ["2%", "5%", "10%"], typicalDoseForm: "solution",
            priceRange: "₹300-600",
            genericAlternatives: [
                GenericAlternative(brandName: "Hair 4U", manufacturer: "Glenmark", priceRange: "₹250-500"),
                GenericAlternative(brandName: "Morr", manufacturer: "Intas", priceRange: "₹200-450")
            ],
            foodInteractions: ["Topical — no food interactions"],
            commonSideEffects: ["Scalp irritation", "Unwanted facial hair", "Dizziness", "Palpitations"],
            storageInstructions: "Store below 30°C.",
            description: "Topical solution for androgenetic alopecia (male and female pattern hair loss).",
            isScheduleH: true
        ))

        db.append(DrugEntry(
            id: "dutasteride", brandName: "Dutas", genericName: "Dutasteride",
            saltComposition: "Dutasteride 0.5mg",
            category: .other, manufacturer: "Dr. Reddy's",
            commonDosages: ["0.5mg"], typicalDoseForm: "capsule",
            priceRange: "₹100-250",
            genericAlternatives: [
                GenericAlternative(brandName: "Avodart", manufacturer: "GSK", priceRange: "₹200-400"),
                GenericAlternative(brandName: "Duprost", manufacturer: "Cipla", priceRange: "₹80-200")
            ],
            foodInteractions: ["Can be taken with or without food", "Swallow whole — do not crush"],
            commonSideEffects: ["Decreased libido", "Erectile dysfunction", "Breast tenderness", "Ejaculatory disorder"],
            storageInstructions: "Store below 30°C.",
            description: "5-alpha reductase inhibitor for BPH. More potent than finasteride.",
            isScheduleH: true
        ))

        db.append(DrugEntry(
            id: "rabeprazole-domperidone", brandName: "Razo-D", genericName: "Rabeprazole + Domperidone",
            saltComposition: "Rabeprazole 20mg + Domperidone 30mg SR",
            category: .antiAcid, manufacturer: "Dr. Reddy's",
            commonDosages: ["20/30mg"], typicalDoseForm: "capsule",
            priceRange: "₹80-150",
            genericAlternatives: [
                GenericAlternative(brandName: "Rablet-D", manufacturer: "Lupin", priceRange: "₹60-120"),
                GenericAlternative(brandName: "R-PPI-D", manufacturer: "Various", priceRange: "₹50-100")
            ],
            foodInteractions: ["Take on empty stomach, before meals"],
            commonSideEffects: ["Headache", "Dry mouth", "Diarrhoea", "Abdominal pain"],
            storageInstructions: "Store below 30°C.",
            description: "PPI + prokinetic for GERD with bloating and nausea.",
            isScheduleH: true
        ))

        db.append(DrugEntry(
            id: "dapoxetine", brandName: "Duralast", genericName: "Dapoxetine",
            saltComposition: "Dapoxetine 30mg",
            category: .other, manufacturer: "Sun Pharma",
            commonDosages: ["30mg", "60mg"], typicalDoseForm: "tablet",
            priceRange: "₹100-250",
            genericAlternatives: [
                GenericAlternative(brandName: "Poxet", manufacturer: "Sunrise", priceRange: "₹70-180"),
                GenericAlternative(brandName: "Sustinex", manufacturer: "Emcure", priceRange: "₹80-200")
            ],
            foodInteractions: ["Can be taken with or without food", "Avoid alcohol"],
            commonSideEffects: ["Nausea", "Dizziness", "Headache", "Diarrhoea", "Insomnia"],
            storageInstructions: "Store below 30°C.",
            description: "SSRI for premature ejaculation. Take 1-3 hours before intercourse.",
            isScheduleH: true
        ))

        db.append(DrugEntry(
            id: "misoprostol", brandName: "Cytotec", genericName: "Misoprostol",
            saltComposition: "Misoprostol 200mcg",
            category: .other, manufacturer: "Pfizer",
            commonDosages: ["100mcg", "200mcg"], typicalDoseForm: "tablet",
            priceRange: "₹30-70",
            genericAlternatives: [
                GenericAlternative(brandName: "Misoprost", manufacturer: "Cipla", priceRange: "₹20-50")
            ],
            foodInteractions: ["Take with food to reduce diarrhoea"],
            commonSideEffects: ["Diarrhoea", "Abdominal pain", "Nausea", "Flatulence"],
            storageInstructions: "Store below 25°C.",
            description: "Prostaglandin for NSAID-induced gastric ulcer prevention. Contraindicated in pregnancy.",
            isScheduleH: true
        ))

        db.append(DrugEntry(
            id: "ursodeoxycholic", brandName: "Udiliv", genericName: "Ursodeoxycholic Acid",
            saltComposition: "Ursodeoxycholic Acid 300mg",
            category: .other, manufacturer: "Abbott",
            commonDosages: ["150mg", "300mg", "450mg"], typicalDoseForm: "tablet",
            priceRange: "₹80-180",
            genericAlternatives: [
                GenericAlternative(brandName: "Ursocol", manufacturer: "Sun Pharma", priceRange: "₹55-120"),
                GenericAlternative(brandName: "Ursomax", manufacturer: "Mankind", priceRange: "₹50-110")
            ],
            foodInteractions: ["Take with meals"],
            commonSideEffects: ["Diarrhoea", "Nausea", "Stomach pain", "Itching"],
            storageInstructions: "Store below 30°C.",
            description: "Bile acid for gallstone dissolution and liver disease (cholestasis).",
            isScheduleH: true
        ))

        db.append(DrugEntry(
            id: "silymarin", brandName: "Silybon", genericName: "Silymarin (Milk Thistle)",
            saltComposition: "Silymarin 140mg",
            category: .other, manufacturer: "Micro Labs",
            commonDosages: ["70mg", "140mg"], typicalDoseForm: "capsule",
            priceRange: "₹80-160",
            genericAlternatives: [
                GenericAlternative(brandName: "Livolin", manufacturer: "Sun Pharma", priceRange: "₹60-120"),
                GenericAlternative(brandName: "Hepamerz", manufacturer: "Various", priceRange: "₹50-100")
            ],
            foodInteractions: ["Take with meals"],
            commonSideEffects: ["Diarrhoea", "Bloating", "Allergic reactions (rare)"],
            storageInstructions: "Store below 30°C.",
            description: "Hepatoprotective supplement for liver protection and fatty liver disease.",
            isScheduleH: false
        ))

        db.append(DrugEntry(
            id: "carbamazepine", brandName: "Tegrital", genericName: "Carbamazepine",
            saltComposition: "Carbamazepine 200mg",
            category: .other, manufacturer: "Novartis",
            commonDosages: ["100mg", "200mg", "400mg"], typicalDoseForm: "tablet",
            priceRange: "₹20-60",
            genericAlternatives: [
                GenericAlternative(brandName: "Zen Retard", manufacturer: "Sun Pharma", priceRange: "₹15-45"),
                GenericAlternative(brandName: "Mazetol", manufacturer: "Intas", priceRange: "₹12-40")
            ],
            foodInteractions: ["Take with food", "Avoid grapefruit juice", "Avoid alcohol"],
            commonSideEffects: ["Drowsiness", "Dizziness", "Nausea", "Rash", "Blood disorders (rare)"],
            storageInstructions: "Store below 30°C. Protect from moisture.",
            description: "Anticonvulsant for epilepsy, trigeminal neuralgia, and bipolar disorder.",
            isScheduleH: true
        ))

        db.append(DrugEntry(
            id: "phenytoin", brandName: "Eptoin", genericName: "Phenytoin",
            saltComposition: "Phenytoin Sodium 100mg",
            category: .other, manufacturer: "Abbott",
            commonDosages: ["50mg", "100mg", "300mg ER"], typicalDoseForm: "tablet",
            priceRange: "₹8-25",
            genericAlternatives: [
                GenericAlternative(brandName: "Dilantin", manufacturer: "Various", priceRange: "₹10-30")
            ],
            foodInteractions: ["Take with food to reduce stomach upset", "Avoid alcohol"],
            commonSideEffects: ["Gum overgrowth", "Nystagmus", "Drowsiness", "Rash", "Hirsutism"],
            storageInstructions: "Store below 30°C.",
            description: "Anticonvulsant for epilepsy. Narrow therapeutic index — regular monitoring needed.",
            isScheduleH: true
        ))

        db.append(DrugEntry(
            id: "levetiracetam", brandName: "Levipil", genericName: "Levetiracetam",
            saltComposition: "Levetiracetam 500mg",
            category: .other, manufacturer: "Sun Pharma",
            commonDosages: ["250mg", "500mg", "750mg", "1000mg"], typicalDoseForm: "tablet",
            priceRange: "₹60-140",
            genericAlternatives: [
                GenericAlternative(brandName: "Keppra", manufacturer: "UCB", priceRange: "₹120-280"),
                GenericAlternative(brandName: "Levera", manufacturer: "Intas", priceRange: "₹50-110")
            ],
            foodInteractions: ["Can be taken with or without food"],
            commonSideEffects: ["Drowsiness", "Dizziness", "Irritability", "Fatigue", "Headache"],
            storageInstructions: "Store below 30°C.",
            description: "Modern anticonvulsant for partial and generalized seizures. Fewer drug interactions.",
            isScheduleH: true
        ))

        db.append(DrugEntry(
            id: "lamotrigine", brandName: "Lamictal", genericName: "Lamotrigine",
            saltComposition: "Lamotrigine 25mg",
            category: .other, manufacturer: "GSK",
            commonDosages: ["25mg", "50mg", "100mg", "200mg"], typicalDoseForm: "tablet",
            priceRange: "₹40-100",
            genericAlternatives: [
                GenericAlternative(brandName: "Lacoset", manufacturer: "Sun Pharma", priceRange: "₹30-80"),
                GenericAlternative(brandName: "Lametec", manufacturer: "Cipla", priceRange: "₹25-70")
            ],
            foodInteractions: ["Can be taken with or without food"],
            commonSideEffects: ["Headache", "Dizziness", "Rash (SJS risk — start low, go slow)", "Nausea", "Insomnia"],
            storageInstructions: "Store below 30°C.",
            description: "Anticonvulsant for epilepsy and bipolar disorder maintenance. Must titrate slowly.",
            isScheduleH: true
        ))

        db.append(DrugEntry(
            id: "domperidone-rabe", brandName: "Veloz-D", genericName: "Rabeprazole + Domperidone",
            saltComposition: "Rabeprazole 20mg + Domperidone 30mg SR",
            category: .antiAcid, manufacturer: "Dr. Reddy's",
            commonDosages: ["20/30mg"], typicalDoseForm: "capsule",
            priceRange: "₹70-130",
            genericAlternatives: [
                GenericAlternative(brandName: "Razo-D", manufacturer: "Dr. Reddy's", priceRange: "₹80-150")
            ],
            foodInteractions: ["Take before meals on empty stomach"],
            commonSideEffects: ["Headache", "Dry mouth", "Diarrhoea"],
            storageInstructions: "Store below 30°C.",
            description: "PPI + antiemetic combination for acid reflux with nausea and bloating.",
            isScheduleH: true
        ))

        db.append(DrugEntry(
            id: "esomeprazole-domperidone", brandName: "Sompraz-D", genericName: "Esomeprazole + Domperidone",
            saltComposition: "Esomeprazole 40mg + Domperidone 30mg SR",
            category: .antiAcid, manufacturer: "Sun Pharma",
            commonDosages: ["40/30mg"], typicalDoseForm: "capsule",
            priceRange: "₹80-160",
            genericAlternatives: [
                GenericAlternative(brandName: "Raciper-D", manufacturer: "Cipla", priceRange: "₹60-120")
            ],
            foodInteractions: ["Take before meals on empty stomach"],
            commonSideEffects: ["Headache", "Dry mouth", "Diarrhoea", "Nausea"],
            storageInstructions: "Store below 30°C.",
            description: "PPI + prokinetic combination for GERD with dyspepsia.",
            isScheduleH: true
        ))

        db.append(DrugEntry(
            id: "acarbose", brandName: "Glucobay", genericName: "Acarbose",
            saltComposition: "Acarbose 25mg",
            category: .antidiabetic, manufacturer: "Bayer",
            commonDosages: ["25mg", "50mg", "100mg"], typicalDoseForm: "tablet",
            priceRange: "₹30-80",
            genericAlternatives: [
                GenericAlternative(brandName: "Acarb", manufacturer: "Various", priceRange: "₹20-55")
            ],
            foodInteractions: ["Take with the first bite of each main meal"],
            commonSideEffects: ["Flatulence", "Bloating", "Diarrhoea", "Abdominal pain"],
            storageInstructions: "Store below 30°C.",
            description: "Alpha-glucosidase inhibitor to control post-meal blood sugar spikes.",
            isScheduleH: true
        ))

        db.append(DrugEntry(
            id: "repaglinide", brandName: "Eurepa", genericName: "Repaglinide",
            saltComposition: "Repaglinide 0.5mg",
            category: .antidiabetic, manufacturer: "Torrent",
            commonDosages: ["0.5mg", "1mg", "2mg"], typicalDoseForm: "tablet",
            priceRange: "₹30-80",
            genericAlternatives: [
                GenericAlternative(brandName: "Novonorm", manufacturer: "Novo Nordisk", priceRange: "₹50-120"),
                GenericAlternative(brandName: "Regan", manufacturer: "Various", priceRange: "₹25-60")
            ],
            foodInteractions: ["Take 15 minutes before meals", "Skip dose if skipping meal"],
            commonSideEffects: ["Hypoglycemia", "Weight gain", "Headache", "Nausea"],
            storageInstructions: "Store below 30°C.",
            description: "Meglitinide for mealtime glucose control. Shorter action than sulfonylureas.",
            isScheduleH: true
        ))

        db.append(DrugEntry(
            id: "insulin-nph", brandName: "Huminsulin N", genericName: "Insulin NPH (Isophane)",
            saltComposition: "Isophane Insulin 40 IU/ml",
            category: .antidiabetic, manufacturer: "Eli Lilly",
            commonDosages: ["40 IU/ml", "100 IU/ml"], typicalDoseForm: "injection",
            priceRange: "₹120-350",
            genericAlternatives: [
                GenericAlternative(brandName: "Insugen-N", manufacturer: "Biocon", priceRange: "₹100-280"),
                GenericAlternative(brandName: "Wosulin-N", manufacturer: "Wockhardt", priceRange: "₹90-260")
            ],
            foodInteractions: ["Inject 30 minutes before meals", "Do not skip meals after injection"],
            commonSideEffects: ["Hypoglycemia", "Weight gain", "Injection site reactions"],
            storageInstructions: "Store in fridge. Roll gently before use.",
            description: "Intermediate-acting insulin for basal coverage in diabetes.",
            isScheduleH: true
        ))

        db.append(DrugEntry(
            id: "liraglutide", brandName: "Victoza", genericName: "Liraglutide",
            saltComposition: "Liraglutide 6mg/ml",
            category: .antidiabetic, manufacturer: "Novo Nordisk",
            commonDosages: ["0.6mg", "1.2mg", "1.8mg"], typicalDoseForm: "injection",
            priceRange: "₹3000-5000",
            genericAlternatives: [],
            foodInteractions: ["Can be injected at any time, independent of meals"],
            commonSideEffects: ["Nausea", "Vomiting", "Diarrhoea", "Headache", "Pancreatitis (rare)"],
            storageInstructions: "Store unopened in fridge. In-use pen at room temperature for 30 days.",
            description: "GLP-1 receptor agonist for Type 2 diabetes. Also promotes weight loss.",
            isScheduleH: true
        ))

        db.append(DrugEntry(
            id: "semaglutide", brandName: "Ozempic", genericName: "Semaglutide",
            saltComposition: "Semaglutide 1.34mg/ml",
            category: .antidiabetic, manufacturer: "Novo Nordisk",
            commonDosages: ["0.25mg", "0.5mg", "1mg", "2mg"], typicalDoseForm: "injection",
            priceRange: "₹5000-10000",
            genericAlternatives: [],
            foodInteractions: ["Inject once weekly, any time of day, with or without meals"],
            commonSideEffects: ["Nausea", "Vomiting", "Diarrhoea", "Constipation", "Pancreatitis (rare)"],
            storageInstructions: "Store unopened in fridge. In-use pen at room temperature for 56 days.",
            description: "Once-weekly GLP-1 agonist for Type 2 diabetes. Significant weight loss and CV benefits.",
            isScheduleH: true
        ))

        db.append(DrugEntry(
            id: "dexamethasone", brandName: "Dexona", genericName: "Dexamethasone",
            saltComposition: "Dexamethasone 0.5mg",
            category: .other, manufacturer: "Zydus Cadila",
            commonDosages: ["0.5mg", "4mg", "8mg"], typicalDoseForm: "tablet",
            priceRange: "₹5-20",
            genericAlternatives: [
                GenericAlternative(brandName: "Decadron", manufacturer: "Various", priceRange: "₹4-15")
            ],
            foodInteractions: ["Take with food"],
            commonSideEffects: ["Weight gain", "Mood changes", "Insomnia", "Blood sugar elevation", "Immunosuppression"],
            storageInstructions: "Store below 30°C.",
            description: "Potent corticosteroid for inflammation, allergies, cerebral oedema, and COVID-19.",
            isScheduleH: true
        ))

        db.append(DrugEntry(
            id: "betahistine", brandName: "Vertin", genericName: "Betahistine",
            saltComposition: "Betahistine 16mg",
            category: .other, manufacturer: "Abbott",
            commonDosages: ["8mg", "16mg", "24mg"], typicalDoseForm: "tablet",
            priceRange: "₹40-100",
            genericAlternatives: [
                GenericAlternative(brandName: "Merislon", manufacturer: "Eisai", priceRange: "₹50-120"),
                GenericAlternative(brandName: "Betaserc", manufacturer: "Various", priceRange: "₹45-110")
            ],
            foodInteractions: ["Take with meals"],
            commonSideEffects: ["Nausea", "Headache", "Stomach upset", "Bloating"],
            storageInstructions: "Store below 30°C.",
            description: "For vertigo and Meniere's disease. Improves blood flow in the inner ear.",
            isScheduleH: true
        ))

        db.append(DrugEntry(
            id: "cinnarizine", brandName: "Stugeron", genericName: "Cinnarizine",
            saltComposition: "Cinnarizine 25mg",
            category: .other, manufacturer: "Janssen",
            commonDosages: ["25mg", "75mg"], typicalDoseForm: "tablet",
            priceRange: "₹20-50",
            genericAlternatives: [
                GenericAlternative(brandName: "Cinzan", manufacturer: "Various", priceRange: "₹12-30")
            ],
            foodInteractions: ["Take after food"],
            commonSideEffects: ["Drowsiness", "Weight gain", "Stomach upset", "Dry mouth"],
            storageInstructions: "Store below 30°C.",
            description: "Antivertigo and anti-motion sickness medicine. Also used for peripheral vascular disease.",
            isScheduleH: true
        ))

        db.append(DrugEntry(
            id: "dimenhydrinate", brandName: "Dramamine", genericName: "Dimenhydrinate",
            saltComposition: "Dimenhydrinate 50mg",
            category: .other, manufacturer: "Various",
            commonDosages: ["25mg", "50mg"], typicalDoseForm: "tablet",
            priceRange: "₹15-35",
            genericAlternatives: [
                GenericAlternative(brandName: "Avomine", manufacturer: "Sanofi", priceRange: "₹12-30")
            ],
            foodInteractions: ["Take 30 minutes before travel"],
            commonSideEffects: ["Drowsiness", "Dry mouth", "Blurred vision", "Constipation"],
            storageInstructions: "Store below 30°C.",
            description: "OTC medicine for motion sickness, nausea, and vomiting.",
            isScheduleH: false
        ))

        db.append(DrugEntry(
            id: "modafinil", brandName: "Modalert", genericName: "Modafinil",
            saltComposition: "Modafinil 200mg",
            category: .other, manufacturer: "Sun Pharma",
            commonDosages: ["100mg", "200mg"], typicalDoseForm: "tablet",
            priceRange: "₹100-250",
            genericAlternatives: [
                GenericAlternative(brandName: "Provigil", manufacturer: "Cephalon", priceRange: "₹200-400"),
                GenericAlternative(brandName: "Modasomil", manufacturer: "Various", priceRange: "₹80-180")
            ],
            foodInteractions: ["Can be taken with or without food"],
            commonSideEffects: ["Headache", "Nausea", "Insomnia", "Nervousness", "Dizziness"],
            storageInstructions: "Store below 30°C.",
            description: "Wakefulness promoter for narcolepsy, shift-work sleep disorder, and excessive sleepiness.",
            isScheduleH: true
        ))

        db.append(DrugEntry(
            id: "montelukast-5", brandName: "Montair 5", genericName: "Montelukast",
            saltComposition: "Montelukast 5mg",
            category: .respiratory, manufacturer: "Cipla",
            commonDosages: ["5mg"], typicalDoseForm: "chewable tablet",
            priceRange: "₹70-130",
            genericAlternatives: [
                GenericAlternative(brandName: "Montek 5", manufacturer: "Sun Pharma", priceRange: "₹50-100")
            ],
            foodInteractions: ["Take in the evening", "Can be taken with or without food"],
            commonSideEffects: ["Headache", "Abdominal pain", "Diarrhoea", "Mood changes (rare)"],
            storageInstructions: "Store below 30°C.",
            description: "Chewable montelukast for asthma and allergies in children aged 6-14 years.",
            isScheduleH: true
        ))

        db.append(DrugEntry(
            id: "salbutamol-ipr", brandName: "Duolin", genericName: "Salbutamol + Ipratropium",
            saltComposition: "Salbutamol 100mcg + Ipratropium 20mcg",
            category: .respiratory, manufacturer: "Cipla",
            commonDosages: ["100/20mcg per puff"], typicalDoseForm: "inhaler",
            priceRange: "₹120-220",
            genericAlternatives: [
                GenericAlternative(brandName: "Combivent", manufacturer: "Boehringer", priceRange: "₹150-280")
            ],
            foodInteractions: ["No food interactions"],
            commonSideEffects: ["Tremor", "Palpitations", "Dry mouth", "Cough", "Headache"],
            storageInstructions: "Store below 30°C.",
            description: "Dual bronchodilator combination for COPD and severe asthma.",
            isScheduleH: true
        ))

        db.append(DrugEntry(
            id: "bilastine", brandName: "Bilasure", genericName: "Bilastine",
            saltComposition: "Bilastine 20mg",
            category: .antiAllergy, manufacturer: "Sun Pharma",
            commonDosages: ["20mg"], typicalDoseForm: "tablet",
            priceRange: "₹80-160",
            genericAlternatives: [
                GenericAlternative(brandName: "Bilazone", manufacturer: "Mankind", priceRange: "₹50-100")
            ],
            foodInteractions: ["Take on empty stomach, 1 hour before or 2 hours after food"],
            commonSideEffects: ["Headache", "Drowsiness (minimal)", "Dizziness"],
            storageInstructions: "Store below 30°C.",
            description: "Second-generation non-sedating antihistamine for allergic rhinitis and urticaria.",
            isScheduleH: true
        ))

        db.append(DrugEntry(
            id: "desloratadine", brandName: "Deslor", genericName: "Desloratadine",
            saltComposition: "Desloratadine 5mg",
            category: .antiAllergy, manufacturer: "Various",
            commonDosages: ["5mg"], typicalDoseForm: "tablet",
            priceRange: "₹40-80",
            genericAlternatives: [
                GenericAlternative(brandName: "Aerius", manufacturer: "MSD", priceRange: "₹80-160")
            ],
            foodInteractions: ["Can be taken with or without food"],
            commonSideEffects: ["Headache", "Dry mouth", "Fatigue (minimal)"],
            storageInstructions: "Store below 30°C.",
            description: "Non-sedating antihistamine, active metabolite of loratadine.",
            isScheduleH: true
        ))

        db.append(DrugEntry(
            id: "loratadine", brandName: "Lorfast", genericName: "Loratadine",
            saltComposition: "Loratadine 10mg",
            category: .antiAllergy, manufacturer: "Cipla",
            commonDosages: ["10mg"], typicalDoseForm: "tablet",
            priceRange: "₹30-70",
            genericAlternatives: [
                GenericAlternative(brandName: "Claritin", manufacturer: "MSD", priceRange: "₹60-120"),
                GenericAlternative(brandName: "Alaspan", manufacturer: "Sun Pharma", priceRange: "₹25-55")
            ],
            foodInteractions: ["Can be taken with or without food"],
            commonSideEffects: ["Headache", "Drowsiness (minimal)", "Dry mouth", "Fatigue"],
            storageInstructions: "Store below 30°C.",
            description: "Non-sedating OTC antihistamine for allergic rhinitis and urticaria.",
            isScheduleH: false
        ))

        db.append(DrugEntry(
            id: "hydroxyzine", brandName: "Atarax", genericName: "Hydroxyzine",
            saltComposition: "Hydroxyzine Hydrochloride 25mg",
            category: .antiAllergy, manufacturer: "UCB",
            commonDosages: ["10mg", "25mg"], typicalDoseForm: "tablet",
            priceRange: "₹20-50",
            genericAlternatives: [
                GenericAlternative(brandName: "HZN", manufacturer: "Various", priceRange: "₹12-30")
            ],
            foodInteractions: ["Can be taken with or without food", "Avoid alcohol"],
            commonSideEffects: ["Drowsiness", "Dry mouth", "Dizziness", "Blurred vision"],
            storageInstructions: "Store below 30°C.",
            description: "First-generation antihistamine for itching, anxiety, and as a pre-operative sedative.",
            isScheduleH: true
        ))

        // ════════════════════════════════════════════
        // BATCH 2 — ADDITIONAL ENTRIES TO REACH 500+
        // ════════════════════════════════════════════

        // ── DIABETES ADDITIONAL ──

        db.append(DrugEntry(
            id: "metformin-linagliptin", brandName: "Trajenta Met", genericName: "Metformin + Linagliptin",
            saltComposition: "Metformin 500mg + Linagliptin 2.5mg",
            category: .antidiabetic, manufacturer: "Boehringer Ingelheim",
            commonDosages: ["500/2.5mg", "1000/2.5mg"], typicalDoseForm: "tablet",
            priceRange: "₹350-550",
            genericAlternatives: [
                GenericAlternative(brandName: "Linares-M", manufacturer: "USV", priceRange: "₹250-400")
            ],
            foodInteractions: ["Take with meals"],
            commonSideEffects: ["Nausea", "Diarrhoea", "Nasopharyngitis", "Hypoglycemia (with SU)"],
            storageInstructions: "Store below 30°C.",
            description: "Metformin + DPP-4 inhibitor. Safe in renal impairment (no dose adjustment for linagliptin).",
            isScheduleH: true
        ))

        db.append(DrugEntry(
            id: "glimepiride-met-vogli", brandName: "Trio Glycomet", genericName: "Glimepiride + Metformin + Voglibose",
            saltComposition: "Glimepiride 2mg + Metformin 500mg + Voglibose 0.3mg",
            category: .antidiabetic, manufacturer: "USV",
            commonDosages: ["2/500/0.3mg"], typicalDoseForm: "tablet",
            priceRange: "₹90-170",
            genericAlternatives: [],
            foodInteractions: ["Take with the first bite of a meal"],
            commonSideEffects: ["Hypoglycemia", "Flatulence", "Nausea", "Diarrhoea"],
            storageInstructions: "Store below 30°C.",
            description: "Triple diabetes combo: sulfonylurea + biguanide + alpha-glucosidase inhibitor.",
            isScheduleH: true
        ))

        db.append(DrugEntry(
            id: "gliclazide-mr", brandName: "Glizid MR", genericName: "Gliclazide MR",
            saltComposition: "Gliclazide 60mg MR",
            category: .antidiabetic, manufacturer: "Sun Pharma",
            commonDosages: ["30mg MR", "60mg MR"], typicalDoseForm: "tablet",
            priceRange: "₹50-100",
            genericAlternatives: [
                GenericAlternative(brandName: "Diamicron MR", manufacturer: "Serdia", priceRange: "₹60-120")
            ],
            foodInteractions: ["Take with breakfast"],
            commonSideEffects: ["Hypoglycemia", "Weight gain", "Nausea"],
            storageInstructions: "Store below 30°C.",
            description: "Modified-release gliclazide for once-daily dosing in Type 2 diabetes.",
            isScheduleH: true
        ))

        db.append(DrugEntry(
            id: "dulaglutide", brandName: "Trulicity", genericName: "Dulaglutide",
            saltComposition: "Dulaglutide 1.5mg/0.5ml",
            category: .antidiabetic, manufacturer: "Eli Lilly",
            commonDosages: ["0.75mg", "1.5mg", "3mg", "4.5mg"], typicalDoseForm: "injection",
            priceRange: "₹3500-7000",
            genericAlternatives: [],
            foodInteractions: ["Inject once weekly, any time, with or without meals"],
            commonSideEffects: ["Nausea", "Diarrhoea", "Vomiting", "Abdominal pain", "Decreased appetite"],
            storageInstructions: "Store in fridge. Can be at room temp for up to 14 days.",
            description: "Once-weekly GLP-1 agonist for Type 2 diabetes with cardiovascular benefits.",
            isScheduleH: true
        ))

        db.append(DrugEntry(
            id: "empagliflozin-linagliptin", brandName: "Glyxambi", genericName: "Empagliflozin + Linagliptin",
            saltComposition: "Empagliflozin 10mg + Linagliptin 5mg",
            category: .antidiabetic, manufacturer: "Boehringer Ingelheim",
            commonDosages: ["10/5mg", "25/5mg"], typicalDoseForm: "tablet",
            priceRange: "₹450-700",
            genericAlternatives: [],
            foodInteractions: ["Can be taken with or without food"],
            commonSideEffects: ["UTI", "Genital fungal infections", "Nasopharyngitis", "Frequent urination"],
            storageInstructions: "Store below 30°C.",
            description: "SGLT2 + DPP-4 inhibitor combination for Type 2 diabetes.",
            isScheduleH: true
        ))

        db.append(DrugEntry(
            id: "insulin-lispro", brandName: "Humalog", genericName: "Insulin Lispro",
            saltComposition: "Insulin Lispro 100 IU/ml",
            category: .antidiabetic, manufacturer: "Eli Lilly",
            commonDosages: ["100 IU/ml"], typicalDoseForm: "injection",
            priceRange: "₹700-1300",
            genericAlternatives: [
                GenericAlternative(brandName: "Admelog", manufacturer: "Sanofi", priceRange: "₹500-1000")
            ],
            foodInteractions: ["Inject just before or immediately after meals"],
            commonSideEffects: ["Hypoglycemia", "Weight gain", "Injection site reactions", "Lipodystrophy"],
            storageInstructions: "Store in fridge. In-use pen at room temperature for 28 days.",
            description: "Rapid-acting insulin analogue for mealtime glucose control.",
            isScheduleH: true
        ))

        db.append(DrugEntry(
            id: "dapagliflozin-met", brandName: "Dapavel-M", genericName: "Dapagliflozin + Metformin",
            saltComposition: "Dapagliflozin 10mg + Metformin 500mg",
            category: .antidiabetic, manufacturer: "Sun Pharma",
            commonDosages: ["10/500mg", "10/1000mg", "5/500mg"], typicalDoseForm: "tablet",
            priceRange: "₹200-380",
            genericAlternatives: [
                GenericAlternative(brandName: "Xigduo", manufacturer: "AstraZeneca", priceRange: "₹350-550")
            ],
            foodInteractions: ["Take with meals", "Increase water intake"],
            commonSideEffects: ["Nausea", "UTI", "Genital fungal infections", "Diarrhoea"],
            storageInstructions: "Store below 30°C.",
            description: "Generic SGLT2 + metformin combination for diabetes management.",
            isScheduleH: true
        ))

        // ── CARDIAC ADDITIONAL ──

        db.append(DrugEntry(
            id: "atorvastatin-aspirin", brandName: "Ecosprin-AV 75/10", genericName: "Aspirin + Atorvastatin",
            saltComposition: "Aspirin 75mg + Atorvastatin 10mg",
            category: .cardiovascular, manufacturer: "USV",
            commonDosages: ["75/10mg", "75/20mg"], typicalDoseForm: "capsule",
            priceRange: "₹40-100",
            genericAlternatives: [],
            foodInteractions: ["Take with food", "Avoid grapefruit juice"],
            commonSideEffects: ["Stomach pain", "Muscle pain", "Heartburn"],
            storageInstructions: "Store below 30°C.",
            description: "Antiplatelet + statin combo for cardiovascular risk reduction.",
            isScheduleH: true
        ))

        db.append(DrugEntry(
            id: "telmisartan-cilnidipine", brandName: "Telma-CN", genericName: "Telmisartan + Cilnidipine",
            saltComposition: "Telmisartan 40mg + Cilnidipine 10mg",
            category: .antihypertensive, manufacturer: "Glenmark",
            commonDosages: ["40/10mg", "80/10mg"], typicalDoseForm: "tablet",
            priceRange: "₹120-220",
            genericAlternatives: [
                GenericAlternative(brandName: "Telmikind-CN", manufacturer: "Mankind", priceRange: "₹80-160")
            ],
            foodInteractions: ["Take after food"],
            commonSideEffects: ["Dizziness", "Headache", "Flushing", "Fatigue"],
            storageInstructions: "Store below 30°C.",
            description: "ARB + N-type CCB for hypertension. Less pedal oedema than amlodipine combos.",
            isScheduleH: true
        ))

        db.append(DrugEntry(
            id: "olmesartan-amlodipine", brandName: "Olmezest-AM", genericName: "Olmesartan + Amlodipine",
            saltComposition: "Olmesartan 20mg + Amlodipine 5mg",
            category: .antihypertensive, manufacturer: "Sun Pharma",
            commonDosages: ["20/5mg", "40/5mg"], typicalDoseForm: "tablet",
            priceRange: "₹100-200",
            genericAlternatives: [
                GenericAlternative(brandName: "Olmy-AM", manufacturer: "Micro Labs", priceRange: "₹70-140")
            ],
            foodInteractions: ["Can be taken with or without food"],
            commonSideEffects: ["Dizziness", "Ankle swelling", "Headache", "Diarrhoea"],
            storageInstructions: "Store below 30°C.",
            description: "ARB + CCB combination for hypertension.",
            isScheduleH: true
        ))

        db.append(DrugEntry(
            id: "olmesartan-hctz", brandName: "Olmezest-H", genericName: "Olmesartan + Hydrochlorothiazide",
            saltComposition: "Olmesartan 20mg + HCTZ 12.5mg",
            category: .antihypertensive, manufacturer: "Sun Pharma",
            commonDosages: ["20/12.5mg", "40/12.5mg"], typicalDoseForm: "tablet",
            priceRange: "₹90-180",
            genericAlternatives: [],
            foodInteractions: ["Can be taken with or without food", "Stay hydrated"],
            commonSideEffects: ["Dizziness", "Frequent urination", "Fatigue", "Low potassium"],
            storageInstructions: "Store below 30°C.",
            description: "ARB + diuretic combination for hypertension.",
            isScheduleH: true
        ))

        db.append(DrugEntry(
            id: "amlodipine-telmisartan-hctz", brandName: "Telma-AMH", genericName: "Telmisartan + Amlodipine + HCTZ",
            saltComposition: "Telmisartan 40mg + Amlodipine 5mg + HCTZ 12.5mg",
            category: .antihypertensive, manufacturer: "Glenmark",
            commonDosages: ["40/5/12.5mg"], typicalDoseForm: "tablet",
            priceRange: "₹130-250",
            genericAlternatives: [],
            foodInteractions: ["Can be taken with or without food", "Stay hydrated"],
            commonSideEffects: ["Dizziness", "Ankle swelling", "Frequent urination", "Fatigue"],
            storageInstructions: "Store below 30°C.",
            description: "Triple antihypertensive combo: ARB + CCB + diuretic for resistant hypertension.",
            isScheduleH: true
        ))

        db.append(DrugEntry(
            id: "dabigatran", brandName: "Pradaxa", genericName: "Dabigatran",
            saltComposition: "Dabigatran Etexilate 150mg",
            category: .cardiovascular, manufacturer: "Boehringer Ingelheim",
            commonDosages: ["75mg", "110mg", "150mg"], typicalDoseForm: "capsule",
            priceRange: "₹250-500",
            genericAlternatives: [
                GenericAlternative(brandName: "Dabigran", manufacturer: "Cipla", priceRange: "₹150-300")
            ],
            foodInteractions: ["Can be taken with or without food", "Swallow whole — do not crush"],
            commonSideEffects: ["Bleeding", "Dyspepsia", "Gastritis", "Nausea"],
            storageInstructions: "Store below 30°C. Keep in original packaging.",
            description: "Direct thrombin inhibitor (DOAC) for atrial fibrillation and DVT/PE.",
            isScheduleH: true
        ))

        db.append(DrugEntry(
            id: "acenocoumarol", brandName: "Acitrom", genericName: "Acenocoumarol",
            saltComposition: "Acenocoumarol 2mg",
            category: .cardiovascular, manufacturer: "Abbott",
            commonDosages: ["1mg", "2mg", "4mg"], typicalDoseForm: "tablet",
            priceRange: "₹20-50",
            genericAlternatives: [
                GenericAlternative(brandName: "Syntrom", manufacturer: "Various", priceRange: "₹15-40")
            ],
            foodInteractions: ["Maintain consistent Vitamin K intake", "Avoid alcohol", "Avoid cranberry juice"],
            commonSideEffects: ["Bleeding", "Bruising", "Nausea", "Rash"],
            storageInstructions: "Store below 30°C. Protect from light.",
            description: "Oral anticoagulant (shorter-acting than warfarin). Common in India. Regular INR monitoring.",
            isScheduleH: true
        ))

        db.append(DrugEntry(
            id: "nicorandil", brandName: "Korandil", genericName: "Nicorandil",
            saltComposition: "Nicorandil 5mg",
            category: .cardiovascular, manufacturer: "Torrent",
            commonDosages: ["5mg", "10mg", "20mg"], typicalDoseForm: "tablet",
            priceRange: "₹30-70",
            genericAlternatives: [
                GenericAlternative(brandName: "Nikoran", manufacturer: "Sun Pharma", priceRange: "₹20-50")
            ],
            foodInteractions: ["Can be taken with or without food", "Avoid alcohol"],
            commonSideEffects: ["Headache", "Dizziness", "Nausea", "Flushing"],
            storageInstructions: "Store below 30°C.",
            description: "Potassium channel opener + nitrate for stable angina. Dual mechanism.",
            isScheduleH: true
        ))

        db.append(DrugEntry(
            id: "rosuvastatin-aspirin-clop", brandName: "Rozavel-ASP", genericName: "Rosuvastatin + Aspirin + Clopidogrel",
            saltComposition: "Rosuvastatin 10mg + Aspirin 75mg + Clopidogrel 75mg",
            category: .cardiovascular, manufacturer: "Sun Pharma",
            commonDosages: ["10/75/75mg"], typicalDoseForm: "capsule",
            priceRange: "₹120-250",
            genericAlternatives: [],
            foodInteractions: ["Take with food"],
            commonSideEffects: ["Bleeding", "Muscle pain", "Stomach pain", "Nausea"],
            storageInstructions: "Store below 30°C.",
            description: "Triple cardiovascular combo: statin + dual antiplatelet post-stent.",
            isScheduleH: true
        ))

        db.append(DrugEntry(
            id: "torsemide-spiro", brandName: "Dytor Plus", genericName: "Torsemide + Spironolactone",
            saltComposition: "Torsemide 10mg + Spironolactone 25mg",
            category: .cardiovascular, manufacturer: "Cipla",
            commonDosages: ["10/25mg", "10/50mg", "20/50mg"], typicalDoseForm: "tablet",
            priceRange: "₹40-90",
            genericAlternatives: [
                GenericAlternative(brandName: "Torsinex Plus", manufacturer: "Glenmark", priceRange: "₹30-70")
            ],
            foodInteractions: ["Take in the morning with food"],
            commonSideEffects: ["Frequent urination", "Dizziness", "Hyperkalemia", "Nausea"],
            storageInstructions: "Store below 30°C.",
            description: "Loop diuretic + K-sparing diuretic combination for heart failure and ascites.",
            isScheduleH: true
        ))

        db.append(DrugEntry(
            id: "furosemide-spiro", brandName: "Lasilactone", genericName: "Furosemide + Spironolactone",
            saltComposition: "Furosemide 20mg + Spironolactone 50mg",
            category: .cardiovascular, manufacturer: "Sanofi",
            commonDosages: ["20/50mg"], typicalDoseForm: "tablet",
            priceRange: "₹30-65",
            genericAlternatives: [
                GenericAlternative(brandName: "Fruselac Plus", manufacturer: "Micro Labs", priceRange: "₹20-45")
            ],
            foodInteractions: ["Take in the morning with food", "Avoid potassium-rich salt substitutes"],
            commonSideEffects: ["Frequent urination", "Dizziness", "Electrolyte imbalance"],
            storageInstructions: "Store below 30°C.",
            description: "Loop + K-sparing diuretic for heart failure, liver cirrhosis ascites.",
            isScheduleH: true
        ))

        // ── ANTIBIOTICS ADDITIONAL ──

        db.append(DrugEntry(
            id: "ceftriaxone-sulbactam", brandName: "Monotax-SB", genericName: "Ceftriaxone + Sulbactam",
            saltComposition: "Ceftriaxone 1g + Sulbactam 500mg",
            category: .antibiotic, manufacturer: "Various",
            commonDosages: ["1g/500mg", "1.5g"], typicalDoseForm: "injection",
            priceRange: "₹100-250",
            genericAlternatives: [],
            foodInteractions: ["Injectable — no direct food interactions"],
            commonSideEffects: ["Pain at injection site", "Diarrhoea", "Rash", "Nausea"],
            storageInstructions: "Store below 25°C. Use reconstituted solution promptly.",
            description: "Cephalosporin + beta-lactamase inhibitor for severe bacterial infections.",
            isScheduleH: true
        ))

        db.append(DrugEntry(
            id: "piperacillin-tazobactam", brandName: "Tazact", genericName: "Piperacillin + Tazobactam",
            saltComposition: "Piperacillin 4g + Tazobactam 500mg",
            category: .antibiotic, manufacturer: "Sun Pharma",
            commonDosages: ["4.5g"], typicalDoseForm: "injection",
            priceRange: "₹250-600",
            genericAlternatives: [
                GenericAlternative(brandName: "Pizon TZ", manufacturer: "Cipla", priceRange: "₹200-450")
            ],
            foodInteractions: ["Injectable — no direct food interactions"],
            commonSideEffects: ["Diarrhoea", "Nausea", "Headache", "Rash", "Phlebitis"],
            storageInstructions: "Store below 25°C.",
            description: "Broad-spectrum IV antibiotic for hospital-acquired and polymicrobial infections.",
            isScheduleH: true
        ))

        db.append(DrugEntry(
            id: "vancomycin", brandName: "Vancocin", genericName: "Vancomycin",
            saltComposition: "Vancomycin 500mg",
            category: .antibiotic, manufacturer: "Various",
            commonDosages: ["500mg", "1g"], typicalDoseForm: "injection",
            priceRange: "₹150-400",
            genericAlternatives: [
                GenericAlternative(brandName: "Vanco", manufacturer: "Cipla", priceRange: "₹100-300")
            ],
            foodInteractions: ["Injectable — no direct food interactions"],
            commonSideEffects: ["Red man syndrome (fast infusion)", "Nephrotoxicity", "Ototoxicity", "Phlebitis"],
            storageInstructions: "Store below 25°C.",
            description: "Glycopeptide antibiotic for MRSA and C. difficile. Requires TDM.",
            isScheduleH: true
        ))

        db.append(DrugEntry(
            id: "colistin", brandName: "Colistop", genericName: "Colistimethate Sodium",
            saltComposition: "Colistimethate Sodium 1MIU",
            category: .antibiotic, manufacturer: "Various",
            commonDosages: ["1MIU", "2MIU"], typicalDoseForm: "injection",
            priceRange: "₹200-500",
            genericAlternatives: [],
            foodInteractions: ["Injectable — no direct food interactions"],
            commonSideEffects: ["Nephrotoxicity", "Neurotoxicity", "Bronchospasm", "Rash"],
            storageInstructions: "Store below 25°C.",
            description: "Last-resort antibiotic for multi-drug resistant gram-negative infections.",
            isScheduleH: true
        ))

        db.append(DrugEntry(
            id: "amikacin", brandName: "Amikacin", genericName: "Amikacin",
            saltComposition: "Amikacin 500mg/2ml",
            category: .antibiotic, manufacturer: "Various",
            commonDosages: ["100mg", "250mg", "500mg"], typicalDoseForm: "injection",
            priceRange: "₹20-60",
            genericAlternatives: [
                GenericAlternative(brandName: "Amikin", manufacturer: "Various", priceRange: "₹15-50")
            ],
            foodInteractions: ["Injectable — no direct food interactions"],
            commonSideEffects: ["Nephrotoxicity", "Ototoxicity", "Nausea", "Rash"],
            storageInstructions: "Store below 30°C.",
            description: "Aminoglycoside for serious gram-negative infections. Monitor kidney function.",
            isScheduleH: true
        ))

        db.append(DrugEntry(
            id: "gentamicin", brandName: "Garamycin", genericName: "Gentamicin",
            saltComposition: "Gentamicin 80mg/2ml",
            category: .antibiotic, manufacturer: "Various",
            commonDosages: ["40mg", "80mg"], typicalDoseForm: "injection",
            priceRange: "₹8-20",
            genericAlternatives: [],
            foodInteractions: ["Injectable — no direct food interactions"],
            commonSideEffects: ["Nephrotoxicity", "Ototoxicity", "Nausea", "Neuromuscular blockade (rare)"],
            storageInstructions: "Store below 30°C.",
            description: "Aminoglycoside antibiotic for serious gram-negative infections.",
            isScheduleH: true
        ))

        db.append(DrugEntry(
            id: "cefoperazone-sulbactam", brandName: "Magnex", genericName: "Cefoperazone + Sulbactam",
            saltComposition: "Cefoperazone 1g + Sulbactam 500mg",
            category: .antibiotic, manufacturer: "Cipla",
            commonDosages: ["1g/500mg", "2g/1g"], typicalDoseForm: "injection",
            priceRange: "₹150-400",
            genericAlternatives: [
                GenericAlternative(brandName: "Cefact", manufacturer: "Sun Pharma", priceRange: "₹120-350")
            ],
            foodInteractions: ["Injectable — no direct food interactions", "Avoid alcohol for 72 hours"],
            commonSideEffects: ["Diarrhoea", "Nausea", "Rash", "Coagulation disorders (Vitamin K def)"],
            storageInstructions: "Store below 25°C.",
            description: "Broad-spectrum IV antibiotic with beta-lactamase inhibitor for severe infections.",
            isScheduleH: true
        ))

        db.append(DrugEntry(
            id: "ampicillin-cloxacillin", brandName: "Megapen", genericName: "Ampicillin + Cloxacillin",
            saltComposition: "Ampicillin 250mg + Cloxacillin 250mg",
            category: .antibiotic, manufacturer: "Aristo",
            commonDosages: ["250/250mg", "500/500mg"], typicalDoseForm: "capsule",
            priceRange: "₹30-60",
            genericAlternatives: [],
            foodInteractions: ["Take on empty stomach"],
            commonSideEffects: ["Diarrhoea", "Nausea", "Rash", "Stomach pain"],
            storageInstructions: "Store below 25°C.",
            description: "Dual penicillin combination for mixed gram-positive infections.",
            isScheduleH: true
        ))

        db.append(DrugEntry(
            id: "roxithromycin", brandName: "Roxid", genericName: "Roxithromycin",
            saltComposition: "Roxithromycin 150mg",
            category: .antibiotic, manufacturer: "Sun Pharma",
            commonDosages: ["150mg", "300mg"], typicalDoseForm: "tablet",
            priceRange: "₹40-90",
            genericAlternatives: [
                GenericAlternative(brandName: "Surlid", manufacturer: "Sanofi", priceRange: "₹50-100")
            ],
            foodInteractions: ["Take on empty stomach, 15 min before meals"],
            commonSideEffects: ["Nausea", "Diarrhoea", "Abdominal pain", "Headache"],
            storageInstructions: "Store below 30°C.",
            description: "Macrolide antibiotic for respiratory, skin, and urogenital infections.",
            isScheduleH: true
        ))

        db.append(DrugEntry(
            id: "erythromycin", brandName: "Erythrocin", genericName: "Erythromycin",
            saltComposition: "Erythromycin Stearate 500mg",
            category: .antibiotic, manufacturer: "Abbott",
            commonDosages: ["250mg", "500mg"], typicalDoseForm: "tablet",
            priceRange: "₹20-50",
            genericAlternatives: [],
            foodInteractions: ["Take on empty stomach or with food (stearate form)"],
            commonSideEffects: ["Nausea", "Vomiting", "Diarrhoea", "Abdominal cramps", "QT prolongation (rare)"],
            storageInstructions: "Store below 25°C.",
            description: "Macrolide antibiotic. Penicillin alternative for respiratory and skin infections.",
            isScheduleH: true
        ))

        // ── GI ADDITIONAL ──

        db.append(DrugEntry(
            id: "itopride", brandName: "Ganaton", genericName: "Itopride",
            saltComposition: "Itopride 50mg",
            category: .antiAcid, manufacturer: "Abbott",
            commonDosages: ["50mg"], typicalDoseForm: "tablet",
            priceRange: "₹60-120",
            genericAlternatives: [
                GenericAlternative(brandName: "Itoact", manufacturer: "Sun Pharma", priceRange: "₹40-80")
            ],
            foodInteractions: ["Take before meals"],
            commonSideEffects: ["Diarrhoea", "Headache", "Abdominal pain", "Elevated prolactin"],
            storageInstructions: "Store below 30°C.",
            description: "Prokinetic for functional dyspepsia, GERD, and gastroparesis.",
            isScheduleH: true
        ))

        db.append(DrugEntry(
            id: "mosapride", brandName: "Mozax", genericName: "Mosapride",
            saltComposition: "Mosapride 5mg",
            category: .antiAcid, manufacturer: "Intas",
            commonDosages: ["2.5mg", "5mg"], typicalDoseForm: "tablet",
            priceRange: "₹40-80",
            genericAlternatives: [
                GenericAlternative(brandName: "Moosa", manufacturer: "Cipla", priceRange: "₹30-60")
            ],
            foodInteractions: ["Take before meals"],
            commonSideEffects: ["Diarrhoea", "Abdominal pain", "Headache", "Dry mouth"],
            storageInstructions: "Store below 30°C.",
            description: "5-HT4 agonist prokinetic for GERD and functional dyspepsia.",
            isScheduleH: true
        ))

        db.append(DrugEntry(
            id: "rebamipide", brandName: "Rebagen", genericName: "Rebamipide",
            saltComposition: "Rebamipide 100mg",
            category: .antiAcid, manufacturer: "Zydus Cadila",
            commonDosages: ["100mg"], typicalDoseForm: "tablet",
            priceRange: "₹50-100",
            genericAlternatives: [
                GenericAlternative(brandName: "Rebax", manufacturer: "Various", priceRange: "₹35-70")
            ],
            foodInteractions: ["Take after meals"],
            commonSideEffects: ["Nausea", "Diarrhoea", "Constipation", "Rash"],
            storageInstructions: "Store below 30°C.",
            description: "Gastroprotective for NSAID-induced gastropathy and gastric ulcer healing.",
            isScheduleH: true
        ))

        db.append(DrugEntry(
            id: "pancreatin", brandName: "Creon", genericName: "Pancreatin (Pancrelipase)",
            saltComposition: "Lipase + Protease + Amylase",
            category: .antiAcid, manufacturer: "Abbott",
            commonDosages: ["10000U", "25000U", "40000U"], typicalDoseForm: "capsule",
            priceRange: "₹150-400",
            genericAlternatives: [
                GenericAlternative(brandName: "Pankreoflat", manufacturer: "Solvay", priceRange: "₹80-200")
            ],
            foodInteractions: ["Take with meals — swallow whole, do not crush"],
            commonSideEffects: ["Nausea", "Diarrhoea", "Stomach cramps", "Mouth sores (chewing)"],
            storageInstructions: "Store below 25°C. Do not freeze.",
            description: "Pancreatic enzyme replacement for chronic pancreatitis and exocrine insufficiency.",
            isScheduleH: true
        ))

        db.append(DrugEntry(
            id: "mesalamine", brandName: "Mesacol", genericName: "Mesalamine (5-ASA)",
            saltComposition: "Mesalamine 400mg",
            category: .antiAcid, manufacturer: "Sun Pharma",
            commonDosages: ["400mg", "800mg", "1.2g"], typicalDoseForm: "tablet",
            priceRange: "₹80-200",
            genericAlternatives: [
                GenericAlternative(brandName: "Pentasa", manufacturer: "Ferring", priceRange: "₹150-350"),
                GenericAlternative(brandName: "Asacol", manufacturer: "Various", priceRange: "₹100-250")
            ],
            foodInteractions: ["Take with food", "Do not crush — enteric coated"],
            commonSideEffects: ["Headache", "Nausea", "Abdominal pain", "Diarrhoea", "Flatulence"],
            storageInstructions: "Store below 30°C.",
            description: "5-aminosalicylate for ulcerative colitis and Crohn's disease maintenance.",
            isScheduleH: true
        ))

        db.append(DrugEntry(
            id: "polyethylene-glycol", brandName: "Peglec", genericName: "Polyethylene Glycol (PEG)",
            saltComposition: "Macrogol 3350 17g",
            category: .antiAcid, manufacturer: "Various",
            commonDosages: ["17g sachet"], typicalDoseForm: "powder",
            priceRange: "₹80-160",
            genericAlternatives: [
                GenericAlternative(brandName: "Cremalax", manufacturer: "Various", priceRange: "₹60-120")
            ],
            foodInteractions: ["Dissolve in water", "Take on empty stomach or at bedtime"],
            commonSideEffects: ["Bloating", "Nausea", "Abdominal cramps", "Diarrhoea (excess)"],
            storageInstructions: "Store below 30°C.",
            description: "Osmotic laxative for chronic constipation. Non-habit-forming.",
            isScheduleH: false
        ))

        // ── PAIN ADDITIONAL ──

        db.append(DrugEntry(
            id: "celecoxib", brandName: "Celebrex", genericName: "Celecoxib",
            saltComposition: "Celecoxib 200mg",
            category: .analgesic, manufacturer: "Pfizer",
            commonDosages: ["100mg", "200mg"], typicalDoseForm: "capsule",
            priceRange: "₹80-180",
            genericAlternatives: [
                GenericAlternative(brandName: "Cobix", manufacturer: "Cipla", priceRange: "₹50-110"),
                GenericAlternative(brandName: "Zycel", manufacturer: "Zydus", priceRange: "₹45-100")
            ],
            foodInteractions: ["Can be taken with or without food"],
            commonSideEffects: ["Stomach pain", "Diarrhoea", "Headache", "Hypertension", "Oedema"],
            storageInstructions: "Store below 30°C.",
            description: "Selective COX-2 inhibitor for osteoarthritis and rheumatoid arthritis.",
            isScheduleH: true
        ))

        db.append(DrugEntry(
            id: "indomethacin", brandName: "Indocap", genericName: "Indomethacin",
            saltComposition: "Indomethacin 25mg",
            category: .analgesic, manufacturer: "Jagsonpal",
            commonDosages: ["25mg", "50mg", "75mg SR"], typicalDoseForm: "capsule",
            priceRange: "₹15-40",
            genericAlternatives: [],
            foodInteractions: ["Take with food", "Avoid alcohol"],
            commonSideEffects: ["Headache", "Dizziness", "Nausea", "Stomach pain", "GI bleeding"],
            storageInstructions: "Store below 30°C.",
            description: "Potent NSAID for gout, RA, ankylosing spondylitis, and PDA closure in neonates.",
            isScheduleH: true
        ))

        db.append(DrugEntry(
            id: "colchicine", brandName: "Zycolchin", genericName: "Colchicine",
            saltComposition: "Colchicine 0.5mg",
            category: .analgesic, manufacturer: "Zydus Cadila",
            commonDosages: ["0.5mg"], typicalDoseForm: "tablet",
            priceRange: "₹10-25",
            genericAlternatives: [],
            foodInteractions: ["Can be taken with or without food"],
            commonSideEffects: ["Diarrhoea", "Nausea", "Vomiting", "Abdominal cramps"],
            storageInstructions: "Store below 30°C.",
            description: "Antigout medicine for acute gout flares and prophylaxis. Also used in pericarditis.",
            isScheduleH: true
        ))

        db.append(DrugEntry(
            id: "allopurinol", brandName: "Zyloric", genericName: "Allopurinol",
            saltComposition: "Allopurinol 100mg",
            category: .analgesic, manufacturer: "GSK",
            commonDosages: ["100mg", "300mg"], typicalDoseForm: "tablet",
            priceRange: "₹10-30",
            genericAlternatives: [
                GenericAlternative(brandName: "Purinol", manufacturer: "Various", priceRange: "₹8-22")
            ],
            foodInteractions: ["Take after food", "Drink plenty of water"],
            commonSideEffects: ["Rash (stop if occurs)", "Nausea", "Elevated liver enzymes", "Gout flare initially"],
            storageInstructions: "Store below 30°C.",
            description: "Xanthine oxidase inhibitor for chronic gout and uric acid kidney stones.",
            isScheduleH: true
        ))

        db.append(DrugEntry(
            id: "febuxostat", brandName: "Febuget", genericName: "Febuxostat",
            saltComposition: "Febuxostat 40mg",
            category: .analgesic, manufacturer: "Sun Pharma",
            commonDosages: ["40mg", "80mg"], typicalDoseForm: "tablet",
            priceRange: "₹60-140",
            genericAlternatives: [
                GenericAlternative(brandName: "Uloric", manufacturer: "Various", priceRange: "₹80-180"),
                GenericAlternative(brandName: "Zurig", manufacturer: "Zydus", priceRange: "₹50-120")
            ],
            foodInteractions: ["Can be taken with or without food"],
            commonSideEffects: ["Liver function abnormalities", "Nausea", "Rash", "Gout flare initially"],
            storageInstructions: "Store below 30°C.",
            description: "Non-purine xanthine oxidase inhibitor for chronic gout. Alternative to allopurinol.",
            isScheduleH: true
        ))

        db.append(DrugEntry(
            id: "diclofenac-paracetamol", brandName: "Voveran D", genericName: "Diclofenac + Paracetamol",
            saltComposition: "Diclofenac Sodium 50mg + Paracetamol 325mg",
            category: .analgesic, manufacturer: "Novartis",
            commonDosages: ["50/325mg"], typicalDoseForm: "tablet",
            priceRange: "₹20-45",
            genericAlternatives: [
                GenericAlternative(brandName: "Dynapar DC", manufacturer: "Troikaa", priceRange: "₹15-35"),
                GenericAlternative(brandName: "Diclogesic DP", manufacturer: "Jagsonpal", priceRange: "₹12-30")
            ],
            foodInteractions: ["Take with food", "Avoid alcohol"],
            commonSideEffects: ["Stomach pain", "Nausea", "Dizziness", "Headache"],
            storageInstructions: "Store below 30°C.",
            description: "NSAID + paracetamol for moderate pain, inflammation, and fever.",
            isScheduleH: true
        ))

        db.append(DrugEntry(
            id: "flupirtine", brandName: "Katadolon", genericName: "Flupirtine",
            saltComposition: "Flupirtine Maleate 100mg",
            category: .analgesic, manufacturer: "Various",
            commonDosages: ["100mg"], typicalDoseForm: "capsule",
            priceRange: "₹80-160",
            genericAlternatives: [],
            foodInteractions: ["Can be taken with or without food"],
            commonSideEffects: ["Dizziness", "Nausea", "Fatigue", "Liver toxicity (monitor)"],
            storageInstructions: "Store below 30°C.",
            description: "Non-opioid, non-NSAID centrally-acting analgesic for acute pain. Max 2 weeks use.",
            isScheduleH: true
        ))

        // ── SKIN ADDITIONAL ──

        db.append(DrugEntry(
            id: "luliconazole", brandName: "Lulican", genericName: "Luliconazole",
            saltComposition: "Luliconazole 1%",
            category: .skinCare, manufacturer: "Sun Pharma",
            commonDosages: ["1%"], typicalDoseForm: "cream",
            priceRange: "₹120-250",
            genericAlternatives: [
                GenericAlternative(brandName: "Lulifin", manufacturer: "Glenmark", priceRange: "₹100-200")
            ],
            foodInteractions: ["Topical — no food interactions"],
            commonSideEffects: ["Skin irritation", "Burning", "Contact dermatitis"],
            storageInstructions: "Store below 30°C.",
            description: "Potent topical antifungal for ringworm, jock itch, and athlete's foot.",
            isScheduleH: true
        ))

        db.append(DrugEntry(
            id: "sertaconazole", brandName: "Onabet", genericName: "Sertaconazole",
            saltComposition: "Sertaconazole 2%",
            category: .skinCare, manufacturer: "Glenmark",
            commonDosages: ["2%"], typicalDoseForm: "cream",
            priceRange: "₹150-280",
            genericAlternatives: [],
            foodInteractions: ["Topical — no food interactions"],
            commonSideEffects: ["Burning", "Itching", "Skin dryness", "Redness"],
            storageInstructions: "Store below 30°C.",
            description: "Broad-spectrum topical antifungal for dermatophytosis and candidiasis.",
            isScheduleH: true
        ))

        db.append(DrugEntry(
            id: "mometasone", brandName: "Elocon", genericName: "Mometasone",
            saltComposition: "Mometasone Furoate 0.1%",
            category: .skinCare, manufacturer: "MSD",
            commonDosages: ["0.1%"], typicalDoseForm: "cream",
            priceRange: "₹100-200",
            genericAlternatives: [
                GenericAlternative(brandName: "Momate", manufacturer: "Glenmark", priceRange: "₹80-160"),
                GenericAlternative(brandName: "Momenext", manufacturer: "Various", priceRange: "₹60-120")
            ],
            foodInteractions: ["Topical — no food interactions"],
            commonSideEffects: ["Skin thinning", "Burning", "Itching", "Folliculitis"],
            storageInstructions: "Store below 25°C.",
            description: "Mid-potency topical steroid for eczema, psoriasis, and dermatitis.",
            isScheduleH: true
        ))

        db.append(DrugEntry(
            id: "tacrolimus-topical", brandName: "Tacroz", genericName: "Tacrolimus",
            saltComposition: "Tacrolimus 0.03%",
            category: .skinCare, manufacturer: "Glenmark",
            commonDosages: ["0.03%", "0.1%"], typicalDoseForm: "ointment",
            priceRange: "₹200-400",
            genericAlternatives: [
                GenericAlternative(brandName: "Protopic", manufacturer: "Astellas", priceRange: "₹300-550")
            ],
            foodInteractions: ["Topical — no food interactions"],
            commonSideEffects: ["Burning sensation (initial)", "Itching", "Skin infections", "Photosensitivity"],
            storageInstructions: "Store below 25°C.",
            description: "Calcineurin inhibitor for atopic dermatitis. Steroid-sparing alternative for face.",
            isScheduleH: true
        ))

        db.append(DrugEntry(
            id: "isotretinoin", brandName: "Isotroin", genericName: "Isotretinoin",
            saltComposition: "Isotretinoin 20mg",
            category: .skinCare, manufacturer: "Cipla",
            commonDosages: ["5mg", "10mg", "20mg", "40mg"], typicalDoseForm: "capsule",
            priceRange: "₹100-300",
            genericAlternatives: [
                GenericAlternative(brandName: "Tretiva", manufacturer: "Intas", priceRange: "₹80-250"),
                GenericAlternative(brandName: "Accutane", manufacturer: "Roche", priceRange: "₹200-500")
            ],
            foodInteractions: ["Take with fatty food for better absorption"],
            commonSideEffects: ["Dry skin/lips", "Nosebleeds", "Joint pain", "Elevated lipids", "Teratogenic — strict contraception"],
            storageInstructions: "Store below 25°C. Protect from light.",
            description: "Oral retinoid for severe cystic acne. Highly teratogenic — pregnancy test mandatory.",
            isScheduleH: true
        ))

        // ── ANTI-INFECTIVE ADDITIONAL ──

        db.append(DrugEntry(
            id: "oseltamivir", brandName: "Tamiflu", genericName: "Oseltamivir",
            saltComposition: "Oseltamivir 75mg",
            category: .antiInfective, manufacturer: "Roche",
            commonDosages: ["30mg", "45mg", "75mg"], typicalDoseForm: "capsule",
            priceRange: "₹200-500",
            genericAlternatives: [
                GenericAlternative(brandName: "Fluvir", manufacturer: "Hetero", priceRange: "₹120-300"),
                GenericAlternative(brandName: "Antiflu", manufacturer: "Cipla", priceRange: "₹100-250")
            ],
            foodInteractions: ["Can be taken with or without food", "Take with food if nauseous"],
            commonSideEffects: ["Nausea", "Vomiting", "Headache", "Abdominal pain"],
            storageInstructions: "Store below 25°C.",
            description: "Antiviral for influenza (H1N1, H5N1). Start within 48 hours of symptoms.",
            isScheduleH: true
        ))

        db.append(DrugEntry(
            id: "terbinafine-oral", brandName: "Terbicip", genericName: "Terbinafine",
            saltComposition: "Terbinafine 250mg",
            category: .antiInfective, manufacturer: "Cipla",
            commonDosages: ["250mg"], typicalDoseForm: "tablet",
            priceRange: "₹80-200",
            genericAlternatives: [
                GenericAlternative(brandName: "Zimig", manufacturer: "GSK", priceRange: "₹100-220")
            ],
            foodInteractions: ["Can be taken with or without food"],
            commonSideEffects: ["Taste changes", "Headache", "Nausea", "Rash", "Liver toxicity (rare)"],
            storageInstructions: "Store below 30°C.",
            description: "Oral antifungal for tinea corporis, tinea pedis, and onychomycosis (nail fungus).",
            isScheduleH: true
        ))

        db.append(DrugEntry(
            id: "voriconazole", brandName: "Vfend", genericName: "Voriconazole",
            saltComposition: "Voriconazole 200mg",
            category: .antiInfective, manufacturer: "Pfizer",
            commonDosages: ["50mg", "200mg"], typicalDoseForm: "tablet",
            priceRange: "₹200-600",
            genericAlternatives: [
                GenericAlternative(brandName: "Vorier", manufacturer: "Cipla", priceRange: "₹120-400"),
                GenericAlternative(brandName: "Voritek", manufacturer: "Dr. Reddy's", priceRange: "₹100-350")
            ],
            foodInteractions: ["Take 1 hour before or after food", "Avoid high-fat meals"],
            commonSideEffects: ["Visual disturbances", "Liver toxicity", "Rash", "Nausea", "Photosensitivity"],
            storageInstructions: "Store below 30°C.",
            description: "Triazole antifungal for invasive aspergillosis and serious fungal infections.",
            isScheduleH: true
        ))

        // ── MISCELLANEOUS ADDITIONAL ──

        db.append(DrugEntry(
            id: "topiramate", brandName: "Topamax", genericName: "Topiramate",
            saltComposition: "Topiramate 25mg",
            category: .other, manufacturer: "Janssen",
            commonDosages: ["25mg", "50mg", "100mg", "200mg"], typicalDoseForm: "tablet",
            priceRange: "₹40-120",
            genericAlternatives: [
                GenericAlternative(brandName: "Topamac", manufacturer: "Sun Pharma", priceRange: "₹30-90"),
                GenericAlternative(brandName: "Nextop", manufacturer: "Cipla", priceRange: "₹25-80")
            ],
            foodInteractions: ["Can be taken with or without food", "Drink plenty of water"],
            commonSideEffects: ["Tingling", "Drowsiness", "Weight loss", "Cognitive impairment", "Kidney stones"],
            storageInstructions: "Store below 30°C.",
            description: "Anticonvulsant for epilepsy and migraine prevention. Causes weight loss.",
            isScheduleH: true
        ))

        db.append(DrugEntry(
            id: "sumatriptan", brandName: "Suminat", genericName: "Sumatriptan",
            saltComposition: "Sumatriptan Succinate 50mg",
            category: .other, manufacturer: "Sun Pharma",
            commonDosages: ["25mg", "50mg", "100mg"], typicalDoseForm: "tablet",
            priceRange: "₹40-100",
            genericAlternatives: [
                GenericAlternative(brandName: "Imitrex", manufacturer: "GSK", priceRange: "₹80-200")
            ],
            foodInteractions: ["Can be taken with or without food"],
            commonSideEffects: ["Tingling", "Chest tightness", "Drowsiness", "Dizziness", "Flushing"],
            storageInstructions: "Store below 30°C.",
            description: "Triptan for acute migraine and cluster headache relief. Not for prevention.",
            isScheduleH: true
        ))

        db.append(DrugEntry(
            id: "flunarizine", brandName: "Sibelium", genericName: "Flunarizine",
            saltComposition: "Flunarizine 10mg",
            category: .other, manufacturer: "Janssen",
            commonDosages: ["5mg", "10mg"], typicalDoseForm: "tablet",
            priceRange: "₹30-70",
            genericAlternatives: [
                GenericAlternative(brandName: "Flu", manufacturer: "Various", priceRange: "₹20-45")
            ],
            foodInteractions: ["Take at bedtime"],
            commonSideEffects: ["Drowsiness", "Weight gain", "Depression", "Parkinsonism (prolonged use)"],
            storageInstructions: "Store below 30°C.",
            description: "Calcium channel blocker for migraine prevention and vertigo.",
            isScheduleH: true
        ))

        db.append(DrugEntry(
            id: "propranolol", brandName: "Ciplar", genericName: "Propranolol",
            saltComposition: "Propranolol 40mg",
            category: .antihypertensive, manufacturer: "Cipla",
            commonDosages: ["10mg", "20mg", "40mg", "80mg"], typicalDoseForm: "tablet",
            priceRange: "₹10-30",
            genericAlternatives: [
                GenericAlternative(brandName: "Inderal", manufacturer: "Various", priceRange: "₹12-35")
            ],
            foodInteractions: ["Take with food", "Avoid alcohol"],
            commonSideEffects: ["Fatigue", "Bradycardia", "Cold extremities", "Bronchospasm", "Depression"],
            storageInstructions: "Store below 30°C.",
            description: "Non-selective beta-blocker for hypertension, tremor, migraine, anxiety, and thyrotoxicosis.",
            isScheduleH: true
        ))

        db.append(DrugEntry(
            id: "oxybutynin", brandName: "Cystran", genericName: "Oxybutynin",
            saltComposition: "Oxybutynin 5mg",
            category: .other, manufacturer: "Various",
            commonDosages: ["2.5mg", "5mg"], typicalDoseForm: "tablet",
            priceRange: "₹20-50",
            genericAlternatives: [
                GenericAlternative(brandName: "Ditropan", manufacturer: "Various", priceRange: "₹25-60")
            ],
            foodInteractions: ["Can be taken with or without food"],
            commonSideEffects: ["Dry mouth", "Constipation", "Drowsiness", "Blurred vision", "Urinary retention"],
            storageInstructions: "Store below 30°C.",
            description: "Anticholinergic for overactive bladder and urinary incontinence.",
            isScheduleH: true
        ))

        db.append(DrugEntry(
            id: "solifenacin", brandName: "Soliten", genericName: "Solifenacin",
            saltComposition: "Solifenacin 5mg",
            category: .other, manufacturer: "Sun Pharma",
            commonDosages: ["5mg", "10mg"], typicalDoseForm: "tablet",
            priceRange: "₹60-140",
            genericAlternatives: [
                GenericAlternative(brandName: "Vesicare", manufacturer: "Astellas", priceRange: "₹120-280")
            ],
            foodInteractions: ["Can be taken with or without food"],
            commonSideEffects: ["Dry mouth", "Constipation", "Blurred vision", "Nausea"],
            storageInstructions: "Store below 30°C.",
            description: "Anticholinergic for overactive bladder with urinary urgency/frequency.",
            isScheduleH: true
        ))

        db.append(DrugEntry(
            id: "mirabegron", brandName: "Myrbetriq", genericName: "Mirabegron",
            saltComposition: "Mirabegron 50mg",
            category: .other, manufacturer: "Astellas",
            commonDosages: ["25mg", "50mg"], typicalDoseForm: "tablet",
            priceRange: "₹200-400",
            genericAlternatives: [
                GenericAlternative(brandName: "Mirago", manufacturer: "Various", priceRange: "₹120-250")
            ],
            foodInteractions: ["Can be taken with or without food"],
            commonSideEffects: ["Hypertension", "UTI", "Headache", "Nasopharyngitis"],
            storageInstructions: "Store below 30°C.",
            description: "Beta-3 agonist for overactive bladder. No anticholinergic side effects.",
            isScheduleH: true
        ))

        db.append(DrugEntry(
            id: "doxazosin", brandName: "Doxacard", genericName: "Doxazosin",
            saltComposition: "Doxazosin 2mg",
            category: .other, manufacturer: "Sun Pharma",
            commonDosages: ["1mg", "2mg", "4mg"], typicalDoseForm: "tablet",
            priceRange: "₹30-80",
            genericAlternatives: [
                GenericAlternative(brandName: "Cardura", manufacturer: "Pfizer", priceRange: "₹50-120")
            ],
            foodInteractions: ["Can be taken with or without food"],
            commonSideEffects: ["Dizziness", "Fatigue", "Orthostatic hypotension", "Headache"],
            storageInstructions: "Store below 30°C.",
            description: "Alpha-blocker for BPH and hypertension.",
            isScheduleH: true
        ))

        db.append(DrugEntry(
            id: "alfuzosin", brandName: "Alfoo", genericName: "Alfuzosin",
            saltComposition: "Alfuzosin 10mg",
            category: .other, manufacturer: "Dr. Reddy's",
            commonDosages: ["10mg"], typicalDoseForm: "tablet",
            priceRange: "₹50-120",
            genericAlternatives: [
                GenericAlternative(brandName: "Xatral", manufacturer: "Sanofi", priceRange: "₹80-180")
            ],
            foodInteractions: ["Take after same meal each day"],
            commonSideEffects: ["Dizziness", "Headache", "Fatigue", "Orthostatic hypotension"],
            storageInstructions: "Store below 30°C.",
            description: "Alpha-blocker for BPH. Does not affect ejaculation like tamsulosin.",
            isScheduleH: true
        ))

        db.append(DrugEntry(
            id: "silodosin", brandName: "Urimax F", genericName: "Silodosin",
            saltComposition: "Silodosin 8mg",
            category: .other, manufacturer: "Cipla",
            commonDosages: ["4mg", "8mg"], typicalDoseForm: "capsule",
            priceRange: "₹80-180",
            genericAlternatives: [
                GenericAlternative(brandName: "Rapaflo", manufacturer: "Various", priceRange: "₹100-220")
            ],
            foodInteractions: ["Take with food"],
            commonSideEffects: ["Retrograde ejaculation", "Dizziness", "Diarrhoea", "Nasal congestion"],
            storageInstructions: "Store below 30°C.",
            description: "Selective alpha-1A blocker for BPH. Most uroselective but high retrograde ejaculation.",
            isScheduleH: true
        ))

        db.append(DrugEntry(
            id: "dutasteride-tamsulosin", brandName: "Dutas-T", genericName: "Dutasteride + Tamsulosin",
            saltComposition: "Dutasteride 0.5mg + Tamsulosin 0.4mg",
            category: .other, manufacturer: "Dr. Reddy's",
            commonDosages: ["0.5/0.4mg"], typicalDoseForm: "capsule",
            priceRange: "₹150-300",
            genericAlternatives: [
                GenericAlternative(brandName: "Jalyn", manufacturer: "GSK", priceRange: "₹200-400")
            ],
            foodInteractions: ["Take 30 minutes after same meal each day"],
            commonSideEffects: ["Decreased libido", "Retrograde ejaculation", "Dizziness", "Breast tenderness"],
            storageInstructions: "Store below 30°C.",
            description: "5ARI + alpha-blocker combo for moderate-to-severe BPH.",
            isScheduleH: true
        ))

        db.append(DrugEntry(
            id: "montelukast-fexofenadine", brandName: "Montek FX", genericName: "Montelukast + Fexofenadine",
            saltComposition: "Montelukast 10mg + Fexofenadine 120mg",
            category: .antiAllergy, manufacturer: "Sun Pharma",
            commonDosages: ["10/120mg"], typicalDoseForm: "tablet",
            priceRange: "₹100-200",
            genericAlternatives: [
                GenericAlternative(brandName: "Montair FX", manufacturer: "Cipla", priceRange: "₹120-220")
            ],
            foodInteractions: ["Take in the evening", "Avoid fruit juices within 4 hours"],
            commonSideEffects: ["Headache", "Dizziness", "Nausea", "Fatigue"],
            storageInstructions: "Store below 30°C.",
            description: "Non-drowsy anti-allergy combo for allergic rhinitis.",
            isScheduleH: true
        ))

        db.append(DrugEntry(
            id: "rupatadine", brandName: "Rupanex", genericName: "Rupatadine",
            saltComposition: "Rupatadine 10mg",
            category: .antiAllergy, manufacturer: "Sun Pharma",
            commonDosages: ["10mg"], typicalDoseForm: "tablet",
            priceRange: "₹60-120",
            genericAlternatives: [],
            foodInteractions: ["Can be taken with or without food"],
            commonSideEffects: ["Drowsiness", "Headache", "Fatigue", "Dry mouth"],
            storageInstructions: "Store below 30°C.",
            description: "Dual-action antihistamine + PAF antagonist for allergic rhinitis and urticaria.",
            isScheduleH: true
        ))

        db.append(DrugEntry(
            id: "ebastine", brandName: "Ebast", genericName: "Ebastine",
            saltComposition: "Ebastine 10mg",
            category: .antiAllergy, manufacturer: "Various",
            commonDosages: ["10mg", "20mg"], typicalDoseForm: "tablet",
            priceRange: "₹40-90",
            genericAlternatives: [],
            foodInteractions: ["Can be taken with or without food"],
            commonSideEffects: ["Headache", "Drowsiness (minimal)", "Dry mouth"],
            storageInstructions: "Store below 30°C.",
            description: "Non-sedating second-generation antihistamine for allergic rhinitis.",
            isScheduleH: true
        ))

        db.append(DrugEntry(
            id: "metformin-sr500", brandName: "Glycomet SR 500", genericName: "Metformin SR",
            saltComposition: "Metformin 500mg SR",
            category: .antidiabetic, manufacturer: "USV",
            commonDosages: ["500mg SR"], typicalDoseForm: "tablet",
            priceRange: "₹25-60",
            genericAlternatives: [
                GenericAlternative(brandName: "Obimet SR", manufacturer: "Abbott", priceRange: "₹30-70"),
                GenericAlternative(brandName: "Gluconorm SR", manufacturer: "Lupin", priceRange: "₹22-55")
            ],
            foodInteractions: ["Take with dinner", "Do not crush"],
            commonSideEffects: ["Nausea", "Diarrhoea", "Metallic taste"],
            storageInstructions: "Store below 30°C.",
            description: "Sustained-release metformin for better GI tolerability in Type 2 diabetes.",
            isScheduleH: true
        ))

        db.append(DrugEntry(
            id: "amlodipine-losartan", brandName: "Amlokind-L", genericName: "Amlodipine + Losartan",
            saltComposition: "Amlodipine 5mg + Losartan 50mg",
            category: .antihypertensive, manufacturer: "Mankind",
            commonDosages: ["5/50mg"], typicalDoseForm: "tablet",
            priceRange: "₹50-100",
            genericAlternatives: [
                GenericAlternative(brandName: "Amlosar", manufacturer: "Various", priceRange: "₹35-75")
            ],
            foodInteractions: ["Can be taken with or without food"],
            commonSideEffects: ["Dizziness", "Ankle swelling", "Headache", "Fatigue"],
            storageInstructions: "Store below 30°C.",
            description: "CCB + ARB combination for hypertension.",
            isScheduleH: true
        ))

        db.append(DrugEntry(
            id: "ramipril-hctz", brandName: "Cardace-H", genericName: "Ramipril + Hydrochlorothiazide",
            saltComposition: "Ramipril 5mg + HCTZ 12.5mg",
            category: .antihypertensive, manufacturer: "Sanofi",
            commonDosages: ["2.5/12.5mg", "5/12.5mg", "5/25mg"], typicalDoseForm: "tablet",
            priceRange: "₹60-130",
            genericAlternatives: [
                GenericAlternative(brandName: "Ramistar-H", manufacturer: "Lupin", priceRange: "₹40-90")
            ],
            foodInteractions: ["Can be taken with or without food", "Avoid potassium supplements"],
            commonSideEffects: ["Dry cough", "Dizziness", "Frequent urination", "Fatigue"],
            storageInstructions: "Store below 30°C.",
            description: "ACE inhibitor + diuretic for hypertension.",
            isScheduleH: true
        ))

        db.append(DrugEntry(
            id: "pioglitazone-met", brandName: "Pioz MF", genericName: "Pioglitazone + Metformin",
            saltComposition: "Pioglitazone 15mg + Metformin 500mg",
            category: .antidiabetic, manufacturer: "USV",
            commonDosages: ["15/500mg", "15/850mg"], typicalDoseForm: "tablet",
            priceRange: "₹50-100",
            genericAlternatives: [
                GenericAlternative(brandName: "Piozone-MF", manufacturer: "Sun Pharma", priceRange: "₹35-75")
            ],
            foodInteractions: ["Take with meals"],
            commonSideEffects: ["Weight gain", "Oedema", "Nausea", "Diarrhoea"],
            storageInstructions: "Store below 30°C.",
            description: "Thiazolidinedione + biguanide combo for insulin resistance in Type 2 diabetes.",
            isScheduleH: true
        ))

        db.append(DrugEntry(
            id: "voglibose-met", brandName: "Vogli-M", genericName: "Voglibose + Metformin",
            saltComposition: "Voglibose 0.2mg + Metformin 500mg",
            category: .antidiabetic, manufacturer: "USV",
            commonDosages: ["0.2/500mg", "0.3/500mg"], typicalDoseForm: "tablet",
            priceRange: "₹50-110",
            genericAlternatives: [
                GenericAlternative(brandName: "PPG-M", manufacturer: "Sun Pharma", priceRange: "₹40-85")
            ],
            foodInteractions: ["Take with the first bite of a meal"],
            commonSideEffects: ["Flatulence", "Bloating", "Diarrhoea", "Nausea"],
            storageInstructions: "Store below 30°C.",
            description: "Alpha-glucosidase inhibitor + biguanide for post-meal glucose control.",
            isScheduleH: true
        ))

        db.append(DrugEntry(
            id: "aspirin-atorva-clop", brandName: "Ecosprin Gold", genericName: "Aspirin + Atorvastatin + Clopidogrel",
            saltComposition: "Aspirin 75mg + Atorvastatin 10mg + Clopidogrel 75mg",
            category: .cardiovascular, manufacturer: "USV",
            commonDosages: ["75/10/75mg", "75/20/75mg"], typicalDoseForm: "capsule",
            priceRange: "₹80-160",
            genericAlternatives: [],
            foodInteractions: ["Take with food"],
            commonSideEffects: ["Bleeding", "Muscle pain", "Stomach pain", "Nausea"],
            storageInstructions: "Store below 30°C.",
            description: "Triple cardiovascular combo for post-ACS and post-stent patients.",
            isScheduleH: true
        ))

        db.append(DrugEntry(
            id: "metformin-sr1000", brandName: "Glycomet SR 1000", genericName: "Metformin SR",
            saltComposition: "Metformin 1000mg SR",
            category: .antidiabetic, manufacturer: "USV",
            commonDosages: ["1000mg SR"], typicalDoseForm: "tablet",
            priceRange: "₹45-100",
            genericAlternatives: [
                GenericAlternative(brandName: "Obimet SR 1000", manufacturer: "Abbott", priceRange: "₹50-110")
            ],
            foodInteractions: ["Take with dinner", "Do not crush"],
            commonSideEffects: ["Nausea", "Diarrhoea", "Metallic taste"],
            storageInstructions: "Store below 30°C.",
            description: "High-dose sustained-release metformin for Type 2 diabetes.",
            isScheduleH: true
        ))

        db.append(DrugEntry(
            id: "sitagliptin-met", brandName: "Istamet", genericName: "Sitagliptin + Metformin",
            saltComposition: "Sitagliptin 50mg + Metformin 1000mg",
            category: .antidiabetic, manufacturer: "Sun Pharma",
            commonDosages: ["50/500mg", "50/1000mg"], typicalDoseForm: "tablet",
            priceRange: "₹250-450",
            genericAlternatives: [
                GenericAlternative(brandName: "Janumet", manufacturer: "MSD", priceRange: "₹350-600")
            ],
            foodInteractions: ["Take with meals"],
            commonSideEffects: ["Nausea", "Diarrhoea", "Headache"],
            storageInstructions: "Store below 30°C.",
            description: "Generic sitagliptin + metformin combo for comprehensive diabetes control.",
            isScheduleH: true
        ))

        db.append(DrugEntry(
            id: "glipizide-met", brandName: "Glucotrol-M", genericName: "Glipizide + Metformin",
            saltComposition: "Glipizide 5mg + Metformin 500mg",
            category: .antidiabetic, manufacturer: "Various",
            commonDosages: ["2.5/500mg", "5/500mg"], typicalDoseForm: "tablet",
            priceRange: "₹30-70",
            genericAlternatives: [],
            foodInteractions: ["Take with meals", "Do not skip meals"],
            commonSideEffects: ["Hypoglycemia", "Nausea", "Diarrhoea"],
            storageInstructions: "Store below 30°C.",
            description: "Sulfonylurea + biguanide combination for Type 2 diabetes.",
            isScheduleH: true
        ))

        db.append(DrugEntry(
            id: "glibenclamide", brandName: "Daonil", genericName: "Glibenclamide",
            saltComposition: "Glibenclamide 5mg",
            category: .antidiabetic, manufacturer: "Sanofi",
            commonDosages: ["2.5mg", "5mg"], typicalDoseForm: "tablet",
            priceRange: "₹8-20",
            genericAlternatives: [
                GenericAlternative(brandName: "Semi-Daonil", manufacturer: "Sanofi", priceRange: "₹6-15")
            ],
            foodInteractions: ["Take 30 min before meals", "Do not skip meals"],
            commonSideEffects: ["Hypoglycemia (severe)", "Weight gain", "Nausea"],
            storageInstructions: "Store below 30°C.",
            description: "Older sulfonylurea. Higher hypoglycemia risk than glimepiride/gliclazide.",
            isScheduleH: true
        ))

        db.append(DrugEntry(
            id: "clotrimazole", brandName: "Candid", genericName: "Clotrimazole",
            saltComposition: "Clotrimazole 1%",
            category: .skinCare, manufacturer: "Glenmark",
            commonDosages: ["1%"], typicalDoseForm: "cream",
            priceRange: "₹40-80",
            genericAlternatives: [
                GenericAlternative(brandName: "Canesten", manufacturer: "Bayer", priceRange: "₹50-100")
            ],
            foodInteractions: ["Topical — no food interactions"],
            commonSideEffects: ["Skin irritation", "Burning", "Redness"],
            storageInstructions: "Store below 30°C.",
            description: "Basic topical antifungal for ringworm, candidiasis, and athlete's foot.",
            isScheduleH: false
        ))

        db.append(DrugEntry(
            id: "miconazole", brandName: "Daktarin", genericName: "Miconazole",
            saltComposition: "Miconazole 2%",
            category: .skinCare, manufacturer: "Janssen",
            commonDosages: ["2%"], typicalDoseForm: "cream/gel",
            priceRange: "₹50-100",
            genericAlternatives: [],
            foodInteractions: ["Topical — no food interactions"],
            commonSideEffects: ["Burning", "Itching", "Redness", "Skin irritation"],
            storageInstructions: "Store below 30°C.",
            description: "Topical antifungal for oral thrush (gel) and skin fungal infections (cream).",
            isScheduleH: true
        ))

        db.append(DrugEntry(
            id: "clindamycin-gel", brandName: "Clinamycin", genericName: "Clindamycin",
            saltComposition: "Clindamycin 1%",
            category: .skinCare, manufacturer: "Various",
            commonDosages: ["1%"], typicalDoseForm: "gel",
            priceRange: "₹60-120",
            genericAlternatives: [
                GenericAlternative(brandName: "Clindasol-A", manufacturer: "Sun Pharma", priceRange: "₹50-100")
            ],
            foodInteractions: ["Topical — no food interactions"],
            commonSideEffects: ["Skin dryness", "Peeling", "Burning", "Itching"],
            storageInstructions: "Store below 30°C.",
            description: "Topical antibiotic gel for acne vulgaris.",
            isScheduleH: true
        ))

        db.append(DrugEntry(
            id: "benzoyl-peroxide", brandName: "Benzac AC", genericName: "Benzoyl Peroxide",
            saltComposition: "Benzoyl Peroxide 2.5%",
            category: .skinCare, manufacturer: "Galderma",
            commonDosages: ["2.5%", "5%", "10%"], typicalDoseForm: "gel",
            priceRange: "₹80-180",
            genericAlternatives: [
                GenericAlternative(brandName: "Persol AC", manufacturer: "Wallace", priceRange: "₹50-120")
            ],
            foodInteractions: ["Topical — no food interactions"],
            commonSideEffects: ["Skin dryness", "Peeling", "Burning", "Redness", "Bleaches fabrics"],
            storageInstructions: "Store below 25°C.",
            description: "Topical antibacterial and comedolytic for mild-to-moderate acne.",
            isScheduleH: false
        ))

        db.append(DrugEntry(
            id: "hydrocortisone-cream", brandName: "Licoid", genericName: "Hydrocortisone",
            saltComposition: "Hydrocortisone 1%",
            category: .skinCare, manufacturer: "Zydus Cadila",
            commonDosages: ["0.5%", "1%"], typicalDoseForm: "cream",
            priceRange: "₹30-60",
            genericAlternatives: [],
            foodInteractions: ["Topical — no food interactions"],
            commonSideEffects: ["Skin thinning (prolonged use)", "Burning", "Itching"],
            storageInstructions: "Store below 30°C.",
            description: "Mild topical steroid for eczema, insect bites, and mild dermatitis. Safe for face.",
            isScheduleH: false
        ))

        db.append(DrugEntry(
            id: "calcipotriol", brandName: "Daivonex", genericName: "Calcipotriol",
            saltComposition: "Calcipotriol 50mcg/g",
            category: .skinCare, manufacturer: "Leo Pharma",
            commonDosages: ["0.005%"], typicalDoseForm: "ointment",
            priceRange: "₹200-400",
            genericAlternatives: [
                GenericAlternative(brandName: "Calcipot", manufacturer: "Cipla", priceRange: "₹120-250")
            ],
            foodInteractions: ["Topical — no food interactions"],
            commonSideEffects: ["Skin irritation", "Burning", "Itching", "Redness"],
            storageInstructions: "Store below 25°C.",
            description: "Vitamin D analogue for psoriasis. Steroid-sparing option.",
            isScheduleH: true
        ))

        db.append(DrugEntry(
            id: "methotrexate-inj", brandName: "Folitrax Injection", genericName: "Methotrexate",
            saltComposition: "Methotrexate 15mg/ml",
            category: .other, manufacturer: "Ipca",
            commonDosages: ["7.5mg", "10mg", "15mg", "25mg"], typicalDoseForm: "injection",
            priceRange: "₹50-150",
            genericAlternatives: [],
            foodInteractions: ["Injectable — take folic acid supplements on non-MTX days"],
            commonSideEffects: ["Nausea", "Fatigue", "Mouth sores", "Liver toxicity", "Immunosuppression"],
            storageInstructions: "Store below 25°C. Protect from light.",
            description: "Injectable methotrexate for RA, psoriasis — better GI tolerability than oral.",
            isScheduleH: true
        ))

        db.append(DrugEntry(
            id: "leflunomide", brandName: "Lefno", genericName: "Leflunomide",
            saltComposition: "Leflunomide 20mg",
            category: .other, manufacturer: "Sun Pharma",
            commonDosages: ["10mg", "20mg"], typicalDoseForm: "tablet",
            priceRange: "₹80-180",
            genericAlternatives: [
                GenericAlternative(brandName: "Arava", manufacturer: "Sanofi", priceRange: "₹120-250")
            ],
            foodInteractions: ["Can be taken with or without food"],
            commonSideEffects: ["Diarrhoea", "Nausea", "Hair loss", "Rash", "Liver toxicity"],
            storageInstructions: "Store below 30°C.",
            description: "DMARD for rheumatoid arthritis. Highly teratogenic — washout needed before pregnancy.",
            isScheduleH: true
        ))

        db.append(DrugEntry(
            id: "sulfasalazine", brandName: "Saaz", genericName: "Sulfasalazine",
            saltComposition: "Sulfasalazine 500mg",
            category: .other, manufacturer: "Ipca",
            commonDosages: ["500mg"], typicalDoseForm: "tablet",
            priceRange: "₹20-50",
            genericAlternatives: [
                GenericAlternative(brandName: "Salazopyrin", manufacturer: "Pfizer", priceRange: "₹30-70")
            ],
            foodInteractions: ["Take after meals", "Drink plenty of water"],
            commonSideEffects: ["Nausea", "Headache", "Rash", "Orange urine/tears", "Oligospermia"],
            storageInstructions: "Store below 30°C. Protect from light.",
            description: "DMARD for RA, ankylosing spondylitis, and ulcerative colitis.",
            isScheduleH: true
        ))

        db.append(DrugEntry(
            id: "tofacitinib", brandName: "Jakafi", genericName: "Tofacitinib",
            saltComposition: "Tofacitinib 5mg",
            category: .other, manufacturer: "Pfizer",
            commonDosages: ["5mg", "10mg", "11mg XR"], typicalDoseForm: "tablet",
            priceRange: "₹200-500",
            genericAlternatives: [
                GenericAlternative(brandName: "Tofajak", manufacturer: "Cipla", priceRange: "₹120-300")
            ],
            foodInteractions: ["Can be taken with or without food"],
            commonSideEffects: ["Infections", "Diarrhoea", "Headache", "Elevated cholesterol", "DVT (rare)"],
            storageInstructions: "Store below 30°C.",
            description: "JAK inhibitor for RA and ulcerative colitis when conventional DMARDs fail.",
            isScheduleH: true
        ))

        db.append(DrugEntry(
            id: "pantoprazole-itopride", brandName: "Ganaton Total", genericName: "Pantoprazole + Itopride",
            saltComposition: "Pantoprazole 40mg + Itopride 150mg SR",
            category: .antiAcid, manufacturer: "Abbott",
            commonDosages: ["40/150mg"], typicalDoseForm: "capsule",
            priceRange: "₹100-200",
            genericAlternatives: [],
            foodInteractions: ["Take on empty stomach, before meals"],
            commonSideEffects: ["Headache", "Diarrhoea", "Abdominal pain", "Dry mouth"],
            storageInstructions: "Store below 30°C.",
            description: "PPI + prokinetic combination for GERD with gastroparesis.",
            isScheduleH: true
        ))

        db.append(DrugEntry(
            id: "racecadotril", brandName: "Redotril", genericName: "Racecadotril",
            saltComposition: "Racecadotril 100mg",
            category: .antiAcid, manufacturer: "Abbott",
            commonDosages: ["10mg", "30mg", "100mg"], typicalDoseForm: "capsule/sachet",
            priceRange: "₹30-70",
            genericAlternatives: [
                GenericAlternative(brandName: "Zedott", manufacturer: "Sun Pharma", priceRange: "₹20-50")
            ],
            foodInteractions: ["Can be taken with or without food"],
            commonSideEffects: ["Headache", "Rash (rare)"],
            storageInstructions: "Store below 30°C.",
            description: "Antisecretory antidiarrheal — reduces intestinal secretions without stopping motility.",
            isScheduleH: true
        ))

        db.append(DrugEntry(
            id: "ondansetron-dom", brandName: "Emeset MD", genericName: "Ondansetron",
            saltComposition: "Ondansetron 8mg",
            category: .other, manufacturer: "Cipla",
            commonDosages: ["4mg", "8mg"], typicalDoseForm: "mouth dissolving tablet",
            priceRange: "₹40-80",
            genericAlternatives: [
                GenericAlternative(brandName: "Ondem MD", manufacturer: "Alkem", priceRange: "₹30-60")
            ],
            foodInteractions: ["Place on tongue — dissolves without water"],
            commonSideEffects: ["Headache", "Constipation", "Fatigue"],
            storageInstructions: "Store below 30°C.",
            description: "Fast-dissolving anti-nausea tablet for chemotherapy, post-op, and severe vomiting.",
            isScheduleH: true
        ))

        // ════════════════════════════════════════════
        // BATCH 3 — FINAL ENTRIES TO REACH 500+
        // ════════════════════════════════════════════

        // ── DIABETES COMBOS ──

        db.append(DrugEntry(id: "teneligliptin-met", brandName: "Tenepure M", genericName: "Teneligliptin + Metformin", saltComposition: "Teneligliptin 20mg + Metformin 500mg", category: .antidiabetic, manufacturer: "Mankind", commonDosages: ["20/500mg", "20/1000mg"], typicalDoseForm: "tablet", priceRange: "₹90-170", genericAlternatives: [], foodInteractions: ["Take with meals"], commonSideEffects: ["Nausea", "Diarrhoea", "Headache"], storageInstructions: "Store below 30°C.", description: "Affordable DPP-4 + metformin combo for diabetes.", isScheduleH: true))

        db.append(DrugEntry(id: "canagliflozin-met", brandName: "Invokamet", genericName: "Canagliflozin + Metformin", saltComposition: "Canagliflozin 50mg + Metformin 500mg", category: .antidiabetic, manufacturer: "Johnson & Johnson", commonDosages: ["50/500mg", "50/1000mg", "150/500mg", "150/1000mg"], typicalDoseForm: "tablet", priceRange: "₹300-550", genericAlternatives: [], foodInteractions: ["Take with meals", "Increase water intake"], commonSideEffects: ["Genital infections", "UTI", "Nausea", "Diarrhoea"], storageInstructions: "Store below 30°C.", description: "SGLT2 + metformin combo for Type 2 diabetes.", isScheduleH: true))

        db.append(DrugEntry(id: "sitagliptin-25", brandName: "Januvia 25", genericName: "Sitagliptin", saltComposition: "Sitagliptin 25mg", category: .antidiabetic, manufacturer: "MSD", commonDosages: ["25mg"], typicalDoseForm: "tablet", priceRange: "₹200-350", genericAlternatives: [GenericAlternative(brandName: "Istavel 25", manufacturer: "Sun Pharma", priceRange: "₹120-250")], foodInteractions: ["Can be taken with or without food"], commonSideEffects: ["Headache", "Nasopharyngitis"], storageInstructions: "Store below 30°C.", description: "Low-dose sitagliptin for severe renal impairment.", isScheduleH: true))

        db.append(DrugEntry(id: "empagliflozin-met", brandName: "Gibtulio Met", genericName: "Empagliflozin + Metformin", saltComposition: "Empagliflozin 5mg + Metformin 500mg", category: .antidiabetic, manufacturer: "Sun Pharma", commonDosages: ["5/500mg", "5/1000mg", "12.5/500mg", "12.5/1000mg"], typicalDoseForm: "tablet", priceRange: "₹220-400", genericAlternatives: [], foodInteractions: ["Take with meals"], commonSideEffects: ["Nausea", "UTI", "Genital infections"], storageInstructions: "Store below 30°C.", description: "Generic SGLT2 + metformin combination.", isScheduleH: true))

        db.append(DrugEntry(id: "gliclazide-met", brandName: "Glizid-M", genericName: "Gliclazide + Metformin", saltComposition: "Gliclazide 80mg + Metformin 500mg", category: .antidiabetic, manufacturer: "Sun Pharma", commonDosages: ["80/500mg"], typicalDoseForm: "tablet", priceRange: "₹40-80", genericAlternatives: [], foodInteractions: ["Take with meals", "Do not skip meals"], commonSideEffects: ["Hypoglycemia", "Nausea", "Diarrhoea"], storageInstructions: "Store below 30°C.", description: "Sulfonylurea + biguanide combination.", isScheduleH: true))

        // ── BP COMBOS ──

        db.append(DrugEntry(id: "amlodipine-olmesartan-hctz", brandName: "Olmezest-AH", genericName: "Olmesartan + Amlodipine + HCTZ", saltComposition: "Olmesartan 20mg + Amlodipine 5mg + HCTZ 12.5mg", category: .antihypertensive, manufacturer: "Sun Pharma", commonDosages: ["20/5/12.5mg"], typicalDoseForm: "tablet", priceRange: "₹130-250", genericAlternatives: [], foodInteractions: ["Can be taken with or without food"], commonSideEffects: ["Dizziness", "Ankle swelling", "Frequent urination"], storageInstructions: "Store below 30°C.", description: "Triple antihypertensive for resistant hypertension.", isScheduleH: true))

        db.append(DrugEntry(id: "losartan-amlodipine", brandName: "Losar-A", genericName: "Losartan + Amlodipine", saltComposition: "Losartan 50mg + Amlodipine 5mg", category: .antihypertensive, manufacturer: "Cipla", commonDosages: ["50/5mg"], typicalDoseForm: "tablet", priceRange: "₹60-120", genericAlternatives: [], foodInteractions: ["Can be taken with or without food"], commonSideEffects: ["Dizziness", "Ankle swelling", "Headache"], storageInstructions: "Store below 30°C.", description: "ARB + CCB combination for hypertension.", isScheduleH: true))

        db.append(DrugEntry(id: "enalapril-hctz", brandName: "Envas-H", genericName: "Enalapril + HCTZ", saltComposition: "Enalapril 10mg + HCTZ 25mg", category: .antihypertensive, manufacturer: "Cadila", commonDosages: ["5/12.5mg", "10/25mg"], typicalDoseForm: "tablet", priceRange: "₹20-50", genericAlternatives: [], foodInteractions: ["Can be taken with or without food"], commonSideEffects: ["Dry cough", "Dizziness", "Frequent urination"], storageInstructions: "Store below 30°C.", description: "ACE inhibitor + diuretic for hypertension.", isScheduleH: true))

        db.append(DrugEntry(id: "metoprolol-amlodipine", brandName: "Met-XL AM", genericName: "Metoprolol + Amlodipine", saltComposition: "Metoprolol 25mg + Amlodipine 5mg", category: .antihypertensive, manufacturer: "Cipla", commonDosages: ["25/2.5mg", "25/5mg", "50/5mg"], typicalDoseForm: "tablet", priceRange: "₹50-110", genericAlternatives: [], foodInteractions: ["Take with food"], commonSideEffects: ["Fatigue", "Ankle swelling", "Bradycardia", "Dizziness"], storageInstructions: "Store below 30°C.", description: "Beta-blocker + CCB combination for hypertension.", isScheduleH: true))

        db.append(DrugEntry(id: "nebivolol-amlodipine", brandName: "Nebicard-A", genericName: "Nebivolol + Amlodipine", saltComposition: "Nebivolol 5mg + Amlodipine 5mg", category: .antihypertensive, manufacturer: "Torrent", commonDosages: ["5/2.5mg", "5/5mg"], typicalDoseForm: "tablet", priceRange: "₹80-160", genericAlternatives: [], foodInteractions: ["Can be taken with or without food"], commonSideEffects: ["Fatigue", "Headache", "Ankle swelling", "Bradycardia"], storageInstructions: "Store below 30°C.", description: "Third-gen beta-blocker + CCB for hypertension.", isScheduleH: true))

        db.append(DrugEntry(id: "bisoprolol-amlodipine", brandName: "Concor-AM", genericName: "Bisoprolol + Amlodipine", saltComposition: "Bisoprolol 2.5mg + Amlodipine 5mg", category: .antihypertensive, manufacturer: "Merck", commonDosages: ["2.5/5mg", "5/5mg", "5/10mg"], typicalDoseForm: "tablet", priceRange: "₹70-150", genericAlternatives: [], foodInteractions: ["Can be taken with or without food"], commonSideEffects: ["Fatigue", "Ankle swelling", "Bradycardia", "Headache"], storageInstructions: "Store below 30°C.", description: "Selective beta-blocker + CCB for hypertension and angina.", isScheduleH: true))

        db.append(DrugEntry(id: "telmisartan-amlodipine-hctz", brandName: "Telma-3D", genericName: "Telmisartan + Amlodipine + Chlorthalidone", saltComposition: "Telmisartan 40mg + Amlodipine 5mg + Chlorthalidone 12.5mg", category: .antihypertensive, manufacturer: "Glenmark", commonDosages: ["40/5/12.5mg"], typicalDoseForm: "tablet", priceRange: "₹140-260", genericAlternatives: [], foodInteractions: ["Can be taken with or without food"], commonSideEffects: ["Dizziness", "Ankle swelling", "Low potassium", "Fatigue"], storageInstructions: "Store below 30°C.", description: "Triple combo with chlorthalidone for resistant hypertension.", isScheduleH: true))

        // ── CARDIAC ADDITIONAL COMBOS ──

        db.append(DrugEntry(id: "atorvastatin-aspirin-clop", brandName: "Atorva-AC", genericName: "Atorvastatin + Aspirin + Clopidogrel", saltComposition: "Atorvastatin 10mg + Aspirin 75mg + Clopidogrel 75mg", category: .cardiovascular, manufacturer: "Zydus", commonDosages: ["10/75/75mg", "20/75/75mg"], typicalDoseForm: "capsule", priceRange: "₹80-170", genericAlternatives: [], foodInteractions: ["Take with food", "Avoid grapefruit juice"], commonSideEffects: ["Bleeding", "Muscle pain", "Stomach pain"], storageInstructions: "Store below 30°C.", description: "Triple cardiac combo: statin + DAPT.", isScheduleH: true))

        db.append(DrugEntry(id: "rosuvastatin-10-asp-clop", brandName: "Rosave-ASP Gold", genericName: "Rosuvastatin + Aspirin + Clopidogrel", saltComposition: "Rosuvastatin 10mg + Aspirin 75mg + Clopidogrel 75mg", category: .cardiovascular, manufacturer: "Sun Pharma", commonDosages: ["10/75/75mg", "20/75/75mg"], typicalDoseForm: "capsule", priceRange: "₹100-200", genericAlternatives: [], foodInteractions: ["Take with food"], commonSideEffects: ["Bleeding", "Muscle pain", "Heartburn"], storageInstructions: "Store below 30°C.", description: "Rosuvastatin-based triple cardiac combo.", isScheduleH: true))

        db.append(DrugEntry(id: "atorvastatin-10-ez-asp", brandName: "Atorva-EZ-ASP", genericName: "Atorvastatin + Ezetimibe + Aspirin", saltComposition: "Atorvastatin 10mg + Ezetimibe 10mg + Aspirin 75mg", category: .cardiovascular, manufacturer: "Zydus", commonDosages: ["10/10/75mg"], typicalDoseForm: "capsule", priceRange: "₹100-200", genericAlternatives: [], foodInteractions: ["Take with food", "Avoid grapefruit juice"], commonSideEffects: ["Stomach pain", "Muscle pain", "Diarrhoea"], storageInstructions: "Store below 30°C.", description: "Triple combo: dual lipid + antiplatelet for high-risk cardiac patients.", isScheduleH: true))

        db.append(DrugEntry(id: "metoprolol-ramipril", brandName: "Cardace-R", genericName: "Ramipril + Metoprolol", saltComposition: "Ramipril 2.5mg + Metoprolol 25mg", category: .antihypertensive, manufacturer: "Sanofi", commonDosages: ["2.5/25mg", "5/25mg", "5/50mg"], typicalDoseForm: "capsule", priceRange: "₹60-130", genericAlternatives: [], foodInteractions: ["Take with food"], commonSideEffects: ["Dry cough", "Fatigue", "Dizziness", "Bradycardia"], storageInstructions: "Store below 30°C.", description: "ACE inhibitor + beta-blocker for post-MI and heart failure.", isScheduleH: true))

        // ── ANTIBIOTICS ADDITIONAL ──

        db.append(DrugEntry(id: "cefixime-azithromycin", brandName: "Zifi-AZ", genericName: "Cefixime + Azithromycin", saltComposition: "Cefixime 200mg + Azithromycin 250mg", category: .antibiotic, manufacturer: "Sun Pharma", commonDosages: ["200/250mg"], typicalDoseForm: "tablet", priceRange: "₹100-200", genericAlternatives: [], foodInteractions: ["Take with food"], commonSideEffects: ["Diarrhoea", "Nausea", "Abdominal pain", "Headache"], storageInstructions: "Store below 30°C.", description: "Cephalosporin + macrolide for respiratory and urogenital infections.", isScheduleH: true))

        db.append(DrugEntry(id: "amox-clav-1000", brandName: "Augmentin 1000", genericName: "Amoxicillin + Clavulanic Acid", saltComposition: "Amoxicillin 875mg + Clavulanic Acid 125mg", category: .antibiotic, manufacturer: "GSK", commonDosages: ["1000mg"], typicalDoseForm: "tablet", priceRange: "₹180-320", genericAlternatives: [GenericAlternative(brandName: "Amoxyclav 1000", manufacturer: "Cipla", priceRange: "₹120-220")], foodInteractions: ["Take at start of meal"], commonSideEffects: ["Diarrhoea", "Nausea", "Vomiting", "Rash"], storageInstructions: "Store below 25°C.", description: "High-strength amoxicillin-clavulanate for severe infections.", isScheduleH: true))

        db.append(DrugEntry(id: "levoflox-ornidazole", brandName: "Levoflox-OZ", genericName: "Levofloxacin + Ornidazole", saltComposition: "Levofloxacin 250mg + Ornidazole 500mg", category: .antibiotic, manufacturer: "Cipla", commonDosages: ["250/500mg"], typicalDoseForm: "tablet", priceRange: "₹50-100", genericAlternatives: [], foodInteractions: ["Take after food", "Avoid dairy", "Avoid alcohol"], commonSideEffects: ["Nausea", "Metallic taste", "Headache", "Dizziness"], storageInstructions: "Store below 30°C.", description: "Fluoroquinolone + antiprotozoal for GI and pelvic infections.", isScheduleH: true))

        db.append(DrugEntry(id: "cefpodoxime-clav", brandName: "Cepodem-XP", genericName: "Cefpodoxime + Clavulanic Acid", saltComposition: "Cefpodoxime 200mg + Clavulanic Acid 125mg", category: .antibiotic, manufacturer: "Cipla", commonDosages: ["200/125mg"], typicalDoseForm: "tablet", priceRange: "₹120-250", genericAlternatives: [], foodInteractions: ["Take with food"], commonSideEffects: ["Diarrhoea", "Nausea", "Rash", "Headache"], storageInstructions: "Store below 30°C.", description: "Third-gen cephalosporin + beta-lactamase inhibitor.", isScheduleH: true))

        db.append(DrugEntry(id: "cefuroxime-clav", brandName: "Ceftum-CV", genericName: "Cefuroxime + Clavulanic Acid", saltComposition: "Cefuroxime 250mg + Clavulanic Acid 125mg", category: .antibiotic, manufacturer: "GSK", commonDosages: ["250/125mg", "500/125mg"], typicalDoseForm: "tablet", priceRange: "₹150-300", genericAlternatives: [], foodInteractions: ["Take with food"], commonSideEffects: ["Diarrhoea", "Nausea", "Vomiting"], storageInstructions: "Store below 30°C.", description: "Second-gen cephalosporin + beta-lactamase inhibitor for resistant infections.", isScheduleH: true))

        db.append(DrugEntry(id: "cefixime-dicloxacillin", brandName: "Mahacef-D", genericName: "Cefixime + Dicloxacillin", saltComposition: "Cefixime 200mg + Dicloxacillin 500mg", category: .antibiotic, manufacturer: "Mankind", commonDosages: ["200/500mg"], typicalDoseForm: "tablet", priceRange: "₹100-200", genericAlternatives: [], foodInteractions: ["Take with food"], commonSideEffects: ["Diarrhoea", "Nausea", "Rash"], storageInstructions: "Store below 30°C.", description: "Cephalosporin + penicillin combo for mixed skin and soft tissue infections.", isScheduleH: true))

        db.append(DrugEntry(id: "faropenem", brandName: "Farobact", genericName: "Faropenem", saltComposition: "Faropenem 200mg", category: .antibiotic, manufacturer: "Cipla", commonDosages: ["200mg"], typicalDoseForm: "tablet", priceRange: "₹150-300", genericAlternatives: [], foodInteractions: ["Take with food"], commonSideEffects: ["Diarrhoea", "Nausea", "Headache", "Rash"], storageInstructions: "Store below 30°C.", description: "Oral penem antibiotic for UTI and respiratory infections. Last-line oral option.", isScheduleH: true))

        db.append(DrugEntry(id: "azithromycin-250", brandName: "Azee 250", genericName: "Azithromycin", saltComposition: "Azithromycin 250mg", category: .antibiotic, manufacturer: "Cipla", commonDosages: ["250mg"], typicalDoseForm: "tablet", priceRange: "₹40-80", genericAlternatives: [GenericAlternative(brandName: "Azithral 250", manufacturer: "Alembic", priceRange: "₹35-70")], foodInteractions: ["Take on empty stomach"], commonSideEffects: ["Nausea", "Diarrhoea", "Stomach pain"], storageInstructions: "Store below 30°C.", description: "Lower-dose azithromycin for mild infections and prophylaxis.", isScheduleH: true))

        // ── GI / ACID COMBOS ──

        db.append(DrugEntry(id: "omeprazole-dom", brandName: "Omez-D", genericName: "Omeprazole + Domperidone", saltComposition: "Omeprazole 20mg + Domperidone 10mg", category: .antiAcid, manufacturer: "Dr. Reddy's", commonDosages: ["20/10mg"], typicalDoseForm: "capsule", priceRange: "₹50-100", genericAlternatives: [], foodInteractions: ["Take before meals"], commonSideEffects: ["Headache", "Dry mouth", "Diarrhoea"], storageInstructions: "Store below 30°C.", description: "PPI + prokinetic for GERD with nausea/bloating.", isScheduleH: true))

        db.append(DrugEntry(id: "esomeprazole-levo", brandName: "Sompraz-L", genericName: "Esomeprazole + Levosulpiride", saltComposition: "Esomeprazole 40mg + Levosulpiride 75mg", category: .antiAcid, manufacturer: "Sun Pharma", commonDosages: ["40/75mg"], typicalDoseForm: "capsule", priceRange: "₹80-160", genericAlternatives: [], foodInteractions: ["Take before meals on empty stomach"], commonSideEffects: ["Headache", "Diarrhoea", "Breast tenderness"], storageInstructions: "Store below 30°C.", description: "PPI + prokinetic for functional dyspepsia and GERD.", isScheduleH: true))

        db.append(DrugEntry(id: "rabeprazole-levo", brandName: "Rablet-L", genericName: "Rabeprazole + Levosulpiride", saltComposition: "Rabeprazole 20mg + Levosulpiride 75mg", category: .antiAcid, manufacturer: "Lupin", commonDosages: ["20/75mg"], typicalDoseForm: "capsule", priceRange: "₹70-140", genericAlternatives: [], foodInteractions: ["Take before meals"], commonSideEffects: ["Headache", "Dry mouth", "Breast tenderness"], storageInstructions: "Store below 30°C.", description: "PPI + prokinetic combination for GERD with dyspepsia.", isScheduleH: true))

        db.append(DrugEntry(id: "dicyclomine-para", brandName: "Cyclopam Plus", genericName: "Dicyclomine + Paracetamol", saltComposition: "Dicyclomine 20mg + Paracetamol 325mg", category: .other, manufacturer: "Sun Pharma", commonDosages: ["20/325mg"], typicalDoseForm: "tablet", priceRange: "₹20-40", genericAlternatives: [], foodInteractions: ["Take before meals"], commonSideEffects: ["Dry mouth", "Drowsiness", "Blurred vision"], storageInstructions: "Store below 30°C.", description: "Antispasmodic + analgesic for abdominal cramps with pain.", isScheduleH: true))

        // ── PAIN COMBOS ──

        db.append(DrugEntry(id: "diclofenac-paracetamol-chlor", brandName: "Voveran Plus", genericName: "Diclofenac + Paracetamol + Chlorzoxazone", saltComposition: "Diclofenac 50mg + Paracetamol 325mg + Chlorzoxazone 250mg", category: .analgesic, manufacturer: "Novartis", commonDosages: ["Standard"], typicalDoseForm: "tablet", priceRange: "₹25-55", genericAlternatives: [], foodInteractions: ["Take with food"], commonSideEffects: ["Drowsiness", "Stomach pain", "Nausea", "Dizziness"], storageInstructions: "Store below 30°C.", description: "NSAID + analgesic + muscle relaxant for musculoskeletal pain with spasm.", isScheduleH: true))

        db.append(DrugEntry(id: "aceclofenac-para-thioco", brandName: "Zerodol-MR", genericName: "Aceclofenac + Paracetamol + Thiocolchicoside", saltComposition: "Aceclofenac 100mg + Paracetamol 325mg + Thiocolchicoside 4mg", category: .analgesic, manufacturer: "Ipca", commonDosages: ["Standard"], typicalDoseForm: "tablet", priceRange: "₹60-120", genericAlternatives: [], foodInteractions: ["Take after food"], commonSideEffects: ["Drowsiness", "Stomach pain", "Nausea", "Dizziness"], storageInstructions: "Store below 30°C.", description: "NSAID + analgesic + muscle relaxant for back pain and spasm.", isScheduleH: true))

        db.append(DrugEntry(id: "thiocolchicoside", brandName: "Myoril", genericName: "Thiocolchicoside", saltComposition: "Thiocolchicoside 4mg", category: .analgesic, manufacturer: "Sanofi", commonDosages: ["4mg", "8mg"], typicalDoseForm: "capsule", priceRange: "₹40-90", genericAlternatives: [GenericAlternative(brandName: "Thioril", manufacturer: "Mankind", priceRange: "₹25-55")], foodInteractions: ["Take with food"], commonSideEffects: ["Drowsiness", "Nausea", "Diarrhoea", "Dizziness"], storageInstructions: "Store below 30°C.", description: "Muscle relaxant for acute musculoskeletal spasm and back pain.", isScheduleH: true))

        db.append(DrugEntry(id: "chlorzoxazone", brandName: "Flexon-MR", genericName: "Chlorzoxazone + Diclofenac + Paracetamol", saltComposition: "Chlorzoxazone 250mg + Diclofenac 50mg + Paracetamol 325mg", category: .analgesic, manufacturer: "Aristo", commonDosages: ["Standard"], typicalDoseForm: "tablet", priceRange: "₹25-50", genericAlternatives: [], foodInteractions: ["Take with food"], commonSideEffects: ["Drowsiness", "Stomach pain", "Nausea"], storageInstructions: "Store below 30°C.", description: "Triple-action for musculoskeletal pain with muscle spasm.", isScheduleH: true))

        db.append(DrugEntry(id: "tizanidine", brandName: "Sirdalud", genericName: "Tizanidine", saltComposition: "Tizanidine 2mg", category: .analgesic, manufacturer: "Novartis", commonDosages: ["2mg", "4mg"], typicalDoseForm: "tablet", priceRange: "₹20-50", genericAlternatives: [GenericAlternative(brandName: "Tizan", manufacturer: "Sun Pharma", priceRange: "₹15-35")], foodInteractions: ["Can be taken with or without food", "Avoid alcohol"], commonSideEffects: ["Drowsiness", "Dry mouth", "Dizziness", "Hypotension", "Weakness"], storageInstructions: "Store below 30°C.", description: "Centrally-acting muscle relaxant for spasticity and acute spasm.", isScheduleH: true))

        db.append(DrugEntry(id: "etoricoxib-thioco", brandName: "Nucoxia-MR", genericName: "Etoricoxib + Thiocolchicoside", saltComposition: "Etoricoxib 60mg + Thiocolchicoside 4mg", category: .analgesic, manufacturer: "Dr. Reddy's", commonDosages: ["60/4mg"], typicalDoseForm: "tablet", priceRange: "₹80-160", genericAlternatives: [], foodInteractions: ["Take after food"], commonSideEffects: ["Drowsiness", "Headache", "Nausea", "Dizziness"], storageInstructions: "Store below 30°C.", description: "COX-2 inhibitor + muscle relaxant for musculoskeletal pain.", isScheduleH: true))

        // ── RESPIRATORY COMBOS ──

        db.append(DrugEntry(id: "budesonide-formoterol", brandName: "Symbicort", genericName: "Budesonide + Formoterol", saltComposition: "Budesonide 200mcg + Formoterol 6mcg", category: .respiratory, manufacturer: "AstraZeneca", commonDosages: ["100/6mcg", "200/6mcg", "400/6mcg"], typicalDoseForm: "inhaler", priceRange: "₹400-750", genericAlternatives: [GenericAlternative(brandName: "Foracort", manufacturer: "Cipla", priceRange: "₹300-600")], foodInteractions: ["Rinse mouth after use"], commonSideEffects: ["Oral thrush", "Hoarse voice", "Headache", "Tremor"], storageInstructions: "Store below 30°C.", description: "ICS/LABA combo for asthma and COPD. SMART therapy option.", isScheduleH: true))

        db.append(DrugEntry(id: "budesonide-formoterol-glyco", brandName: "Trixeo Aerosphere", genericName: "Budesonide + Formoterol + Glycopyrronium", saltComposition: "Budesonide 160mcg + Formoterol 4.8mcg + Glycopyrronium 7.2mcg", category: .respiratory, manufacturer: "AstraZeneca", commonDosages: ["Standard"], typicalDoseForm: "inhaler", priceRange: "₹600-1200", genericAlternatives: [], foodInteractions: ["Rinse mouth after use"], commonSideEffects: ["Oral thrush", "Dry mouth", "Hoarse voice", "Headache"], storageInstructions: "Store below 30°C.", description: "Triple inhaler (ICS/LABA/LAMA) for moderate-to-severe COPD.", isScheduleH: true))

        db.append(DrugEntry(id: "umeclidinium-vilanterol", brandName: "Anoro Ellipta", genericName: "Umeclidinium + Vilanterol", saltComposition: "Umeclidinium 62.5mcg + Vilanterol 25mcg", category: .respiratory, manufacturer: "GSK", commonDosages: ["62.5/25mcg"], typicalDoseForm: "inhaler", priceRange: "₹500-1000", genericAlternatives: [], foodInteractions: ["No food interactions"], commonSideEffects: ["Headache", "Pharyngitis", "Cough", "UTI"], storageInstructions: "Store below 30°C.", description: "LAMA/LABA dual bronchodilator for COPD maintenance.", isScheduleH: true))

        db.append(DrugEntry(id: "fluticasone-vilanterol", brandName: "Breo Ellipta", genericName: "Fluticasone Furoate + Vilanterol", saltComposition: "Fluticasone 100mcg + Vilanterol 25mcg", category: .respiratory, manufacturer: "GSK", commonDosages: ["100/25mcg", "200/25mcg"], typicalDoseForm: "inhaler", priceRange: "₹500-1000", genericAlternatives: [], foodInteractions: ["Rinse mouth after use"], commonSideEffects: ["Oral thrush", "Headache", "Nasopharyngitis"], storageInstructions: "Store below 30°C.", description: "Once-daily ICS/LABA for asthma and COPD.", isScheduleH: true))

        db.append(DrugEntry(id: "mometasone-formoterol", brandName: "Dulera", genericName: "Mometasone + Formoterol", saltComposition: "Mometasone 200mcg + Formoterol 5mcg", category: .respiratory, manufacturer: "MSD", commonDosages: ["100/5mcg", "200/5mcg"], typicalDoseForm: "inhaler", priceRange: "₹400-800", genericAlternatives: [GenericAlternative(brandName: "Momera-F", manufacturer: "Cipla", priceRange: "₹300-600")], foodInteractions: ["Rinse mouth after use"], commonSideEffects: ["Oral thrush", "Headache", "Nasopharyngitis"], storageInstructions: "Store below 30°C.", description: "ICS/LABA combination for asthma maintenance.", isScheduleH: true))

        // ── MENTAL HEALTH ADDITIONAL ──

        db.append(DrugEntry(id: "aripiprazole", brandName: "Abilify", genericName: "Aripiprazole", saltComposition: "Aripiprazole 10mg", category: .antiDepressant, manufacturer: "Otsuka", commonDosages: ["2mg", "5mg", "10mg", "15mg", "20mg", "30mg"], typicalDoseForm: "tablet", priceRange: "₹60-180", genericAlternatives: [GenericAlternative(brandName: "Aripra", manufacturer: "Sun Pharma", priceRange: "₹40-120")], foodInteractions: ["Can be taken with or without food"], commonSideEffects: ["Restlessness", "Insomnia", "Headache", "Nausea", "Weight gain (less than others)"], storageInstructions: "Store below 30°C.", description: "Atypical antipsychotic (partial D2 agonist) for schizophrenia, bipolar, and as adjunct for depression.", isScheduleH: true))

        db.append(DrugEntry(id: "asenapine", brandName: "Saphris", genericName: "Asenapine", saltComposition: "Asenapine 5mg", category: .antiDepressant, manufacturer: "Various", commonDosages: ["2.5mg", "5mg", "10mg"], typicalDoseForm: "sublingual tablet", priceRange: "₹100-250", genericAlternatives: [], foodInteractions: ["Place under tongue — do not eat/drink for 10 minutes"], commonSideEffects: ["Oral numbness", "Drowsiness", "Weight gain", "Dizziness"], storageInstructions: "Store below 30°C.", description: "Sublingual atypical antipsychotic for schizophrenia and bipolar disorder.", isScheduleH: true))

        db.append(DrugEntry(id: "oxcarbazepine", brandName: "Oxetol", genericName: "Oxcarbazepine", saltComposition: "Oxcarbazepine 300mg", category: .other, manufacturer: "Sun Pharma", commonDosages: ["150mg", "300mg", "600mg"], typicalDoseForm: "tablet", priceRange: "₹40-100", genericAlternatives: [GenericAlternative(brandName: "Trileptal", manufacturer: "Novartis", priceRange: "₹60-150")], foodInteractions: ["Can be taken with or without food"], commonSideEffects: ["Drowsiness", "Dizziness", "Nausea", "Hyponatremia", "Rash"], storageInstructions: "Store below 30°C.", description: "Anticonvulsant for epilepsy and trigeminal neuralgia. Fewer interactions than carbamazepine.", isScheduleH: true))

        db.append(DrugEntry(id: "zolpidem", brandName: "Zolfresh", genericName: "Zolpidem", saltComposition: "Zolpidem Tartrate 10mg", category: .antiDepressant, manufacturer: "Sun Pharma", commonDosages: ["5mg", "10mg"], typicalDoseForm: "tablet", priceRange: "₹30-70", genericAlternatives: [GenericAlternative(brandName: "Stilnoct", manufacturer: "Sanofi", priceRange: "₹50-110")], foodInteractions: ["Take at bedtime on empty stomach", "Avoid alcohol strictly"], commonSideEffects: ["Drowsiness", "Dizziness", "Headache", "Amnesia", "Dependence"], storageInstructions: "Store below 30°C.", description: "Non-benzodiazepine hypnotic for short-term insomnia. Max 2-4 weeks use.", isScheduleH: true))

        db.append(DrugEntry(id: "buspirone", brandName: "Buspin", genericName: "Buspirone", saltComposition: "Buspirone 5mg", category: .antiDepressant, manufacturer: "Sun Pharma", commonDosages: ["5mg", "10mg"], typicalDoseForm: "tablet", priceRange: "₹20-50", genericAlternatives: [], foodInteractions: ["Take consistently with or without food"], commonSideEffects: ["Dizziness", "Nausea", "Headache", "Nervousness"], storageInstructions: "Store below 30°C.", description: "Non-benzodiazepine anxiolytic for GAD. No dependence potential.", isScheduleH: true))

        db.append(DrugEntry(id: "escitalopram-clonazepam", brandName: "Nexito Plus", genericName: "Escitalopram + Clonazepam", saltComposition: "Escitalopram 10mg + Clonazepam 0.5mg", category: .antiDepressant, manufacturer: "Sun Pharma", commonDosages: ["5/0.25mg", "10/0.5mg", "20/0.5mg"], typicalDoseForm: "tablet", priceRange: "₹80-180", genericAlternatives: [GenericAlternative(brandName: "S Citadep Plus", manufacturer: "Cipla", priceRange: "₹50-120")], foodInteractions: ["Can be taken with or without food", "Avoid alcohol"], commonSideEffects: ["Drowsiness", "Nausea", "Headache", "Dependence (clonazepam)"], storageInstructions: "Store below 30°C.", description: "SSRI + benzodiazepine for depression/anxiety with initial anxiety relief.", isScheduleH: true))

        // ── VITAMINS ADDITIONAL ──

        db.append(DrugEntry(id: "calcitriol", brandName: "Rocaltrol", genericName: "Calcitriol", saltComposition: "Calcitriol 0.25mcg", category: .vitamin, manufacturer: "Roche", commonDosages: ["0.25mcg", "0.5mcg"], typicalDoseForm: "capsule", priceRange: "₹80-180", genericAlternatives: [GenericAlternative(brandName: "Trical", manufacturer: "Intas", priceRange: "₹50-120")], foodInteractions: ["Can be taken with or without food"], commonSideEffects: ["Hypercalcemia", "Nausea", "Headache", "Weakness"], storageInstructions: "Store below 25°C. Protect from light.", description: "Active Vitamin D3 for CKD, hypoparathyroidism, and severe deficiency.", isScheduleH: true))

        db.append(DrugEntry(id: "alfacalcidol", brandName: "Alpha D3", genericName: "Alfacalcidol", saltComposition: "Alfacalcidol 0.25mcg", category: .vitamin, manufacturer: "Abbott", commonDosages: ["0.25mcg", "0.5mcg", "1mcg"], typicalDoseForm: "capsule", priceRange: "₹60-140", genericAlternatives: [], foodInteractions: ["Can be taken with or without food"], commonSideEffects: ["Hypercalcemia", "Nausea", "Headache"], storageInstructions: "Store below 25°C.", description: "Active Vitamin D analogue for renal osteodystrophy and osteoporosis.", isScheduleH: true))

        db.append(DrugEntry(id: "calcium-citrate-d3", brandName: "Cipcal", genericName: "Calcium Citrate + Vitamin D3", saltComposition: "Calcium Citrate 1000mg + Vitamin D3 200IU", category: .vitamin, manufacturer: "Cipla", commonDosages: ["Standard"], typicalDoseForm: "tablet", priceRange: "₹100-180", genericAlternatives: [GenericAlternative(brandName: "Ostocalcium", manufacturer: "GSK", priceRange: "₹80-150")], foodInteractions: ["Can be taken with or without food — citrate not affected by food"], commonSideEffects: ["Constipation", "Bloating", "Gas"], storageInstructions: "Store below 30°C.", description: "Calcium citrate (better absorbed than carbonate on empty stomach) + D3.", isScheduleH: false))

        db.append(DrugEntry(id: "iron-sucrose", brandName: "Orofer-FCM", genericName: "Ferric Carboxymaltose", saltComposition: "Ferric Carboxymaltose 500mg/10ml", category: .vitamin, manufacturer: "Emcure", commonDosages: ["500mg", "1000mg"], typicalDoseForm: "injection", priceRange: "₹1500-3000", genericAlternatives: [], foodInteractions: ["Injectable — no food interactions"], commonSideEffects: ["Headache", "Nausea", "Injection site reactions", "Hypophosphatemia"], storageInstructions: "Store below 30°C.", description: "IV iron for severe iron deficiency anemia when oral iron fails or is not tolerated.", isScheduleH: true))

        db.append(DrugEntry(id: "folic-acid", brandName: "Folvite", genericName: "Folic Acid", saltComposition: "Folic Acid 5mg", category: .vitamin, manufacturer: "Pfizer", commonDosages: ["1mg", "5mg"], typicalDoseForm: "tablet", priceRange: "₹5-15", genericAlternatives: [], foodInteractions: ["Can be taken with or without food"], commonSideEffects: ["Generally well-tolerated", "Nausea (rare)"], storageInstructions: "Store below 30°C.", description: "Folic acid for pregnancy, anaemia, and methotrexate supplementation.", isScheduleH: false))

        db.append(DrugEntry(id: "vitamin-b-complex", brandName: "Polybion", genericName: "Vitamin B Complex", saltComposition: "Vitamins B1+B2+B3+B5+B6+B12", category: .vitamin, manufacturer: "Abbott", commonDosages: ["Standard"], typicalDoseForm: "tablet", priceRange: "₹20-45", genericAlternatives: [GenericAlternative(brandName: "Becosules", manufacturer: "Pfizer", priceRange: "₹25-50")], foodInteractions: ["Take after meals"], commonSideEffects: ["Nausea (rare)", "Yellow urine (normal)"], storageInstructions: "Store below 30°C.", description: "B-complex supplement for general deficiency and neuropathy support.", isScheduleH: false))

        db.append(DrugEntry(id: "dexorange", brandName: "Dexorange", genericName: "Iron + Vitamin B12 + Folic Acid", saltComposition: "Ferric Ammonium Citrate 160mg + Folic Acid 0.5mg + Cyanocobalamin 7.5mcg", category: .vitamin, manufacturer: "Franco-Indian", commonDosages: ["15ml"], typicalDoseForm: "syrup", priceRange: "₹100-180", genericAlternatives: [], foodInteractions: ["Take on empty stomach", "Avoid tea/coffee within 2 hours"], commonSideEffects: ["Constipation", "Dark stools", "Nausea", "Metallic taste"], storageInstructions: "Store below 30°C.", description: "Popular iron tonic syrup for anaemia in India.", isScheduleH: false))

        // ── MISCELLANEOUS REMAINING ──

        db.append(DrugEntry(id: "pantoprazole-d-sr", brandName: "Pantop-D SR", genericName: "Pantoprazole + Domperidone SR", saltComposition: "Pantoprazole 40mg + Domperidone 30mg SR", category: .antiAcid, manufacturer: "Aristo", commonDosages: ["40/30mg"], typicalDoseForm: "capsule", priceRange: "₹50-100", genericAlternatives: [], foodInteractions: ["Take before meals"], commonSideEffects: ["Headache", "Dry mouth", "Diarrhoea"], storageInstructions: "Store below 30°C.", description: "Generic PPI + prokinetic combo for GERD.", isScheduleH: true))

        db.append(DrugEntry(id: "rabeprazole-aceclofenac", brandName: "Razo-Plus", genericName: "Rabeprazole + Aceclofenac", saltComposition: "Rabeprazole 20mg + Aceclofenac 200mg SR", category: .analgesic, manufacturer: "Dr. Reddy's", commonDosages: ["20/200mg"], typicalDoseForm: "tablet", priceRange: "₹60-120", genericAlternatives: [], foodInteractions: ["Take with food"], commonSideEffects: ["Stomach pain", "Nausea", "Headache"], storageInstructions: "Store below 30°C.", description: "PPI-protected NSAID for pain with gastroprotection.", isScheduleH: true))

        db.append(DrugEntry(id: "pregabalin-methylcobalamin", brandName: "Pregabalin-M", genericName: "Pregabalin + Methylcobalamin", saltComposition: "Pregabalin 75mg + Methylcobalamin 750mcg", category: .other, manufacturer: "Various", commonDosages: ["75/750mcg", "150/750mcg"], typicalDoseForm: "capsule", priceRange: "₹80-180", genericAlternatives: [GenericAlternative(brandName: "Pregalin-M", manufacturer: "Torrent", priceRange: "₹60-140")], foodInteractions: ["Can be taken with or without food"], commonSideEffects: ["Dizziness", "Drowsiness", "Weight gain", "Dry mouth"], storageInstructions: "Store below 30°C.", description: "Nerve pain combo: gabapentinoid + vitamin B12 for diabetic neuropathy.", isScheduleH: true))

        db.append(DrugEntry(id: "gabapentin-methylcobalamin", brandName: "Gabapin-NT", genericName: "Gabapentin + Nortriptyline", saltComposition: "Gabapentin 300mg + Nortriptyline 10mg", category: .other, manufacturer: "Intas", commonDosages: ["300/10mg", "400/10mg"], typicalDoseForm: "tablet", priceRange: "₹60-140", genericAlternatives: [], foodInteractions: ["Can be taken with or without food", "Avoid alcohol"], commonSideEffects: ["Drowsiness", "Dry mouth", "Dizziness", "Weight gain"], storageInstructions: "Store below 30°C.", description: "Gabapentinoid + TCA for neuropathic pain syndromes.", isScheduleH: true))

        db.append(DrugEntry(id: "duloxetine-methylcobalamin", brandName: "Duzela-M", genericName: "Duloxetine + Methylcobalamin", saltComposition: "Duloxetine 20mg + Methylcobalamin 1500mcg", category: .antiDepressant, manufacturer: "Sun Pharma", commonDosages: ["20/1500mcg", "30/1500mcg"], typicalDoseForm: "capsule", priceRange: "₹80-160", genericAlternatives: [], foodInteractions: ["Can be taken with or without food"], commonSideEffects: ["Nausea", "Dry mouth", "Drowsiness", "Constipation"], storageInstructions: "Store below 30°C.", description: "SNRI + B12 for diabetic neuropathic pain.", isScheduleH: true))

        db.append(DrugEntry(id: "rosuvastatin-fenofibrate", brandName: "Rozavel-F", genericName: "Rosuvastatin + Fenofibrate", saltComposition: "Rosuvastatin 10mg + Fenofibrate 145mg", category: .cholesterol, manufacturer: "Sun Pharma", commonDosages: ["5/145mg", "10/145mg", "10/160mg"], typicalDoseForm: "tablet", priceRange: "₹120-220", genericAlternatives: [], foodInteractions: ["Take with meals", "Avoid alcohol"], commonSideEffects: ["Muscle pain", "Stomach pain", "Nausea", "Elevated liver enzymes"], storageInstructions: "Store below 30°C.", description: "Statin + fibrate for mixed dyslipidemia (high cholesterol + triglycerides).", isScheduleH: true))

        db.append(DrugEntry(id: "rosuvastatin-ezetimibe", brandName: "Rozavel-EZ", genericName: "Rosuvastatin + Ezetimibe", saltComposition: "Rosuvastatin 10mg + Ezetimibe 10mg", category: .cholesterol, manufacturer: "Sun Pharma", commonDosages: ["5/10mg", "10/10mg", "20/10mg"], typicalDoseForm: "tablet", priceRange: "₹100-200", genericAlternatives: [], foodInteractions: ["Can be taken with or without food"], commonSideEffects: ["Muscle pain", "Headache", "Diarrhoea"], storageInstructions: "Store below 30°C.", description: "Statin + cholesterol absorption inhibitor for aggressive LDL lowering.", isScheduleH: true))

        db.append(DrugEntry(id: "montelukast-bambuterol", brandName: "Montair Plus", genericName: "Montelukast + Bambuterol", saltComposition: "Montelukast 10mg + Bambuterol 10mg", category: .respiratory, manufacturer: "Cipla", commonDosages: ["10/10mg"], typicalDoseForm: "tablet", priceRange: "₹80-160", genericAlternatives: [], foodInteractions: ["Take in the evening"], commonSideEffects: ["Headache", "Tremor", "Palpitations", "Nausea"], storageInstructions: "Store below 30°C.", description: "Leukotriene antagonist + oral bronchodilator for asthma.", isScheduleH: true))

        db.append(DrugEntry(id: "bambuterol", brandName: "Bambudil", genericName: "Bambuterol", saltComposition: "Bambuterol 10mg", category: .respiratory, manufacturer: "Various", commonDosages: ["10mg", "20mg"], typicalDoseForm: "tablet", priceRange: "₹30-60", genericAlternatives: [], foodInteractions: ["Take in the evening"], commonSideEffects: ["Tremor", "Palpitations", "Headache", "Muscle cramps"], storageInstructions: "Store below 30°C.", description: "Long-acting oral bronchodilator (prodrug of terbutaline) for nocturnal asthma.", isScheduleH: true))

        db.append(DrugEntry(id: "acebrophylline", brandName: "Duolin Respule", genericName: "Acebrophylline", saltComposition: "Acebrophylline 100mg", category: .respiratory, manufacturer: "Various", commonDosages: ["100mg"], typicalDoseForm: "capsule", priceRange: "₹50-100", genericAlternatives: [], foodInteractions: ["Take with food"], commonSideEffects: ["Nausea", "Palpitations", "Headache", "Stomach upset"], storageInstructions: "Store below 30°C.", description: "Mucoregulator + bronchodilator for asthma and COPD.", isScheduleH: true))

        db.append(DrugEntry(id: "doxofylline", brandName: "Doxobid", genericName: "Doxofylline", saltComposition: "Doxofylline 400mg", category: .respiratory, manufacturer: "Various", commonDosages: ["200mg", "400mg"], typicalDoseForm: "tablet", priceRange: "₹40-90", genericAlternatives: [], foodInteractions: ["Can be taken with or without food"], commonSideEffects: ["Nausea", "Headache", "Palpitations", "Insomnia"], storageInstructions: "Store below 30°C.", description: "Methylxanthine bronchodilator with fewer cardiac side effects than theophylline.", isScheduleH: true))

        db.append(DrugEntry(id: "erdosteine", brandName: "Erdotin", genericName: "Erdosteine", saltComposition: "Erdosteine 300mg", category: .respiratory, manufacturer: "Various", commonDosages: ["300mg"], typicalDoseForm: "capsule", priceRange: "₹60-120", genericAlternatives: [], foodInteractions: ["Take with food"], commonSideEffects: ["Nausea", "Diarrhoea", "Stomach pain", "Rash"], storageInstructions: "Store below 30°C.", description: "Mucolytic + antioxidant for COPD exacerbation prevention.", isScheduleH: true))

        db.append(DrugEntry(id: "levocetirizine-montelukast-ambroxol", brandName: "Montair-LAX", genericName: "Montelukast + Levocetirizine + Ambroxol", saltComposition: "Montelukast 10mg + Levocetirizine 5mg + Ambroxol 75mg SR", category: .respiratory, manufacturer: "Cipla", commonDosages: ["10/5/75mg"], typicalDoseForm: "tablet", priceRange: "₹120-220", genericAlternatives: [], foodInteractions: ["Take in the evening"], commonSideEffects: ["Drowsiness", "Headache", "Dry mouth", "Nausea"], storageInstructions: "Store below 30°C.", description: "Triple allergy-asthma combo: LTRA + antihistamine + mucolytic.", isScheduleH: true))

        db.append(DrugEntry(id: "atorvastatin-asp", brandName: "Atorva-ASP", genericName: "Atorvastatin + Aspirin", saltComposition: "Atorvastatin 10mg + Aspirin 75mg", category: .cardiovascular, manufacturer: "Zydus", commonDosages: ["10/75mg", "20/75mg"], typicalDoseForm: "capsule", priceRange: "₹40-90", genericAlternatives: [], foodInteractions: ["Take with food"], commonSideEffects: ["Stomach pain", "Muscle pain", "Heartburn"], storageInstructions: "Store below 30°C.", description: "Statin + antiplatelet for cardiovascular risk reduction.", isScheduleH: true))

        db.append(DrugEntry(id: "rosuvastatin-asp", brandName: "Rozavel-ASP", genericName: "Rosuvastatin + Aspirin", saltComposition: "Rosuvastatin 10mg + Aspirin 75mg", category: .cardiovascular, manufacturer: "Sun Pharma", commonDosages: ["5/75mg", "10/75mg", "20/75mg"], typicalDoseForm: "capsule", priceRange: "₹60-120", genericAlternatives: [], foodInteractions: ["Take with food"], commonSideEffects: ["Stomach pain", "Muscle pain", "Heartburn"], storageInstructions: "Store below 30°C.", description: "Rosuvastatin + antiplatelet combination.", isScheduleH: true))

        db.append(DrugEntry(id: "clopidogrel-asp-150", brandName: "Deplatt-A 150", genericName: "Aspirin + Clopidogrel", saltComposition: "Aspirin 150mg + Clopidogrel 75mg", category: .cardiovascular, manufacturer: "Torrent", commonDosages: ["150/75mg"], typicalDoseForm: "tablet", priceRange: "₹60-130", genericAlternatives: [], foodInteractions: ["Take with food"], commonSideEffects: ["Bleeding", "Bruising", "Stomach pain"], storageInstructions: "Store below 30°C.", description: "Higher-dose aspirin + clopidogrel DAPT.", isScheduleH: true))

        db.append(DrugEntry(id: "pantoprazole-levo-dom", brandName: "Pantocid-L", genericName: "Pantoprazole + Levosulpiride", saltComposition: "Pantoprazole 40mg + Levosulpiride 75mg SR", category: .antiAcid, manufacturer: "Sun Pharma", commonDosages: ["40/75mg"], typicalDoseForm: "capsule", priceRange: "₹70-140", genericAlternatives: [], foodInteractions: ["Take before meals"], commonSideEffects: ["Headache", "Breast tenderness", "Diarrhoea"], storageInstructions: "Store below 30°C.", description: "PPI + prokinetic for functional dyspepsia.", isScheduleH: true))

        db.append(DrugEntry(id: "ambroxol-guaifenesin-terbutaline", brandName: "Ascoril-LS", genericName: "Ambroxol + Guaifenesin + Levosalbutamol", saltComposition: "Ambroxol 30mg + Guaifenesin 50mg + Levosalbutamol 1mg", category: .respiratory, manufacturer: "Glenmark", commonDosages: ["5ml"], typicalDoseForm: "syrup", priceRange: "₹60-120", genericAlternatives: [], foodInteractions: ["Can be taken with or without food"], commonSideEffects: ["Tremor", "Palpitations", "Nausea", "Headache"], storageInstructions: "Store below 30°C.", description: "Triple cough syrup: mucolytic + expectorant + bronchodilator.", isScheduleH: true))

        db.append(DrugEntry(id: "salbutamol-guaifenesin", brandName: "Ascoril", genericName: "Salbutamol + Guaifenesin + Bromhexine", saltComposition: "Salbutamol 2mg + Guaifenesin 100mg + Bromhexine 4mg per 5ml", category: .respiratory, manufacturer: "Glenmark", commonDosages: ["5ml", "10ml"], typicalDoseForm: "syrup", priceRange: "₹60-120", genericAlternatives: [GenericAlternative(brandName: "Alex", manufacturer: "Glenmark", priceRange: "₹50-100")], foodInteractions: ["Can be taken with or without food"], commonSideEffects: ["Tremor", "Palpitations", "Nausea", "Stomach upset"], storageInstructions: "Store below 30°C.", description: "Popular cough syrup: bronchodilator + expectorant + mucolytic.", isScheduleH: true))

        db.append(DrugEntry(id: "dextromethorphan-cpheniramine", brandName: "Corex-DX", genericName: "Dextromethorphan + Chlorpheniramine", saltComposition: "Dextromethorphan 10mg + Chlorpheniramine 4mg per 5ml", category: .respiratory, manufacturer: "Pfizer", commonDosages: ["5ml"], typicalDoseForm: "syrup", priceRange: "₹50-100", genericAlternatives: [], foodInteractions: ["Take at bedtime if drowsy"], commonSideEffects: ["Drowsiness", "Dry mouth", "Dizziness", "Constipation"], storageInstructions: "Store below 30°C.", description: "Cough suppressant + antihistamine for dry cough with allergic symptoms.", isScheduleH: true))

        db.append(DrugEntry(id: "norfloxacin-metronidazole", brandName: "Nor-Metrogyl", genericName: "Norfloxacin + Metronidazole", saltComposition: "Norfloxacin 400mg + Metronidazole 500mg", category: .antibiotic, manufacturer: "J.B. Chemicals", commonDosages: ["400/500mg"], typicalDoseForm: "tablet", priceRange: "₹25-55", genericAlternatives: [], foodInteractions: ["Take on empty stomach", "Strictly avoid alcohol"], commonSideEffects: ["Nausea", "Metallic taste", "Headache", "Diarrhoea"], storageInstructions: "Store below 30°C.", description: "Antibiotic + antiprotozoal for infectious diarrhoea and dysentery.", isScheduleH: true))

        db.append(DrugEntry(id: "ciprofloxacin-tinidazole", brandName: "Ciplox-TZ", genericName: "Ciprofloxacin + Tinidazole", saltComposition: "Ciprofloxacin 500mg + Tinidazole 600mg", category: .antibiotic, manufacturer: "Cipla", commonDosages: ["500/600mg"], typicalDoseForm: "tablet", priceRange: "₹30-70", genericAlternatives: [], foodInteractions: ["Take on empty stomach", "Avoid dairy", "Avoid alcohol for 72 hours"], commonSideEffects: ["Nausea", "Metallic taste", "Headache", "Dizziness"], storageInstructions: "Store below 30°C.", description: "Fluoroquinolone + antiprotozoal for GI and pelvic infections.", isScheduleH: true))

        db.append(DrugEntry(id: "glimepiride-pioglitazone-met", brandName: "Glycomet Trio PG", genericName: "Glimepiride + Pioglitazone + Metformin", saltComposition: "Glimepiride 1mg + Pioglitazone 15mg + Metformin 500mg", category: .antidiabetic, manufacturer: "USV", commonDosages: ["1/15/500mg", "2/15/500mg"], typicalDoseForm: "tablet", priceRange: "₹80-160", genericAlternatives: [], foodInteractions: ["Take with meals"], commonSideEffects: ["Hypoglycemia", "Weight gain", "Oedema", "Nausea"], storageInstructions: "Store below 30°C.", description: "Triple oral diabetes combo: SU + TZD + biguanide.", isScheduleH: true))

        db.append(DrugEntry(id: "telmisartan-ramipril", brandName: "Telsar-R", genericName: "Telmisartan + Ramipril", saltComposition: "Telmisartan 40mg + Ramipril 5mg", category: .antihypertensive, manufacturer: "Various", commonDosages: ["40/2.5mg", "40/5mg"], typicalDoseForm: "capsule", priceRange: "₹80-160", genericAlternatives: [], foodInteractions: ["Can be taken with or without food"], commonSideEffects: ["Dizziness", "Dry cough", "Hyperkalemia", "Hypotension"], storageInstructions: "Store below 30°C.", description: "ARB + ACE inhibitor combo (note: dual RAAS blockade used selectively).", isScheduleH: true))

        db.append(DrugEntry(id: "nateglinide", brandName: "Glinate", genericName: "Nateglinide", saltComposition: "Nateglinide 120mg", category: .antidiabetic, manufacturer: "Novartis", commonDosages: ["60mg", "120mg"], typicalDoseForm: "tablet", priceRange: "₹60-130", genericAlternatives: [], foodInteractions: ["Take 1-30 minutes before meals"], commonSideEffects: ["Hypoglycemia", "Upper respiratory infection", "Dizziness"], storageInstructions: "Store below 30°C.", description: "D-phenylalanine derivative for mealtime glucose control in Type 2 diabetes.", isScheduleH: true))

        db.append(DrugEntry(id: "epalrestat", brandName: "Eparon", genericName: "Epalrestat", saltComposition: "Epalrestat 150mg", category: .antidiabetic, manufacturer: "Various", commonDosages: ["50mg", "150mg"], typicalDoseForm: "tablet", priceRange: "₹60-130", genericAlternatives: [], foodInteractions: ["Take before meals"], commonSideEffects: ["Nausea", "Diarrhoea", "Rash", "Liver enzyme elevation"], storageInstructions: "Store below 30°C. Protect from light.", description: "Aldose reductase inhibitor for diabetic neuropathy. Popular in India.", isScheduleH: true))

        db.append(DrugEntry(id: "saroglitazar", brandName: "Lipaglyn", genericName: "Saroglitazar", saltComposition: "Saroglitazar 4mg", category: .antidiabetic, manufacturer: "Zydus Cadila", commonDosages: ["4mg"], typicalDoseForm: "tablet", priceRange: "₹200-400", genericAlternatives: [], foodInteractions: ["Can be taken with or without food"], commonSideEffects: ["Gastritis", "Asthenia", "Pain"], storageInstructions: "Store below 30°C.", description: "First-in-class PPAR alpha/gamma agonist for diabetic dyslipidemia. Made in India.", isScheduleH: true))

        // ════════════════════════════════════════════
        // BATCH 4 — FINAL ENTRIES TO HIT 500+
        // ════════════════════════════════════════════

        db.append(DrugEntry(id: "vildagliptin-met", brandName: "Jalra-M 50/500", genericName: "Vildagliptin + Metformin", saltComposition: "Vildagliptin 50mg + Metformin 500mg", category: .antidiabetic, manufacturer: "USV", commonDosages: ["50/500mg", "50/1000mg"], typicalDoseForm: "tablet", priceRange: "₹200-350", genericAlternatives: [GenericAlternative(brandName: "Galvus Met", manufacturer: "Novartis", priceRange: "₹280-450")], foodInteractions: ["Take with meals"], commonSideEffects: ["Nausea", "Diarrhoea", "Headache"], storageInstructions: "Store below 30°C.", description: "Generic vildagliptin + metformin combo.", isScheduleH: true))

        db.append(DrugEntry(id: "linagliptin-met", brandName: "Linares-M", genericName: "Linagliptin + Metformin", saltComposition: "Linagliptin 2.5mg + Metformin 500mg", category: .antidiabetic, manufacturer: "USV", commonDosages: ["2.5/500mg", "2.5/1000mg"], typicalDoseForm: "tablet", priceRange: "₹250-400", genericAlternatives: [GenericAlternative(brandName: "Trajenta Met", manufacturer: "Boehringer", priceRange: "₹350-550")], foodInteractions: ["Take with meals"], commonSideEffects: ["Nausea", "Diarrhoea", "Nasopharyngitis"], storageInstructions: "Store below 30°C.", description: "Generic linagliptin + metformin.", isScheduleH: true))

        db.append(DrugEntry(id: "dapagliflozin-saxagliptin", brandName: "Qtern", genericName: "Dapagliflozin + Saxagliptin", saltComposition: "Dapagliflozin 10mg + Saxagliptin 5mg", category: .antidiabetic, manufacturer: "AstraZeneca", commonDosages: ["10/5mg"], typicalDoseForm: "tablet", priceRange: "₹400-650", genericAlternatives: [], foodInteractions: ["Can be taken with or without food"], commonSideEffects: ["UTI", "Genital infections", "Nasopharyngitis"], storageInstructions: "Store below 30°C.", description: "SGLT2 + DPP-4 inhibitor for Type 2 diabetes.", isScheduleH: true))

        db.append(DrugEntry(id: "insulin-glulisine", brandName: "Apidra", genericName: "Insulin Glulisine", saltComposition: "Insulin Glulisine 100 IU/ml", category: .antidiabetic, manufacturer: "Sanofi", commonDosages: ["100 IU/ml"], typicalDoseForm: "injection", priceRange: "₹700-1300", genericAlternatives: [], foodInteractions: ["Inject within 15 min before or within 20 min after starting meal"], commonSideEffects: ["Hypoglycemia", "Injection site reactions", "Weight gain"], storageInstructions: "Store in fridge. In-use pen at room temperature for 28 days.", description: "Rapid-acting insulin analogue.", isScheduleH: true))

        db.append(DrugEntry(id: "sitagliptin-dapagliflozin", brandName: "Steglujan", genericName: "Sitagliptin + Ertugliflozin", saltComposition: "Sitagliptin 100mg + Ertugliflozin 5mg", category: .antidiabetic, manufacturer: "MSD", commonDosages: ["100/5mg", "100/15mg"], typicalDoseForm: "tablet", priceRange: "₹500-800", genericAlternatives: [], foodInteractions: ["Can be taken with or without food"], commonSideEffects: ["UTI", "Genital infections", "Headache"], storageInstructions: "Store below 30°C.", description: "DPP-4 + SGLT2 inhibitor combination for Type 2 diabetes.", isScheduleH: true))

        // ── BP ADDITIONAL FINAL ──

        db.append(DrugEntry(id: "amlodipine-benazepril", brandName: "Amlobenz", genericName: "Amlodipine + Benazepril", saltComposition: "Amlodipine 5mg + Benazepril 10mg", category: .antihypertensive, manufacturer: "Various", commonDosages: ["5/10mg", "5/20mg"], typicalDoseForm: "capsule", priceRange: "₹60-130", genericAlternatives: [], foodInteractions: ["Can be taken with or without food"], commonSideEffects: ["Cough", "Ankle swelling", "Dizziness"], storageInstructions: "Store below 30°C.", description: "CCB + ACE inhibitor for hypertension.", isScheduleH: true))

        db.append(DrugEntry(id: "indapamide", brandName: "Lorvas", genericName: "Indapamide", saltComposition: "Indapamide 1.5mg SR", category: .antihypertensive, manufacturer: "Torrent", commonDosages: ["1.5mg SR", "2.5mg"], typicalDoseForm: "tablet", priceRange: "₹20-50", genericAlternatives: [], foodInteractions: ["Take in the morning", "Can be taken with or without food"], commonSideEffects: ["Dizziness", "Headache", "Low potassium", "Nausea"], storageInstructions: "Store below 30°C.", description: "Thiazide-like diuretic for hypertension. Sustained-release form.", isScheduleH: true))

        db.append(DrugEntry(id: "perindopril-amlodipine", brandName: "Coversyl AM", genericName: "Perindopril + Amlodipine", saltComposition: "Perindopril 4mg + Amlodipine 5mg", category: .antihypertensive, manufacturer: "Serdia (Servier)", commonDosages: ["4/5mg", "8/5mg", "4/10mg", "8/10mg"], typicalDoseForm: "tablet", priceRange: "₹100-220", genericAlternatives: [], foodInteractions: ["Take in the morning", "Can be taken with or without food"], commonSideEffects: ["Cough", "Ankle swelling", "Dizziness", "Headache"], storageInstructions: "Store below 30°C.", description: "ACE inhibitor + CCB (ASCOT trial combo) for hypertension.", isScheduleH: true))

        db.append(DrugEntry(id: "perindopril-indapamide", brandName: "Coversyl Plus", genericName: "Perindopril + Indapamide", saltComposition: "Perindopril 4mg + Indapamide 1.25mg", category: .antihypertensive, manufacturer: "Serdia (Servier)", commonDosages: ["4/1.25mg", "8/2.5mg"], typicalDoseForm: "tablet", priceRange: "₹80-180", genericAlternatives: [], foodInteractions: ["Take in the morning"], commonSideEffects: ["Cough", "Dizziness", "Low potassium", "Headache"], storageInstructions: "Store below 30°C.", description: "ACE inhibitor + diuretic (ADVANCE trial combo) for hypertension.", isScheduleH: true))

        db.append(DrugEntry(id: "azilsartan", brandName: "Zilarbi", genericName: "Azilsartan", saltComposition: "Azilsartan Medoxomil 40mg", category: .antihypertensive, manufacturer: "Micro Labs", commonDosages: ["20mg", "40mg", "80mg"], typicalDoseForm: "tablet", priceRange: "₹80-180", genericAlternatives: [], foodInteractions: ["Can be taken with or without food"], commonSideEffects: ["Dizziness", "Diarrhoea", "Fatigue"], storageInstructions: "Store below 30°C.", description: "Newest ARB with strongest 24-hour BP reduction.", isScheduleH: true))

        db.append(DrugEntry(id: "telmisartan-nebivolol", brandName: "Telma-NB", genericName: "Telmisartan + Nebivolol", saltComposition: "Telmisartan 40mg + Nebivolol 5mg", category: .antihypertensive, manufacturer: "Glenmark", commonDosages: ["40/5mg"], typicalDoseForm: "tablet", priceRange: "₹90-180", genericAlternatives: [], foodInteractions: ["Can be taken with or without food"], commonSideEffects: ["Dizziness", "Fatigue", "Bradycardia", "Headache"], storageInstructions: "Store below 30°C.", description: "ARB + third-gen beta-blocker for hypertension.", isScheduleH: true))

        // ── CHOLESTEROL ADDITIONAL ──

        db.append(DrugEntry(id: "pitavastatin", brandName: "Pivasta", genericName: "Pitavastatin", saltComposition: "Pitavastatin 2mg", category: .cholesterol, manufacturer: "Sun Pharma", commonDosages: ["1mg", "2mg", "4mg"], typicalDoseForm: "tablet", priceRange: "₹80-180", genericAlternatives: [GenericAlternative(brandName: "Livazo", manufacturer: "Kowa", priceRange: "₹100-220")], foodInteractions: ["Can be taken with or without food", "No grapefruit interaction"], commonSideEffects: ["Muscle pain", "Headache", "Constipation", "Back pain"], storageInstructions: "Store below 30°C.", description: "Statin with fewest drug interactions. Does not affect glucose metabolism.", isScheduleH: true))

        db.append(DrugEntry(id: "simvastatin", brandName: "Zocor", genericName: "Simvastatin", saltComposition: "Simvastatin 20mg", category: .cholesterol, manufacturer: "MSD", commonDosages: ["5mg", "10mg", "20mg", "40mg"], typicalDoseForm: "tablet", priceRange: "₹40-100", genericAlternatives: [GenericAlternative(brandName: "Simvas", manufacturer: "Sun Pharma", priceRange: "₹25-65")], foodInteractions: ["Take at bedtime", "Avoid grapefruit juice"], commonSideEffects: ["Muscle pain", "Headache", "Constipation", "Abdominal pain"], storageInstructions: "Store below 30°C.", description: "Older statin for hypercholesterolemia. Take in the evening.", isScheduleH: true))

        db.append(DrugEntry(id: "rosuvastatin-asp-clop-2", brandName: "Rosufit-ACG", genericName: "Rosuvastatin + Aspirin + Clopidogrel", saltComposition: "Rosuvastatin 10mg + Aspirin 75mg + Clopidogrel 75mg", category: .cardiovascular, manufacturer: "Mankind", commonDosages: ["10/75/75mg"], typicalDoseForm: "capsule", priceRange: "₹80-160", genericAlternatives: [], foodInteractions: ["Take with food"], commonSideEffects: ["Bleeding", "Muscle pain", "Stomach pain"], storageInstructions: "Store below 30°C.", description: "Generic triple cardiac combo.", isScheduleH: true))

        // ── ANTI-INFECTIVE ADDITIONAL ──

        db.append(DrugEntry(id: "nitazoxanide", brandName: "Nizonide", genericName: "Nitazoxanide", saltComposition: "Nitazoxanide 500mg", category: .antiInfective, manufacturer: "Lupin", commonDosages: ["200mg", "500mg"], typicalDoseForm: "tablet", priceRange: "₹30-70", genericAlternatives: [GenericAlternative(brandName: "Nizonide", manufacturer: "Lupin", priceRange: "₹25-60")], foodInteractions: ["Take with food"], commonSideEffects: ["Nausea", "Abdominal pain", "Yellow-green urine", "Headache"], storageInstructions: "Store below 30°C.", description: "Antiparasitic and antiviral for giardiasis, cryptosporidiosis, and rotavirus diarrhoea.", isScheduleH: true))

        db.append(DrugEntry(id: "dapsone", brandName: "Dapsone", genericName: "Dapsone", saltComposition: "Dapsone 100mg", category: .antiInfective, manufacturer: "Various", commonDosages: ["50mg", "100mg"], typicalDoseForm: "tablet", priceRange: "₹5-15", genericAlternatives: [], foodInteractions: ["Can be taken with or without food"], commonSideEffects: ["Haemolytic anaemia (G6PD)", "Methemoglobinemia", "Rash", "Nausea"], storageInstructions: "Store below 30°C.", description: "Sulfone antibiotic for leprosy, dermatitis herpetiformis, and PCP prophylaxis.", isScheduleH: true))

        db.append(DrugEntry(id: "rifampicin", brandName: "R-Cin", genericName: "Rifampicin", saltComposition: "Rifampicin 450mg", category: .antiInfective, manufacturer: "Lupin", commonDosages: ["150mg", "300mg", "450mg", "600mg"], typicalDoseForm: "capsule", priceRange: "₹10-30", genericAlternatives: [], foodInteractions: ["Take on empty stomach", "Orange discoloration of urine/tears"], commonSideEffects: ["Hepatotoxicity", "Orange body fluids", "Nausea", "Thrombocytopenia"], storageInstructions: "Store below 25°C. Protect from light.", description: "Antimycobacterial for tuberculosis and leprosy. Many drug interactions.", isScheduleH: true))

        db.append(DrugEntry(id: "isoniazid", brandName: "INH", genericName: "Isoniazid", saltComposition: "Isoniazid 300mg", category: .antiInfective, manufacturer: "Various", commonDosages: ["100mg", "300mg"], typicalDoseForm: "tablet", priceRange: "₹3-10", genericAlternatives: [], foodInteractions: ["Take on empty stomach", "Avoid alcohol", "Avoid tyramine-rich foods"], commonSideEffects: ["Hepatotoxicity", "Peripheral neuropathy", "Nausea", "Rash"], storageInstructions: "Store below 30°C.", description: "First-line anti-TB drug. Take with pyridoxine (B6) to prevent neuropathy.", isScheduleH: true))

        db.append(DrugEntry(id: "pyrazinamide", brandName: "PZA-Ciba", genericName: "Pyrazinamide", saltComposition: "Pyrazinamide 500mg", category: .antiInfective, manufacturer: "Various", commonDosages: ["500mg", "750mg"], typicalDoseForm: "tablet", priceRange: "₹5-15", genericAlternatives: [], foodInteractions: ["Can be taken with food"], commonSideEffects: ["Hepatotoxicity", "Hyperuricemia", "Joint pain", "Nausea", "Rash"], storageInstructions: "Store below 30°C.", description: "Anti-TB drug used in initial intensive phase. Raises uric acid.", isScheduleH: true))

        db.append(DrugEntry(id: "ethambutol", brandName: "Myambutol", genericName: "Ethambutol", saltComposition: "Ethambutol 800mg", category: .antiInfective, manufacturer: "Various", commonDosages: ["400mg", "600mg", "800mg"], typicalDoseForm: "tablet", priceRange: "₹5-15", genericAlternatives: [], foodInteractions: ["Can be taken with food"], commonSideEffects: ["Optic neuritis (visual changes)", "Hyperuricemia", "Nausea", "Rash"], storageInstructions: "Store below 30°C.", description: "Anti-TB drug. Monitor vision regularly — optic neuritis is dose-related.", isScheduleH: true))

        db.append(DrugEntry(id: "akt-4", brandName: "AKT-4", genericName: "RHZE (Rifampicin+Isoniazid+Pyrazinamide+Ethambutol)", saltComposition: "Rifampicin 150mg + Isoniazid 75mg + Pyrazinamide 400mg + Ethambutol 275mg", category: .antiInfective, manufacturer: "Lupin", commonDosages: ["Standard FDC"], typicalDoseForm: "tablet", priceRange: "₹15-40", genericAlternatives: [], foodInteractions: ["Take on empty stomach, 30 min before breakfast"], commonSideEffects: ["Hepatotoxicity", "Orange urine", "Nausea", "Joint pain", "Visual changes"], storageInstructions: "Store below 25°C. Protect from light.", description: "4-drug FDC for TB intensive phase (first 2 months). DOTS-compatible.", isScheduleH: true))

        // ── MISCELLANEOUS FINAL ──

        db.append(DrugEntry(id: "trihexyphenidyl", brandName: "Pacitane", genericName: "Trihexyphenidyl", saltComposition: "Trihexyphenidyl 2mg", category: .other, manufacturer: "Wyeth", commonDosages: ["2mg", "5mg"], typicalDoseForm: "tablet", priceRange: "₹8-20", genericAlternatives: [], foodInteractions: ["Take after food to reduce GI upset"], commonSideEffects: ["Dry mouth", "Blurred vision", "Constipation", "Urinary retention", "Confusion"], storageInstructions: "Store below 30°C.", description: "Anticholinergic for Parkinson's disease and drug-induced extrapyramidal symptoms.", isScheduleH: true))

        db.append(DrugEntry(id: "levodopa-carbidopa", brandName: "Syndopa", genericName: "Levodopa + Carbidopa", saltComposition: "Levodopa 100mg + Carbidopa 25mg", category: .other, manufacturer: "Sun Pharma", commonDosages: ["110mg (100/10)", "275mg (250/25)", "125mg (100/25)"], typicalDoseForm: "tablet", priceRange: "₹20-50", genericAlternatives: [GenericAlternative(brandName: "Sinemet", manufacturer: "MSD", priceRange: "₹40-100")], foodInteractions: ["Take 30 min before meals", "High protein meals may reduce absorption"], commonSideEffects: ["Nausea", "Dyskinesia", "Orthostatic hypotension", "Hallucinations", "Dark urine"], storageInstructions: "Store below 30°C. Protect from light.", description: "Gold standard treatment for Parkinson's disease.", isScheduleH: true))

        db.append(DrugEntry(id: "ropinirole", brandName: "Ropark", genericName: "Ropinirole", saltComposition: "Ropinirole 0.25mg", category: .other, manufacturer: "Sun Pharma", commonDosages: ["0.25mg", "0.5mg", "1mg", "2mg"], typicalDoseForm: "tablet", priceRange: "₹30-80", genericAlternatives: [GenericAlternative(brandName: "Requip", manufacturer: "GSK", priceRange: "₹60-150")], foodInteractions: ["Can be taken with or without food"], commonSideEffects: ["Nausea", "Drowsiness", "Dizziness", "Hallucinations", "Impulse control disorders"], storageInstructions: "Store below 30°C.", description: "Dopamine agonist for early Parkinson's disease and restless leg syndrome.", isScheduleH: true))

        db.append(DrugEntry(id: "donepezil", brandName: "Aricept", genericName: "Donepezil", saltComposition: "Donepezil 5mg", category: .other, manufacturer: "Eisai", commonDosages: ["5mg", "10mg", "23mg"], typicalDoseForm: "tablet", priceRange: "₹80-200", genericAlternatives: [GenericAlternative(brandName: "Donep", manufacturer: "Sun Pharma", priceRange: "₹50-120")], foodInteractions: ["Can be taken with or without food"], commonSideEffects: ["Nausea", "Diarrhoea", "Insomnia", "Muscle cramps", "Fatigue"], storageInstructions: "Store below 30°C.", description: "Cholinesterase inhibitor for mild-to-moderate Alzheimer's disease.", isScheduleH: true))

        db.append(DrugEntry(id: "memantine", brandName: "Admenta", genericName: "Memantine", saltComposition: "Memantine 10mg", category: .other, manufacturer: "Sun Pharma", commonDosages: ["5mg", "10mg", "20mg"], typicalDoseForm: "tablet", priceRange: "₹60-150", genericAlternatives: [GenericAlternative(brandName: "Namenda", manufacturer: "Various", priceRange: "₹100-250")], foodInteractions: ["Can be taken with or without food"], commonSideEffects: ["Dizziness", "Headache", "Constipation", "Confusion"], storageInstructions: "Store below 30°C.", description: "NMDA antagonist for moderate-to-severe Alzheimer's disease.", isScheduleH: true))

        db.append(DrugEntry(id: "baclofen", brandName: "Liofen", genericName: "Baclofen", saltComposition: "Baclofen 10mg", category: .other, manufacturer: "Sun Pharma", commonDosages: ["5mg", "10mg", "20mg"], typicalDoseForm: "tablet", priceRange: "₹10-30", genericAlternatives: [GenericAlternative(brandName: "Lioresal", manufacturer: "Novartis", priceRange: "₹20-50")], foodInteractions: ["Take with food to reduce stomach upset"], commonSideEffects: ["Drowsiness", "Dizziness", "Weakness", "Nausea", "Confusion"], storageInstructions: "Store below 30°C.", description: "GABA-B agonist muscle relaxant for spasticity in MS and spinal cord injury.", isScheduleH: true))

        db.append(DrugEntry(id: "diethylcarbamazine", brandName: "Banocide Forte", genericName: "Diethylcarbamazine (DEC)", saltComposition: "Diethylcarbamazine 100mg", category: .antiInfective, manufacturer: "GSK", commonDosages: ["50mg", "100mg"], typicalDoseForm: "tablet", priceRange: "₹5-15", genericAlternatives: [], foodInteractions: ["Take after meals"], commonSideEffects: ["Fever", "Headache", "Nausea", "Joint pain", "Mazzotti reaction"], storageInstructions: "Store below 30°C.", description: "Antifilarial for lymphatic filariasis and tropical eosinophilia.", isScheduleH: true))

        db.append(DrugEntry(id: "chloroquine", brandName: "Resochin", genericName: "Chloroquine", saltComposition: "Chloroquine Phosphate 250mg", category: .antiInfective, manufacturer: "Bayer", commonDosages: ["250mg", "500mg"], typicalDoseForm: "tablet", priceRange: "₹5-15", genericAlternatives: [GenericAlternative(brandName: "Lariago", manufacturer: "Ipca", priceRange: "₹4-12")], foodInteractions: ["Take with food to reduce stomach upset"], commonSideEffects: ["Nausea", "Headache", "Visual disturbances", "Retinal toxicity (long-term)"], storageInstructions: "Store below 30°C.", description: "Antimalarial for P. vivax malaria and RA/SLE.", isScheduleH: true))

        db.append(DrugEntry(id: "artemether-lumefantrine", brandName: "Coartem", genericName: "Artemether + Lumefantrine", saltComposition: "Artemether 20mg + Lumefantrine 120mg", category: .antiInfective, manufacturer: "Novartis", commonDosages: ["20/120mg"], typicalDoseForm: "tablet", priceRange: "₹30-80", genericAlternatives: [GenericAlternative(brandName: "Falcigo", manufacturer: "Various", priceRange: "₹20-50")], foodInteractions: ["Take with fatty food for better absorption"], commonSideEffects: ["Headache", "Dizziness", "Nausea", "Joint pain", "Palpitations"], storageInstructions: "Store below 30°C.", description: "ACT (Artemisinin-based combination therapy) for P. falciparum malaria.", isScheduleH: true))

        db.append(DrugEntry(id: "primaquine", brandName: "Primaquine", genericName: "Primaquine", saltComposition: "Primaquine 15mg", category: .antiInfective, manufacturer: "Various", commonDosages: ["7.5mg", "15mg"], typicalDoseForm: "tablet", priceRange: "₹3-10", genericAlternatives: [], foodInteractions: ["Take with food"], commonSideEffects: ["Nausea", "Stomach cramps", "Haemolytic anaemia (G6PD deficiency)"], storageInstructions: "Store below 30°C. Protect from light.", description: "Antimalarial for radical cure of P. vivax (kills liver hypnozoites). Check G6PD first.", isScheduleH: true))

        db.append(DrugEntry(id: "artesunate", brandName: "Artesunate", genericName: "Artesunate", saltComposition: "Artesunate 60mg", category: .antiInfective, manufacturer: "Various", commonDosages: ["50mg", "60mg"], typicalDoseForm: "injection", priceRange: "₹20-60", genericAlternatives: [], foodInteractions: ["Injectable — no food interactions"], commonSideEffects: ["Delayed haemolysis", "Dizziness", "Nausea", "Reticulocyte reduction"], storageInstructions: "Store below 30°C.", description: "Injectable artesunate for severe malaria. WHO first-line for cerebral malaria.", isScheduleH: true))

        db.append(DrugEntry(id: "acotiamide", brandName: "Acotrust", genericName: "Acotiamide", saltComposition: "Acotiamide 100mg", category: .antiAcid, manufacturer: "Sun Pharma", commonDosages: ["100mg"], typicalDoseForm: "tablet", priceRange: "₹80-160", genericAlternatives: [], foodInteractions: ["Take before meals"], commonSideEffects: ["Diarrhoea", "Constipation", "Nausea", "Headache"], storageInstructions: "Store below 30°C.", description: "Prokinetic for functional dyspepsia. Enhances acetylcholine release.", isScheduleH: true))

        db.append(DrugEntry(id: "vonoprazan", brandName: "Vocinta", genericName: "Vonoprazan", saltComposition: "Vonoprazan 20mg", category: .antiAcid, manufacturer: "Sun Pharma", commonDosages: ["10mg", "20mg"], typicalDoseForm: "tablet", priceRange: "₹100-200", genericAlternatives: [], foodInteractions: ["Can be taken with or without food"], commonSideEffects: ["Diarrhoea", "Nausea", "Headache", "Abdominal pain"], storageInstructions: "Store below 30°C.", description: "Potassium-competitive acid blocker (P-CAB). Faster, stronger acid suppression than PPIs.", isScheduleH: true))

        db.append(DrugEntry(id: "dydrogesterone", brandName: "Duphaston", genericName: "Dydrogesterone", saltComposition: "Dydrogesterone 10mg", category: .other, manufacturer: "Abbott", commonDosages: ["10mg"], typicalDoseForm: "tablet", priceRange: "₹150-300", genericAlternatives: [GenericAlternative(brandName: "Duvadilan Retard", manufacturer: "Solvay", priceRange: "₹100-200")], foodInteractions: ["Can be taken with or without food"], commonSideEffects: ["Headache", "Nausea", "Breast tenderness", "Irregular bleeding"], storageInstructions: "Store below 30°C.", description: "Progestogen for threatened miscarriage, endometriosis, and menstrual disorders.", isScheduleH: true))

        db.append(DrugEntry(id: "norethisterone", brandName: "Regestrone", genericName: "Norethisterone", saltComposition: "Norethisterone 5mg", category: .other, manufacturer: "Zydus", commonDosages: ["5mg"], typicalDoseForm: "tablet", priceRange: "₹20-50", genericAlternatives: [GenericAlternative(brandName: "Primolut-N", manufacturer: "Bayer", priceRange: "₹30-70")], foodInteractions: ["Can be taken with or without food"], commonSideEffects: ["Nausea", "Headache", "Breast tenderness", "Breakthrough bleeding"], storageInstructions: "Store below 30°C.", description: "Progestogen for delaying periods, heavy bleeding, and endometriosis.", isScheduleH: true))

        db.append(DrugEntry(id: "mifepristone", brandName: "Mifeprin", genericName: "Mifepristone", saltComposition: "Mifepristone 200mg", category: .other, manufacturer: "Cipla", commonDosages: ["200mg"], typicalDoseForm: "tablet", priceRange: "₹80-200", genericAlternatives: [GenericAlternative(brandName: "Mifegest", manufacturer: "Zydus", priceRange: "₹60-150")], foodInteractions: ["Can be taken with or without food"], commonSideEffects: ["Nausea", "Vomiting", "Diarrhoea", "Abdominal cramps", "Heavy bleeding"], storageInstructions: "Store below 25°C.", description: "Antiprogestogen for medical termination of pregnancy (with misoprostol). Rx only.", isScheduleH: true))

        db.append(DrugEntry(id: "letrozole", brandName: "Letroz", genericName: "Letrozole", saltComposition: "Letrozole 2.5mg", category: .other, manufacturer: "Sun Pharma", commonDosages: ["2.5mg"], typicalDoseForm: "tablet", priceRange: "₹50-120", genericAlternatives: [GenericAlternative(brandName: "Femara", manufacturer: "Novartis", priceRange: "₹100-250")], foodInteractions: ["Can be taken with or without food"], commonSideEffects: ["Hot flashes", "Joint pain", "Fatigue", "Nausea"], storageInstructions: "Store below 30°C.", description: "Aromatase inhibitor for breast cancer and ovulation induction.", isScheduleH: true))

        db.append(DrugEntry(id: "clomiphene", brandName: "Siphene", genericName: "Clomiphene Citrate", saltComposition: "Clomiphene 50mg", category: .other, manufacturer: "Cipla", commonDosages: ["25mg", "50mg", "100mg"], typicalDoseForm: "tablet", priceRange: "₹30-80", genericAlternatives: [GenericAlternative(brandName: "Fertomid", manufacturer: "Cipla", priceRange: "₹25-60")], foodInteractions: ["Can be taken with or without food"], commonSideEffects: ["Hot flashes", "Bloating", "Headache", "Visual disturbances", "Ovarian hyperstimulation"], storageInstructions: "Store below 30°C.", description: "Ovulation inducer for infertility treatment (PCOS, anovulation).", isScheduleH: true))

        db.append(DrugEntry(id: "progesterone", brandName: "Susten", genericName: "Progesterone", saltComposition: "Micronised Progesterone 200mg", category: .other, manufacturer: "Sun Pharma", commonDosages: ["100mg", "200mg", "400mg"], typicalDoseForm: "capsule/vaginal insert", priceRange: "₹100-250", genericAlternatives: [GenericAlternative(brandName: "Gestone", manufacturer: "Various", priceRange: "₹80-200")], foodInteractions: ["Take at bedtime if oral"], commonSideEffects: ["Drowsiness", "Bloating", "Breast tenderness", "Dizziness"], storageInstructions: "Store below 25°C.", description: "Natural progesterone for luteal phase support and threatened abortion.", isScheduleH: true))

        db.append(DrugEntry(id: "ethinyl-estradiol-levonorgestrel", brandName: "Ovral-L", genericName: "Ethinyl Estradiol + Levonorgestrel", saltComposition: "Ethinyl Estradiol 0.03mg + Levonorgestrel 0.15mg", category: .other, manufacturer: "Pfizer", commonDosages: ["Standard"], typicalDoseForm: "tablet", priceRange: "₹30-80", genericAlternatives: [GenericAlternative(brandName: "Mala-D", manufacturer: "HLL", priceRange: "₹5-15")], foodInteractions: ["Take at same time daily"], commonSideEffects: ["Nausea", "Breast tenderness", "Headache", "Weight gain", "Mood changes"], storageInstructions: "Store below 30°C.", description: "Combined oral contraceptive pill (OCP). 21-day cycle.", isScheduleH: true))

        db.append(DrugEntry(id: "levonorgestrel-emergency", brandName: "iPill", genericName: "Levonorgestrel", saltComposition: "Levonorgestrel 1.5mg", category: .other, manufacturer: "Cipla", commonDosages: ["1.5mg"], typicalDoseForm: "tablet", priceRange: "₹80-150", genericAlternatives: [GenericAlternative(brandName: "Unwanted-72", manufacturer: "Mankind", priceRange: "₹60-100")], foodInteractions: ["Can be taken with or without food"], commonSideEffects: ["Nausea", "Vomiting", "Irregular bleeding", "Headache", "Fatigue"], storageInstructions: "Store below 30°C.", description: "Emergency contraception (morning-after pill). Take within 72 hours. OTC.", isScheduleH: false))

        db.append(DrugEntry(id: "medroxyprogesterone", brandName: "Meprate", genericName: "Medroxyprogesterone", saltComposition: "Medroxyprogesterone Acetate 10mg", category: .other, manufacturer: "Sun Pharma", commonDosages: ["5mg", "10mg"], typicalDoseForm: "tablet", priceRange: "₹20-50", genericAlternatives: [GenericAlternative(brandName: "Provera", manufacturer: "Pfizer", priceRange: "₹30-70")], foodInteractions: ["Can be taken with or without food"], commonSideEffects: ["Irregular bleeding", "Weight gain", "Mood changes", "Headache"], storageInstructions: "Store below 30°C.", description: "Progestogen for abnormal uterine bleeding, amenorrhea, and endometriosis.", isScheduleH: true))

        db.append(DrugEntry(id: "miglitol", brandName: "Mignar", genericName: "Miglitol", saltComposition: "Miglitol 25mg", category: .antidiabetic, manufacturer: "Glenmark", commonDosages: ["25mg", "50mg", "100mg"], typicalDoseForm: "tablet", priceRange: "₹40-90", genericAlternatives: [], foodInteractions: ["Take with the first bite of each main meal"], commonSideEffects: ["Flatulence", "Diarrhoea", "Abdominal pain"], storageInstructions: "Store below 30°C.", description: "Alpha-glucosidase inhibitor for post-prandial glucose control. Alternative to voglibose.", isScheduleH: true))

        db.append(DrugEntry(id: "clobazam", brandName: "Frisium", genericName: "Clobazam", saltComposition: "Clobazam 10mg", category: .other, manufacturer: "Sanofi", commonDosages: ["5mg", "10mg", "20mg"], typicalDoseForm: "tablet", priceRange: "₹30-70", genericAlternatives: [GenericAlternative(brandName: "Cloba", manufacturer: "Various", priceRange: "₹20-50")], foodInteractions: ["Can be taken with or without food", "Avoid alcohol"], commonSideEffects: ["Drowsiness", "Dizziness", "Fatigue", "Irritability", "Dependence"], storageInstructions: "Store below 30°C.", description: "1,5-benzodiazepine for epilepsy adjunct and anxiety. Less sedating than clonazepam.", isScheduleH: true))

        db.append(DrugEntry(id: "brivaracetam", brandName: "Briviact", genericName: "Brivaracetam", saltComposition: "Brivaracetam 50mg", category: .other, manufacturer: "UCB", commonDosages: ["25mg", "50mg", "75mg", "100mg"], typicalDoseForm: "tablet", priceRange: "₹100-250", genericAlternatives: [], foodInteractions: ["Can be taken with or without food"], commonSideEffects: ["Drowsiness", "Dizziness", "Fatigue", "Nausea"], storageInstructions: "Store below 30°C.", description: "Newer anticonvulsant related to levetiracetam. For partial onset seizures.", isScheduleH: true))

        db.append(DrugEntry(id: "lacosamide", brandName: "Lacoset", genericName: "Lacosamide", saltComposition: "Lacosamide 100mg", category: .other, manufacturer: "Sun Pharma", commonDosages: ["50mg", "100mg", "150mg", "200mg"], typicalDoseForm: "tablet", priceRange: "₹80-200", genericAlternatives: [GenericAlternative(brandName: "Vimpat", manufacturer: "UCB", priceRange: "₹150-350")], foodInteractions: ["Can be taken with or without food"], commonSideEffects: ["Dizziness", "Headache", "Nausea", "Diplopia", "PR prolongation"], storageInstructions: "Store below 30°C.", description: "Sodium channel blocker anticonvulsant for partial seizures.", isScheduleH: true))

        db.append(DrugEntry(id: "pantoprazole-aceclofenac", brandName: "Pan-Aceclofenac", genericName: "Pantoprazole + Aceclofenac", saltComposition: "Pantoprazole 40mg + Aceclofenac 200mg SR", category: .analgesic, manufacturer: "Various", commonDosages: ["40/200mg"], typicalDoseForm: "tablet", priceRange: "₹50-100", genericAlternatives: [], foodInteractions: ["Take with food"], commonSideEffects: ["Stomach pain", "Headache", "Nausea"], storageInstructions: "Store below 30°C.", description: "PPI-protected NSAID for pain with gastroprotection.", isScheduleH: true))

        db.append(DrugEntry(id: "olmesartan-cilnidipine", brandName: "Olmy-CN", genericName: "Olmesartan + Cilnidipine", saltComposition: "Olmesartan 20mg + Cilnidipine 10mg", category: .antihypertensive, manufacturer: "Micro Labs", commonDosages: ["20/10mg", "40/10mg"], typicalDoseForm: "tablet", priceRange: "₹100-200", genericAlternatives: [], foodInteractions: ["Take after food"], commonSideEffects: ["Dizziness", "Headache", "Flushing"], storageInstructions: "Store below 30°C.", description: "ARB + N-type CCB for hypertension with less edema.", isScheduleH: true))

        db.append(DrugEntry(id: "telmisartan-indapamide", brandName: "Telma-ID", genericName: "Telmisartan + Indapamide", saltComposition: "Telmisartan 40mg + Indapamide 1.5mg", category: .antihypertensive, manufacturer: "Glenmark", commonDosages: ["40/1.5mg", "80/1.5mg"], typicalDoseForm: "tablet", priceRange: "₹80-160", genericAlternatives: [], foodInteractions: ["Can be taken with or without food"], commonSideEffects: ["Dizziness", "Low potassium", "Fatigue"], storageInstructions: "Store below 30°C.", description: "ARB + thiazide-like diuretic for hypertension.", isScheduleH: true))

        db.append(DrugEntry(id: "candesartan", brandName: "Candesar", genericName: "Candesartan", saltComposition: "Candesartan 8mg", category: .antihypertensive, manufacturer: "Ranbaxy", commonDosages: ["4mg", "8mg", "16mg", "32mg"], typicalDoseForm: "tablet", priceRange: "₹60-140", genericAlternatives: [], foodInteractions: ["Can be taken with or without food"], commonSideEffects: ["Dizziness", "Back pain", "Upper respiratory infection"], storageInstructions: "Store below 30°C.", description: "ARB for hypertension and heart failure.", isScheduleH: true))

        db.append(DrugEntry(id: "irbesartan", brandName: "Irovel", genericName: "Irbesartan", saltComposition: "Irbesartan 150mg", category: .antihypertensive, manufacturer: "Sun Pharma", commonDosages: ["75mg", "150mg", "300mg"], typicalDoseForm: "tablet", priceRange: "₹50-130", genericAlternatives: [], foodInteractions: ["Can be taken with or without food"], commonSideEffects: ["Dizziness", "Fatigue", "Diarrhoea", "Musculoskeletal pain"], storageInstructions: "Store below 30°C.", description: "ARB for hypertension and diabetic nephropathy.", isScheduleH: true))

        db.append(DrugEntry(id: "tadalafil-5", brandName: "Megalis 5", genericName: "Tadalafil", saltComposition: "Tadalafil 5mg", category: .other, manufacturer: "Macleods", commonDosages: ["5mg"], typicalDoseForm: "tablet", priceRange: "₹50-120", genericAlternatives: [GenericAlternative(brandName: "Tadacip 5", manufacturer: "Cipla", priceRange: "₹40-100")], foodInteractions: ["Can be taken with or without food", "Avoid grapefruit juice"], commonSideEffects: ["Headache", "Back pain", "Nasal congestion", "Flushing"], storageInstructions: "Store below 30°C.", description: "Daily low-dose tadalafil for ED and BPH (LUTS).", isScheduleH: true))

        db.append(DrugEntry(id: "montelukast-acebrophylline", brandName: "Montair-AB", genericName: "Montelukast + Acebrophylline", saltComposition: "Montelukast 10mg + Acebrophylline 200mg SR", category: .respiratory, manufacturer: "Cipla", commonDosages: ["10/200mg"], typicalDoseForm: "tablet", priceRange: "₹100-200", genericAlternatives: [], foodInteractions: ["Take in the evening"], commonSideEffects: ["Headache", "Nausea", "Palpitations"], storageInstructions: "Store below 30°C.", description: "LTRA + mucoregulator for asthma with productive cough.", isScheduleH: true))

        db.append(DrugEntry(id: "levosalbutamol", brandName: "Levolin", genericName: "Levosalbutamol", saltComposition: "Levosalbutamol 50mcg/puff", category: .respiratory, manufacturer: "Cipla", commonDosages: ["50mcg"], typicalDoseForm: "inhaler", priceRange: "₹80-150", genericAlternatives: [], foodInteractions: ["No food interactions"], commonSideEffects: ["Tremor (less than salbutamol)", "Palpitations", "Headache"], storageInstructions: "Store below 30°C.", description: "R-isomer of salbutamol. More potent with fewer cardiac side effects.", isScheduleH: true))

        db.append(DrugEntry(id: "formoterol-inhaler", brandName: "Formoterol Rotacap", genericName: "Formoterol", saltComposition: "Formoterol 12mcg", category: .respiratory, manufacturer: "Cipla", commonDosages: ["6mcg", "12mcg"], typicalDoseForm: "inhaler", priceRange: "₹100-200", genericAlternatives: [], foodInteractions: ["No food interactions"], commonSideEffects: ["Tremor", "Palpitations", "Headache", "Muscle cramps"], storageInstructions: "Store below 30°C. Protect from moisture.", description: "Long-acting bronchodilator (LABA) for asthma and COPD maintenance.", isScheduleH: true))

        db.append(DrugEntry(id: "aclidinium-formoterol", brandName: "Duaklir", genericName: "Aclidinium + Formoterol", saltComposition: "Aclidinium 400mcg + Formoterol 12mcg", category: .respiratory, manufacturer: "AstraZeneca", commonDosages: ["400/12mcg"], typicalDoseForm: "inhaler", priceRange: "₹400-800", genericAlternatives: [], foodInteractions: ["No food interactions"], commonSideEffects: ["Headache", "Cough", "Nasopharyngitis", "Diarrhoea"], storageInstructions: "Store below 30°C.", description: "LAMA/LABA dual bronchodilator for COPD maintenance.", isScheduleH: true))

        db.append(DrugEntry(id: "glycopyrronium", brandName: "Seebri", genericName: "Glycopyrronium", saltComposition: "Glycopyrronium 50mcg", category: .respiratory, manufacturer: "Novartis", commonDosages: ["50mcg"], typicalDoseForm: "inhaler", priceRange: "₹300-600", genericAlternatives: [GenericAlternative(brandName: "Glyco", manufacturer: "Cipla", priceRange: "₹200-400")], foodInteractions: ["No food interactions"], commonSideEffects: ["Dry mouth", "UTI", "Nasopharyngitis"], storageInstructions: "Store below 30°C. Protect from moisture.", description: "Long-acting muscarinic antagonist (LAMA) for COPD.", isScheduleH: true))

        db.append(DrugEntry(id: "indacaterol-glyco", brandName: "Ultibro", genericName: "Indacaterol + Glycopyrronium", saltComposition: "Indacaterol 110mcg + Glycopyrronium 50mcg", category: .respiratory, manufacturer: "Novartis", commonDosages: ["110/50mcg"], typicalDoseForm: "inhaler", priceRange: "₹500-1000", genericAlternatives: [], foodInteractions: ["No food interactions"], commonSideEffects: ["Cough", "Nasopharyngitis", "Headache", "UTI"], storageInstructions: "Store below 30°C. Protect from moisture.", description: "LABA/LAMA dual bronchodilator for COPD.", isScheduleH: true))

        db.append(DrugEntry(id: "fluticasone-umeclidinium-vilanterol", brandName: "Trelegy Ellipta", genericName: "Fluticasone + Umeclidinium + Vilanterol", saltComposition: "Fluticasone 100mcg + Umeclidinium 62.5mcg + Vilanterol 25mcg", category: .respiratory, manufacturer: "GSK", commonDosages: ["100/62.5/25mcg"], typicalDoseForm: "inhaler", priceRange: "₹800-1500", genericAlternatives: [], foodInteractions: ["Rinse mouth after use"], commonSideEffects: ["Oral thrush", "Headache", "Back pain", "Pneumonia", "UTI"], storageInstructions: "Store below 30°C.", description: "Once-daily triple therapy (ICS/LAMA/LABA) for COPD.", isScheduleH: true))

        db.append(DrugEntry(id: "ciclesonide", brandName: "Alvesco", genericName: "Ciclesonide", saltComposition: "Ciclesonide 160mcg", category: .respiratory, manufacturer: "Cipla", commonDosages: ["80mcg", "160mcg"], typicalDoseForm: "inhaler", priceRange: "₹250-500", genericAlternatives: [], foodInteractions: ["No food interactions", "No need to rinse mouth (activated in lungs)"], commonSideEffects: ["Headache", "Nasopharyngitis", "Oral thrush (minimal)"], storageInstructions: "Store below 30°C.", description: "Inhaled corticosteroid prodrug with minimal oral side effects. Once-daily.", isScheduleH: true))

        return db
    }
}
