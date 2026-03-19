import Foundation

// MARK: - Models

struct MoodEntry: Codable, Identifiable, Hashable {
    let id: UUID
    let date: Date
    let moodScore: Int        // 1-5
    let energyLevel: Int      // 1-5
    let anxietyLevel: Int     // 1-5
    let sleepQuality: Int     // 1-5
    let note: String?
    let medicinesTakenToday: [String]

    init(
        id: UUID = UUID(),
        date: Date = Date(),
        moodScore: Int,
        energyLevel: Int,
        anxietyLevel: Int,
        sleepQuality: Int,
        note: String? = nil,
        medicinesTakenToday: [String] = []
    ) {
        self.id = id
        self.date = date
        self.moodScore = min(max(moodScore, 1), 5)
        self.energyLevel = min(max(energyLevel, 1), 5)
        self.anxietyLevel = min(max(anxietyLevel, 1), 5)
        self.sleepQuality = min(max(sleepQuality, 1), 5)
        self.note = note
        self.medicinesTakenToday = medicinesTakenToday
    }
}

enum CorrelationType: String, Codable {
    case positive
    case negative
    case neutral
}

struct MoodCorrelation: Identifiable {
    let id = UUID()
    let medicineName: String
    let avgMoodWithMedicine: Double
    let avgMoodWithoutMedicine: Double
    let correlation: CorrelationType
    let confidence: Double       // 0.0 - 1.0
    let insight: String
}

enum MoodTrend {
    case improving(delta: Double)
    case stable(delta: Double)
    case declining(delta: Double)

    var label: String {
        switch self {
        case .improving: return "Improving"
        case .stable: return "Stable"
        case .declining: return "Declining"
        }
    }

    var icon: String {
        switch self {
        case .improving: return "arrow.up.right"
        case .stable: return "arrow.right"
        case .declining: return "arrow.down.right"
        }
    }

    var delta: Double {
        switch self {
        case .improving(let d), .stable(let d), .declining(let d): return d
        }
    }
}

// MARK: - Service

@Observable
final class MoodTrackingService {

    private static let storageKey = "com.medcare.moodEntries"

    // MARK: - Public API

    func logMood(
        mood: Int,
        energy: Int,
        anxiety: Int,
        sleep: Int,
        note: String? = nil,
        medicines: [String] = []
    ) {
        let entry = MoodEntry(
            moodScore: mood,
            energyLevel: energy,
            anxietyLevel: anxiety,
            sleepQuality: sleep,
            note: note,
            medicinesTakenToday: medicines
        )
        var existing = loadAll()
        existing.append(entry)
        save(existing)
    }

    func getMoodHistory(days: Int) -> [MoodEntry] {
        let cutoff = Calendar.current.date(byAdding: .day, value: -days, to: Date()) ?? Date()
        return loadAll()
            .filter { $0.date >= cutoff }
            .sorted { $0.date < $1.date }
    }

    // MARK: - Correlation Analysis

    func analyzeMoodMedicineCorrelation(moodEntries: [MoodEntry]) -> [MoodCorrelation] {
        // Collect all unique medicine names
        let allMedicines = Set(moodEntries.flatMap { $0.medicinesTakenToday })
        guard !allMedicines.isEmpty else { return [] }

        var correlations: [MoodCorrelation] = []

        for medicine in allMedicines {
            let withMedicine = moodEntries.filter { $0.medicinesTakenToday.contains(medicine) }
            let withoutMedicine = moodEntries.filter { !$0.medicinesTakenToday.contains(medicine) }

            // Need at least 5 data points each way for meaningful correlation
            guard withMedicine.count >= 5, withoutMedicine.count >= 5 else { continue }

            let avgWith = Double(withMedicine.map(\.moodScore).reduce(0, +)) / Double(withMedicine.count)
            let avgWithout = Double(withoutMedicine.map(\.moodScore).reduce(0, +)) / Double(withoutMedicine.count)

            let diff = avgWith - avgWithout
            let correlation: CorrelationType
            if diff > 0.3 {
                correlation = .positive
            } else if diff < -0.3 {
                correlation = .negative
            } else {
                correlation = .neutral
            }

            // Confidence based on sample size (more data = higher confidence, capped at 1.0)
            let totalSamples = withMedicine.count + withoutMedicine.count
            let confidence = min(Double(totalSamples) / 60.0, 1.0)

            let insight = generateInsight(
                medicineName: medicine,
                avgWith: avgWith,
                avgWithout: avgWithout,
                correlation: correlation,
                withCount: withMedicine.count,
                withoutCount: withoutMedicine.count
            )

            correlations.append(MoodCorrelation(
                medicineName: medicine,
                avgMoodWithMedicine: avgWith,
                avgMoodWithoutMedicine: avgWithout,
                correlation: correlation,
                confidence: confidence,
                insight: insight
            ))
        }

        return correlations.sorted { $0.confidence > $1.confidence }
    }

    // MARK: - Mood Trend

    func getMoodTrend(days: Int) -> MoodTrend {
        let entries = getMoodHistory(days: days)
        guard entries.count >= 2 else { return .stable(delta: 0) }

        let midpoint = entries.count / 2
        let firstHalf = Array(entries.prefix(midpoint))
        let secondHalf = Array(entries.suffix(from: midpoint))

        let firstAvg = Double(firstHalf.map(\.moodScore).reduce(0, +)) / Double(firstHalf.count)
        let secondAvg = Double(secondHalf.map(\.moodScore).reduce(0, +)) / Double(secondHalf.count)

        let delta = secondAvg - firstAvg

        if delta > 0.3 {
            return .improving(delta: delta)
        } else if delta < -0.3 {
            return .declining(delta: delta)
        } else {
            return .stable(delta: delta)
        }
    }

