import Foundation

// MARK: - Input Structs (decoupled from SwiftData)

struct MedicineInfo: Identifiable {
    let id: UUID
    let brandName: String
    let genericName: String?
    let dosage: String
    let doseForm: DoseForm
    let frequency: MedicineFrequency
    let mealTiming: MealTiming
    let category: DrugCategory?
    let startDate: Date
    let isActive: Bool
    let isCritical: Bool
}

struct DoseLogInfo: Identifiable {
    let id: UUID
    let medicineName: String
    let medicineId: UUID
    let scheduledTime: Date
    let actualTime: Date?
    let status: DoseStatus
}

struct SymptomLogInfo: Identifiable {
    let id: UUID
    let date: Date
    let overallFeeling: FeelingLevel
    let symptoms: [SymptomEntry]
    let notes: String?
}

// MARK: - Output Structs

struct DoctorVisitSummary {
    let patientInfo: PatientInfoSummary
    let medicationSummary: [MedicationAdherenceSummary]
    let adherenceOverview: AdherenceOverview
    let symptomSummary: SymptomOverview
    let healthScoreInfo: HealthScoreOverview
    let questionsToAsk: [String]
    let concerns: [String]
    let formattedText: String
    let generatedDate: Date
    let dateRange: Int
}

struct PatientInfoSummary {
    let name: String
    let age: Int?
    let gender: String?
    let conditions: [String]
    let allergies: [String]
    let bloodGroup: String?
}

struct MedicationAdherenceSummary: Identifiable {
    let id: UUID
    let name: String
    let genericName: String?
    let dosage: String
    let frequency: String
    let adherencePercentage: Double
    let totalDoses: Int
    let takenDoses: Int
    let missedDoses: Int
    let isCritical: Bool
}

struct AdherenceOverview {
    let overallPercentage: Double
    let bestPerforming: String?
    let worstPerforming: String?
    let totalDoses: Int
    let takenDoses: Int
    let missedDoses: Int
}

struct SymptomOverview {
    let mostFrequentSymptoms: [(name: String, count: Int)]
    let trend: SymptomTrend
    let averageFeeling: Double
    let totalLogs: Int
}

struct HealthScoreOverview {
    let currentScore: Int
    let grade: String
    let trend: String
}

// MARK: - Service

@Observable
final class DoctorVisitPrepService {

    func prepareSummary(
        profile: UserProfile,
        medicines: [MedicineInfo],
        doseLogs: [DoseLogInfo],
        symptomLogs: [SymptomLogInfo],
        healthScore: HealthScore,
        dateRange: Int
    ) -> DoctorVisitSummary {
        let cutoffDate = Calendar.current.date(byAdding: .day, value: -dateRange, to: Date()) ?? Date()

        let filteredDoseLogs = doseLogs.filter { $0.scheduledTime >= cutoffDate }
        let filteredSymptomLogs = symptomLogs.filter { $0.date >= cutoffDate }
        let activeMedicines = medicines.filter { $0.isActive }

        let patientInfo = buildPatientInfo(profile: profile)
        let medicationSummary = buildMedicationSummary(medicines: activeMedicines, doseLogs: filteredDoseLogs)
        let adherenceOverview = buildAdherenceOverview(medicationSummary: medicationSummary, doseLogs: filteredDoseLogs)
        let symptomSummary = buildSymptomSummary(symptomLogs: filteredSymptomLogs)
        let healthScoreInfo = HealthScoreOverview(
            currentScore: healthScore.total,
            grade: healthScore.grade.rawValue,
            trend: healthScore.trend.rawValue
        )
        let questions = generateQuestions(
            medicationSummary: medicationSummary,
            symptomSummary: symptomSummary,
            adherenceOverview: adherenceOverview,
            medicines: activeMedicines
        )
        let concerns = detectConcerns(
            adherenceOverview: adherenceOverview,
            symptomSummary: symptomSummary,
            medicationSummary: medicationSummary,
            healthScore: healthScore
        )

        let formattedText = formatSummaryText(
            patientInfo: patientInfo,
            medicationSummary: medicationSummary,
            adherenceOverview: adherenceOverview,
            symptomSummary: symptomSummary,
            healthScoreInfo: healthScoreInfo,
            questions: questions,
            concerns: concerns,
            dateRange: dateRange
        )

        return DoctorVisitSummary(
            patientInfo: patientInfo,
            medicationSummary: medicationSummary,
            adherenceOverview: adherenceOverview,
            symptomSummary: symptomSummary,
            healthScoreInfo: healthScoreInfo,
            questionsToAsk: questions,
            concerns: concerns,
            formattedText: formattedText,
            generatedDate: Date(),
            dateRange: dateRange
        )
    }

