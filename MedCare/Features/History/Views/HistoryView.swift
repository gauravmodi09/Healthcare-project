import SwiftUI
import SwiftData

// MARK: - Health Tab (redesigned History)

struct HistoryView: View {
    @Query private var users: [User]
    @State private var selectedTab: HealthTab = .today
    @State private var showExportSheet = false
    @State private var isLoading = true

    private let healthScoreService = HealthScoreService()

    private var activeProfile: UserProfile? { users.first?.activeProfile }

    private func healthScoreFor(_ profile: UserProfile) -> HealthScore {
        let doseLogs = profile.episodes.flatMap { $0.medicines }.flatMap { $0.doseLogs }
        let symptomLogs = profile.episodes.flatMap { $0.symptomLogs }
        return healthScoreService.calculateFromLogs(
            doseLogs: doseLogs,
            symptomLogs: symptomLogs,
            totalEpisodeFields: profile.episodes.count * 5,
            filledEpisodeFields: profile.episodes.filter { $0.diagnosis != nil }.count * 5,
            documentCount: profile.episodes.flatMap { $0.images }.count
        )
    }

    enum HealthTab: String, CaseIterable {
        case today = "Today"
        case overview = "Overview"
        case calendar = "Calendar"
        case insights = "Insights"
        case journal = "Journal"
        case vitals = "Vitals"
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                if isLoading {
                    VStack(spacing: MCSpacing.md) {
                        ForEach(0..<3, id: \.self) { _ in
                            SkeletonCardView()
                        }
                    }
                    .padding(.horizontal, MCSpacing.screenPadding)
                    .padding(.top, MCSpacing.md)
                    .task {
                        try? await Task.sleep(nanoseconds: 400_000_000)
                        withAnimation(.easeOut(duration: 0.3)) {
                            isLoading = false
                        }
                    }
                } else if let profile = activeProfile {
                    VStack(spacing: MCSpacing.lg) {
                        // Segmented picker
                        Picker("Section", selection: $selectedTab) {
                            ForEach(HealthTab.allCases, id: \.self) { tab in
                                Text(tab.rawValue).tag(tab)
                            }
                        }
                        .pickerStyle(.segmented)
                        .padding(.horizontal, MCSpacing.screenPadding)

                        switch selectedTab {
                        case .today:
                            DailyTrackingView(profile: profile)
                        case .overview:
                            HealthOverviewSection(profile: profile)
                        case .calendar:
                            DoseCalendarView(profile: profile)
                                .padding(.horizontal, MCSpacing.screenPadding)
                        case .insights:
                            HealthInsightsSection(
                                profile: profile,
                                showExportSheet: $showExportSheet
                            )
                        case .journal:
                            HealthJournalView(profileId: profile.id.uuidString)
                                .padding(.horizontal, MCSpacing.screenPadding)
                        case .vitals:
                            VitalsTrackingView()
                        }
                    }
                    .padding(.vertical, MCSpacing.md)
                } else {
                    ContentUnavailableView(
                        "No profile active",
                        systemImage: "person.crop.circle.badge.questionmark"
                    )
                }
            }
            .refreshable {
                // Trigger SwiftUI to re-evaluate health data
                try? await Task.sleep(for: .milliseconds(300))
            }
            .background(MCColors.backgroundLight)
            .navigationTitle("Health")
            .sheet(isPresented: $showExportSheet) {
                if let profile = activeProfile {
                    ShareReportView(
                        profile: profile,
                        episodes: profile.episodes,
                        healthScore: healthScoreFor(profile)
                    )
                }
            }
        }
    }
}

// MARK: - Overview Section

private struct HealthOverviewSection: View {
    let profile: UserProfile

    private let healthScoreService = HealthScoreService()

    private var allDoseLogs: [DoseLog] {
        profile.episodes.flatMap { $0.medicines }.flatMap { $0.doseLogs }
    }

    private var allSymptomLogs: [SymptomLog] {
        profile.episodes.flatMap { $0.symptomLogs }
    }

