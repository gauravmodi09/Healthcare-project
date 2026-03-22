import SwiftUI
import SwiftData

struct MainTabView: View {
    @Environment(AppRouter.self) private var router
    @Environment(DataService.self) private var dataService
    @Environment(SmartNudgeService.self) private var nudgeService
    @AppStorage("mc_has_seeded_demo") private var hasSeededData = false
    @AppStorage("mc_user_role") private var storedRole = ""
    @Query private var users: [User]
    @State private var showProfileSetup = false

    private var networkMonitor = NetworkMonitor.shared
    private var currentUser: User? { users.first }
    private var needsProfileSetup: Bool {
        guard let user = currentUser else { return false }
        return user.profiles.isEmpty
    }

    private var currentRole: UserRole {
        UserRole(rawValue: storedRole) ?? .patient
    }

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

            switch currentRole {
            case .patient:
                patientTabs(router: router)
            case .individualDoctor, .hospitalDoctor:
                doctorTabs(router: router)
            case .hospitalAdmin:
                adminTabs(router: router)
            }
        } // end VStack
        .animation(.easeInOut(duration: 0.3), value: networkMonitor.isConnected)
        .sheet(isPresented: $showProfileSetup) {
            NavigationStack {
                ProfileSetupView(phoneNumber: currentUser?.phoneNumber ?? "")
            }
        }
        .onAppear {
            // Seed demo data on first launch for all personas
            if !hasSeededData {
                let _ = dataService.seedDemoData()
                seedSampleDoctors()
                hasSeededData = true
            }

            // Auto-show profile setup for new patient users with no profiles
            if currentRole == .patient && needsProfileSetup {
                showProfileSetup = true
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

    // MARK: - Patient Tabs (Default)

    @ViewBuilder
    private func patientTabs(router: AppRouter) -> some View {
        @Bindable var router = router
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
    }

    // MARK: - Doctor Tabs

    @ViewBuilder
    private func doctorTabs(router: AppRouter) -> some View {
        @Bindable var router = router
        TabView(selection: $router.selectedTab) {
            DoctorDashboardView()
                .tabItem {
                    Label("Dashboard", systemImage: "stethoscope")
                }
                .tag(AppTab.home)

            DoctorPatientsListView()
                .tabItem {
                    Label("My Patients", systemImage: "person.2.fill")
                }
                .tag(AppTab.meds)

            DoctorAppointmentsView()
                .tabItem {
                    Label("Appointments", systemImage: "calendar")
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
        .tint(Color(hex: "3B82F6"))
    }

    // MARK: - Hospital Admin Tabs

    @ViewBuilder
    private func adminTabs(router: AppRouter) -> some View {
        @Bindable var router = router
        TabView(selection: $router.selectedTab) {
            AdminDashboardView()
                .tabItem {
                    Label("Dashboard", systemImage: "chart.bar.fill")
                }
                .tag(AppTab.home)

            AdminDoctorsView()
                .tabItem {
                    Label("Doctors", systemImage: "stethoscope")
                }
                .tag(AppTab.meds)

            AdminPatientsView()
                .tabItem {
                    Label("Patients", systemImage: "person.2.fill")
                }
                .tag(AppTab.health)

            AdminAnalyticsView()
                .tabItem {
                    Label("Analytics", systemImage: "chart.line.uptrend.xyaxis")
                }
                .tag(AppTab.ai)

            ProfileManagementView()
                .tabItem {
                    Label("Settings", systemImage: "gearshape.fill")
                }
                .tag(AppTab.profile)
        }
        .tint(Color(hex: "D97706"))
    }

    // MARK: - Seed Sample Doctors

    private func seedSampleDoctors() {
        let context = dataService.modelContext

        let doctors: [(name: String, specialty: String, phone: String, email: String, reg: String, fee: Double, emoji: String)] = [
            ("Dr. Priya Mehta", "General Medicine", "9876543210", "priya.mehta@hospital.com", "MCI-12345", 500, "👩‍⚕️"),
            ("Dr. Anil Kumar", "Endocrinology", "9876543211", "anil.kumar@maxhealth.com", "MCI-23456", 800, "👨‍⚕️"),
            ("Dr. Rajesh Sharma", "Cardiology", "9876543212", "rajesh.sharma@medanta.com", "MCI-34567", 1200, "👨‍⚕️"),
            ("Dr. Neha Gupta", "Dermatology", "9876543213", "neha.gupta@fortis.com", "MCI-45678", 600, "👩‍⚕️"),
            ("Dr. Vikram Singh", "Orthopedics", "9876543214", "vikram.singh@aiims.com", "MCI-56789", 1000, "👨‍⚕️"),
            ("Dr. Sunita Reddy", "Pediatrics", "9876543215", "sunita.reddy@rainbow.com", "MCI-67890", 700, "👩‍⚕️"),
            ("Dr. Arjun Patel", "Psychiatry", "9876543216", "arjun.patel@nimhans.com", "MCI-78901", 900, "👨‍⚕️"),
            ("Dr. Kavita Desai", "Gynecology", "9876543217", "kavita.desai@apollo.com", "MCI-89012", 800, "👩‍⚕️"),
        ]

        for doc in doctors {
            let doctor = Doctor(
                name: doc.name,
                specialty: doc.specialty,
                phone: doc.phone,
                email: doc.email,
                registrationNumber: doc.reg,
                consultationFee: doc.fee
            )
            doctor.avatarEmoji = doc.emoji
            context.insert(doctor)
        }
        try? context.save()
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
