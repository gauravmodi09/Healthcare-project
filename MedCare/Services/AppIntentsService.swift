import AppIntents
import SwiftData

// MARK: - Log Dose Intent

struct LogDoseIntent: AppIntent {
    static var title: LocalizedStringResource = "Log Dose as Taken"
    static var description: IntentDescription = IntentDescription("Mark your current dose as taken")
    static var openAppWhenRun: Bool = false

    func perform() async throws -> some IntentResult & ReturnsValue<String> {
        // Access the shared model container
        let container = try ModelContainer(for: User.self, UserProfile.self, DoseLog.self)
        let context = ModelContext(container)

        let descriptor = FetchDescriptor<User>()
        let users = try context.fetch(descriptor)

        guard let user = users.first,
              let profile = user.profiles.first(where: { $0.isActive }) else {
            return .result(value: "No active profile found. Please open MedCare first.")
        }

        // Find the next pending dose
        let now = Date()
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: now)

        let allDoseLogs = profile.episodes
            .flatMap { $0.activeMedicines }
            .flatMap { $0.doseLogs }
            .filter { calendar.isDate($0.scheduledTime, inSameDayAs: today) && $0.status == .pending }
            .sorted { $0.scheduledTime < $1.scheduledTime }

        guard let nextDose = allDoseLogs.first else {
            return .result(value: "No pending doses right now. You're all caught up!")
        }

        nextDose.status = .taken
        nextDose.actualTime = now
        try context.save()

        let medicineName = nextDose.medicine?.brandName ?? "your medicine"
        return .result(value: "Marked \(medicineName) as taken. Keep it up!")
    }
}

// MARK: - Check Adherence Intent

struct CheckAdherenceIntent: AppIntent {
    static var title: LocalizedStringResource = "Check Adherence"
    static var description: IntentDescription = IntentDescription("Check your medication adherence")
    static var openAppWhenRun: Bool = false

    func perform() async throws -> some IntentResult & ReturnsValue<String> {
        let container = try ModelContainer(for: User.self, UserProfile.self, DoseLog.self)
        let context = ModelContext(container)

        let descriptor = FetchDescriptor<User>()
        let users = try context.fetch(descriptor)

        guard let user = users.first,
              let profile = user.profiles.first(where: { $0.isActive }) else {
            return .result(value: "No active profile found. Please open MedCare first.")
        }

        // Calculate 7-day adherence
        let calendar = Calendar.current
        let sevenDaysAgo = calendar.date(byAdding: .day, value: -7, to: Date()) ?? Date()

        let allDoseLogs = profile.episodes
            .flatMap { $0.activeMedicines }
            .flatMap { $0.doseLogs }
            .filter { $0.scheduledTime >= sevenDaysAgo }

        let total = allDoseLogs.count
        guard total > 0 else {
            return .result(value: "No dose data in the last 7 days.")
        }

        let taken = allDoseLogs.filter { $0.status == .taken }.count
        let rate = Int(Double(taken) / Double(total) * 100)

        let message: String
        switch rate {
        case 90...100:
            message = "Your 7-day adherence is \(rate)% \u{2014} outstanding! Keep it up."
        case 70..<90:
            message = "Your 7-day adherence is \(rate)%. Good progress, try to stay consistent."
        case 50..<70:
            message = "Your 7-day adherence is \(rate)%. Room for improvement \u{2014} try linking doses to daily habits."
        default:
            message = "Your 7-day adherence is \(rate)%. Let's work on building a better routine."
        }

        return .result(value: message)
    }
}

// MARK: - App Shortcuts Provider

struct MedCareShortcuts: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: LogDoseIntent(),
            phrases: [
                "Log my dose in \(.applicationName)",
                "Mark medicine taken in \(.applicationName)",
            ],
            shortTitle: "Log Dose",
            systemImageName: "pills.fill"
        )
        AppShortcut(
            intent: CheckAdherenceIntent(),
            phrases: [
                "How is my adherence in \(.applicationName)",
                "Check my medicine compliance in \(.applicationName)",
            ],
            shortTitle: "Check Adherence",
            systemImageName: "chart.bar.fill"
        )
    }
}