    private var healthScore: HealthScore {
        healthScoreService.calculateFromLogs(
            doseLogs: allDoseLogs,
            symptomLogs: allSymptomLogs,
            totalEpisodeFields: profile.episodes.count * 5,
            filledEpisodeFields: profile.episodes.filter { $0.diagnosis != nil }.count * 5,
            documentCount: profile.episodes.flatMap { $0.images }.count
        )
    }

    var body: some View {
        VStack(spacing: MCSpacing.lg) {
            // Health Score Card
            healthScoreCard

            // Weekly Adherence Bar Chart
            weeklyAdherenceChart

            // Symptom Trend Mini Chart
            symptomTrendChart

            // Recent Activity Feed
            recentActivityFeed
        }
    }

    // MARK: - Health Score Card

    private var healthScoreCard: some View {
        MCCard {
            VStack(spacing: MCSpacing.sm) {
                HealthScoreView(score: healthScore.total)

                // Grade + Trend
                HStack(spacing: MCSpacing.md) {
                    Label {
                        Text("Grade: \(healthScore.grade.rawValue)")
                            .font(MCTypography.subheadline)
                    } icon: {
                        Image(systemName: healthScore.grade.icon)
                            .foregroundStyle(Color(hex: healthScore.grade.color))
                    }

                    Spacer()

                    Label {
                        Text(healthScore.trend.rawValue)
                            .font(MCTypography.subheadline)
                    } icon: {
                        Image(systemName: healthScore.trend.icon)
                            .foregroundStyle(Color(hex: healthScore.trend.color))
                    }
                }
                .foregroundStyle(MCColors.textSecondary)

                // Tip
                Text(healthScore.tip)
                    .font(MCTypography.caption)
                    .foregroundStyle(MCColors.textSecondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(MCSpacing.sm)
                    .background(MCColors.primaryTeal.opacity(0.08))
                    .clipShape(RoundedRectangle(cornerRadius: MCSpacing.cornerRadiusSmall))
            }
        }
        .padding(.horizontal, MCSpacing.screenPadding)
    }

    // MARK: - Weekly Adherence Chart

    private var weeklyAdherenceChart: some View {
        MCCard {
            VStack(alignment: .leading, spacing: MCSpacing.md) {
                Text("Weekly Adherence")
                    .font(MCTypography.headline)
                    .foregroundStyle(MCColors.textPrimary)

                let data = weeklyData()
                HStack(alignment: .bottom, spacing: MCSpacing.xs) {
                    ForEach(data, id: \.label) { item in
                        VStack(spacing: MCSpacing.xxs) {
                            Text("\(Int(item.percentage * 100))%")
                                .font(.system(size: 9, weight: .medium))
                                .foregroundStyle(MCColors.textTertiary)

                            RoundedRectangle(cornerRadius: 4)
                                .fill(MCColors.primaryTeal)
                                .frame(height: max(4, CGFloat(item.percentage) * 100))

                            Text(item.label)
                                .font(.system(size: 11, weight: .medium))
                                .foregroundStyle(MCColors.textSecondary)
                        }
                        .frame(maxWidth: .infinity)
                    }
                }
                .frame(height: 140, alignment: .bottom)
                .frame(maxWidth: .infinity)
            }
        }
        .padding(.horizontal, MCSpacing.screenPadding)
    }

    // MARK: - Symptom Trend Mini Chart

    private var symptomTrendChart: some View {
        let data = symptomTrendData()
        return MCCard {
            VStack(alignment: .leading, spacing: MCSpacing.md) {
                HStack {
                    Text("How You've Been Feeling")
                        .font(MCTypography.headline)
                        .foregroundStyle(MCColors.textPrimary)

                    Spacer()

                    Text("Last 7 days")
                        .font(MCTypography.caption)
                        .foregroundStyle(MCColors.textTertiary)
                }

                if data.isEmpty {
                    Text("No symptom logs yet. Log how you feel to see trends here.")
                        .font(MCTypography.caption)
                        .foregroundStyle(MCColors.textSecondary)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(.vertical, MCSpacing.md)
                } else {
                    // Simple line-like bar visualization
                    HStack(alignment: .bottom, spacing: MCSpacing.xs) {
                        ForEach(data, id: \.date) { item in
                            VStack(spacing: MCSpacing.xxs) {
                                Text(item.feeling.emoji)
                                    .font(.system(size: 18))

                                RoundedRectangle(cornerRadius: 4)
                                    .fill(feelingColor(item.feeling))
                                    .frame(height: CGFloat(item.feeling.rawValue) * 16)

                                Text(shortDayName(item.date))
                                    .font(.system(size: 10))
                                    .foregroundStyle(MCColors.textTertiary)
                            }
                            .frame(maxWidth: .infinity)
                        }
                    }
                    .frame(height: 120, alignment: .bottom)
                }
            }
        }
        .padding(.horizontal, MCSpacing.screenPadding)
    }

    // MARK: - Recent Activity Feed

    private var recentActivityFeed: some View {
        VStack(alignment: .leading, spacing: MCSpacing.sm) {
            Text("Recent Activity")
                .font(MCTypography.headline)
                .foregroundStyle(MCColors.textPrimary)
                .padding(.horizontal, MCSpacing.screenPadding)

            let activities = recentActivities()

            if activities.isEmpty {
                MCCard {
                    VStack(spacing: MCSpacing.sm) {
                        Image(systemName: "tray")
                            .font(.system(size: 32))
                            .foregroundStyle(MCColors.textTertiary)
                        Text("No recent activity")
                            .font(MCTypography.body)
                            .foregroundStyle(MCColors.textSecondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, MCSpacing.md)
                }
                .padding(.horizontal, MCSpacing.screenPadding)
            } else {
                ForEach(activities) { activity in
                    MCCard {
                        HStack(spacing: MCSpacing.sm) {
                            Image(systemName: activity.icon)
                                .font(.system(size: 14))
                                .foregroundStyle(activity.color)
                                .frame(width: 32, height: 32)
                                .background(activity.color.opacity(0.12))
                                .clipShape(RoundedRectangle(cornerRadius: 8))

                            VStack(alignment: .leading, spacing: 2) {
                                Text(activity.title)
                                    .font(MCTypography.bodyMedium)
                                    .foregroundStyle(MCColors.textPrimary)
                                Text(activity.subtitle)
                                    .font(MCTypography.caption)
                                    .foregroundStyle(MCColors.textSecondary)
                            }

                            Spacer()

                            Text(activity.date, style: .relative)
                                .font(MCTypography.caption)
                                .foregroundStyle(MCColors.textTertiary)
                        }
                    }
                    .padding(.horizontal, MCSpacing.screenPadding)
                }
            }
        }
    }

    // MARK: - Data Helpers

    private struct WeekDay: Hashable {
        let label: String
        let percentage: Double

        func hash(into hasher: inout Hasher) {
            hasher.combine(label)
        }
    }

    private func weeklyData() -> [WeekDay] {
        let calendar = Calendar.current
        let dayLabels = ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"]

        // Find the start of this week (Monday)
        var comps = calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: Date())
        comps.weekday = 2 // Monday
        let monday = calendar.date(from: comps) ?? Date()

        return (0..<7).map { offset in
            let date = calendar.date(byAdding: .day, value: offset, to: monday) ?? monday
            let startOfDay = calendar.startOfDay(for: date)
            let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay) ?? startOfDay.addingTimeInterval(86400)

            let doses = allDoseLogs.filter {
                $0.scheduledTime >= startOfDay && $0.scheduledTime < endOfDay
            }
            let total = doses.count
            let taken = doses.filter { $0.status == .taken }.count
            let pct = total > 0 ? Double(taken) / Double(total) : 0

            return WeekDay(label: dayLabels[offset], percentage: pct)
        }
    }

