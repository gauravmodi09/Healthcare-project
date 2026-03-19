import SwiftUI
import SwiftData

struct HealthJournalView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var journalService = HealthJournalService()

    // Check-in state
    @State private var selectedMood: JournalMood = .okay
    @State private var energyLevel: Double = 3
    @State private var quickNote: String = ""
    @State private var showingCheckIn = false
    @State private var justSaved = false

    // Data
    @Query(sort: \DoseLog.scheduledTime, order: .reverse) private var doseLogs: [DoseLog]
    @Query(sort: \SymptomLog.date, order: .reverse) private var symptomLogs: [SymptomLog]

    var body: some View {
        ScrollView {
            VStack(spacing: MCSpacing.sectionSpacing) {
                dailyCheckInCard
                weeklySummaryCard
                pastEntriesList
            }
            .padding(.horizontal, MCSpacing.screenPadding)
            .padding(.vertical, MCSpacing.md)
        }
        .background(MCColors.backgroundLight.ignoresSafeArea())
        .navigationTitle("Health Journal")
        .navigationBarTitleDisplayMode(.large)
    }

    // MARK: - Daily Check-In Card

    private var dailyCheckInCard: some View {
        VStack(alignment: .leading, spacing: MCSpacing.md) {
            HStack {
                Image(systemName: "heart.text.clipboard")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundStyle(MCColors.primaryTeal)
                Text("Daily Check-In")
                    .font(MCTypography.headline)
                    .foregroundStyle(MCColors.textPrimary)
                Spacer()

                if hasTodayEntry {
                    Label("Done", systemImage: "checkmark.circle.fill")
                        .font(MCTypography.caption)
                        .foregroundStyle(MCColors.success)
                }
            }

            if showingCheckIn || !hasTodayEntry {
                VStack(spacing: MCSpacing.md) {
                    // Mood picker
                    VStack(alignment: .leading, spacing: MCSpacing.xs) {
                        Text("How are you feeling?")
                            .font(MCTypography.subheadline)
                            .foregroundStyle(MCColors.textSecondary)

                        HStack(spacing: MCSpacing.sm) {
                            ForEach(JournalMood.allCases, id: \.self) { mood in
                                moodButton(mood)
                            }
                        }
                    }

                    // Energy slider
                    VStack(alignment: .leading, spacing: MCSpacing.xs) {
                        HStack {
                            Text("Energy Level")
                                .font(MCTypography.subheadline)
                                .foregroundStyle(MCColors.textSecondary)
                            Spacer()
                            Text(energyLabel)
                                .font(MCTypography.captionBold)
                                .foregroundStyle(MCColors.primaryTeal)
                        }

                        Slider(value: $energyLevel, in: 1...5, step: 1)
                            .tint(MCColors.primaryTeal)

                        HStack {
                            Text("Low")
                                .font(MCTypography.caption)
                                .foregroundStyle(MCColors.textTertiary)
                            Spacer()
                            Text("High")
                                .font(MCTypography.caption)
                                .foregroundStyle(MCColors.textTertiary)
                        }
                    }

                    // Quick note
                    VStack(alignment: .leading, spacing: MCSpacing.xs) {
                        Text("Quick Note (optional)")
                            .font(MCTypography.subheadline)
                            .foregroundStyle(MCColors.textSecondary)

                        TextField("How's your day going?", text: $quickNote, axis: .vertical)
                            .lineLimit(2...4)
                            .padding(MCSpacing.sm)
                            .background(MCColors.surface)
                            .clipShape(RoundedRectangle(cornerRadius: MCSpacing.cornerRadiusSmall))
                    }

                    // Save button
                    Button {
                        saveCheckIn()
                    } label: {
                        HStack {
                            Image(systemName: justSaved ? "checkmark" : "square.and.pencil")
                            Text(justSaved ? "Saved!" : "Save Check-In")
                        }
                        .font(MCTypography.headline)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: MCSpacing.buttonHeight)
                        .background(justSaved ? MCColors.success : MCColors.primaryTeal)
                        .clipShape(RoundedRectangle(cornerRadius: MCSpacing.cornerRadius))
                    }
                    .disabled(justSaved)
                }
                .transition(.opacity.combined(with: .move(edge: .top)))
            } else {
                // Already checked in — show option to add another
                Button {
                    withAnimation(.easeInOut(duration: 0.25)) {
                        showingCheckIn = true
                    }
                } label: {
                    HStack {
                        Image(systemName: "plus.circle.fill")
                        Text("Add Another Entry")
                    }
                    .font(MCTypography.subheadline)
                    .foregroundStyle(MCColors.primaryTeal)
                }
            }
        }
        .padding(MCSpacing.cardPadding)
        .background(MCColors.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: MCSpacing.cornerRadius))
        .shadow(color: .black.opacity(0.04), radius: 8, y: 2)
    }

    // MARK: - Weekly Summary Card

    private var weeklySummaryCard: some View {
        VStack(alignment: .leading, spacing: MCSpacing.md) {
            HStack {
                Image(systemName: "chart.bar.doc.horizontal")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundStyle(MCColors.info)
                Text("This Week")
                    .font(MCTypography.headline)
                    .foregroundStyle(MCColors.textPrimary)
                Spacer()
            }

            let summary = journalService.generateWeeklySummary(
                entries: journalService.entries,
                doseLogs: doseLogs,
                symptomLogs: symptomLogs
            )

            // Stats row
            HStack(spacing: MCSpacing.md) {
                weeklyStatPill(
                    icon: "face.smiling",
                    label: "Mood",
                    value: summary.overallMood.emoji
                )
                weeklyStatPill(
                    icon: "pill.fill",
                    label: "Adherence",
                    value: "\(Int(summary.adherenceRate * 100))%"
                )
                weeklyStatPill(
                    icon: "list.clipboard",
                    label: "Entries",
                    value: "\(journalService.entries.filter { isThisWeek($0.date) }.count)"
                )
            }

            // Top symptoms
            if !summary.topSymptoms.isEmpty {
                VStack(alignment: .leading, spacing: MCSpacing.xxs) {
                    Text("Top Symptoms")
                        .font(MCTypography.captionBold)
                        .foregroundStyle(MCColors.textSecondary)
                    ForEach(summary.topSymptoms, id: \.name) { symptom in
                        HStack(spacing: MCSpacing.xs) {
                            Circle()
                                .fill(MCColors.accentCoral)
                                .frame(width: 6, height: 6)
                            Text(symptom.name)
                                .font(MCTypography.callout)
                                .foregroundStyle(MCColors.textPrimary)
                            Spacer()
                            Text("\(symptom.count)x")
                                .font(MCTypography.captionBold)
                                .foregroundStyle(MCColors.textTertiary)
                        }
                    }
                }
            }

            // AI narrative
            if !summary.aiNarrative.isEmpty {
                VStack(alignment: .leading, spacing: MCSpacing.xs) {
                    HStack(spacing: MCSpacing.xxs) {
                        Image(systemName: "sparkles")
                            .font(.system(size: 12))
                            .foregroundStyle(MCColors.primaryTeal)
                        Text("AI Summary")
                            .font(MCTypography.captionBold)
                            .foregroundStyle(MCColors.primaryTeal)
                    }

                    Text(summary.aiNarrative)
                        .font(MCTypography.callout)
                        .foregroundStyle(MCColors.textSecondary)
                        .lineSpacing(3)
                }
                .padding(MCSpacing.sm)
                .background(MCColors.primaryTeal.opacity(0.08))
                .clipShape(RoundedRectangle(cornerRadius: MCSpacing.cornerRadiusSmall))
            }
        }
        .padding(MCSpacing.cardPadding)
        .background(MCColors.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: MCSpacing.cornerRadius))
        .shadow(color: .black.opacity(0.04), radius: 8, y: 2)
    }

    // MARK: - Past Entries List

    private var pastEntriesList: some View {
        VStack(alignment: .leading, spacing: MCSpacing.sm) {
            if !journalService.entries.isEmpty {
                HStack {
                    Text("Past Entries")
                        .font(MCTypography.headline)
                        .foregroundStyle(MCColors.textPrimary)
                    Spacer()
                    Text("\(journalService.entries.count) total")
                        .font(MCTypography.caption)
                        .foregroundStyle(MCColors.textTertiary)
                }

                ForEach(journalService.entries.prefix(20)) { entry in
                    pastEntryRow(entry)
                }
            } else {
                VStack(spacing: MCSpacing.sm) {
                    Image(systemName: "book.closed")
                        .font(.system(size: 36))
                        .foregroundStyle(MCColors.textTertiary)
                    Text("No journal entries yet")
                        .font(MCTypography.subheadline)
                        .foregroundStyle(MCColors.textSecondary)
                    Text("Complete your first daily check-in above to start tracking.")
                        .font(MCTypography.caption)
                        .foregroundStyle(MCColors.textTertiary)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, MCSpacing.xl)
            }
        }
    }

    // MARK: - Subviews

    private func moodButton(_ mood: JournalMood) -> some View {
        Button {
            withAnimation(.easeInOut(duration: 0.15)) {
                selectedMood = mood
            }
        } label: {
            VStack(spacing: MCSpacing.xxs) {
                Text(mood.emoji)
                    .font(.system(size: selectedMood == mood ? 32 : 26))
                Text(mood.label)
                    .font(MCTypography.caption)
                    .foregroundStyle(selectedMood == mood ? MCColors.primaryTeal : MCColors.textTertiary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, MCSpacing.xs)
            .background(
                selectedMood == mood
                    ? MCColors.primaryTeal.opacity(0.12)
                    : Color.clear
            )
            .clipShape(RoundedRectangle(cornerRadius: MCSpacing.cornerRadiusSmall))
            .overlay(
                RoundedRectangle(cornerRadius: MCSpacing.cornerRadiusSmall)
                    .stroke(selectedMood == mood ? MCColors.primaryTeal : Color.clear, lineWidth: 1.5)
            )
        }
        .buttonStyle(.plain)
    }

    private func weeklyStatPill(icon: String, label: String, value: String) -> some View {
        VStack(spacing: MCSpacing.xxs) {
            Image(systemName: icon)
                .font(.system(size: 14))
                .foregroundStyle(MCColors.primaryTeal)
            Text(value)
                .font(MCTypography.headline)
                .foregroundStyle(MCColors.textPrimary)
            Text(label)
                .font(MCTypography.caption)
                .foregroundStyle(MCColors.textTertiary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, MCSpacing.sm)
        .background(MCColors.surface)
        .clipShape(RoundedRectangle(cornerRadius: MCSpacing.cornerRadiusSmall))
    }

    private func pastEntryRow(_ entry: JournalEntry) -> some View {
        HStack(spacing: MCSpacing.sm) {
            Text(entry.mood.emoji)
                .font(.system(size: 28))

            VStack(alignment: .leading, spacing: MCSpacing.xxs) {
                HStack {
                    Text(entry.date, style: .date)
                        .font(MCTypography.subheadline)
                        .foregroundStyle(MCColors.textPrimary)
                    Spacer()
                    energyDots(level: entry.energyLevel)
                }

                if !entry.quickNote.isEmpty {
                    Text(entry.quickNote)
                        .font(MCTypography.callout)
                        .foregroundStyle(MCColors.textSecondary)
                        .lineLimit(2)
                }

                if let firstInsight = entry.autoInsights.first {
                    HStack(spacing: MCSpacing.xxs) {
                        Image(systemName: "sparkles")
                            .font(.system(size: 10))
                        Text(firstInsight)
                            .font(MCTypography.caption)
                    }
                    .foregroundStyle(MCColors.primaryTeal)
                    .lineLimit(1)
                }
            }
        }
        .padding(MCSpacing.sm)
        .background(MCColors.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: MCSpacing.cornerRadiusSmall))
    }

    private func energyDots(level: Int) -> some View {
        HStack(spacing: 3) {
            ForEach(1...5, id: \.self) { i in
                Circle()
                    .fill(i <= level ? MCColors.primaryTeal : MCColors.divider)
                    .frame(width: 6, height: 6)
            }
        }
    }

    // MARK: - Helpers

    private var hasTodayEntry: Bool {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        return journalService.entries.contains { calendar.startOfDay(for: $0.date) == today }
    }

    private var energyLabel: String {
        switch Int(energyLevel) {
        case 1: return "Very Low"
        case 2: return "Low"
        case 3: return "Moderate"
        case 4: return "High"
        default: return "Very High"
        }
    }

    private func isThisWeek(_ date: Date) -> Bool {
        let calendar = Calendar.current
        let weekAgo = calendar.date(byAdding: .day, value: -7, to: Date())!
        return date >= weekAgo
    }

    private func saveCheckIn() {
        _ = journalService.createDailyEntry(
            mood: selectedMood,
            energy: Int(energyLevel),
            note: quickNote,
            doseLogs: doseLogs,
            symptomLogs: symptomLogs
        )

        withAnimation(.easeInOut(duration: 0.25)) {
            justSaved = true
        }

        quickNote = ""
        selectedMood = .okay
        energyLevel = 3

        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            withAnimation {
                justSaved = false
                showingCheckIn = false
            }
        }
    }
}

#Preview {
    NavigationStack {
        HealthJournalView()
    }
    .modelContainer(for: [DoseLog.self, SymptomLog.self], inMemory: true)
}