    // MARK: - Patient Info

    private func buildPatientInfo(profile: UserProfile) -> PatientInfoSummary {
        PatientInfoSummary(
            name: profile.name,
            age: profile.age,
            gender: profile.gender?.rawValue,
            conditions: profile.knownConditions,
            allergies: profile.allergies,
            bloodGroup: profile.bloodGroup
        )
    }

    // MARK: - Medication Summary

    private func buildMedicationSummary(medicines: [MedicineInfo], doseLogs: [DoseLogInfo]) -> [MedicationAdherenceSummary] {
        medicines.map { med in
            let medLogs = doseLogs.filter { $0.medicineId == med.id }
            let pastLogs = medLogs.filter { $0.scheduledTime <= Date() }
            let total = pastLogs.count
            let taken = pastLogs.filter { $0.status == .taken }.count
            let missed = pastLogs.filter { $0.status == .missed }.count
            let adherence = total > 0 ? Double(taken) / Double(total) : 0

            return MedicationAdherenceSummary(
                id: med.id,
                name: med.brandName,
                genericName: med.genericName,
                dosage: med.dosage,
                frequency: med.frequency.rawValue,
                adherencePercentage: adherence,
                totalDoses: total,
                takenDoses: taken,
                missedDoses: missed,
                isCritical: med.isCritical
            )
        }
        .sorted { $0.adherencePercentage < $1.adherencePercentage } // worst first for doctor attention
    }

    // MARK: - Adherence Overview

    private func buildAdherenceOverview(medicationSummary: [MedicationAdherenceSummary], doseLogs: [DoseLogInfo]) -> AdherenceOverview {
        let pastLogs = doseLogs.filter { $0.scheduledTime <= Date() }
        let totalDoses = pastLogs.count
        let takenDoses = pastLogs.filter { $0.status == .taken }.count
        let missedDoses = pastLogs.filter { $0.status == .missed }.count
        let overall = totalDoses > 0 ? Double(takenDoses) / Double(totalDoses) : 0

        let best = medicationSummary.max(by: { $0.adherencePercentage < $1.adherencePercentage })
        let worst = medicationSummary.min(by: { $0.adherencePercentage < $1.adherencePercentage })

        return AdherenceOverview(
            overallPercentage: overall,
            bestPerforming: best?.name,
            worstPerforming: worst?.name,
            totalDoses: totalDoses,
            takenDoses: takenDoses,
            missedDoses: missedDoses
        )
    }

    // MARK: - Symptom Summary

    private func buildSymptomSummary(symptomLogs: [SymptomLogInfo]) -> SymptomOverview {
        // Count all symptoms
        var symptomCounts: [String: Int] = [:]
        for log in symptomLogs {
            for symptom in log.symptoms {
                symptomCounts[symptom.name, default: 0] += 1
            }
        }

        let sorted = symptomCounts.sorted { $0.value > $1.value }
        let topSymptoms = Array(sorted.prefix(5)).map { (name: $0.key, count: $0.value) }

        // Trend
        let trend: SymptomTrend
        if symptomLogs.count >= 2 {
            let sortedLogs = symptomLogs.sorted { $0.date < $1.date }
            let midpoint = sortedLogs.count / 2
            let firstHalf = sortedLogs.prefix(midpoint)
            let secondHalf = sortedLogs.suffix(from: midpoint)

            let firstAvg = firstHalf.map { Double($0.overallFeeling.rawValue) }.reduce(0, +) / Double(firstHalf.count)
            let secondAvg = secondHalf.map { Double($0.overallFeeling.rawValue) }.reduce(0, +) / Double(secondHalf.count)

            let diff = secondAvg - firstAvg
            if diff > 0.3 {
                trend = .improving
            } else if diff < -0.3 {
                trend = .worsening
            } else {
                trend = .stable
            }
        } else {
            trend = .noData
        }

        let avgFeeling: Double
        if !symptomLogs.isEmpty {
            avgFeeling = symptomLogs.map { Double($0.overallFeeling.rawValue) }.reduce(0, +) / Double(symptomLogs.count)
        } else {
            avgFeeling = 0
        }

        return SymptomOverview(
            mostFrequentSymptoms: topSymptoms,
            trend: trend,
            averageFeeling: avgFeeling,
            totalLogs: symptomLogs.count
        )
    }