    private struct SymptomDay: Hashable {
        let date: Date
        let feeling: FeelingLevel

        func hash(into hasher: inout Hasher) {
            hasher.combine(date)
        }
    }

    private func symptomTrendData() -> [SymptomDay] {
        let calendar = Calendar.current
        var results: [SymptomDay] = []

        for offset in (0..<7).reversed() {
            guard let date = calendar.date(byAdding: .day, value: -offset, to: Date()) else { continue }
            let startOfDay = calendar.startOfDay(for: date)
            guard let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay) else { continue }

            let dayLogs = allSymptomLogs.filter {
                $0.date >= startOfDay && $0.date < endOfDay
            }

            if let avgRaw = dayLogs.isEmpty ? nil : dayLogs.map({ $0.overallFeeling.rawValue }).reduce(0, +) / dayLogs.count,
               let feeling = FeelingLevel(rawValue: avgRaw) {
                results.append(SymptomDay(date: date, feeling: feeling))
            }
        }

        return results
    }

    private func shortDayName(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE"
        return formatter.string(from: date)
    }

    private func feelingColor(_ feeling: FeelingLevel) -> Color {
        switch feeling {
        case .terrible: return MCColors.error
        case .bad: return MCColors.accentCoral
        case .okay: return MCColors.warning
        case .good: return MCColors.info
        case .great: return MCColors.success
        }
    }

    struct ActivityItem: Identifiable {
        let id = UUID()
        let icon: String
        let title: String
        let subtitle: String
        let date: Date
        let color: Color
    }

    private func recentActivities() -> [ActivityItem] {
        var items: [ActivityItem] = []

        // Add recent dose logs
        let recentDoses = allDoseLogs
            .sorted { $0.createdAt > $1.createdAt }
            .prefix(5)

        for dose in recentDoses {
            let medicineName = dose.medicine?.brandName ?? "Medicine"
            items.append(ActivityItem(
                icon: dose.status.icon,
                title: "\(medicineName) - \(dose.status.rawValue)",
                subtitle: dose.scheduledTime.formatted(date: .abbreviated, time: .shortened),
                date: dose.createdAt,
                color: MCColors.statusColor(dose.status)
            ))
        }

        // Add recent symptom logs
        let recentSymptoms = allSymptomLogs
            .sorted { $0.date > $1.date }
            .prefix(5)

        for log in recentSymptoms {
            let symptomNames = log.symptoms.prefix(2).map { $0.name }.joined(separator: ", ")
            let subtitle = symptomNames.isEmpty ? "Feeling: \(log.overallFeeling.label)" : symptomNames
            items.append(ActivityItem(
                icon: "heart.text.square",
                title: "Symptom Log - \(log.overallFeeling.emoji) \(log.overallFeeling.label)",
                subtitle: subtitle,
                date: log.date,
                color: feelingColor(log.overallFeeling)
            ))
        }

        // Sort combined and take top 5
        return items.sorted { $0.date > $1.date }.prefix(5).map { $0 }
    }
}

