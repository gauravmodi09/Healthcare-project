import Foundation
import SwiftUI
import SwiftData

/// Smart Nudge Service — Monitors adherence patterns and triggers behavioral interventions
@Observable
final class SmartNudgeService {
    var activeNudges: [Nudge] = []

    // MARK: - Nudge Evaluation

    /// Evaluates all trigger conditions and creates appropriate nudges
    func evaluateNudges(
        profile: UserProfile,
        modelContext: ModelContext
    ) {
        let episodes = profile.episodes.filter { $0.status == .active }

        for episode in episodes {
            checkMissedDoses(episode: episode, modelContext: modelContext)
            checkCourseEnding(episode: episode, modelContext: modelContext)
            checkAdherenceDrop(episode: episode, modelContext: modelContext)
            checkNoSymptomLog(episode: episode, modelContext: modelContext)
        }

        // Refresh active nudges
        loadActiveNudges(modelContext: modelContext)
    }

    // MARK: - Trigger Checks

    /// Trigger: 2+ consecutive missed doses
    private func checkMissedDoses(episode: Episode, modelContext: ModelContext) {
        let allLogs = episode.medicines.flatMap { $0.doseLogs }
        let recentLogs = allLogs
            .filter { $0.scheduledTime < Date() }
            .sorted { $0.scheduledTime > $1.scheduledTime }
            .prefix(5)

        let consecutiveMissed = recentLogs.prefix(while: {
            $0.status == .missed || $0.status == .skipped
        }).count

        if consecutiveMissed >= 2 {
            guard !hasRecentNudge(type: .missedDose, episodeId: episode.id, modelContext: modelContext) else { return }

            let medicineName = episode.activeMedicines.first?.brandName ?? "your medicine"
            let nudge = Nudge(
                type: .missedDose,
                title: "Missed Doses",
                body: "You've missed your last \(consecutiveMissed) doses of \(medicineName). Your body needs consistent doses for the treatment to work. Can we help?",
                episodeId: episode.id
            )
            modelContext.insert(nudge)
            try? modelContext.save()
        }
    }

    /// Trigger: Course ends within 2 days
    private func checkCourseEnding(episode: Episode, modelContext: ModelContext) {
        guard let daysRemaining = episode.daysRemaining, daysRemaining > 0, daysRemaining <= 2 else { return }
        guard !hasRecentNudge(type: .courseEnding, episodeId: episode.id, modelContext: modelContext) else { return }

        let nudge = Nudge(
            type: .courseEnding,
            title: "Almost Done! 🏁",
            body: "Only \(daysRemaining) day\(daysRemaining == 1 ? "" : "s") left in your \(episode.title) treatment! Finishing the full course prevents the infection from coming back stronger.",
            episodeId: episode.id
        )
        modelContext.insert(nudge)
        try? modelContext.save()
    }

    /// Trigger: Adherence drops below 70%
    private func checkAdherenceDrop(episode: Episode, modelContext: ModelContext) {
        let adherence = episode.adherencePercentage
        guard adherence > 0 && adherence < 0.70 else { return }
        guard !hasRecentNudge(type: .adherenceDrop, episodeId: episode.id, modelContext: modelContext) else { return }

        let pct = Int(adherence * 100)
        let nudge = Nudge(
            type: .adherenceDrop,
            title: "Let's Get Back on Track",
            body: "Your adherence for \(episode.title) is at \(pct)%. Taking medicines regularly is the most important factor in your recovery. You've got this! 💪",
            episodeId: episode.id
        )
        modelContext.insert(nudge)
        try? modelContext.save()
    }

    /// Trigger: No symptom log for 3+ days
    private func checkNoSymptomLog(episode: Episode, modelContext: ModelContext) {
        let lastLog = episode.symptomLogs
            .sorted { $0.date > $1.date }
            .first

        let daysSinceLastLog: Int
        if let lastDate = lastLog?.date {
            daysSinceLastLog = Calendar.current.dateComponents([.day], from: lastDate, to: Date()).day ?? 0
        } else {
            daysSinceLastLog = Calendar.current.dateComponents([.day], from: episode.startDate, to: Date()).day ?? 0
        }

        guard daysSinceLastLog >= 3 else { return }
        guard !hasRecentNudge(type: .noSymptomLog, episodeId: episode.id, modelContext: modelContext) else { return }

        let nudge = Nudge(
            type: .noSymptomLog,
            title: "How Are You Feeling?",
            body: "It's been \(daysSinceLastLog) days since your last symptom log. A quick check-in helps track your recovery and gives your doctor better data.",
            episodeId: episode.id
        )
        modelContext.insert(nudge)
        try? modelContext.save()
    }

    // MARK: - Nudge Management

    private func hasRecentNudge(type: NudgeType, episodeId: UUID, modelContext: ModelContext) -> Bool {
        let typeRaw = type.rawValue
        let descriptor = FetchDescriptor<Nudge>(
            predicate: #Predicate<Nudge> { nudge in
                nudge.type.rawValue == typeRaw
            }
        )
        let matches = (try? modelContext.fetch(descriptor)) ?? []
        return matches.contains { nudge in
            nudge.episodeId == episodeId &&
            Calendar.current.dateComponents([.hour], from: nudge.createdAt, to: Date()).hour ?? 0 < 24
        }
    }

    func loadActiveNudges(modelContext: ModelContext) {
        let descriptor = FetchDescriptor<Nudge>(
            sortBy: [SortDescriptor(\.triggerDate, order: .reverse)]
        )
        if let all = try? modelContext.fetch(descriptor) {
            activeNudges = all.filter { $0.isActive }
        }
    }

    func dismissNudge(_ nudge: Nudge) {
        nudge.dismissed = true
    }

    func markActedOn(_ nudge: Nudge) {
        nudge.actedOn = true
    }
}
