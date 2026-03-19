import Foundation

// MARK: - Input Models

struct ProfileInfo {
    let name: String
    let age: Int?
}

struct DoseInfo {
    let medicineName: String
    let dosage: String
    let scheduledTime: Date
    let isCritical: Bool
}

// MARK: - Output Model

struct MorningBriefing {
    let greeting: String
    let healthScoreLine: String
    let todayPlan: [String]
    let streakInfo: String
    let alertLines: [String]
    let motivationalQuote: String
    let formattedText: String
}

// MARK: - Service

@Observable
final class MorningBriefingService {

    // MARK: - Motivational Quotes

    private let healthQuotes: [String] = [
        "The greatest wealth is health. — Virgil",
        "Take care of your body. It's the only place you have to live. — Jim Rohn",
        "Health is not valued till sickness comes. — Thomas Fuller",
        "A healthy outside starts from the inside. — Robert Urich",
        "Your body hears everything your mind says. Stay positive.",
        "Small daily improvements lead to staggering long-term results.",
        "Consistency is the key to achieving and maintaining health.",
        "Every dose you take is an investment in your future self.",
        "Medicine works best when you work with it — stay on schedule.",
        "You don't have to be perfect, just consistent.",
        "Progress, not perfection, is what matters.",
        "One pill at a time, one day at a time — you've got this.",
        "Your health journey is a marathon, not a sprint.",
        "Discipline is choosing between what you want now and what you want most.",
        "The best time to take care of your health was yesterday. The next best time is now.",
        "Self-care is not selfish. It's essential.",
        "Every healthy choice you make is a vote for your future self.",
        "Healing takes time, and asking for help is a courageous step.",
        "Good health and good sense are two of life's greatest blessings. — Publilius Syrus",
        "When you take care of yourself, you're better able to take care of others."
    ]

    // MARK: - Generate Briefing

    func generateBriefing(
        profile: ProfileInfo,
        todayDoses: [DoseInfo],
        yesterdayAdherence: Double,
        currentStreak: Int,
        healthScore: Int,
        recentMood: Int?,
        lowStockMedicines: [String]
    ) -> MorningBriefing {

        let greeting = buildGreeting(name: profile.name)
        let healthScoreLine = buildHealthScoreLine(score: healthScore)
        let todayPlan = buildTodayPlan(doses: todayDoses)
        let streakInfo = buildStreakInfo(streak: currentStreak)
        let alertLines = buildAlertLines(
            lowStockMedicines: lowStockMedicines,
            yesterdayAdherence: yesterdayAdherence,
            recentMood: recentMood,
            criticalDoses: todayDoses.filter(\.isCritical)
        )
        let quote = randomQuote()

        let formattedText = buildFormattedText(
            greeting: greeting,
            healthScoreLine: healthScoreLine,
            todayPlan: todayPlan,
            streakInfo: streakInfo,
            alertLines: alertLines,
            quote: quote
        )

        return MorningBriefing(
            greeting: greeting,
            healthScoreLine: healthScoreLine,
            todayPlan: todayPlan,
            streakInfo: streakInfo,
            alertLines: alertLines,
            motivationalQuote: quote,
            formattedText: formattedText
        )
    }

    // MARK: - Private Builders

    private func buildGreeting(name: String) -> String {
        let hour = Calendar.current.component(.hour, from: Date())
        let timeGreeting: String
        let emoji: String

        switch hour {
        case 5..<12:
            timeGreeting = "Good morning"
            emoji = "\u{1F305}" // sunrise
        case 12..<17:
            timeGreeting = "Good afternoon"
            emoji = "\u{2600}\u{FE0F}" // sun
        case 17..<21:
            timeGreeting = "Good evening"
            emoji = "\u{1F307}" // sunset
        default:
            timeGreeting = "Good night"
            emoji = "\u{1F319}" // moon
        }

        return "\(timeGreeting), \(name)! \(emoji)"
    }

    private func buildHealthScoreLine(score: Int) -> String {
        let grade = HealthGrade.from(score: score)
        let commentary: String

        switch score {
        case 90...100:
            commentary = "You're doing amazing!"
        case 75..<90:
            commentary = "You're doing great!"
        case 60..<75:
            commentary = "Good progress, keep it up!"
        case 40..<60:
            commentary = "Room to improve \u{2014} stay consistent."
        default:
            commentary = "Let's work on getting this up."
        }

        return "Health Score: \(score) (\(grade.rawValue)) \u{2014} \(commentary)"
    }

