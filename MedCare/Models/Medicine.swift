import Foundation
import SwiftData

@Model
final class Medicine {
    @Attribute(.unique) var id: UUID
    var brandName: String
    var genericName: String?
    var dosage: String
    var doseForm: DoseForm = DoseForm.tablet
    var frequency: MedicineFrequency
    var timing: [MedicineTiming]
    var duration: Int? // days
    var mealTiming: MealTiming = MealTiming.noPreference
    var instructions: String?
    var manufacturer: String?
    var mrp: Double?
    var expiryDate: Date?
    var totalPillCount: Int?       // Total pills in the pack
    var pillsRemaining: Int?       // Current remaining count
    var refillAlertDays: Int = 5   // Alert X days before running out
    var isActive: Bool
    var isCritical: Bool = false
    var source: MedicineSource
    var confidenceScore: Double
    var startDate: Date
    var endDate: Date?
    var createdAt: Date

    @Relationship(inverse: \Episode.medicines) var episode: Episode?
    @Relationship(deleteRule: .cascade) var doseLogs: [DoseLog]

    init(
        brandName: String,
        genericName: String? = nil,
        dosage: String,
        doseForm: DoseForm = .tablet,
        frequency: MedicineFrequency = .onceDaily,
        timing: [MedicineTiming] = [.morning],
        duration: Int? = nil,
        mealTiming: MealTiming = .noPreference,
        source: MedicineSource = .manual,
        confidenceScore: Double = 1.0,
        isCritical: Bool = false
    ) {
        self.id = UUID()
        self.brandName = brandName
        self.genericName = genericName
        self.dosage = dosage
        self.doseForm = doseForm
        self.frequency = frequency
        self.timing = timing
        self.duration = duration
        self.mealTiming = mealTiming
        self.instructions = nil
        self.manufacturer = nil
        self.mrp = nil
        self.expiryDate = nil
        self.isActive = true
        self.isCritical = isCritical
        self.source = source
        self.confidenceScore = confidenceScore
        self.startDate = Date()
        self.endDate = duration.map {
            Calendar.current.date(byAdding: .day, value: $0, to: Date()) ?? Date()
        }
        self.createdAt = Date()
        self.doseLogs = []
    }

    var isLowConfidence: Bool {
        confidenceScore < 0.70
    }

    var nextDoseTime: Date? {
        let calendar = Calendar.current
        let now = Date()
        let todayComponents = calendar.dateComponents([.year, .month, .day], from: now)

        for time in timing.sorted(by: { $0.hour < $1.hour }) {
            var components = todayComponents
            components.hour = time.hour
            components.minute = time.minute
            if let date = calendar.date(from: components), date > now {
                return date
            }
        }

        // Next day first dose
        if let tomorrow = calendar.date(byAdding: .day, value: 1, to: now),
           let firstTiming = timing.sorted(by: { $0.hour < $1.hour }).first {
            let tomorrowComponents = calendar.dateComponents([.year, .month, .day], from: tomorrow)
            var components = tomorrowComponents
            components.hour = firstTiming.hour
            components.minute = firstTiming.minute
            return calendar.date(from: components)
        }

        return nil
    }
}

enum MedicineFrequency: String, Codable, CaseIterable {
    case onceDaily = "Once Daily"
    case twiceDaily = "Twice Daily"
    case thriceDaily = "Thrice Daily"
    case fourTimesDaily = "Four Times Daily"
    case asNeeded = "As Needed"
    case weekly = "Weekly"
    case alternate = "Alternate Days"

    var timesPerDay: Int {
        switch self {
        case .onceDaily: return 1
        case .twiceDaily: return 2
        case .thriceDaily: return 3
        case .fourTimesDaily: return 4
        case .asNeeded: return 0
        case .weekly: return 1
        case .alternate: return 1
        }
    }
}

enum MedicineTiming: Codable, Hashable, Comparable {
    case morning
    case afternoon
    case evening
    case night
    case custom(hour: Int, minute: Int)

    var hour: Int {
        switch self {
        case .morning: return 8
        case .afternoon: return 13
        case .evening: return 18
        case .night: return 21
        case .custom(let h, _): return h
        }
    }

    var minute: Int {
        switch self {
        case .custom(_, let m): return m
        default: return 0
        }
    }

    var displayName: String {
        switch self {
        case .morning: return "Morning"
        case .afternoon: return "Afternoon"
        case .evening: return "Evening"
        case .night: return "Night"
        case .custom(let h, let m): return String(format: "%02d:%02d", h, m)
        }
    }

    var icon: String {
        switch self {
        case .morning: return "sunrise"
        case .afternoon: return "sun.max"
        case .evening: return "sunset"
        case .night: return "moon.stars"
        case .custom: return "clock"
        }
    }

    static func < (lhs: MedicineTiming, rhs: MedicineTiming) -> Bool {
        if lhs.hour != rhs.hour { return lhs.hour < rhs.hour }
        return lhs.minute < rhs.minute
    }
}

enum MedicineSource: String, Codable {
    case aiExtracted = "AI Extracted"
    case manual = "Manual Entry"
    case edited = "User Edited"
    case ayurvedic = "Ayurvedic"
    case homeopathic = "Homeopathic"
}

enum DoseForm: String, Codable, CaseIterable {
    case tablet = "Tablet"
    case capsule = "Capsule"
    case syrup = "Syrup"
    case injection = "Injection"
    case drops = "Drops"
    case cream = "Cream/Ointment"
    case inhaler = "Inhaler"
    case patch = "Patch"
    case powder = "Powder"
    case suppository = "Suppository"
    // AYUSH / Traditional medicine forms
    case churna = "Churna"
    case kadha = "Kadha"
    case vati = "Vati"
    case ark = "Ark"

    var icon: String {
        switch self {
        case .tablet: return "pills"
        case .capsule: return "capsule"
        case .syrup: return "cup.and.saucer"
        case .injection: return "syringe"
        case .drops: return "drop"
        case .cream: return "hand.raised"
        case .inhaler: return "lungs"
        case .patch: return "bandage"
        case .powder: return "sparkles"
        case .suppository: return "pill"
        case .churna: return "leaf"
        case .kadha: return "cup.and.saucer"
        case .vati: return "circle.grid.2x2"
        case .ark: return "drop"
        }
    }

    var unit: String {
        switch self {
        case .tablet, .capsule: return "tab"
        case .syrup: return "ml"
        case .injection: return "ml"
        case .drops: return "drops"
        case .cream: return "application"
        case .inhaler: return "puff"
        case .patch: return "patch"
        case .powder: return "sachet"
        case .suppository: return "unit"
        case .churna: return "g"
        case .kadha: return "ml"
        case .vati: return "tab"
        case .ark: return "ml"
        }
    }
}

enum MealTiming: String, Codable, CaseIterable {
    case beforeMeal = "Before Meal"
    case afterMeal = "After Meal"
    case withMeal = "With Meal"
    case emptyStomach = "Empty Stomach"
    case noPreference = "Any Time"

    var icon: String {
        switch self {
        case .beforeMeal: return "fork.knife"
        case .afterMeal: return "fork.knife.circle.fill"
        case .withMeal: return "fork.knife.circle"
        case .emptyStomach: return "cup.and.saucer"
        case .noPreference: return "clock"
        }
    }

    var shortLabel: String {
        switch self {
        case .beforeMeal: return "Before food"
        case .afterMeal: return "After food"
        case .withMeal: return "With food"
        case .emptyStomach: return "Empty stomach"
        case .noPreference: return ""
        }
    }
}