// MARK: - Insights Section

private struct HealthInsightsSection: View {
    let profile: UserProfile
    @Binding var showExportSheet: Bool

    private let correlationService = SymptomCorrelationService()
    private let predictiveInsightsService = PredictiveInsightsService()

    private var allDoseLogs: [DoseLog] {
        profile.episodes.flatMap { $0.medicines }.flatMap { $0.doseLogs }
    }

    private var allSymptomLogs: [SymptomLog] {
        profile.episodes.flatMap { $0.symptomLogs }
    }

    private var hasAnyData: Bool {
        !allDoseLogs.isEmpty || !allSymptomLogs.isEmpty
    }

    var body: some View {
        if hasAnyData {
            VStack(spacing: MCSpacing.lg) {
                // Symptom-Medicine Correlations
                correlationsCard

                // Adherence Trends
                adherenceTrendsCard

                // Best / Worst Days
                bestWorstDaysCard

                // Predictive Insights
                predictiveInsightsCard

                // Share with Doctor
                MCSecondaryButton("Share with Doctor", icon: "square.and.arrow.up") {
                    showExportSheet = true
                }
                .padding(.horizontal, MCSpacing.screenPadding)
            }
        } else {
            MCEmptyState(
                icon: "chart.bar.doc.horizontal",
                title: "No insights yet",
                message: "Start logging doses and tracking symptoms to unlock personalized health insights and trends.",
                iconColor: MCColors.info
            )
            .padding(.top, MCSpacing.xl)
        }
    }

