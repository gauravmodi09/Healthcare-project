import Foundation
import SwiftData

/// Exports all user data as a portable JSON file (DPDPA 2023 Data Portability)
@Observable
final class ExportService {

    // MARK: - Export All Data

    func exportAllData(for profile: UserProfile) -> URL? {
        let exportData = buildExportPayload(for: profile)

        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601

        guard let jsonData = try? encoder.encode(exportData) else { return nil }

        let fileName = "MedCare_Export_\(profile.name.replacingOccurrences(of: " ", with: "_"))_\(Date().formatted(.dateTime.year().month().day())).json"
        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent(fileName)

        do {
            try jsonData.write(to: tempURL)
            return tempURL
        } catch {
            return nil
        }
    }

    // MARK: - Build Payload

    private func buildExportPayload(for profile: UserProfile) -> ExportPayload {
        let profileData = ExportProfile(
            id: profile.id.uuidString,
            name: profile.name,
            relation: profile.relation.rawValue,
            dateOfBirth: profile.dateOfBirth,
            gender: profile.gender?.rawValue,
            bloodGroup: profile.bloodGroup,
            knownConditions: profile.knownConditions,
            allergies: profile.allergies,
            emergencyContact: profile.emergencyContact,
            caregiverName: profile.caregiverName,
            caregiverPhoneNumber: profile.caregiverPhoneNumber,
            avatarEmoji: profile.avatarEmoji,
            createdAt: profile.createdAt
        )

        let episodes = profile.episodes.map { episode in
            ExportEpisode(
                id: episode.id.uuidString,
                title: episode.title,
                type: episode.episodeType.rawValue,
                status: episode.status.rawValue,
                doctorName: episode.doctorName,
                hospitalName: episode.hospitalName,
                diagnosis: episode.diagnosis,
                notes: episode.notes,
                followUpDate: episode.followUpDate,
                startDate: episode.startDate,
                endDate: episode.endDate,
                createdAt: episode.createdAt,
                medicines: episode.medicines.map { med in
                    ExportMedicine(
                        id: med.id.uuidString,
                        brandName: med.brandName,
                        genericName: med.genericName,
                        dosage: med.dosage,
                        doseForm: med.doseForm.rawValue,
                        frequency: med.frequency.rawValue,
                        duration: med.duration,
                        mealTiming: med.mealTiming.rawValue,
                        instructions: med.instructions,
                        manufacturer: med.manufacturer,
                        isActive: med.isActive,
                        isCritical: med.isCritical,
                        source: med.source.rawValue,
                        confidenceScore: med.confidenceScore,
                        startDate: med.startDate,
                        endDate: med.endDate,
                        createdAt: med.createdAt,
                        doseLogs: med.doseLogs.map { log in
                            ExportDoseLog(
                                id: log.id.uuidString,
                                scheduledTime: log.scheduledTime,
                                actualTime: log.actualTime,
                                status: log.status.rawValue,
                                skipReason: log.skipReason,
                                notes: log.notes,
                                createdAt: log.createdAt
                            )
                        }
                    )
                },
                symptomLogs: episode.symptomLogs.map { log in
                    ExportSymptomLog(
                        id: log.id.uuidString,
                        date: log.date,
                        overallFeeling: log.overallFeeling.label,
                        symptoms: log.symptoms.map { s in
                            ExportSymptomEntry(name: s.name, severity: s.severity.label)
                        },
                        temperature: log.temperature,
                        bloodPressureSystolic: log.bloodPressureSystolic,
                        bloodPressureDiastolic: log.bloodPressureDiastolic,
                        weight: log.weight,
                        notes: log.notes,
                        createdAt: log.createdAt
                    )
                },
                documents: episode.images.map { img in
                    ExportDocument(
                        id: img.id.uuidString,
                        type: img.imageType.rawValue,
                        title: img.displayTitle,
                        notes: img.notes,
                        fileSize: img.fileSize,
                        createdAt: img.createdAt
                    )
                },
                tasks: episode.tasks.map { task in
                    ExportCareTask(
                        id: task.id.uuidString,
                        title: task.title,
                        type: task.taskType.rawValue,
                        isCompleted: task.isCompleted,
                        dueDate: task.dueDate,
                        notes: task.notes,
                        priority: task.priority.rawValue,
                        createdAt: task.createdAt
                    )
                }
            )
        }

        return ExportPayload(
            exportDate: Date(),
            appVersion: Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0",
            profile: profileData,
            episodes: episodes
        )
    }
}

// MARK: - Export Data Structures

struct ExportPayload: Encodable {
    let exportDate: Date
    let appVersion: String
    let profile: ExportProfile
    let episodes: [ExportEpisode]
}

struct ExportProfile: Encodable {
    let id: String
    let name: String
    let relation: String
    let dateOfBirth: Date?
    let gender: String?
    let bloodGroup: String?
    let knownConditions: [String]
    let allergies: [String]
    let emergencyContact: String?
    let caregiverName: String?
    let caregiverPhoneNumber: String?
    let avatarEmoji: String
    let createdAt: Date
}

struct ExportEpisode: Encodable {
    let id: String
    let title: String
    let type: String
    let status: String
    let doctorName: String?
    let hospitalName: String?
    let diagnosis: String?
    let notes: String?
    let followUpDate: Date?
    let startDate: Date
    let endDate: Date?
    let createdAt: Date
    let medicines: [ExportMedicine]
    let symptomLogs: [ExportSymptomLog]
    let documents: [ExportDocument]
    let tasks: [ExportCareTask]
}

struct ExportMedicine: Encodable {
    let id: String
    let brandName: String
    let genericName: String?
    let dosage: String
    let doseForm: String
    let frequency: String
    let duration: Int?
    let mealTiming: String
    let instructions: String?
    let manufacturer: String?
    let isActive: Bool
    let isCritical: Bool
    let source: String
    let confidenceScore: Double
    let startDate: Date
    let endDate: Date?
    let createdAt: Date
    let doseLogs: [ExportDoseLog]
}

struct ExportDoseLog: Encodable {
    let id: String
    let scheduledTime: Date
    let actualTime: Date?
    let status: String
    let skipReason: String?
    let notes: String?
    let createdAt: Date
}

struct ExportSymptomLog: Encodable {
    let id: String
    let date: Date
    let overallFeeling: String
    let symptoms: [ExportSymptomEntry]
    let temperature: Double?
    let bloodPressureSystolic: Int?
    let bloodPressureDiastolic: Int?
    let weight: Double?
    let notes: String?
    let createdAt: Date
}

struct ExportSymptomEntry: Encodable {
    let name: String
    let severity: String
}

struct ExportDocument: Encodable {
    let id: String
    let type: String
    let title: String
    let notes: String?
    let fileSize: Int64?
    let createdAt: Date
}

struct ExportCareTask: Encodable {
    let id: String
    let title: String
    let type: String
    let isCompleted: Bool
    let dueDate: Date?
    let notes: String?
    let priority: String
    let createdAt: Date
}
