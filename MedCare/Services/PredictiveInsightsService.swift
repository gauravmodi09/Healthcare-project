import Foundation
import SwiftUI

// MARK: - Health Insight Model

struct HealthInsight: Identifiable {
    let id: UUID
    let title: String
    let description: String
    let insightType: InsightType
    let confidence: Double // 0-1
    let icon: String
    let color: Color

    enum InsightType: String {
        case prediction  // Forward-looking ("you might experience…")
        case pattern     // Historical pattern detected
        case tip         // Actionable advice
        case warning     // Needs attention
    }
}

// MARK: - Predictive Insights Service

/// On-device pattern analysis to predict health outcomes from dose and symptom history.
@Observable
final class PredictiveInsightsService {

    // MARK: - Generate Insights

    func generateInsights(doseLogs: [DoseLog], symptomLogs: [SymptomLog]) -> [HealthInsight] {
        var insights: [HealthInsight] = []

        insights.append(contentsOf: analyzeMissedDoseConsequences(doseLogs: doseLogs, symptomLogs: symptomLogs))
        insights.append(contentsOf: analyzeSideEffectTiming(doseLogs: doseLogs, symptomLogs: symptomLogs))
        insights.append(contentsOf: analyzeBestWorstDays(doseLogs: doseLogs))
        insights.append(contentsOf: analyzeFlareUpPrediction(doseLogs: doseLogs, symptomLogs: symptomLogs))
        insights.append(contentsOf: analyzeAdherenceMomentum(doseLogs: doseLogs))
        insights.append(contentsOf: analyzeTimeOfDayPatterns(doseLogs: doseLogs))

        return insights.sorted { $0.confidence > $1.confidence }
    }

    // MARK: - 1. Missed Dose Consequences

    /// "Your headaches tend to occur 2 days after missing BP meds"
    private func analyzeMissedDoseConsequences(doseLogs: [DoseLog], symptomLogs: [SymptomLog]) -> [HealthInsight] {
        let calendar = Calendar.current
        var insights: [HealthInsight] = []

        // Find all missed/skipped dose dates
        let missedDoses = doseLogs.filter { $0.status == .missed || $0.status == .skipped }
        guard missedDoses.count >= 2 else { return [] }

        let missedDates = Set(missedDoses.map { calendar.startOfDay(for: $0.scheduledTime) })

        // For each symptom type, check if it tends to appear 1-3 days after missed doses
        let allSymptomNames = Set(symptomLogs.flatMap { $0.symptoms.map { $0.name } })

        for symptomName in allSymptomNames {
            let symptomDates = symptomLogs
                .filter { log in log.symptoms.contains { $0.name.lowercased() == symptomName.lowercased() } }
                .map { calendar.startOfDay(for: $0.date) }

            guard symptomDates.count >= 2 else { continue }

            // Check lag of 1-3 days after missed doses
            for lagDays in 1...3 {
                var matchCount = 0
                for missedDate in missedDates {
                    guard let lagDate = calendar.date(byAdding: .day, value: lagDays, to: missedDate) else { continue }
                    if symptomDates.contains(lagDate) {
                        matchCount += 1
                    }
                }

                let matchRate = Double(matchCount) / Double(missedDates.count)
                if matchRate >= 0.4 && matchCount >= 2 {
                    let confidence = min(matchRate, 0.9) * min(Double(matchCount) / 5.0, 1.0)
                    let medicineName = missedDoses.first?.medicine?.brandName ?? "your medicine"

                    insights.append(HealthInsight(
                        id: UUID(),
                        title: "Missed Dose Pattern",
                        description: "\(symptomName) tends to occur \(lagDays) day\(lagDays == 1 ? "" : "s") after missing \(medicineName). Staying consistent can help prevent this.",
                        insightType: .pattern,
                        confidence: confidence,
                        icon: "exclamationmark.triangle.fill",
                        color: MCColors.warning
                    ))
                    break // Only report the strongest lag for each symptom
                }
            }
        }

        return insights
    }

    // MARK: - 2. Side Effect Timing

