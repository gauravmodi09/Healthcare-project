import SwiftUI
import SwiftData
import StoreKit

struct HomeView: View {
    @Environment(AppRouter.self) private var router
    @Environment(DataService.self) private var dataService
    @Environment(SmartNudgeService.self) private var nudgeService
    @Environment(LiveActivityService.self) private var liveActivityService
    @Environment(\.requestReview) private var requestReview
    @Query private var users: [User]
    @State private var showUpload = false
    @State private var showMessages = false
    @State private var showStreakCelebration = false
    @State private var previousStreak: Int?
    @State private var isLoading = true
    @State private var profileLoadFailed = false
    @AppStorage("mc_has_requested_review") private var hasRequestedReview = false

    private let morningBriefingService = MorningBriefingService()
    private let analyticsService = AnalyticsService()
    private let drugInteractionService = DrugInteractionService()

    private var currentUser: User? { users.first }
    private var activeProfile: UserProfile? { currentUser?.activeProfile }

    private var moodTracker: MoodTrackingService {
        MoodTrackingService(profileId: activeProfile?.id.uuidString)
    }

    private var isMorning: Bool {
        Calendar.current.component(.hour, from: Date()) < 12
    }

    private var hasLoggedMoodToday: Bool {
        let entries = moodTracker.getMoodHistory(days: 1)
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        return entries.contains { calendar.startOfDay(for: $0.date) == today }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: MCSpacing.sectionSpacing) {
                    // Header with greeting & profile switcher
                    headerSection

                    if isLoading {
                        // Skeleton loading placeholders
                        ForEach(0..<3, id: \.self) { _ in
                            SkeletonCardView()
                        }
                    } else if profileLoadFailed {
                        MCErrorView(
                            "Couldn't Load Profile",
                            message: "There was a problem loading your health data. Please try again.",
                            retryAction: {
                                profileLoadFailed = false
                                isLoading = true
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                                    withAnimation(.easeOut(duration: 0.3)) {
                                        isLoading = false
                                        if activeProfile == nil && currentUser != nil {
                                            profileLoadFailed = true
                                        }
                                    }
                                }
                            }
                        )
                    } else if activeProfile == nil {
                        // No profile yet — welcome empty state
                        welcomeEmptyState
                    } else if let profile = activeProfile {
                        // Hero Health Score
                        healthScoreHero(profile: profile)

                        // Morning Briefing (before noon only)
                        if isMorning {
                            morningBriefingCard(profile: profile)
                        }

                        // Nudge banner
                        nudgeBannerSection(profile: profile)

                        // Next Dose Hero Card
                        nextDoseHeroCard(profile: profile)

                        // Metrics Row — Streak + Today's Progress
                        metricsRow(profile: profile)

                        // Mood Check-In (only if not logged today)
                        if !hasLoggedMoodToday {
                            let medicineNames = profile.episodes
                                .flatMap { $0.activeMedicines }
                                .map { $0.brandName }
                            MoodCheckInCard(medicines: medicineNames, profileId: profile.id.uuidString)
                        }

                        // Quick Actions Row
                        quickActionsRow

                        // Active Episodes
                        activeEpisodesSection(profile: profile)

                        // Drug Interaction Warnings
                        drugInteractionSection(profile: profile)

                        // Smart Insights
                        insightsSection(profile: profile)

                        // Upcoming Tasks
                        upcomingTasksSection(profile: profile)

                        // Child Growth Chart (only for child profiles)
                        if ChildCareService.isChildProfile(profile) {
                            ChildGrowthChartCard(profile: profile)
                        }
                    }
                }
                .padding(.horizontal, MCSpacing.screenPadding)
                .padding(.bottom, MCSpacing.xxl)
            }
            .refreshable {
                await refreshHomeData()
            }
            .background(MCColors.backgroundLight)
            .dynamicTypeSize(.xSmall ... .accessibility3)
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .navigationDestination(for: UUID.self) { id in
                EpisodeDetailView(episodeId: id)
            }
            .sheet(isPresented: $showUpload) {
                UploadPrescriptionView()
            }
            .sheet(isPresented: $showMessages) {
                DoctorListView()
            }
            .overlay {
                if showStreakCelebration {
                    ConfettiView()
                        .allowsHitTesting(false)
                        .transition(.opacity)
                }
            }
            .onAppear {
                // Brief skeleton loading state
                if isLoading {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                        withAnimation(.easeOut(duration: 0.3)) {
                            isLoading = false
                        }
                    }
                }

                if let profile = activeProfile {
                    let streak = bestStreak(for: profile)
                    // Show celebration when streak hits a milestone
                    if let prev = previousStreak, prev < streak,
                       StreakLevel.milestones.contains(streak) {
                        withAnimation {
                            showStreakCelebration = true
                        }
                        DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
                            withAnimation {
                                showStreakCelebration = false
                            }
                        }
                    }
                    previousStreak = streak

                    // Request app review after 7-day streak (only once)
                    if !hasRequestedReview && streak >= 7 {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                            requestReview()
                            hasRequestedReview = true
                        }
                    }

                    // Also trigger review when an episode is completed
                    if !hasRequestedReview {
                        let completedEpisodes = profile.episodes.filter { $0.status == .completed }
                        if !completedEpisodes.isEmpty {
                            DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                                requestReview()
                                hasRequestedReview = true
                            }
                        }
                    }
                }
            }
        }
    }

    // MARK: - Pull-to-Refresh

    @MainActor
    private func refreshHomeData() async {
        if let profile = activeProfile {
            nudgeService.evaluateNudges(
                profile: profile,
                modelContext: dataService.modelContainer.mainContext
            )
        }
        // Brief delay so the refresh indicator feels intentional
        try? await Task.sleep(for: .milliseconds(300))
    }

    // MARK: - Welcome Empty State (no profile)

    private var welcomeEmptyState: some View {
        VStack(spacing: MCSpacing.lg) {
            Spacer().frame(height: MCSpacing.xl)

            ZStack {
                Circle()
                    .fill(MCColors.primaryTeal.opacity(0.1))
                    .frame(width: 120, height: 120)
                Image(systemName: "heart.text.square.fill")
                    .font(.system(size: 52, weight: .medium))
                    .foregroundStyle(MCColors.primaryTeal)
            }

            VStack(spacing: MCSpacing.sm) {
                Text("Welcome to MedCare")
                    .font(MCTypography.title)
                    .foregroundStyle(MCColors.textPrimary)

                Text("Your personal health companion. Set up your profile to get started with medication tracking, reminders, and AI-powered health insights.")
                    .font(MCTypography.body)
                    .foregroundStyle(MCColors.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, MCSpacing.md)
            }

            VStack(spacing: MCSpacing.sm) {
                MCPrimaryButton("Add Your First Profile", icon: "person.badge.plus") {
                    // Switch to Profile tab where user can set up their profile
                    router.selectedTab = .profile
                }

                Button {
                    showUpload = true
                } label: {
                    HStack(spacing: MCSpacing.xs) {
                        Image(systemName: "doc.text.viewfinder")
                            .font(.system(size: 15, weight: .medium))
                        Text("Upload a Prescription")
                            .font(MCTypography.bodyMedium)
                    }
                    .foregroundStyle(MCColors.primaryTeal)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, MCSpacing.sm)
                    .background(MCColors.primaryTeal.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: MCSpacing.cornerRadius))
                }
            }
            .padding(.horizontal, MCSpacing.md)

            Spacer()
        }
    }

    // MARK: - Header

    private var headerSection: some View {
        HStack(alignment: .center) {
            VStack(alignment: .leading, spacing: MCSpacing.xxs) {
                Text(greetingText)
                    .font(MCTypography.callout)
                    .foregroundStyle(MCColors.textSecondary)

                HStack(spacing: MCSpacing.xs) {
                    Text(activeProfile?.name ?? "User")
                        .font(MCTypography.display)
                        .foregroundStyle(MCColors.textPrimary)

                    if let profile = activeProfile, ChildCareService.isChildProfile(profile) {
                        ChildProfileBadge()
                    }
                }
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

    // MARK: - Morning Briefing

    private func morningBriefingCard(profile: UserProfile) -> some View {
        let doses = dataService.todaysDoses(for: profile)
        let doseInfos = doses.compactMap { log -> DoseInfo? in
            guard let med = log.medicine else { return nil }
            return DoseInfo(
                medicineName: med.brandName,
                dosage: med.dosage,
                scheduledTime: log.scheduledTime,
                isCritical: med.isCritical
            )
        }

        let allDoseLogs = profile.episodes.flatMap { $0.medicines }.flatMap { $0.doseLogs }
        let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: Date()) ?? Date()
        let yesterdayStart = Calendar.current.startOfDay(for: yesterday)
        let todayStart = Calendar.current.startOfDay(for: Date())
        let yesterdayDoses = allDoseLogs.filter { $0.scheduledTime >= yesterdayStart && $0.scheduledTime < todayStart }
        let yesterdayAdherence: Double = yesterdayDoses.isEmpty ? 1.0
            : Double(yesterdayDoses.filter { $0.status == .taken }.count) / Double(yesterdayDoses.count)

        let streak = bestStreak(for: profile)
        let healthScoreService = HealthScoreService()
        let allSymptomLogs = profile.episodes.flatMap { $0.symptomLogs }
        let healthScore = healthScoreService.calculateFromLogs(
            doseLogs: allDoseLogs,
            symptomLogs: allSymptomLogs,
            totalEpisodeFields: profile.episodes.count * 5,
            filledEpisodeFields: profile.episodes.filter { $0.diagnosis != nil }.count * 5,
            documentCount: profile.episodes.flatMap { $0.images }.count
        )

        let recentMoodEntries = moodTracker.getMoodHistory(days: 3)
        let recentMood = recentMoodEntries.last?.moodScore

        let lowStockMedicines: [String] = []

        let briefing = morningBriefingService.generateBriefing(
            profile: ProfileInfo(name: profile.name, age: nil),
            todayDoses: doseInfos,
            yesterdayAdherence: yesterdayAdherence,
            currentStreak: streak,
            healthScore: healthScore.total,
            recentMood: recentMood,
            lowStockMedicines: lowStockMedicines
        )

        return MorningBriefingCard(briefing: briefing)
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

                            if let generic = nextDose.medicine?.genericName {
                                Text(generic)
                                    .font(MCTypography.caption)
                                    .foregroundStyle(.white.opacity(0.7))
                            }

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
                                .contentTransition(.numericText())
                        }
                    }

                    // Take Now button (if within reminder window — within 30 min)
                    if nextDose.scheduledTime.timeIntervalSinceNow < 30 * 60 {
                        Button {
                            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                            withAnimation {
                                dataService.logDose(nextDose, status: .taken)
                            }
                            Task {
                                await liveActivityService.endActivity(doseLogId: nextDose.id)
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
                        .accessibilityLabel("Take \(nextDose.medicine?.brandName ?? "medicine") now")
                        .accessibilityHint("Double tap to mark this dose as taken")
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
                .clipShape(RoundedRectangle(cornerRadius: MCSpacing.cornerRadiusLarge, style: .continuous))
                .shadow(color: .black.opacity(0.06), radius: 16, y: 8)
                .shadow(color: MCColors.primaryTeal.opacity(0.3), radius: 12, y: 6)
                .shadow(color: .black.opacity(0.03), radius: 2, y: 1)
                .accessibilityElement(children: .combine)
                .accessibilityLabel("Next dose: \(nextDose.medicine?.brandName ?? "Medicine"), \(nextDose.medicine?.dosage ?? ""), scheduled at \(nextDose.scheduledTime.formatted(date: .omitted, time: .shortened))")
                .accessibilityHint("Shows your next upcoming medication dose")
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
        let isMilestone = StreakLevel.milestones.contains(streak)

        return VStack(spacing: 12) {
            // Prominent Streak Badge when streak >= 3
            if streak >= 3 {
                StreakBannerCard(streak: streak, level: level, isMilestone: isMilestone)
            }

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                // Left: Streak Card (enhanced)
                VStack(spacing: MCSpacing.sm) {
                    HStack {
                        StreakFlameIcon(streak: streak, level: level)
                        Spacer()
                        if streak >= 3 {
                            StreakBadgeView(streak: streak, compact: true)
                        }
                    }

                    HStack(alignment: .firstTextBaseline, spacing: 4) {
                        Text("\(streak)")
                            .font(.system(.title, design: .rounded, weight: .bold))
                            .foregroundStyle(MCColors.textPrimary)
                            .contentTransition(.numericText())
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

                    // Progress to next milestone
                    if let nextMilestone = nextMilestoneTarget(for: streak) {
                        VStack(spacing: 4) {
                            GeometryReader { geo in
                                ZStack(alignment: .leading) {
                                    Capsule()
                                        .fill(level.color.opacity(0.15))
                                        .frame(height: 4)

                                    Capsule()
                                        .fill(
                                            LinearGradient(
                                                colors: level.gradientColors,
                                                startPoint: .leading,
                                                endPoint: .trailing
                                            )
                                        )
                                        .frame(width: geo.size.width * milestoneProgress(streak: streak, target: nextMilestone), height: 4)
                                }
                            }
                            .frame(height: 4)

                            Text("\(nextMilestone - streak) to \(nextMilestone)d")
                                .font(.system(size: 10, weight: .medium))
                                .foregroundStyle(MCColors.textTertiary)
                                .frame(maxWidth: .infinity, alignment: .trailing)
                        }
                    }
                }
                .padding(MCSpacing.cardPadding)
                .background(.ultraThinMaterial)
                .clipShape(RoundedRectangle(cornerRadius: MCSpacing.cornerRadius, style: .continuous))
                .shadow(color: .black.opacity(0.06), radius: 16, y: 8)
                .shadow(color: .black.opacity(0.03), radius: 2, y: 1)
                .overlay(
                    RoundedRectangle(cornerRadius: MCSpacing.cornerRadius, style: .continuous)
                        .stroke(streak >= 3 ? level.color.opacity(0.2) : Color.clear, lineWidth: 1)
                )
                .accessibilityElement(children: .combine)
                .accessibilityLabel("\(streak) day streak, \(level.label)")
                .accessibilityHint("Your current medication adherence streak")

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
                .background(.ultraThinMaterial)
                .clipShape(RoundedRectangle(cornerRadius: MCSpacing.cornerRadius, style: .continuous))
                .shadow(color: .black.opacity(0.06), radius: 16, y: 8)
                .shadow(color: .black.opacity(0.03), radius: 2, y: 1)
                .accessibilityElement(children: .combine)
                .accessibilityLabel("Today's progress: \(taken) of \(totalDoses) doses taken, \(Int(adherence * 100)) percent")
            }
        }
    }

    // MARK: - Streak Helpers

    private func nextMilestoneTarget(for streak: Int) -> Int? {
        StreakLevel.milestones.first { $0 > streak }
    }

    private func milestoneProgress(streak: Int, target: Int) -> CGFloat {
        let previousMilestone = StreakLevel.milestones.last { $0 <= streak } ?? 0
        let range = target - previousMilestone
        guard range > 0 else { return 0 }
        return CGFloat(streak - previousMilestone) / CGFloat(range)
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
            .buttonStyle(PressableButtonStyle())
            .accessibilityLabel("Upload Prescription")
            .accessibilityHint("Double tap to scan or upload a prescription photo")

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
            .buttonStyle(PressableButtonStyle())
            .accessibilityLabel("AI Health Chat")
            .accessibilityHint("Double tap to open the AI health assistant")

            // Doctor Messages
            Button {
                showMessages = true
            } label: {
                HStack(spacing: MCSpacing.xs) {
                    ZStack {
                        Circle()
                            .fill(MCColors.info.opacity(0.1))
                            .frame(width: 36, height: 36)
                        Image(systemName: "bubble.left.and.bubble.right.fill")
                            .font(.system(size: 16))
                            .foregroundStyle(MCColors.info)
                    }

                    VStack(alignment: .leading, spacing: 2) {
                        Text("Doctor")
                            .font(MCTypography.bodyMedium)
                            .foregroundStyle(MCColors.textPrimary)
                        Text("Messages")
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
                        .stroke(MCColors.info.opacity(0.2), lineWidth: 1)
                )
            }
            .buttonStyle(PressableButtonStyle())
            .accessibilityLabel("Doctor Messages")
            .accessibilityHint("Double tap to message your doctors")
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

    // MARK: - Drug Interaction Section

    private func drugInteractionSection(profile: UserProfile) -> some View {
        let medicines = profile.episodes.flatMap { $0.activeMedicines }
        let alerts = drugInteractionService.checkInteractions(medicines: medicines)

        return DrugInteractionBanner(alerts: alerts)
    }

    // MARK: - Insights Section

    private func insightsSection(profile: UserProfile) -> some View {
        let insights = analyticsService.generateInsights(for: profile)

        return InsightsCard(insights: insights)
    }

    // MARK: - Hero Health Score

    private func healthScoreHero(profile: UserProfile) -> some View {
        let allDoseLogs = profile.episodes.flatMap { $0.medicines }.flatMap { $0.doseLogs }
        let allSymptomLogs = profile.episodes.flatMap { $0.symptomLogs }
        let healthScoreService = HealthScoreService()
        let score = healthScoreService.calculateFromLogs(
            doseLogs: allDoseLogs,
            symptomLogs: allSymptomLogs,
            totalEpisodeFields: profile.episodes.count * 5,
            filledEpisodeFields: profile.episodes.filter { $0.diagnosis != nil }.count * 5,
            documentCount: profile.episodes.flatMap { $0.images }.count
        )

        return MCGlassCard {
            VStack(spacing: MCSpacing.xs) {
                Text("Health Score")
                    .font(MCTypography.metricLabel)
                    .foregroundStyle(MCColors.textSecondary)
                    .textCase(.uppercase)
                    .kerning(1.2)

                ZStack {
                    Circle()
                        .stroke(MCColors.primaryTeal.opacity(0.15), lineWidth: 8)
                        .frame(width: 100, height: 100)

                    Circle()
                        .trim(from: 0, to: CGFloat(score.total) / 100.0)
                        .stroke(
                            LinearGradient(
                                colors: [MCColors.primaryTeal, MCColors.primaryTealDark],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            style: StrokeStyle(lineWidth: 8, lineCap: .round)
                        )
                        .frame(width: 100, height: 100)
                        .rotationEffect(.degrees(-90))

                    Text("\(score.total)")
                        .font(MCTypography.heroMetric)
                        .foregroundStyle(MCColors.textPrimary)
                        .contentTransition(.numericText())
                }

                Text("out of 100")
                    .font(MCTypography.metricLabel)
                    .foregroundStyle(MCColors.textTertiary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, MCSpacing.sm)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Health score \(score.total) out of 100")
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
                    if let generic = doseLog.medicine?.genericName {
                        Text(generic)
                            .font(MCTypography.caption)
                            .foregroundStyle(MCColors.primaryTeal)
                    }
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
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(doseLog.medicine?.brandName ?? "Medicine"), \(doseLog.medicine?.dosage ?? ""), at \(doseLog.scheduledTime.formatted(date: .omitted, time: .shortened)), \(doseLog.status.rawValue)")
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
                            .fill(
                                LinearGradient(
                                    colors: adherence > 0.7
                                        ? [MCColors.success, MCColors.primaryTeal]
                                        : [MCColors.warning, MCColors.accentCoral],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .frame(width: geo.size.width * adherence, height: 6)
                    }
                }
                .frame(height: 6)
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(episode.title), \(episode.activeMedicines.count) medicines, \(Int(episode.adherencePercentage * 100)) percent adherence")
        .accessibilityHint("Double tap to view care plan details")
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

// MARK: - Streak Banner Card (prominent display for streaks >= 3)

struct StreakBannerCard: View {
    let streak: Int
    let level: StreakLevel
    let isMilestone: Bool

    @State private var animateGlow = false

    var body: some View {
        HStack(spacing: MCSpacing.md) {
            // Badge circle with gradient
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: level.gradientColors,
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 52, height: 52)
                    .shadow(color: level.color.opacity(animateGlow ? 0.5 : 0.2), radius: animateGlow ? 12 : 6, y: 2)

                VStack(spacing: 0) {
                    Image(systemName: level.icon)
                        .font(.system(size: 18, weight: .bold))
                        .foregroundStyle(.white)

                    Text("\(streak)")
                        .font(.system(size: 13, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                }
            }

            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    Text(streakTitle)
                        .font(.system(size: 16, weight: .bold))
                        .foregroundStyle(MCColors.textPrimary)

                    if isMilestone {
                        Text("NEW")
                            .font(.system(size: 9, weight: .heavy))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(level.color)
                            .clipShape(Capsule())
                    }
                }

                Text(streakMessage)
                    .font(.system(size: 13))
                    .foregroundStyle(MCColors.textSecondary)
                    .lineLimit(2)
            }

            Spacer()
        }
        .padding(MCSpacing.cardPadding)
        .background(
            RoundedRectangle(cornerRadius: MCSpacing.cornerRadius)
                .fill(MCColors.cardBackground)
                .overlay(
                    RoundedRectangle(cornerRadius: MCSpacing.cornerRadius)
                        .stroke(
                            LinearGradient(
                                colors: level.gradientColors.map { $0.opacity(0.3) },
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1.5
                        )
                )
        )
        .shadow(color: level.color.opacity(0.1), radius: 8, y: 4)
        .onAppear {
            if streak >= 7 {
                withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
                    animateGlow = true
                }
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(streak) day streak, \(level.label) level")
    }

    private var streakTitle: String {
        switch level {
        case .none:     return "Building Momentum"
        case .bronze:   return "Bronze Streak!"
        case .silver:   return "Silver Streak!"
        case .gold:     return "Gold Streak!"
        case .diamond:  return "Diamond Streak!"
        case .platinum: return "Platinum Legend!"
        }
    }

    private var streakMessage: String {
        switch streak {
        case 3..<7:   return "3 days strong -- keep the momentum going!"
        case 7..<14:  return "A full week of perfect adherence!"
        case 14..<30: return "Two weeks and counting. You are unstoppable!"
        case 30..<100: return "A whole month! Your health thanks you."
        case 100...:  return "100+ days of dedication. Truly inspiring!"
        default:      return "Great start! Stay consistent."
        }
    }
}

// MARK: - Streak Flame Icon (grows with longer streaks)

struct StreakFlameIcon: View {
    let streak: Int
    let level: StreakLevel

    @State private var animatePulse = false

    private var flameSize: CGFloat {
        switch streak {
        case 0..<3:   return 18
        case 3..<7:   return 20
        case 7..<14:  return 22
        case 14..<30: return 24
        case 30..<100: return 26
        default:      return 28
        }
    }

    var body: some View {
        ZStack {
            // Outer glow ring for streaks >= 7
            if streak >= 7 {
                Circle()
                    .fill(level.color.opacity(0.1))
                    .frame(width: flameSize + 16, height: flameSize + 16)
                    .scaleEffect(animatePulse ? 1.15 : 1.0)
            }

            Image(systemName: level.icon)
                .font(.system(size: flameSize, weight: .semibold))
                .foregroundStyle(
                    LinearGradient(
                        colors: level.gradientColors,
                        startPoint: .bottom,
                        endPoint: .top
                    )
                )
                .scaleEffect(animatePulse ? 1.1 : 1.0)
        }
        .onAppear {
            guard streak >= 3 else { return }
            let speed: Double = streak >= 14 ? 0.8 : 1.2
            withAnimation(.easeInOut(duration: speed).repeatForever(autoreverses: true)) {
                animatePulse = true
            }
        }
    }
}

// MARK: - Pressable Button Style (scale on press)

struct PressableButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
            .animation(.easeInOut(duration: 0.15), value: configuration.isPressed)
    }
}
