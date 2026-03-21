import SwiftUI

struct AchievementsView: View {
    @Environment(\.dismiss) private var dismiss

    private let service = AchievementService.shared
    private let goldColor = Color(hex: "FFD700")

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: MCSpacing.sectionSpacing) {
                    // Summary header
                    summaryCard

                    // Grouped by category
                    ForEach(AchievementService.AchievementCategory.allCases, id: \.self) { category in
                        let achievements = service.achievements(for: category)
                        if !achievements.isEmpty {
                            categorySection(category, achievements: achievements)
                        }
                    }
                }
                .padding(.vertical, MCSpacing.md)
            }
            .background(MCColors.backgroundLight)
            .navigationTitle("Achievements")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                        .foregroundStyle(MCColors.primaryTeal)
                }
            }
        }
    }

    // MARK: - Summary Card

    private var summaryCard: some View {
        MCCard {
            VStack(spacing: MCSpacing.sm) {
                ZStack {
                    Circle()
                        .stroke(MCColors.divider, lineWidth: 6)
                        .frame(width: 80, height: 80)

                    Circle()
                        .trim(from: 0, to: service.completionPercentage)
                        .stroke(
                            LinearGradient(
                                colors: [MCColors.primaryTeal, goldColor],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            style: StrokeStyle(lineWidth: 6, lineCap: .round)
                        )
                        .frame(width: 80, height: 80)
                        .rotationEffect(.degrees(-90))

                    VStack(spacing: 0) {
                        Text("\(service.totalUnlocked)")
                            .font(MCTypography.title)
                            .foregroundStyle(MCColors.textPrimary)
                        Text("of \(service.totalAvailable)")
                            .font(MCTypography.caption)
                            .foregroundStyle(MCColors.textSecondary)
                    }
                }

                Text("Achievements Unlocked")
                    .font(MCTypography.headline)
                    .foregroundStyle(MCColors.textPrimary)

                Text("\(Int(service.completionPercentage * 100))% complete")
                    .font(MCTypography.subheadline)
                    .foregroundStyle(MCColors.textSecondary)
            }
            .frame(maxWidth: .infinity)
        }
        .padding(.horizontal, MCSpacing.screenPadding)
    }

    // MARK: - Category Section

    private func categorySection(_ category: AchievementService.AchievementCategory, achievements: [AchievementService.Achievement]) -> some View {
        VStack(alignment: .leading, spacing: MCSpacing.sm) {
            // Section header
            HStack(spacing: MCSpacing.xs) {
                Image(systemName: category.icon)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(Color(hex: category.color))

                Text(category.rawValue)
                    .font(MCTypography.sectionHeader)
                    .foregroundStyle(MCColors.textPrimary)
                    .textCase(.uppercase)
                    .kerning(1.2)

                Spacer()

                let unlocked = achievements.filter(\.isUnlocked).count
                Text("\(unlocked)/\(achievements.count)")
                    .font(MCTypography.captionBold)
                    .foregroundStyle(MCColors.textSecondary)
            }
            .padding(.horizontal, MCSpacing.screenPadding)

            // Achievement cards
            VStack(spacing: 0) {
                ForEach(Array(achievements.enumerated()), id: \.element.id) { index, achievement in
                    achievementRow(achievement, categoryColor: Color(hex: category.color))

                    if index < achievements.count - 1 {
                        Divider().padding(.leading, 60)
                    }
                }
            }
            .background(MCColors.cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: MCSpacing.cornerRadius))
            .shadow(color: .black.opacity(0.06), radius: 8, y: 2)
            .padding(.horizontal, MCSpacing.screenPadding)
        }
    }

    // MARK: - Achievement Row

    private func achievementRow(_ achievement: AchievementService.Achievement, categoryColor: Color) -> some View {
        HStack(spacing: MCSpacing.sm) {
            // Icon
            ZStack {
                if achievement.isUnlocked {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [goldColor.opacity(0.3), goldColor.opacity(0.1)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 44, height: 44)
                        .shadow(color: goldColor.opacity(0.4), radius: 6, y: 0)
                } else {
                    Circle()
                        .fill(MCColors.backgroundLight)
                        .frame(width: 44, height: 44)
                }

                Image(systemName: achievement.icon)
                    .font(.system(size: 18, weight: .medium))
                    .foregroundStyle(
                        achievement.isUnlocked ? goldColor : MCColors.textTertiary
                    )
            }

            // Text content
            VStack(alignment: .leading, spacing: MCSpacing.xxs) {
                Text(achievement.name)
                    .font(MCTypography.bodyMedium)
                    .foregroundStyle(
                        achievement.isUnlocked ? MCColors.textPrimary : MCColors.textSecondary
                    )

                Text(achievement.description)
                    .font(MCTypography.caption)
                    .foregroundStyle(MCColors.textTertiary)
                    .lineLimit(2)

                if achievement.isUnlocked {
                    if let date = achievement.unlockedDate {
                        Text("Unlocked \(date.formatted(.dateTime.month(.abbreviated).day().year()))")
                            .font(.system(size: 10, weight: .medium))
                            .foregroundStyle(goldColor)
                    }
                } else if achievement.progress > 0 {
                    // Progress bar
                    HStack(spacing: MCSpacing.xs) {
                        GeometryReader { geo in
                            ZStack(alignment: .leading) {
                                Capsule()
                                    .fill(MCColors.divider)
                                    .frame(height: 4)

                                Capsule()
                                    .fill(categoryColor)
                                    .frame(width: geo.size.width * achievement.progress, height: 4)
                            }
                        }
                        .frame(height: 4)

                        Text("\(Int(achievement.progress * 100))%")
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundStyle(categoryColor)
                            .frame(width: 32, alignment: .trailing)
                    }
                    .padding(.top, MCSpacing.xxs)
                }
            }

            Spacer()

            // Unlocked checkmark
            if achievement.isUnlocked {
                Image(systemName: "checkmark.seal.fill")
                    .font(.system(size: 20))
                    .foregroundStyle(MCColors.primaryTeal)
            }
        }
        .padding(.horizontal, MCSpacing.cardPadding)
        .padding(.vertical, MCSpacing.sm)
        .opacity(achievement.isUnlocked ? 1.0 : 0.7)
    }
}
