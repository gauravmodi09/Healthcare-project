import SwiftUI

/// Centralized navigation router for the app
@Observable
final class AppRouter {
    var authPath = NavigationPath()
    var homePath = NavigationPath()
    var selectedTab: AppTab = .home
    var showingUploadFlow = false
    var showingProfileSetup = false

    enum AuthRoute: Hashable {
        case phoneLogin
        case otpVerification(phoneNumber: String)
        case profileSetup
    }

    enum HomeRoute: Hashable {
        case episodeDetail(episodeId: UUID)
        case uploadPrescription
        case confirmExtraction(episodeId: UUID)
        case medicineDetail(medicineId: UUID)
        case addMedicine(episodeId: UUID)
        case symptomLog(episodeId: UUID)
        case adherenceReport(episodeId: UUID)
        case profileManagement
        case profileDetail(profileId: UUID)
        case documentDetail(documentId: UUID)
        case profileFiles(profileId: UUID)
        case aiChat(profileId: UUID)
        case settings
    }

    func navigateToAuth(_ route: AuthRoute) {
        authPath.append(route)
    }

    func navigateToHome(_ route: HomeRoute) {
        homePath.append(route)
    }

    func popAuth() {
        if !authPath.isEmpty {
            authPath.removeLast()
        }
    }

    func popHome() {
        if !homePath.isEmpty {
            homePath.removeLast()
        }
    }

    func resetToHome() {
        homePath = NavigationPath()
        selectedTab = .home
    }
}

enum AppTab: String, CaseIterable {
    case home = "Home"
    case meds = "Medications"
    case health = "Health"
    case ai = "AI"
    case profile = "Profile"

    var icon: String {
        switch self {
        case .home: return "house.fill"
        case .meds: return "pills.fill"
        case .health: return "heart.text.square.fill"
        case .ai: return "sparkles"
        case .profile: return "person.fill"
        }
    }
}