    /// "Nausea usually peaks 3-4 hours after taking antibiotic"
    private func analyzeSideEffectTiming(doseLogs: [DoseLog], symptomLogs: [SymptomLog]) -> [HealthInsight] {
        let calendar = Calendar.current
        var insights: [HealthInsight] = []

        let takenDoses = doseLogs.filter { $0.status == .taken && $0.actualTime != nil }
        guard takenDoses.count >= 3 else { return [] }

        // Group taken doses by medicine
        let dosesByMedicine = Dictionary(grouping: takenDoses) { $0.medicine?.brandName ?? "Unknown" }

        for (medicineName, doses) in dosesByMedicine {
            guard doses.count >= 3 else { continue }

            let takenDays = Set(doses.compactMap { $0.actualTime }.map { calendar.startOfDay(for: $0) })

            // Find symptom logs on those days
            let symptomLogsOnTakenDays = symptomLogs.filter { takenDays.contains(calendar.startOfDay(for: $0.date)) }
            let allSymptomNames = Set(symptomLogsOnTakenDays.flatMap { $0.symptoms.map { $0.name } })

            for symptomName in allSymptomNames {
                let affectedLogs = symptomLogsOnTakenDays.filter { log in
                    log.symptoms.contains { $0.name.lowercased() == symptomName.lowercased() }
                }

                let rate = Double(affectedLogs.count) / Double(symptomLogsOnTakenDays.count)
                guard rate >= 0.5 && affectedLogs.count >= 3 else { continue }

                // Calculate average time gap between dose and symptom log
                var hourGaps: [Double] = []
                for symptomLog in affectedLogs {
                    let symptomDay = calendar.startOfDay(for: symptomLog.date)
                    let sameDayDoses = doses.filter { calendar.startOfDay(for: $0.actualTime ?? $0.scheduledTime) == symptomDay }
                    for dose in sameDayDoses {
                        guard let actualTime = dose.actualTime else { continue }
                        let gap = symptomLog.date.timeIntervalSince(actualTime) / 3600.0
                        if gap > 0 && gap < 24 {
                            hourGaps.append(gap)
                        }
                    }
                }

                guard hourGaps.count >= 2 else { continue }
                let avgHours = hourGaps.reduce(0, +) / Double(hourGaps.count)
                let roundedHours = Int(round(avgHours))

                if roundedHours >= 1 && roundedHours <= 12 {
                    let confidence = min(rate, 0.85) * min(Double(affectedLogs.count) / 6.0, 1.0)
                    insights.append(HealthInsight(
                        id: UUID(),
                        title: "Side Effect Timing",
                        description: "\(symptomName) usually appears around \(roundedHours) hour\(roundedHours == 1 ? "" : "s") after taking \(medicineName).",
                        insightType: .pattern,
                        confidence: confidence,
                        icon: "clock.arrow.circlepath",
                        color: MCColors.accentCoral
                    ))
                }
            }
        }

        return insights
    }

    // MARK: - 3. Best/Worst Days

    /// "You tend to miss doses on weekends"
    private func analyzeBestWorstDays(doseLogs: [DoseLog]) -> [HealthInsight] {
        let calendar = Calendar.current
        var insights: [HealthInsight] = []

        let pastDoses = doseLogs.filter { $0.scheduledTime <= Date() }
        guard pastDoses.count >= 14 else { return [] }

        // Group by day of week (1=Sunday, 7=Saturday)
        var dayStats: [Int: (taken: Int, total: Int)] = [:]
        for dose in pastDoses {
            let weekday = calendar.component(.weekday, from: dose.scheduledTime)
            var stats = dayStats[weekday, default: (taken: 0, total: 0)]
            stats.total += 1
            if dose.status == .taken { stats.taken += 1 }
            dayStats[weekday] = stats
        }

        let dayNames = ["", "Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday"]

        // Find best and worst days
        var bestDay: (day: Int, rate: Double) = (0, 0)
        var worstDay: (day: Int, rate: Double) = (0, 1.0)

        for (day, stats) in dayStats where stats.total >= 2 {
            let rate = Double(stats.taken) / Double(stats.total)
            if rate > bestDay.rate { bestDay = (day, rate) }
            if rate < worstDay.rate { worstDay = (day, rate) }
        }

        let spread = bestDay.rate - worstDay.rate
        guard spread > 0.15 && bestDay.day > 0 && worstDay.day > 0 else { return insights }

        let confidence = min(spread, 0.85) * min(Double(pastDoses.count) / 30.0, 1.0)

        // Check for weekend pattern
        let weekendDays: Set<Int> = [1, 7] // Sunday, Saturday
        let isWeekendWorst = weekendDays.contains(worstDay.day)

        if isWeekendWorst {
            insights.append(HealthInsight(
                id: UUID(),
                title: "Weekend Dip",
                description: "You tend to miss doses on weekends. Your \(dayNames[worstDay.day]) adherence is \(Int(worstDay.rate * 100))% vs \(Int(bestDay.rate * 100))% on \(dayNames[bestDay.day])s. Try setting a weekend-specific reminder.",
                insightType: .pattern,
                confidence: confidence,
                icon: "calendar.badge.exclamationmark",
                color: MCColors.warning
            ))
        } else {
            insights.append(HealthInsight(
                id: UUID(),
                title: "Day-of-Week Pattern",
                description: "\(dayNames[worstDay.day])s are your toughest day at \(Int(worstDay.rate * 100))% adherence. \(dayNames[bestDay.day])s are your best at \(Int(bestDay.rate * 100))%. Plan ahead for \(dayNames[worstDay.day])s!",
                insightType: .pattern,
                confidence: confidence,
                icon: "calendar",
                color: MCColors.info
            ))
        }

        return insights
    }

