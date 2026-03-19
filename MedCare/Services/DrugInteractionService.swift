import Foundation

/// Comprehensive Drug Interaction Checker for Indian prescriptions
/// Uses String-based APIs — does not depend on SwiftData models directly
@Observable
final class DrugInteractionService {

    // MARK: - Types

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

    // MARK: - Interaction Database

    private struct InteractionRule {
        let drug1Keywords: [String]   // any keyword match for drug 1
        let drug2Keywords: [String]   // any keyword match for drug 2
        let severity: InteractionSeverity
        let description: String
        let recommendation: String
    }

    private let interactionRules: [InteractionRule] = {
        var rules: [InteractionRule] = []

        // ────────────────────────────────────────────
        // MAJOR Interactions
        // ────────────────────────────────────────────

        rules.append(InteractionRule(
            drug1Keywords: ["metformin", "glycomet", "gluconorm", "obimet"],
            drug2Keywords: ["alcohol"],
            severity: .major,
            description: "Metformin with alcohol greatly increases risk of lactic acidosis, a potentially fatal condition.",
            recommendation: "Avoid alcohol completely while on Metformin. If consumed, monitor for symptoms like rapid breathing, nausea, and muscle pain."
        ))

        rules.append(InteractionRule(
            drug1Keywords: ["warfarin", "warf", "acitrom", "acenocoumarol", "coumadin"],
            drug2Keywords: ["aspirin", "ecosprin", "disprin"],
            severity: .major,
            description: "Combined use dramatically increases bleeding risk. Both drugs inhibit clotting through different mechanisms.",
            recommendation: "Monitor INR very closely. Consult your doctor immediately. Do not self-medicate with aspirin while on warfarin."
        ))

        rules.append(InteractionRule(
            drug1Keywords: ["ramipril", "cardace", "enalapril", "envas", "lisinopril"],
            drug2Keywords: ["potassium", "k-dur", "aldactone", "spironolactone"],
            severity: .major,
            description: "ACE inhibitors with potassium supplements or potassium-sparing diuretics can cause dangerously high potassium levels (hyperkalemia).",
            recommendation: "Regular potassium level monitoring required. Do not take potassium supplements without doctor approval."
        ))

        rules.append(InteractionRule(
            drug1Keywords: ["metformin", "glycomet", "gluconorm"],
            drug2Keywords: ["contrast", "iodinated", "ct scan dye"],
            severity: .major,
            description: "Metformin with iodinated contrast media increases risk of contrast-induced nephropathy and lactic acidosis.",
            recommendation: "Stop Metformin 48 hours before and after contrast procedures. Resume only after kidney function is confirmed normal."
        ))

        rules.append(InteractionRule(
            drug1Keywords: ["clopidogrel", "clopilet", "plavix", "clopigrel"],
            drug2Keywords: ["omeprazole", "omez", "pantoprazole", "pan 40", "pantop", "rabeprazole", "razo"],
            severity: .major,
            description: "PPIs (especially omeprazole) significantly reduce the antiplatelet effect of clopidogrel by inhibiting CYP2C19, increasing risk of cardiovascular events.",
            recommendation: "Switch to pantoprazole (least interaction) or consider H2 blockers. Discuss with your cardiologist."
        ))

        rules.append(InteractionRule(
            drug1Keywords: ["warfarin", "warf", "acitrom", "acenocoumarol"],
            drug2Keywords: ["metronidazole", "metrogyl", "flagyl"],
            severity: .major,
            description: "Metronidazole inhibits warfarin metabolism, dramatically increasing bleeding risk.",
            recommendation: "INR monitoring every 2-3 days during metronidazole course. Dose adjustment likely needed."
        ))

        rules.append(InteractionRule(
            drug1Keywords: ["warfarin", "warf", "acitrom"],
            drug2Keywords: ["azithromycin", "azithral", "azee", "clarithromycin"],
            severity: .major,
            description: "Macrolide antibiotics increase warfarin levels, significantly raising bleeding risk.",
            recommendation: "Monitor INR closely during and after antibiotic course. Warfarin dose reduction may be needed."
        ))

        rules.append(InteractionRule(
            drug1Keywords: ["simvastatin", "zocor"],
            drug2Keywords: ["clarithromycin", "erythromycin", "itraconazole"],
            severity: .major,
            description: "These drugs inhibit simvastatin metabolism, causing dangerous muscle breakdown (rhabdomyolysis).",
            recommendation: "Stop simvastatin during the antibiotic/antifungal course. Contact your doctor immediately."
        ))

        rules.append(InteractionRule(
            drug1Keywords: ["methotrexate", "folitrax", "imutrex"],
            drug2Keywords: ["amoxicillin", "augmentin", "amoxyclav", "co-trimoxazole", "trimethoprim"],
            severity: .major,
            description: "These antibiotics reduce methotrexate excretion, causing toxic accumulation.",
            recommendation: "Avoid combination. If absolutely necessary, monitor blood counts and kidney function closely."
        ))

        rules.append(InteractionRule(
            drug1Keywords: ["methotrexate", "folitrax", "imutrex"],
            drug2Keywords: ["ibuprofen", "brufen", "diclofenac", "voveran", "aceclofenac", "zerodol", "combiflam"],
            severity: .major,
            description: "NSAIDs reduce methotrexate clearance and can cause fatal toxicity.",
            recommendation: "Avoid NSAIDs with methotrexate. Use paracetamol for pain relief. Consult your rheumatologist."
        ))

        rules.append(InteractionRule(
            drug1Keywords: ["sildenafil", "manforce", "penegra", "tadalafil", "megalis", "cialis"],
            drug2Keywords: ["nitroglycerin", "sorbitrate", "isosorbide", "nitrate", "isoket"],
            severity: .contraindicated,
            description: "LIFE-THREATENING: PDE5 inhibitors with nitrates cause severe, potentially fatal hypotension.",
            recommendation: "NEVER take together. Wait at least 24 hours (48 for tadalafil) after last nitrate dose."
        ))

        rules.append(InteractionRule(
            drug1Keywords: ["ciprofloxacin", "cifran", "ciplox"],
            drug2Keywords: ["tizanidine", "sirdalud"],
            severity: .contraindicated,
            description: "Ciprofloxacin causes dangerous increase in tizanidine levels, leading to severe hypotension and sedation.",
            recommendation: "Do NOT take together. This combination is contraindicated."
        ))

        rules.append(InteractionRule(
            drug1Keywords: ["fluconazole", "zocon", "forcan"],
            drug2Keywords: ["terfenadine", "cisapride"],
            severity: .contraindicated,
            description: "Risk of fatal cardiac arrhythmias (QT prolongation and torsades de pointes).",
            recommendation: "Combination is absolutely contraindicated. Use alternative antifungal."
        ))

        rules.append(InteractionRule(
            drug1Keywords: ["warfarin", "warf", "acitrom"],
            drug2Keywords: ["ibuprofen", "brufen", "diclofenac", "voveran", "combiflam", "aceclofenac", "zerodol"],
            severity: .major,
            description: "NSAIDs increase warfarin's anticoagulant effect and independently increase GI bleeding risk.",
            recommendation: "Avoid NSAIDs. Use paracetamol for pain. If NSAID essential, add GI protection and monitor INR."
        ))

        rules.append(InteractionRule(
            drug1Keywords: ["lithium"],
            drug2Keywords: ["ibuprofen", "brufen", "diclofenac", "voveran", "aceclofenac", "zerodol", "combiflam"],
            severity: .major,
            description: "NSAIDs reduce lithium excretion, causing potentially toxic lithium levels.",
            recommendation: "Avoid NSAIDs. If needed, monitor lithium levels closely and adjust dose."
        ))

        rules.append(InteractionRule(
            drug1Keywords: ["digoxin", "lanoxin", "digox"],
            drug2Keywords: ["amiodarone", "cordarone"],
            severity: .major,
            description: "Amiodarone increases digoxin levels by 70-100%, risking toxicity.",
            recommendation: "Reduce digoxin dose by 50% when starting amiodarone. Monitor digoxin levels closely."
        ))

        rules.append(InteractionRule(
            drug1Keywords: ["clonazepam", "rivotril", "clonotril", "alprazolam", "trika", "diazepam", "valium"],
            drug2Keywords: ["tramadol", "ultracet", "tramazac", "opioid", "codeine"],
            severity: .major,
            description: "Combined CNS depression can cause respiratory failure and death.",
            recommendation: "Avoid combination. If essential, use lowest doses and monitor closely for respiratory depression."
        ))

        // ────────────────────────────────────────────
        // MODERATE Interactions
        // ────────────────────────────────────────────

        rules.append(InteractionRule(
            drug1Keywords: ["atorvastatin", "atorva", "atocor", "lipitor"],
            drug2Keywords: ["grapefruit"],
            severity: .moderate,
            description: "Grapefruit inhibits CYP3A4, increasing atorvastatin levels and risk of muscle damage.",
            recommendation: "Avoid grapefruit and grapefruit juice while taking atorvastatin."
        ))

        rules.append(InteractionRule(
            drug1Keywords: ["ciprofloxacin", "cifran", "ciplox", "levofloxacin", "levoflox"],
            drug2Keywords: ["antacid", "aluminium", "magnesium", "calcium", "shelcal", "calcimax"],
            severity: .moderate,
            description: "Antacids and calcium significantly reduce absorption of fluoroquinolone antibiotics.",
            recommendation: "Take fluoroquinolone 2 hours before or 6 hours after antacids/calcium."
        ))

        rules.append(InteractionRule(
            drug1Keywords: ["escitalopram", "nexito", "s citadep", "fluoxetine", "prodep", "fludac", "sertraline"],
            drug2Keywords: ["ibuprofen", "brufen", "diclofenac", "voveran", "aspirin", "ecosprin", "combiflam", "aceclofenac", "zerodol"],
            severity: .moderate,
            description: "SSRIs with NSAIDs/aspirin increase gastrointestinal bleeding risk significantly.",
            recommendation: "Use with caution. Consider adding a PPI for GI protection. Prefer paracetamol over NSAIDs."
        ))

        rules.append(InteractionRule(
            drug1Keywords: ["atenolol", "aten", "betacard", "metoprolol", "met xl", "metolar"],
            drug2Keywords: ["insulin", "lantus", "basalog", "glargine", "human insulin", "actrapid"],
            severity: .moderate,
            description: "Beta-blockers mask hypoglycemia symptoms (tremor, fast heartbeat) and may prolong low blood sugar episodes.",
            recommendation: "Monitor blood glucose more frequently. Be aware that sweating will still occur as a hypoglycemia warning sign."
        ))

        rules.append(InteractionRule(
            drug1Keywords: ["levothyroxine", "thyronorm", "eltroxin", "thyrox"],
            drug2Keywords: ["calcium", "shelcal", "calcimax", "antacid", "iron", "ferrous", "autrin", "fefol"],
            severity: .moderate,
            description: "Calcium, iron, and antacids significantly reduce levothyroxine absorption.",
            recommendation: "Take levothyroxine at least 4 hours apart from calcium, iron supplements, and antacids."
        ))

        rules.append(InteractionRule(
            drug1Keywords: ["amlodipine", "amlong", "amlip", "stamlo"],
            drug2Keywords: ["simvastatin", "zocor"],
            severity: .moderate,
            description: "Amlodipine increases simvastatin levels, raising risk of muscle damage (rhabdomyolysis).",
            recommendation: "Limit simvastatin dose to 20mg daily when combined with amlodipine. Consider switching to atorvastatin."
        ))

        rules.append(InteractionRule(
            drug1Keywords: ["atenolol", "aten", "metoprolol", "met xl"],
            drug2Keywords: ["verapamil", "diltiazem", "dilzem", "herbesser"],
            severity: .moderate,
            description: "Combining beta-blockers with non-dihydropyridine calcium channel blockers can cause severe bradycardia and heart block.",
            recommendation: "Avoid combination unless under close cardiac monitoring. Prefer amlodipine with beta-blockers."
        ))

        rules.append(InteractionRule(
            drug1Keywords: ["escitalopram", "nexito", "fluoxetine", "prodep", "venlafaxine", "venlor"],
            drug2Keywords: ["tramadol", "ultracet", "tramazac"],
            severity: .moderate,
            description: "Risk of serotonin syndrome — a potentially life-threatening condition with agitation, tremor, and high temperature.",
            recommendation: "Use with extreme caution. Watch for agitation, tremor, diarrhoea, and rapid heartbeat."
        ))

        rules.append(InteractionRule(
            drug1Keywords: ["metformin", "glycomet", "gluconorm"],
            drug2Keywords: ["prednisolone", "wysolone", "omnacortil", "dexamethasone", "deflazacort"],
            severity: .moderate,
            description: "Corticosteroids raise blood glucose levels, counteracting the effect of metformin.",
            recommendation: "Monitor blood sugar more frequently. Diabetes medication dose may need to be increased temporarily."
        ))

        rules.append(InteractionRule(
            drug1Keywords: ["glimepiride", "amaryl", "glimisave", "gliclazide", "diamicron", "glizid"],
            drug2Keywords: ["fluconazole", "zocon", "forcan"],
            severity: .moderate,
            description: "Fluconazole inhibits sulfonylurea metabolism, increasing hypoglycemia risk.",
            recommendation: "Monitor blood glucose closely during fluconazole course. Reduce sulfonylurea dose if needed."
        ))

        rules.append(InteractionRule(
            drug1Keywords: ["ramipril", "cardace", "enalapril", "envas"],
            drug2Keywords: ["telmisartan", "telma", "losartan", "losacar", "olmesartan"],
            severity: .moderate,
            description: "Dual RAAS blockade (ACE inhibitor + ARB) increases risk of hyperkalemia, hypotension, and kidney injury.",
            recommendation: "Generally avoid this combination. It is no longer recommended in most guidelines."
        ))

        rules.append(InteractionRule(
            drug1Keywords: ["digoxin", "lanoxin", "digox"],
            drug2Keywords: ["furosemide", "lasix", "torsemide"],
            severity: .moderate,
            description: "Loop diuretics cause potassium loss, increasing sensitivity to digoxin toxicity.",
            recommendation: "Monitor potassium levels regularly. Consider potassium supplementation or adding spironolactone."
        ))

        rules.append(InteractionRule(
            drug1Keywords: ["azithromycin", "azithral", "azee", "azibact"],
            drug2Keywords: ["antacid", "aluminium", "magnesium"],
            severity: .moderate,
            description: "Antacids reduce azithromycin absorption.",
            recommendation: "Take azithromycin 1 hour before or 2 hours after antacids."
        ))

        rules.append(InteractionRule(
            drug1Keywords: ["doxycycline", "doxylab", "doxycap", "microdox"],
            drug2Keywords: ["antacid", "calcium", "shelcal", "iron", "ferrous", "autrin", "milk"],
            severity: .moderate,
            description: "Divalent cations (calcium, iron, antacids) form insoluble complexes with doxycycline, reducing absorption.",
            recommendation: "Separate doxycycline from these supplements by at least 2-3 hours."
        ))

        rules.append(InteractionRule(
            drug1Keywords: ["ciprofloxacin", "cifran", "ciplox", "ofloxacin", "oflox"],
            drug2Keywords: ["theophylline", "deriphyllin", "theodrip", "aminophylline"],
            severity: .moderate,
            description: "Fluoroquinolones inhibit theophylline metabolism, increasing risk of seizures and cardiac arrhythmias.",
            recommendation: "Monitor theophylline levels. Reduce theophylline dose by 25-50% if combination is necessary."
        ))

        rules.append(InteractionRule(
            drug1Keywords: ["clopidogrel", "clopilet", "plavix"],
            drug2Keywords: ["aspirin", "ecosprin"],
            severity: .moderate,
            description: "Dual antiplatelet therapy increases bleeding risk, though often prescribed intentionally after stenting.",
            recommendation: "If prescribed together post-stent, follow doctor's instructions. Watch for unusual bleeding or bruising."
        ))

        rules.append(InteractionRule(
            drug1Keywords: ["atorvastatin", "atorva", "rosuvastatin", "rosuvas", "crestor"],
            drug2Keywords: ["erythromycin", "clarithromycin"],
            severity: .moderate,
            description: "Macrolides inhibit statin metabolism, increasing risk of myopathy and rhabdomyolysis.",
            recommendation: "Consider temporarily stopping statin during short antibiotic courses. Use azithromycin instead if possible."
        ))

        rules.append(InteractionRule(
            drug1Keywords: ["escitalopram", "nexito", "fluoxetine", "prodep", "sertraline"],
            drug2Keywords: ["escitalopram", "nexito", "fluoxetine", "prodep", "sertraline", "venlafaxine", "venlor"],
            severity: .major,
            description: "Combining two serotonergic antidepressants significantly increases risk of serotonin syndrome.",
            recommendation: "Never take two antidepressants together without explicit doctor supervision. Taper one before starting another."
        ))

        rules.append(InteractionRule(
            drug1Keywords: ["amlodipine", "amlong", "nifedipine", "adalat"],
            drug2Keywords: ["grapefruit"],
            severity: .moderate,
            description: "Grapefruit increases calcium channel blocker levels, causing excessive blood pressure lowering.",
            recommendation: "Avoid grapefruit and grapefruit juice."
        ))

        rules.append(InteractionRule(
            drug1Keywords: ["pioglitazone", "pioz", "piozone"],
            drug2Keywords: ["insulin", "lantus", "basalog", "glargine"],
            severity: .moderate,
            description: "Pioglitazone with insulin increases risk of fluid retention, weight gain, and heart failure.",
            recommendation: "Monitor for swelling, weight gain, and shortness of breath. Report symptoms immediately."
        ))

        rules.append(InteractionRule(
            drug1Keywords: ["furosemide", "lasix", "fruselac"],
            drug2Keywords: ["ramipril", "cardace", "enalapril", "envas"],
            severity: .moderate,
            description: "First-dose hypotension when starting ACE inhibitor in patients on diuretics.",
            recommendation: "Start ACE inhibitor at low dose. Consider holding diuretic for 2-3 days before starting."
        ))

        rules.append(InteractionRule(
            drug1Keywords: ["pregabalin", "lyrica", "pregalin", "gabapentin", "gabapin"],
            drug2Keywords: ["clonazepam", "rivotril", "alprazolam", "trika", "diazepam"],
            severity: .moderate,
            description: "Additive CNS depression causing excessive sedation, dizziness, and respiratory depression.",
            recommendation: "Use lowest effective doses. Avoid driving. Monitor for excessive drowsiness."
        ))

        rules.append(InteractionRule(
            drug1Keywords: ["hydroxychloroquine", "hcqs", "plaquenil"],
            drug2Keywords: ["azithromycin", "azithral", "azee"],
            severity: .moderate,
            description: "Both drugs can prolong QT interval, increasing risk of cardiac arrhythmias.",
            recommendation: "ECG monitoring recommended before and during combination therapy."
        ))

        rules.append(InteractionRule(
            drug1Keywords: ["warfarin", "warf", "acitrom"],
            drug2Keywords: ["paracetamol", "crocin", "dolo", "calpol"],
            severity: .moderate,
            description: "Regular paracetamol use (>2g/day) can increase INR and bleeding risk with warfarin.",
            recommendation: "Occasional paracetamol is safe. For regular use, monitor INR more frequently."
        ))

        rules.append(InteractionRule(
            drug1Keywords: ["empagliflozin", "jardiance", "dapagliflozin", "forxiga"],
            drug2Keywords: ["furosemide", "lasix", "torsemide", "hydrochlorothiazide"],
            severity: .moderate,
            description: "SGLT2 inhibitors with diuretics increase risk of dehydration and hypotension.",
            recommendation: "Stay well hydrated. Monitor blood pressure. Diuretic dose reduction may be needed."
        ))

        rules.append(InteractionRule(
            drug1Keywords: ["metronidazole", "metrogyl", "flagyl"],
            drug2Keywords: ["alcohol"],
            severity: .major,
            description: "Disulfiram-like reaction: severe nausea, vomiting, flushing, headache, and abdominal cramps.",
            recommendation: "Strictly avoid alcohol during treatment and for 48 hours after completing the course."
        ))

        // ────────────────────────────────────────────
        // MINOR Interactions
        // ────────────────────────────────────────────

        rules.append(InteractionRule(
            drug1Keywords: ["levocetirizine", "xyzal", "levocet", "cetirizine", "cetzine", "okacet"],
            drug2Keywords: ["alcohol"],
            severity: .minor,
            description: "Enhanced sedation and drowsiness when antihistamines are taken with alcohol.",
            recommendation: "Avoid alcohol while taking antihistamines, especially before driving or operating machinery."
        ))

        rules.append(InteractionRule(
            drug1Keywords: ["pantoprazole", "pan 40", "pantop", "omeprazole", "omez", "rabeprazole", "razo"],
            drug2Keywords: ["iron", "ferrous", "autrin", "fefol", "dexorange"],
            severity: .minor,
            description: "PPIs reduce stomach acid needed for iron absorption.",
            recommendation: "Take iron supplement 2 hours before PPI. Consider Vitamin C with iron to enhance absorption."
        ))

        rules.append(InteractionRule(
            drug1Keywords: ["montelukast", "montair", "montek"],
            drug2Keywords: ["phenobarbital", "phenytoin", "carbamazepine"],
            severity: .moderate,
            description: "Enzyme-inducing anticonvulsants reduce montelukast effectiveness.",
            recommendation: "Dosage adjustment may be needed. Consult your doctor."
        ))

        rules.append(InteractionRule(
            drug1Keywords: ["pantoprazole", "pan 40", "omeprazole", "omez"],
            drug2Keywords: ["calcium", "shelcal", "calcimax"],
            severity: .minor,
            description: "Long-term PPI use may reduce calcium absorption, increasing osteoporosis risk.",
            recommendation: "Ensure adequate calcium and Vitamin D supplementation. Take calcium separately."
        ))

        rules.append(InteractionRule(
            drug1Keywords: ["metformin", "glycomet"],
            drug2Keywords: ["vitamin b12", "methylcobalamin", "mecobalamin"],
            severity: .minor,
            description: "Long-term metformin use depletes Vitamin B12 levels.",
            recommendation: "This is actually a beneficial combination. Continue B12 supplementation while on long-term metformin."
        ))

        rules.append(InteractionRule(
            drug1Keywords: ["paracetamol", "crocin", "dolo", "calpol"],
            drug2Keywords: ["alcohol"],
            severity: .moderate,
            description: "Chronic alcohol use with paracetamol significantly increases risk of liver damage.",
            recommendation: "Avoid alcohol while taking paracetamol. Maximum 2g/day for regular drinkers."
        ))

        rules.append(InteractionRule(
            drug1Keywords: ["amlodipine", "amlong", "amlip"],
            drug2Keywords: ["atenolol", "aten", "metoprolol", "met xl"],
            severity: .minor,
            description: "Both lower blood pressure through different mechanisms. Intentionally combined but may cause excessive BP lowering.",
            recommendation: "Monitor blood pressure regularly. Watch for dizziness and lightheadedness on standing."
        ))

        rules.append(InteractionRule(
            drug1Keywords: ["aspirin", "ecosprin", "disprin"],
            drug2Keywords: ["ibuprofen", "brufen", "combiflam", "ibugesic"],
            severity: .moderate,
            description: "Ibuprofen can block aspirin's antiplatelet effect when taken before aspirin.",
            recommendation: "Take aspirin at least 30 minutes before ibuprofen, or 8 hours after. Consider alternative analgesics."
        ))

        rules.append(InteractionRule(
            drug1Keywords: ["telmisartan", "telma", "losartan", "losacar", "olmesartan"],
            drug2Keywords: ["potassium", "k-dur", "potklor"],
            severity: .moderate,
            description: "ARBs increase potassium retention. Additional potassium supplementation may cause hyperkalemia.",
            recommendation: "Monitor potassium levels. Avoid potassium supplements and salt substitutes unless directed by doctor."
        ))

        rules.append(InteractionRule(
            drug1Keywords: ["fluoxetine", "prodep", "fludac", "flunil"],
            drug2Keywords: ["tamoxifen"],
            severity: .major,
            description: "Fluoxetine strongly inhibits CYP2D6, significantly reducing tamoxifen's anticancer effectiveness.",
            recommendation: "Switch to a different antidepressant (venlafaxine or escitalopram). Do not combine."
        ))

        rules.append(InteractionRule(
            drug1Keywords: ["ciprofloxacin", "cifran", "levofloxacin", "levoflox", "ofloxacin", "oflox"],
            drug2Keywords: ["prednisolone", "wysolone", "dexamethasone"],
            severity: .moderate,
            description: "Fluoroquinolones with corticosteroids significantly increase risk of tendon rupture.",
            recommendation: "Be alert for tendon pain, especially in the Achilles tendon. Stop exercise if pain occurs."
        ))

        rules.append(InteractionRule(
            drug1Keywords: ["glimepiride", "amaryl", "gliclazide", "diamicron", "glipizide", "glynase"],
            drug2Keywords: ["alcohol"],
            severity: .moderate,
            description: "Alcohol enhances hypoglycemic effect of sulfonylureas, causing dangerous blood sugar drops.",
            recommendation: "Limit alcohol intake. Never drink on an empty stomach while on sulfonylureas."
        ))

        rules.append(InteractionRule(
            drug1Keywords: ["atenolol", "aten", "metoprolol", "met xl"],
            drug2Keywords: ["salbutamol", "asthalin", "ventolin"],
            severity: .minor,
            description: "Beta-blockers can reduce the bronchodilator effect of salbutamol.",
            recommendation: "Use cardioselective beta-blockers (metoprolol) in asthmatic patients. Avoid atenolol in asthma."
        ))

        rules.append(InteractionRule(
            drug1Keywords: ["levothyroxine", "thyronorm", "eltroxin"],
            drug2Keywords: ["omeprazole", "omez", "pantoprazole", "pan 40", "rabeprazole", "razo"],
            severity: .minor,
            description: "PPIs may reduce levothyroxine absorption by altering gastric pH.",
            recommendation: "Take levothyroxine on empty stomach, at least 30 minutes before PPI. Monitor TSH."
        ))

        rules.append(InteractionRule(
            drug1Keywords: ["warfarin", "warf", "acitrom"],
            drug2Keywords: ["vitamin k", "green leafy"],
            severity: .minor,
            description: "Vitamin K-rich foods counteract warfarin's anticoagulant effect.",
            recommendation: "Maintain consistent Vitamin K intake. Don't suddenly increase or decrease green vegetables."
        ))

        rules.append(InteractionRule(
            drug1Keywords: ["atorvastatin", "atorva", "rosuvastatin", "rosuvas"],
            drug2Keywords: ["fenofibrate", "lipanthyl", "lipicard"],
            severity: .moderate,
            description: "Combining statins with fibrates increases risk of myopathy and rhabdomyolysis.",
            recommendation: "Monitor for muscle pain and weakness. Get CK levels checked if symptoms occur."
        ))

        rules.append(InteractionRule(
            drug1Keywords: ["digoxin", "lanoxin"],
            drug2Keywords: ["verapamil", "diltiazem", "dilzem"],
            severity: .moderate,
            description: "Verapamil/diltiazem increase digoxin levels and combined AV node depression risk.",
            recommendation: "Reduce digoxin dose by 33-50%. Monitor heart rate and digoxin levels."
        ))

        rules.append(InteractionRule(
            drug1Keywords: ["carbamazepine", "tegretol", "zen"],
            drug2Keywords: ["erythromycin", "clarithromycin"],
            severity: .major,
            description: "Macrolides inhibit carbamazepine metabolism causing toxicity (dizziness, double vision, ataxia).",
            recommendation: "Use azithromycin instead. If combination unavoidable, monitor carbamazepine levels."
        ))

        rules.append(InteractionRule(
            drug1Keywords: ["phenytoin", "eptoin", "dilantin"],
            drug2Keywords: ["fluconazole", "zocon", "forcan"],
            severity: .major,
            description: "Fluconazole inhibits phenytoin metabolism, causing toxicity.",
            recommendation: "Monitor phenytoin levels. Dose reduction usually needed during fluconazole course."
        ))

        rules.append(InteractionRule(
            drug1Keywords: ["acyclovir", "zovirax", "acivir"],
            drug2Keywords: ["methotrexate", "folitrax"],
            severity: .moderate,
            description: "Both drugs compete for renal excretion, increasing risk of nephrotoxicity.",
            recommendation: "Ensure adequate hydration. Monitor kidney function."
        ))

        rules.append(InteractionRule(
            drug1Keywords: ["orlistat", "obelit", "xenical"],
            drug2Keywords: ["levothyroxine", "thyronorm", "eltroxin"],
            severity: .moderate,
            description: "Orlistat may reduce levothyroxine absorption.",
            recommendation: "Take levothyroxine and orlistat at least 4 hours apart. Monitor TSH."
        ))

        rules.append(InteractionRule(
            drug1Keywords: ["orlistat", "obelit", "xenical"],
            drug2Keywords: ["warfarin", "warf", "acitrom"],
            severity: .moderate,
            description: "Orlistat reduces absorption of fat-soluble Vitamin K, enhancing warfarin effect.",
            recommendation: "Monitor INR closely when starting or stopping orlistat."
        ))

        rules.append(InteractionRule(
            drug1Keywords: ["tamsulosin", "urimax", "contiflo"],
            drug2Keywords: ["sildenafil", "manforce", "tadalafil", "megalis"],
            severity: .moderate,
            description: "Both lower blood pressure — combined use increases risk of orthostatic hypotension.",
            recommendation: "Start with lower doses. Rise slowly from sitting/lying position."
        ))

        rules.append(InteractionRule(
            drug1Keywords: ["spironolactone", "aldactone"],
            drug2Keywords: ["ramipril", "cardace", "enalapril", "envas", "telmisartan", "telma", "losartan"],
            severity: .moderate,
            description: "Triple RAAS blockade or dual potassium-sparing combination increases hyperkalemia risk.",
            recommendation: "Monitor potassium levels regularly (every 1-2 weeks initially). Avoid potassium-rich salt substitutes."
        ))

        rules.append(InteractionRule(
            drug1Keywords: ["clonazepam", "rivotril", "alprazolam"],
            drug2Keywords: ["alcohol"],
            severity: .major,
            description: "Benzodiazepines with alcohol can cause fatal respiratory depression.",
            recommendation: "NEVER combine with alcohol. Risk of coma and death."
        ))

        return rules
    }()

