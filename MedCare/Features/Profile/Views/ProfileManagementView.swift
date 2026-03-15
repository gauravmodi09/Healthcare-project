import SwiftUI
import SwiftData

struct ProfileManagementView: View {
    @Environment(DataService.self) private var dataService
    @Environment(AuthService.self) private var authService
    @Query private var users: [User]
    @State private var showAddProfile = false
    @State private var showSettings = false
    @State private var showSubscription = false

    private var currentUser: User? { users.first }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: MCSpacing.sectionSpacing) {
                    // Active profile header
                    if let profile = currentUser?.activeProfile {
                        activeProfileCard(profile)
                    }

                    // Family profiles
                    familyProfilesSection

                    // Subscription
                    subscriptionCard

                    // Settings
                    settingsSection

                    // Logout
                    MCSecondaryButton("Logout", icon: "rectangle.portrait.and.arrow.right") {
                        authService.logout()
                    }
                    .padding(.horizontal, MCSpacing.screenPadding)
                    .padding(.bottom, MCSpacing.lg)
                }
                .padding(.vertical, MCSpacing.md)
            }
            .background(MCColors.backgroundLight)
            .navigationTitle("Profile")
            .navigationDestination(for: String.self) { destination in
                if destination == "profileFiles" {
                    ProfileFilesView()
                }
            }
            .sheet(isPresented: $showAddProfile) {
                AddFamilyProfileView()
            }
        }
    }

    // MARK: - Active Profile

    private func activeProfileCard(_ profile: UserProfile) -> some View {
        VStack(spacing: MCSpacing.md) {
            // Avatar & Name card
            MCCard {
                VStack(spacing: MCSpacing.md) {
                    Text(profile.avatarEmoji)
                        .font(.system(size: 44))
                        .frame(width: 72, height: 72)
                        .background(MCColors.primaryTeal.opacity(0.1))
                        .clipShape(Circle())

                    VStack(spacing: MCSpacing.xxs) {
                        Text(profile.name)
                            .font(MCTypography.title)
                            .foregroundStyle(MCColors.textPrimary)

                        HStack(spacing: MCSpacing.xs) {
                            Text(profile.relation.rawValue)
                                .font(MCTypography.footnote)
                                .foregroundStyle(MCColors.textSecondary)

                            if let age = profile.age {
                                Text("·")
                                    .foregroundStyle(MCColors.textTertiary)
                                Text("\(age) years old")
                                    .font(MCTypography.footnote)
                                    .foregroundStyle(MCColors.textSecondary)
                            }
                        }
                    }

                    // Known conditions
                    if !profile.knownConditions.isEmpty {
                        FlowLayout(spacing: MCSpacing.xxs) {
                            ForEach(profile.knownConditions, id: \.self) { condition in
                                Text(condition)
                                    .font(MCTypography.caption)
                                    .foregroundStyle(MCColors.primaryTeal)
                                    .padding(.horizontal, MCSpacing.xs)
                                    .padding(.vertical, 3)
                                    .background(MCColors.primaryTeal.opacity(0.1))
                                    .clipShape(Capsule())
                            }
                        }
                    }
                }
                .frame(maxWidth: .infinity)
            }

            // Stats row — separate card for visual weight
            HStack(spacing: 0) {
                profileStat(
                    value: "\(profile.episodes.count)",
                    label: "Episodes",
                    icon: "doc.text"
                )
                Divider().frame(height: 40)
                profileStat(
                    value: "\(profile.episodes.flatMap { $0.medicines }.count)",
                    label: "Medicines",
                    icon: "pills"
                )
                Divider().frame(height: 40)
                profileStat(
                    value: "\(profile.episodes.flatMap { $0.images }.count)",
                    label: "Files",
                    icon: "folder"
                )
                Divider().frame(height: 40)
                profileStat(
                    value: "\(Int(overallAdherence(profile) * 100))%",
                    label: "Adherence",
                    icon: "chart.bar"
                )
            }
            .padding(.vertical, MCSpacing.sm)
            .background(MCColors.cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: MCSpacing.cornerRadius))
            .shadow(color: .black.opacity(0.06), radius: 8, y: 2)
        }
        .padding(.horizontal, MCSpacing.screenPadding)
    }

    private func profileStat(value: String, label: String, icon: String) -> some View {
        VStack(spacing: MCSpacing.xxs) {
            Image(systemName: icon)
                .foregroundStyle(MCColors.primaryTeal)
            Text(value)
                .font(MCTypography.headline)
                .foregroundStyle(MCColors.textPrimary)
            Text(label)
                .font(MCTypography.caption)
                .foregroundStyle(MCColors.textSecondary)
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Family Profiles

    private var familyProfilesSection: some View {
        VStack(alignment: .leading, spacing: MCSpacing.sm) {
            HStack {
                Text("Family Profiles")
                    .font(MCTypography.headline)
                Spacer()
                Button {
                    showAddProfile = true
                } label: {
                    Label("Add", systemImage: "plus.circle")
                        .font(MCTypography.subheadline)
                        .foregroundStyle(MCColors.primaryTeal)
                }
            }
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
                                VStack(spacing: MCSpacing.xs) {
                                    Text(profile.avatarEmoji)
                                        .font(.system(size: 32))
                                        .frame(width: 56, height: 56)
                                        .background(profile.isActive ? MCColors.primaryTeal.opacity(0.2) : MCColors.backgroundLight)
                                        .clipShape(Circle())
                                        .overlay(
                                            profile.isActive
                                                ? Circle().stroke(MCColors.primaryTeal, lineWidth: 2)
                                                : nil
                                        )

                                    Text(profile.name)
                                        .font(MCTypography.caption)
                                        .foregroundStyle(profile.isActive ? MCColors.primaryTeal : MCColors.textSecondary)

                                    Text(profile.relation.rawValue)
                                        .font(.system(size: 10))
                                        .foregroundStyle(MCColors.textTertiary)
                                }
                            }
                        }
                    }

                    // Add button
                    Button {
                        showAddProfile = true
                    } label: {
                        VStack(spacing: MCSpacing.xs) {
                            Image(systemName: "plus")
                                .font(.system(size: 20))
                                .frame(width: 56, height: 56)
                                .background(MCColors.primaryTeal.opacity(0.05))
                                .clipShape(Circle())
                                .overlay(
                                    Circle()
                                        .strokeBorder(style: StrokeStyle(lineWidth: 1, dash: [4]))
                                        .foregroundStyle(MCColors.primaryTeal.opacity(0.3))
                                )
                            Text("Add")
                                .font(MCTypography.caption)
                                .foregroundStyle(MCColors.primaryTeal)
                            Text(" ")
                                .font(.system(size: 10))
                        }
                    }
                }
                .padding(.horizontal, MCSpacing.screenPadding)
            }
        }
    }

    // MARK: - Subscription

    private var subscriptionCard: some View {
        MCCard {
            HStack {
                VStack(alignment: .leading, spacing: MCSpacing.xxs) {
                    HStack {
                        Text("Current Plan")
                            .font(MCTypography.subheadline)
                            .foregroundStyle(MCColors.textSecondary)
                        MCBadge(currentUser?.subscriptionTier.displayName ?? "Free", color: MCColors.primaryTeal, style: .filled)
                    }
                    Text("Upgrade to Pro for unlimited episodes & AI extraction")
                        .font(MCTypography.caption)
                        .foregroundStyle(MCColors.textTertiary)
                }

                Spacer()

                Button {
                    showSubscription = true
                } label: {
                    Text("Upgrade")
                        .font(MCTypography.subheadline)
                        .foregroundStyle(.white)
                        .padding(.horizontal, MCSpacing.md)
                        .padding(.vertical, MCSpacing.xs)
                        .background(MCColors.coralGradient)
                        .clipShape(Capsule())
                }
            }
        }
        .padding(.horizontal, MCSpacing.screenPadding)
    }

    // MARK: - Settings

    private var settingsSection: some View {
        VStack(alignment: .leading, spacing: MCSpacing.xs) {
            Text("Settings")
                .font(MCTypography.headline)
                .padding(.horizontal, MCSpacing.screenPadding)

            VStack(spacing: 0) {
                NavigationLink(value: "profileFiles") {
                    HStack(spacing: MCSpacing.sm) {
                        Image(systemName: "folder.fill")
                            .foregroundStyle(MCColors.info)
                            .frame(width: 32, height: 32)
                            .background(MCColors.info.opacity(0.1))
                            .clipShape(RoundedRectangle(cornerRadius: 8))

                        Text("All Documents")
                            .font(MCTypography.body)
                            .foregroundStyle(MCColors.textPrimary)

                        Spacer()

                        if let profile = currentUser?.activeProfile {
                            Text("\(profile.episodes.flatMap { $0.images }.count)")
                                .font(MCTypography.captionBold)
                                .foregroundStyle(MCColors.info)
                        }

                        Image(systemName: "chevron.right")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundStyle(MCColors.textTertiary)
                    }
                    .padding(.horizontal, MCSpacing.cardPadding)
                    .padding(.vertical, MCSpacing.sm)
                }
                .buttonStyle(.plain)
                Divider().padding(.leading, 60)
                settingsRow(icon: "bell", title: "Notification Preferences", color: MCColors.primaryTeal)
                Divider().padding(.leading, 60)
                settingsRow(icon: "lock.shield", title: "Privacy & Security", color: MCColors.success)
                Divider().padding(.leading, 60)
                settingsRow(icon: "questionmark.circle", title: "Help & Support", color: MCColors.info)
                Divider().padding(.leading, 60)
                settingsRow(icon: "doc.text", title: "Terms & Privacy Policy", color: MCColors.textSecondary)
                Divider().padding(.leading, 60)
                settingsRow(icon: "trash", title: "Delete Account & Data", color: MCColors.error)
            }
            .background(MCColors.cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: MCSpacing.cornerRadius))
            .shadow(color: .black.opacity(0.06), radius: 8, y: 2)
            .padding(.horizontal, MCSpacing.screenPadding)
        }
    }

    private func settingsRow(icon: String, title: String, color: Color) -> some View {
        Button {
            // Navigate to setting
        } label: {
            HStack(spacing: MCSpacing.sm) {
                Image(systemName: icon)
                    .foregroundStyle(color)
                    .frame(width: 32, height: 32)
                    .background(color.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: 8))

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

    private func overallAdherence(_ profile: UserProfile) -> Double {
        let allLogs = profile.episodes.flatMap { $0.medicines }.flatMap { $0.doseLogs }
        guard !allLogs.isEmpty else { return 0 }
        let taken = allLogs.filter { $0.status == .taken }.count
        return Double(taken) / Double(allLogs.count)
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
                    // Avatar preview
                    Text(relation.emoji)
                        .font(.system(size: 56))
                        .frame(width: 100, height: 100)
                        .background(MCColors.primaryTeal.opacity(0.1))
                        .clipShape(Circle())

                    MCTextField(label: "Name", icon: "person", text: $name)

                    // Relation picker
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

                    // Gender
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