    // MARK: - 4. Flare-Up Prediction

    /// "Based on patterns, you might experience symptoms tomorrow — stay on track today"
    private func analyzeFlareUpPrediction(doseLogs: [DoseLog], symptomLogs: [SymptomLog]) -> [HealthInsight] {
        let calendar = Calendar.current
        var insights: [HealthInsight] = []

        let today = calendar.startOfDay(for: Date())

        // Check if today/yesterday had missed doses
        let recentMissed = doseLogs.filter { dose in
            let doseDay = calendar.startOfDay(for: dose.scheduledTime)
            let daysAgo = calendar.dateComponents([.day], from: doseDay, to: today).day ?? 999
            return daysAgo >= 0 && daysAgo <= 1 && (dose.status == .missed || dose.status == .skipped)
        }

        guard !recentMissed.isEmpty else { return [] }

        // Check historical pattern: do symptoms tend to follow missed doses?
        let allMissedDates = Set(doseLogs.filter { $0.status == .missed || $0.status == .skipped }.map { calendar.startOfDay(for: $0.scheduledTime) })
        guard allMissedDates.count >= 3 else { return [] }

        // Count how often symptoms appeared 1-2 days after any missed dose
        var postMissSymptomCount = 0
        for missedDate in allMissedDates {
            for lag in 1...2 {
                guard let lagDate = calendar.date(byAdding: .day, value: lag, to: missedDate) else { continue }
                let hadSymptoms = symptomLogs.contains { log in
                    calendar.startOfDay(for: log.date) == lagDate &&
                    (log.overallFeeling == .terrible || log.overallFeeling == .bad || !log.symptoms.isEmpty)
                }
                if hadSymptoms { postMissSymptomCount += 1; break }
            }
        }

        let predictionRate = Double(postMissSymptomCount) / Double(allMissedDates.count)
        guard predictionRate >= 0.4 else { return [] }

        let confidence = min(predictionRate, 0.8) * min(Double(allMissedDates.count) / 8.0, 1.0)

        insights.append(HealthInsight(
            id: UUID(),
            title: "Heads Up",
            description: "Based on your patterns, you might not feel your best tomorrow after missing a dose today. Taking your next dose on time can help prevent that.",
            insightType: .prediction,
            confidence: confidence,
            icon: "exclamationmark.bubble.fill",
            color: MCColors.accentCoral
        ))

        return insights
    }

    // MARK: - 5. Adherence Momentum