    // MARK: - String-Based API (Primary)

    /// Check interactions between a list of medicine names (brand or generic)
    func checkInteractions(medicines: [String]) -> [InteractionAlert] {
        var alerts: [InteractionAlert] = []
        let normalizedNames = medicines.map { normalizeDrugName($0) }

        for i in 0..<normalizedNames.count {
            for j in (i + 1)..<normalizedNames.count {
                let name1 = normalizedNames[i]
                let name2 = normalizedNames[j]

                for rule in interactionRules {
                    let match1to1 = rule.drug1Keywords.contains { name1.contains($0) }
                    let match1to2 = rule.drug2Keywords.contains { name2.contains($0) }
                    let match2to1 = rule.drug1Keywords.contains { name2.contains($0) }
                    let match2to2 = rule.drug2Keywords.contains { name1.contains($0) }

                    if (match1to1 && match1to2) || (match2to1 && match2to2) {
                        // Avoid duplicate self-interaction for same-class rule
                        if medicines[i] != medicines[j] {
                            alerts.append(InteractionAlert(
                                medicine1: medicines[i],
                                medicine2: medicines[j],
                                severity: rule.severity,
                                description: rule.description,
                                recommendation: rule.recommendation
                            ))
                        }
                    }
                }
            }
        }

        return alerts.sorted { severityWeight($0.severity) > severityWeight($1.severity) }
    }

