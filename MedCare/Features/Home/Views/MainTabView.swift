import SwiftUI
import SwiftData

struct MainTabView: View {
    @Environment(AppRouter.self) private var router
    @Environment(DataService.self) private var dataService
    @Environment(SmartNudgeService.self) private var nudgeService
    @State private var hasSeededData = false

    var body: some View {
        @Bindable var router = router

        TabView(selection: $router.selectedTab) {
            HomeView()
                .tabItem {
                    Label("Home", systemImage: "house.fill")
                }
                .tag(AppTab.home)

            RemindersView()
                .tabItem {
                    Label("Reminders", systemImage: "bell.fill")
                }
                .tag(AppTab.reminders)

            aiChatTab
                .tabItem {
                    Label("AI Chat", systemImage: "sparkles")
                }
                .tag(AppTab.ai)

            HistoryView()
                .tabItem {
                    Label("History", systemImage: "clock.fill")
                }
                .tag(AppTab.history)

            ProfileManagementView()
                .tabItem {
                    Label("Profile", systemImage: "person.fill")
                }
                .tag(AppTab.profile)
        }
        .tint(MCColors.primaryTeal)
        .onAppear {
            if !hasSeededData {
                let _ = dataService.seedDemoData()
                hasSeededData = true
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
