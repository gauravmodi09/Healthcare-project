import SwiftUI

struct RootView: View {
    @Environment(AuthService.self) private var authService
    @State private var showSplash = true

    var body: some View {
        ZStack {
            if showSplash {
                SplashScreen()
                    .transition(.opacity)
            } else if authService.isAuthenticated {
                MainTabView()
                    .transition(.opacity)
            } else {
                PhoneLoginView()
                    .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.5), value: showSplash)
        .animation(.easeInOut(duration: 0.3), value: authService.isAuthenticated)
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                withAnimation {
                    showSplash = false
                }
            }
        }
    }
}
