import Foundation
import SwiftData

/// Phase 4 Intelligence: Composite health score (0-100) based on adherence, symptoms, streaks, and completeness
@Observable
final class HealthScoreService {

    // MARK: - Calculate Score

    func calculateScore(
        adherencePercentage: Double,
        symptomTrend: SymptomTrend,
        currentStreak: Int,
        completenessScore: Double
    ) -> HealthScore {
        // Adherence component (40% weight, max 40 points)
        let adherenceComponent = Int((min(max(adherencePercentage, 0), 1.0)) * 40)

        // Symptom component (25% weight, max 25 points)
        let symptomComponent: Int = {
            switch symptomTrend {
            case .improving: return 25
            case .stable: return 18
            case .worsening: return 8
            case .noData: return 12 // neutral — no data shouldn't punish
            }
        }()

        // Streak component (20% weight, max 20 points)
        let streakComponent: Int = {
            switch currentStreak {
            case 0: return 0
            case 1...2: return 5
            case 3...6: return 10
            case 7...13: return 14
            case 14...29: return 17
            default: return 20 // 30+ days
            }
        }()

        // Completeness component (15% weight, max 15 points)
        let completenessComponent = Int((min(max(completenessScore, 0), 1.0)) * 15)

        let total = min(adherenceComponent + symptomComponent + streakComponent + completenessComponent, 100)
        let grade = HealthGrade.from(score: total)
        let trend = determineTrend(adherence: adherencePercentage, symptomTrend: symptomTrend, streak: currentStreak)
        let tip = generateTip(
            adherencePercentage: adherencePercentage,
            symptomTrend: symptomTrend,
            currentStreak: currentStreak,
            completenessScore: completenessScore,
            total: total
        )

        return HealthScore(
            total: total,
            adherenceComponent: adherenceComponent,
            symptomComponent: symptomComponent,
            streakComponent: streakComponent,
            completenessComponent: completenessComponent,
            grade: grade,
            trend: trend,
            tip: tip
        )
    }

    // MARK: - Convenience: Calculate from raw data

    func calculateFromLogs(
        doseLogs: [DoseLog],
        symptomLogs: [SymptomLog],
        totalEpisodeFields: Int,
        filledEpisodeFields: Int,
        documentCount: Int
    ) -> HealthScore {
        let adherence = calculateAdherence(doseLogs: doseLogs)
        let trend = calculateSymptomTrend(symptomLogs: symptomLogs)
        let streak = calculateStreak(doseLogs: doseLogs)
        let completeness = calculateCompleteness(
            symptomLogCount: symptomLogs.count,
            totalFields: totalEpisodeFields,
            filledFields: filledEpisodeFields,
            documentCount: documentCount
        )

        return calculateScore(
            adherencePercentage: adherence,
            symptomTrend: trend,
            currentStreak: streak,
            completenessScore: completeness
        )
    }

    // MARK: - Adherence Calculation

    private func calculateAdherence(doseLogs: [DoseLog]) -> Double {
        let pastDoses = doseLogs.filter { $0.scheduledTime <= Date() }
        guard !pastDoses.isEmpty else { return 0 }
        let taken = pastDoses.filter { $0.status == .taken }.count
        return Double(taken) / Double(pastDoses.count)
    }

    // MARK: - Symptom Trend

    private func calculateSymptomTrend(symptomLogs: [SymptomLog]) -> SymptomTrend {
        let sorted = symptomLogs.sorted { $0.date < $1.date }
        guard sorted.count >= 2 else { return .noData }

        let midpoint = sorted.count / 2
        let firstHalf = sorted.prefix(midpoint)
        let secondHalf = sorted.suffix(from: midpoint)

        let firstAvg = firstHalf.map { Double($0.overallFeeling.rawValue) }.reduce(0, +) / Double(firstHalf.count)
        let secondAvg = secondHalf.map { Double($0.overallFeeling.rawValue) }.reduce(0, +) / Double(secondHalf.count)

        let diff = secondAvg - firstAvg
        if diff > 0.3 {
            return .improving
        } else if diff < -0.3 {
            return .worsening
        } else {
            return .stable
        }
    }

    // MARK: - Streak Calculation

    private func calculateStreak(doseLogs: [DoseLog]) -> Int {
        let calendar = Calendar.current
        let pastDoses = doseLogs.filter { $0.scheduledTime <= Date() }
        guard !pastDoses.isEmpty else { return 0 }

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

        return streak
    }

    // MARK: - Completeness

