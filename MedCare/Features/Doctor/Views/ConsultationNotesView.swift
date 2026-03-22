import SwiftUI

struct ConsultationNotesView: View {
    let patient: DoctorPatientData
    @Environment(\.dismiss) private var dismiss
    @State private var diagnosis = ""
    @State private var treatmentPlan = ""
    @State private var followUpDate = Date()
    @State private var showFollowUpPicker = false
    @State private var showPrescription = false
    @State private var isSaved = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: MCSpacing.sectionSpacing) {
                    patientHeader
                    diagnosisSection
                    treatmentSection
                    followUpSection
                    prescriptionAction
                    saveButton
                }
                .padding(.vertical, MCSpacing.md)
            }
            .background(MCColors.backgroundLight)
            .navigationTitle("Consultation Notes")
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
        MCAccentCard(accent: MCColors.primaryTeal) {
            HStack(spacing: MCSpacing.sm) {
                Text(patient.avatarEmoji)
                    .font(.system(size: 28))
                    .frame(width: 44, height: 44)
                    .background(MCColors.backgroundLight)
                    .clipShape(Circle())
                VStack(alignment: .leading, spacing: MCSpacing.xxs) {
                    Text(patient.name)
                        .font(MCTypography.headline)
                        .foregroundStyle(MCColors.textPrimary)
                    HStack(spacing: MCSpacing.xs) {
                        Text("\(patient.age) yrs")
                        Text("\u{00B7}")
                        Text(patient.primaryCondition)
                    }
                    .font(MCTypography.caption)
                    .foregroundStyle(MCColors.textSecondary)
                }
                Spacer()
                MCBadge(patient.status.rawValue, color: patient.status.color, style: .soft)
            }
        }
        .padding(.horizontal, MCSpacing.screenPadding)
    }

    // MARK: - Diagnosis

    private var diagnosisSection: some View {
        VStack(alignment: .leading, spacing: MCSpacing.xs) {
            sectionLabel(icon: "stethoscope", title: "DIAGNOSIS")

            TextEditor(text: $diagnosis)
                .font(MCTypography.body)
                .frame(minHeight: 80)
                .padding(MCSpacing.xs)
                .background(MCColors.backgroundLight)
                .clipShape(RoundedRectangle(cornerRadius: MCSpacing.cornerRadius))
                .overlay(
                    Group {
                        if diagnosis.isEmpty {
                            Text("Enter diagnosis...")
                                .font(MCTypography.body)
                                .foregroundStyle(MCColors.textTertiary)
                                .padding(MCSpacing.sm)
                                .allowsHitTesting(false)
                        }
                    },
                    alignment: .topLeading
                )
                .overlay(
                    RoundedRectangle(cornerRadius: MCSpacing.cornerRadius)
                        .stroke(MCColors.divider, lineWidth: 1)
                )
                .padding(.horizontal, MCSpacing.screenPadding)
        }
    }

    // MARK: - Treatment Plan

    private var treatmentSection: some View {
        VStack(alignment: .leading, spacing: MCSpacing.xs) {
            sectionLabel(icon: "list.clipboard", title: "TREATMENT PLAN")

            TextEditor(text: $treatmentPlan)
                .font(MCTypography.body)
                .frame(minHeight: 100)
                .padding(MCSpacing.xs)
                .background(MCColors.backgroundLight)
                .clipShape(RoundedRectangle(cornerRadius: MCSpacing.cornerRadius))
                .overlay(
                    Group {
                        if treatmentPlan.isEmpty {
                            Text("Enter treatment plan...")
                                .font(MCTypography.body)
                                .foregroundStyle(MCColors.textTertiary)
                                .padding(MCSpacing.sm)
                                .allowsHitTesting(false)
                        }
                    },
                    alignment: .topLeading
                )
                .overlay(
                    RoundedRectangle(cornerRadius: MCSpacing.cornerRadius)
                        .stroke(MCColors.divider, lineWidth: 1)
                )
                .padding(.horizontal, MCSpacing.screenPadding)
        }
    }

    // MARK: - Follow-Up Date

    private var followUpSection: some View {
        VStack(alignment: .leading, spacing: MCSpacing.xs) {
            sectionLabel(icon: "calendar.badge.plus", title: "FOLLOW-UP")

            MCCard {
                VStack(spacing: MCSpacing.sm) {
                    Button {
                        showFollowUpPicker.toggle()
                    } label: {
                        HStack {
                            Image(systemName: "calendar")
                                .foregroundStyle(MCColors.primaryTeal)
                            Text("Follow-up Date")
                                .font(MCTypography.subheadline)
                                .foregroundStyle(MCColors.textPrimary)
                            Spacer()
                            Text(followUpDateString)
                                .font(MCTypography.captionBold)
                                .foregroundStyle(MCColors.primaryTeal)
                            Image(systemName: showFollowUpPicker ? "chevron.up" : "chevron.down")
                                .font(.system(size: 12))
                                .foregroundStyle(MCColors.textTertiary)
                        }
                    }

                    if showFollowUpPicker {
                        DatePicker("", selection: $followUpDate, in: Date()..., displayedComponents: .date)
                            .datePickerStyle(.graphical)
                            .tint(MCColors.primaryTeal)
                    }

                    // Quick date buttons
                    HStack(spacing: MCSpacing.xs) {
                        ForEach([7, 14, 30], id: \.self) { days in
                            Button {
                                followUpDate = Calendar.current.date(byAdding: .day, value: days, to: Date()) ?? Date()
                            } label: {
                                Text("\(days) days")
                                    .font(MCTypography.captionBold)
                                    .foregroundStyle(MCColors.primaryTeal)
                                    .padding(.horizontal, MCSpacing.sm)
                                    .padding(.vertical, MCSpacing.xs)
                                    .background(MCColors.primaryTeal.opacity(0.1))
                                    .clipShape(Capsule())
                            }
                        }
                        Spacer()
                    }
                }
            }
            .padding(.horizontal, MCSpacing.screenPadding)
        }
    }

    // MARK: - Prescription Action

    private var prescriptionAction: some View {
        MCSecondaryButton("Write Prescription", icon: "doc.text") {
            showPrescription = true
        }
        .padding(.horizontal, MCSpacing.screenPadding)
    }

    // MARK: - Save Button

    private var saveButton: some View {
        VStack(spacing: MCSpacing.xs) {
            MCPrimaryButton(isSaved ? "Saved" : "Save Notes", icon: isSaved ? "checkmark.circle.fill" : "square.and.arrow.down") {
                withAnimation {
                    isSaved = true
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                    dismiss()
                }
            }
            .disabled(diagnosis.isEmpty)
            .opacity(diagnosis.isEmpty ? 0.5 : 1)
            .padding(.horizontal, MCSpacing.screenPadding)

            if diagnosis.isEmpty {
                Text("Enter a diagnosis to save")
                    .font(MCTypography.caption)
                    .foregroundStyle(MCColors.textTertiary)
            }
        }
        .padding(.bottom, MCSpacing.lg)
    }

    // MARK: - Helpers

    private func sectionLabel(icon: String, title: String) -> some View {
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

    private var followUpDateString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d, yyyy"
        return formatter.string(from: followUpDate)
    }
}

#Preview {
    ConsultationNotesView(patient: DoctorPatientData(
        id: UUID(),
        name: "Preview Patient",
        age: 45,
        avatarEmoji: "\u{1F468}",
        primaryCondition: "Hypertension",
        status: .warning,
        lastVitalLabel: "BP",
        lastVitalValue: "142/92",
        lastVitalTime: "2h ago",
        adherencePercent: 68,
        heartRate: 82,
        bpSystolic: 142,
        bpDiastolic: 92,
        spO2: 97,
        glucose: 110,
        hrTrend: .stable,
        bpTrend: .up,
        spO2Trend: .stable,
        glucoseTrend: .stable,
        medications: [],
        recentSymptoms: [],
        dailyAdherence7Days: [100, 67, 100, 33, 100, 67, 100]
    ))
}