    /// Check if adding a new medicine name conflicts with existing medicine names
    func checkNewMedicine(_ newMedicine: String, against existingNames: [String]) -> [InteractionAlert] {
        return checkInteractions(medicines: existingNames + [newMedicine])
    }

    // MARK: - Medicine Model API (Backward Compatible)

    /// Check interactions between Medicine model objects
    func checkInteractions(medicines: [Medicine]) -> [InteractionAlert] {
        let names = medicines.map { buildSearchableName(from: $0) }

        var alerts: [InteractionAlert] = []

        for i in 0..<medicines.count {
            for j in (i + 1)..<medicines.count {
                let name1 = names[i]
                let name2 = names[j]

                for rule in interactionRules {
                    let match1to1 = rule.drug1Keywords.contains { name1.contains($0) }
                    let match1to2 = rule.drug2Keywords.contains { name2.contains($0) }
                    let match2to1 = rule.drug1Keywords.contains { name2.contains($0) }
                    let match2to2 = rule.drug2Keywords.contains { name1.contains($0) }

                    if (match1to1 && match1to2) || (match2to1 && match2to2) {
                        alerts.append(InteractionAlert(
                            medicine1: medicines[i].brandName,
                            medicine2: medicines[j].brandName,
                            severity: rule.severity,
                            description: rule.description,
                            recommendation: rule.recommendation
                        ))
                    }
                }
            }
        }

        return alerts.sorted { severityWeight($0.severity) > severityWeight($1.severity) }
    }

