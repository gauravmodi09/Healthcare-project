import SwiftUI

struct MorningBriefingCard: View {
    let briefing: MorningBriefing
    var onViewFull: (() -> Void)?

    @State private var isExpanded = false

    var body: some View {
        VStack(spacing: 0) {
            // Gradient header with greeting
            VStack(alignment: .leading, spacing: 6) {
                Text(briefing.greeting)
                    .font(MCTypography.title2)
                    .foregroundStyle(.white)

                Text(briefing.healthScoreLine)
                    .font(MCTypography.subheadline)
                    .foregroundStyle(.white.opacity(0.9))
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(16)
            .background(MCColors.primaryGradient)

            // Body
            VStack(alignment: .leading, spacing: 14) {
                // Today's plan
                VStack(alignment: .leading, spacing: 6) {
                    Label {
                        Text("Today's Plan")
                            .font(MCTypography.headline)
                            .foregroundStyle(MCColors.textPrimary)
                    } icon: {
                        Image(systemName: "calendar.badge.clock")
                            .foregroundStyle(MCColors.primaryTeal)
                    }

                    ForEach(briefing.todayPlan, id: \.self) { item in
                        HStack(alignment: .top, spacing: 6) {
                            Text("\u{2022}")
                                .foregroundStyle(MCColors.primaryTeal)
                            Text(item)
                                .font(MCTypography.callout)
                                .foregroundStyle(MCColors.textSecondary)
                        }
                    }
                }

                Divider()
                    .background(MCColors.divider)

                // Streak badge
                HStack(spacing: 8) {
                    Text(briefing.streakInfo)
                        .font(MCTypography.subheadline)
                        .foregroundStyle(MCColors.textPrimary)
                }

                // Alerts
                if !briefing.alertLines.isEmpty {
                    Divider()
                        .background(MCColors.divider)

                    VStack(alignment: .leading, spacing: 6) {
                        ForEach(briefing.alertLines, id: \.self) { alert in
                            Text(alert)
                                .font(MCTypography.callout)
                                .foregroundStyle(MCColors.textPrimary)
                        }
                    }
                }

                // Expanded content
                if isExpanded {
                    Divider()
                        .background(MCColors.divider)

                    // Motivational quote
                    Text("\"\(briefing.motivationalQuote)\"")
                        .font(MCTypography.callout.italic())
                        .foregroundStyle(MCColors.textSecondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(12)
                        .background(MCColors.surface)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                }

                // Expand / collapse button
                Button {
                    withAnimation(.easeInOut(duration: 0.25)) {
                        isExpanded.toggle()
                    }
                    if isExpanded {
                        onViewFull?()
                    }
                } label: {
                    HStack(spacing: 4) {
                        Text(isExpanded ? "Show Less" : "View Full Briefing")
                            .font(MCTypography.subheadline)
                        Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                            .font(.caption2.weight(.semibold))
                    }
                    .foregroundStyle(MCColors.primaryTeal)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                    .background(MCColors.primaryTeal.opacity(0.08))
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                }
                .buttonStyle(.plain)

                // AI disclaimer
                HStack(spacing: 3) {
                    Image(systemName: "info.circle")
                        .font(.system(size: 9))
                    Text("AI-generated \u{00B7} Not medical advice")
                        .font(.system(size: 10, weight: .regular))
                }
                .foregroundStyle(MCColors.textTertiary)
            }
            .padding(16)
        }
        .background(MCColors.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.06), radius: 8, x: 0, y: 2)
    }
}

#Preview {
    let briefing = MorningBriefing(
        greeting: "Good morning, Ravi! \u{1F305}",
        healthScoreLine: "Health Score: 85 (A) \u{2014} You're doing great!",
        todayPlan: [
            "3 doses scheduled today",
            "Metformin at 8 AM, Atorvastatin at 9 PM",
            "Next up: Metformin at 8:00 AM"
        ],
        streakInfo: "\u{1F525} Day 12 streak! Keep it up!",
        alertLines: [
            "\u{26A0}\u{FE0F} Crocin running low \u{2014} consider refilling soon",
            "\u{1F534} Critical medicine today: Warfarin"
        ],
        motivationalQuote: "The greatest wealth is health. \u{2014} Virgil",
        formattedText: ""
    )

    MorningBriefingCard(briefing: briefing)
        .padding()
        .background(MCColors.backgroundLight)
}
