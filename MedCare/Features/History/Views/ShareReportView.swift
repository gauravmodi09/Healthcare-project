import SwiftUI
import SwiftData

struct ShareReportView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    let profile: UserProfile
    let episodes: [Episode]
    let healthScore: HealthScore

    @State private var selectedRange: ReportRange = .thirtyDays
    @State private var customStartDate = Calendar.current.date(byAdding: .day, value: -30, to: Date()) ?? Date()
    @State private var customEndDate = Date()
    @State private var isGenerating = false
    @State private var showShareSheet = false
    @State private var pdfURL: URL?

    private let reportService = HealthReportService()

    private var dateRange: ClosedRange<Date> {
        switch selectedRange {
        case .sevenDays:
            return (Calendar.current.date(byAdding: .day, value: -7, to: Date()) ?? Date())...Date()
        case .fourteenDays:
            return (Calendar.current.date(byAdding: .day, value: -14, to: Date()) ?? Date())...Date()
        case .thirtyDays:
            return (Calendar.current.date(byAdding: .day, value: -30, to: Date()) ?? Date())...Date()
        case .custom:
            return customStartDate...customEndDate
        }
    }

    private var allMedicines: [Medicine] {
        episodes.flatMap { $0.medicines }
    }

    private var allDoseLogs: [DoseLog] {
        allMedicines.flatMap { $0.doseLogs }
    }

    private var allSymptomLogs: [SymptomLog] {
        episodes.flatMap { $0.symptomLogs }
    }

    // Filtered stats for preview
    private var filteredDoseLogs: [DoseLog] {
        allDoseLogs.filter { dateRange.contains($0.scheduledTime) }
    }

    private var filteredSymptomLogs: [SymptomLog] {
        allSymptomLogs.filter { dateRange.contains($0.date) }
    }

    private var adherencePercent: Double {
        let total = filteredDoseLogs.count
        guard total > 0 else { return 0 }
        let taken = filteredDoseLogs.filter { $0.status == .taken }.count
        return Double(taken) / Double(total) * 100
    }

    private var activeMedicineCount: Int {
        allMedicines.filter { $0.isActive }.count
    }

    private var activeEpisodeCount: Int {
        episodes.filter { $0.status == .active || $0.status == .pendingConfirmation }.count
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: MCSpacing.sectionSpacing) {
                    dateRangeSection
                    reportPreviewSection
                    generateButton
                }
                .padding(.horizontal, MCSpacing.screenPadding)
                .padding(.vertical, MCSpacing.md)
            }
            .background(MCColors.backgroundLight.ignoresSafeArea())
            .navigationTitle("Health Report")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .foregroundStyle(MCColors.primaryTeal)
                }
            }
            .sheet(isPresented: $showShareSheet) {
                if let url = pdfURL {
                    ActivityViewRepresentable(items: [url])
                        .presentationDetents([.medium, .large])
                }
            }
        }
    }

    // MARK: - Date Range Section

    private var dateRangeSection: some View {
        VStack(alignment: .leading, spacing: MCSpacing.sm) {
            Text("REPORT PERIOD")
                .font(MCTypography.sectionHeader)
                .foregroundStyle(MCColors.textSecondary)
                .textCase(.uppercase)
                .kerning(1.2)

            VStack(spacing: MCSpacing.xs) {
                HStack(spacing: MCSpacing.xs) {
                    ForEach(ReportRange.allCases, id: \.self) { range in
                        Button {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                selectedRange = range
                            }
                        } label: {
                            Text(range.label)
                                .font(MCTypography.subheadline)
                                .foregroundStyle(selectedRange == range ? MCColors.textOnPrimary : MCColors.textPrimary)
                                .padding(.horizontal, MCSpacing.sm)
                                .padding(.vertical, MCSpacing.xs)
                                .frame(maxWidth: .infinity)
                                .background(
                                    RoundedRectangle(cornerRadius: MCSpacing.cornerRadiusSmall)
                                        .fill(selectedRange == range ? MCColors.primaryTeal : MCColors.cardBackground)
                                )
                        }
                        .buttonStyle(.plain)
                    }
                }

                if selectedRange == .custom {
                    HStack(spacing: MCSpacing.md) {
                        VStack(alignment: .leading, spacing: MCSpacing.xxs) {
                            Text("From")
                                .font(MCTypography.caption)
                                .foregroundStyle(MCColors.textSecondary)
                            DatePicker("", selection: $customStartDate, in: ...customEndDate, displayedComponents: .date)
                                .labelsHidden()
                                .tint(MCColors.primaryTeal)
                        }
                        VStack(alignment: .leading, spacing: MCSpacing.xxs) {
                            Text("To")
                                .font(MCTypography.caption)
                                .foregroundStyle(MCColors.textSecondary)
                            DatePicker("", selection: $customEndDate, in: customStartDate...Date(), displayedComponents: .date)
                                .labelsHidden()
                                .tint(MCColors.primaryTeal)
                        }
                    }
                    .padding(.top, MCSpacing.xxs)
                    .transition(.opacity.combined(with: .move(edge: .top)))
                }
            }
            .padding(MCSpacing.cardPadding)
            .background(
                RoundedRectangle(cornerRadius: MCSpacing.cornerRadius)
                    .fill(MCColors.cardBackground)
                    .shadow(color: .black.opacity(0.04), radius: 8, y: 2)
            )
        }
    }

    // MARK: - Report Preview Section

    private var reportPreviewSection: some View {
        VStack(alignment: .leading, spacing: MCSpacing.sm) {
            Text("REPORT PREVIEW")
                .font(MCTypography.sectionHeader)
                .foregroundStyle(MCColors.textSecondary)
                .textCase(.uppercase)
                .kerning(1.2)

            VStack(spacing: 0) {
                previewRow(icon: "person.text.rectangle", title: "Patient Info", detail: profile.name)
                Divider().padding(.horizontal, MCSpacing.md)
                previewRow(icon: "heart.text.square", title: "Health Score", detail: "\(healthScore.total)/100 (Grade \(healthScore.grade.rawValue))")
                Divider().padding(.horizontal, MCSpacing.md)
                previewRow(icon: "chart.bar", title: "Adherence", detail: String(format: "%.0f%% (%d doses)", adherencePercent, filteredDoseLogs.count))
                Divider().padding(.horizontal, MCSpacing.md)
                previewRow(icon: "pills", title: "Active Medications", detail: "\(activeMedicineCount)")
                Divider().padding(.horizontal, MCSpacing.md)
                previewRow(icon: "face.smiling", title: "Symptom Logs", detail: "\(filteredSymptomLogs.count) entries")
                Divider().padding(.horizontal, MCSpacing.md)
                previewRow(icon: "doc.text", title: "Active Episodes", detail: "\(activeEpisodeCount)")
                Divider().padding(.horizontal, MCSpacing.md)
                previewRow(icon: "calendar", title: "Adherence Heatmap", detail: "Visual calendar")
                Divider().padding(.horizontal, MCSpacing.md)
                previewRow(icon: "lightbulb", title: "Insights", detail: "Personalized tips")
            }
            .padding(.vertical, MCSpacing.xs)
            .background(
                RoundedRectangle(cornerRadius: MCSpacing.cornerRadius)
                    .fill(MCColors.cardBackground)
                    .shadow(color: .black.opacity(0.04), radius: 8, y: 2)
            )
        }
    }

    private func previewRow(icon: String, title: String, detail: String) -> some View {
        HStack(spacing: MCSpacing.sm) {
            Image(systemName: icon)
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(MCColors.primaryTeal)
                .frame(width: 24)

            Text(title)
                .font(MCTypography.subheadline)
                .foregroundStyle(MCColors.textPrimary)

            Spacer()

            Text(detail)
                .font(MCTypography.caption)
                .foregroundStyle(MCColors.textSecondary)
                .lineLimit(1)
        }
        .padding(.horizontal, MCSpacing.cardPadding)
        .padding(.vertical, MCSpacing.sm)
    }

    // MARK: - Generate Button

    private var generateButton: some View {
        Button {
            generateAndShare()
        } label: {
            HStack(spacing: MCSpacing.xs) {
                if isGenerating {
                    ProgressView()
                        .tint(.white)
                } else {
                    Image(systemName: "square.and.arrow.up")
                        .font(.system(size: 16, weight: .semibold))
                }
                Text(isGenerating ? "Generating..." : "Generate & Share Report")
                    .font(MCTypography.headline)
            }
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .frame(height: MCSpacing.buttonHeight)
            .background(
                RoundedRectangle(cornerRadius: MCSpacing.cornerRadius)
                    .fill(isGenerating ? MCColors.primaryTeal.opacity(0.6) : MCColors.primaryTeal)
            )
        }
        .disabled(isGenerating)
        .buttonStyle(.plain)
    }

    // MARK: - Actions

    private func generateAndShare() {
        isGenerating = true

        Task.detached { [dateRange, profile, healthScore] in
            let service = HealthReportService()
            let medicines = await MainActor.run { self.allMedicines }
            let doseLogs = await MainActor.run { self.allDoseLogs }
            let symptomLogs = await MainActor.run { self.allSymptomLogs }
            let episodes = await MainActor.run { self.episodes }

            let pdfData = service.generateReport(
                profile: profile,
                medicines: medicines,
                doseLogs: doseLogs,
                symptomLogs: symptomLogs,
                episodes: episodes,
                healthScore: healthScore,
                dateRange: dateRange
            )

            let url = service.shareReport(data: pdfData)

            await MainActor.run {
                self.isGenerating = false
                if let url {
                    self.pdfURL = url
                    self.showShareSheet = true
                }
            }
        }
    }
}

// MARK: - Report Range

enum ReportRange: String, CaseIterable {
    case sevenDays
    case fourteenDays
    case thirtyDays
    case custom

    var label: String {
        switch self {
        case .sevenDays: return "7 Days"
        case .fourteenDays: return "14 Days"
        case .thirtyDays: return "30 Days"
        case .custom: return "Custom"
        }
    }
}

// MARK: - UIActivityViewController Wrapper

struct ActivityViewRepresentable: UIViewControllerRepresentable {
    let items: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        let controller = UIActivityViewController(activityItems: items, applicationActivities: nil)
        controller.excludedActivityTypes = [.assignToContact, .addToReadingList]
        return controller
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
