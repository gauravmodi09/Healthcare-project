import Foundation
import SwiftUI

// MARK: - Journal Entry

struct JournalEntry: Identifiable, Codable {
    let id: UUID
    let date: Date
    let mood: JournalMood
    let energyLevel: Int // 1-5
    let quickNote: String
    let autoInsights: [String] // AI-generated observations

    init(date: Date = Date(), mood: JournalMood, energyLevel: Int, quickNote: String, autoInsights: [String] = []) {
        self.id = UUID()
        self.date = date
        self.mood = mood
        self.energyLevel = energyLevel
        self.quickNote = quickNote
        self.autoInsights = autoInsights
    }
}

enum JournalMood: String, Codable, CaseIterable {
    case terrible
    case bad
    case okay
    case good
    case great

    var emoji: String {
        switch self {
        case .terrible: return "😫"
        case .bad: return "😟"
        case .okay: return "😐"
        case .good: return "🙂"
        case .great: return "😊"
        }
    }

    var label: String {
        switch self {
        case .terrible: return "Terrible"
        case .bad: return "Not Good"
        case .okay: return "Okay"
        case .good: return "Good"
        case .great: return "Great"
        }
    }

    var value: Int {
        switch self {
        case .terrible: return 1
        case .bad: return 2
        case .okay: return 3
        case .good: return 4
        case .great: return 5
        }
    }
}

// MARK: - Weekly Summary

struct WeeklySummary: Identifiable {
    let id = UUID()
    let dateRange: (start: Date, end: Date)
    let overallMood: JournalMood
    let adherenceRate: Double // 0-1
    let topSymptoms: [(name: String, count: Int)]
    let improvements: [String]
    let concerns: [String]
    let aiNarrative: String
}

// MARK: - Health Journal Service

/// On-device health journaling with template-based AI narrative generation.
@Observable
final class HealthJournalService {

    private static let storageKeyPrefix = "mc_health_journal_entries"

    /// The profile ID this service instance is scoped to.
    /// When nil, falls back to a shared key (backward-compatible).
    private let profileId: String?

    private var storageKey: String {
        if let profileId {
            return "\(Self.storageKeyPrefix)_\(profileId)"
        }
        return Self.storageKeyPrefix
    }

    // MARK: - Stored Entries

    var entries: [JournalEntry] = []

    init(profileId: String? = nil) {
        self.profileId = profileId
        loadEntries()
    }

    // MARK: - Create Daily Entry

    func createDailyEntry(
        mood: JournalMood,
        energy: Int,
        note: String,
        doseLogs: [DoseLog],
        symptomLogs: [SymptomLog]
    ) -> JournalEntry {
        let autoInsights = generateAutoInsights(mood: mood, energy: energy, doseLogs: doseLogs, symptomLogs: symptomLogs)

        let entry = JournalEntry(
            date: Date(),
            mood: mood,
            energyLevel: min(max(energy, 1), 5),
            quickNote: note,
            autoInsights: autoInsights
        )

        entries.insert(entry, at: 0)
        saveEntries()
        return entry
    }

    // MARK: - Generate Weekly Summary

    func generateWeeklySummary(
        entries: [JournalEntry],
        doseLogs: [DoseLog],
        symptomLogs: [SymptomLog]
    ) -> WeeklySummary {
        let calendar = Calendar.current
        let now = Date()
        let weekAgo = calendar.date(byAdding: .day, value: -7, to: now)!

        // Filter to this week
        let weekEntries = entries.filter { $0.date >= weekAgo }
        let weekDoseLogs = doseLogs.filter { $0.scheduledTime >= weekAgo && $0.scheduledTime <= now }
        let weekSymptomLogs = symptomLogs.filter { $0.date >= weekAgo }

        // Overall mood — average, rounded to nearest
        let moodAvg: Double = weekEntries.isEmpty ? 3.0 : Double(weekEntries.map { $0.mood.value }.reduce(0, +)) / Double(weekEntries.count)
        let overallMood = moodFromAverage(moodAvg)

        // Adherence
        let pastDoses = weekDoseLogs.filter { $0.scheduledTime <= now }
        let adherenceRate: Double = pastDoses.isEmpty ? 0 : Double(pastDoses.filter { $0.status == .taken }.count) / Double(pastDoses.count)

        // Top symptoms
        var symptomCounts: [String: Int] = [:]
        for log in weekSymptomLogs {
            for symptom in log.symptoms {
                symptomCounts[symptom.name, default: 0] += 1
            }
        }
        let topSymptoms = symptomCounts.sorted { $0.value > $1.value }.prefix(3).map { ($0.key, $0.value) }

        // Improvements and concerns
        let improvements = detectImprovements(entries: weekEntries, doseLogs: weekDoseLogs, symptomLogs: weekSymptomLogs)
        let concerns = detectConcerns(entries: weekEntries, doseLogs: weekDoseLogs, symptomLogs: weekSymptomLogs)

        let summary = WeeklySummary(
            dateRange: (start: weekAgo, end: now),
            overallMood: overallMood,
            adherenceRate: adherenceRate,
            topSymptoms: topSymptoms,
            improvements: improvements,
            concerns: concerns,
            aiNarrative: "" // placeholder, filled below
        )

        let narrative = generateAINarrative(from: summary)

        return WeeklySummary(
            dateRange: summary.dateRange,
            overallMood: summary.overallMood,
            adherenceRate: summary.adherenceRate,
            topSymptoms: summary.topSymptoms,
            improvements: summary.improvements,
            concerns: summary.concerns,
            aiNarrative: narrative
        )
    }

