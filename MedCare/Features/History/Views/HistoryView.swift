import SwiftUI
import SwiftData

struct HistoryView: View {
    @Query private var users: [User]
    @State private var selectedTimeRange: TimeRange = .week
    @State private var showExportSheet = false

    private var activeProfile: UserProfile? { users.first?.activeProfile }

    enum TimeRange: String, CaseIterable {
        case week = "7 Days"
        case twoWeeks = "14 Days"
        case month = "30 Days"
        case all = "All Time"

        var days: Int {
            switch self {
            case .week: return 7
            case .twoWeeks: return 14
            case .month: return 30
            case .all: return 365
            }
        }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                if let profile = activeProfile {
                    VStack(spacing: MCSpacing.lg) {
                        // Time range picker
                        Picker("Time Range", selection: $selectedTimeRange) {
                            ForEach(TimeRange.allCases, id: \.self) { range in
                                Text(range.rawValue).tag(range)
                            }
                        }
                        .pickerStyle(.segmented)
                        .padding(.horizontal, MCSpacing.screenPadding)

                        // Adherence chart
                        adherenceChart(profile: profile)

                        // Episode history
                        episodeHistory(profile: profile)

                        // Export button
                        MCSecondaryButton("Export Report as PDF", icon: "square.and.arrow.up") {
                            showExportSheet = true
                        }
                        .padding(.horizontal, MCSpacing.screenPadding)
                    }
                    .padding(.vertical, MCSpacing.md)
                } else {
                    ContentUnavailableView("No profile active", systemImage: "person.crop.circle.badge.questionmark")
                }
            }
            .background(MCColors.backgroundLight)
            .navigationTitle("History")
            .sheet(isPresented: $showExportSheet) {
                AdherenceReportView()
            }
        }
    }

    // MARK: - Adherence Chart

    private func adherenceChart(profile: UserProfile) -> some View {
        MCCard {
            VStack(alignment: .leading, spacing: MCSpacing.md) {
                Text("Adherence Trend")
                    .font(MCTypography.headline)
                    .foregroundStyle(MCColors.textPrimary)

                // Simple bar chart
                let data = adherenceData(profile: profile)
                HStack(alignment: .bottom, spacing: MCSpacing.xxs) {
                    ForEach(data, id: \.date) { item in
                        VStack(spacing: MCSpacing.xxs) {
                            RoundedRectangle(cornerRadius: 3)
                                .fill(item.percentage > 0.7 ? MCColors.success : item.percentage > 0.4 ? MCColors.warning : MCColors.error)
                                .frame(height: max(4, CGFloat(item.percentage) * 100))

                            Text(shortDate(item.date))
                                .font(.system(size: 9))
                                .foregroundStyle(MCColors.textTertiary)
                        }
                        .frame(maxWidth: .infinity)
                    }
                }
                .frame(height: 120, alignment: .bottom)
                .frame(maxWidth: .infinity)

                // Legend
                HStack(spacing: MCSpacing.md) {
                    legendItem(color: MCColors.success, label: ">70% Good")
                    legendItem(color: MCColors.warning, label: "40-70% Fair")
                    legendItem(color: MCColors.error, label: "<40% Low")
                }
            }
        }
        .padding(.horizontal, MCSpacing.screenPadding)
    }

    private func legendItem(color: Color, label: String) -> some View {
        HStack(spacing: MCSpacing.xxs) {
            Circle()
                .fill(color)
                .frame(width: 8, height: 8)
            Text(label)
                .font(MCTypography.caption)
                .foregroundStyle(MCColors.textSecondary)
        }
    }

    // MARK: - Episode History

    private func episodeHistory(profile: UserProfile) -> some View {
        VStack(alignment: .leading, spacing: MCSpacing.sm) {
            Text("Past Episodes")
                .font(MCTypography.headline)
                .padding(.horizontal, MCSpacing.screenPadding)

            let allEpisodes = profile.episodes.sorted { $0.createdAt > $1.createdAt }

            if allEpisodes.isEmpty {
                MCCard {
                    VStack(spacing: MCSpacing.sm) {
                        Image(systemName: "tray")
                            .font(.system(size: 36))
                            .foregroundStyle(MCColors.textTertiary)
                        Text("No episodes yet")
                            .font(MCTypography.body)
                            .foregroundStyle(MCColors.textSecondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, MCSpacing.lg)
                }
                .padding(.horizontal, MCSpacing.screenPadding)
            } else {
                ForEach(allEpisodes) { episode in
                    NavigationLink(value: episode.id) {
                        EpisodeHistoryCard(episode: episode)
                    }
                    .buttonStyle(.plain)
                    .padding(.horizontal, MCSpacing.screenPadding)
                }
            }
        }
    }

    // MARK: - Helpers

    struct AdherenceDay: Hashable {
        let date: Date
        let percentage: Double

        func hash(into hasher: inout Hasher) {
            hasher.combine(date)
        }
    }

    private func adherenceData(profile: UserProfile) -> [AdherenceDay] {
        let calendar = Calendar.current
        let days = min(selectedTimeRange.days, 14)

        return (0..<days).reversed().map { offset in
            let date = calendar.date(byAdding: .day, value: -offset, to: Date())!
            let startOfDay = calendar.startOfDay(for: date)
            let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!

            let doses = profile.episodes
                .flatMap { $0.medicines }
                .flatMap { $0.doseLogs }
                .filter { $0.scheduledTime >= startOfDay && $0.scheduledTime < endOfDay }

            let total = doses.count
            let taken = doses.filter { $0.status == .taken }.count
            let pct = total > 0 ? Double(taken) / Double(total) : 0

            return AdherenceDay(date: date, percentage: pct)
        }
    }

    private func shortDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "d"
        return formatter.string(from: date)
    }
}

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

// MARK: - Adherence Report

struct AdherenceReportView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            VStack(spacing: MCSpacing.lg) {
                Image(systemName: "doc.richtext")
                    .font(.system(size: 48))
                    .foregroundStyle(MCColors.primaryTeal)

                Text("Adherence Report")
                    .font(MCTypography.title)

                Text("Generate a PDF report of your medication adherence that you can share with your doctor.")
                    .font(MCTypography.body)
                    .foregroundStyle(MCColors.textSecondary)
                    .multilineTextAlignment(.center)

                MCPrimaryButton("Generate PDF", icon: "doc.badge.arrow.up") {
                    // Generate and share PDF
                    dismiss()
                }

                MCSecondaryButton("Cancel") {
                    dismiss()
                }
            }
            .padding(MCSpacing.screenPadding)
            .navigationTitle("Export Report")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}
