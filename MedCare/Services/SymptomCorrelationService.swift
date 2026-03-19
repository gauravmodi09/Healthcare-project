import Foundation

// MARK: - Data Transfer Structs (non-SwiftData)

struct DoseLogData {
    let medicineId: UUID
    let medicineName: String
    let scheduledTime: Date
    let status: String // "taken", "skipped", "missed"
    let actualTime: Date?
}

struct SymptomLogData {
    let date: Date
    let overallFeeling: Int // 1-5
    let symptoms: [(name: String, severity: Int)]
    let notes: String?
}

struct MedicineData {
    let id: UUID
    let brandName: String
    let mealTiming: String
    let startDate: Date?
}

// MARK: - Symptom Correlation Service

/// Phase 4 Intelligence: Analyzes symptom logs vs medication adherence to find patterns
@Observable
final class SymptomCorrelationService {

    struct Correlation: Identifiable {
        let id = UUID()
        let type: CorrelationType
        let description: String
        let confidence: Double // 0-1
        let medicineName: String?
        let symptomName: String?
        let insight: String // human-readable insight
        let recommendation: String
    }

    enum CorrelationType: String {
        case medicineHelps        // "Headaches decreased 60% since starting Metformin"
        case medicineSideEffect   // "Nausea reported on 70% of days you take Augmentin"
        case timingCorrelation    // "Stomach pain worse when taking medicine on empty stomach"
        case adherenceImpact      // "Symptoms worsen on days you miss doses"
        case improvementTrend     // "Overall feeling improved from 2.1 to 3.8 over 14 days"

        var icon: String {
            switch self {
            case .medicineHelps: return "hand.thumbsup.fill"
            case .medicineSideEffect: return "exclamationmark.triangle.fill"
            case .timingCorrelation: return "clock.arrow.circlepath"
            case .adherenceImpact: return "chart.line.downtrend.xyaxis"
            case .improvementTrend: return "chart.line.uptrend.xyaxis"
            }
        }

        var color: String {
            switch self {
            case .medicineHelps: return "34C759"
            case .medicineSideEffect: return "FF6B6B"
            case .timingCorrelation: return "F5A623"
            case .adherenceImpact: return "FF3B30"
            case .improvementTrend: return "007AFF"
            }
        }
    }

    // MARK: - Main Analysis

    func analyzeCorrelations(
        doseLogs: [DoseLogData],
        symptomLogs: [SymptomLogData],
        medicines: [MedicineData]
    ) -> [Correlation] {
        guard !symptomLogs.isEmpty else { return [] }

        var correlations: [Correlation] = []

        // 1. Medicine helps / adherence impact
        correlations.append(contentsOf: analyzeMedicineImpact(doseLogs: doseLogs, symptomLogs: symptomLogs, medicines: medicines))

        // 2. Side effect detection
        correlations.append(contentsOf: analyzeSideEffects(doseLogs: doseLogs, symptomLogs: symptomLogs, medicines: medicines))

        // 3. Timing correlations
        correlations.append(contentsOf: analyzeTimingCorrelations(doseLogs: doseLogs, symptomLogs: symptomLogs, medicines: medicines))

        // 4. Overall improvement trend
        correlations.append(contentsOf: analyzeImprovementTrend(symptomLogs: symptomLogs))

        // Sort by confidence descending
        return correlations.sorted { $0.confidence > $1.confidence }
    }

    // MARK: - Medicine Impact Analysis

