import SwiftUI

struct RootView: View {
    @Environment(AuthService.self) private var authService
    @State private var showSplash = true
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    @AppStorage("mc_has_shown_notification_primer") private var hasShownNotificationPrimer = false
    @AppStorage("mc_last_seen_version") private var lastSeenVersion = ""
    @State private var showNotificationPrimer = false
    @State private var showWhatsNew = false

    private var currentVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
    }

    var body: some View {
        ZStack {
            if showSplash {
                SplashScreen()
                    .transition(.opacity)
            } else if !hasCompletedOnboarding {
                OnboardingView {
                    withAnimation {
                        hasCompletedOnboarding = true
                    }
                }
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
        .animation(.easeInOut(duration: 0.3), value: hasCompletedOnboarding)
        .animation(.easeInOut(duration: 0.3), value: authService.isAuthenticated)
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                withAnimation {
                    showSplash = false
                }
            }
        }
        .onChange(of: authService.isAuthenticated) { _, isAuth in
            if isAuth && !hasShownNotificationPrimer {
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                    showNotificationPrimer = true
                }
            }
            // What's New: show after app update (not on first install)
            if isAuth && !lastSeenVersion.isEmpty && lastSeenVersion != currentVersion {
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                    showWhatsNew = true
                }
            }
            // Set version on first launch so we don't show What's New on initial install
            if isAuth && lastSeenVersion.isEmpty {
                lastSeenVersion = currentVersion
            }
        }
        .sheet(isPresented: $showNotificationPrimer) {
            NotificationPermissionView()
                .presentationDetents([.large])
                .presentationDragIndicator(.hidden)
        }
        .sheet(isPresented: $showWhatsNew, onDismiss: {
            lastSeenVersion = currentVersion
        }) {
            WhatsNewView()
                .presentationDetents([.large])
                .presentationDragIndicator(.visible)
        }
    }
}
