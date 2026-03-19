import SwiftUI

// MARK: - AppLanguage

enum AppLanguage: String, CaseIterable, Codable {
    case english = "en"
    case hindi = "hi"

    var displayName: String {
        switch self {
        case .english: return "English"
        case .hindi: return "हिन्दी"
        }
    }
}

// MARK: - LocalizationService

@Observable
final class LocalizationService {

    // MARK: - State

    var currentLanguage: AppLanguage {
        didSet {
            UserDefaults.standard.set(currentLanguage.rawValue, forKey: Self.languageKey)
        }
    }

    // MARK: - Init

    private static let languageKey = "mc_app_language"

    init() {
        let stored = UserDefaults.standard.string(forKey: Self.languageKey) ?? AppLanguage.english.rawValue
        self.currentLanguage = AppLanguage(rawValue: stored) ?? .english
    }

    // MARK: - Public API

    /// Returns the localized string for the given key in the current language.
    /// Falls back to the key itself if no translation is found.
    func localized(_ key: String) -> String {
        switch currentLanguage {
        case .english:
            return englishStrings[key] ?? key
        case .hindi:
            return hindiStrings[key] ?? englishStrings[key] ?? key
        }
    }

    /// Convenience subscript: `l10n["key"]`
    subscript(_ key: String) -> String {
        localized(key)
    }

    // MARK: - English Strings

    private let englishStrings: [String: String] = [
        // Tab labels
        "tab.home":                 "Home",
        "tab.medications":          "Medications",
        "tab.health":               "Health",
        "tab.ai":                   "AI",
        "tab.profile":              "Profile",

        // Home screen
        "home.good_morning":        "Good morning",
        "home.good_afternoon":      "Good afternoon",
        "home.good_evening":        "Good evening",
        "home.good_night":          "Good night",
        "home.next_dose":           "Next Dose",
        "home.take_now":            "Take Now",
        "home.streak":              "Streak",
        "home.todays_adherence":    "Today's Adherence",
        "home.quick_actions":       "Quick Actions",
        "home.scan_rx":             "Scan Rx",
        "home.ai_chat":             "AI Chat",
        "home.upload":              "Upload",
        "home.prescription":        "Prescription",
        "home.ai_health":           "AI Health",
        "home.chat":                "Chat",
        "home.today":               "Today",
        "home.days":                "days",
        "home.all_done":            "All done for today!",
        "home.great_job":           "Great job keeping up with your medications",
        "home.no_doses":            "No doses scheduled",
        "home.upload_to_start":     "Upload a prescription to get started",
        "home.active_care_plans":   "Active Care Plans",
        "home.upcoming_tasks":      "Upcoming Tasks",

        // Health tab
        "health.overview":          "Overview",
        "health.calendar":          "Calendar",
        "health.insights":          "Insights",
        "health.health_score":      "Health Score",
        "health.weekly_adherence":  "Weekly Adherence",
        "health.share_with_doctor": "Share with Doctor",

        // Medication
        "med.add_medicine":         "Add Medicine",
        "med.dose_taken":           "Dose Taken",
        "med.dose_missed":          "Dose Missed",
        "med.dose_skipped":         "Dose Skipped",
        "med.snoozed":              "Snoozed",
        "med.out_of_stock":         "Out of Stock",
        "med.refill_needed":        "Refill Needed",

        // Symptom logging
        "symptom.how_feeling":      "How are you feeling?",
        "symptom.great":            "Great",
        "symptom.good":             "Good",
        "symptom.okay":             "Okay",
        "symptom.bad":              "Bad",
        "symptom.terrible":         "Terrible",
        "symptom.specific":         "Any specific symptoms?",
        "symptom.pain_level":       "Pain level",

        // Common
        "common.cancel":            "Cancel",
        "common.done":              "Done",
        "common.save":              "Save",
        "common.delete":            "Delete",
        "common.edit":              "Edit",
        "common.settings":          "Settings",
        "common.notifications":     "Notifications",
        "common.loading":           "Loading...",
        "common.next":              "Next",
        "common.back":              "Back",

        // Profile
        "profile.family_members":   "Family Members",
        "profile.add_profile":      "Add Profile",
        "profile.switch_profile":   "Switch Profile",
        "profile.subscription":     "Subscription",
    ]

