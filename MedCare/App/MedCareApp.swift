import SwiftUI
import SwiftData

@main
struct MedCareApp: App {
    @State private var router = AppRouter()
    @State private var authService = AuthService()
    @State private var dataService = DataService()
    @State private var aiService = AIExtractionService()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(router)
                .environment(authService)
                .environment(dataService)
                .environment(aiService)
                .modelContainer(dataService.modelContainer)
        }
    }
}
