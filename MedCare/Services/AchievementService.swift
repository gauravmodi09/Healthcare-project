import Foundation

/// Phase 6 Engagement: Achievement/badge system for gamifying health management
@Observable
final class AchievementService {

    static let shared = AchievementService()

    @ObservationIgnored private(set) var unlockedAchievements: [Achievement] = []
    @ObservationIgnored private(set) var availableAchievements: [Achievement] = []
    @ObservationIgnored private(set) var allAchievements: [Achievement] = []

    // UserDefaults key for persisting unlocked achievements
    private let unlockedKey = "com.medcare.unlockedAchievements"

    struct Achievement: Identifiable, Codable {
        let id: String
        let name: String
        let description: String
        let icon: String // SF Symbol
        let category: AchievementCategory
        let requirement: String
        var isUnlocked: Bool
        var unlockedDate: Date?
        var progress: Double // 0-1
    }

    enum AchievementCategory: String, CaseIterable, Codable {
        case streak = "Streaks"
        case adherence = "Adherence"
        case tracking = "Tracking"
        case family = "Family"
        case milestone = "Milestones"

        var icon: String {
            switch self {
            case .streak: return "flame.fill"
            case .adherence: return "checkmark.seal.fill"
            case .tracking: return "list.clipboard.fill"
            case .family: return "person.3.fill"
            case .milestone: return "flag.fill"
            }
        }

        var color: String {
            switch self {
            case .streak: return "FF6B6B"
            case .adherence: return "34C759"
            case .tracking: return "007AFF"
            case .family: return "AF52DE"
            case .milestone: return "FFD700"
            }
        }
    }

    // MARK: - Input Data

    struct AchievementInput {
        let currentStreak: Int
        let longestStreak: Int
        let totalDosesTaken: Int
        let totalDosesScheduled: Int
        let perfectDays: Int // days with 100% adherence
        let perfectWeeks: Int // weeks with 100% adherence
        let daysWithSymptomLogs: Int
        let documentsUploaded: Int
        let episodesCompleted: Int
        let episodesWithAllFields: Int
        let profilesManaged: Int
        let morningDosesOnTimeCount: Int // 7+ means achievement
        let eveningDosesOnTimeCount: Int // 7+ means achievement
        let hadGapOfThreePlusDays: Bool
        let resumedAfterGap: Bool
        let missedDaysThisWeek: Int // for grace period logic
        let totalDaysTracked: Int
    }

    // MARK: - Initialization

    init() {
        allAchievements = Self.defineAchievements()
        loadUnlockedState()
    }

    // MARK: - Achievement Definitions (20+)

