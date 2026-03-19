import Foundation

// MARK: - Supporting Types

struct MedicineTipInfo: Identifiable {
    let id: UUID
    let name: String
    let category: DrugCategory
    let mealTiming: MealTiming
    let timeOfDay: [MedicineTiming]

    init(id: UUID = UUID(), name: String, category: DrugCategory, mealTiming: MealTiming, timeOfDay: [MedicineTiming]) {
        self.id = id
        self.name = name
        self.category = category
        self.mealTiming = mealTiming
        self.timeOfDay = timeOfDay
    }
}

enum TipCategory: String, CaseIterable {
    case timeBased = "Time-based"
    case weatherAware = "Weather"
    case activityBased = "Activity"
    case adherenceBased = "Adherence"
    case medicineSpecific = "Medicine"
    case seasonal = "Seasonal"
    case generalWellness = "Wellness"
}

struct HealthTip: Identifiable, Equatable {
    let id: UUID
    let message: String
    let category: TipCategory
    let priority: Int // 1 (highest) to 5 (lowest)
    let icon: String  // SF Symbol
    let colorHex: String

    init(message: String, category: TipCategory, priority: Int, icon: String, colorHex: String) {
        self.id = UUID()
        self.message = message
        self.category = category
        self.priority = priority
        self.icon = icon
        self.colorHex = colorHex
    }

    static func == (lhs: HealthTip, rhs: HealthTip) -> Bool {
        lhs.id == rhs.id
    }
}

// MARK: - Service

@Observable
final class ContextualTipsService {

    private let shownTipsKey = "ContextualTipsService.shownTipHashes"
    private let shownTipsDateKey = "ContextualTipsService.shownTipsDate"

    // MARK: - Generate Tips

    func generateTips(
        medicines: [MedicineTipInfo],
        adherenceRate: Double,
        currentStreak: Int,
        steps: Int?,
        temperature: Double?,
        hour: Int
    ) -> [HealthTip] {
        resetShownTipsIfNewDay()

        var allTips: [HealthTip] = []

        // Time-based tips
        allTips.append(contentsOf: generateTimeTips(medicines: medicines, hour: hour))

        // Weather-aware tips
        if let temp = temperature {
            allTips.append(contentsOf: generateWeatherTips(medicines: medicines, temperature: temp))
        }

        // Activity-based tips
        if let steps = steps {
            allTips.append(contentsOf: generateActivityTips(medicines: medicines, steps: steps))
        }

        // Adherence-based tips
        allTips.append(contentsOf: generateAdherenceTips(adherenceRate: adherenceRate, currentStreak: currentStreak))

        // Medicine-specific tips
        allTips.append(contentsOf: generateMedicineSpecificTips(medicines: medicines))

        // Seasonal tips (Indian calendar)
        allTips.append(contentsOf: generateSeasonalTips(medicines: medicines))

        // General wellness
        allTips.append(contentsOf: generateWellnessTips(medicines: medicines))

        // Filter out already-shown tips
        let shownHashes = getShownTipHashes()
        let filtered = allTips.filter { !shownHashes.contains(tipHash($0)) }

        // Sort by priority (1 = highest), take top 3-5
        let sorted = filtered.sorted { $0.priority < $1.priority }
        let result = Array(sorted.prefix(5))

        // Ensure at least 3 tips if possible, pad with general wellness
        let final: [HealthTip]
        if result.count >= 3 {
            final = result
        } else {
            // Include already-shown tips to fill up to 3
            let remaining = allTips.sorted { $0.priority < $1.priority }
                .filter { tip in !result.contains(where: { $0.message == tip.message }) }
            final = Array((result + remaining).prefix(max(3, result.count)))
        }

        // Mark these tips as shown
        markTipsAsShown(final)

        return final
    }

    // MARK: - Time-Based Tips

