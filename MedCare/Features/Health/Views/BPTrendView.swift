import SwiftUI
import Charts

// MARK: - Blood Pressure Trend View

struct BPTrendView: View {
    let healthService: HealthKitService
    let latestBP: BloodPressureReading?

    @State private var bpHistory: [BloodPressureReading] = []
    @State private var selectedPeriod: TimePeriod = .sevenDays
    @State private var isLoading = true
    @State private var showAddReading = false

    enum TimePeriod: String, CaseIterable, Identifiable {
        case sevenDays = "7D"
        case thirtyDays = "30D"
        case ninetyDays = "90D"

        var id: String { rawValue }

        var days: Int {
            switch self {
            case .sevenDays: return 7
            case .thirtyDays: return 30
            case .ninetyDays: return 90
            }
        }

        var label: String {
            switch self {
            case .sevenDays: return "7 Days"
            case .thirtyDays: return "30 Days"
            case .ninetyDays: return "90 Days"
            }
        }
    }

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: MCSpacing.lg) {
                    // Hero latest reading
                    latestReadingCard

                    // Period toggle
                    periodPicker

                    // BP Chart
                    bpChart

                    // Stats cards
                    statsSection

                    // History list
                    historySection
                }
                .padding(.vertical, MCSpacing.md)
            }
            .background(MCColors.backgroundLight)
            .navigationTitle("Blood Pressure")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                        .foregroundStyle(MCColors.primaryTeal)
                }
            }
            .sheet(isPresented: $showAddReading) {
                AddVitalEntryView(healthService: healthService) {
                    Task { await loadData() }
                }
            }
            .task {
                await loadData()
            }
        }
    }

    // MARK: - Latest Reading Hero

    private var latestReadingCard: some View {
        MCCard {
            VStack(spacing: MCSpacing.sm) {
                HStack {
                    Image(systemName: "heart.text.square.fill")
                        .font(.system(size: 18))
                        .foregroundStyle(bpAccentColor)

                    Text("Latest Reading")
                        .font(MCTypography.subheadline)
                        .foregroundStyle(MCColors.textSecondary)

                    Spacer()

                    if let bp = latestBP {
                        Text(bpStageLabel(systolic: bp.systolic, diastolic: bp.diastolic))
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundStyle(bpStageColor(systolic: bp.systolic, diastolic: bp.diastolic))
                            .padding(.horizontal, 8)
                            .padding(.vertical, 3)
                            .background(bpStageColor(systolic: bp.systolic, diastolic: bp.diastolic).opacity(0.12))
                            .clipShape(Capsule())
                    }
                }

                HStack(alignment: .firstTextBaseline, spacing: 4) {
                    if let bp = latestBP {
                        Text("\(Int(bp.systolic))/\(Int(bp.diastolic))")
                            .font(MCTypography.heroMetric)
                            .foregroundStyle(bpAccentColor)
                    } else {
                        Text("--/--")
                            .font(MCTypography.heroMetric)
                            .foregroundStyle(MCColors.textTertiary)
                    }

                    Text("mmHg")
                        .font(MCTypography.metricLabel)
                        .foregroundStyle(MCColors.textTertiary)
                }

                if let bp = latestBP {
                    Text(bp.date.formatted(date: .abbreviated, time: .shortened))
                        .font(MCTypography.caption)
                        .foregroundStyle(MCColors.textSecondary)
                }
            }
        }
        .padding(.horizontal, MCSpacing.screenPadding)
    }

    // MARK: - Period Picker

    private var periodPicker: some View {
        HStack(spacing: MCSpacing.xxs) {
            ForEach(TimePeriod.allCases) { period in
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        selectedPeriod = period
                    }
                    Task { await loadData() }
                } label: {
                    Text(period.rawValue)
                        .font(MCTypography.captionBold)
                        .foregroundStyle(selectedPeriod == period ? .white : MCColors.textSecondary)
                        .padding(.horizontal, MCSpacing.md)
                        .padding(.vertical, MCSpacing.xs)
                        .background(selectedPeriod == period ? MCColors.primaryTeal : MCColors.cardBackground)
                        .clipShape(Capsule())
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, MCSpacing.screenPadding)
    }

    // MARK: - BP Chart

    private var bpChart: some View {
        MCCard {
            VStack(alignment: .leading, spacing: MCSpacing.sm) {
                Text("\(selectedPeriod.label) Blood Pressure")
                    .font(MCTypography.subheadline)
                    .foregroundStyle(MCColors.textSecondary)

                if sortedHistory.isEmpty {
                    Text("No readings for this period")
                        .font(MCTypography.body)
                        .foregroundStyle(MCColors.textTertiary)
                        .frame(maxWidth: .infinity)
                        .frame(height: 200)
                } else {
                    Chart {
                        // Hypertension zone bands
                        // Normal (<120/80) - Green
                        RectangleMark(yStart: .value("", 0), yEnd: .value("", 80))
                            .foregroundStyle(MCColors.success.opacity(0.05))

                        // Elevated (120-129) - Yellow
                        RectangleMark(yStart: .value("", 120), yEnd: .value("", 129))
                            .foregroundStyle(MCColors.warning.opacity(0.06))

                        // Stage 1 (130-139) - Orange
                        RectangleMark(yStart: .value("", 130), yEnd: .value("", 139))
                            .foregroundStyle(Color.orange.opacity(0.06))

                        // Stage 2 (140-180) - Red
                        RectangleMark(yStart: .value("", 140), yEnd: .value("", 180))
                            .foregroundStyle(MCColors.error.opacity(0.06))

                        // Crisis (>180) - Dark red
                        RectangleMark(yStart: .value("", 180), yEnd: .value("", 220))
                            .foregroundStyle(Color(hex: "991B1B").opacity(0.06))

                        // Systolic line (teal)
                        ForEach(sortedHistory) { reading in
                            LineMark(
                                x: .value("Date", reading.date),
                                y: .value("Systolic", reading.systolic),
                                series: .value("Type", "Systolic")
                            )
                            .foregroundStyle(MCColors.primaryTeal)
                            .lineStyle(StrokeStyle(lineWidth: 2.5))
                            .interpolationMethod(.catmullRom)

                            PointMark(
                                x: .value("Date", reading.date),
                                y: .value("Systolic", reading.systolic)
                            )
                            .foregroundStyle(MCColors.primaryTeal)
                            .symbolSize(20)
                        }

                        // Diastolic line (coral)
                        ForEach(sortedHistory) { reading in
                            LineMark(
                                x: .value("Date", reading.date),
                                y: .value("Diastolic", reading.diastolic),
                                series: .value("Type", "Diastolic")
                            )
                            .foregroundStyle(MCColors.accentCoral)
                            .lineStyle(StrokeStyle(lineWidth: 2.5))
                            .interpolationMethod(.catmullRom)

                            PointMark(
                                x: .value("Date", reading.date),
                                y: .value("Diastolic", reading.diastolic)
                            )
                            .foregroundStyle(MCColors.accentCoral)
                            .symbolSize(20)
                        }
                    }
                    .chartYScale(domain: chartYDomain)
                    .chartYAxis {
                        AxisMarks(position: .leading, values: [60, 80, 100, 120, 140, 160, 180]) { value in
                            AxisValueLabel()
                                .font(.system(size: 10))
                                .foregroundStyle(MCColors.textTertiary)
                            AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5, dash: [4, 4]))
                                .foregroundStyle(MCColors.divider)
                        }
                    }
                    .chartXAxis {
                        AxisMarks(preset: .aligned) { _ in
                            AxisValueLabel(format: .dateTime.month(.abbreviated).day())
                                .font(.system(size: 9))
                                .foregroundStyle(MCColors.textTertiary)
                        }
                    }
                    .frame(height: 220)

                    // Legend
                    HStack(spacing: MCSpacing.md) {
                        legendItem(color: MCColors.primaryTeal, label: "Systolic")
                        legendItem(color: MCColors.accentCoral, label: "Diastolic")
                    }
                    .padding(.top, MCSpacing.xxs)
                }
            }
        }
        .padding(.horizontal, MCSpacing.screenPadding)
    }

    private func legendItem(color: Color, label: String) -> some View {
        HStack(spacing: 4) {
            Circle()
                .fill(color)
                .frame(width: 8, height: 8)
            Text(label)
                .font(.system(size: 11))
                .foregroundStyle(MCColors.textSecondary)
        }
    }

    // MARK: - Stats Section

    private var statsSection: some View {
        VStack(alignment: .leading, spacing: MCSpacing.sm) {
            Text("Statistics")
                .font(MCTypography.headline)
                .foregroundStyle(MCColors.textPrimary)
                .padding(.horizontal, MCSpacing.screenPadding)

            HStack(spacing: MCSpacing.sm) {
                bpStatCard(
                    title: "Average",
                    systolic: avgSystolic,
                    diastolic: avgDiastolic
                )
                bpStatCard(
                    title: "Min",
                    systolic: minSystolic,
                    diastolic: minDiastolic
                )
                bpStatCard(
                    title: "Max",
                    systolic: maxSystolic,
                    diastolic: maxDiastolic
                )
            }
            .padding(.horizontal, MCSpacing.screenPadding)
        }
    }

    private func bpStatCard(title: String, systolic: Int?, diastolic: Int?) -> some View {
        MCCard {
            VStack(spacing: MCSpacing.xxs) {
                Text(title)
                    .font(.system(size: 10, weight: .medium))
                    .foregroundStyle(MCColors.textTertiary)

                if let sys = systolic, let dia = diastolic {
                    Text("\(sys)/\(dia)")
                        .font(.system(size: 18, weight: .bold, design: .rounded))
                        .foregroundStyle(MCColors.textPrimary)
                } else {
                    Text("--/--")
                        .font(.system(size: 18, weight: .bold, design: .rounded))
                        .foregroundStyle(MCColors.textTertiary)
                }

                Text("mmHg")
                    .font(.system(size: 10))
                    .foregroundStyle(MCColors.textTertiary)
            }
            .frame(maxWidth: .infinity)
        }
    }

    // MARK: - History Section

    private var historySection: some View {
        VStack(alignment: .leading, spacing: MCSpacing.sm) {
            HStack {
                Text("History")
                    .font(MCTypography.headline)
                    .foregroundStyle(MCColors.textPrimary)

                Spacer()

                Button {
                    showAddReading = true
                } label: {
                    Label("Add", systemImage: "plus.circle.fill")
                        .font(MCTypography.subheadline)
                        .foregroundStyle(MCColors.primaryTeal)
                }
            }
            .padding(.horizontal, MCSpacing.screenPadding)

            if bpHistory.isEmpty {
                MCCard {
                    HStack {
                        Spacer()
                        Text("No readings yet")
                            .font(MCTypography.body)
                            .foregroundStyle(MCColors.textTertiary)
                        Spacer()
                    }
                }
                .padding(.horizontal, MCSpacing.screenPadding)
            } else {
                ForEach(bpHistory.prefix(20)) { reading in
                    MCCard {
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                HStack(alignment: .firstTextBaseline, spacing: 4) {
                                    Text("\(Int(reading.systolic))/\(Int(reading.diastolic))")
                                        .font(MCTypography.bodyMedium)
                                        .foregroundStyle(MCColors.textPrimary)

                                    Text("mmHg")
                                        .font(MCTypography.caption)
                                        .foregroundStyle(MCColors.textTertiary)
                                }

                                Text(reading.date.formatted(date: .abbreviated, time: .shortened))
                                    .font(MCTypography.caption)
                                    .foregroundStyle(MCColors.textSecondary)
                            }

                            Spacer()

                            Text(bpStageLabel(systolic: reading.systolic, diastolic: reading.diastolic))
                                .font(.system(size: 10, weight: .semibold))
                                .foregroundStyle(bpStageColor(systolic: reading.systolic, diastolic: reading.diastolic))
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(bpStageColor(systolic: reading.systolic, diastolic: reading.diastolic).opacity(0.12))
                                .clipShape(Capsule())
                        }
                    }
                    .padding(.horizontal, MCSpacing.screenPadding)
                }
            }
        }
        .padding(.bottom, MCSpacing.lg)
    }

    // MARK: - Data Loading

    private func loadData() async {
        isLoading = true
        bpHistory = await healthService.fetchBloodPressureHistory(days: selectedPeriod.days)
        isLoading = false
    }

    // MARK: - Computed

    private var sortedHistory: [BloodPressureReading] {
        bpHistory.sorted { $0.date < $1.date }
    }

    private var chartYDomain: ClosedRange<Double> {
        guard !bpHistory.isEmpty else { return 40...200 }
        let allValues = bpHistory.flatMap { [$0.systolic, $0.diastolic] }
        let minVal = max((allValues.min() ?? 40) - 10, 30)
        let maxVal = min((allValues.max() ?? 200) + 20, 250)
        return minVal...maxVal
    }

    private var bpAccentColor: Color {
        guard let bp = latestBP else { return MCColors.textTertiary }
        return bpStageColor(systolic: bp.systolic, diastolic: bp.diastolic)
    }

    private var avgSystolic: Int? {
        guard !bpHistory.isEmpty else { return nil }
        return Int(bpHistory.map(\.systolic).reduce(0, +) / Double(bpHistory.count))
    }

    private var avgDiastolic: Int? {
        guard !bpHistory.isEmpty else { return nil }
        return Int(bpHistory.map(\.diastolic).reduce(0, +) / Double(bpHistory.count))
    }

    private var minSystolic: Int? {
        guard !bpHistory.isEmpty else { return nil }
        return Int(bpHistory.map(\.systolic).min() ?? 0)
    }

    private var minDiastolic: Int? {
        guard !bpHistory.isEmpty else { return nil }
        return Int(bpHistory.map(\.diastolic).min() ?? 0)
    }

    private var maxSystolic: Int? {
        guard !bpHistory.isEmpty else { return nil }
        return Int(bpHistory.map(\.systolic).max() ?? 0)
    }

    private var maxDiastolic: Int? {
        guard !bpHistory.isEmpty else { return nil }
        return Int(bpHistory.map(\.diastolic).max() ?? 0)
    }

    // MARK: - BP Classification Helpers

    private func bpStageLabel(systolic: Double, diastolic: Double) -> String {
        if systolic > 180 || diastolic > 120 { return "Crisis" }
        if systolic >= 140 || diastolic >= 90 { return "Stage 2" }
        if systolic >= 130 || diastolic >= 80 { return "Stage 1" }
        if systolic >= 120 && diastolic < 80 { return "Elevated" }
        return "Normal"
    }

    private func bpStageColor(systolic: Double, diastolic: Double) -> Color {
        if systolic > 180 || diastolic > 120 { return Color(hex: "991B1B") }
        if systolic >= 140 || diastolic >= 90 { return MCColors.error }
        if systolic >= 130 || diastolic >= 80 { return Color.orange }
        if systolic >= 120 && diastolic < 80 { return MCColors.warning }
        return MCColors.success
    }
}
