import SwiftUI
import SwiftData

// MARK: - Doctor Dashboard View

struct DoctorDashboardView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(DataService.self) private var dataService
    @Query private var profiles: [UserProfile]

    @State private var selectedPatient: DoctorPatientData?
    @State private var searchText = ""
    @State private var showCalendar = false
    @State private var showQueue = false
    @State private var isLoading = true

    private var patients: [DoctorPatientData] {
        profiles.map { DoctorPatientData.from(profile: $0) }
    }

    private var alerts: [DoctorAlert] {
        patients.flatMap { $0.generateAlerts() }
    }

    private var filteredPatients: [DoctorPatientData] {
        if searchText.isEmpty { return patients }
        return patients.filter {
            $0.name.localizedCaseInsensitiveContains(searchText) ||
            $0.primaryCondition.localizedCaseInsensitiveContains(searchText)
        }
    }

    private var alertPatients: [DoctorPatientData] {
        patients.filter { $0.status != .stable }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                if isLoading {
                    VStack(spacing: MCSpacing.md) {
                        SkeletonCardView()
                        SkeletonCardView()
                        SkeletonCardView()
                    }
                    .padding(.horizontal, MCSpacing.screenPadding)
                    .padding(.top, MCSpacing.md)
                } else {
                    VStack(spacing: MCSpacing.sectionSpacing) {
                        doctorHeader
                        if !alerts.isEmpty {
                            alertPanel
                        }
                        patientListSection
                    }
                    .padding(.vertical, MCSpacing.md)
                }
            }
            .task {
                try? await Task.sleep(nanoseconds: 400_000_000)
                withAnimation(.easeOut(duration: 0.3)) {
                    isLoading = false
                }
            }
            .background(MCColors.backgroundLight)
            .navigationTitle("Doctor Dashboard")
            .navigationBarTitleDisplayMode(.large)
            .searchable(text: $searchText, prompt: "Search patients...")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        dismiss()
                    } label: {
                        HStack(spacing: 4) {
                            Text("Exit")
                                .font(.system(size: 15, weight: .medium))
                            Image(systemName: "xmark.circle.fill")
                                .font(.system(size: 18))
                        }
                        .foregroundStyle(MCColors.accentCoral)
                    }
                }
            }
            .sheet(item: $selectedPatient) { patient in
                DoctorPatientDetailView(patient: patient)
            }
            .sheet(isPresented: $showCalendar) {
                DoctorCalendarView()
            }
            .sheet(isPresented: $showQueue) {
                WalkInQueueView()
            }
        }
    }

    // MARK: - Doctor Header

    private var doctorHeader: some View {
        MCCard {
            HStack(spacing: MCSpacing.md) {
                ZStack {
                    Circle()
                        .fill(MCColors.primaryGradient)
                        .frame(width: 56, height: 56)
                    Image(systemName: "stethoscope")
                        .font(.system(size: 24, weight: .semibold))
                        .foregroundStyle(.white)
                }

                VStack(alignment: .leading, spacing: MCSpacing.xxs) {
                    Text("Doctor Dashboard")
                        .font(MCTypography.title2)
                        .foregroundStyle(MCColors.textPrimary)
                    Text("Patient Overview")
                        .font(MCTypography.subheadline)
                        .foregroundStyle(MCColors.textSecondary)
                    HStack(spacing: MCSpacing.xxs) {
                        Image(systemName: "person.2.fill")
                            .font(.system(size: 11))
                        Text("\(patients.count) patients")
                            .font(MCTypography.captionBold)
                    }
                    .foregroundStyle(MCColors.primaryTeal)
                    .padding(.horizontal, MCSpacing.xs)
                    .padding(.vertical, MCSpacing.xxs)
                    .background(MCColors.primaryTeal.opacity(0.1))
                    .clipShape(Capsule())
                }

                Spacer()

                VStack(spacing: MCSpacing.xxs) {
                    Text("\(alertPatients.count)")
                        .font(MCTypography.metric)
                        .foregroundStyle(MCColors.error)
                    Text("Alerts")
                        .font(MCTypography.caption)
                        .foregroundStyle(MCColors.textSecondary)
                }
            }

            // Quick access buttons
            HStack(spacing: MCSpacing.xs) {
                Button { showCalendar = true } label: {
                    HStack(spacing: MCSpacing.xxs) {
                        Image(systemName: "calendar")
                            .font(.system(size: 13, weight: .semibold))
                        Text("Calendar")
                            .font(MCTypography.captionBold)
                    }
                    .foregroundStyle(MCColors.primaryTeal)
                    .padding(.horizontal, MCSpacing.sm)
                    .padding(.vertical, MCSpacing.xs)
                    .background(MCColors.primaryTeal.opacity(0.1))
                    .clipShape(Capsule())
                }

                Button { showQueue = true } label: {
                    HStack(spacing: MCSpacing.xxs) {
                        Image(systemName: "person.3.sequence.fill")
                            .font(.system(size: 13, weight: .semibold))
                        Text("Queue")
                            .font(MCTypography.captionBold)
                    }
                    .foregroundStyle(MCColors.warning)
                    .padding(.horizontal, MCSpacing.sm)
                    .padding(.vertical, MCSpacing.xs)
                    .background(MCColors.warning.opacity(0.1))
                    .clipShape(Capsule())
                }

                Spacer()
            }
        }
        .padding(.horizontal, MCSpacing.screenPadding)
    }

    // MARK: - Alert Panel

    private var alertPanel: some View {
        VStack(alignment: .leading, spacing: MCSpacing.sm) {
            HStack {
                Image(systemName: "bell.badge.fill")
                    .foregroundStyle(MCColors.error)
                Text("NEEDS ATTENTION")
                    .font(MCTypography.sectionHeader)
                    .foregroundStyle(MCColors.textSecondary)
                    .kerning(1.2)
                Spacer()
                MCBadge("\(alerts.count)", color: MCColors.error, style: .filled)
            }
            .padding(.horizontal, MCSpacing.screenPadding)

            VStack(spacing: MCSpacing.xs) {
                ForEach(alerts) { alert in
                    MCAccentCard(accent: alert.severity.color) {
                        HStack(spacing: MCSpacing.sm) {
                            Image(systemName: alert.severity.icon)
                                .foregroundStyle(alert.severity.color)
                                .font(.system(size: 16, weight: .semibold))

                            VStack(alignment: .leading, spacing: MCSpacing.xxs) {
                                HStack(spacing: MCSpacing.xxs) {
                                    Text(alert.patientName)
                                        .font(MCTypography.headline)
                                        .foregroundStyle(MCColors.textPrimary)
                                    Text(alert.timeAgo)
                                        .font(MCTypography.caption)
                                        .foregroundStyle(MCColors.textTertiary)
                                }
                                Text(alert.message)
                                    .font(MCTypography.callout)
                                    .foregroundStyle(MCColors.textSecondary)
                            }

                            Spacer()

                            Image(systemName: "chevron.right")
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundStyle(MCColors.textTertiary)
                        }
                    }
                }
            }
            .padding(.horizontal, MCSpacing.screenPadding)
        }
    }

    // MARK: - Patient List

    private var patientListSection: some View {
        VStack(alignment: .leading, spacing: MCSpacing.sm) {
            HStack {
                Image(systemName: "person.2.fill")
                    .foregroundStyle(MCColors.primaryTeal)
                Text("ALL PATIENTS")
                    .font(MCTypography.sectionHeader)
                    .foregroundStyle(MCColors.textSecondary)
                    .kerning(1.2)
                Spacer()
            }
            .padding(.horizontal, MCSpacing.screenPadding)

            if filteredPatients.isEmpty {
                MCCard {
                    HStack {
                        Image(systemName: "person.slash")
                            .foregroundStyle(MCColors.textTertiary)
                        Text("No patient profiles found. Add profiles to see them here.")
                            .font(MCTypography.callout)
                            .foregroundStyle(MCColors.textSecondary)
                    }
                }
                .padding(.horizontal, MCSpacing.screenPadding)
            } else {
                VStack(spacing: MCSpacing.xs) {
                    ForEach(filteredPatients) { patient in
                        Button {
                            selectedPatient = patient
                        } label: {
                            patientRow(patient)
                        }
                    }
                }
                .padding(.horizontal, MCSpacing.screenPadding)
            }
        }
    }

    private func patientRow(_ patient: DoctorPatientData) -> some View {
        MCCard {
            HStack(spacing: MCSpacing.sm) {
                // Status dot + Avatar
                ZStack(alignment: .bottomTrailing) {
                    Text(patient.avatarEmoji)
                        .font(.system(size: 28))
                        .frame(width: 48, height: 48)
                        .background(MCColors.backgroundLight)
                        .clipShape(Circle())

                    Circle()
                        .fill(patient.status.color)
                        .frame(width: 14, height: 14)
                        .overlay(Circle().stroke(MCColors.cardBackground, lineWidth: 2))
                        .offset(x: 2, y: 2)
                }

                // Name, condition, vital
                VStack(alignment: .leading, spacing: MCSpacing.xxs) {
                    HStack(spacing: MCSpacing.xxs) {
                        Text(patient.name)
                            .font(MCTypography.headline)
                            .foregroundStyle(MCColors.textPrimary)
                        Text("\(patient.age)y")
                            .font(MCTypography.caption)
                            .foregroundStyle(MCColors.textTertiary)
                    }
                    Text(patient.primaryCondition)
                        .font(MCTypography.subheadline)
                        .foregroundStyle(MCColors.textSecondary)
                    HStack(spacing: MCSpacing.xxs) {
                        Text("\(patient.lastVitalLabel): \(patient.lastVitalValue)")
                            .font(MCTypography.caption)
                            .foregroundStyle(MCColors.textTertiary)
                        Text(patient.lastVitalTime)
                            .font(MCTypography.caption)
                            .foregroundStyle(MCColors.textTertiary)
                    }
                }

                Spacer()

                // Adherence badge
                VStack(spacing: MCSpacing.xxs) {
                    Text("\(patient.adherencePercent)%")
                        .font(MCTypography.captionBold)
                        .foregroundStyle(adherenceColor(patient.adherencePercent))
                    Text("Adherence")
                        .font(.system(size: 9))
                        .foregroundStyle(MCColors.textTertiary)
                }
                .padding(.horizontal, MCSpacing.xs)
                .padding(.vertical, MCSpacing.xxs)
                .background(adherenceColor(patient.adherencePercent).opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: MCSpacing.cornerRadiusSmall))

                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(MCColors.textTertiary)
            }
        }
    }

    private func adherenceColor(_ percent: Int) -> Color {
        switch percent {
        case 0..<50: return MCColors.error
        case 50..<75: return MCColors.warning
        case 75..<90: return MCColors.info
        default: return MCColors.success
        }
    }
}

#Preview {
    DoctorDashboardView()
}
