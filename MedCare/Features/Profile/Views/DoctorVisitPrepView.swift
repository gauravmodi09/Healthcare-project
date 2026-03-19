import SwiftUI

struct DoctorVisitPrepView: View {
    let profile: UserProfile
    let medicines: [MedicineInfo]
    let doseLogs: [DoseLogInfo]
    let symptomLogs: [SymptomLogInfo]
    let healthScore: HealthScore

    @State private var selectedDateRange = 14
    @State private var summary: DoctorVisitSummary?
    @State private var showShareSheet = false
    @State private var copiedToClipboard = false

    private let service = DoctorVisitPrepService()
    private let dateRangeOptions = [7, 14, 30]

    var body: some View {
        ScrollView {
            VStack(spacing: MCSpacing.sectionSpacing) {
                headerSection
                dateRangePicker
                if let summary {
                    patientInfoSection(summary.patientInfo)
                    medicationsSection(summary.medicationSummary)
                    adherenceSection(summary.adherenceOverview)
                    symptomsSection(summary.symptomSummary)
                    healthScoreSection(summary.healthScoreInfo)
                    if !summary.concerns.isEmpty {
                        concernsSection(summary.concerns)
                    }
                    questionsSection(summary.questionsToAsk)
                    actionButtons(summary)
                } else {
                    emptyState
                }
            }
            .padding(.horizontal, MCSpacing.screenPadding)
            .padding(.bottom, MCSpacing.xxl)
        }
        .background(MCColors.backgroundLight.ignoresSafeArea())
        .navigationTitle("Doctor Visit Prep")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { generateSummary() }
        .onChange(of: selectedDateRange) { _, _ in generateSummary() }
        .sheet(isPresented: $showShareSheet) {
            if let text = summary?.formattedText {
                ShareSheet(items: [text])
            }
        }
    }

    // MARK: - Header

    private var headerSection: some View {
        VStack(spacing: MCSpacing.xs) {
            Image(systemName: "stethoscope")
                .font(.system(size: 44))
                .foregroundStyle(MCColors.primaryTeal)

            Text("Prepare for Your Doctor Visit")
                .font(MCTypography.title)
                .foregroundStyle(MCColors.textPrimary)

            Text("A comprehensive summary of your health data to share with your doctor.")
                .font(MCTypography.callout)
                .foregroundStyle(MCColors.textSecondary)
                .multilineTextAlignment(.center)
        }
        .padding(.top, MCSpacing.md)
    }

    // MARK: - Date Range Picker

