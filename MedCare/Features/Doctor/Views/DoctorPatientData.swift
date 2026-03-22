import Foundation
import SwiftUI

// MARK: - Computed Patient Data (from real SwiftData)

/// Replaces DoctorMockPatient with real data derived from UserProfile + Episodes + DoseLogs + SymptomLogs
struct DoctorPatientData: Identifiable {
    let id: UUID
    let name: String
    let age: Int
    let avatarEmoji: String
    let primaryCondition: String
    let status: PatientStatus
    let lastVitalLabel: String
    let lastVitalValue: String
    let lastVitalTime: String
    let adherencePercent: Int
    let heartRate: Int
    let bpSystolic: Int
    let bpDiastolic: Int
    let spO2: Int
    let glucose: Int
    let hrTrend: VitalTrend
    let bpTrend: VitalTrend
    let spO2Trend: VitalTrend
    let glucoseTrend: VitalTrend
    let medications: [DoctorPatientMedication]
    let recentSymptoms: [DoctorPatientSymptom]
    let dailyAdherence7Days: [Int]

    /// Build from a real UserProfile
    static func from(profile: UserProfile) -> DoctorPatientData {
        let profileAge = profile.age ?? 0
        let activeEpisodes = profile.episodes.filter { $0.status == .active }
        let allEpisodes = profile.episodes

        // Primary condition from first active episode diagnosis, or known conditions
        let primaryCondition: String = {
            if let diag = activeEpisodes.first?.diagnosis, !diag.isEmpty {
                return diag
            }
            if let first = activeEpisodes.first {
                return first.title
            }
            if let cond = profile.knownConditions.first {
                return cond
            }
            return "No condition recorded"
        }()

        // Gather all active medicines across all active episodes
        let allMedicines = activeEpisodes.flatMap { $0.activeMedicines }

        // Compute per-medicine adherence
        let medData: [DoctorPatientMedication] = allMedicines.map { med in
            let pastLogs = med.doseLogs.filter { $0.scheduledTime <= Date() }
            let taken = pastLogs.filter { $0.status == .taken }.count
            let adherence = pastLogs.isEmpty ? 100 : Int((Double(taken) / Double(pastLogs.count)) * 100)
            return DoctorPatientMedication(
                name: med.brandName,
                dosage: med.dosage,
                frequency: med.frequency.rawValue,
                adherencePercent: adherence
            )
        }

        // Overall adherence from all dose logs in active episodes
        let allDoseLogs = allMedicines.flatMap { $0.doseLogs }
        let pastDoseLogs = allDoseLogs.filter { $0.scheduledTime <= Date() }
        let takenCount = pastDoseLogs.filter { $0.status == .taken }.count
        let overallAdherence = pastDoseLogs.isEmpty ? 100 : Int((Double(takenCount) / Double(pastDoseLogs.count)) * 100)

        // Daily adherence for last 7 days
        let dailyAdherence = computeDailyAdherence(doseLogs: allDoseLogs, days: 7)

        // Missed doses in last 24 hours
        let last24h = Date().addingTimeInterval(-86400)
        let missedLast24h = pastDoseLogs.filter {
            $0.scheduledTime >= last24h && ($0.status == .missed || $0.status == .skipped)
        }.count

        // Latest vitals from symptom logs
        let allSymptomLogs = allEpisodes.flatMap { $0.symptomLogs }.sorted { $0.date > $1.date }
        let latestVitals = allSymptomLogs.first

        let bpSys = latestVitals?.bloodPressureSystolic ?? 120
        let bpDia = latestVitals?.bloodPressureDiastolic ?? 80
        let hr = 72 // HealthKit not available here, default
        let spo2 = 98 // Default
        let glucose = 100 // Default

        // Determine last vital for display
        var lastVitalLabel = "BP"
        var lastVitalValue = "\(bpSys)/\(bpDia)"
        var lastVitalTime = "N/A"

        if let lv = latestVitals {
            let interval = Date().timeIntervalSince(lv.date)
            if interval < 3600 {
                lastVitalTime = "\(Int(interval / 60))m ago"
            } else if interval < 86400 {
                lastVitalTime = "\(Int(interval / 3600))h ago"
            } else {
                lastVitalTime = "\(Int(interval / 86400))d ago"
            }

            if lv.bloodPressureSystolic != nil {
                lastVitalLabel = "BP"
                lastVitalValue = "\(bpSys)/\(bpDia)"
            } else if lv.temperature != nil {
                lastVitalLabel = "Temp"
                lastVitalValue = String(format: "%.1f\u{00B0}F", lv.temperature ?? 0)
            }
        }

        // Recent symptoms from symptom logs in last 7 days
        let sevenDaysAgo = Calendar.current.date(byAdding: .day, value: -7, to: Date()) ?? Date()
        let recentSymptomEntries: [DoctorPatientSymptom] = allSymptomLogs
            .filter { $0.date >= sevenDaysAgo }
            .flatMap { log in
                log.symptoms.map { entry in
                    let daysAgo = Calendar.current.dateComponents([.day], from: log.date, to: Date()).day ?? 0
                    return DoctorPatientSymptom(
                        name: entry.name,
                        severity: entry.severity.label,
                        daysAgo: daysAgo
                    )
                }
            }

        // Check for critical vital breach
        let hasCriticalVitalBreach = bpSys > 160 || bpDia > 100 || spo2 < 92 || glucose > 250

        // Traffic-light status
        let status: PatientStatus = {
            if overallAdherence < 50 || missedLast24h >= 3 || hasCriticalVitalBreach {
                return .critical
            } else if overallAdherence < 80 || missedLast24h >= 1 {
                return .warning
            } else {
                return .stable
            }
        }()

        return DoctorPatientData(
            id: profile.id,
            name: profile.name,
            age: profileAge,
            avatarEmoji: profile.avatarEmoji,
            primaryCondition: primaryCondition,
            status: status,
            lastVitalLabel: lastVitalLabel,
            lastVitalValue: lastVitalValue,
            lastVitalTime: lastVitalTime,
            adherencePercent: overallAdherence,
            heartRate: hr,
            bpSystolic: bpSys,
            bpDiastolic: bpDia,
            spO2: spo2,
            glucose: glucose,
            hrTrend: .stable,
            bpTrend: bpSys > 140 ? .up : .stable,
            spO2Trend: .stable,
            glucoseTrend: .stable,
            medications: medData,
            recentSymptoms: recentSymptomEntries,
            dailyAdherence7Days: dailyAdherence
        )
    }

