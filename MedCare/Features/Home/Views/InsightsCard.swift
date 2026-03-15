import SwiftUI

/// Enhancement #7: Insights Dashboard Card
/// Shows AI-generated adherence insights on the home screen
struct InsightsCard: View {
    let insights: [AnalyticsService.AdherenceInsight]
    @State private var currentIndex = 0

    var body: some View {
        if !insights.isEmpty {
            VStack(alignment: .leading, spacing: MCSpacing.sm) {
                HStack {
                    Image(systemName: "sparkles")
                        .foregroundStyle(MCColors.primaryTeal)
                    Text("Smart Insights")
                        .font(MCTypography.headline)
                        .foregroundStyle(MCColors.textPrimary)
                    Spacer()
                    Text("\(currentIndex + 1)/\(insights.count)")
                        .font(MCTypography.caption)
                        .foregroundStyle(MCColors.textTertiary)
                }

                let insight = insights[currentIndex]

                MCCard {
                    VStack(alignment: .leading, spacing: MCSpacing.xs) {
                        HStack(spacing: MCSpacing.xs) {
                            Image(systemName: insight.type.icon)
                                .font(.system(size: 18))
                                .foregroundStyle(Color(hex: insight.type.color))
                                .frame(width: 32, height: 32)
                                .background(Color(hex: insight.type.color).opacity(0.1))
                                .clipShape(Circle())

                            Text(insight.title)
                                .font(MCTypography.bodyMedium)
                                .foregroundStyle(MCColors.textPrimary)
                        }

                        Text(insight.description)
                            .font(MCTypography.footnote)
                            .foregroundStyle(MCColors.textSecondary)

                        if let action = insight.actionable {
                            HStack(spacing: MCSpacing.xxs) {
                                Image(systemName: "lightbulb.min")
                                    .font(.system(size: 12))
                                Text(action)
                                    .font(MCTypography.caption)
                            }
                            .foregroundStyle(MCColors.info)
                            .padding(MCSpacing.xs)
                            .background(MCColors.info.opacity(0.08))
                            .clipShape(RoundedRectangle(cornerRadius: MCSpacing.cornerRadiusSmall))
                        }
                    }
                }
                .gesture(
                    DragGesture(minimumDistance: 30)
                        .onEnded { value in
                            withAnimation {
                                if value.translation.width < 0 {
                                    currentIndex = min(currentIndex + 1, insights.count - 1)
                                } else {
                                    currentIndex = max(currentIndex - 1, 0)
                                }
                            }
                        }
                )

                // Page dots
                HStack(spacing: 4) {
                    Spacer()
                    ForEach(0..<min(insights.count, 5), id: \.self) { index in
                        Circle()
                            .fill(index == currentIndex ? MCColors.primaryTeal : MCColors.textTertiary.opacity(0.3))
                            .frame(width: 6, height: 6)
                    }
                    Spacer()
                }
            }
        }
    }
}

/// Enhancement #8: Drug Interaction Alert Banner
struct DrugInteractionBanner: View {
    let alerts: [DrugInteractionService.InteractionAlert]
    @State private var isExpanded = false

    var body: some View {
        if !alerts.isEmpty {
            MCAccentCard(accent: MCColors.error) {
                VStack(alignment: .leading, spacing: MCSpacing.xs) {
                    Button {
                        withAnimation { isExpanded.toggle() }
                    } label: {
                        HStack {
                            Image(systemName: "exclamationmark.shield.fill")
                                .foregroundStyle(MCColors.error)
                            Text("Drug Interaction Warning")
                                .font(MCTypography.bodyMedium)
                                .foregroundStyle(MCColors.textPrimary)
                            Spacer()
                            Text("\(alerts.count)")
                                .font(MCTypography.captionBold)
                                .foregroundStyle(.white)
                                .frame(width: 22, height: 22)
                                .background(MCColors.error)
                                .clipShape(Circle())
                            Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                                .foregroundStyle(MCColors.textTertiary)
                        }
                    }

                    if isExpanded {
                        ForEach(alerts) { alert in
                            VStack(alignment: .leading, spacing: MCSpacing.xxs) {
                                HStack {
                                    Image(systemName: alert.severity.icon)
                                        .foregroundStyle(Color(hex: alert.severity.color))
                                    Text("\(alert.medicine1) + \(alert.medicine2)")
                                        .font(MCTypography.subheadline)
                                    MCBadge(alert.severity.rawValue, color: Color(hex: alert.severity.color), style: .filled)
                                }

                                Text(alert.description)
                                    .font(MCTypography.caption)
                                    .foregroundStyle(MCColors.textSecondary)

                                Text(alert.recommendation)
                                    .font(MCTypography.caption)
                                    .foregroundStyle(MCColors.info)
                            }
                            .padding(MCSpacing.xs)
                            .background(Color(hex: alert.severity.color).opacity(0.05))
                            .clipShape(RoundedRectangle(cornerRadius: MCSpacing.cornerRadiusSmall))
                        }
                    }
                }
            }
        }
    }
}

/// Enhancement #9: Medicine Expiry Alert View
struct ExpiryAlertView: View {
    let alerts: [MedicineExpiryService.ExpiryAlert]

    var body: some View {
        let urgentAlerts = alerts.filter { $0.urgency != .safe }
        if !urgentAlerts.isEmpty {
            VStack(alignment: .leading, spacing: MCSpacing.xs) {
                HStack {
                    Image(systemName: "calendar.badge.exclamationmark")
                        .foregroundStyle(MCColors.warning)
                    Text("Expiry Alerts")
                        .font(MCTypography.headline)
                }

                ForEach(urgentAlerts) { alert in
                    HStack(spacing: MCSpacing.sm) {
                        Image(systemName: alert.urgency.icon)
                            .foregroundStyle(Color(hex: alert.urgency.color))

                        VStack(alignment: .leading, spacing: 2) {
                            Text(alert.medicineName)
                                .font(MCTypography.bodyMedium)
                            Text(alert.urgency == .expired
                                 ? "Expired!"
                                 : "Expires in \(alert.daysUntilExpiry) days")
                                .font(MCTypography.caption)
                                .foregroundStyle(Color(hex: alert.urgency.color))
                        }

                        Spacer()

                        MCBadge(alert.urgency.rawValue, color: Color(hex: alert.urgency.color))
                    }
                    .padding(MCSpacing.xs)
                    .background(Color(hex: alert.urgency.color).opacity(0.05))
                    .clipShape(RoundedRectangle(cornerRadius: MCSpacing.cornerRadiusSmall))
                }
            }
        }
    }
}
