import SwiftUI

// MARK: - AppLanguage

enum AppLanguage: String, CaseIterable, Codable {
    case english = "en"
    case hindi = "hi"
    case tamil = "ta"
    case telugu = "te"
    case marathi = "mr"
    case bengali = "bn"

    var displayName: String {
        switch self {
        case .english: return "English"
        case .hindi: return "हिन्दी"
        case .tamil: return "தமிழ்"
        case .telugu: return "తెలుగు"
        case .marathi: return "मराठी"
        case .bengali: return "বাংলা"
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
        case .tamil, .telugu, .marathi, .bengali:
            // Regional languages fall back to English for UI strings
            return englishStrings[key] ?? key
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
        "profile.sign_out":         "Sign Out",
        "profile.about":            "About",
        "profile.achievements":     "Achievements",
        "profile.doctor_visit":     "Doctor Visit Prep",
        "profile.elder_mode":       "Elder Mode",

        // Settings
        "settings.import_records":  "Import Health Records",
        "settings.abha_linking":    "ABHA Linking",
        "settings.payment_upi":    "Payment & UPI",
        "settings.help_support":   "Help & Support",
        "settings.about_app":      "About MedCare",
        "settings.privacy":         "Privacy Settings",
        "settings.manage_consents": "Manage Consents",
        "settings.export_data":     "Export My Data",
        "settings.delete_account":  "Delete Account",

        // Messages
        "messages.doctor":          "Doctor",
        "messages.patient":         "Patient",
        "messages.send":            "Send",
        "messages.type_message":    "Type a message...",

        // Dose Status
        "dose.taken":               "Taken",
        "dose.missed":              "Missed",
        "dose.pending":             "Pending",
        "dose.snoozed":             "Snoozed",
        "dose.skipped":             "Skipped",

        // Actions
        "action.take_now":          "Take Now",
        "action.skip":              "Skip",
        "action.snooze":            "Snooze",
        "action.share":             "Share",
        "action.retry":             "Retry",
        "action.confirm":           "Confirm",
        "action.search":            "Search",
        "action.filter":            "Filter",
        "action.add":               "Add",
        "action.remove":            "Remove",
        "action.refresh":           "Refresh",
        "action.view_all":          "View All",
        "action.learn_more":        "Learn More",

        // Ayurvedic
        "ayurvedic.title":          "Ayurvedic Medicines",
        "ayurvedic.uses":           "Common Uses",
        "ayurvedic.dosage":         "Dosage",
        "ayurvedic.timing":         "When to Take",
        "ayurvedic.caution":        "Contraindications",
        "ayurvedic.form":           "Form",

        // ABDM / Health Records
        "abdm.import_title":        "Import Health Records",
        "abdm.search_providers":    "Search hospitals, clinics, labs...",
        "abdm.data_types":          "Data Types",
        "abdm.date_range":          "Date Range",
        "abdm.request_records":     "Request Records",
        "abdm.pending_requests":    "Pending Requests",
        "abdm.imported_records":    "Imported Records",
        "abdm.prescriptions":       "Prescriptions",
        "abdm.lab_reports":         "Lab Reports",
        "abdm.discharge_summaries": "Discharge Summaries",
        "abdm.vitals":              "Vitals",
        "abdm.status_requested":    "Requested",
        "abdm.status_approved":     "Approved",
        "abdm.status_denied":       "Denied",
        "abdm.status_expired":      "Expired",

        // Errors
        "error.generic":            "Something went wrong",
        "error.network":            "No internet connection",
        "error.try_again":          "Please try again",
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
        "profile.sign_out":         "साइन आउट",
        "profile.about":            "के बारे में",
        "profile.achievements":     "उपलब्धियाँ",
        "profile.doctor_visit":     "डॉक्टर मिलने की तैयारी",
        "profile.elder_mode":       "बड़ों का मोड",

        // Settings
        "settings.import_records":  "स्वास्थ्य रिकॉर्ड आयात करें",
        "settings.abha_linking":    "ABHA लिंकिंग",
        "settings.payment_upi":    "भुगतान और UPI",
        "settings.help_support":   "सहायता",
        "settings.about_app":      "MedCare के बारे में",
        "settings.privacy":         "गोपनीयता सेटिंग्स",
        "settings.manage_consents": "सहमतियाँ प्रबंधित करें",
        "settings.export_data":     "डेटा निर्यात करें",
        "settings.delete_account":  "खाता हटाएँ",

        // Messages
        "messages.doctor":          "डॉक्टर",
        "messages.patient":         "मरीज़",
        "messages.send":            "भेजें",
        "messages.type_message":    "संदेश लिखें...",

        // Dose Status
        "dose.taken":               "ली गई",
        "dose.missed":              "छूट गई",
        "dose.pending":             "बाकी",
        "dose.snoozed":             "स्नूज़ किया",
        "dose.skipped":             "छोड़ी गई",

        // Actions
        "action.take_now":          "अभी लें",
        "action.skip":              "छोड़ें",
        "action.snooze":            "स्नूज़",
        "action.share":             "साझा करें",
        "action.retry":             "पुनः प्रयास",
        "action.confirm":           "पुष्टि करें",
        "action.search":            "खोजें",
        "action.filter":            "फ़िल्टर",
        "action.add":               "जोड़ें",
        "action.remove":            "हटाएँ",
        "action.refresh":           "ताज़ा करें",
        "action.view_all":          "सभी देखें",
        "action.learn_more":        "और जानें",

        // Ayurvedic
        "ayurvedic.title":          "आयुर्वेदिक दवाइयाँ",
        "ayurvedic.uses":           "सामान्य उपयोग",
        "ayurvedic.dosage":         "खुराक",
        "ayurvedic.timing":         "कब लें",
        "ayurvedic.caution":        "सावधानियाँ",
        "ayurvedic.form":           "रूप",

        // ABDM / Health Records
        "abdm.import_title":        "स्वास्थ्य रिकॉर्ड आयात करें",
        "abdm.search_providers":    "अस्पताल, क्लिनिक, लैब खोजें...",
        "abdm.data_types":          "डेटा प्रकार",
        "abdm.date_range":          "तारीख सीमा",
        "abdm.request_records":     "रिकॉर्ड का अनुरोध करें",
        "abdm.pending_requests":    "लंबित अनुरोध",
        "abdm.imported_records":    "आयातित रिकॉर्ड",
        "abdm.prescriptions":       "पर्चे",
        "abdm.lab_reports":         "लैब रिपोर्ट",
        "abdm.discharge_summaries": "डिस्चार्ज सारांश",
        "abdm.vitals":              "वाइटल्स",
        "abdm.status_requested":    "अनुरोधित",
        "abdm.status_approved":     "स्वीकृत",
        "abdm.status_denied":       "अस्वीकृत",
        "abdm.status_expired":      "समाप्त",

        // Errors
        "error.generic":            "कुछ गलत हो गया",
        "error.network":            "इंटरनेट कनेक्शन नहीं है",
        "error.try_again":          "कृपया पुनः प्रयास करें",
    ]

    // MARK: - Hindi Dosage Instructions

    /// Case-insensitive lookup for common dosage instructions.
    /// Used when the Hindi display toggle is on, independent of app language.
    private static let hindiDosageMap: [(english: String, hindi: String)] = [
        // Meal timing
        ("After food",                  "खाने के बाद"),
        ("Before food",                 "खाने से पहले"),
        ("With food",                   "खाने के साथ"),
        ("Empty stomach",              "खाली पेट"),
        ("After breakfast",            "नाश्ते के बाद"),
        ("After lunch",                "दोपहर के खाने के बाद"),
        ("After dinner",               "रात के खाने के बाद"),

        // Time of day
        ("Morning",                    "सुबह"),
        ("Afternoon",                  "दोपहर"),
        ("Evening",                    "शाम"),
        ("Night",                      "रात"),

        // Frequency
        ("Once daily",                 "दिन में एक बार"),
        ("Twice daily",                "दिन में दो बार"),
        ("Thrice daily",               "दिन में तीन बार"),

        // Dose forms
        ("Tablet",                     "गोली"),
        ("Capsule",                    "कैप्सूल"),
        ("Syrup",                      "सिरप"),
        ("Injection",                  "इंजेक्शन"),
        ("Drops",                      "बूँदें"),
        ("Cream/Ointment",            "मलहम"),
        ("Inhaler",                    "इनहेलर"),
        ("Powder",                     "पाउडर"),
    ]

    // MARK: - Tamil Dosage Instructions

    private static let tamilDosageMap: [(english: String, translated: String)] = [
        ("After food",          "சாப்பிட்ட பிறகு"),
        ("Before food",         "சாப்பிடும் முன்"),
        ("With food",           "சாப்பிடும்போது"),
        ("Empty stomach",       "வெறும் வயிற்றில்"),
        ("Morning",             "காலை"),
        ("Afternoon",           "மதியம்"),
        ("Evening",             "மாலை"),
        ("Night",               "இரவு"),
        ("Once daily",          "தினமும் ஒருமுறை"),
        ("Twice daily",         "தினமும் இருமுறை"),
        ("Thrice daily",        "தினமும் மூன்றுமுறை"),
        ("Tablet",              "மாத்திரை"),
        ("Capsule",             "காப்ஸ்யூல்"),
        ("Syrup",               "சிரப்"),
        ("Injection",           "ஊசி"),
        ("Drops",               "சொட்டுகள்"),
        ("Powder",              "பொடி"),
    ]

    // MARK: - Telugu Dosage Instructions

    private static let teluguDosageMap: [(english: String, translated: String)] = [
        ("After food",          "తిన్న తర్వాత"),
        ("Before food",         "తినడానికి ముందు"),
        ("With food",           "తింటూ"),
        ("Empty stomach",       "ఖాళీ కడుపుతో"),
        ("Morning",             "ఉదయం"),
        ("Afternoon",           "మధ్యాహ్నం"),
        ("Evening",             "సాయంత్రం"),
        ("Night",               "రాత్రి"),
        ("Once daily",          "రోజుకు ఒకసారి"),
        ("Twice daily",         "రోజుకు రెండుసార్లు"),
        ("Thrice daily",        "రోజుకు మూడుసార్లు"),
        ("Tablet",              "మాత్ర"),
        ("Capsule",             "క్యాప్సూల్"),
        ("Syrup",               "సిరప్"),
        ("Injection",           "ఇంజెక్షన్"),
        ("Drops",               "చుక్కలు"),
        ("Powder",              "పొడి"),
    ]

    // MARK: - Marathi Dosage Instructions

    private static let marathiDosageMap: [(english: String, translated: String)] = [
        ("After food",          "जेवणानंतर"),
        ("Before food",         "जेवणापूर्वी"),
        ("With food",           "जेवणासोबत"),
        ("Empty stomach",       "रिकाम्या पोटी"),
        ("Morning",             "सकाळ"),
        ("Afternoon",           "दुपार"),
        ("Evening",             "संध्याकाळ"),
        ("Night",               "रात्र"),
        ("Once daily",          "दिवसातून एकदा"),
        ("Twice daily",         "दिवसातून दोनदा"),
        ("Thrice daily",        "दिवसातून तीनदा"),
        ("Tablet",              "गोळी"),
        ("Capsule",             "कॅप्सूल"),
        ("Syrup",               "सिरप"),
        ("Injection",           "इंजेक्शन"),
        ("Drops",               "थेंब"),
        ("Powder",              "पावडर"),
    ]

    // MARK: - Bengali Dosage Instructions

    private static let bengaliDosageMap: [(english: String, translated: String)] = [
        ("After food",          "খাওয়ার পরে"),
        ("Before food",         "খাওয়ার আগে"),
        ("With food",           "খাওয়ার সাথে"),
        ("Empty stomach",       "খালি পেটে"),
        ("Morning",             "সকাল"),
        ("Afternoon",           "দুপুর"),
        ("Evening",             "সন্ধ্যা"),
        ("Night",               "রাত"),
        ("Once daily",          "দিনে একবার"),
        ("Twice daily",         "দিনে দুইবার"),
        ("Thrice daily",        "দিনে তিনবার"),
        ("Tablet",              "ট্যাবলেট"),
        ("Capsule",             "ক্যাপসুল"),
        ("Syrup",               "সিরাপ"),
        ("Injection",           "ইনজেকশন"),
        ("Drops",               "ড্রপ"),
        ("Powder",              "গুঁড়া"),
    ]

    /// Returns the Hindi translation for a dosage instruction, or `nil` if not found.
    func hindiDosageText(for english: String) -> String? {
        let lower = english.lowercased().trimmingCharacters(in: .whitespaces)
        return Self.hindiDosageMap.first { $0.english.lowercased() == lower }?.hindi
    }

    /// Returns the regional translation for a dosage instruction in the given language, or `nil` if not found.
    func regionalDosageText(for english: String, language: AppLanguage) -> String? {
        let lower = english.lowercased().trimmingCharacters(in: .whitespaces)
        let map: [(english: String, translated: String)]
        switch language {
        case .hindi:
            // Reuse the existing Hindi map (field name is .hindi not .translated)
            return Self.hindiDosageMap.first { $0.english.lowercased() == lower }?.hindi
        case .tamil:
            map = Self.tamilDosageMap
        case .telugu:
            map = Self.teluguDosageMap
        case .marathi:
            map = Self.marathiDosageMap
        case .bengali:
            map = Self.bengaliDosageMap
        case .english:
            return nil
        }
        return map.first { $0.english.lowercased() == lower }?.translated
    }

    /// Builds a combined Hindi instruction string from meal timing + dose form.
    func hindiInstructionLine(mealTiming: String?, doseForm: String?) -> String? {
        var parts: [String] = []
        if let meal = mealTiming, let h = hindiDosageText(for: meal) {
            parts.append(h)
        }
        if let form = doseForm, let h = hindiDosageText(for: form) {
            parts.append("(\(h))")
        }
        return parts.isEmpty ? nil : parts.joined(separator: " ")
    }

    /// Builds a combined regional instruction string from meal timing + dose form for any supported language.
    func regionalInstructionLine(mealTiming: String?, doseForm: String?, language: AppLanguage) -> String? {
        var parts: [String] = []
        if let meal = mealTiming, let t = regionalDosageText(for: meal, language: language) {
            parts.append(t)
        }
        if let form = doseForm, let t = regionalDosageText(for: form, language: language) {
            parts.append("(\(t))")
        }
        return parts.isEmpty ? nil : parts.joined(separator: " ")
    }
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