    /// Compute daily adherence percentages for the last N days
    private static func computeDailyAdherence(doseLogs: [DoseLog], days: Int) -> [Int] {
        let calendar = Calendar.current
        var result: [Int] = []

        for dayOffset in stride(from: -(days - 1), through: 0, by: 1) {
            let dayStart = calendar.startOfDay(for: calendar.date(byAdding: .day, value: dayOffset, to: Date()) ?? Date())
            let dayEnd = calendar.date(byAdding: .day, value: 1, to: dayStart)!

            let dayLogs = doseLogs.filter {
                $0.scheduledTime >= dayStart && $0.scheduledTime < dayEnd
            }

            if dayLogs.isEmpty {
                result.append(100) // No doses scheduled = full adherence
            } else {
                let taken = dayLogs.filter { $0.status == .taken }.count
                result.append(Int((Double(taken) / Double(dayLogs.count)) * 100))
            }
        }

        return result
    }
}

struct DoctorPatientMedication: Identifiable {
    let id = UUID()
    let name: String
    let dosage: String
    let frequency: String
    let adherencePercent: Int
}

struct DoctorPatientSymptom: Identifiable {
    let id = UUID()
    let name: String
    let severity: String
    let daysAgo: Int
}

// MARK: - Alert computed from real data

struct DoctorAlert: Identifiable {
    let id = UUID()
    let patientName: String
    let message: String
    let severity: PatientStatus
    let timeAgo: String
}

enum PatientStatus: String {
    case critical = "Critical"
    case warning = "Needs Attention"
    case stable = "Stable"

    var color: Color {
        switch self {
        case .critical: return MCColors.error
        case .warning: return MCColors.warning
        case .stable: return MCColors.success
        }
    }

    var icon: String {
        switch self {
        case .critical: return "exclamationmark.triangle.fill"
        case .warning: return "exclamationmark.circle.fill"
        case .stable: return "checkmark.circle.fill"
        }
    }
}

enum VitalTrend: String {
    case up = "arrow.up.right"
    case down = "arrow.down.right"
    case stable = "arrow.right"
}

// MARK: - Alert Generation from Real Data

extension DoctorPatientData {
    /// Generate real alerts from patient data
    func generateAlerts() -> [DoctorAlert] {
        var alerts: [DoctorAlert] = []

        if bpSystolic > 140 || bpDiastolic > 90 {
            alerts.append(DoctorAlert(
                patientName: name,
                message: "BP elevated at \(bpSystolic)/\(bpDiastolic)",
                severity: bpSystolic > 160 ? .critical : .warning,
                timeAgo: lastVitalTime
            ))
        }

        if adherencePercent < 50 {
            alerts.append(DoctorAlert(
                patientName: name,
                message: "Adherence critically low at \(adherencePercent)%",
                severity: .critical,
                timeAgo: "This week"
            ))
        } else if adherencePercent < 75 {
            let missedMeds = medications.filter { $0.adherencePercent < 60 }.map(\.name)
            if !missedMeds.isEmpty {
                alerts.append(DoctorAlert(
                    patientName: name,
                    message: "Low adherence for \(missedMeds.joined(separator: ", "))",
                    severity: .warning,
                    timeAgo: "This week"
                ))
            }
        }

        if glucose > 250 {
            alerts.append(DoctorAlert(
                patientName: name,
                message: "Blood glucose at \(glucose) mg/dL",
                severity: .critical,
                timeAgo: lastVitalTime
            ))
        }

        if spO2 < 95 {
            alerts.append(DoctorAlert(
                patientName: name,
                message: "SpO2 dropped to \(spO2)%",
                severity: spO2 < 92 ? .critical : .warning,
                timeAgo: lastVitalTime
            ))
        }

        return alerts
    }
}