    private func generateTimeTips(medicines: [MedicineTipInfo], hour: Int) -> [HealthTip] {
        var tips: [HealthTip] = []

        let isMorning = hour >= 5 && hour < 12
        let isAfternoon = hour >= 12 && hour < 17
        let isEvening = hour >= 17 && hour < 21
        let isNight = hour >= 21 || hour < 5

        if isMorning {
            // Thyroid medicines need special morning timing
            let thyroidMeds = medicines.filter { $0.category == .thyroid }
            for med in thyroidMeds {
                tips.append(HealthTip(
                    message: "Good morning! Take \(med.name) 30 minutes before breakfast on an empty stomach for best absorption.",
                    category: .timeBased,
                    priority: 1,
                    icon: "sunrise.fill",
                    colorHex: "F59E0B"
                ))
            }

            // Empty stomach medicines
            let emptyStomachMeds = medicines.filter { $0.mealTiming == .emptyStomach && $0.category != .thyroid }
            for med in emptyStomachMeds {
                tips.append(HealthTip(
                    message: "Good morning! Remember to take \(med.name) on an empty stomach before eating.",
                    category: .timeBased,
                    priority: 2,
                    icon: "sunrise.fill",
                    colorHex: "F59E0B"
                ))
            }

            if thyroidMeds.isEmpty && emptyStomachMeds.isEmpty {
                let morningMeds = medicines.filter { $0.timeOfDay.contains(.morning) }
                if !morningMeds.isEmpty {
                    let names = morningMeds.map(\.name).joined(separator: ", ")
                    tips.append(HealthTip(
                        message: "Good morning! Time for your morning medicines: \(names).",
                        category: .timeBased,
                        priority: 2,
                        icon: "sunrise.fill",
                        colorHex: "F59E0B"
                    ))
                }
            }
        }

        if isEvening {
            let eveningMeds = medicines.filter { $0.timeOfDay.contains(.evening) }
            for med in eveningMeds {
                tips.append(HealthTip(
                    message: "Evening dose time! Take \(med.name)\(med.mealTiming == .withMeal ? " with dinner" : "").",
                    category: .timeBased,
                    priority: 2,
                    icon: "sunset.fill",
                    colorHex: "FF6B6B"
                ))
            }
        }

        if isNight {
            let nightMeds = medicines.filter { $0.timeOfDay.contains(.night) }
            if !nightMeds.isEmpty {
                let names = nightMeds.map(\.name).joined(separator: ", ")
                tips.append(HealthTip(
                    message: "Before bed, don't forget: \(names). Good night!",
                    category: .timeBased,
                    priority: 2,
                    icon: "moon.stars.fill",
                    colorHex: "A78BFA"
                ))
            }
        }

        if isAfternoon {
            let afternoonMeds = medicines.filter { $0.timeOfDay.contains(.afternoon) }
            if !afternoonMeds.isEmpty {
                let names = afternoonMeds.map(\.name).joined(separator: ", ")
                tips.append(HealthTip(
                    message: "Afternoon reminder: time for \(names).",
                    category: .timeBased,
                    priority: 2,
                    icon: "sun.max.fill",
                    colorHex: "F59E0B"
                ))
            }
        }

        return tips
    }

    // MARK: - Weather-Aware Tips

    private func generateWeatherTips(medicines: [MedicineTipInfo], temperature: Double) -> [HealthTip] {
        var tips: [HealthTip] = []

        if temperature >= 35 {
            // Hot weather
            let hasDiuretic = medicines.contains { $0.category == .antihypertensive || $0.category == .cardiovascular }
            if hasDiuretic {
                tips.append(HealthTip(
                    message: "Hot day ahead (\(Int(temperature)) C) \u{2014} drink extra water, especially with your blood pressure medication.",
                    category: .weatherAware,
                    priority: 2,
                    icon: "thermometer.sun.fill",
                    colorHex: "EF4444"
                ))
            } else {
                tips.append(HealthTip(
                    message: "It's \(Int(temperature)) C outside. Stay hydrated \u{2014} your body needs extra water to process medications in the heat.",
                    category: .weatherAware,
                    priority: 3,
                    icon: "thermometer.sun.fill",
                    colorHex: "EF4444"
                ))
            }
        }

        if temperature <= 10 {
            let hasRespiratory = medicines.contains { $0.category == .respiratory }
            if hasRespiratory {
                tips.append(HealthTip(
                    message: "Cold weather (\(Int(temperature)) C) can worsen respiratory issues. Keep your inhaler handy and stay warm.",
                    category: .weatherAware,
                    priority: 2,
                    icon: "thermometer.snowflake",
                    colorHex: "60A5FA"
                ))
            } else {
                tips.append(HealthTip(
                    message: "Chilly today (\(Int(temperature)) C). Cold weather can affect blood pressure \u{2014} keep warm and stay consistent with your medicines.",
                    category: .weatherAware,
                    priority: 4,
                    icon: "thermometer.snowflake",
                    colorHex: "60A5FA"
                ))
            }
        }

        return tips
    }