    private static func defineAchievements() -> [Achievement] {
        [
            // STREAKS (6)
            Achievement(id: "streak_3", name: "First Steps", description: "Maintain a 3-day adherence streak", icon: "figure.walk", category: .streak, requirement: "3 consecutive days of full adherence", isUnlocked: false, unlockedDate: nil, progress: 0),
            Achievement(id: "streak_7", name: "Weekly Warrior", description: "Maintain a 7-day adherence streak", icon: "flame", category: .streak, requirement: "7 consecutive days of full adherence", isUnlocked: false, unlockedDate: nil, progress: 0),
            Achievement(id: "streak_14", name: "Two Weeks Strong", description: "Maintain a 14-day adherence streak", icon: "flame.fill", category: .streak, requirement: "14 consecutive days of full adherence", isUnlocked: false, unlockedDate: nil, progress: 0),
            Achievement(id: "streak_30", name: "Monthly Champion", description: "Maintain a 30-day adherence streak", icon: "trophy", category: .streak, requirement: "30 consecutive days of full adherence", isUnlocked: false, unlockedDate: nil, progress: 0),
            Achievement(id: "streak_100", name: "Century Club", description: "Maintain a 100-day adherence streak", icon: "trophy.fill", category: .streak, requirement: "100 consecutive days of full adherence", isUnlocked: false, unlockedDate: nil, progress: 0),
            Achievement(id: "streak_365", name: "Yearly Hero", description: "Maintain a 365-day adherence streak", icon: "star.circle.fill", category: .streak, requirement: "365 consecutive days of full adherence", isUnlocked: false, unlockedDate: nil, progress: 0),

            // ADHERENCE (3)
            Achievement(id: "perfect_day", name: "Perfect Day", description: "Take 100% of your doses in a single day", icon: "checkmark.circle.fill", category: .adherence, requirement: "100% adherence in one day", isUnlocked: false, unlockedDate: nil, progress: 0),
            Achievement(id: "perfect_week", name: "Perfect Week", description: "Take 100% of your doses for an entire week", icon: "checkmark.seal.fill", category: .adherence, requirement: "100% adherence for 7 consecutive days", isUnlocked: false, unlockedDate: nil, progress: 0),
            Achievement(id: "comeback_king", name: "Comeback King", description: "Resume taking medicine after a 3+ day gap", icon: "arrow.uturn.up.circle.fill", category: .adherence, requirement: "Resume adherence after missing 3+ days", isUnlocked: false, unlockedDate: nil, progress: 0),

            // TRACKING (4)
            Achievement(id: "symptom_scout", name: "Symptom Scout", description: "Log symptoms for 7 different days", icon: "list.clipboard", category: .tracking, requirement: "Log symptoms on 7 different days", isUnlocked: false, unlockedDate: nil, progress: 0),
            Achievement(id: "symptom_veteran", name: "Symptom Veteran", description: "Log symptoms for 30 different days", icon: "list.clipboard.fill", category: .tracking, requirement: "Log symptoms on 30 different days", isUnlocked: false, unlockedDate: nil, progress: 0),
            Achievement(id: "document_pro", name: "Document Pro", description: "Upload 5 medical documents", icon: "doc.text.fill", category: .tracking, requirement: "Upload 5 documents to your episodes", isUnlocked: false, unlockedDate: nil, progress: 0),
            Achievement(id: "complete_care", name: "Complete Care", description: "Fill all fields in an episode", icon: "text.badge.checkmark", category: .tracking, requirement: "Complete every field in an episode", isUnlocked: false, unlockedDate: nil, progress: 0),

            // FAMILY (2)
            Achievement(id: "family_guardian", name: "Family Guardian", description: "Manage medicine for a family member", icon: "person.2.fill", category: .family, requirement: "Create and manage a second profile", isUnlocked: false, unlockedDate: nil, progress: 0),
            Achievement(id: "care_circle", name: "Care Circle", description: "Manage 3 or more profiles", icon: "person.3.fill", category: .family, requirement: "Have 3+ active profiles", isUnlocked: false, unlockedDate: nil, progress: 0),

            // MILESTONES (6)
            Achievement(id: "first_dose", name: "First Dose", description: "Log your very first dose", icon: "pill.fill", category: .milestone, requirement: "Take and log your first dose", isUnlocked: false, unlockedDate: nil, progress: 0),
            Achievement(id: "dose_50", name: "Half Century", description: "Take 50 doses", icon: "50.circle.fill", category: .milestone, requirement: "Take 50 total doses", isUnlocked: false, unlockedDate: nil, progress: 0),
            Achievement(id: "dose_500", name: "Dose Master", description: "Take 500 doses", icon: "star.fill", category: .milestone, requirement: "Take 500 total doses", isUnlocked: false, unlockedDate: nil, progress: 0),
            Achievement(id: "early_bird", name: "Early Bird", description: "Take morning meds on time for 7 days", icon: "sunrise.fill", category: .milestone, requirement: "Morning doses on time for 7 days", isUnlocked: false, unlockedDate: nil, progress: 0),
            Achievement(id: "night_owl", name: "Night Owl", description: "Take evening meds on time for 7 days", icon: "moon.stars.fill", category: .milestone, requirement: "Evening doses on time for 7 days", isUnlocked: false, unlockedDate: nil, progress: 0),
            Achievement(id: "episode_master", name: "Episode Master", description: "Complete a full treatment episode", icon: "flag.checkered", category: .milestone, requirement: "Complete an episode from start to finish", isUnlocked: false, unlockedDate: nil, progress: 0),
        ]
    }