    // MARK: - Hindi Strings

    private let hindiStrings: [String: String] = [
        // Tab labels
        "tab.home":                 "होम",
        "tab.medications":          "दवाइयाँ",
        "tab.health":               "स्वास्थ्य",
        "tab.ai":                   "AI",
        "tab.profile":              "प्रोफ़ाइल",

        // Home screen
        "home.good_morning":        "सुप्रभात",
        "home.good_afternoon":      "नमस्कार",
        "home.good_evening":        "शुभ संध्या",
        "home.good_night":          "शुभ रात्रि",
        "home.next_dose":           "अगली खुराक",
        "home.take_now":            "अभी लें",
        "home.streak":              "लगातार",
        "home.todays_adherence":    "आज की पालना",
        "home.quick_actions":       "त्वरित कार्य",
        "home.scan_rx":             "पर्चा स्कैन करें",
        "home.ai_chat":             "AI चैट",
        "home.upload":              "अपलोड",
        "home.prescription":        "पर्चा",
        "home.ai_health":           "AI स्वास्थ्य",
        "home.chat":                "चैट",
        "home.today":               "आज",
        "home.days":                "दिन",
        "home.all_done":            "आज की सभी दवाइयाँ ले ली!",
        "home.great_job":           "दवाइयाँ समय पर लेने के लिए शाबाश",
        "home.no_doses":            "कोई खुराक निर्धारित नहीं",
        "home.upload_to_start":     "शुरू करने के लिए पर्चा अपलोड करें",
        "home.active_care_plans":   "सक्रिय उपचार योजनाएँ",
        "home.upcoming_tasks":      "आगामी कार्य",

        // Health tab
        "health.overview":          "सारांश",
        "health.calendar":          "कैलेंडर",
        "health.insights":          "विश्लेषण",
        "health.health_score":      "स्वास्थ्य स्कोर",
        "health.weekly_adherence":  "साप्ताहिक पालना",
        "health.share_with_doctor": "डॉक्टर के साथ साझा करें",

        // Medication
        "med.add_medicine":         "दवा जोड़ें",
        "med.dose_taken":           "खुराक ली गई",
        "med.dose_missed":          "खुराक छूट गई",
        "med.dose_skipped":         "खुराक छोड़ी गई",
        "med.snoozed":              "स्नूज़ किया",
        "med.out_of_stock":         "स्टॉक में नहीं",
        "med.refill_needed":        "रीफ़िल ज़रूरी",

        // Symptom logging
        "symptom.how_feeling":      "आप कैसा महसूस कर रहे हैं?",
        "symptom.great":            "बहुत अच्छा",
        "symptom.good":             "अच्छा",
        "symptom.okay":             "ठीक",
        "symptom.bad":              "खराब",
        "symptom.terrible":         "बहुत खराब",
        "symptom.specific":         "कोई विशेष लक्षण?",
        "symptom.pain_level":       "दर्द का स्तर",

        // Common
        "common.cancel":            "रद्द करें",
        "common.done":              "हो गया",
        "common.save":              "सहेजें",
        "common.delete":            "हटाएँ",
        "common.edit":              "संपादित करें",
        "common.settings":          "सेटिंग्स",
        "common.notifications":     "सूचनाएँ",
        "common.loading":           "लोड हो रहा है...",
        "common.next":              "अगला",
        "common.back":              "पीछे",

        // Profile
        "profile.family_members":   "परिवार के सदस्य",
        "profile.add_profile":      "प्रोफ़ाइल जोड़ें",
        "profile.switch_profile":   "प्रोफ़ाइल बदलें",
        "profile.subscription":     "सदस्यता",
    ]
}

// MARK: - Environment Key

private struct LocalizationServiceKey: EnvironmentKey {
    static let defaultValue = LocalizationService()
}

extension EnvironmentValues {
    var localization: LocalizationService {
        get { self[LocalizationServiceKey.self] }
        set { self[LocalizationServiceKey.self] = newValue }
    }
}
