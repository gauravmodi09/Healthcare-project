import SwiftUI

// MARK: - Clarification Models

struct SymptomClarification: Identifiable {
    let id = UUID()
    let symptomName: String
    let acknowledgment: String
    let questions: [ClarifyingQuestion]
    let urgencyLevel: UrgencyLevel
    let possibleCauses: [String]
    let selfCareActions: [String]
    let whenToSeeDoctor: [String]
}

struct ClarifyingQuestion: Identifiable {
    let id = UUID()
    let question: String
    let suggestedAnswers: [String]
    let category: QuestionCategory
}

enum QuestionCategory: String {
    case duration = "Duration"
    case severity = "Severity"
    case triggers = "Triggers"
    case pattern = "Pattern"
    case associated = "Associated Symptoms"
    case relief = "Relief"
}

enum UrgencyLevel: Int, Comparable {
    case low = 1
    case moderate = 2
    case high = 3
    case emergency = 4

    static func < (lhs: UrgencyLevel, rhs: UrgencyLevel) -> Bool {
        lhs.rawValue < rhs.rawValue
    }

    var label: String {
        switch self {
        case .low: "Low — monitor at home"
        case .moderate: "Moderate — schedule a visit if it persists"
        case .high: "High — see a doctor soon"
        case .emergency: "Emergency — seek immediate help"
        }
    }

    var color: Color {
        switch self {
        case .low: .green
        case .moderate: .orange
        case .high: .red
        case .emergency: .red
        }
    }

    var icon: String {
        switch self {
        case .low: "checkmark.circle"
        case .moderate: "exclamationmark.triangle"
        case .high: "exclamationmark.circle"
        case .emergency: "cross.circle.fill"
        }
    }
}

// MARK: - Symptom Clarifier Service

@Observable
@MainActor
final class SymptomClarifierService {

    func clarify(symptom: String, severity: SeverityLevel, context: SymptomContext = .init()) -> SymptomClarification {
        let lower = symptom.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)

        // Route to specific handler
        if containsAny(lower, ["headache", "head pain", "sar dard", "sir dard", "migraine"]) {
            return headacheClarification(severity: severity, context: context)
        }
        if containsAny(lower, ["stomach", "abdominal", "pet dard", "pet me dard", "belly", "tummy"]) {
            return stomachPainClarification(severity: severity, context: context)
        }
        if containsAny(lower, ["chest", "seene me dard", "chest pain", "chest tight"]) {
            return chestPainClarification(severity: severity, context: context)
        }
        if containsAny(lower, ["dizzy", "dizziness", "chakkar", "lightheaded", "vertigo"]) {
            return dizzinessClarification(severity: severity, context: context)
        }
        if containsAny(lower, ["nausea", "vomit", "ulti", "ji machlana", "throwing up"]) {
            return nauseaClarification(severity: severity, context: context)
        }
        if containsAny(lower, ["fever", "bukhar", "temperature", "hot"]) {
            return feverClarification(severity: severity, context: context)
        }
        if containsAny(lower, ["cough", "khansi", "sore throat", "gala dard"]) {
            return coughClarification(severity: severity, context: context)
        }
        if containsAny(lower, ["fatigue", "tired", "thakan", "weakness", "kamzori", "exhausted"]) {
            return fatigueClarification(severity: severity, context: context)
        }
        if containsAny(lower, ["rash", "skin", "itch", "khujli", "allergy", "hives"]) {
            return skinClarification(severity: severity, context: context)
        }
        if containsAny(lower, ["joint", "muscle", "body pain", "back pain", "knee", "jodo me dard"]) {
            return jointPainClarification(severity: severity, context: context)
        }