    // MARK: - Check Achievements

    /// Evaluates all achievement conditions and unlocks those that are met.
    /// Returns newly unlocked achievements (for showing notifications).
    @discardableResult
    func checkAchievements(input: AchievementInput) -> [Achievement] {
        var newlyUnlocked: [Achievement] = []

        // Streak with grace period: allow 1 miss per week without breaking streak
        let effectiveStreak = calculateStreakWithGrace(
            rawStreak: input.currentStreak,
            missedThisWeek: input.missedDaysThisWeek,
            totalDaysTracked: input.totalDaysTracked
        )

        for i in allAchievements.indices {
            let achievement = allAchievements[i]
            guard !achievement.isUnlocked else { continue }

            let (met, progress) = evaluateCondition(id: achievement.id, input: input, effectiveStreak: effectiveStreak)
            allAchievements[i].progress = progress

            if met {
                allAchievements[i].isUnlocked = true
                allAchievements[i].unlockedDate = Date()
                allAchievements[i].progress = 1.0
                newlyUnlocked.append(allAchievements[i])
            }
        }

        // Update derived lists
        unlockedAchievements = allAchievements.filter { $0.isUnlocked }
        availableAchievements = allAchievements.filter { !$0.isUnlocked }

        // Persist
        saveUnlockedState()

        return newlyUnlocked
    }

    // MARK: - Condition Evaluation

    private func evaluateCondition(id: String, input: AchievementInput, effectiveStreak: Int) -> (met: Bool, progress: Double) {
        switch id {
        // Streaks
        case "streak_3":
            return (effectiveStreak >= 3, min(Double(effectiveStreak) / 3.0, 1.0))
        case "streak_7":
            return (effectiveStreak >= 7, min(Double(effectiveStreak) / 7.0, 1.0))
        case "streak_14":
            return (effectiveStreak >= 14, min(Double(effectiveStreak) / 14.0, 1.0))
        case "streak_30":
            return (effectiveStreak >= 30, min(Double(effectiveStreak) / 30.0, 1.0))
        case "streak_100":
            return (effectiveStreak >= 100, min(Double(effectiveStreak) / 100.0, 1.0))
        case "streak_365":
            return (effectiveStreak >= 365, min(Double(effectiveStreak) / 365.0, 1.0))

        // Adherence
        case "perfect_day":
            return (input.perfectDays >= 1, input.perfectDays >= 1 ? 1.0 : 0)
        case "perfect_week":
            return (input.perfectWeeks >= 1, input.perfectWeeks >= 1 ? 1.0 : 0)
        case "comeback_king":
            return (input.hadGapOfThreePlusDays && input.resumedAfterGap, input.resumedAfterGap ? 1.0 : 0)

        // Tracking
        case "symptom_scout":
            return (input.daysWithSymptomLogs >= 7, min(Double(input.daysWithSymptomLogs) / 7.0, 1.0))
        case "symptom_veteran":
            return (input.daysWithSymptomLogs >= 30, min(Double(input.daysWithSymptomLogs) / 30.0, 1.0))
        case "document_pro":
            return (input.documentsUploaded >= 5, min(Double(input.documentsUploaded) / 5.0, 1.0))
        case "complete_care":
            return (input.episodesWithAllFields >= 1, input.episodesWithAllFields >= 1 ? 1.0 : 0)

        // Family
        case "family_guardian":
            return (input.profilesManaged >= 2, min(Double(input.profilesManaged) / 2.0, 1.0))
        case "care_circle":
            return (input.profilesManaged >= 3, min(Double(input.profilesManaged) / 3.0, 1.0))

        // Milestones
        case "first_dose":
            return (input.totalDosesTaken >= 1, input.totalDosesTaken >= 1 ? 1.0 : 0)
        case "dose_50":
            return (input.totalDosesTaken >= 50, min(Double(input.totalDosesTaken) / 50.0, 1.0))
        case "dose_500":
            return (input.totalDosesTaken >= 500, min(Double(input.totalDosesTaken) / 500.0, 1.0))
        case "early_bird":
            return (input.morningDosesOnTimeCount >= 7, min(Double(input.morningDosesOnTimeCount) / 7.0, 1.0))
        case "night_owl":
            return (input.eveningDosesOnTimeCount >= 7, min(Double(input.eveningDosesOnTimeCount) / 7.0, 1.0))
        case "episode_master":
            return (input.episodesCompleted >= 1, input.episodesCompleted >= 1 ? 1.0 : 0)

        default:
            return (false, 0)
        }
    }

