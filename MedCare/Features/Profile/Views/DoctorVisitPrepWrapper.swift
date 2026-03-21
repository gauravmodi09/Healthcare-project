import SwiftUI
import SwiftData

/// Wrapper that assembles data for DoctorVisitPrepView from the active profile
struct DoctorVisitPrepWrapper: View {
    @Environment(\.dismiss) private var dismiss
    @Query private var users: [User]

    private var activeProfile: UserProfile? { users.first?.activeProfile }

    var body: some View {
        NavigationStack {
            if let profile = activeProfile {
                prepView(for: profile)
            } else {
                ContentUnavailableView(
                    "No Active Profile",
                    systemImage: "person.crop.circle.badge.questionmark",
                    description: Text("Set up a profile first to prepare for your doctor visit.")
                )
            }
        }
    }

    private func prepView(for profile: UserProfile) -> some View {
        let allMedicines: [Medicine] = profile.episodes.flatMap { $0.medicines }
        let activeMeds: [Medicine] = allMedicines.filter { $0.isActive }

        let medicines: [MedicineInfo] = activeMeds.map { med in
            MedicineInfo(
                id: med.id,
                brandName: med.brandName,
                genericName: med.genericName,
                dosage: med.dosage,
                doseForm: med.doseForm,
                frequency: med.frequency,
                mealTiming: med.mealTiming,
                category: nil,
                startDate: med.startDate,
                isActive: med.isActive,
                isCritical: med.isCritical
            )
        }

        var doseLogsList: [DoseLogInfo] = []
        for med in allMedicines {
            for log in med.doseLogs {
                doseLogsList.append(DoseLogInfo(
                    id: log.id,
                    medicineName: med.brandName,
                    medicineId: med.id,
                    scheduledTime: log.scheduledTime,
                    actualTime: log.actualTime,
                    status: log.status
                ))
            }
        }

        let allSymptomLogs: [SymptomLog] = profile.episodes.flatMap { $0.symptomLogs }
        let symptomLogs: [SymptomLogInfo] = allSymptomLogs.map { log in
            SymptomLogInfo(
                id: log.id,
                date: log.date,
                overallFeeling: log.overallFeeling,
                symptoms: log.symptoms,
                notes: log.notes
            )
        }

        let adherence = calculateAdherence(doseLogsList)
        let healthScore = HealthScoreService().calculateScore(
            adherencePercentage: adherence,
            symptomTrend: .stable,
            currentStreak: 5,
            completenessScore: 0.8
        )

        return DoctorVisitPrepView(
            profile: profile,
            medicines: medicines,
            doseLogs: doseLogsList,
            symptomLogs: symptomLogs,
            healthScore: healthScore
        )
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("Done") { dismiss() }
                    .foregroundStyle(MCColors.primaryTeal)
            }
        }
    }

    private func calculateAdherence(_ logs: [DoseLogInfo]) -> Double {
        let past = logs.filter { $0.scheduledTime <= Date() }
        guard !past.isEmpty else { return 1.0 }
        return Double(past.filter { $0.status == .taken }.count) / Double(past.count)
    }
}
