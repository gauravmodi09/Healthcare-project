import SwiftUI
import SwiftData

struct AdminAnalyticsView: View {
    @Query private var doctors: [Doctor]
    @Query private var profiles: [UserProfile]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: MCSpacing.lg) {
                    // Key Metrics
                    VStack(alignment: .leading, spacing: MCSpacing.md) {
                        Text("KEY METRICS")
                            .font(MCTypography.sectionHeader)
                            .foregroundStyle(MCColors.textSecondary)
                            .textCase(.uppercase)
                            .kerning(1.2)

                        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: MCSpacing.md) {
                            metricCard(title: "Avg. Wait Time", value: "18 min", trend: "-12%", trendPositive: true, icon: "clock.fill")
                            metricCard(title: "Bed Occupancy", value: "78%", trend: "+5%", trendPositive: false, icon: "bed.double.fill")
                            metricCard(title: "Revenue (MTD)", value: "Rs. 24.5L", trend: "+8%", trendPositive: true, icon: "indianrupeesign.circle.fill")
                            metricCard(title: "Patient Satisfaction", value: "4.6/5", trend: "+0.2", trendPositive: true, icon: "star.fill")
                        }
                    }
                    .padding(.horizontal, MCSpacing.screenPadding)

                    // Department Performance
                    VStack(alignment: .leading, spacing: MCSpacing.md) {
                        Text("DEPARTMENT PERFORMANCE")
                            .font(MCTypography.sectionHeader)
                            .foregroundStyle(MCColors.textSecondary)
                            .textCase(.uppercase)
                            .kerning(1.2)
                            .padding(.horizontal, MCSpacing.screenPadding)

                        ForEach(departmentStats, id: \.name) { dept in
                            MCCard {
                                VStack(spacing: MCSpacing.sm) {
                                    HStack {
                                        Text(dept.name)
                                            .font(MCTypography.bodyMedium)
                                            .foregroundStyle(MCColors.textPrimary)
                                        Spacer()
                                        Text("\(dept.patients) patients")
                                            .font(MCTypography.caption)
                                            .foregroundStyle(MCColors.textSecondary)
                                    }

                                    // Progress bar
                                    GeometryReader { geo in
                                        ZStack(alignment: .leading) {
                                            RoundedRectangle(cornerRadius: 4)
                                                .fill(MCColors.divider)
                                                .frame(height: 8)
                                            RoundedRectangle(cornerRadius: 4)
                                                .fill(dept.color)
                                                .frame(width: geo.size.width * dept.utilization, height: 8)
                                        }
                                    }
                                    .frame(height: 8)

                                    HStack {
                                        Text("\(Int(dept.utilization * 100))% utilization")
                                            .font(MCTypography.caption)
                                            .foregroundStyle(MCColors.textTertiary)
                                        Spacer()
                                        Text("\(dept.doctorCount) doctors")
                                            .font(MCTypography.caption)
                                            .foregroundStyle(MCColors.textTertiary)
                                    }
                                }
                            }
                            .padding(.horizontal, MCSpacing.screenPadding)
                        }
                    }
                }
                .padding(.top, MCSpacing.md)
                .padding(.bottom, MCSpacing.xl)
            }
            .background(MCColors.backgroundLight)
            .navigationTitle("Analytics")
        }
    }

    private func metricCard(title: String, value: String, trend: String, trendPositive: Bool, icon: String) -> some View {
        MCGlassCard {
            VStack(alignment: .leading, spacing: MCSpacing.sm) {
                Image(systemName: icon)
                    .font(.system(size: 18))
                    .foregroundStyle(MCColors.primaryTeal)

                Text(value)
                    .font(MCTypography.title)
                    .foregroundStyle(MCColors.textPrimary)

                HStack(spacing: MCSpacing.xxs) {
                    Text(title)
                        .font(MCTypography.caption)
                        .foregroundStyle(MCColors.textSecondary)
                    Spacer()
                    Text(trend)
                        .font(MCTypography.captionBold)
                        .foregroundStyle(trendPositive ? MCColors.success : MCColors.error)
                }
            }
        }
    }

    private var departmentStats: [(name: String, patients: Int, doctorCount: Int, utilization: CGFloat, color: Color)] {
        [
            ("Cardiology", 145, 12, 0.88, Color(hex: "EF4444")),
            ("General Medicine", 230, 18, 0.72, MCColors.primaryTeal),
            ("Pediatrics", 98, 8, 0.65, Color(hex: "3B82F6")),
            ("Orthopedics", 76, 6, 0.80, Color(hex: "F59E0B")),
            ("Neurology", 54, 5, 0.58, Color(hex: "6366F1")),
        ]
    }
}
