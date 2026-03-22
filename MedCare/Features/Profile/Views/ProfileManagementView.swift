import SwiftUI
import SwiftData

struct ProfileManagementView: View {
    @Environment(DataService.self) private var dataService
    @Environment(AuthService.self) private var authService
    @Environment(ConsentService.self) private var consentService
    @Query private var users: [User]
    @State private var showAddProfile = false
    @State private var showSubscription = false
    @State private var showEditProfile = false
    @State private var showDeleteConfirmation = false
    @State private var showSignOutConfirmation = false
    @State private var showNotifications = false
    @State private var showDoctorVisitPrep = false
    @State private var showElderMode = false
    @State private var showAbout = false
    @State private var showAchievements = false
    @State private var showExportShare = false
    @State private var exportFileURL: URL?
    @State private var showConsentManagement = false
    @State private var showDataDeletion = false
    @State private var showABHALinking = false
    @State private var showPayment = false
    @State private var showDoctorDashboard = false
    @AppStorage("mc_doctor_mode_enabled") private var doctorModeEnabled = false
    private let exportService = ExportService()

    private var currentUser: User? { users.first }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: MCSpacing.sectionSpacing) {
                    if let profile = currentUser?.activeProfile {
                        userHeaderCard(profile)
                    }
                    familyProfilesSection
                    if let profile = currentUser?.activeProfile {
                        if profile.episodes.isEmpty {
                            MCEmptyState.episodes()
                        } else {
                            quickStatsRow(profile)
                        }
                    }
                    settingsSection
                    privacyDataSection
                    dangerZoneSection
                    versionFooter
                }
                .padding(.vertical, MCSpacing.md)
            }
            .background(MCColors.backgroundLight)
            .dynamicTypeSize(.xSmall ... .accessibility3)
            .navigationTitle("Profile")
            .navigationDestination(for: String.self) { destination in
                if destination == "profileFiles" {
                    ProfileFilesView()
                }
            }
            .sheet(isPresented: $showEditProfile) {
                if let profile = currentUser?.activeProfile {
                    EditProfileView(profile: profile)
                }
            }
            .sheet(isPresented: $showAddProfile) {
                AddFamilyProfileView()
            }
            .sheet(isPresented: $showSubscription) {
                MCSubscriptionView()
            }
            .alert("Delete Account", isPresented: $showDeleteConfirmation) {
                Button("Cancel", role: .cancel) {}
                Button("Delete", role: .destructive) {
                    deleteAccount()
                }
            } message: {
                Text("This will permanently delete your account and all associated data. This action cannot be undone.")
            }
            .alert("Sign Out", isPresented: $showSignOutConfirmation) {
                Button("Cancel", role: .cancel) {}
                Button("Sign Out", role: .destructive) {
                    authService.logout()
                }
            } message: {
                Text("Are you sure you want to sign out?")
            }
            .sheet(isPresented: $showNotifications) {
                NotificationSettingsView()
            }
            .sheet(isPresented: $showDoctorVisitPrep) {
                DoctorVisitPrepWrapper()
            }
            .sheet(isPresented: $showElderMode) {
                NavigationStack {
                    ElderModeSettingsView()
                }
            }
            .sheet(isPresented: $showAbout) {
                AboutMedCareView()
            }
            .sheet(isPresented: $showAchievements) {
                AchievementsView()
            }
            .sheet(isPresented: $showABHALinking) {
                ABHALinkingView()
            }
            .sheet(isPresented: $showPayment) {
                PaymentView()
            }
            .sheet(isPresented: $showExportShare) {
                if let url = exportFileURL {
                    ShareSheetView(items: [url])
                }
            }
            .sheet(isPresented: $showConsentManagement) {
                NavigationStack {
                    ConsentManagementView()
                        .toolbar {
                            ToolbarItem(placement: .cancellationAction) {
                                Button("Done") { showConsentManagement = false }
                            }
                        }
                }
            }
            .sheet(isPresented: $showDataDeletion) {
                if let profile = currentUser?.activeProfile {
                    NavigationStack {
                        DataDeletionView(profile: profile, exportService: exportService)
                            .toolbar {
                                ToolbarItem(placement: .cancellationAction) {
                                    Button("Cancel") { showDataDeletion = false }
                                }
                            }
                    }
                }
            }
            .fullScreenCover(isPresented: $showDoctorDashboard) {
                DoctorDashboardView()
            }
        }
    }

    // MARK: - User Header Card

    private func userHeaderCard(_ profile: UserProfile) -> some View {
        MCCard {
            VStack(spacing: MCSpacing.md) {
                ZStack {
                    Circle()
                        .fill(MCColors.primaryGradient)
                        .frame(width: MCSpacing.avatarSizeLarge + 8, height: MCSpacing.avatarSizeLarge + 8)
                    Circle()
                        .fill(MCColors.cardBackground)
                        .frame(width: MCSpacing.avatarSizeLarge, height: MCSpacing.avatarSizeLarge)
                    Text(profile.avatarEmoji)
                        .font(.system(size: 40))
                }
                VStack(spacing: MCSpacing.xxs) {
                    Text(profile.name)
                        .font(MCTypography.title)
                        .foregroundStyle(MCColors.textPrimary)
                    HStack(spacing: MCSpacing.xs) {
                        if let age = profile.age {
                            Text("\(age) yrs")
                                .font(MCTypography.subheadline)
                                .foregroundStyle(MCColors.textSecondary)
                        }
                        if let gender = profile.gender {
                            if profile.age != nil {
                                Text("\u{00B7}")
                                    .foregroundStyle(MCColors.textTertiary)
                            }
                            Text(gender.rawValue)
                                .font(MCTypography.subheadline)
                                .foregroundStyle(MCColors.textSecondary)
                        }
                    }
                }
                subscriptionBadge
                Button {
                    showEditProfile = true
                } label: {
                    HStack(spacing: MCSpacing.xs) {
                        Image(systemName: "pencil")
                            .font(.system(size: 13, weight: .medium))
                        Text("Edit Profile")
                            .font(MCTypography.subheadline)
                    }
                    .foregroundStyle(MCColors.primaryTeal)
                    .padding(.horizontal, MCSpacing.md)
                    .padding(.vertical, MCSpacing.xs)
                    .background(MCColors.primaryTeal.opacity(0.1))
                    .clipShape(Capsule())
                }
            }
            .frame(maxWidth: .infinity)
        }
        .padding(.horizontal, MCSpacing.screenPadding)
    }

    private var subscriptionBadge: some View {
        let tier = currentUser?.subscriptionTier ?? .free
        let badgeColor: Color = {
            switch tier {
            case .free: return MCColors.textSecondary
            case .pro: return MCColors.primaryTeal
            case .premium: return MCColors.warning
            }
        }()
        let badgeIcon: String = {
            switch tier {
            case .free: return "star"
            case .pro: return "star.fill"
            case .premium: return "crown.fill"
            }
        }()
        return HStack(spacing: MCSpacing.xxs) {
            Image(systemName: badgeIcon)
                .font(.system(size: 11, weight: .semibold))
            Text(tier.displayName)
                .font(MCTypography.captionBold)
        }
        .foregroundStyle(badgeColor)
        .padding(.horizontal, MCSpacing.sm)
        .padding(.vertical, MCSpacing.xxs + 1)
        .background(badgeColor.opacity(0.12))
        .clipShape(Capsule())
    }

    // MARK: - Family Profiles

    private var familyProfilesSection: some View {
        VStack(alignment: .leading, spacing: MCSpacing.sm) {
            Text("Family Profiles")
                .font(MCTypography.headline)
                .foregroundStyle(MCColors.textPrimary)
                .padding(.horizontal, MCSpacing.screenPadding)
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: MCSpacing.sm) {
                    if let profiles = currentUser?.profiles {
                        ForEach(profiles) { profile in
                            Button {
                                if let user = currentUser {
                                    dataService.switchActiveProfile(to: profile, for: user)
                                }
                            } label: {
                                familyProfileCard(profile)
                            }
                        }
                    }
                    addFamilyMemberCard
                }
                .padding(.horizontal, MCSpacing.screenPadding)
            }
        }
    }

    private func familyProfileCard(_ profile: UserProfile) -> some View {
        VStack(spacing: MCSpacing.xs) {
            ZStack(alignment: .bottomTrailing) {
                Text(profile.avatarEmoji)
                    .font(.system(size: 28))
                    .frame(width: 52, height: 52)
                    .background(
                        profile.isActive
                            ? MCColors.primaryTeal.opacity(0.15)
                            : MCColors.backgroundLight
                    )
                    .clipShape(Circle())
                if profile.isActive {
                    Circle()
                        .fill(MCColors.success)
                        .frame(width: 12, height: 12)
                        .overlay(
                            Circle().stroke(MCColors.cardBackground, lineWidth: 2)
                        )
                        .offset(x: 2, y: 2)
                }
            }
            Text(profile.name)
                .font(MCTypography.captionBold)
                .foregroundStyle(
                    profile.isActive ? MCColors.primaryTeal : MCColors.textPrimary
                )
                .lineLimit(1)
            Text(profile.relation.rawValue)
                .font(.system(size: 10))
                .foregroundStyle(MCColors.textTertiary)
        }
        .frame(width: 80)
        .padding(.vertical, MCSpacing.sm)
        .background(MCColors.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: MCSpacing.cornerRadius))
        .overlay(
            RoundedRectangle(cornerRadius: MCSpacing.cornerRadius)
                .stroke(
                    profile.isActive ? MCColors.primaryTeal : MCColors.divider,
                    lineWidth: profile.isActive ? 2 : 1
                )
        )
    }

    private var addFamilyMemberCard: some View {
        Button {
            showAddProfile = true
        } label: {
            VStack(spacing: MCSpacing.xs) {
                Image(systemName: "plus")
                    .font(.system(size: 22, weight: .medium))
                    .foregroundStyle(MCColors.primaryTeal.opacity(0.6))
                    .frame(width: 52, height: 52)
                    .background(MCColors.primaryTeal.opacity(0.05))
                    .clipShape(Circle())
                Text("Add")
                    .font(MCTypography.captionBold)
                    .foregroundStyle(MCColors.primaryTeal)
                Text("Member")
                    .font(.system(size: 10))
                    .foregroundStyle(MCColors.textTertiary)
            }
            .frame(width: 80)
            .padding(.vertical, MCSpacing.sm)
            .background(MCColors.cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: MCSpacing.cornerRadius))
            .overlay(
                RoundedRectangle(cornerRadius: MCSpacing.cornerRadius)
                    .strokeBorder(
                        style: StrokeStyle(lineWidth: 1.5, dash: [6, 4])
                    )
                    .foregroundStyle(MCColors.primaryTeal.opacity(0.3))
            )
        }
    }

    // MARK: - Quick Stats Row

    private func quickStatsRow(_ profile: UserProfile) -> some View {
        HStack(spacing: MCSpacing.sm) {
            quickStatCard(icon: "pills.fill", value: "\(profile.episodes.flatMap { $0.medicines }.count)", label: "Medicines", color: MCColors.primaryTeal)
            quickStatCard(icon: "heart.text.clipboard.fill", value: "\(profile.episodes.count)", label: "Episodes", color: MCColors.accentCoral)
            quickStatCard(icon: "doc.text.fill", value: "\(profile.episodes.flatMap { $0.images }.count)", label: "Documents", color: MCColors.info)
        }
        .padding(.horizontal, MCSpacing.screenPadding)
    }

    private func quickStatCard(icon: String, value: String, label: String, color: Color) -> some View {
        VStack(spacing: MCSpacing.xs) {
            Image(systemName: icon)
                .font(.system(size: 18))
                .foregroundStyle(color)
                .frame(width: 36, height: 36)
                .background(color.opacity(0.1))
                .clipShape(Circle())
            Text(value)
                .font(MCTypography.headline)
                .foregroundStyle(MCColors.textPrimary)
            Text(label)
                .font(MCTypography.caption)
                .foregroundStyle(MCColors.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, MCSpacing.sm)
        .background(MCColors.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: MCSpacing.cornerRadius))
        .shadow(color: .black.opacity(0.06), radius: 8, y: 2)
    }

    // MARK: - Settings List

    private var settingsSection: some View {
        VStack(spacing: 0) {
            settingsRow(icon: "bell.fill", title: "Notifications", color: MCColors.primaryTeal) { showNotifications = true }
            Divider().padding(.leading, 60)
            settingsRow(icon: "crown.fill", title: "Subscription", color: MCColors.warning) { showSubscription = true }
            Divider().padding(.leading, 60)
            settingsRow(icon: "indianrupeesign.circle.fill", title: "Payment & UPI", color: MCColors.success) { showPayment = true }
            Divider().padding(.leading, 60)
            settingsRow(icon: "checkmark.shield.fill", title: "ABHA Linking", color: MCColors.primaryTeal) { showABHALinking = true }
            Divider().padding(.leading, 60)
            settingsRow(icon: "trophy.fill", title: "Achievements", color: MCColors.warning) { showAchievements = true }
            Divider().padding(.leading, 60)
            settingsRow(icon: "stethoscope", title: "Doctor Visit Prep", color: MCColors.accentCoral) { showDoctorVisitPrep = true }
            Divider().padding(.leading, 60)
            settingsRow(icon: "figure.walk", title: "Elder Mode", color: MCColors.success) { showElderMode = true }
            Divider().padding(.leading, 60)
            doctorModeRow
            Divider().padding(.leading, 60)
            settingsRow(icon: "questionmark.circle.fill", title: "Help & Support", color: MCColors.info) {
                if let url = URL(string: "mailto:support@medcare.app") { UIApplication.shared.open(url) }
            }
            Divider().padding(.leading, 60)
            settingsRow(icon: "info.circle.fill", title: "About MedCare", color: MCColors.textSecondary) { showAbout = true }
        }
        .background(MCColors.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: MCSpacing.cornerRadius))
        .shadow(color: .black.opacity(0.06), radius: 8, y: 2)
        .padding(.horizontal, MCSpacing.screenPadding)
    }

    private func settingsRow(icon: String, title: String, color: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: MCSpacing.sm) {
                Image(systemName: icon)
                    .foregroundStyle(color)
                    .font(.system(size: 15))
                    .frame(width: 32, height: 32)
                    .background(color.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: MCSpacing.cornerRadiusSmall))
                Text(title)
                    .font(MCTypography.body)
                    .foregroundStyle(MCColors.textPrimary)
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(MCColors.textTertiary)
            }
            .padding(.horizontal, MCSpacing.cardPadding)
            .padding(.vertical, MCSpacing.sm)
        }
    }

    // MARK: - Privacy & Data

    private var privacyDataSection: some View {
        VStack(alignment: .leading, spacing: MCSpacing.sm) {
            Text("Privacy & Data")
                .font(MCTypography.headline)
                .foregroundStyle(MCColors.textPrimary)
                .padding(.horizontal, MCSpacing.screenPadding)
            VStack(spacing: 0) {
                settingsRow(icon: "hand.raised.fill", title: "Manage Consents", color: MCColors.primaryTeal) {
                    showConsentManagement = true
                }
                Divider().padding(.leading, 60)
                settingsRow(icon: "square.and.arrow.up", title: "Export My Data", color: MCColors.info) {
                    if let profile = currentUser?.activeProfile {
                        exportFileURL = exportService.exportAllData(for: profile)
                        if exportFileURL != nil { showExportShare = true }
                    }
                }
                Divider().padding(.leading, 60)
                settingsRow(icon: "lock.fill", title: "Privacy Settings", color: MCColors.success) {
                    if let url = URL(string: UIApplication.openSettingsURLString) { UIApplication.shared.open(url) }
                }
            }
            .background(MCColors.cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: MCSpacing.cornerRadius))
            .shadow(color: .black.opacity(0.06), radius: 8, y: 2)
            .padding(.horizontal, MCSpacing.screenPadding)
        }
    }

    // MARK: - Doctor Mode

    private var doctorModeRow: some View {
        HStack(spacing: MCSpacing.sm) {
            Image(systemName: "stethoscope")
                .foregroundStyle(MCColors.primaryTeal)
                .font(.system(size: 15))
                .frame(width: 32, height: 32)
                .background(MCColors.primaryTeal.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: MCSpacing.cornerRadiusSmall))
            Text("Doctor Mode")
                .font(MCTypography.body)
                .foregroundStyle(MCColors.textPrimary)
            Spacer()
            if doctorModeEnabled {
                Button {
                    showDoctorDashboard = true
                } label: {
                    Text("Open")
                        .font(MCTypography.captionBold)
                        .foregroundStyle(.white)
                        .padding(.horizontal, MCSpacing.sm)
                        .padding(.vertical, MCSpacing.xxs + 1)
                        .background(MCColors.primaryTeal)
                        .clipShape(Capsule())
                }
            }
            Toggle("", isOn: $doctorModeEnabled)
                .labelsHidden()
                .tint(MCColors.primaryTeal)
        }
        .padding(.horizontal, MCSpacing.cardPadding)
        .padding(.vertical, MCSpacing.sm)
    }

    // MARK: - Danger Zone

    private var dangerZoneSection: some View {
        VStack(spacing: 0) {
            Button {
                showDataDeletion = true
            } label: {
                HStack(spacing: MCSpacing.sm) {
                    Image(systemName: "trash.fill")
                        .foregroundStyle(MCColors.error)
                        .font(.system(size: 15))
                        .frame(width: 32, height: 32)
                        .background(MCColors.error.opacity(0.1))
                        .clipShape(RoundedRectangle(cornerRadius: MCSpacing.cornerRadiusSmall))
                    Text("Delete My Data")
                        .font(MCTypography.body)
                        .foregroundStyle(MCColors.error)
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(MCColors.textTertiary)
                }
                .padding(.horizontal, MCSpacing.cardPadding)
                .padding(.vertical, MCSpacing.sm)
            }
            Divider().padding(.leading, 60)
            Button {
                showSignOutConfirmation = true
            } label: {
                HStack(spacing: MCSpacing.sm) {
                    Image(systemName: "rectangle.portrait.and.arrow.right")
                        .foregroundStyle(MCColors.textSecondary)
                        .font(.system(size: 15))
                        .frame(width: 32, height: 32)
                        .background(MCColors.textSecondary.opacity(0.1))
                        .clipShape(RoundedRectangle(cornerRadius: MCSpacing.cornerRadiusSmall))
                    Text("Sign Out")
                        .font(MCTypography.body)
                        .foregroundStyle(MCColors.textPrimary)
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(MCColors.textTertiary)
                }
                .padding(.horizontal, MCSpacing.cardPadding)
                .padding(.vertical, MCSpacing.sm)
            }
        }
        .background(MCColors.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: MCSpacing.cornerRadius))
        .shadow(color: .black.opacity(0.06), radius: 8, y: 2)
        .padding(.horizontal, MCSpacing.screenPadding)
    }

    // MARK: - Delete Account

    private func deleteAccount() {
        let context = dataService.modelContext
        try? context.delete(model: Nudge.self)
        try? context.delete(model: ChatMessage.self)
        try? context.delete(model: ChatSession.self)
        try? context.delete(model: DoseLog.self)
        try? context.delete(model: SymptomLog.self)
        try? context.delete(model: CareTask.self)
        try? context.delete(model: EpisodeImage.self)
        try? context.delete(model: Medicine.self)
        try? context.delete(model: Episode.self)
        try? context.delete(model: UserProfile.self)
        try? context.delete(model: User.self)
        dataService.save()
        UserDefaults.standard.removeObject(forKey: "mc_has_seeded_demo")
        UserDefaults.standard.removeObject(forKey: "hasCompletedOnboarding")
        authService.logout()
    }

    // MARK: - Version Footer

    private var versionFooter: some View {
        Text("MedCare v\(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0") (\(Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"))")
            .font(MCTypography.caption)
            .foregroundStyle(MCColors.textTertiary)
            .frame(maxWidth: .infinity)
            .padding(.bottom, MCSpacing.lg)
    }
}

