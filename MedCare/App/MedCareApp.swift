import SwiftUI
import SwiftData

@main
struct MedCareApp: App {
    @State private var router = AppRouter()
    @State private var authService = AuthService()
    @State private var dataService = DataService()
    @State private var aiService = AIExtractionService()
    @State private var chatService = AIChatService()
    @State private var nudgeService = SmartNudgeService()
    @State private var liveActivityService = LiveActivityService()
    @State private var elderModeService = ElderModeService()
    @Environment(\.scenePhase) private var scenePhase

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(router)
                .environment(authService)
                .environment(dataService)
                .environment(aiService)
                .environment(chatService)
                .environment(nudgeService)
                .environment(liveActivityService)
                .environment(\.elderModeService, elderModeService)
                .modelContainer(dataService.modelContainer)
                .onOpenURL { url in
                    handleDeepLink(url)
                }
        }
        .onChange(of: scenePhase) { _, newPhase in
            if newPhase == .active {
                evaluateUpcomingDoses()
            }
        }
    }

    // MARK: - Deep Link Handling (from Dynamic Island buttons)

    private func handleDeepLink(_ url: URL) {
        guard url.scheme == "medcare",
              url.host == "dose",
              url.pathComponents.count >= 3
        else { return }

        let action = url.pathComponents[1]   // "take", "snooze", or "skip"
        let idString = url.pathComponents[2] // doseLogId UUID string
        guard let doseLogId = UUID(uuidString: idString) else { return }

        // Find the dose log in the data service
        let context = dataService.modelContainer.mainContext
        let descriptor = FetchDescriptor<DoseLog>()
        guard let doseLogs = try? context.fetch(descriptor),
              let dose = doseLogs.first(where: { $0.id == doseLogId })
        else { return }

        switch action {
        case "take":
            dataService.logDose(dose, status: .taken)
            Task {
                await liveActivityService.endActivity(doseLogId: doseLogId)
            }
        case "snooze":
            dataService.logDose(dose, status: .snoozed)
            if let med = dose.medicine {
                Task {
                    await NotificationService.shared.scheduleSnooze(
                        medicineId: med.id,
                        medicineName: med.brandName,
                        dosage: med.dosage,
                        doseLogId: dose.id
                    )
                    let snoozedUntil = Date().addingTimeInterval(15 * 60)
                    await liveActivityService.updateActivity(
                        doseLogId: doseLogId,
                        status: .snoozed,
                        minutesRemaining: 15,
                        snoozedUntil: snoozedUntil
                    )
                }
            }
        case "skip":
            dataService.logDose(dose, status: .skipped)
            Task {
                await liveActivityService.endActivity(doseLogId: doseLogId)
            }
        default:
            break
        }
    }

    // MARK: - Evaluate Upcoming Doses for Live Activities

    private func evaluateUpcomingDoses() {
        let context = dataService.modelContainer.mainContext
        let descriptor = FetchDescriptor<DoseLog>()
        guard let allDoses = try? context.fetch(descriptor) else { return }

        let now = Date()
        let endOfWindow = now.addingTimeInterval(15 * 60)

        // Filter to pending doses within the 15-minute window
        let upcomingDoses = allDoses.filter { dose in
            dose.status == .pending &&
            dose.scheduledTime <= endOfWindow &&
            dose.scheduledTime > now.addingTimeInterval(-30 * 60)
        }

        liveActivityService.evaluateUpcomingDoses(from: upcomingDoses)
    }
}