    // MARK: - Predictive Insights

    private var predictiveInsights: [HealthInsight] {
        predictiveInsightsService.generateInsights(doseLogs: allDoseLogs, symptomLogs: allSymptomLogs)
    }

    private var predictiveInsightsCard: some View {
        let insights = predictiveInsights
        return VStack(alignment: .leading, spacing: MCSpacing.sm) {
            Text("Predictive Insights")
                .font(MCTypography.headline)
                .foregroundStyle(MCColors.textPrimary)
                .padding(.horizontal, MCSpacing.screenPadding)

            if insights.isEmpty {
                MCCard {
                    VStack(spacing: MCSpacing.sm) {
                        Image(systemName: "sparkles")
                            .font(.system(size: 32))
                            .foregroundStyle(MCColors.textTertiary)
                        Text("No predictions yet")
                            .font(MCTypography.bodyMedium)
                            .foregroundStyle(MCColors.textSecondary)
                        Text("Keep logging doses and symptoms. We'll detect patterns and predict what's ahead.")
                            .font(MCTypography.caption)
                            .foregroundStyle(MCColors.textTertiary)
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, MCSpacing.sm)
                }
                .padding(.horizontal, MCSpacing.screenPadding)
            } else {
                ForEach(insights) { insight in
                    MCAccentCard(accent: insight.color) {
                        VStack(alignment: .leading, spacing: MCSpacing.xs) {
                            HStack(spacing: MCSpacing.xs) {
                                Image(systemName: insight.icon)
                                    .foregroundStyle(insight.color)
                                Text(insight.title)
                                    .font(MCTypography.bodyMedium)
                                    .foregroundStyle(MCColors.textPrimary)

                                Spacer()

                                Text(insight.insightType.rawValue.capitalized)
                                    .font(MCTypography.caption)
                                    .foregroundStyle(insight.color)
                                    .padding(.horizontal, MCSpacing.xs)
                                    .padding(.vertical, 2)
                                    .background(insight.color.opacity(0.12))
                                    .clipShape(Capsule())
                            }

                            Text(insight.description)
                                .font(MCTypography.caption)
                                .foregroundStyle(MCColors.textSecondary)

                            // Confidence bar
                            HStack(spacing: MCSpacing.xs) {
                                Text("Confidence")
                                    .font(MCTypography.caption)
                                    .foregroundStyle(MCColors.textTertiary)

                                GeometryReader { geo in
                                    ZStack(alignment: .leading) {
                                        RoundedRectangle(cornerRadius: 2)
                                            .fill(MCColors.divider)
                                            .frame(height: 4)
                                        RoundedRectangle(cornerRadius: 2)
                                            .fill(MCColors.confidenceColor(insight.confidence))
                                            .frame(width: geo.size.width * insight.confidence, height: 4)
                                    }
                                }
                                .frame(height: 4)

                                Text("\(Int(insight.confidence * 100))%")
                                    .font(MCTypography.captionBold)
                                    .foregroundStyle(MCColors.confidenceColor(insight.confidence))
                                    .frame(width: 36, alignment: .trailing)
                            }
                        }
                    }
                    .padding(.horizontal, MCSpacing.screenPadding)
                }

                // AI disclaimer
                HStack(spacing: 3) {
                    Image(systemName: "info.circle")
                        .font(.system(size: 9))
                    Text("AI-generated \u{00B7} Not medical advice")
                        .font(.system(size: 10, weight: .regular))
                }
                .foregroundStyle(MCColors.textTertiary)
                .padding(.horizontal, MCSpacing.screenPadding)
            }
        }
    }

