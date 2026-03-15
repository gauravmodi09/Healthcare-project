import SwiftUI

struct MainTabView: View {
    @Environment(AppRouter.self) private var router
    @Environment(DataService.self) private var dataService
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
}