    /// Compares symptom severity on days medicine was taken vs missed
    private func analyzeMedicineImpact(
        doseLogs: [DoseLogData],
        symptomLogs: [SymptomLogData],
        medicines: [MedicineData]
    ) -> [Correlation] {
        let calendar = Calendar.current
        var correlations: [Correlation] = []

        for medicine in medicines {
            let medDoses = doseLogs.filter { $0.medicineId == medicine.id }
            guard medDoses.count >= 5 else { continue }

            // Group doses by day: taken days vs missed days
            let takenDays = Set(medDoses.filter { $0.status == "taken" }.map { calendar.startOfDay(for: $0.scheduledTime) })
            let missedDays = Set(medDoses.filter { $0.status == "missed" || $0.status == "skipped" }.map { calendar.startOfDay(for: $0.scheduledTime) })

            guard !takenDays.isEmpty && !missedDays.isEmpty else { continue }

            // Average overall feeling on taken days vs missed days
            let takenDayLogs = symptomLogs.filter { takenDays.contains(calendar.startOfDay(for: $0.date)) }
            let missedDayLogs = symptomLogs.filter { missedDays.contains(calendar.startOfDay(for: $0.date)) }

            guard !takenDayLogs.isEmpty && !missedDayLogs.isEmpty else { continue }

            let avgFeelingTaken = Double(takenDayLogs.map { $0.overallFeeling }.reduce(0, +)) / Double(takenDayLogs.count)
            let avgFeelingMissed = Double(missedDayLogs.map { $0.overallFeeling }.reduce(0, +)) / Double(missedDayLogs.count)

            let diff = avgFeelingTaken - avgFeelingMissed

            if diff > 0.5 {
                // Medicine helps
                let pctBetter = Int((diff / avgFeelingMissed) * 100)
                let confidence = min(diff / 2.0, 1.0) * min(Double(takenDayLogs.count + missedDayLogs.count) / 14.0, 1.0)

                correlations.append(Correlation(
                    type: .medicineHelps,
                    description: "You feel \(pctBetter)% better on days you take \(medicine.brandName)",
                    confidence: min(confidence, 0.95),
                    medicineName: medicine.brandName,
                    symptomName: nil,
                    insight: "On days you take \(medicine.brandName), your average feeling is \(String(format: "%.1f", avgFeelingTaken))/5 vs \(String(format: "%.1f", avgFeelingMissed))/5 when you miss it.",
                    recommendation: "Keep taking \(medicine.brandName) consistently — it appears to be helping you feel better."
                ))
            } else if diff < -0.3 {
                // Adherence impact — feeling worse on taken days (possible side effects handled separately)
                let confidence = min(abs(diff) / 2.0, 1.0) * min(Double(takenDayLogs.count + missedDayLogs.count) / 14.0, 1.0)

                correlations.append(Correlation(
                    type: .adherenceImpact,
                    description: "Symptoms change when taking \(medicine.brandName)",
                    confidence: min(confidence, 0.85),
                    medicineName: medicine.brandName,
                    symptomName: nil,
                    insight: "Your average feeling on days you take \(medicine.brandName) is \(String(format: "%.1f", avgFeelingTaken))/5 compared to \(String(format: "%.1f", avgFeelingMissed))/5 without it. Discuss this pattern with your doctor.",
                    recommendation: "Share this data with your doctor at your next visit — they may adjust your dosage or timing."
                ))
            }
        }

        return correlations
    }

    // MARK: - Side Effect Detection

    /// Identifies symptoms that appear predominantly on days a specific medicine is taken
    private func analyzeSideEffects(
        doseLogs: [DoseLogData],
        symptomLogs: [SymptomLogData],
        medicines: [MedicineData]
    ) -> [Correlation] {
        let calendar = Calendar.current
        var correlations: [Correlation] = []

        for medicine in medicines {
            let medDoses = doseLogs.filter { $0.medicineId == medicine.id }
            let takenDays = Set(medDoses.filter { $0.status == "taken" }.map { calendar.startOfDay(for: $0.scheduledTime) })
            let notTakenDays = Set(medDoses.filter { $0.status != "taken" }.map { calendar.startOfDay(for: $0.scheduledTime) })

            guard takenDays.count >= 3 && notTakenDays.count >= 2 else { continue }

            // Collect all unique symptom names
            let allSymptomNames = Set(symptomLogs.flatMap { $0.symptoms.map { $0.name } })

            for symptomName in allSymptomNames {
                // Frequency of this symptom on taken days vs not-taken days
                let takenDayLogs = symptomLogs.filter { takenDays.contains(calendar.startOfDay(for: $0.date)) }
                let notTakenDayLogs = symptomLogs.filter { notTakenDays.contains(calendar.startOfDay(for: $0.date)) }

                let symptomOnTakenDays = takenDayLogs.filter { log in
                    log.symptoms.contains { $0.name.lowercased() == symptomName.lowercased() }
                }.count

                let symptomOnNotTakenDays = notTakenDayLogs.filter { log in
                    log.symptoms.contains { $0.name.lowercased() == symptomName.lowercased() }
                }.count

                guard takenDayLogs.count > 0 else { continue }

                let rateOnTaken = Double(symptomOnTakenDays) / Double(takenDayLogs.count)
                let rateOnNotTaken = notTakenDayLogs.isEmpty ? 0 : Double(symptomOnNotTakenDays) / Double(notTakenDayLogs.count)

                // If symptom appears significantly more on taken days
                if rateOnTaken >= 0.5 && rateOnTaken > rateOnNotTaken * 2.0 && symptomOnTakenDays >= 3 {
                    let pct = Int(rateOnTaken * 100)
                    let sampleSize = Double(takenDayLogs.count + notTakenDayLogs.count)
                    let confidence = min((rateOnTaken - rateOnNotTaken) * min(sampleSize / 14.0, 1.0), 0.90)

                    correlations.append(Correlation(
                        type: .medicineSideEffect,
                        description: "\(symptomName) reported on \(pct)% of days you take \(medicine.brandName)",
                        confidence: max(confidence, 0.3),
                        medicineName: medicine.brandName,
                        symptomName: symptomName,
                        insight: "\(symptomName) appears on \(pct)% of days when you take \(medicine.brandName), but only \(Int(rateOnNotTaken * 100))% on other days. This could be a side effect.",
                        recommendation: "Mention this pattern to your doctor. They may suggest taking \(medicine.brandName) at a different time or with food."
                    ))
                }
            }
        }

        return correlations
    }