    // MARK: - Activity-Based Tips

    private func generateActivityTips(medicines: [MedicineTipInfo], steps: Int) -> [HealthTip] {
        var tips: [HealthTip] = []

        if steps >= 8000 {
            let hasDiabetes = medicines.contains { $0.category == .antidiabetic }
            if hasDiabetes {
                tips.append(HealthTip(
                    message: "Great job on \(steps.formatted()) steps today! Walking helps manage your blood sugar levels.",
                    category: .activityBased,
                    priority: 3,
                    icon: "figure.walk",
                    colorHex: "22C55E"
                ))
            } else {
                tips.append(HealthTip(
                    message: "Amazing \(steps.formatted()) steps today! Regular activity helps your body respond better to medications.",
                    category: .activityBased,
                    priority: 4,
                    icon: "figure.walk",
                    colorHex: "22C55E"
                ))
            }
        } else if steps >= 5000 {
            tips.append(HealthTip(
                message: "\(steps.formatted()) steps so far \u{2014} you're halfway to 10,000! A short walk after meals can help with digestion and absorption.",
                category: .activityBased,
                priority: 4,
                icon: "figure.walk",
                colorHex: "60A5FA"
            ))
        } else if steps < 2000 && steps > 0 {
            tips.append(HealthTip(
                message: "Try a short 10-minute walk today. Even light movement helps your body absorb medicines more effectively.",
                category: .activityBased,
                priority: 4,
                icon: "figure.walk",
                colorHex: "F59E0B"
            ))
        }

        return tips
    }

    // MARK: - Adherence-Based Tips

    private func generateAdherenceTips(adherenceRate: Double, currentStreak: Int) -> [HealthTip] {
        var tips: [HealthTip] = []

        if currentStreak >= 30 {
            tips.append(HealthTip(
                message: "Incredible \(currentStreak)-day streak! Your consistency is truly paying off. Keep it up!",
                category: .adherenceBased,
                priority: 3,
                icon: "flame.fill",
                colorHex: "22C55E"
            ))
        } else if currentStreak >= 7 {
            tips.append(HealthTip(
                message: "\(currentStreak) days perfect streak! Your body thrives on consistency \u{2014} keep the momentum going!",
                category: .adherenceBased,
                priority: 3,
                icon: "flame.fill",
                colorHex: "22C55E"
            ))
        } else if currentStreak >= 3 {
            tips.append(HealthTip(
                message: "\(currentStreak) days perfect streak! Keep going \u{2014} building habits takes 21 days, you're on track!",
                category: .adherenceBased,
                priority: 3,
                icon: "flame.fill",
                colorHex: "F59E0B"
            ))
        }

        if adherenceRate < 0.5 && currentStreak == 0 {
            tips.append(HealthTip(
                message: "You missed some doses recently \u{2014} today's a fresh start. Try linking your dose to a daily habit like brushing teeth.",
                category: .adherenceBased,
                priority: 1,
                icon: "arrow.counterclockwise.circle.fill",
                colorHex: "EF4444"
            ))
        } else if adherenceRate < 0.7 {
            tips.append(HealthTip(
                message: "Your adherence is at \(Int(adherenceRate * 100))%. Even small improvements can make a big difference in how well your treatment works.",
                category: .adherenceBased,
                priority: 2,
                icon: "chart.line.uptrend.xyaxis",
                colorHex: "F59E0B"
            ))
        } else if adherenceRate >= 0.9 {
            tips.append(HealthTip(
                message: "\(Int(adherenceRate * 100))% adherence \u{2014} outstanding! You're one of the most consistent patients. Your health thanks you.",
                category: .adherenceBased,
                priority: 4,
                icon: "star.fill",
                colorHex: "22C55E"
            ))
        }

        return tips
    }

    // MARK: - Medicine-Specific Tips