    /// Check if adding a new medicine conflicts with existing Medicine models
    func checkNewMedicine(_ newMedicine: String, against existing: [Medicine]) -> [InteractionAlert] {
        let existingNames = existing.map { buildSearchableName(from: $0) }
        let newName = normalizeDrugName(newMedicine)

        var alerts: [InteractionAlert] = []

        for i in 0..<existingNames.count {
            let name1 = existingNames[i]
            let name2 = newName

            for rule in interactionRules {
                let match1to1 = rule.drug1Keywords.contains { name1.contains($0) }
                let match1to2 = rule.drug2Keywords.contains { name2.contains($0) }
                let match2to1 = rule.drug1Keywords.contains { name2.contains($0) }
                let match2to2 = rule.drug2Keywords.contains { name1.contains($0) }

                if (match1to1 && match1to2) || (match2to1 && match2to2) {
                    alerts.append(InteractionAlert(
                        medicine1: existing[i].brandName,
                        medicine2: newMedicine,
                        severity: rule.severity,
                        description: rule.description,
                        recommendation: rule.recommendation
                    ))
                }
            }
        }

        return alerts.sorted { severityWeight($0.severity) > severityWeight($1.severity) }
    }

    // MARK: - Helpers

    private func normalizeDrugName(_ name: String) -> String {
        let lowered = name.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)

        // Also resolve brand names to generic via the database
        if let entry = IndianDrugDatabase.shared.medicines.first(where: {
            $0.brandName.lowercased() == lowered || $0.id == lowered
        }) {
            return "\(lowered) \(entry.genericName.lowercased()) \(entry.saltComposition.lowercased())"
        }

        return lowered
    }

    private func buildSearchableName(from medicine: Medicine) -> String {
        let brandLower = medicine.brandName.lowercased()
        let genericLower = (medicine.genericName ?? "").lowercased()
        let combined = "\(brandLower) \(genericLower)"

        // Enrich with database lookup
        if let entry = IndianDrugDatabase.shared.medicines.first(where: {
            $0.brandName.lowercased() == brandLower || $0.id == brandLower
        }) {
            return "\(combined) \(entry.saltComposition.lowercased())"
        }

        return combined
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