    // MARK: - Auto-Generate Questions

    private func generateQuestions(
        medicationSummary: [MedicationAdherenceSummary],
        symptomSummary: SymptomOverview,
        adherenceOverview: AdherenceOverview,
        medicines: [MedicineInfo]
    ) -> [String] {
        var questions: [String] = []

        // Questions about persistent symptoms
        for (name, count) in symptomSummary.mostFrequentSymptoms where count >= 3 {
            questions.append("I've been experiencing \(name.lowercased()) frequently (\(count) times recently). Could this be related to my medication?")
        }

        // Questions about low-adherence medicines
        for med in medicationSummary where med.adherencePercentage < 0.6 && med.totalDoses > 3 {
            questions.append("I've been having trouble staying consistent with \(med.name). Are there alternative forms or timings?")
        }

        // Questions about worsening symptoms
        if symptomSummary.trend == .worsening {
            questions.append("My overall symptoms seem to be getting worse. Should we review my current treatment plan?")
        }

        // Questions about multiple medications
        if medicines.count >= 4 {
            questions.append("I'm currently on \(medicines.count) medications. Are there any interactions I should be aware of?")
        }

        // Questions about critical medicines
        let criticalLowAdherence = medicationSummary.filter { $0.isCritical && $0.adherencePercentage < 0.8 }
        for med in criticalLowAdherence {
            questions.append("\(med.name) is critical for my treatment but I've only managed \(Int(med.adherencePercentage * 100))% adherence. What can I do to improve?")
        }

        // Generic helpful questions
        if medicines.contains(where: { $0.category == .antibiotic }) {
            questions.append("I'm on antibiotics. Do I need probiotics to protect my gut health?")
        }

        if questions.isEmpty {
            questions.append("Based on my current health data, is my treatment plan on track?")
            questions.append("Are there any lifestyle changes I should make to improve my health outcomes?")
        }

        return Array(questions.prefix(6))
    }

    // MARK: - Auto-Detect Concerns

    private func detectConcerns(
        adherenceOverview: AdherenceOverview,
        symptomSummary: SymptomOverview,
        medicationSummary: [MedicationAdherenceSummary],
        healthScore: HealthScore
    ) -> [String] {
        var concerns: [String] = []

        // Low overall adherence
        if adherenceOverview.overallPercentage < 0.6 {
            concerns.append("Low overall adherence (\(Int(adherenceOverview.overallPercentage * 100))%) may be reducing treatment effectiveness.")
        }

        // Worsening symptoms
        if symptomSummary.trend == .worsening {
            concerns.append("Symptom trend is worsening. Review of treatment plan may be needed.")
        }

        // Specific medicines with very low adherence
        for med in medicationSummary where med.adherencePercentage < 0.4 && med.totalDoses > 5 {
            concerns.append("\(med.name) has very low adherence (\(Int(med.adherencePercentage * 100))%). Patient may need alternative dosing or formulation.")
        }

        // Critical medicines not taken
        for med in medicationSummary where med.isCritical && med.adherencePercentage < 0.7 {
            concerns.append("Critical medication \(med.name) has only \(Int(med.adherencePercentage * 100))% adherence.")
        }

        // Declining health score
        if healthScore.trend == .declining {
            concerns.append("Health score trend is declining (currently \(healthScore.total)/100, grade \(healthScore.grade.rawValue)).")
        }

        // High missed doses
        if adherenceOverview.missedDoses > 10 {
            concerns.append("\(adherenceOverview.missedDoses) doses were missed in the selected period.")
        }

        return concerns
    }

    // MARK: - Formatted Text

    private func formatSummaryText(
        patientInfo: PatientInfoSummary,
        medicationSummary: [MedicationAdherenceSummary],
        adherenceOverview: AdherenceOverview,
        symptomSummary: SymptomOverview,
        healthScoreInfo: HealthScoreOverview,
        questions: [String],
        concerns: [String],
        dateRange: Int
    ) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .medium

        var text = ""