    // MARK: - Correlations

    private var correlationsCard: some View {
        let correlations = computeCorrelations()
        return VStack(alignment: .leading, spacing: MCSpacing.sm) {
            Text("Symptom-Medicine Insights")
                .font(MCTypography.headline)
                .foregroundStyle(MCColors.textPrimary)
                .padding(.horizontal, MCSpacing.screenPadding)

            if correlations.isEmpty {
                MCCard {
                    VStack(spacing: MCSpacing.sm) {
                        Image(systemName: "waveform.path.ecg")
                            .font(.system(size: 32))
                            .foregroundStyle(MCColors.textTertiary)
                        Text("Not enough data yet")
                            .font(MCTypography.bodyMedium)
                            .foregroundStyle(MCColors.textSecondary)
                        Text("Keep logging symptoms and taking medicines. We'll find patterns for you.")
                            .font(MCTypography.caption)
                            .foregroundStyle(MCColors.textTertiary)
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, MCSpacing.sm)
                }
                .padding(.horizontal, MCSpacing.screenPadding)
            } else {
                ForEach(correlations) { corr in
                    MCAccentCard(accent: Color(hex: corr.type.color)) {
                        VStack(alignment: .leading, spacing: MCSpacing.xs) {
                            HStack(spacing: MCSpacing.xs) {
                                Image(systemName: corr.type.icon)
                                    .foregroundStyle(Color(hex: corr.type.color))
                                Text(corr.description)
                                    .font(MCTypography.bodyMedium)
                                    .foregroundStyle(MCColors.textPrimary)
                            }

                            Text(corr.insight)
                                .font(MCTypography.caption)
                                .foregroundStyle(MCColors.textSecondary)

                            // Confidence bar
                            HStack(spacing: MCSpacing.xs) {
                                Text("Confidence")
                                    .font(MCTypography.caption)
                                    .foregroundStyle(MCColors.textTertiary)

                                GeometryReader { geo in
                                    ZStack(alignment: .leading) {
                                        RoundedRectangle(cornerRadius: 2)
                                            .fill(MCColors.divider)
                                            .frame(height: 4)
                                        RoundedRectangle(cornerRadius: 2)
                                            .fill(MCColors.confidenceColor(corr.confidence))
                                            .frame(width: geo.size.width * corr.confidence, height: 4)
                                    }
                                }
                                .frame(height: 4)

                                Text("\(Int(corr.confidence * 100))%")
                                    .font(MCTypography.captionBold)
                                    .foregroundStyle(MCColors.confidenceColor(corr.confidence))
                                    .frame(width: 36, alignment: .trailing)
                            }

                            Text(corr.recommendation)
                                .font(MCTypography.caption)
                                .foregroundStyle(MCColors.primaryTeal)
                                .padding(MCSpacing.xs)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .background(MCColors.primaryTeal.opacity(0.06))
                                .clipShape(RoundedRectangle(cornerRadius: MCSpacing.cornerRadiusSmall))
                        }
                    }
                    .padding(.horizontal, MCSpacing.screenPadding)
                }
            }
        }
    }

    // MARK: - Adherence Trends