    private var dateRangePicker: some View {
        VStack(alignment: .leading, spacing: MCSpacing.xs) {
            Text("TIME PERIOD")
                .font(MCTypography.sectionHeader)
                .foregroundStyle(MCColors.textSecondary)
                .kerning(1.2)

            HStack(spacing: MCSpacing.xs) {
                ForEach(dateRangeOptions, id: \.self) { days in
                    Button {
                        selectedDateRange = days
                    } label: {
                        Text("Last \(days) days")
                            .font(MCTypography.subheadline)
                            .foregroundStyle(selectedDateRange == days ? MCColors.textOnPrimary : MCColors.textPrimary)
                            .padding(.horizontal, MCSpacing.md)
                            .padding(.vertical, MCSpacing.xs)
                            .background(
                                RoundedRectangle(cornerRadius: MCSpacing.cornerRadiusSmall)
                                    .fill(selectedDateRange == days ? MCColors.primaryTeal : MCColors.cardBackground)
                            )
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: - Patient Info

    private func patientInfoSection(_ info: PatientInfoSummary) -> some View {
        sectionCard(title: "Patient Information", icon: "person.fill", color: MCColors.primaryTeal) {
            VStack(alignment: .leading, spacing: MCSpacing.xs) {
                infoRow("Name", info.name)
                if let age = info.age { infoRow("Age", "\(age) years") }
                if let gender = info.gender { infoRow("Gender", gender) }
                if let blood = info.bloodGroup { infoRow("Blood Group", blood) }
                if !info.conditions.isEmpty {
                    infoRow("Conditions", info.conditions.joined(separator: ", "))
                }
                if !info.allergies.isEmpty {
                    infoRow("Allergies", info.allergies.joined(separator: ", "))
                }
            }
        }
    }

    // MARK: - Medications

    private func medicationsSection(_ meds: [MedicationAdherenceSummary]) -> some View {
        sectionCard(title: "Medications", icon: "pills.fill", color: MCColors.info) {
            VStack(spacing: MCSpacing.sm) {
                ForEach(meds) { med in
                    VStack(alignment: .leading, spacing: MCSpacing.xxs) {
                        HStack {
                            Text(med.name)
                                .font(MCTypography.bodyMedium)
                                .foregroundStyle(MCColors.textPrimary)
                            if med.isCritical {
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .font(.caption)
                                    .foregroundStyle(MCColors.warning)
                            }
                            Spacer()
                            Text("\(Int(med.adherencePercentage * 100))%")
                                .font(MCTypography.bodyMedium)
                                .foregroundStyle(adherenceColor(med.adherencePercentage))
                        }

                        if let generic = med.genericName, !generic.isEmpty {
                            Text(generic)
                                .font(MCTypography.caption)
                                .foregroundStyle(MCColors.textTertiary)
                        }

                        Text("\(med.dosage) \u{2022} \(med.frequency)")
                            .font(MCTypography.footnote)
                            .foregroundStyle(MCColors.textSecondary)

                        // Mini adherence bar
                        GeometryReader { geo in
                            ZStack(alignment: .leading) {
                                RoundedRectangle(cornerRadius: 2)
                                    .fill(MCColors.divider)
                                    .frame(height: 4)
                                RoundedRectangle(cornerRadius: 2)
                                    .fill(adherenceColor(med.adherencePercentage))
                                    .frame(width: geo.size.width * med.adherencePercentage, height: 4)
                            }
                        }
                        .frame(height: 4)
                    }
                    .padding(.vertical, MCSpacing.xxs)

                    if med.id != meds.last?.id {
                        Divider()
                            .overlay(MCColors.divider)
                    }
                }
            }
        }
    }

    // MARK: - Adherence

    private func adherenceSection(_ overview: AdherenceOverview) -> some View {
        sectionCard(title: "Adherence Overview", icon: "chart.bar.fill", color: MCColors.success) {
            VStack(spacing: MCSpacing.sm) {
                // Big percentage
                HStack {
                    VStack(alignment: .leading, spacing: MCSpacing.xxs) {
                        Text("Overall Adherence")
                            .font(MCTypography.footnote)
                            .foregroundStyle(MCColors.textSecondary)
                        Text("\(Int(overview.overallPercentage * 100))%")
                            .font(MCTypography.metric)
                            .foregroundStyle(adherenceColor(overview.overallPercentage))
                    }
                    Spacer()
                    VStack(alignment: .trailing, spacing: MCSpacing.xxs) {
                        statPill("Taken", "\(overview.takenDoses)", MCColors.success)
                        statPill("Missed", "\(overview.missedDoses)", MCColors.error)
                    }
                }

                Divider().overlay(MCColors.divider)

                if let best = overview.bestPerforming {
                    HStack {
                        Image(systemName: "arrow.up.circle.fill")
                            .foregroundStyle(MCColors.success)
                        Text("Best: \(best)")
                            .font(MCTypography.footnote)
                            .foregroundStyle(MCColors.textSecondary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }

                if let worst = overview.worstPerforming, worst != overview.bestPerforming {
                    HStack {
                        Image(systemName: "arrow.down.circle.fill")
                            .foregroundStyle(MCColors.error)
                        Text("Needs improvement: \(worst)")
                            .font(MCTypography.footnote)
                            .foregroundStyle(MCColors.textSecondary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
        }
    }

    // MARK: - Symptoms

    private func symptomsSection(_ overview: SymptomOverview) -> some View {
        sectionCard(title: "Symptoms", icon: "heart.text.clipboard.fill", color: MCColors.warning) {
            VStack(alignment: .leading, spacing: MCSpacing.sm) {
                HStack {
                    VStack(alignment: .leading, spacing: MCSpacing.xxs) {
                        Text("Trend")
                            .font(MCTypography.footnote)
                            .foregroundStyle(MCColors.textSecondary)
                        HStack(spacing: MCSpacing.xxs) {
                            Image(systemName: trendIcon(overview.trend))
                                .foregroundStyle(trendColor(overview.trend))
                            Text(overview.trend.rawValue)
                                .font(MCTypography.bodyMedium)
                                .foregroundStyle(trendColor(overview.trend))
                        }
                    }
                    Spacer()
                    VStack(alignment: .trailing, spacing: MCSpacing.xxs) {
                        Text("Logs")
                            .font(MCTypography.footnote)
                            .foregroundStyle(MCColors.textSecondary)
                        Text("\(overview.totalLogs)")
                            .font(MCTypography.headline)
                            .foregroundStyle(MCColors.textPrimary)
                    }
                }

                if !overview.mostFrequentSymptoms.isEmpty {
                    Divider().overlay(MCColors.divider)

                    Text("Most Frequent")
                        .font(MCTypography.captionBold)
                        .foregroundStyle(MCColors.textSecondary)

                    ForEach(overview.mostFrequentSymptoms, id: \.name) { symptom in
                        HStack {
                            Text(symptom.name)
                                .font(MCTypography.footnote)
                                .foregroundStyle(MCColors.textPrimary)
                            Spacer()
                            Text("\(symptom.count)x")
                                .font(MCTypography.captionBold)
                                .foregroundStyle(MCColors.textSecondary)
                                .padding(.horizontal, MCSpacing.xs)
                                .padding(.vertical, 2)
                                .background(
                                    Capsule().fill(MCColors.surface)
                                )
                        }
                    }
                }
            }
        }
    }

    // MARK: - Health Score

    private func healthScoreSection(_ score: HealthScoreOverview) -> some View {
        sectionCard(title: "Health Score", icon: "heart.circle.fill", color: Color(hex: HealthGrade.from(score: score.currentScore).color)) {
            HStack {
                VStack(alignment: .leading, spacing: MCSpacing.xxs) {
                    Text("Current Score")
                        .font(MCTypography.footnote)
                        .foregroundStyle(MCColors.textSecondary)
                    HStack(alignment: .firstTextBaseline, spacing: MCSpacing.xxs) {
                        Text("\(score.currentScore)")
                            .font(MCTypography.metric)
                            .foregroundStyle(Color(hex: HealthGrade.from(score: score.currentScore).color))
                        Text("/100")
                            .font(MCTypography.footnote)
                            .foregroundStyle(MCColors.textTertiary)
                    }
                }
                Spacer()
                VStack(spacing: MCSpacing.xxs) {
                    Text("Grade")
                        .font(MCTypography.footnote)
                        .foregroundStyle(MCColors.textSecondary)
                    Text(score.grade)
                        .font(MCTypography.title)
                        .foregroundStyle(Color(hex: HealthGrade.from(score: score.currentScore).color))
                }
                Spacer()
                VStack(spacing: MCSpacing.xxs) {
                    Text("Trend")
                        .font(MCTypography.footnote)
                        .foregroundStyle(MCColors.textSecondary)
                    Text(score.trend)
                        .font(MCTypography.subheadline)
                        .foregroundStyle(MCColors.textPrimary)
                }
            }
        }
    }

    // MARK: - Concerns

    private func concernsSection(_ concerns: [String]) -> some View {
        sectionCard(title: "Concerns", icon: "exclamationmark.triangle.fill", color: MCColors.error) {
            VStack(alignment: .leading, spacing: MCSpacing.xs) {
                ForEach(concerns, id: \.self) { concern in
                    HStack(alignment: .top, spacing: MCSpacing.xs) {
                        Image(systemName: "exclamationmark.circle.fill")
                            .font(.caption)
                            .foregroundStyle(MCColors.error)
                            .padding(.top, 2)
                        Text(concern)
                            .font(MCTypography.footnote)
                            .foregroundStyle(MCColors.textPrimary)
                    }
                }
            }
        }
    }

    // MARK: - Questions

    private func questionsSection(_ questions: [String]) -> some View {
        sectionCard(title: "Questions to Ask", icon: "questionmark.bubble.fill", color: MCColors.info) {
            VStack(alignment: .leading, spacing: MCSpacing.sm) {
                ForEach(Array(questions.enumerated()), id: \.offset) { index, question in
                    HStack(alignment: .top, spacing: MCSpacing.xs) {
                        Text("\(index + 1).")
                            .font(MCTypography.captionBold)
                            .foregroundStyle(MCColors.primaryTeal)
                            .frame(width: 20, alignment: .leading)
                        Text(question)
                            .font(MCTypography.footnote)
                            .foregroundStyle(MCColors.textPrimary)
                    }
                }
            }
        }
    }

    // MARK: - Action Buttons

    private func actionButtons(_ summary: DoctorVisitSummary) -> some View {
        VStack(spacing: MCSpacing.sm) {
            // Copy button
            Button {
                UIPasteboard.general.string = summary.formattedText
                copiedToClipboard = true
                DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                    copiedToClipboard = false
                }
            } label: {
                HStack(spacing: MCSpacing.xs) {
                    Image(systemName: copiedToClipboard ? "checkmark" : "doc.on.doc")
                    Text(copiedToClipboard ? "Copied!" : "Copy to Clipboard")
                        .font(MCTypography.bodyMedium)
                }
                .foregroundStyle(MCColors.textOnPrimary)
                .frame(maxWidth: .infinity)
                .frame(height: MCSpacing.buttonHeight)
                .background(
                    RoundedRectangle(cornerRadius: MCSpacing.cornerRadius)
                        .fill(MCColors.primaryTeal)
                )
            }

            // Share button
            Button {
                showShareSheet = true
            } label: {
                HStack(spacing: MCSpacing.xs) {
                    Image(systemName: "square.and.arrow.up")
                    Text("Share Summary")
                        .font(MCTypography.bodyMedium)
                }
                .foregroundStyle(MCColors.primaryTeal)
                .frame(maxWidth: .infinity)
                .frame(height: MCSpacing.buttonHeight)
                .background(
                    RoundedRectangle(cornerRadius: MCSpacing.cornerRadius)
                        .stroke(MCColors.primaryTeal, lineWidth: 1.5)
                )
            }
        }
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: MCSpacing.md) {
            Image(systemName: "doc.text.magnifyingglass")
                .font(.system(size: 48))
                .foregroundStyle(MCColors.textTertiary)
            Text("Generating your health summary...")
                .font(MCTypography.callout)
                .foregroundStyle(MCColors.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, MCSpacing.xxl)
    }

    // MARK: - Helpers

    private func generateSummary() {
        summary = service.prepareSummary(
            profile: profile,
            medicines: medicines,
            doseLogs: doseLogs,
            symptomLogs: symptomLogs,
            healthScore: healthScore,
            dateRange: selectedDateRange
        )
    }

    private func sectionCard<Content: View>(
        title: String,
        icon: String,
        color: Color,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: MCSpacing.sm) {
            HStack(spacing: MCSpacing.xs) {
                Image(systemName: icon)
                    .font(.subheadline)
                    .foregroundStyle(color)
                Text(title.uppercased())
                    .font(MCTypography.sectionHeader)
                    .foregroundStyle(MCColors.textSecondary)
                    .kerning(1.2)
            }

            VStack(alignment: .leading, spacing: MCSpacing.sm) {
                content()
            }
            .padding(MCSpacing.cardPadding)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: MCSpacing.cornerRadius)
                    .fill(MCColors.cardBackground)
                    .shadow(color: .black.opacity(0.04), radius: 8, y: 2)
            )
        }
    }

    private func infoRow(_ label: String, _ value: String) -> some View {
        HStack(alignment: .top) {
            Text(label)
                .font(MCTypography.footnote)
                .foregroundStyle(MCColors.textSecondary)
                .frame(width: 100, alignment: .leading)
            Text(value)
                .font(MCTypography.footnote)
                .foregroundStyle(MCColors.textPrimary)
        }
    }

    private func statPill(_ label: String, _ value: String, _ color: Color) -> some View {
        HStack(spacing: MCSpacing.xxs) {
            Text(label)
                .font(MCTypography.caption)
                .foregroundStyle(MCColors.textSecondary)
            Text(value)
                .font(MCTypography.captionBold)
                .foregroundStyle(color)
        }
    }

    private func adherenceColor(_ rate: Double) -> Color {
        switch rate {
        case 0..<0.5: return MCColors.error
        case 0.5..<0.7: return MCColors.warning
        case 0.7..<0.9: return MCColors.info
        default: return MCColors.success
        }
    }

    private func trendIcon(_ trend: SymptomTrend) -> String {
        switch trend {
        case .improving: return "arrow.up.right.circle.fill"
        case .stable: return "arrow.right.circle.fill"
        case .worsening: return "arrow.down.right.circle.fill"
        case .noData: return "questionmark.circle.fill"
        }
    }

    private func trendColor(_ trend: SymptomTrend) -> Color {
        switch trend {
        case .improving: return MCColors.success
        case .stable: return MCColors.warning
        case .worsening: return MCColors.error
        case .noData: return MCColors.textTertiary
        }
    }
}

// MARK: - Share Sheet

private struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
