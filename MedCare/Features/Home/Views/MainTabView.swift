import SwiftUI
import SwiftData

struct MainTabView: View {
    @Environment(AppRouter.self) private var router
    @Environment(DataService.self) private var dataService
    @Environment(SmartNudgeService.self) private var nudgeService
    @AppStorage("mc_has_seeded_demo") private var hasSeededData = false

    private var networkMonitor = NetworkMonitor.shared

    var body: some View {
        @Bindable var router = router

        VStack(spacing: 0) {
            // Offline banner
            if !networkMonitor.isConnected {
                HStack(spacing: 8) {
                    Image(systemName: "wifi.slash")
                        .font(.system(size: 13, weight: .semibold))
                    Text("You're offline — core features still work")
                        .font(.system(size: 13, weight: .medium))
                }
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
                .background(Color(hex: "D97706")) // warm amber
                .transition(.move(edge: .top).combined(with: .opacity))
            }

        TabView(selection: $router.selectedTab) {
            HomeView()
                .tabItem {
                    Label("Home", systemImage: "house.fill")
                }
                .tag(AppTab.home)

            RemindersView()
                .tabItem {
                    Label("Medications", systemImage: "pills.fill")
                }
                .tag(AppTab.meds)

            HistoryView()
                .tabItem {
                    Label("Health", systemImage: "heart.text.square.fill")
                }
                .tag(AppTab.health)

            aiChatTab
                .tabItem {
                    Label("AI", systemImage: "sparkles")
                }
                .tag(AppTab.ai)

            ProfileManagementView()
                .tabItem {
                    Label("Profile", systemImage: "person.fill")
                }
                .tag(AppTab.profile)
        }
        .tint(MCColors.primaryTeal)
        } // end VStack
        .animation(.easeInOut(duration: 0.3), value: networkMonitor.isConnected)
        .onAppear {
            if !hasSeededData {
                let _ = dataService.seedDemoData()
                hasSeededData = true
            }

            // Evaluate smart nudges for the active profile
            let descriptor = FetchDescriptor<UserProfile>(
                predicate: #Predicate<UserProfile> { $0.isActive }
            )
            if let activeProfile = try? dataService.modelContext.fetch(descriptor).first {
                nudgeService.evaluateNudges(profile: activeProfile, modelContext: dataService.modelContext)

                // Auto-extend dose logs for chronic medicines
                dataService.extendDoseLogsIfNeeded(for: activeProfile)

                // Check refill stock levels and schedule reminders
                let activeMedicines = activeProfile.episodes
                    .flatMap { $0.medicines }
                    .filter { $0.isActive }
                let stockInfos: [MedicineStockInfo] = activeMedicines.compactMap { med in
                    guard let totalPills = med.totalPillCount, totalPills > 0 else { return nil }
                    let dosesTaken = med.doseLogs.filter { $0.status == .taken }.count
                    return MedicineStockInfo(
                        id: med.id,
                        brandName: med.brandName,
                        totalPillCount: totalPills,
                        dosesPerDay: med.frequency.timesPerDay,
                        dosesTaken: dosesTaken,
                        startDate: med.startDate
                    )
                }
                if !stockInfos.isEmpty {
                    Task {
                        await RefillReminderService.shared.checkAllAndScheduleReminders(medicines: stockInfos)
                    }
                }
            }
        }
    }

    /// AI Chat tab — finds the active profile and passes it to AIChatView
    @ViewBuilder
    private var aiChatTab: some View {
        let descriptor = FetchDescriptor<UserProfile>(
            predicate: #Predicate<UserProfile> { $0.isActive }
        )
        if let profile = try? dataService.modelContext.fetch(descriptor).first {
            AIChatView(profile: profile)
        } else {
            VStack(spacing: 12) {
                Image(systemName: "person.crop.circle.badge.questionmark")
                    .font(.system(size: 48))
                    .foregroundColor(.secondary)
                Text("No active profile found")
                    .font(.headline)
                Text("Set up a profile to start chatting with MedCare AI")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
        }
    }
}