        // Header
        text += "DOCTOR VISIT HEALTH SUMMARY\n"
        text += "Generated: \(dateFormatter.string(from: Date()))\n"
        text += "Period: Last \(dateRange) days\n"
        text += String(repeating: "=", count: 40) + "\n\n"

        // Patient Info
        text += "PATIENT INFORMATION\n"
        text += String(repeating: "-", count: 25) + "\n"
        text += "Name: \(patientInfo.name)\n"
        if let age = patientInfo.age { text += "Age: \(age) years\n" }
        if let gender = patientInfo.gender { text += "Gender: \(gender)\n" }
        if let blood = patientInfo.bloodGroup { text += "Blood Group: \(blood)\n" }
        if !patientInfo.conditions.isEmpty {
            text += "Known Conditions: \(patientInfo.conditions.joined(separator: ", "))\n"
        }
        if !patientInfo.allergies.isEmpty {
            text += "Allergies: \(patientInfo.allergies.joined(separator: ", "))\n"
        }
        text += "\n"

        // Medications
        text += "CURRENT MEDICATIONS\n"
        text += String(repeating: "-", count: 25) + "\n"
        for med in medicationSummary {
            let generic = med.genericName.map { " (\($0))" } ?? ""
            text += "\(med.name)\(generic) - \(med.dosage), \(med.frequency)\n"
            text += "  Adherence: \(Int(med.adherencePercentage * 100))% (\(med.takenDoses)/\(med.totalDoses) doses taken)\n"
            if med.missedDoses > 0 {
                text += "  Missed: \(med.missedDoses) doses\n"
            }
            if med.isCritical {
                text += "  [CRITICAL MEDICATION]\n"
            }
        }
        text += "\n"

        // Adherence Overview
        text += "ADHERENCE OVERVIEW\n"
        text += String(repeating: "-", count: 25) + "\n"
        text += "Overall Adherence: \(Int(adherenceOverview.overallPercentage * 100))%\n"
        text += "Total Doses: \(adherenceOverview.totalDoses) | Taken: \(adherenceOverview.takenDoses) | Missed: \(adherenceOverview.missedDoses)\n"
        if let best = adherenceOverview.bestPerforming {
            text += "Best: \(best)\n"
        }
        if let worst = adherenceOverview.worstPerforming, medicationSummary.count > 1 {
            text += "Needs Improvement: \(worst)\n"
        }
        text += "\n"

        // Symptoms
        text += "SYMPTOM SUMMARY\n"
        text += String(repeating: "-", count: 25) + "\n"
        text += "Symptom Logs: \(symptomSummary.totalLogs)\n"
        text += "Trend: \(symptomSummary.trend.rawValue)\n"
        if symptomSummary.averageFeeling > 0 {
            let feelingLabel: String
            switch symptomSummary.averageFeeling {
            case ..<1.5: feelingLabel = "Terrible"
            case 1.5..<2.5: feelingLabel = "Not Good"
            case 2.5..<3.5: feelingLabel = "Okay"
            case 3.5..<4.5: feelingLabel = "Good"
            default: feelingLabel = "Great"
            }
            text += "Average Feeling: \(feelingLabel)\n"
        }
        if !symptomSummary.mostFrequentSymptoms.isEmpty {
            text += "Frequent Symptoms:\n"
            for (name, count) in symptomSummary.mostFrequentSymptoms {
                text += "  - \(name): \(count) times\n"
            }
        }
        text += "\n"

        // Health Score
        text += "HEALTH SCORE\n"
        text += String(repeating: "-", count: 25) + "\n"
        text += "Score: \(healthScoreInfo.currentScore)/100 (Grade: \(healthScoreInfo.grade))\n"
        text += "Trend: \(healthScoreInfo.trend)\n"
        text += "\n"

        // Concerns
        if !concerns.isEmpty {
            text += "CONCERNS\n"
            text += String(repeating: "-", count: 25) + "\n"
            for concern in concerns {
                text += "* \(concern)\n"
            }
            text += "\n"
        }

        // Questions
        text += "SUGGESTED QUESTIONS FOR DOCTOR\n"
        text += String(repeating: "-", count: 25) + "\n"
        for (i, question) in questions.enumerated() {
            text += "\(i + 1). \(question)\n"
        }
        text += "\n"

        text += String(repeating: "=", count: 40) + "\n"
        text += "Generated by MedCare App\n"

        return text
    }
}
