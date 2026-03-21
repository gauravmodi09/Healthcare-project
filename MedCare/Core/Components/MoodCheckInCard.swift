import SwiftUI

struct MoodCheckInCard: View {
    @State private var selectedMood: Int = 0
    @State private var energyLevel: Int = 3
    @State private var showEnergySlider = false
    @State private var isLogged = false
    @State private var animatePulse = false

    var medicines: [String] = []
    var profileId: String? = nil
    var onLog: ((Int, Int) -> Void)?

    private var moodTracker: MoodTrackingService {
        MoodTrackingService(profileId: profileId)
    }
    private let moods: [(emoji: String, label: String)] = [
        ("\u{1F62B}", "Terrible"),
        ("\u{1F61E}", "Bad"),
        ("\u{1F610}", "Okay"),
        ("\u{1F60A}", "Good"),
        ("\u{1F604}", "Great")
    ]

    var body: some View {
        VStack(spacing: 12) {
            // Header
            HStack {
                Image(systemName: "heart.text.clipboard")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(MCColors.primaryTeal)
                Text("How are you feeling?")
                    .font(MCTypography.headline)
                    .foregroundStyle(MCColors.textPrimary)
                Spacer()

                let streak = moodTracker.getCurrentStreak()
                if streak > 0 {
                    HStack(spacing: 3) {
                        Text("\u{1F525}")
                            .font(.caption)
                        Text("\(streak)d")
                            .font(MCTypography.captionBold)
                            .foregroundStyle(MCColors.accentCoral)
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(MCColors.accentCoral.opacity(0.12))
                    .clipShape(Capsule())
                }
            }

            // Mood selection row
            HStack(spacing: 0) {
                ForEach(1...5, id: \.self) { score in
                    let index = score - 1
                    Button {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                            selectedMood = score
                            isLogged = false
                        }
                    } label: {
                        VStack(spacing: 4) {
                            Text(moods[index].emoji)
                                .font(.system(size: selectedMood == score ? 32 : 26))
                                .scaleEffect(selectedMood == score ? 1.15 : 1.0)

                            Text(moods[index].label)
                                .font(MCTypography.caption)
                                .foregroundStyle(
                                    selectedMood == score
                                        ? MCColors.primaryTeal
                                        : MCColors.textTertiary
                                )
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                        .background(
                            selectedMood == score
                                ? MCColors.primaryTeal.opacity(0.1)
                                : Color.clear
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                    }
                    .buttonStyle(.plain)
                }
            }

            // Energy slider (expandable)
            if selectedMood > 0 {
                VStack(spacing: 6) {
                    Button {
                        withAnimation(.easeInOut(duration: 0.25)) {
                            showEnergySlider.toggle()
                        }
                    } label: {
                        HStack(spacing: 4) {
                            Text("Energy level")
                                .font(MCTypography.subheadline)
                                .foregroundStyle(MCColors.textSecondary)
                            Image(systemName: showEnergySlider ? "chevron.up" : "chevron.down")
                                .font(.caption2)
                                .foregroundStyle(MCColors.textTertiary)
                        }
                    }
                    .buttonStyle(.plain)

                    if showEnergySlider {
                        HStack(spacing: 8) {
                            ForEach(1...5, id: \.self) { level in
                                Button {
                                    withAnimation(.spring(response: 0.25)) {
                                        energyLevel = level
                                    }
                                } label: {
                                    Image(systemName: level <= energyLevel ? "bolt.fill" : "bolt")
                                        .font(.system(size: 18))
                                        .foregroundStyle(
                                            level <= energyLevel
                                                ? MCColors.warning
                                                : MCColors.textTertiary
                                        )
                                }
                                .buttonStyle(.plain)
                            }
                            Spacer()
                        }
                        .transition(.opacity.combined(with: .move(edge: .top)))
                    }
                }
            }

            // Log button
            if selectedMood > 0 {
                Button {
                    logMood()
                } label: {
                    HStack(spacing: 6) {
                        if isLogged {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 15, weight: .semibold))
                            Text("Logged!")
                        } else {
                            Image(systemName: "plus.circle.fill")
                                .font(.system(size: 15, weight: .semibold))
                            Text("Log Mood")
                        }
                    }
                    .font(MCTypography.subheadline)
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(
                        isLogged
                            ? MCColors.success
                            : MCColors.primaryTeal
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                }
                .buttonStyle(.plain)
                .disabled(isLogged)
                .transition(.opacity.combined(with: .move(edge: .bottom)))
            }
        }
        .padding(16)
        .background(MCColors.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.06), radius: 8, x: 0, y: 2)
    }

    private func logMood() {
        moodTracker.logMood(
            mood: selectedMood,
            energy: energyLevel,
            anxiety: 3, // default neutral
            sleep: 3,   // default neutral
            medicines: medicines
        )
        withAnimation(.spring(response: 0.3)) {
            isLogged = true
        }
        onLog?(selectedMood, energyLevel)
    }
}

#Preview {
    MoodCheckInCard(medicines: ["Metformin", "Atorvastatin"])
        .padding()
        .background(MCColors.backgroundLight)
}