        return genericClarification(symptom: symptom, severity: severity, context: context)
    }

    // MARK: - Context

    struct SymptomContext {
        var currentMedicines: [String] = []
        var knownConditions: [String] = []
        var allergies: [String] = []
        var recentSymptoms: [String] = []
        var age: Int?
    }

    // MARK: - Specific Symptom Handlers

    private func headacheClarification(severity: SeverityLevel, context: SymptomContext) -> SymptomClarification {
        let urgency: UrgencyLevel = severity == .critical ? .high : (severity == .severe ? .moderate : .low)

        return SymptomClarification(
            symptomName: "Headache",
            acknowledgment: "Headaches can range from tension-type to migraines. Let me ask a few questions to understand yours better.",
            questions: [
                ClarifyingQuestion(
                    question: "Where exactly is the pain?",
                    suggestedAnswers: ["Forehead / temples", "One side only", "Back of head / neck", "All over", "Behind the eyes"],
                    category: .pattern
                ),
                ClarifyingQuestion(
                    question: "How would you describe the pain?",
                    suggestedAnswers: ["Throbbing / pulsing", "Tight / pressing", "Sharp / stabbing", "Dull / constant"],
                    category: .severity
                ),
                ClarifyingQuestion(
                    question: "When did it start and does anything make it worse?",
                    suggestedAnswers: ["Started today — worsens with light", "Started today — worsens with movement", "Been a few days — comes and goes", "Constant for 24+ hours"],
                    category: .triggers
                ),
                ClarifyingQuestion(
                    question: "Any associated symptoms?",
                    suggestedAnswers: ["Nausea or vomiting", "Sensitivity to light/sound", "Vision changes", "Neck stiffness", "None of these"],
                    category: .associated
                ),
            ],
            urgencyLevel: urgency,
            possibleCauses: [
                "Tension headache (most common — stress, posture, screen time)",
                "Migraine (throbbing, one-sided, with nausea/light sensitivity)",
                "Dehydration or skipped meals",
                "Medication side effect",
                "Sinusitis (with facial pressure)",
            ],
            selfCareActions: [
                "Rest in a quiet, dark room",
                "Stay hydrated — drink water or ORS",
                "Apply a cold compress to forehead",
                "Try gentle neck stretches",
            ],
            whenToSeeDoctor: [
                "Sudden, severe 'thunderclap' headache",
                "Headache with fever and stiff neck",
                "Vision changes or confusion",
                "Headache after a head injury",
                "Persistent headache for more than 3 days",
            ]
        )
    }

    private func stomachPainClarification(severity: SeverityLevel, context: SymptomContext) -> SymptomClarification {
        let urgency: UrgencyLevel = severity == .critical ? .high : (severity == .severe ? .moderate : .low)

        return SymptomClarification(
            symptomName: "Stomach / Abdominal Pain",
            acknowledgment: "Abdominal pain can have many causes. Let me help you narrow it down.",
            questions: [
                ClarifyingQuestion(
                    question: "Where is the pain?",
                    suggestedAnswers: ["Upper middle (above navel)", "Lower middle (below navel)", "Right side", "Left side", "All over"],
                    category: .pattern
                ),
                ClarifyingQuestion(
                    question: "What does the pain feel like?",
                    suggestedAnswers: ["Cramping / squeezing", "Burning / acidic", "Sharp / stabbing", "Bloating / pressure", "Dull ache"],
                    category: .severity
                ),
                ClarifyingQuestion(
                    question: "Is it related to food?",
                    suggestedAnswers: ["Worse after eating", "Better after eating", "Worse on empty stomach", "No food connection"],
                    category: .triggers
                ),
            ],
            urgencyLevel: urgency,
            possibleCauses: [
                "Acidity / gastritis (burning, worse on empty stomach)",
                "Food intolerance or indigestion",
                "Gas / bloating",
                "Gastroenteritis (with diarrhea/vomiting)",
                "Medication-related (NSAIDs, antibiotics)",
            ],
            selfCareActions: [
                "Eat light, bland foods (khichdi, dal rice)",
                "Avoid spicy, fried, and acidic foods",
                "Stay hydrated — small sips of water or buttermilk",
                "Try antacids if it's a burning sensation",
            ],
            whenToSeeDoctor: [
                "Severe pain that doesn't improve in 2–3 hours",
                "Blood in stool or vomit",
                "Fever above 101°F with abdominal pain",
                "Pain in the lower right side (could be appendix)",
                "Inability to keep any fluids down",
            ]
        )
    }

    private func chestPainClarification(severity: SeverityLevel, context: SymptomContext) -> SymptomClarification {
        return SymptomClarification(
            symptomName: "Chest Pain",
            acknowledgment: "Chest pain should always be taken seriously. Let me ask a few questions — but if you feel it's an emergency, call 112 or visit the nearest hospital immediately.",
            questions: [
                ClarifyingQuestion(
                    question: "How would you describe the pain?",
                    suggestedAnswers: ["Pressure / squeezing", "Sharp / stabbing", "Burning", "Aching", "Tightness"],
                    category: .severity
                ),
                ClarifyingQuestion(
                    question: "Does the pain radiate anywhere?",
                    suggestedAnswers: ["Left arm or shoulder", "Jaw or neck", "Back", "Stays in one spot", "Not sure"],
                    category: .pattern
                ),
                ClarifyingQuestion(
                    question: "What triggers or worsens it?",
                    suggestedAnswers: ["Physical activity", "Deep breathing", "Lying down", "After eating", "At rest / no trigger"],
                    category: .triggers
                ),
            ],
            urgencyLevel: severity.rawValue >= 3 ? .emergency : .high,
            possibleCauses: [
                "Muscular / chest wall pain (sharp, worsens with movement)",
                "Acid reflux / GERD (burning, worse after meals)",
                "Anxiety / panic attack (tightness, shortness of breath)",
                "Cardiac concern (pressure, radiating to arm/jaw)",
            ],
            selfCareActions: [
                "Rest and stay calm",
                "If you have prescribed nitroglycerin, use as directed",
                "Sit upright if breathing is uncomfortable",
            ],
            whenToSeeDoctor: [
                "Any new chest pain — get it evaluated",
                "Pain with shortness of breath or sweating",
                "Pain radiating to arm, jaw, or back",
                "History of heart disease or high BP",
                "Pain lasting more than a few minutes at rest",
            ]
        )
    }

    private func dizzinessClarification(severity: SeverityLevel, context: SymptomContext) -> SymptomClarification {
        let urgency: UrgencyLevel = severity.rawValue >= 3 ? .high : .moderate

        var possibleCauses = [
            "Low blood pressure (postural drop)",
            "Dehydration or low blood sugar",
            "Inner ear issue (BPPV, labyrinthitis)",
            "Anxiety or hyperventilation",
        ]
        if !context.currentMedicines.isEmpty {
            possibleCauses.append("Medication side effect (\(context.currentMedicines.prefix(2).joined(separator: ", ")))")
        }

        return SymptomClarification(
            symptomName: "Dizziness",
            acknowledgment: "Dizziness can feel unsettling. Let me understand what you're experiencing.",
            questions: [
                ClarifyingQuestion(
                    question: "What type of dizziness do you feel?",
                    suggestedAnswers: ["Room spinning (vertigo)", "Lightheaded / faint", "Unsteady / off-balance", "Floating feeling"],
                    category: .pattern
                ),
                ClarifyingQuestion(
                    question: "When does it happen?",
                    suggestedAnswers: ["Standing up quickly", "Turning head / rolling in bed", "All the time", "After taking medicine", "Random episodes"],
                    category: .triggers
                ),
            ],
            urgencyLevel: urgency,
            possibleCauses: possibleCauses,
            selfCareActions: [
                "Sit or lie down until it passes",
                "Drink water — dehydration is a common cause",
                "Stand up slowly from sitting or lying positions",
                "Eat something if you haven't in a while",
            ],
            whenToSeeDoctor: [
                "Dizziness with chest pain or headache",
                "Sudden hearing loss with vertigo",
                "Fainting or near-fainting episodes",
                "Persistent dizziness for more than 2 days",
                "Numbness, weakness, or vision changes",
            ]
        )
    }

    private func nauseaClarification(severity: SeverityLevel, context: SymptomContext) -> SymptomClarification {
        return SymptomClarification(
            symptomName: "Nausea / Vomiting",
            acknowledgment: "Nausea can be quite distressing. Let me understand the pattern better.",
            questions: [
                ClarifyingQuestion(
                    question: "How often are you vomiting?",
                    suggestedAnswers: ["Just nausea, no vomiting", "1–2 times today", "Multiple times", "Can't keep anything down"],
                    category: .severity
                ),
                ClarifyingQuestion(
                    question: "When does it happen?",
                    suggestedAnswers: ["After eating", "In the morning", "After taking medicine", "Constant", "Random"],
                    category: .triggers
                ),
            ],
            urgencyLevel: severity.rawValue >= 3 ? .high : .low,
            possibleCauses: [
                "Food poisoning or gastroenteritis",
                "Medication side effect",
                "Acidity or indigestion",
                "Motion sickness",
                "Anxiety or stress",
            ],
            selfCareActions: [
                "Sip clear fluids (water, ORS, coconut water)",
                "Avoid solid food until nausea passes",
                "Try ginger tea or jeera water",
                "Rest in a well-ventilated room",
            ],
            whenToSeeDoctor: [
                "Unable to keep any fluids down for 12+ hours",
                "Blood in vomit",
                "Severe abdominal pain with vomiting",
                "Signs of dehydration (dark urine, dry mouth)",
                "Vomiting after a head injury",
            ]
        )
    }

    private func feverClarification(severity: SeverityLevel, context: SymptomContext) -> SymptomClarification {
        return SymptomClarification(
            symptomName: "Fever",
            acknowledgment: "Fever is your body's way of fighting infection. Let me ask about the details.",
            questions: [
                ClarifyingQuestion(
                    question: "What's your temperature (if measured)?",
                    suggestedAnswers: ["99–100°F (low grade)", "100–102°F (moderate)", "Above 102°F (high)", "Haven't measured"],
                    category: .severity
                ),
                ClarifyingQuestion(
                    question: "How long have you had the fever?",
                    suggestedAnswers: ["Started today", "1–2 days", "3–5 days", "More than 5 days"],
                    category: .duration
                ),
                ClarifyingQuestion(
                    question: "Any other symptoms?",
                    suggestedAnswers: ["Body aches / chills", "Cough / cold", "Sore throat", "Rash", "None"],
                    category: .associated
                ),
            ],
            urgencyLevel: severity.rawValue >= 3 ? .high : .moderate,
            possibleCauses: [
                "Viral infection (most common — cold, flu)",
                "Bacterial infection (UTI, throat, ear)",
                "Dengue or malaria (in endemic areas)",
                "Medication reaction",
            ],
            selfCareActions: [
                "Rest and stay hydrated",
                "Take paracetamol (Crocin/Dolo 650) as directed",
                "Use tepid sponging to bring down temperature",
                "Wear light clothing",
            ],
            whenToSeeDoctor: [
                "Fever above 103°F that doesn't respond to paracetamol",
                "Fever lasting more than 3 days",
                "Fever with rash or stiff neck",
                "Fever with difficulty breathing",
                "In areas endemic for dengue/malaria — get tested",
            ]
        )
    }

    private func coughClarification(severity: SeverityLevel, context: SymptomContext) -> SymptomClarification {
        return SymptomClarification(
            symptomName: "Cough / Sore Throat",
            acknowledgment: "Coughs can be annoying and persistent. Let me understand yours better.",
            questions: [
                ClarifyingQuestion(
                    question: "What type of cough?",
                    suggestedAnswers: ["Dry / tickly", "Wet / with phlegm", "Barking / harsh", "Cough with blood"],
                    category: .pattern
                ),
                ClarifyingQuestion(
                    question: "How long have you had it?",
                    suggestedAnswers: ["1–3 days", "1–2 weeks", "More than 2 weeks", "Comes and goes"],
                    category: .duration
                ),
            ],
            urgencyLevel: severity.rawValue >= 3 ? .moderate : .low,
            possibleCauses: [
                "Common cold or viral infection",
                "Allergies or post-nasal drip",
                "Acid reflux (cough worse at night)",
                "Asthma (cough with wheezing)",
            ],
            selfCareActions: [
                "Drink warm water with honey and tulsi",
                "Gargle with warm salt water for sore throat",
                "Use steam inhalation",
                "Avoid cold drinks and dusty environments",
            ],
            whenToSeeDoctor: [
                "Cough lasting more than 2 weeks",
                "Coughing up blood",
                "Difficulty breathing or wheezing",
                "Cough with high fever",
                "Weight loss with persistent cough",
            ]
        )
    }

    private func fatigueClarification(severity: SeverityLevel, context: SymptomContext) -> SymptomClarification {
        return SymptomClarification(
            symptomName: "Fatigue / Weakness",
            acknowledgment: "Feeling tired and weak can affect everything. Let me understand what's going on.",
            questions: [
                ClarifyingQuestion(
                    question: "How long have you been feeling this way?",
                    suggestedAnswers: ["Just today", "A few days", "1–2 weeks", "More than a month"],
                    category: .duration
                ),
                ClarifyingQuestion(
                    question: "Does rest help?",
                    suggestedAnswers: ["Yes, I feel better after sleep", "No, still tired after rest", "I can't sleep properly", "Slightly better"],
                    category: .relief
                ),
            ],
            urgencyLevel: severity.rawValue >= 3 ? .moderate : .low,
            possibleCauses: [
                "Poor sleep or stress",
                "Iron deficiency / anemia (common in India)",
                "Thyroid issues",
                "Vitamin D or B12 deficiency",
                "Medication side effect",
                "Diabetes or blood sugar issues",
            ],
            selfCareActions: [
                "Ensure 7–8 hours of quality sleep",
                "Eat iron-rich foods (spinach, jaggery, dates)",
                "Stay hydrated and limit caffeine",
                "Light exercise like walking can boost energy",
            ],
            whenToSeeDoctor: [
                "Fatigue lasting more than 2 weeks without improvement",
                "Unexplained weight loss with fatigue",
                "Breathlessness on mild exertion",
                "Pale skin or easy bruising",
            ]
        )
    }

    private func skinClarification(severity: SeverityLevel, context: SymptomContext) -> SymptomClarification {
        return SymptomClarification(
            symptomName: "Skin Issue / Rash",
            acknowledgment: "Skin symptoms can be uncomfortable. Let me understand what you're seeing.",
            questions: [
                ClarifyingQuestion(
                    question: "What does it look like?",
                    suggestedAnswers: ["Red patches", "Bumps / hives", "Blisters", "Dry / flaky", "Swelling"],
                    category: .pattern
                ),
                ClarifyingQuestion(
                    question: "Is it itchy?",
                    suggestedAnswers: ["Very itchy", "Mildly itchy", "Painful, not itchy", "No itch or pain"],
                    category: .severity
                ),
                ClarifyingQuestion(
                    question: "Did you start any new medicine or food recently?",
                    suggestedAnswers: ["Yes, new medicine", "Yes, new food", "New soap / cosmetic", "No changes"],
                    category: .triggers
                ),
            ],
            urgencyLevel: severity.rawValue >= 3 ? .high : .low,
            possibleCauses: [
                "Allergic reaction (medicine, food, contact)",
                "Eczema or dermatitis",
                "Fungal infection (ringworm, common in humid weather)",
                "Heat rash (prickly heat)",
            ],
            selfCareActions: [
                "Avoid scratching — apply calamine lotion",
                "Wear loose, cotton clothing",
                "Take an antihistamine (Cetirizine) if itchy",
                "Keep the area clean and dry",
            ],
            whenToSeeDoctor: [
                "Rash spreading rapidly",
                "Swelling of face, lips, or throat (allergic emergency)",
                "Fever with rash",
                "Rash with pus or signs of infection",
                "Rash after starting new medication",
            ]
        )
    }

    private func jointPainClarification(severity: SeverityLevel, context: SymptomContext) -> SymptomClarification {
        return SymptomClarification(
            symptomName: "Joint / Muscle Pain",
            acknowledgment: "Body and joint pain can really slow you down. Let me understand the pattern.",
            questions: [
                ClarifyingQuestion(
                    question: "Which area is affected?",
                    suggestedAnswers: ["Knees", "Back (lower)", "Back (upper/neck)", "Shoulders / arms", "Multiple joints"],
                    category: .pattern
                ),
                ClarifyingQuestion(
                    question: "When is it worst?",
                    suggestedAnswers: ["In the morning (stiffness)", "After activity / exercise", "At night", "Constant / all day"],
                    category: .triggers
                ),
            ],
            urgencyLevel: severity.rawValue >= 3 ? .moderate : .low,
            possibleCauses: [
                "Muscle strain or overuse",
                "Arthritis (especially with morning stiffness)",
                "Vitamin D deficiency (very common in India)",
                "Post-viral body aches",
            ],
            selfCareActions: [
                "Rest the affected area",
                "Apply hot or cold compress",
                "Gentle stretching and movement",
                "Take a pain reliever if needed (paracetamol)",
            ],
            whenToSeeDoctor: [
                "Joint swelling, redness, or warmth",
                "Pain after an injury or fall",
                "Morning stiffness lasting more than 30 minutes daily",
                "Pain that prevents daily activities",
            ]
        )
    }

    private func genericClarification(symptom: String, severity: SeverityLevel, context: SymptomContext) -> SymptomClarification {
        let urgency: UrgencyLevel = severity.rawValue >= 3 ? .moderate : .low

        return SymptomClarification(
            symptomName: symptom.capitalized,
            acknowledgment: "I want to understand your \(symptom.lowercased()) better so I can help.",
            questions: [
                ClarifyingQuestion(
                    question: "How long have you had this symptom?",
                    suggestedAnswers: ["Just started today", "A few days", "More than a week", "Comes and goes"],
                    category: .duration
                ),
                ClarifyingQuestion(
                    question: "How severe is it on a scale?",
                    suggestedAnswers: ["Mild — noticeable but manageable", "Moderate — affecting daily activities", "Severe — hard to function", "Getting worse over time"],
                    category: .severity
                ),
                ClarifyingQuestion(
                    question: "Does anything make it better or worse?",
                    suggestedAnswers: ["Rest helps", "Medicine helps", "Nothing helps", "Gets worse with activity"],
                    category: .relief
                ),
            ],
            urgencyLevel: urgency,
            possibleCauses: [
                "Could be related to current medications",
                "May be linked to stress or lifestyle",
                "Could indicate an underlying condition",
            ],
            selfCareActions: [
                "Rest and monitor the symptom",
                "Stay hydrated and eat well",
                "Note any changes to share with your doctor",
            ],
            whenToSeeDoctor: [
                "Symptom persists for more than a week",
                "Symptom is getting progressively worse",
                "Associated with fever, weight loss, or severe pain",
                "Interfering with daily life or sleep",
            ]
        )
    }

    // MARK: - Helpers

    private func containsAny(_ text: String, _ keywords: [String]) -> Bool {
        keywords.contains { text.contains($0) }
    }
}