// MARK: - Add Family Profile

struct AddFamilyProfileView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(DataService.self) private var dataService
    @Query private var users: [User]
    @State private var name = ""
    @State private var relation: ProfileRelation = .parent
    @State private var dateOfBirth = Calendar.current.date(byAdding: .year, value: -50, to: Date())!
    @State private var gender: Gender?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: MCSpacing.lg) {
                    Text(relation.emoji)
                        .font(.system(size: 56))
                        .frame(width: 100, height: 100)
                        .background(MCColors.primaryTeal.opacity(0.1))
                        .clipShape(Circle())
                    MCTextField(label: "Name", icon: "person", text: $name)
                    VStack(alignment: .leading, spacing: MCSpacing.xs) {
                        Text("Relation")
                            .font(MCTypography.subheadline)
                            .foregroundStyle(MCColors.textSecondary)
                        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: MCSpacing.xs) {
                            ForEach(ProfileRelation.allCases.filter { $0 != .myself }, id: \.self) { rel in
                                Button {
                                    relation = rel
                                } label: {
                                    VStack(spacing: MCSpacing.xxs) {
                                        Text(rel.emoji)
                                            .font(.system(size: 24))
                                        Text(rel.rawValue)
                                            .font(MCTypography.caption)
                                    }
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, MCSpacing.xs)
                                    .background(relation == rel ? MCColors.primaryTeal.opacity(0.1) : MCColors.backgroundLight)
                                    .clipShape(RoundedRectangle(cornerRadius: MCSpacing.cornerRadiusSmall))
                                    .overlay(
                                        relation == rel
                                            ? RoundedRectangle(cornerRadius: MCSpacing.cornerRadiusSmall)
                                                .stroke(MCColors.primaryTeal, lineWidth: 1)
                                            : nil
                                    )
                                }
                                .foregroundStyle(MCColors.textPrimary)
                            }
                        }
                    }
                    VStack(alignment: .leading, spacing: MCSpacing.xs) {
                        Text("Gender")
                            .font(MCTypography.subheadline)
                            .foregroundStyle(MCColors.textSecondary)
                        HStack(spacing: MCSpacing.xs) {
                            ForEach(Gender.allCases, id: \.self) { g in
                                Button {
                                    gender = g
                                } label: {
                                    Text(g.rawValue)
                                        .font(MCTypography.footnote)
                                        .foregroundStyle(gender == g ? .white : MCColors.textPrimary)
                                        .padding(.horizontal, MCSpacing.sm)
                                        .padding(.vertical, MCSpacing.xs)
                                        .background(gender == g ? MCColors.primaryTeal : MCColors.backgroundLight)
                                        .clipShape(Capsule())
                                }
                            }
                        }
                    }
                    DatePicker("Date of Birth", selection: $dateOfBirth, displayedComponents: .date)
                        .datePickerStyle(.compact)
                    MCPrimaryButton("Add Profile", icon: "person.badge.plus") {
                        addProfile()
                    }
                    .disabled(name.isEmpty)
                    .opacity(name.isEmpty ? 0.6 : 1)
                }
                .padding(.horizontal, MCSpacing.screenPadding)
                .padding(.vertical, MCSpacing.lg)
            }
            .background(MCColors.backgroundLight)
            .navigationTitle("Add Family Member")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }

    private func addProfile() {
        guard let user = users.first else { return }
        let _ = dataService.createProfile(for: user, name: name, relation: relation, dob: dateOfBirth, gender: gender)
        dismiss()
    }
}
