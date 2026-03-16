import SwiftUI
import SwiftData

struct HomeView: View {
    @Environment(AppRouter.self) private var router
    @Environment(DataService.self) private var dataService
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

                    // Two-door CTA
                    twoDoorCTA

                    // Today's medication summary
                    if let profile = activeProfile {
                        todaysMedicationSection(profile: profile)

                        // Active episodes
                        activeEpisodesSection(profile: profile)

                        // Upcoming tasks
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

    // MARK: - Two-Door CTA

    private var twoDoorCTA: some View {
        HStack(spacing: MCSpacing.sm) {
            // Door A: Consult Doctor (Phase 3)
            Button {
                // Future: teleconsultation
            } label: {
                VStack(spacing: MCSpacing.xs) {
                    ZStack {
                        Circle()
                            .fill(MCColors.primaryTeal.opacity(0.1))
                            .frame(width: 48, height: 48)
                        Image(systemName: "stethoscope")
                            .font(.system(size: 20))
                            .foregroundStyle(MCColors.primaryTeal)
                    }
                    Text("Consult\nDoctor")
                        .font(MCTypography.subheadline)
                        .foregroundStyle(MCColors.textPrimary)
                        .multilineTextAlignment(.center)
                        .lineLimit(2)
                        .fixedSize(horizontal: false, vertical: true)

                    MCBadge("Coming Soon", color: MCColors.textTertiary, style: .outlined)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, MCSpacing.md)
                .background(MCColors.cardBackground)
                .clipShape(RoundedRectangle(cornerRadius: MCSpacing.cornerRadius))
                .shadow(color: .black.opacity(0.04), radius: 8, y: 2)
            }
            .disabled(true)
            .opacity(0.7)

            // Door B: Upload Prescription
            Button {
                showUpload = true
            } label: {
                VStack(spacing: MCSpacing.xs) {
                    ZStack {
                        Circle()
                            .fill(MCColors.accentCoral.opacity(0.1))
                            .frame(width: 48, height: 48)
                        Image(systemName: "doc.text.viewfinder")
                            .font(.system(size: 20))
                            .foregroundStyle(MCColors.accentCoral)
                    }
                    Text("Upload\nPrescription")
                        .font(MCTypography.subheadline)
                        .foregroundStyle(MCColors.textPrimary)
                        .multilineTextAlignment(.center)
                        .lineLimit(2)
                        .fixedSize(horizontal: false, vertical: true)

                    MCBadge("AI Powered", color: MCColors.accentCoral, style: .soft)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, MCSpacing.md)
                .background(MCColors.cardBackground)
                .clipShape(RoundedRectangle(cornerRadius: MCSpacing.cornerRadius))
                .shadow(color: .black.opacity(0.04), radius: 8, y: 2)
                .overlay(
                    RoundedRectangle(cornerRadius: MCSpacing.cornerRadius)
                        .stroke(MCColors.accentCoral.opacity(0.3), lineWidth: 1)
                )
            }
        }
    }

    // MARK: - Today's Medication

    private func todaysMedicationSection(profile: UserProfile) -> some View {
        VStack(alignment: .leading, spacing: MCSpacing.sm) {
            HStack {
                Text("Today's Medication")
                    .font(MCTypography.headline)
                    .foregroundStyle(MCColors.textPrimary)
                Spacer()
                let doses = dataService.todaysDoses(for: profile)
                let taken = doses.filter { $0.status == .taken }.count
                Text("\(taken)/\(doses.count)")
                    .font(MCTypography.subheadline)
                    .foregroundStyle(MCColors.primaryTeal)
            }

            let upcoming = dataService.upcomingDoses(for: profile, limit: 4)
            if upcoming.isEmpty {
                MCCard {
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(MCColors.success)
                        Text("All doses for today are done!")
                            .font(MCTypography.body)
                            .foregroundStyle(MCColors.textSecondary)
                    }
                    .frame(maxWidth: .infinity)
                }
            } else {
                ForEach(upcoming) { dose in
                    DoseReminderCard(doseLog: dose)
                }
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

    private var greetingText: String {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 5..<12: return "Good morning"
        case 12..<17: return "Good afternoon"
        case 17..<21: return "Good evening"
        default: return "Good night"
        }
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