    // MARK: - AI Narrative (Template-Based)

    func generateAINarrative(from summary: WeeklySummary) -> String {
        var parts: [String] = []

        // Opening based on overall mood
        switch summary.overallMood {
        case .great:
            parts.append("This was a great week for you!")
        case .good:
            parts.append("Overall, this was a good week.")
        case .okay:
            parts.append("This week had its ups and downs.")
        case .bad:
            parts.append("This was a tougher week, but tracking it shows real commitment.")
        case .terrible:
            parts.append("This was a rough week. Acknowledging that is the first step to feeling better.")
        }

        // Adherence
        let adherencePct = Int(summary.adherenceRate * 100)
        if summary.adherenceRate >= 0.9 {
            parts.append("Your adherence was excellent at \(adherencePct)% — that consistency is making a real difference.")
        } else if summary.adherenceRate >= 0.7 {
            parts.append("You maintained a solid \(adherencePct)% adherence rate this week.")
        } else if summary.adherenceRate >= 0.5 {
            parts.append("Your adherence was \(adherencePct)% this week — there's room to improve, and small steps help.")
        } else if summary.adherenceRate > 0 {
            parts.append("Adherence was at \(adherencePct)% this week. Try linking your doses to a daily habit like brushing your teeth.")
        }

        // Symptoms
        if !summary.topSymptoms.isEmpty {
            let symptomList = summary.topSymptoms.map { $0.name }.joined(separator: ", ")
            if summary.topSymptoms.count == 1 {
                parts.append("You reported \(symptomList) this week.")
            } else {
                parts.append("Your most reported symptoms were \(symptomList).")
            }
        } else {
            parts.append("No symptoms were logged this week, which is a positive sign!")
        }

        // Improvements
        if !summary.improvements.isEmpty {
            parts.append(summary.improvements.first!)
        }

        // Concerns
        if !summary.concerns.isEmpty {
            parts.append(summary.concerns.first!)
        }

        // Closing
        if summary.overallMood.value >= 4 && summary.adherenceRate >= 0.8 {
            parts.append("Keep up the amazing work!")
        } else {
            parts.append("Every day is a fresh opportunity to take care of yourself.")
        }

        return parts.joined(separator: " ")
    }

    // MARK: - Delete Entry

    func deleteEntry(_ entry: JournalEntry) {
        entries.removeAll { $0.id == entry.id }
        saveEntries()
    }

    // MARK: - Private Helpers

    private func generateAutoInsights(
        mood: JournalMood,
        energy: Int,
        doseLogs: [DoseLog],
        symptomLogs: [SymptomLog]
    ) -> [String] {
        var insights: [String] = []
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())

        // Today's adherence
        let todayDoses = doseLogs.filter { calendar.startOfDay(for: $0.scheduledTime) == today && $0.scheduledTime <= Date() }
        if !todayDoses.isEmpty {
            let takenCount = todayDoses.filter { $0.status == .taken }.count
            if takenCount == todayDoses.count {
                insights.append("All \(takenCount) dose\(takenCount == 1 ? "" : "s") taken today!")
            } else {
                let missed = todayDoses.count - takenCount
                insights.append("\(missed) dose\(missed == 1 ? "" : "s") still pending or missed today.")
            }
        }