    private var adherenceTrendsCard: some View {
        let (thisWeek, lastWeek) = weeklyAdherenceComparison()
        let diff = thisWeek - lastWeek
        let trendIcon = diff > 0 ? "arrow.up.right" : diff < 0 ? "arrow.down.right" : "arrow.right"
        let trendColor = diff > 0 ? MCColors.success : diff < 0 ? MCColors.error : MCColors.warning

        return MCCard {
            VStack(alignment: .leading, spacing: MCSpacing.md) {
                Text("Adherence Trends")
                    .font(MCTypography.headline)
                    .foregroundStyle(MCColors.textPrimary)

                HStack(spacing: MCSpacing.lg) {
                    // This week
                    VStack(spacing: MCSpacing.xxs) {
                        Text("This Week")
                            .font(MCTypography.caption)
                            .foregroundStyle(MCColors.textTertiary)
                        ActivityRingView(
                            progress: thisWeek,
                            size: 64,
                            lineWidth: 8,
                            color: MCColors.primaryTeal
                        )
                    }

                    // Arrow
                    VStack(spacing: MCSpacing.xxs) {
                        Image(systemName: trendIcon)
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundStyle(trendColor)

                        let diffPct = Int(abs(diff) * 100)
                        Text(diff >= 0 ? "+\(diffPct)%" : "-\(diffPct)%")
                            .font(MCTypography.captionBold)
                            .foregroundStyle(trendColor)
                    }

                    // Last week
                    VStack(spacing: MCSpacing.xxs) {
                        Text("Last Week")
                            .font(MCTypography.caption)
                            .foregroundStyle(MCColors.textTertiary)
                        ActivityRingView(
                            progress: lastWeek,
                            size: 64,
                            lineWidth: 8,
                            color: MCColors.textTertiary
                        )
                    }
                }
                .frame(maxWidth: .infinity)
            }
        }
        .padding(.horizontal, MCSpacing.screenPadding)
    }

    // MARK: - Best / Worst Days

    private var bestWorstDaysCard: some View {
        let dayStats = dayOfWeekAdherence()
        let best = dayStats.max(by: { $0.value < $1.value })
        let worst = dayStats.filter { $0.value > 0 }.min(by: { $0.value < $1.value })

        return MCCard {
            VStack(alignment: .leading, spacing: MCSpacing.md) {
                Text("Day of Week Analysis")
                    .font(MCTypography.headline)
                    .foregroundStyle(MCColors.textPrimary)

                if dayStats.isEmpty || dayStats.allSatisfy({ $0.value == 0 }) {
                    Text("Take medicines for a few days to see which days work best for you.")
                        .font(MCTypography.caption)
                        .foregroundStyle(MCColors.textSecondary)
                } else {
                    HStack(spacing: MCSpacing.md) {
                        if let best {
                            dayStatView(
                                label: "Best Day",
                                day: best.key,
                                pct: best.value,
                                color: MCColors.success,
                                icon: "hand.thumbsup.fill"
                            )
                        }

                        if let worst, worst.key != best?.key {
                            dayStatView(
                                label: "Needs Work",
                                day: worst.key,
                                pct: worst.value,
                                color: MCColors.accentCoral,
                                icon: "exclamationmark.triangle.fill"
                            )
                        }
                    }
                    .frame(maxWidth: .infinity)

                    // All days mini bar chart
                    HStack(alignment: .bottom, spacing: MCSpacing.xxs) {
                        let orderedDays = ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"]
                        ForEach(orderedDays, id: \.self) { day in
                            let pct = dayStats[day, default: 0]
                            VStack(spacing: 2) {
                                RoundedRectangle(cornerRadius: 3)
                                    .fill(pct >= 0.8 ? MCColors.success : pct >= 0.5 ? MCColors.warning : MCColors.error)
                                    .frame(height: max(4, CGFloat(pct) * 50))
                                Text(String(day.prefix(1)))
                                    .font(.system(size: 10))
                                    .foregroundStyle(MCColors.textTertiary)
                            }
                            .frame(maxWidth: .infinity)
                        }
                    }
                    .frame(height: 70, alignment: .bottom)
                }
            }
        }
        .padding(.horizontal, MCSpacing.screenPadding)
    }

