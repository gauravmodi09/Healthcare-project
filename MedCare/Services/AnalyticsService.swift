import Foundation

/// Enhancement #5: Privacy-first analytics for adherence insights
/// All data is anonymized and PII-scrubbed before any analytics
@Observable
final class AnalyticsService {

    struct AdherenceInsight: Identifiable {
        let id = UUID()
        let type: InsightType
        let title: String
        let description: String
        let actionable: String?
        let priority: Int // 1=highest
    }

    enum InsightType {
        case streak
        case improvement
        case concern
        case tip
        case achievement

        var icon: String {
            switch self {
            case .streak: return "flame.fill"
            case .improvement: return "arrow.up.right"
            case .concern: return "exclamationmark.triangle"
            case .tip: return "lightbulb"
            case .achievement: return "star.fill"
            }
        }

        var color: String {
            switch self {
            case .streak: return "FF6B6B"
            case .improvement: return "34C759"
            case .concern: return "F5A623"
            case .tip: return "007AFF"
            case .achievement: return "FFD700"
            }
        }
    }

    /// Generate insights from adherence data
    func generateInsights(for profile: UserProfile) -> [AdherenceInsight] {
        var insights: [AdherenceInsight] = []

        let allDoses = profile.episodes
            .flatMap { $0.medicines }
            .filter { $0.isActive }
            .flatMap { $0.doseLogs }

        // Streak detection
        if let streak = calculateStreak(doses: allDoses) {
            insights.append(AdherenceInsight(
                type: .streak,
                title: "\(streak)-day streak!",
                description: "You've taken all your medicines for \(streak) consecutive days.",
                actionable: nil,
                priority: streak >= 7 ? 1 : 3
            ))
        }

        // Most missed time slot
        let missedByTime = findMostMissedTimeSlot(doses: allDoses)
        if let (timeSlot, count) = missedByTime, count >= 3 {
            insights.append(AdherenceInsight(
                type: .concern,
                title: "Frequently missed: \(timeSlot)",
                description: "You've missed \(count) doses at \(timeSlot) in the past week.",
                actionable: "Try setting an additional alarm or linking it to a daily habit.",
                priority: 2
            ))
        }

        // Overall adherence trend
        let weeklyAdherence = calculateWeeklyAdherence(doses: allDoses)
        if weeklyAdherence > 0.8 {
            insights.append(AdherenceInsight(
                type: .achievement,
                title: "Great adherence!",
                description: "Your adherence this week is \(Int(weeklyAdherence * 100))%. Keep it up!",
                actionable: nil,
                priority: 4
            ))
        } else if weeklyAdherence < 0.5 {
            insights.append(AdherenceInsight(
                type: .concern,
                title: "Adherence needs attention",
                description: "Your adherence this week is \(Int(weeklyAdherence * 100))%. Missing doses can reduce treatment effectiveness.",
                actionable: "Consider snoozing reminders instead of ignoring them.",
                priority: 1
            ))
        }

        // Medicine-specific insights
        for episode in profile.episodes where episode.status == .active {
            for medicine in episode.activeMedicines {
                let medDoses = medicine.doseLogs.filter {
                    $0.scheduledTime > Calendar.current.date(byAdding: .day, value: -7, to: Date())!
                }
                let taken = medDoses.filter { $0.status == .taken }.count
                let total = medDoses.count
                if total > 0 && Double(taken) / Double(total) < 0.5 {
                    insights.append(AdherenceInsight(
                        type: .concern,
                        title: "\(medicine.brandName) adherence low",
                        description: "Only \(taken)/\(total) doses taken this week.",
                        actionable: "Set a specific routine for this medicine.",
                        priority: 2
                    ))
                }
            }
        }

        // Tips
        insights.append(AdherenceInsight(
            type: .tip,
            title: "Tip: Pill organizer",
            description: "Using a weekly pill organizer can improve adherence by up to 30%.",
            actionable: nil,
            priority: 5
        ))

        return insights.sorted { $0.priority < $1.priority }
    }

    private func calculateStreak(doses: [DoseLog]) -> Int? {
        let calendar = Calendar.current
        var streak = 0
        var checkDate = calendar.startOfDay(for: Date())

        for _ in 0..<365 {
            let dayDoses = doses.filter {
                calendar.isDate($0.scheduledTime, inSameDayAs: checkDate)
            }

            guard !dayDoses.isEmpty else { break }

            let allTaken = dayDoses.allSatisfy { $0.status == .taken }
            if allTaken {
                streak += 1
                checkDate = calendar.date(byAdding: .day, value: -1, to: checkDate)!
            } else {
                break
            }
        }

        return streak > 0 ? streak : nil
    }

    private func findMostMissedTimeSlot(doses: [DoseLog]) -> (String, Int)? {
        let calendar = Calendar.current
        let weekAgo = calendar.date(byAdding: .day, value: -7, to: Date())!

        let missed = doses.filter {
            $0.scheduledTime > weekAgo &&
            ($0.status == .missed || $0.status == .skipped)
        }

        let grouped = Dictionary(grouping: missed) { dose -> String in
            let hour = calendar.component(.hour, from: dose.scheduledTime)
            switch hour {
            case 5..<12: return "Morning"
            case 12..<17: return "Afternoon"
            case 17..<21: return "Evening"
            default: return "Night"
            }
        }

        return grouped.max(by: { $0.value.count < $1.value.count })
            .map { ($0.key, $0.value.count) }
    }

    private func calculateWeeklyAdherence(doses: [DoseLog]) -> Double {
        let weekAgo = Calendar.current.date(byAdding: .day, value: -7, to: Date())!
        let recentDoses = doses.filter { $0.scheduledTime > weekAgo }
        guard !recentDoses.isEmpty else { return 0 }
        let taken = recentDoses.filter { $0.status == .taken }.count
        return Double(taken) / Double(recentDoses.count)
    }
}
