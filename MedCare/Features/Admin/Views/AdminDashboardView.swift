import SwiftUI
import SwiftData

struct AdminDashboardView: View {
    @Query private var doctors: [Doctor]
    @Query private var profiles: [UserProfile]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: MCSpacing.lg) {
                    // Stats Grid
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: MCSpacing.md) {
                        adminStatCard(value: "\(doctors.count)", label: "Total Doctors", icon: "stethoscope", color: Color(hex: "3B82F6"))
                        adminStatCard(value: "\(profiles.count)", label: "Total Patients", icon: "person.2.fill", color: MCColors.primaryTeal)
                        adminStatCard(value: "24", label: "Today's Appointments", icon: "calendar", color: Color(hex: "6366F1"))
                        adminStatCard(value: "92%", label: "Satisfaction", icon: "hand.thumbsup.fill", color: MCColors.success)
                    }
                    .padding(.horizontal, MCSpacing.screenPadding)

                    // Recent Activity
                    VStack(alignment: .leading, spacing: MCSpacing.md) {
                        Text("RECENT ACTIVITY")
                            .font(MCTypography.sectionHeader)
                            .foregroundStyle(MCColors.textSecondary)
                            .textCase(.uppercase)
                            .kerning(1.2)
                            .padding(.horizontal, MCSpacing.screenPadding)

                        ForEach(recentActivities, id: \.title) { activity in
                            MCCard {
                                HStack(spacing: MCSpacing.md) {
                                    Image(systemName: activity.icon)
                                        .font(.system(size: 18))
                                        .foregroundStyle(activity.color)
                                        .frame(width: 36, height: 36)
                                        .background(activity.color.opacity(0.1))
                                        .clipShape(Circle())

                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(activity.title)
                                            .font(MCTypography.bodyMedium)
                                            .foregroundStyle(MCColors.textPrimary)
                                        Text(activity.subtitle)
                                            .font(MCTypography.caption)
                                            .foregroundStyle(MCColors.textSecondary)
                                    }

                                    Spacer()

                                    Text(activity.time)
                                        .font(MCTypography.caption)
                                        .foregroundStyle(MCColors.textTertiary)
                                }
                            }
                            .padding(.horizontal, MCSpacing.screenPadding)
                        }
                    }
                }
                .padding(.top, MCSpacing.md)
            }
            .background(MCColors.backgroundLight)
            .navigationTitle("Admin Dashboard")
        }
    }

    private func adminStatCard(value: String, label: String, icon: String, color: Color) -> some View {
        MCGlassCard {
            VStack(spacing: MCSpacing.sm) {
                Image(systemName: icon)
                    .font(.system(size: 22))
                    .foregroundStyle(color)

                Text(value)
                    .font(MCTypography.display)
                    .foregroundStyle(MCColors.textPrimary)

                Text(label)
                    .font(MCTypography.caption)
                    .foregroundStyle(MCColors.textSecondary)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
        }
    }

    private var recentActivities: [(icon: String, title: String, subtitle: String, time: String, color: Color)] {
        [
            ("person.badge.plus", "New doctor registered", "Dr. Aarav Joshi - Cardiology", "2h ago", Color(hex: "3B82F6")),
            ("calendar.badge.plus", "Appointment surge", "15 new bookings for next week", "4h ago", Color(hex: "6366F1")),
            ("exclamationmark.triangle", "Low staff alert", "Pediatrics department - 2 doctors on leave", "5h ago", MCColors.warning),
            ("star.fill", "Patient feedback", "4.8/5 avg rating this week", "1d ago", MCColors.success),
        ]
    }
}
