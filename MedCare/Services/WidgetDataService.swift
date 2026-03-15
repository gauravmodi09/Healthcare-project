import Foundation

/// Enhancement #6: Widget & Watch Complications Data Provider
/// Provides data for iOS home screen widgets and Apple Watch complications
final class WidgetDataService {

    struct WidgetData: Codable {
        let nextDose: NextDoseInfo?
        let todayProgress: TodayProgress
        let activeEpisodes: Int
        let adherenceStreak: Int
        let updatedAt: Date
    }

    struct NextDoseInfo: Codable {
        let medicineName: String
        let dosage: String
        let scheduledTime: Date
        let episodeName: String
    }

    struct TodayProgress: Codable {
        let taken: Int
        let total: Int
        let percentage: Double
    }

    private let suiteName = "group.com.medcare.shared"

    /// Update widget data (call after any dose status change)
    func updateWidgetData(for profile: UserProfile) {
        let calendar = Calendar.current
        let now = Date()
        let startOfDay = calendar.startOfDay(for: now)
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!

        // Get today's doses
        let todayDoses = profile.episodes
            .flatMap { $0.medicines }
            .filter { $0.isActive }
            .flatMap { $0.doseLogs }
            .filter { $0.scheduledTime >= startOfDay && $0.scheduledTime < endOfDay }

        let taken = todayDoses.filter { $0.status == .taken }.count
        let total = todayDoses.count

        // Find next upcoming dose
        let nextDose = todayDoses
            .filter { $0.scheduledTime > now && $0.status == .pending }
            .sorted { $0.scheduledTime < $1.scheduledTime }
            .first

        let nextDoseInfo: NextDoseInfo? = nextDose.flatMap { dose in
            guard let medicine = dose.medicine else { return nil }
            return NextDoseInfo(
                medicineName: medicine.brandName,
                dosage: medicine.dosage,
                scheduledTime: dose.scheduledTime,
                episodeName: medicine.episode?.title ?? ""
            )
        }

        let widgetData = WidgetData(
            nextDose: nextDoseInfo,
            todayProgress: TodayProgress(
                taken: taken,
                total: total,
                percentage: total > 0 ? Double(taken) / Double(total) : 0
            ),
            activeEpisodes: profile.episodes.filter { $0.status == .active }.count,
            adherenceStreak: calculateStreak(profile: profile),
            updatedAt: now
        )

        // Save to shared UserDefaults for widget access
        if let data = try? JSONEncoder().encode(widgetData),
           let defaults = UserDefaults(suiteName: suiteName) {
            defaults.set(data, forKey: "widgetData")
        }
    }

    private func calculateStreak(profile: UserProfile) -> Int {
        let calendar = Calendar.current
        var streak = 0
        var checkDate = calendar.startOfDay(for: Date())

        for _ in 0..<365 {
            let dayDoses = profile.episodes
                .flatMap { $0.medicines }
                .flatMap { $0.doseLogs }
                .filter { calendar.isDate($0.scheduledTime, inSameDayAs: checkDate) }

            guard !dayDoses.isEmpty else { break }
            if dayDoses.allSatisfy({ $0.status == .taken }) {
                streak += 1
                checkDate = calendar.date(byAdding: .day, value: -1, to: checkDate)!
            } else {
                break
            }
        }
        return streak
    }
}