    // MARK: - Timing Correlations

    /// Analyzes whether symptoms correlate with medicine timing (e.g., empty stomach)
    private func analyzeTimingCorrelations(
        doseLogs: [DoseLogData],
        symptomLogs: [SymptomLogData],
        medicines: [MedicineData]
    ) -> [Correlation] {
        let calendar = Calendar.current
        var correlations: [Correlation] = []

        for medicine in medicines {
            let takenDoses = doseLogs.filter { $0.medicineId == medicine.id && $0.status == "taken" && $0.actualTime != nil }
            guard takenDoses.count >= 5 else { continue }

            // Split into morning (before 12) and evening (after 17) doses
            let morningDoses = takenDoses.filter {
                guard let actual = $0.actualTime else { return false }
                return calendar.component(.hour, from: actual) < 12
            }
            let eveningDoses = takenDoses.filter {
                guard let actual = $0.actualTime else { return false }
                return calendar.component(.hour, from: actual) >= 17
            }

            // Check if symptoms differ by timing
            if morningDoses.count >= 3 && eveningDoses.count >= 3 {
                let morningDays = Set(morningDoses.compactMap { $0.actualTime }.map { calendar.startOfDay(for: $0) })
                let eveningDays = Set(eveningDoses.compactMap { $0.actualTime }.map { calendar.startOfDay(for: $0) })

                let morningSymptomLogs = symptomLogs.filter { morningDays.contains(calendar.startOfDay(for: $0.date)) }
                let eveningSymptomLogs = symptomLogs.filter { eveningDays.contains(calendar.startOfDay(for: $0.date)) }

                guard !morningSymptomLogs.isEmpty && !eveningSymptomLogs.isEmpty else { continue }

                let avgMorning = Double(morningSymptomLogs.map { $0.overallFeeling }.reduce(0, +)) / Double(morningSymptomLogs.count)
                let avgEvening = Double(eveningSymptomLogs.map { $0.overallFeeling }.reduce(0, +)) / Double(eveningSymptomLogs.count)

                let diff = abs(avgMorning - avgEvening)
                if diff > 0.8 {
                    let betterTime = avgMorning > avgEvening ? "morning" : "evening"
                    let worseTime = avgMorning > avgEvening ? "evening" : "morning"
                    let confidence = min(diff / 2.5, 0.85) * min(Double(morningSymptomLogs.count + eveningSymptomLogs.count) / 10.0, 1.0)

                    correlations.append(Correlation(
                        type: .timingCorrelation,
                        description: "You feel better taking \(medicine.brandName) in the \(betterTime)",
                        confidence: max(confidence, 0.3),
                        medicineName: medicine.brandName,
                        symptomName: nil,
                        insight: "When you take \(medicine.brandName) in the \(betterTime), your average feeling is \(String(format: "%.1f", max(avgMorning, avgEvening)))/5 vs \(String(format: "%.1f", min(avgMorning, avgEvening)))/5 in the \(worseTime).",
                        recommendation: "Consider taking \(medicine.brandName) in the \(betterTime) if your doctor approves. \(medicine.mealTiming.isEmpty ? "" : "Current timing: \(medicine.mealTiming).")"
                    ))
                }
            }

            // Meal timing correlation for medicines marked as before/after food
            if medicine.mealTiming.lowercased().contains("before") || medicine.mealTiming.lowercased().contains("empty") {
                // Check for stomach-related symptoms
                let stomachSymptoms = ["nausea", "stomach pain", "stomach ache", "upset stomach", "vomiting", "bloating", "acidity"]
                let takenDays = Set(takenDoses.compactMap { $0.actualTime }.map { calendar.startOfDay(for: $0) })
                let logsOnTakenDays = symptomLogs.filter { takenDays.contains(calendar.startOfDay(for: $0.date)) }

                let stomachIssues = logsOnTakenDays.filter { log in
                    log.symptoms.contains { entry in
                        stomachSymptoms.contains { entry.name.lowercased().contains($0) }
                    }
                }

                if logsOnTakenDays.count >= 3 {
                    let rate = Double(stomachIssues.count) / Double(logsOnTakenDays.count)
                    if rate >= 0.4 {
                        let pct = Int(rate * 100)
                        correlations.append(Correlation(
                            type: .timingCorrelation,
                            description: "Stomach issues on \(pct)% of days taking \(medicine.brandName) on empty stomach",
                            confidence: min(rate * 0.8, 0.80),
                            medicineName: medicine.brandName,
                            symptomName: "Stomach issues",
                            insight: "You report stomach-related symptoms on \(pct)% of days when taking \(medicine.brandName), which is prescribed on an empty stomach.",
                            recommendation: "Ask your doctor if you can take \(medicine.brandName) with a light snack to reduce stomach discomfort."
                        ))
                    }
                }
            }
        }

        return correlations
    }