    private func generateMedicineSpecificTips(medicines: [MedicineTipInfo]) -> [HealthTip] {
        var tips: [HealthTip] = []

        // Antibiotics
        let antibiotics = medicines.filter { $0.category == .antibiotic }
        for med in antibiotics {
            if med.mealTiming == .emptyStomach || med.mealTiming == .beforeMeal {
                tips.append(HealthTip(
                    message: "\(med.name) works best on an empty stomach. Take it 1 hour before or 2 hours after meals.",
                    category: .medicineSpecific,
                    priority: 2,
                    icon: "pills.fill",
                    colorHex: "60A5FA"
                ))
            }
            tips.append(HealthTip(
                message: "Complete the full course of \(med.name) even if you feel better. Stopping early can cause resistance.",
                category: .medicineSpecific,
                priority: 1,
                icon: "exclamationmark.shield.fill",
                colorHex: "EF4444"
            ))
        }

        // Antidiabetic
        let diabetesMeds = medicines.filter { $0.category == .antidiabetic }
        for med in diabetesMeds {
            tips.append(HealthTip(
                message: "Monitor your sugar levels regularly while taking \(med.name). Watch for signs of low blood sugar.",
                category: .medicineSpecific,
                priority: 2,
                icon: "drop.fill",
                colorHex: "F59E0B"
            ))
        }

        // Cholesterol (statins)
        let cholesterolMeds = medicines.filter { $0.category == .cholesterol }
        for med in cholesterolMeds {
            tips.append(HealthTip(
                message: "\(med.name) works best when taken at night, as your body produces more cholesterol while you sleep.",
                category: .medicineSpecific,
                priority: 3,
                icon: "moon.fill",
                colorHex: "A78BFA"
            ))
            tips.append(HealthTip(
                message: "Avoid grapefruit and grapefruit juice while on \(med.name) \u{2014} it can increase side effects.",
                category: .medicineSpecific,
                priority: 3,
                icon: "exclamationmark.triangle.fill",
                colorHex: "F59E0B"
            ))
        }

        // Antihypertensive
        let bpMeds = medicines.filter { $0.category == .antihypertensive }
        for med in bpMeds {
            tips.append(HealthTip(
                message: "Stand up slowly when taking \(med.name) to prevent dizziness from sudden blood pressure drops.",
                category: .medicineSpecific,
                priority: 3,
                icon: "heart.fill",
                colorHex: "EF4444"
            ))
        }

        // Anti-acid
        let antacidMeds = medicines.filter { $0.category == .antiAcid }
        for med in antacidMeds {
            tips.append(HealthTip(
                message: "Take \(med.name) 30 minutes before meals for maximum effectiveness against acidity.",
                category: .medicineSpecific,
                priority: 3,
                icon: "flame.fill",
                colorHex: "F59E0B"
            ))
        }

        // Calcium / Vitamins interaction
        let hasCalcium = medicines.contains { $0.category == .vitamin }
        let hasAntibiotic = !antibiotics.isEmpty
        if hasCalcium && hasAntibiotic {
            tips.append(HealthTip(
                message: "Space your calcium/vitamin supplements at least 2 hours apart from your antibiotic for proper absorption.",
                category: .medicineSpecific,
                priority: 1,
                icon: "clock.arrow.2.circlepath",
                colorHex: "EF4444"
            ))
        }

        return tips
    }

    // MARK: - Seasonal Tips (Indian Calendar)

