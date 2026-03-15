import SwiftUI

/// Positioning Agent Dashboard — for internal/business use
/// Shows competitive analysis, moat strength, and strategic recommendations
struct PositioningDashboard: View {
    @State private var agent = PositioningAgent()
    @State private var selectedPillar: PositioningAgent.StrategyPillar?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: MCSpacing.lg) {
                    // Moat Health
                    moatSection

                    // Competitive Landscape
                    competitiveSection

                    // Strategic Recommendations
                    strategicSection

                    // ASO Strategy
                    asoSection
                }
                .padding(.horizontal, MCSpacing.screenPadding)
                .padding(.vertical, MCSpacing.md)
            }
            .background(MCColors.backgroundLight)
            .navigationTitle("Positioning Agent")
        }
    }

    // MARK: - Moat Health

    private var moatSection: some View {
        VStack(alignment: .leading, spacing: MCSpacing.sm) {
            HStack {
                Image(systemName: "shield.checkered")
                    .foregroundStyle(MCColors.primaryTeal)
                Text("Moat Health")
                    .font(MCTypography.headline)
            }

            ForEach(agent.assessMoats(), id: \.moatName) { moat in
                MCCard {
                    VStack(alignment: .leading, spacing: MCSpacing.xs) {
                        HStack {
                            Text(moat.moatName)
                                .font(MCTypography.bodyMedium)
                            Spacer()
                            MCBadge(
                                moat.trend.rawValue,
                                color: moat.trend == .strengthening ? MCColors.success :
                                    moat.trend == .stable ? MCColors.info : MCColors.error
                            )
                        }

                        // Strength bar
                        GeometryReader { geo in
                            ZStack(alignment: .leading) {
                                Capsule()
                                    .fill(MCColors.backgroundLight)
                                    .frame(height: 8)
                                Capsule()
                                    .fill(MCColors.primaryGradient)
                                    .frame(width: geo.size.width * moat.currentStrength, height: 8)
                            }
                        }
                        .frame(height: 8)

                        Text("\(Int(moat.currentStrength * 100))% strength")
                            .font(MCTypography.caption)
                            .foregroundStyle(MCColors.textSecondary)
                    }
                }
            }
        }
    }

    // MARK: - Competitive Landscape

    private var competitiveSection: some View {
        VStack(alignment: .leading, spacing: MCSpacing.sm) {
            HStack {
                Image(systemName: "chart.bar.xaxis")
                    .foregroundStyle(MCColors.accentCoral)
                Text("Competitive Landscape")
                    .font(MCTypography.headline)
            }

            ForEach(agent.competitiveLandscape, id: \.name) { competitor in
                MCCard {
                    VStack(alignment: .leading, spacing: MCSpacing.xs) {
                        HStack {
                            Text(competitor.name)
                                .font(MCTypography.bodyMedium)
                            MCBadge(competitor.category.rawValue, color: MCColors.info, style: .outlined)
                            Spacer()
                            Text(competitor.userBase)
                                .font(MCTypography.caption)
                                .foregroundStyle(MCColors.textSecondary)
                        }

                        HStack(alignment: .top, spacing: MCSpacing.md) {
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Strengths")
                                    .font(MCTypography.captionBold)
                                    .foregroundStyle(MCColors.success)
                                ForEach(competitor.strengths, id: \.self) { s in
                                    Text("+ \(s)")
                                        .font(MCTypography.caption)
                                        .foregroundStyle(MCColors.textSecondary)
                                }
                            }

                            VStack(alignment: .leading, spacing: 2) {
                                Text("Gaps (our opportunity)")
                                    .font(MCTypography.captionBold)
                                    .foregroundStyle(MCColors.accentCoral)
                                ForEach(competitor.weaknesses, id: \.self) { w in
                                    Text("- \(w)")
                                        .font(MCTypography.caption)
                                        .foregroundStyle(MCColors.textSecondary)
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    // MARK: - Strategic Recommendations

    private var strategicSection: some View {
        VStack(alignment: .leading, spacing: MCSpacing.sm) {
            HStack {
                Image(systemName: "lightbulb")
                    .foregroundStyle(MCColors.warning)
                Text("Strategic Recommendations")
                    .font(MCTypography.headline)
            }

            // Pillar filter
            HStack(spacing: MCSpacing.xs) {
                Button {
                    selectedPillar = nil
                } label: {
                    Text("All")
                        .font(MCTypography.caption)
                        .foregroundStyle(selectedPillar == nil ? .white : MCColors.textPrimary)
                        .padding(.horizontal, MCSpacing.sm)
                        .padding(.vertical, MCSpacing.xxs)
                        .background(selectedPillar == nil ? MCColors.primaryTeal : MCColors.backgroundLight)
                        .clipShape(Capsule())
                }
                ForEach(PositioningAgent.StrategyPillar.allCases, id: \.rawValue) { pillar in
                    Button {
                        selectedPillar = pillar
                    } label: {
                        Text(pillar.rawValue)
                            .font(MCTypography.caption)
                            .foregroundStyle(selectedPillar == pillar ? .white : MCColors.textPrimary)
                            .padding(.horizontal, MCSpacing.sm)
                            .padding(.vertical, MCSpacing.xxs)
                            .background(selectedPillar == pillar ? MCColors.primaryTeal : MCColors.backgroundLight)
                            .clipShape(Capsule())
                    }
                }
            }

            let recs = agent.generateRecommendations()
                .filter { selectedPillar == nil || $0.pillar == selectedPillar }

            ForEach(recs) { rec in
                MCAccentCard(accent: Color(hex: rec.pillar.color)) {
                    VStack(alignment: .leading, spacing: MCSpacing.xs) {
                        HStack {
                            Image(systemName: rec.pillar.icon)
                                .foregroundStyle(Color(hex: rec.pillar.color))
                            Text(rec.title)
                                .font(MCTypography.bodyMedium)
                            Spacer()
                            MCBadge(rec.impact.rawValue, color: rec.impact == .critical ? MCColors.error : MCColors.info)
                        }

                        Text(rec.description)
                            .font(MCTypography.footnote)
                            .foregroundStyle(MCColors.textSecondary)

                        HStack(spacing: MCSpacing.md) {
                            Label(rec.effort.rawValue + " effort", systemImage: "hammer")
                            Label(rec.timeline, systemImage: "calendar")
                        }
                        .font(MCTypography.caption)
                        .foregroundStyle(MCColors.textTertiary)
                    }
                }
            }
        }
    }

    // MARK: - ASO Strategy

    private var asoSection: some View {
        let aso = agent.generateASOStrategy()
        return VStack(alignment: .leading, spacing: MCSpacing.sm) {
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(MCColors.info)
                Text("App Store Optimization")
                    .font(MCTypography.headline)
            }

            MCCard {
                VStack(alignment: .leading, spacing: MCSpacing.xs) {
                    Text("Title: \(aso.title)")
                        .font(MCTypography.bodyMedium)
                    Text("Subtitle: \(aso.subtitle)")
                        .font(MCTypography.footnote)
                        .foregroundStyle(MCColors.textSecondary)

                    Text("Keywords:")
                        .font(MCTypography.captionBold)
                        .foregroundStyle(MCColors.textSecondary)
                    FlowLayout(spacing: MCSpacing.xxs) {
                        ForEach(aso.keywords, id: \.self) { keyword in
                            Text(keyword)
                                .font(MCTypography.caption)
                                .foregroundStyle(MCColors.primaryTeal)
                                .padding(.horizontal, MCSpacing.xs)
                                .padding(.vertical, 2)
                                .background(MCColors.primaryTeal.opacity(0.1))
                                .clipShape(Capsule())
                        }
                    }
                }
            }
        }
    }
}

extension PositioningAgent.StrategyPillar: CaseIterable {
    nonisolated static let allCases: [PositioningAgent.StrategyPillar] = [.defend, .extend, .disrupt]
}
