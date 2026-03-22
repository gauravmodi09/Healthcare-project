import SwiftUI

struct DoctorPatientDetailView: View {
    let patient: DoctorMockPatient
    @Environment(\.dismiss) private var dismiss
    @State private var showPrescription = false
    @State private var selectedAdherenceRange = 0 // 0 = 7 days, 1 = 30 days

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: MCSpacing.sectionSpacing) {
                    patientHeader
                    vitalsSummary
                    adherenceChart
                    currentMedications
                    recentSymptoms
                    quickActions
                }
                .padding(.vertical, MCSpacing.md)
            }
            .background(MCColors.backgroundLight)
            .navigationTitle(patient.name)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                }
            }
            .sheet(isPresented: $showPrescription) {
                EPrescriptionView(patient: patient)
            }
        }
    }

    // MARK: - Patient Header

    private var patientHeader: some View {
        MCCard {
            HStack(spacing: MCSpacing.md) {
                ZStack(alignment: .bottomTrailing) {
                    Text(patient.avatarEmoji)
                        .font(.system(size: 36))
                        .frame(width: 64, height: 64)
                        .background(MCColors.backgroundLight)
                        .clipShape(Circle())
                    Circle()
                        .fill(patient.status.color)
                        .frame(width: 16, height: 16)
                        .overlay(Circle().stroke(MCColors.cardBackground, lineWidth: 2))
                        .offset(x: 2, y: 2)
                }

                VStack(alignment: .leading, spacing: MCSpacing.xxs) {
                    Text(patient.name)
                        .font(MCTypography.title2)
                        .foregroundStyle(MCColors.textPrimary)
                    HStack(spacing: MCSpacing.xs) {
                        Text("\(patient.age) yrs")
                            .font(MCTypography.subheadline)
                            .foregroundStyle(MCColors.textSecondary)
                        Text("\u{00B7}")
                            .foregroundStyle(MCColors.textTertiary)
                        Text(patient.primaryCondition)
                            .font(MCTypography.subheadline)
                            .foregroundStyle(MCColors.textSecondary)
                    }
                    MCBadge(patient.status.rawValue, color: patient.status.color, style: .soft)
                }
                Spacer()
            }
        }
        .padding(.horizontal, MCSpacing.screenPadding)
    }

    // MARK: - Vitals Summary

    private var vitalsSummary: some View {
        VStack(alignment: .leading, spacing: MCSpacing.sm) {
            sectionHeader(icon: "heart.text.square.fill", title: "VITALS SUMMARY")

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: MCSpacing.sm) {
                vitalCard(
                    title: "Heart Rate",
                    value: "\(patient.heartRate)",
                    unit: "bpm",
                    icon: "heart.fill",
                    trend: patient.hrTrend,
                    color: MCColors.accentCoral
                )
                vitalCard(
                    title: "Blood Pressure",
                    value: "\(patient.bpSystolic)/\(patient.bpDiastolic)",
                    unit: "mmHg",
                    icon: "waveform.path.ecg",
                    trend: patient.bpTrend,
                    color: patient.bpSystolic > 140 ? MCColors.error : MCColors.primaryTeal
                )
                vitalCard(
                    title: "SpO2",
                    value: "\(patient.spO2)",
                    unit: "%",
                    icon: "lungs.fill",
                    trend: patient.spO2Trend,
                    color: patient.spO2 < 95 ? MCColors.warning : MCColors.success
                )
                vitalCard(
                    title: "Glucose",
                    value: "\(patient.glucose)",
                    unit: "mg/dL",
                    icon: "drop.fill",
                    trend: patient.glucoseTrend,
                    color: patient.glucose > 200 ? MCColors.error : (patient.glucose > 140 ? MCColors.warning : MCColors.success)
                )
            }
            .padding(.horizontal, MCSpacing.screenPadding)
        }
    }

    private func vitalCard(title: String, value: String, unit: String, icon: String, trend: VitalTrend, color: Color) -> some View {
        MCCard {
            VStack(alignment: .leading, spacing: MCSpacing.xs) {
                HStack {
                    Image(systemName: icon)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(color)
                    Spacer()
                    Image(systemName: trend.rawValue)
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(trendColor(trend, for: title))
                }
                HStack(alignment: .lastTextBaseline, spacing: MCSpacing.xxs) {
                    Text(value)
                        .font(MCTypography.title2)
                        .foregroundStyle(MCColors.textPrimary)
                    Text(unit)
                        .font(MCTypography.caption)
                        .foregroundStyle(MCColors.textTertiary)
                }
                Text(title)
                    .font(MCTypography.caption)
                    .foregroundStyle(MCColors.textSecondary)
            }
        }
    }

    private func trendColor(_ trend: VitalTrend, for title: String) -> Color {
        switch trend {
        case .stable: return MCColors.textTertiary
        case .up:
            // Up is bad for BP, glucose, HR; good for SpO2
            return title == "SpO2" ? MCColors.success : MCColors.error
        case .down:
            return title == "SpO2" ? MCColors.error : MCColors.success
        }
    }

    // MARK: - Adherence Chart

    private var adherenceChart: some View {
        VStack(alignment: .leading, spacing: MCSpacing.sm) {
            HStack {
                sectionHeader(icon: "chart.bar.fill", title: "ADHERENCE")
                Spacer()
                Picker("Range", selection: $selectedAdherenceRange) {
                    Text("7 Days").tag(0)
                    Text("30 Days").tag(1)
                }
                .pickerStyle(.segmented)
                .frame(width: 160)
                .padding(.trailing, MCSpacing.screenPadding)
            }

            MCCard {
                VStack(spacing: MCSpacing.sm) {
                    // Overall adherence
                    HStack {
                        Text("Overall")
                            .font(MCTypography.subheadline)
                            .foregroundStyle(MCColors.textSecondary)
                        Spacer()
                        Text("\(patient.adherencePercent)%")
                            .font(MCTypography.headline)
                            .foregroundStyle(adherenceColor(patient.adherencePercent))
                    }

                    // Bar chart
                    HStack(alignment: .bottom, spacing: MCSpacing.xxs) {
                        ForEach(Array(patient.dailyAdherence7Days.enumerated()), id: \.offset) { index, value in
                            VStack(spacing: MCSpacing.xxs) {
                                RoundedRectangle(cornerRadius: 3)
                                    .fill(barColor(value))
                                    .frame(height: CGFloat(value) / 100.0 * 80)
                                    .frame(maxWidth: .infinity)

                                Text(dayLabel(index))
                                    .font(.system(size: 9))
                                    .foregroundStyle(MCColors.textTertiary)
                            }
                        }
                    }
                    .frame(height: 100)
                }
            }
            .padding(.horizontal, MCSpacing.screenPadding)
        }
    }

    private func barColor(_ value: Int) -> Color {
        switch value {
        case 0: return MCColors.error.opacity(0.3)
        case 1..<50: return MCColors.error
        case 50..<75: return MCColors.warning
        case 75..<90: return MCColors.info
        default: return MCColors.success
        }
    }

    private func dayLabel(_ index: Int) -> String {
        let calendar = Calendar.current
        let date = calendar.date(byAdding: .day, value: -(6 - index), to: Date()) ?? Date()
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE"
        return String(formatter.string(from: date).prefix(2))
    }

    // MARK: - Current Medications

    private var currentMedications: some View {
        VStack(alignment: .leading, spacing: MCSpacing.sm) {
            sectionHeader(icon: "pills.fill", title: "CURRENT MEDICATIONS")

            VStack(spacing: MCSpacing.xs) {
                ForEach(patient.medications) { med in
                    MCCard {
                        HStack(spacing: MCSpacing.sm) {
                            Image(systemName: "pills.fill")
                                .font(.system(size: 16))
                                .foregroundStyle(MCColors.primaryTeal)
                                .frame(width: 32, height: 32)
                                .background(MCColors.primaryTeal.opacity(0.1))
                                .clipShape(RoundedRectangle(cornerRadius: MCSpacing.cornerRadiusSmall))

                            VStack(alignment: .leading, spacing: MCSpacing.xxs) {
                                Text(med.name)
                                    .font(MCTypography.headline)
                                    .foregroundStyle(MCColors.textPrimary)
                                Text("\(med.dosage) \u{00B7} \(med.frequency)")
                                    .font(MCTypography.caption)
                                    .foregroundStyle(MCColors.textSecondary)
                            }

                            Spacer()

                            // Adherence per medicine
                            VStack(spacing: 2) {
                                Text("\(med.adherencePercent)%")
                                    .font(MCTypography.captionBold)
                                    .foregroundStyle(adherenceColor(med.adherencePercent))
                                // Mini progress bar
                                GeometryReader { geo in
                                    ZStack(alignment: .leading) {
                                        RoundedRectangle(cornerRadius: 2)
                                            .fill(MCColors.divider)
                                        RoundedRectangle(cornerRadius: 2)
                                            .fill(adherenceColor(med.adherencePercent))
                                            .frame(width: geo.size.width * CGFloat(med.adherencePercent) / 100)
                                    }
                                }
                                .frame(width: 48, height: 4)
                            }
                        }
                    }
                }
            }
            .padding(.horizontal, MCSpacing.screenPadding)
        }
    }

    // MARK: - Recent Symptoms

    private var recentSymptoms: some View {
        VStack(alignment: .leading, spacing: MCSpacing.sm) {
            sectionHeader(icon: "heart.text.clipboard", title: "RECENT SYMPTOMS")

            if patient.recentSymptoms.isEmpty {
                MCCard {
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(MCColors.success)
                        Text("No symptoms reported in the last 7 days")
                            .font(MCTypography.callout)
                            .foregroundStyle(MCColors.textSecondary)
                    }
                }
                .padding(.horizontal, MCSpacing.screenPadding)
            } else {
                MCCard {
                    VStack(spacing: MCSpacing.xs) {
                        ForEach(patient.recentSymptoms) { symptom in
                            HStack(spacing: MCSpacing.sm) {
                                Circle()
                                    .fill(symptomColor(symptom.severity))
                                    .frame(width: 8, height: 8)
                                Text(symptom.name)
                                    .font(MCTypography.callout)
                                    .foregroundStyle(MCColors.textPrimary)
                                Spacer()
                                MCBadge(symptom.severity, color: symptomColor(symptom.severity))
                                Text(symptom.daysAgo == 0 ? "Today" : "\(symptom.daysAgo)d ago")
                                    .font(MCTypography.caption)
                                    .foregroundStyle(MCColors.textTertiary)
                            }
                            if symptom.id != patient.recentSymptoms.last?.id {
                                Divider()
                            }
                        }
                    }
                }
                .padding(.horizontal, MCSpacing.screenPadding)
            }
        }
    }

    private func symptomColor(_ severity: String) -> Color {
        switch severity {
        case "Mild": return MCColors.success
        case "Moderate": return MCColors.warning
        case "Severe": return MCColors.error
        default: return MCColors.textSecondary
        }
    }

    // MARK: - Quick Actions

    private var quickActions: some View {
        VStack(alignment: .leading, spacing: MCSpacing.sm) {
            sectionHeader(icon: "bolt.fill", title: "QUICK ACTIONS")

            VStack(spacing: MCSpacing.xs) {
                HStack(spacing: MCSpacing.xs) {
                    quickActionButton(icon: "bubble.left.fill", title: "Send Message", color: MCColors.primaryTeal) {
                        // placeholder action
                    }
                    quickActionButton(icon: "doc.text.fill", title: "Write Prescription", color: MCColors.accentCoral) {
                        showPrescription = true
                    }
                }
                HStack(spacing: MCSpacing.xs) {
                    quickActionButton(icon: "calendar.badge.plus", title: "Schedule Follow-up", color: MCColors.info) {
                        // placeholder action
                    }
                    quickActionButton(icon: "phone.fill", title: "Call Patient", color: MCColors.success) {
                        // placeholder action
                    }
                }
            }
            .padding(.horizontal, MCSpacing.screenPadding)
        }
        .padding(.bottom, MCSpacing.lg)
    }

    private func quickActionButton(icon: String, title: String, color: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            MCCard {
                HStack(spacing: MCSpacing.sm) {
                    Image(systemName: icon)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(color)
                        .frame(width: 36, height: 36)
                        .background(color.opacity(0.1))
                        .clipShape(Circle())
                    Text(title)
                        .font(MCTypography.subheadline)
                        .foregroundStyle(MCColors.textPrimary)
                    Spacer()
                }
            }
        }
    }

    // MARK: - Helpers

    private func sectionHeader(icon: String, title: String) -> some View {
        HStack(spacing: MCSpacing.xs) {
            Image(systemName: icon)
                .foregroundStyle(MCColors.primaryTeal)
                .font(.system(size: 14))
            Text(title)
                .font(MCTypography.sectionHeader)
                .foregroundStyle(MCColors.textSecondary)
                .kerning(1.2)
        }
        .padding(.horizontal, MCSpacing.screenPadding)
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
    DoctorPatientDetailView(patient: DoctorMockData.patients.first!)
}