    // MARK: - Streak Grace Period

    /// Grace period: 1 miss per week doesn't break the streak.
    /// If the user missed <= 1 day this week, the streak continues.
    private func calculateStreakWithGrace(rawStreak: Int, missedThisWeek: Int, totalDaysTracked: Int) -> Int {
        // If tracking for less than a week, use raw streak
        guard totalDaysTracked >= 7 else { return rawStreak }

        // Grace: allow 1 missed day per 7-day period without breaking streak
        if missedThisWeek <= 1 && rawStreak == 0 {
            // The raw streak broke but within grace — estimate effective streak
            // We return at least the days tracked this week minus misses
            return max(totalDaysTracked - missedThisWeek, 0)
        }

        // If raw streak is active and within grace, keep it
        if missedThisWeek <= 1 {
            return rawStreak + missedThisWeek // credit back the graceful miss
        }

        return rawStreak
    }

    // MARK: - Persistence

    private func saveUnlockedState() {
        let unlockedIds = allAchievements.filter { $0.isUnlocked }.map { $0.id }
        let dates = Dictionary(uniqueKeysWithValues: allAchievements.compactMap { a -> (String, Date)? in
            guard let date = a.unlockedDate else { return nil }
            return (a.id, date)
        })
        UserDefaults.standard.set(unlockedIds, forKey: unlockedKey)
        if let data = try? JSONEncoder().encode(dates) {
            UserDefaults.standard.set(data, forKey: "\(unlockedKey).dates")
        }
    }

    private func loadUnlockedState() {
        let unlockedIds = UserDefaults.standard.stringArray(forKey: unlockedKey) ?? []
        var dates: [String: Date] = [:]
        if let data = UserDefaults.standard.data(forKey: "\(unlockedKey).dates"),
           let decoded = try? JSONDecoder().decode([String: Date].self, from: data) {
            dates = decoded
        }

        for i in allAchievements.indices {
            if unlockedIds.contains(allAchievements[i].id) {
                allAchievements[i].isUnlocked = true
                allAchievements[i].unlockedDate = dates[allAchievements[i].id]
                allAchievements[i].progress = 1.0
            }
        }

        unlockedAchievements = allAchievements.filter { $0.isUnlocked }
        availableAchievements = allAchievements.filter { !$0.isUnlocked }
    }

    // MARK: - Helpers

    func achievement(byId id: String) -> Achievement? {
        allAchievements.first { $0.id == id }
    }

    func achievements(for category: AchievementCategory) -> [Achievement] {
        allAchievements.filter { $0.category == category }
    }

    var totalUnlocked: Int { unlockedAchievements.count }
    var totalAvailable: Int { allAchievements.count }
    var completionPercentage: Double {
        guard !allAchievements.isEmpty else { return 0 }
        return Double(totalUnlocked) / Double(totalAvailable)
    }

    /// Reset all achievements (for testing/debug)
    func resetAll() {
        allAchievements = Self.defineAchievements()
        unlockedAchievements = []
        availableAchievements = allAchievements
        UserDefaults.standard.removeObject(forKey: unlockedKey)
        UserDefaults.standard.removeObject(forKey: "\(unlockedKey).dates")
    }
}
