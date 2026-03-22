import SwiftUI

struct DoctorAppointmentsView: View {
    @State private var selectedDate = Date()

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: MCSpacing.lg) {
                    // Date picker
                    DatePicker("Select Date", selection: $selectedDate, displayedComponents: .date)
                        .datePickerStyle(.graphical)
                        .tint(MCColors.primaryTeal)
                        .padding(.horizontal, MCSpacing.screenPadding)

                    // Today's appointments
                    VStack(alignment: .leading, spacing: MCSpacing.md) {
                        Text("TODAY'S SCHEDULE")
                            .font(MCTypography.sectionHeader)
                            .foregroundStyle(MCColors.textSecondary)
                            .textCase(.uppercase)
                            .kerning(1.2)
                            .padding(.horizontal, MCSpacing.screenPadding)

                        // Sample appointments
                        ForEach(sampleAppointments, id: \.time) { apt in
                            MCCard {
                                HStack(spacing: MCSpacing.md) {
                                    VStack(spacing: 2) {
                                        Text(apt.time)
                                            .font(MCTypography.bodyMedium)
                                            .foregroundStyle(MCColors.primaryTeal)
                                        Text(apt.duration)
                                            .font(MCTypography.caption)
                                            .foregroundStyle(MCColors.textTertiary)
                                    }
                                    .frame(width: 60)

                                    Rectangle()
                                        .fill(apt.statusColor)
                                        .frame(width: 3)
                                        .clipShape(Capsule())

                                    VStack(alignment: .leading, spacing: MCSpacing.xxs) {
                                        Text(apt.patientName)
                                            .font(MCTypography.bodyMedium)
                                            .foregroundStyle(MCColors.textPrimary)
                                        Text(apt.reason)
                                            .font(MCTypography.caption)
                                            .foregroundStyle(MCColors.textSecondary)
                                    }

                                    Spacer()

                                    Text(apt.type)
                                        .font(MCTypography.caption)
                                        .foregroundStyle(apt.statusColor)
                                        .padding(.horizontal, MCSpacing.xs)
                                        .padding(.vertical, MCSpacing.xxs)
                                        .background(apt.statusColor.opacity(0.1))
                                        .clipShape(Capsule())
                                }
                            }
                            .padding(.horizontal, MCSpacing.screenPadding)
                        }
                    }
                }
                .padding(.top, MCSpacing.md)
            }
            .background(MCColors.backgroundLight)
            .navigationTitle("Appointments")
        }
    }

    private var sampleAppointments: [(time: String, duration: String, patientName: String, reason: String, type: String, statusColor: Color)] {
        [
            ("9:00 AM", "30 min", "Ramesh Kumar", "Follow-up: Diabetes", "In-Person", MCColors.primaryTeal),
            ("9:45 AM", "20 min", "Sita Devi", "Blood pressure check", "Walk-in", MCColors.warning),
            ("10:30 AM", "30 min", "Arun Mehta", "New consultation", "Video", Color(hex: "6366F1")),
            ("11:15 AM", "15 min", "Priya Sharma", "Prescription renewal", "In-Person", MCColors.primaryTeal),
            ("2:00 PM", "30 min", "Vikram Patel", "Post-surgery follow-up", "In-Person", MCColors.primaryTeal),
            ("3:00 PM", "20 min", "Lakshmi Narayan", "Lab results review", "Video", Color(hex: "6366F1")),
        ]
    }
}