        // Mood compared to recent entries
        let recentEntries = entries.prefix(7)
        if recentEntries.count >= 3 {
            let avgMood = Double(recentEntries.map { $0.mood.value }.reduce(0, +)) / Double(recentEntries.count)
            if Double(mood.value) > avgMood + 0.5 {
                insights.append("Your mood is higher than your recent average — nice!")
            } else if Double(mood.value) < avgMood - 0.5 {
                insights.append("Your mood is lower than usual. Take it easy today.")
            }
        }

        // Energy vs mood alignment
        if energy >= 4 && mood.value <= 2 {
            insights.append("Interesting — high energy but low mood. Stress or anxiety might be a factor.")
        } else if energy <= 2 && mood.value >= 4 {
            insights.append("Good mood despite low energy — rest and recovery day might help.")
        }

        // Today's symptoms
        let todaySymptoms = symptomLogs.filter { calendar.startOfDay(for: $0.date) == today }
        if let log = todaySymptoms.last, !log.symptoms.isEmpty {
            let names = log.symptoms.map { $0.name }.joined(separator: ", ")
            insights.append("Today's symptoms: \(names).")
        }

        return insights
    }

    private func detectImprovements(entries: [JournalEntry], doseLogs: [DoseLog], symptomLogs: [SymptomLog]) -> [String] {
        var improvements: [String] = []

        // Mood trend within the week
        if entries.count >= 3 {
            let firstHalf = entries.suffix(entries.count / 2)
            let secondHalf = entries.prefix(entries.count / 2)
            let firstAvg = Double(firstHalf.map { $0.mood.value }.reduce(0, +)) / Double(firstHalf.count)
            let secondAvg = Double(secondHalf.map { $0.mood.value }.reduce(0, +)) / Double(secondHalf.count)
            if secondAvg > firstAvg + 0.3 {
                improvements.append("Your mood improved through the week — a great sign.")
            }
        }

        // Good adherence
        let pastDoses = doseLogs.filter { $0.scheduledTime <= Date() }
        if !pastDoses.isEmpty {
            let rate = Double(pastDoses.filter { $0.status == .taken }.count) / Double(pastDoses.count)
            if rate >= 0.9 {
                improvements.append("Your adherence stayed above 90% — excellent consistency.")
            }
        }

        // Fewer symptoms
        if symptomLogs.count <= 1 {
            improvements.append("Very few symptoms logged this week, which is encouraging.")
        }

        return improvements
    }

    private func detectConcerns(entries: [JournalEntry], doseLogs: [DoseLog], symptomLogs: [SymptomLog]) -> [String] {
        var concerns: [String] = []

        // Low mood trend
        let lowMoodDays = entries.filter { $0.mood.value <= 2 }.count
        if lowMoodDays >= 3 {
            concerns.append("You had \(lowMoodDays) low-mood days this week. If this continues, consider talking to your doctor.")
        }

        // Low energy
        let lowEnergyDays = entries.filter { $0.energyLevel <= 2 }.count
        if lowEnergyDays >= 3 {
            concerns.append("Low energy on \(lowEnergyDays) days this week — make sure you're getting enough rest.")
        }

        // High severity symptoms
        let allSymptoms = symptomLogs.flatMap { $0.symptoms }
        let severeSymptoms = allSymptoms.filter { $0.severity == .severe || $0.severity == .critical }
        let severeSymptomsCount = severeSymptoms.count
        if severeSymptomsCount >= 2 {
            concerns.append("There were \(severeSymptomsCount) severe symptom reports this week. Share this data with your doctor.")
        }

        return concerns
    }

    private func moodFromAverage(_ avg: Double) -> JournalMood {
        switch Int(round(avg)) {
        case 1: return .terrible
        case 2: return .bad
        case 3: return .okay
        case 4: return .good
        default: return .great
        }
    }

    // MARK: - Persistence (UserDefaults)

    private func saveEntries() {
        guard let data = try? JSONEncoder().encode(entries) else { return }
        UserDefaults.standard.set(data, forKey: storageKey)
    }

    private func loadEntries() {
        guard let data = UserDefaults.standard.data(forKey: storageKey),
              let decoded = try? JSONDecoder().decode([JournalEntry].self, from: data) else { return }
        entries = decoded
    }
}