    // MARK: - Weekly Summary

    func getWeeklyMoodSummary() -> String {
        let thisWeek = getMoodHistory(days: 7)
        let lastWeek = getMoodHistory(days: 14).filter {
            let sevenDaysAgo = Calendar.current.date(byAdding: .day, value: -7, to: Date()) ?? Date()
            return $0.date < sevenDaysAgo
        }

        guard !thisWeek.isEmpty else {
            return "No mood data this week. Start logging to see insights!"
        }

        let thisWeekAvg = Double(thisWeek.map(\.moodScore).reduce(0, +)) / Double(thisWeek.count)
        let formattedAvg = String(format: "%.1f", thisWeekAvg)

        var summary = "Your mood averaged \(formattedAvg)/5 this week"

        if !lastWeek.isEmpty {
            let lastWeekAvg = Double(lastWeek.map(\.moodScore).reduce(0, +)) / Double(lastWeek.count)
            let formattedLastAvg = String(format: "%.1f", lastWeekAvg)
            if thisWeekAvg > lastWeekAvg + 0.2 {
                summary += " (\u{2191} from \(formattedLastAvg))"
            } else if thisWeekAvg < lastWeekAvg - 0.2 {
                summary += " (\u{2193} from \(formattedLastAvg))"
            } else {
                summary += " (steady from \(formattedLastAvg))"
            }
        }
        summary += "."

        // Sleep quality insight
        let highSleepDays = thisWeek.filter { $0.sleepQuality >= 4 }
        let lowSleepDays = thisWeek.filter { $0.sleepQuality <= 2 }
        if highSleepDays.count >= 3 {
            let highSleepMoodAvg = Double(highSleepDays.map(\.moodScore).reduce(0, +)) / Double(highSleepDays.count)
            if highSleepMoodAvg >= 3.5 {
                summary += " Better mood on days with good sleep quality."
            }
        } else if lowSleepDays.count >= 2 {
            summary += " Consider improving sleep for a potential mood boost."
        }

        // Medicine insight
        let daysWithMedicine = thisWeek.filter { !$0.medicinesTakenToday.isEmpty }
        let daysWithoutMedicine = thisWeek.filter { $0.medicinesTakenToday.isEmpty }
        if daysWithMedicine.count >= 3, daysWithoutMedicine.count >= 2 {
            let withAvg = Double(daysWithMedicine.map(\.moodScore).reduce(0, +)) / Double(daysWithMedicine.count)
            let withoutAvg = Double(daysWithoutMedicine.map(\.moodScore).reduce(0, +)) / Double(daysWithoutMedicine.count)
            if withAvg > withoutAvg + 0.5 {
                summary += " Better mood on days you took your medicines."
            }
        }

        return summary
    }

    // MARK: - Streak

    func getCurrentStreak() -> Int {
        let entries = loadAll().sorted { $0.date > $1.date }
        guard !entries.isEmpty else { return 0 }

        let calendar = Calendar.current
        var streak = 0
        var checkDate = calendar.startOfDay(for: Date())

        for _ in 0..<365 {
            let hasEntry = entries.contains {
                calendar.isDate($0.date, inSameDayAs: checkDate)
            }
            if hasEntry {
                streak += 1
                checkDate = calendar.date(byAdding: .day, value: -1, to: checkDate)!
            } else {
                break
            }
        }

        return streak
    }

    // MARK: - Private Helpers

    private func generateInsight(
        medicineName: String,
        avgWith: Double,
        avgWithout: Double,
        correlation: CorrelationType,
        withCount: Int,
        withoutCount: Int
    ) -> String {
        let diff = abs(avgWith - avgWithout)
        let formattedWith = String(format: "%.1f", avgWith)
        let formattedWithout = String(format: "%.1f", avgWithout)

        switch correlation {
        case .positive:
            if diff > 1.0 {
                return "Strong positive pattern: Your mood averages \(formattedWith)/5 on days with \(medicineName) vs \(formattedWithout)/5 without. Taking it consistently may help your wellbeing."
            } else {
                return "Your mood tends to be slightly better on days you take \(medicineName) (\(formattedWith) vs \(formattedWithout))."
            }
        case .negative:
            if diff > 1.0 {
                return "Your mood averages \(formattedWith)/5 on days with \(medicineName) vs \(formattedWithout)/5 without. Consider discussing this with your doctor."
            } else {
                return "Slight mood dip on days you take \(medicineName) (\(formattedWith) vs \(formattedWithout)). This may be coincidental."
            }
        case .neutral:
            return "No significant mood difference with \(medicineName) (avg \(formattedWith) with, \(formattedWithout) without). Based on \(withCount + withoutCount) days of data."
        }
    }

    // MARK: - Persistence (UserDefaults)

    private func loadAll() -> [MoodEntry] {
        guard let data = UserDefaults.standard.data(forKey: Self.storageKey) else { return [] }
        return (try? JSONDecoder().decode([MoodEntry].self, from: data)) ?? []
    }

    private func save(_ entries: [MoodEntry]) {
        guard let data = try? JSONEncoder().encode(entries) else { return }
        UserDefaults.standard.set(data, forKey: Self.storageKey)
    }
}