    // MARK: - Improvement Trend

    /// Tracks overall feeling trend over time
    private func analyzeImprovementTrend(symptomLogs: [SymptomLogData]) -> [Correlation] {
        let sorted = symptomLogs.sorted { $0.date < $1.date }
        guard sorted.count >= 4 else { return [] }

        // Compare first third vs last third
        let thirdSize = max(sorted.count / 3, 1)
        let firstThird = Array(sorted.prefix(thirdSize))
        let lastThird = Array(sorted.suffix(thirdSize))

        let firstAvg = Double(firstThird.map { $0.overallFeeling }.reduce(0, +)) / Double(firstThird.count)
        let lastAvg = Double(lastThird.map { $0.overallFeeling }.reduce(0, +)) / Double(lastThird.count)

        let diff = lastAvg - firstAvg
        guard abs(diff) > 0.3 else { return [] }

        let daySpan = Calendar.current.dateComponents([.day], from: sorted.first!.date, to: sorted.last!.date).day ?? 1

        if diff > 0 {
            let confidence = min(diff / 2.0, 0.90) * min(Double(sorted.count) / 10.0, 1.0)
            return [Correlation(
                type: .improvementTrend,
                description: "Overall feeling improved from \(String(format: "%.1f", firstAvg)) to \(String(format: "%.1f", lastAvg)) over \(daySpan) days",
                confidence: max(confidence, 0.3),
                medicineName: nil,
                symptomName: nil,
                insight: "Your overall feeling has improved from \(String(format: "%.1f", firstAvg))/5 to \(String(format: "%.1f", lastAvg))/5 over the past \(daySpan) days. Your treatment appears to be working.",
                recommendation: "Keep up the great work! Continue taking your medicines as prescribed."
            )]
        } else {
            let confidence = min(abs(diff) / 2.0, 0.90) * min(Double(sorted.count) / 10.0, 1.0)
            return [Correlation(
                type: .improvementTrend,
                description: "Overall feeling declined from \(String(format: "%.1f", firstAvg)) to \(String(format: "%.1f", lastAvg)) over \(daySpan) days",
                confidence: max(confidence, 0.3),
                medicineName: nil,
                symptomName: nil,
                insight: "Your overall feeling has dropped from \(String(format: "%.1f", firstAvg))/5 to \(String(format: "%.1f", lastAvg))/5 over the past \(daySpan) days.",
                recommendation: "Consider reaching out to your doctor to discuss how you've been feeling. Share your symptom logs for a more productive conversation."
            )]
        }
    }

    // MARK: - Convenience Converter

    /// Convert SwiftData models to data structs for analysis
    static func convertDoseLog(_ log: DoseLog, medicineId: UUID, medicineName: String) -> DoseLogData {
        DoseLogData(
            medicineId: medicineId,
            medicineName: medicineName,
            scheduledTime: log.scheduledTime,
            status: log.status.rawValue.lowercased(),
            actualTime: log.actualTime
        )
    }

    static func convertSymptomLog(_ log: SymptomLog) -> SymptomLogData {
        SymptomLogData(
            date: log.date,
            overallFeeling: log.overallFeeling.rawValue,
            symptoms: log.symptoms.map { ($0.name, $0.severity.rawValue) },
            notes: log.notes
        )
    }
}