    private func buildTodayPlan(doses: [DoseInfo]) -> [String] {
        guard !doses.isEmpty else {
            return ["No doses scheduled today \u{2014} enjoy your free day!"]
        }

        var plan: [String] = []
        let doseCount = doses.count
        plan.append("\(doseCount) dose\(doseCount == 1 ? "" : "s") scheduled today")

        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"

        let sortedDoses = doses.sorted { $0.scheduledTime < $1.scheduledTime }
        let doseDescriptions = sortedDoses.map { dose in
            let timeStr = formatter.string(from: dose.scheduledTime)
            let critical = dose.isCritical ? " \u{1F534}" : ""
            return "\(dose.medicineName) at \(timeStr)\(critical)"
        }

        plan.append(doseDescriptions.joined(separator: ", "))

        // Highlight next upcoming dose
        let now = Date()
        if let nextDose = sortedDoses.first(where: { $0.scheduledTime > now }) {
            let timeStr = formatter.string(from: nextDose.scheduledTime)
            plan.append("Next up: \(nextDose.medicineName) at \(timeStr)")
        }

        return plan
    }

    private func buildStreakInfo(streak: Int) -> String {
        switch streak {
        case 0:
            return "Start a new streak today! Take all your doses to begin."
        case 1:
            return "\u{1F525} Day 1 \u{2014} great start! Keep going!"
        case 2...6:
            return "\u{1F525} Day \(streak) streak! Building momentum!"
        case 7...13:
            return "\u{1F525} Day \(streak) streak! A whole week strong!"
        case 14...29:
            return "\u{1F525}\u{1F525} Day \(streak) streak! You're on fire!"
        default:
            return "\u{1F525}\u{1F525}\u{1F525} Day \(streak) streak! Incredible consistency!"
        }
    }

    private func buildAlertLines(
        lowStockMedicines: [String],
        yesterdayAdherence: Double,
        recentMood: Int?,
        criticalDoses: [DoseInfo]
    ) -> [String] {
        var alerts: [String] = []

        // Low stock alerts
        for medicine in lowStockMedicines {
            alerts.append("\u{26A0}\u{FE0F} \(medicine) running low \u{2014} consider refilling soon")
        }

        // Critical dose alert
        if !criticalDoses.isEmpty {
            let names = criticalDoses.map(\.medicineName).joined(separator: ", ")
            alerts.append("\u{1F534} Critical medicine\(criticalDoses.count > 1 ? "s" : "") today: \(names)")
        }

        // Yesterday adherence alert
        if yesterdayAdherence < 0.5 {
            alerts.append("\u{1F4CB} Yesterday's adherence was \(Int(yesterdayAdherence * 100))% \u{2014} try to stay on track today")
        }

        // Mood alert
        if let mood = recentMood, mood <= 2 {
            alerts.append("\u{1F49C} Your recent mood has been low. Remember to take care of yourself.")
        }

        return alerts
    }

    private func randomQuote() -> String {
        // Use day of year for deterministic daily rotation
        let dayOfYear = Calendar.current.ordinality(of: .day, in: .year, for: Date()) ?? 1
        let index = (dayOfYear - 1) % healthQuotes.count
        return healthQuotes[index]
    }

    private func buildFormattedText(
        greeting: String,
        healthScoreLine: String,
        todayPlan: [String],
        streakInfo: String,
        alertLines: [String],
        quote: String
    ) -> String {
        var lines: [String] = []

        lines.append(greeting)
        lines.append("")
        lines.append(healthScoreLine)
        lines.append("")

        lines.append("Today's Plan:")
        for item in todayPlan {
            lines.append("  \u{2022} \(item)")
        }
        lines.append("")

        lines.append(streakInfo)

        if !alertLines.isEmpty {
            lines.append("")
            lines.append("Alerts:")
            for alert in alertLines {
                lines.append("  \(alert)")
            }
        }

        lines.append("")
        lines.append("\"\(quote)\"")

        return lines.joined(separator: "\n")
    }
}