    private func generateSeasonalTips(medicines: [MedicineTipInfo]) -> [HealthTip] {
        var tips: [HealthTip] = []
        let month = Calendar.current.component(.month, from: Date())

        switch month {
        case 6, 7, 8, 9: // Monsoon (June-September)
            let hasImmunosuppressant = medicines.contains { $0.category == .antiInfective || $0.category == .antibiotic }
            if hasImmunosuppressant {
                tips.append(HealthTip(
                    message: "Monsoon season \u{2014} infections are common. Be extra careful with hygiene while on your medication.",
                    category: .seasonal,
                    priority: 3,
                    icon: "cloud.rain.fill",
                    colorHex: "60A5FA"
                ))
            } else {
                tips.append(HealthTip(
                    message: "Monsoon tip: Store your medicines in a dry, cool place. Humidity can affect tablet quality.",
                    category: .seasonal,
                    priority: 4,
                    icon: "cloud.rain.fill",
                    colorHex: "60A5FA"
                ))
            }

        case 10, 11: // Festival season (Dussehra/Diwali)
            let hasDiabetes = medicines.contains { $0.category == .antidiabetic }
            if hasDiabetes {
                tips.append(HealthTip(
                    message: "Festival season \u{2014} enjoy celebrations in moderation. Watch your sugar intake with your diabetes medication.",
                    category: .seasonal,
                    priority: 2,
                    icon: "sparkles",
                    colorHex: "F59E0B"
                ))
            }
            let hasCholesterol = medicines.contains { $0.category == .cholesterol }
            if hasCholesterol {
                tips.append(HealthTip(
                    message: "Festival sweets and fried foods can spike cholesterol. Enjoy in moderation while on \(medicines.first { $0.category == .cholesterol }?.name ?? "your medication").",
                    category: .seasonal,
                    priority: 3,
                    icon: "sparkles",
                    colorHex: "F59E0B"
                ))
            }

        case 4, 5: // Summer (April-May)
            tips.append(HealthTip(
                message: "Summer heat can affect how your body absorbs medicines. Drink at least 8 glasses of water daily.",
                category: .seasonal,
                priority: 4,
                icon: "sun.max.fill",
                colorHex: "F59E0B"
            ))

        case 12, 1, 2: // Winter
            let hasRespiratory = medicines.contains { $0.category == .respiratory }
            if hasRespiratory {
                tips.append(HealthTip(
                    message: "Winter air can trigger respiratory issues. Keep your inhaler nearby and avoid sudden temperature changes.",
                    category: .seasonal,
                    priority: 3,
                    icon: "snowflake",
                    colorHex: "60A5FA"
                ))
            }

        default:
            break
        }

        return tips
    }

    // MARK: - General Wellness Tips

    private func generateWellnessTips(medicines: [MedicineTipInfo]) -> [HealthTip] {
        let wellnessTips: [(String, String, String)] = [
            ("Staying hydrated helps your kidneys process medications better. Aim for 2-3 litres of water daily.", "drop.fill", "60A5FA"),
            ("Getting 7-8 hours of sleep helps your body heal and respond better to treatment.", "bed.double.fill", "A78BFA"),
            ("Taking medicines at the same time each day helps maintain steady levels in your body.", "clock.fill", "0D9488"),
            ("A balanced diet rich in fruits and vegetables supports your medication's effectiveness.", "leaf.fill", "22C55E"),
            ("Stress can affect how well your medicines work. Try 5 minutes of deep breathing today.", "wind", "60A5FA"),
            ("Regular check-ups help your doctor adjust treatment. Schedule one if it's been a while.", "stethoscope", "0D9488"),
        ]

        // Pick 1-2 random wellness tips
        let shuffled = wellnessTips.shuffled()
        let count = min(2, shuffled.count)

        return shuffled.prefix(count).map { message, icon, color in
            HealthTip(
                message: message,
                category: .generalWellness,
                priority: 5,
                icon: icon,
                colorHex: color
            )
        }
    }

    // MARK: - Deduplication (24-hour window)

    private func tipHash(_ tip: HealthTip) -> String {
        // Use first 60 chars of message as fingerprint to catch similar tips
        let prefix = String(tip.message.prefix(60))
        return "\(tip.category.rawValue):\(prefix)"
    }

    private func getShownTipHashes() -> Set<String> {
        let hashes = UserDefaults.standard.stringArray(forKey: shownTipsKey) ?? []
        return Set(hashes)
    }

    private func markTipsAsShown(_ tips: [HealthTip]) {
        var existing = getShownTipHashes()
        for tip in tips {
            existing.insert(tipHash(tip))
        }
        UserDefaults.standard.set(Array(existing), forKey: shownTipsKey)
        UserDefaults.standard.set(Date().timeIntervalSince1970, forKey: shownTipsDateKey)
    }

    private func resetShownTipsIfNewDay() {
        let lastTimestamp = UserDefaults.standard.double(forKey: shownTipsDateKey)
        guard lastTimestamp > 0 else { return }

        let lastDate = Date(timeIntervalSince1970: lastTimestamp)
        if !Calendar.current.isDateInToday(lastDate) {
            UserDefaults.standard.removeObject(forKey: shownTipsKey)
            UserDefaults.standard.removeObject(forKey: shownTipsDateKey)
        }
    }
}
