import Foundation

/// Simple water intake tracking service.
/// Stores glasses per day per profile in UserDefaults.
@Observable
final class WaterTrackingService {

    // MARK: - Constants

    private static let storageKeyPrefix = "mc_water_intake"
    private static let goalKeyPrefix = "mc_water_goal"
    static let defaultGoal = 8 // 8 glasses (~2L)

    // MARK: - Properties

    private let profileId: String?

    /// Current day's glass count (observable)
    var currentGlasses: Int = 0

    // MARK: - Init

    init(profileId: String? = nil) {
        self.profileId = profileId
        currentGlasses = getGlasses(for: Date())
    }

    // MARK: - Storage Keys

    private func storageKey(for date: Date) -> String {
        let dateKey = Self.dateKey(for: date)
        if let profileId {
            return "\(Self.storageKeyPrefix)_\(profileId)_\(dateKey)"
        }
        return "\(Self.storageKeyPrefix)_\(dateKey)"
    }

    private var goalKey: String {
        if let profileId {
            return "\(Self.goalKeyPrefix)_\(profileId)"
        }
        return Self.goalKeyPrefix
    }

    private static func dateKey(for date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: date)
    }

    // MARK: - Public API

    func addGlass(for date: Date = Date()) {
        let current = getGlasses(for: date)
        let newValue = min(current + 1, 12)
        setGlasses(newValue, for: date)
        if Calendar.current.isDateInToday(date) {
            currentGlasses = newValue
        }
    }

    func removeGlass(for date: Date = Date()) {
        let current = getGlasses(for: date)
        let newValue = max(current - 1, 0)
        setGlasses(newValue, for: date)
        if Calendar.current.isDateInToday(date) {
            currentGlasses = newValue
        }
    }

    func getGlasses(for date: Date) -> Int {
        UserDefaults.standard.integer(forKey: storageKey(for: date))
    }

    func setGlasses(_ count: Int, for date: Date) {
        UserDefaults.standard.set(count, forKey: storageKey(for: date))
    }

    func getDailyGoal() -> Int {
        let stored = UserDefaults.standard.integer(forKey: goalKey)
        return stored > 0 ? stored : Self.defaultGoal
    }

    func setDailyGoal(_ goal: Int) {
        UserDefaults.standard.set(max(1, min(goal, 20)), forKey: goalKey)
    }

    /// Refresh current glasses for today (call when date changes)
    func refreshToday() {
        currentGlasses = getGlasses(for: Date())
    }
}