    /// "You're on a great streak! 93% of users who reach 7 days maintain 90%+ adherence"
    private func analyzeAdherenceMomentum(doseLogs: [DoseLog]) -> [HealthInsight] {
        let calendar = Calendar.current
        var insights: [HealthInsight] = []

        // Calculate current streak
        let pastDoses = doseLogs.filter { $0.scheduledTime <= Date() }
        guard !pastDoses.isEmpty else { return [] }

        var streak = 0
        var checkDate = calendar.startOfDay(for: Date())

        for _ in 0..<365 {
            let dayEnd = calendar.date(byAdding: .day, value: 1, to: checkDate)!
            let dayLogs = pastDoses.filter {
                $0.scheduledTime >= checkDate && $0.scheduledTime < dayEnd
            }

            if dayLogs.isEmpty {
                checkDate = calendar.date(byAdding: .day, value: -1, to: checkDate)!
                continue
            }

            let allTaken = dayLogs.allSatisfy { $0.status == .taken }
            if allTaken {
                streak += 1
                checkDate = calendar.date(byAdding: .day, value: -1, to: checkDate)!
            } else {
                break
            }
        }

        // Calculate recent adherence (last 7 days)
        let sevenDaysAgo = calendar.date(byAdding: .day, value: -7, to: Date())!
        let recentDoses = pastDoses.filter { $0.scheduledTime >= sevenDaysAgo }
        let recentAdherence = recentDoses.isEmpty ? 0 : Double(recentDoses.filter { $0.status == .taken }.count) / Double(recentDoses.count)

        if streak >= 14 {
            insights.append(HealthInsight(
                id: UUID(),
                title: "Incredible Streak!",
                description: "You're on a \(streak)-day streak! Research shows habits solidify after 2 weeks. You've built a powerful routine — keep going!",
                insightType: .tip,
                confidence: 0.95,
                icon: "flame.fill",
                color: MCColors.success
            ))
        } else if streak >= 7 {
            insights.append(HealthInsight(
                id: UUID(),
                title: "Momentum Building",
                description: "Amazing \(streak)-day streak! Most people who reach 7 days maintain 90%+ adherence long-term. You're building a great habit.",
                insightType: .tip,
                confidence: 0.90,
                icon: "bolt.fill",
                color: MCColors.success
            ))
        } else if streak >= 3 {
            insights.append(HealthInsight(
                id: UUID(),
                title: "Getting Consistent",
                description: "\(streak) days strong! Keep it up — just \(7 - streak) more days to build a solid weekly habit.",
                insightType: .tip,
                confidence: 0.80,
                icon: "arrow.up.right",
                color: MCColors.primaryTeal
            ))
        } else if streak == 0 && recentAdherence < 0.5 && recentDoses.count >= 3 {
            insights.append(HealthInsight(
                id: UUID(),
                title: "Fresh Start",
                description: "It's been a tough stretch, but today is a new day. Taking even one dose on time starts a new streak. You've got this!",
                insightType: .tip,
                confidence: 0.85,
                icon: "sunrise.fill",
                color: MCColors.primaryTeal
            ))
        }

        return insights
    }

    // MARK: - 6. Time-of-Day Patterns

    /// Analyzes whether morning vs evening adherence differs
    private func analyzeTimeOfDayPatterns(doseLogs: [DoseLog]) -> [HealthInsight] {
        let calendar = Calendar.current
        var insights: [HealthInsight] = []

        let pastDoses = doseLogs.filter { $0.scheduledTime <= Date() }
        guard pastDoses.count >= 10 else { return [] }

        // Split into morning (before noon) and afternoon/evening
        let morningDoses = pastDoses.filter { calendar.component(.hour, from: $0.scheduledTime) < 12 }
        let eveningDoses = pastDoses.filter { calendar.component(.hour, from: $0.scheduledTime) >= 17 }

        guard morningDoses.count >= 5 && eveningDoses.count >= 5 else { return [] }

        let morningRate = Double(morningDoses.filter { $0.status == .taken }.count) / Double(morningDoses.count)
        let eveningRate = Double(eveningDoses.filter { $0.status == .taken }.count) / Double(eveningDoses.count)

        let diff = abs(morningRate - eveningRate)
        guard diff > 0.15 else { return [] }

        let betterTime = morningRate > eveningRate ? "morning" : "evening"
        let worseTime = morningRate > eveningRate ? "evening" : "morning"
        let betterRate = Int(max(morningRate, eveningRate) * 100)
        let worseRate = Int(min(morningRate, eveningRate) * 100)

        let confidence = min(diff, 0.8) * min(Double(pastDoses.count) / 20.0, 1.0)

        insights.append(HealthInsight(
            id: UUID(),
            title: "Time-of-Day Pattern",
            description: "Your \(betterTime) doses are at \(betterRate)% adherence, but \(worseTime) drops to \(worseRate)%. Try setting a specific \(worseTime) alarm.",
            insightType: .pattern,
            confidence: confidence,
            icon: "clock.fill",
            color: MCColors.info
        ))

        return insights
    }
}
