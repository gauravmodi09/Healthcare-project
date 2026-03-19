import SwiftUI
import SwiftData

struct HomeView: View {
    @Environment(AppRouter.self) private var router
    @Environment(DataService.self) private var dataService
    @Environment(SmartNudgeService.self) private var nudgeService
    @Query private var users: [User]
    @State private var showUpload = false

    private var currentUser: User? { users.first }
    private var activeProfile: UserProfile? { currentUser?.activeProfile }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: MCSpacing.sectionSpacing) {
                    // Header with greeting & profile switcher
                    headerSection

                    if let profile = activeProfile {
                        // Nudge banner
                        nudgeBannerSection(profile: profile)

                        // Next Dose Hero Card
                        nextDoseHeroCard(profile: profile)

                        // Metrics Row — Streak + Today's Progress
                        metricsRow(profile: profile)

                        // Quick Actions Row
                        quickActionsRow

                        // Active Episodes
                        activeEpisodesSection(profile: profile)

                        // Upcoming Tasks
                        upcomingTasksSection(profile: profile)
                    }
                }
                .padding(.horizontal, MCSpacing.screenPadding)
                .padding(.bottom, MCSpacing.xxl)
            }
            .background(MCColors.backgroundLight)
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .navigationDestination(for: UUID.self) { id in
                EpisodeDetailView(episodeId: id)
            }
            .sheet(isPresented: $showUpload) {
                UploadPrescriptionView()
            }
        }
    }

    // MARK: - Header

    private var headerSection: some View {
        HStack(alignment: .center) {
            VStack(alignment: .leading, spacing: MCSpacing.xxs) {
                Text(greetingText)
                    .font(MCTypography.callout)
                    .foregroundStyle(MCColors.textSecondary)

                Text(activeProfile?.name ?? "User")
                    .font(MCTypography.display)
                    .foregroundStyle(MCColors.textPrimary)
            }

            Spacer()

            // Profile avatar
            if let profile = activeProfile {
                Menu {
                    if let user = currentUser {
                        ForEach(user.profiles) { p in
                            Button {
                                dataService.switchActiveProfile(to: p, for: user)
                            } label: {
                                Label(
                                    "\(p.avatarEmoji) \(p.name)",
                                    systemImage: p.isActive ? "checkmark.circle.fill" : "circle"
                                )
                            }
                        }
                    }
                } label: {
                    Text(profile.avatarEmoji)
                        .font(.system(size: 28))
                        .frame(width: MCSpacing.avatarSize, height: MCSpacing.avatarSize)
                        .background(MCColors.primaryTeal.opacity(0.1))
                        .clipShape(Circle())
                }
            }
        }
        .padding(.top, MCSpacing.xs)
    }

    // MARK: - Nudge Banner

    @ViewBuilder
    private func nudgeBannerSection(profile: UserProfile) -> some View {
        ForEach(nudgeService.activeNudges) { nudge in
            NudgeBannerView(nudge: nudge) {
                nudgeService.markActedOn(nudge)
            } onDismiss: {
                nudgeService.dismissNudge(nudge)
            }
        }
    }

    // MARK: - Next Dose Hero Card

    private func nextDoseHeroCard(profile: UserProfile) -> some View {
        let upcoming = dataService.upcomingDoses(for: profile, limit: 1)
        let todaysDosesList = dataService.todaysDoses(for: profile)
        let allDone = todaysDosesList.allSatisfy { $0.status == .taken } && !todaysDosesList.isEmpty

        return Group {
            if let nextDose = upcoming.first {
                // Has upcoming dose
                VStack(alignment: .leading, spacing: MCSpacing.sm) {
                    HStack(spacing: MCSpacing.sm) {
                        // Pill icon
                        ZStack {
                            Circle()
                                .fill(.white.opacity(0.2))
                                .frame(width: 52, height: 52)
                            Image(systemName: nextDose.medicine?.doseForm.icon ?? "pills")
                                .font(.system(size: 24, weight: .medium))
                                .foregroundStyle(.white)
                        }

                        VStack(alignment: .leading, spacing: 4) {
                            Text("Next Dose")
                                .font(MCTypography.caption)
                                .foregroundStyle(.white.opacity(0.8))

                            Text(nextDose.medicine?.brandName ?? "Medicine")
                                .font(MCTypography.title2)
                                .foregroundStyle(.white)
                                .fontWeight(.bold)

                            Text(nextDose.medicine?.dosage ?? "")
                                .font(MCTypography.subheadline)
                                .foregroundStyle(.white.opacity(0.85))
                        }

                        Spacer()

                        // Time countdown
                        VStack(alignment: .trailing, spacing: 4) {
                            Text(nextDose.scheduledTime, style: .time)
                                .font(MCTypography.headline)
                                .foregroundStyle(.white)

                            Text(timeUntil(nextDose.scheduledTime))
                                .font(MCTypography.caption)
                                .foregroundStyle(.white.opacity(0.8))
                        }
                    }

                    // Take Now button (if within reminder window — within 30 min)
                    if nextDose.scheduledTime.timeIntervalSinceNow < 30 * 60 {
                        Button {
                            withAnimation {
                                dataService.logDose(nextDose, status: .taken)
                            }
                        } label: {
                            HStack {
                                Image(systemName: "checkmark.circle.fill")
                                Text("Take Now")
                                    .fontWeight(.semibold)
                            }
                            .font(MCTypography.subheadline)
                            .foregroundStyle(MCColors.primaryTeal)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, MCSpacing.xs)
                            .background(.white)
                            .clipShape(RoundedRectangle(cornerRadius: MCSpacing.cornerRadiusSmall))
                        }
                    }
                }
                .padding(MCSpacing.cardPadding)
                .background(
                    LinearGradient(
                        colors: [MCColors.primaryTeal, MCColors.primaryTealDark],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .clipShape(RoundedRectangle(cornerRadius: MCSpacing.cornerRadius))
                .shadow(color: MCColors.primaryTeal.opacity(0.3), radius: 12, y: 6)
            } else if allDone {
                // All done for today
                HStack(spacing: MCSpacing.md) {
                    ZStack {
                        Circle()
                            .fill(MCColors.success.opacity(0.15))
                            .frame(width: 52, height: 52)
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 28))
                            .foregroundStyle(MCColors.success)
                    }

                    VStack(alignment: .leading, spacing: 4) {
                        Text("All done for today!")
                            .font(MCTypography.title2)
                            .foregroundStyle(MCColors.textPrimary)
                            .fontWeight(.bold)
                        Text("Great job keeping up with your medications")
                            .font(MCTypography.caption)
                            .foregroundStyle(MCColors.textSecondary)
                    }

                    Spacer()
                }
                .padding(MCSpacing.cardPadding)
                .background(MCColors.cardBackground)
                .clipShape(RoundedRectangle(cornerRadius: MCSpacing.cornerRadius))
                .overlay(
                    RoundedRectangle(cornerRadius: MCSpacing.cornerRadius)
                        .stroke(MCColors.success.opacity(0.3), lineWidth: 1)
                )
            } else {
                // No doses scheduled
                HStack(spacing: MCSpacing.md) {
                    ZStack {
                        Circle()
                            .fill(MCColors.primaryTeal.opacity(0.1))
                            .frame(width: 52, height: 52)
                        Image(systemName: "pills")
                            .font(.system(size: 24))
                            .foregroundStyle(MCColors.primaryTeal)
                    }

                    VStack(alignment: .leading, spacing: 4) {
                        Text("No doses scheduled")
                            .font(MCTypography.title2)
                            .foregroundStyle(MCColors.textPrimary)
                            .fontWeight(.bold)
                        Text("Upload a prescription to get started")
                            .font(MCTypography.caption)
                            .foregroundStyle(MCColors.textSecondary)
                    }

                    Spacer()
                }
                .padding(MCSpacing.cardPadding)
                .background(MCColors.cardBackground)
                .clipShape(RoundedRectangle(cornerRadius: MCSpacing.cornerRadius))
            }
        }
    }

    // MARK: - Metrics Row

    private func metricsRow(profile: UserProfile) -> some View {
        let doses = dataService.todaysDoses(for: profile)
        let taken = doses.filter { $0.status == .taken }.count
        let totalDoses = doses.count
        let adherence = totalDoses > 0 ? Double(taken) / Double(totalDoses) : 0.0
        let streak = bestStreak(for: profile)
        let level = StreakLevel(streak: streak)

        return LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
            // Left: Streak Card
            VStack(spacing: MCSpacing.sm) {
                HStack {
                    Image(systemName: level.icon)
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(level.color)
                    Spacer()
                }

                HStack(alignment: .firstTextBaseline, spacing: 4) {
                    Text("\(streak)")
                        .font(.system(size: 32, weight: .bold, design: .rounded))
                        .foregroundStyle(MCColors.textPrimary)
                    Text("days")
                        .font(MCTypography.caption)
                        .foregroundStyle(MCColors.textSecondary)
                    Spacer()
                }

                HStack {
                    Text(level.label)
                        .font(MCTypography.captionBold)
                        .foregroundStyle(level.color)
                        .padding(.horizontal, MCSpacing.xs)
                        .padding(.vertical, 2)
                        .background(level.color.opacity(0.12))
                        .clipShape(Capsule())
                    Spacer()
                }
            }
            .padding(MCSpacing.cardPadding)
            .background(MCColors.cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: MCSpacing.cornerRadius))
            .shadow(color: .black.opacity(0.04), radius: 8, y: 2)

            // Right: Today's Progress Card
            VStack(spacing: MCSpacing.sm) {
                HStack {
                    Text("Today")
                        .font(MCTypography.caption)
                        .foregroundStyle(MCColors.textSecondary)
                    Spacer()
                }

                ActivityRingView(
                    progress: adherence,
                    size: 56,
                    lineWidth: 7,
                    color: MCColors.primaryTeal
                )

                Text("\(taken)/\(totalDoses) doses")
                    .font(MCTypography.captionBold)
                    .foregroundStyle(MCColors.textSecondary)
            }
            .padding(MCSpacing.cardPadding)
            .background(MCColors.cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: MCSpacing.cornerRadius))
            .shadow(color: .black.opacity(0.04), radius: 8, y: 2)
        }
    }

    // MARK: - Quick Actions Row

    private var quickActionsRow: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
            // Upload Prescription
            Button {
                showUpload = true
            } label: {
                HStack(spacing: MCSpacing.xs) {
                    ZStack {
                        Circle()
                            .fill(MCColors.accentCoral.opacity(0.1))
                            .frame(width: 36, height: 36)
                        Image(systemName: "camera.fill")
                            .font(.system(size: 16))
                            .foregroundStyle(MCColors.accentCoral)
                    }

                    VStack(alignment: .leading, spacing: 2) {
                        Text("Upload")
                            .font(MCTypography.bodyMedium)
                            .foregroundStyle(MCColors.textPrimary)
                        Text("Prescription")
                            .font(MCTypography.caption)
                            .foregroundStyle(MCColors.textSecondary)
                    }

                    Spacer()
                }
                .padding(MCSpacing.cardPadding)
                .background(MCColors.cardBackground)
                .clipShape(RoundedRectangle(cornerRadius: MCSpacing.cornerRadius))
                .shadow(color: .black.opacity(0.04), radius: 8, y: 2)
                .overlay(
                    RoundedRectangle(cornerRadius: MCSpacing.cornerRadius)
                        .stroke(MCColors.accentCoral.opacity(0.2), lineWidth: 1)
                )
            }

            // AI Health Chat
            Button {
                router.selectedTab = .ai
            } label: {
                HStack(spacing: MCSpacing.xs) {
                    ZStack {
                        Circle()
                            .fill(MCColors.primaryTeal.opacity(0.1))
                            .frame(width: 36, height: 36)
                        Image(systemName: "sparkles")
                            .font(.system(size: 16))
                            .foregroundStyle(MCColors.primaryTeal)
                    }

                    VStack(alignment: .leading, spacing: 2) {
                        Text("AI Health")
                            .font(MCTypography.bodyMedium)
                            .foregroundStyle(MCColors.textPrimary)
                        Text("Chat")
                            .font(MCTypography.caption)
                            .foregroundStyle(MCColors.textSecondary)
                    }

                    Spacer()
                }
                .padding(MCSpacing.cardPadding)
                .background(MCColors.cardBackground)
                .clipShape(RoundedRectangle(cornerRadius: MCSpacing.cornerRadius))
                .shadow(color: .black.opacity(0.04), radius: 8, y: 2)
                .overlay(
                    RoundedRectangle(cornerRadius: MCSpacing.cornerRadius)
                        .stroke(MCColors.primaryTeal.opacity(0.2), lineWidth: 1)
                )
            }
        }
    }

    // MARK: - Active Episodes

    private func activeEpisodesSection(profile: UserProfile) -> some View {
        let episodes = dataService.activeEpisodes(for: profile)

        return Group {
            if !episodes.isEmpty {
                VStack(alignment: .leading, spacing: MCSpacing.sm) {
                    Text("Active Care Plans")
                        .font(MCTypography.headline)
                        .foregroundStyle(MCColors.textPrimary)
                        .padding(.bottom, MCSpacing.xxs)

                    ForEach(episodes) { episode in
                        NavigationLink(value: episode.id) {
                            EpisodeCard(episode: episode)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }

    // MARK: - Upcoming Tasks

    private func upcomingTasksSection(profile: UserProfile) -> some View {
        let tasks = profile.episodes
            .flatMap { $0.tasks }
            .filter { !$0.isCompleted }
            .sorted { ($0.dueDate ?? .distantFuture) < ($1.dueDate ?? .distantFuture) }
            .prefix(3)

        return Group {
            if !tasks.isEmpty {
                VStack(alignment: .leading, spacing: MCSpacing.sm) {
                    Text("Upcoming Tasks")
                        .font(MCTypography.headline)
                        .foregroundStyle(MCColors.textPrimary)
                        .padding(.bottom, MCSpacing.xxs)

                    ForEach(Array(tasks)) { task in
                        TaskCard(task: task)
                    }
                }
            }
        }
    }

    // MARK: - Helpers

    private var greetingText: String {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 5..<12: return "Good morning"
        case 12..<17: return "Good afternoon"
        case 17..<21: return "Good evening"
        default: return "Good night"
        }
    }

    private func timeUntil(_ date: Date) -> String {
        let interval = date.timeIntervalSinceNow
        guard interval > 0 else { return "now" }
        let hours = Int(interval) / 3600
        let minutes = (Int(interval) % 3600) / 60
        if hours > 0 {
            return "in \(hours)h \(minutes)m"
        } else {
            return "in \(minutes)m"
        }
    }

    private func bestStreak(for profile: UserProfile) -> Int {
        let episodes = dataService.activeEpisodes(for: profile)
        guard !episodes.isEmpty else { return 0 }
        return episodes.map { $0.adherenceStreak }.max() ?? 0
    }
}

// MARK: - Subviews

struct DoseReminderCard: View {
    let doseLog: DoseLog

    var body: some View {
        MCCard {
            HStack(spacing: MCSpacing.sm) {
                Circle()
                    .fill(MCColors.primaryTeal.opacity(0.1))
                    .frame(width: 40, height: 40)
                    .overlay(
                        Image(systemName: doseLog.medicine?.doseForm.icon ?? "pills")
                            .foregroundStyle(MCColors.primaryTeal)
                    )

                VStack(alignment: .leading, spacing: 2) {
                    Text(doseLog.medicine?.brandName ?? "Medicine")
                        .font(MCTypography.bodyMedium)
                        .foregroundStyle(MCColors.textPrimary)
                    HStack(spacing: 4) {
                        Text(doseLog.medicine?.dosage ?? "")
                            .font(MCTypography.caption)
                            .foregroundStyle(MCColors.textSecondary)
                        if let med = doseLog.medicine, med.mealTiming != .noPreference {
                            Text("·")
                                .foregroundStyle(MCColors.textTertiary)
                            Image(systemName: med.mealTiming.icon)
                                .font(.system(size: 10))
                                .foregroundStyle(MCColors.warning)
                            Text(med.mealTiming.shortLabel)
                                .font(MCTypography.caption)
                                .foregroundStyle(MCColors.warning)
                        }
                    }
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 2) {
                    Text(doseLog.scheduledTime, style: .time)
                        .font(MCTypography.subheadline)
                        .foregroundStyle(MCColors.textPrimary)

                    MCBadge(doseLog.status.rawValue, color: Color(hex: doseLog.status.color))
                }
            }
        }
    }
}

struct EpisodeCard: View {
    let episode: Episode

    var body: some View {
        MCAccentCard(accent: Color(hex: episode.episodeType.color)) {
            VStack(alignment: .leading, spacing: MCSpacing.xs) {
                HStack {
                    Image(systemName: episode.episodeType.icon)
                        .foregroundStyle(Color(hex: episode.episodeType.color))
                    Text(episode.title)
                        .font(MCTypography.bodyMedium)
                        .foregroundStyle(MCColors.textPrimary)
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(MCColors.textTertiary)
                }

                HStack(spacing: MCSpacing.md) {
                    if let doctor = episode.doctorName {
                        Label(doctor, systemImage: "stethoscope")
                            .font(MCTypography.caption)
                            .foregroundStyle(MCColors.textSecondary)
                    }

                    Label("\(episode.activeMedicines.count) meds", systemImage: "pills")
                        .font(MCTypography.caption)
                        .foregroundStyle(MCColors.textSecondary)

                    if episode.adherenceStreak > 0 {
                        HStack(spacing: 2) {
                            Image(systemName: "flame.fill")
                                .font(.system(size: 10))
                            Text("\(episode.adherenceStreak)d streak")
                                .font(MCTypography.caption)
                        }
                        .foregroundStyle(MCColors.accentCoral)
                    }
                }

                // Adherence bar
                let adherence = episode.adherencePercentage
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Capsule()
                            .fill(MCColors.backgroundLight)
                            .frame(height: 6)

                        Capsule()
                            .fill(adherence > 0.7 ? MCColors.success : MCColors.warning)
                            .frame(width: geo.size.width * adherence, height: 6)
                    }
                }
                .frame(height: 6)
            }
        }
    }
}

struct TaskCard: View {
    let task: CareTask

    var body: some View {
        MCCard {
            HStack(spacing: MCSpacing.sm) {
                Image(systemName: task.taskType.icon)
                    .font(.system(size: 18))
                    .foregroundStyle(MCColors.primaryTeal)
                    .frame(width: 36, height: 36)
                    .background(MCColors.primaryTeal.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: 8))

                VStack(alignment: .leading, spacing: 2) {
                    Text(task.title)
                        .font(MCTypography.bodyMedium)
                        .foregroundStyle(MCColors.textPrimary)
                    if let due = task.dueDate {
                        Text(due, style: .relative)
                            .font(MCTypography.caption)
                            .foregroundStyle(MCColors.textSecondary)
                    }
                }

                Spacer()

                MCBadge(task.taskType.rawValue, color: MCColors.primaryTeal, style: .outlined)
            }
        }
    }
}