    private func calculateCompleteness(
        symptomLogCount: Int,
        totalFields: Int,
        filledFields: Int,
        documentCount: Int
    ) -> Double {
        var score = 0.0

        // Symptom logging contributes 40% of completeness
        let symptomPart = min(Double(symptomLogCount) / 7.0, 1.0) * 0.4

        // Episode field completeness contributes 40%
        let fieldPart: Double
        if totalFields > 0 {
            fieldPart = (Double(filledFields) / Double(totalFields)) * 0.4
        } else {
            fieldPart = 0.2 // neutral if no fields to fill
        }

        // Document uploads contribute 20%
        let docPart = min(Double(documentCount) / 3.0, 1.0) * 0.2

        score = symptomPart + fieldPart + docPart
        return min(max(score, 0), 1.0)
    }

    // MARK: - Trend Determination

    private func determineTrend(adherence: Double, symptomTrend: SymptomTrend, streak: Int) -> ScoreTrend {
        // If symptoms are improving and adherence is decent, improving
        if symptomTrend == .improving && adherence >= 0.6 {
            return .improving
        }
        // If symptoms are worsening or adherence is low, declining
        if symptomTrend == .worsening || adherence < 0.4 {
            return .declining
        }
        // If good streak going, improving
        if streak >= 7 && adherence >= 0.8 {
            return .improving
        }
        return .stable
    }

    // MARK: - Contextual Tips

    private func generateTip(
        adherencePercentage: Double,
        symptomTrend: SymptomTrend,
        currentStreak: Int,
        completenessScore: Double,
        total: Int
    ) -> String {
        // Lowest component gets priority tip
        if adherencePercentage < 0.5 {
            return "Taking your medicines consistently is the single most important thing for your recovery. Try linking doses to daily habits like meals."
        }

        if symptomTrend == .worsening {
            return "Your symptoms seem to be getting worse. Make sure to log them regularly and share the data with your doctor at your next visit."
        }

        if currentStreak == 0 {
            return "Start building your streak today! Taking all your doses consistently helps your treatment work better."
        }

        if completenessScore < 0.3 {
            return "Logging symptoms and uploading documents gives you a more complete health picture. Try logging how you feel today."
        }

        if total >= 90 {
            return "Outstanding work! You're managing your health like a pro. Keep up this excellent routine."
        }

        if total >= 70 {
            return "You're doing great! A little more consistency with your doses can push your score even higher."
        }

        if currentStreak >= 7 {
            return "Amazing \(currentStreak)-day streak! Consistency is key — your body thanks you."
        }

        if adherencePercentage >= 0.8 && completenessScore < 0.5 {
            return "Great adherence! Try logging your symptoms more often to get a complete picture of your health journey."
        }

        return "Keep tracking your medicines and symptoms — every day of consistency brings you closer to better health."
    }
}

// MARK: - Supporting Types

struct HealthScore {
    let total: Int // 0-100
    let adherenceComponent: Int
    let symptomComponent: Int
    let streakComponent: Int
    let completenessComponent: Int
    let grade: HealthGrade
    let trend: ScoreTrend
    let tip: String
}

enum HealthGrade: String, CaseIterable {
    case aPlus = "A+"
    case a = "A"
    case b = "B"
    case c = "C"
    case d = "D"
    case f = "F"

    static func from(score: Int) -> HealthGrade {
        switch score {
        case 95...100: return .aPlus
        case 85..<95: return .a
        case 70..<85: return .b
        case 55..<70: return .c
        case 40..<55: return .d
        default: return .f
        }
    }

    var color: String {
        switch self {
        case .aPlus, .a: return "34C759"
        case .b: return "007AFF"
        case .c: return "F5A623"
        case .d: return "FF6B6B"
        case .f: return "FF3B30"
        }
    }

    var icon: String {
        switch self {
        case .aPlus: return "star.circle.fill"
        case .a: return "checkmark.seal.fill"
        case .b: return "hand.thumbsup.fill"
        case .c: return "exclamationmark.circle"
        case .d: return "exclamationmark.triangle"
        case .f: return "xmark.octagon"
        }
    }
}

enum ScoreTrend: String {
    case improving = "Improving"
    case stable = "Stable"
    case declining = "Declining"

    var icon: String {
        switch self {
        case .improving: return "arrow.up.right"
        case .stable: return "arrow.right"
        case .declining: return "arrow.down.right"
        }
    }

    var color: String {
        switch self {
        case .improving: return "34C759"
        case .stable: return "F5A623"
        case .declining: return "FF3B30"
        }
    }
}

enum SymptomTrend: String {
    case improving = "Improving"
    case stable = "Stable"
    case worsening = "Worsening"
    case noData = "No Data"
}