    private func dayStatView(label: String, day: String, pct: Double, color: Color, icon: String) -> some View {
        VStack(spacing: MCSpacing.xs) {
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundStyle(color)

            Text(label)
                .font(MCTypography.captionBold)
                .foregroundStyle(MCColors.textSecondary)

            Text(day)
                .font(MCTypography.headline)
                .foregroundStyle(MCColors.textPrimary)

            Text("\(Int(pct * 100))%")
                .font(MCTypography.subheadline)
                .foregroundStyle(color)
        }
        .frame(maxWidth: .infinity)
        .padding(MCSpacing.sm)
        .background(color.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: MCSpacing.cornerRadiusSmall))
    }

    // MARK: - Computation Helpers

    private func computeCorrelations() -> [SymptomCorrelationService.Correlation] {
        let doseLogData = profile.episodes.flatMap { ep in
            ep.medicines.flatMap { med in
                med.doseLogs.map {
                    SymptomCorrelationService.convertDoseLog($0, medicineId: med.id, medicineName: med.brandName)
                }
            }
        }

        let symptomLogData = allSymptomLogs.map {
            SymptomCorrelationService.convertSymptomLog($0)
        }

        let medicineData = profile.episodes.flatMap { $0.medicines }.map { med in
            MedicineData(
                id: med.id,
                brandName: med.brandName,
                mealTiming: med.mealTiming.rawValue,
                startDate: med.startDate
            )
        }

        return correlationService.analyzeCorrelations(
            doseLogs: doseLogData,
            symptomLogs: symptomLogData,
            medicines: medicineData
        )
    }

    private func weeklyAdherenceComparison() -> (thisWeek: Double, lastWeek: Double) {
        let calendar = Calendar.current
        let now = Date()

        func adherenceForWeek(startingDaysAgo: Int) -> Double {
            guard let start = calendar.date(byAdding: .day, value: -startingDaysAgo, to: calendar.startOfDay(for: now)),
                  let end = calendar.date(byAdding: .day, value: 7, to: start) else { return 0 }

            let doses = allDoseLogs.filter {
                $0.scheduledTime >= start && $0.scheduledTime < end
            }
            guard !doses.isEmpty else { return 0 }
            let taken = doses.filter { $0.status == .taken }.count
            return Double(taken) / Double(doses.count)
        }

        return (adherenceForWeek(startingDaysAgo: 6), adherenceForWeek(startingDaysAgo: 13))
    }

    private func dayOfWeekAdherence() -> [String: Double] {
        let calendar = Calendar.current
        let dayNames = ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"]
        var totals: [String: Int] = [:]
        var takens: [String: Int] = [:]

        for dose in allDoseLogs {
            let weekday = calendar.component(.weekday, from: dose.scheduledTime)
            let name = dayNames[weekday - 1]
            totals[name, default: 0] += 1
            if dose.status == .taken {
                takens[name, default: 0] += 1
            }
        }

        var result: [String: Double] = [:]
        for (day, total) in totals where total > 0 {
            result[day] = Double(takens[day, default: 0]) / Double(total)
        }
        return result
    }
}

// MARK: - Episode History Card (preserved)

struct EpisodeHistoryCard: View {
    let episode: Episode

    var body: some View {
        MCCard {
            HStack {
                VStack(alignment: .leading, spacing: MCSpacing.xxs) {
                    HStack(spacing: MCSpacing.xs) {
                        Image(systemName: episode.episodeType.icon)
                            .foregroundStyle(Color(hex: episode.episodeType.color))
                        Text(episode.title)
                            .font(MCTypography.bodyMedium)
                            .foregroundStyle(MCColors.textPrimary)
                            .lineLimit(2)
                            .minimumScaleFactor(0.85)
                    }

                    HStack(spacing: MCSpacing.sm) {
                        MCBadge(episode.status.displayName, color: episode.status == .active ? MCColors.success : MCColors.textTertiary)

                        Text(episode.createdAt, style: .date)
                            .font(MCTypography.caption)
                            .foregroundStyle(MCColors.textSecondary)
                    }

                    HStack(spacing: MCSpacing.sm) {
                        Label("\(episode.medicines.count) medicines", systemImage: "pills")
                        Label("\(Int(episode.adherencePercentage * 100))% adherence", systemImage: "chart.bar")
                    }
                    .font(MCTypography.caption)
                    .foregroundStyle(MCColors.textSecondary)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .foregroundStyle(MCColors.textTertiary)
            }
        }
    }
}

