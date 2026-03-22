import SwiftUI
import Charts

// MARK: - Glucose Tracking Dashboard

struct GlucoseTrackingView: View {
    let healthService: HealthKitService
    let latestReading: Double?

    @State private var glucoseHistory: [VitalDataPoint] = []
    @State private var selectedPeriod: TimePeriod = .sevenDays
    @State private var isLoading = true
    @State private var showAddReading = false
    @State private var isCGMConnected = false

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
                    // Hero current reading
                    currentReadingCard

                    // CGM badge
                    if isCGMConnected {
                        cgmBadge
                    }

                    // Period toggle
                    periodPicker

                    // Glucose chart
                    glucoseChart

                    // Time in Range ring
                    timeInRangeCard

                    // Stats row
                    statsRow

                    // Glucose-Medication Correlation
                    correlationCard

                    // Add Reading button
                    addReadingButton
                }
                .padding(.vertical, MCSpacing.md)
            }
            .background(MCColors.backgroundLight)
            .navigationTitle("Glucose Tracking")
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

    // MARK: - Current Reading Hero Card

    private var currentReadingCard: some View {
        MCCard {
            VStack(spacing: MCSpacing.sm) {
                HStack {
                    Image(systemName: "drop.fill")
                        .font(.system(size: 18))
                        .foregroundStyle(glucoseColor)

                    Text("Current Reading")
                        .font(MCTypography.subheadline)
                        .foregroundStyle(MCColors.textSecondary)

                    Spacer()

                    if let reading = latestReading {
                        Text(glucoseStageBadge(reading))
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundStyle(glucoseColorForValue(reading))
                            .padding(.horizontal, 8)
                            .padding(.vertical, 3)
                            .background(glucoseColorForValue(reading).opacity(0.12))
                            .clipShape(Capsule())
                    }
                }

                HStack(alignment: .firstTextBaseline, spacing: 4) {
                    Text(latestReading.map { "\(Int($0))" } ?? "--")
                        .font(MCTypography.heroMetric)
                        .foregroundStyle(glucoseColor)

                    Text("mg/dL")
                        .font(MCTypography.metricLabel)
                        .foregroundStyle(MCColors.textTertiary)
                }

                if let reading = latestReading {
                    Text(glucoseRangeDescription(reading))
                        .font(MCTypography.caption)
                        .foregroundStyle(MCColors.textSecondary)
                }
            }
        }
        .padding(.horizontal, MCSpacing.screenPadding)
    }

    // MARK: - CGM Badge

    private var cgmBadge: some View {
        HStack(spacing: MCSpacing.xs) {
            Image(systemName: "antenna.radiowaves.left.and.right")
                .font(.system(size: 14))
                .foregroundStyle(MCColors.primaryTeal)

            Text("FreeStyle Libre Connected")
                .font(MCTypography.captionBold)
                .foregroundStyle(MCColors.primaryTeal)

            Spacer()

            Circle()
                .fill(MCColors.success)
                .frame(width: 8, height: 8)
        }
        .padding(.horizontal, MCSpacing.md)
        .padding(.vertical, MCSpacing.xs)
        .background(MCColors.primaryTeal.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: MCSpacing.cornerRadiusSmall))
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

    // MARK: - Glucose Chart

    private var glucoseChart: some View {
        MCCard {
            VStack(alignment: .leading, spacing: MCSpacing.sm) {
                Text("\(selectedPeriod.label) Glucose Trend")
                    .font(MCTypography.subheadline)
                    .foregroundStyle(MCColors.textSecondary)

                if glucoseHistory.isEmpty {
                    Text("No readings for this period")
                        .font(MCTypography.body)
                        .foregroundStyle(MCColors.textTertiary)
                        .frame(maxWidth: .infinity)
                        .frame(height: 180)
                } else {
                    Chart {
                        // Target range band (70-180)
                        RectangleMark(
                            xStart: nil,
                            xEnd: nil,
                            yStart: .value("Low", 70),
                            yEnd: .value("High", 180)
                        )
                        .foregroundStyle(MCColors.success.opacity(0.08))

                        // Glucose line
                        ForEach(sortedHistory) { point in
                            LineMark(
                                x: .value("Time", point.date),
                                y: .value("Glucose", point.value)
                            )
                            .foregroundStyle(MCColors.primaryTeal)
                            .lineStyle(StrokeStyle(lineWidth: 2))
                            .interpolationMethod(.catmullRom)

                            AreaMark(
                                x: .value("Time", point.date),
                                y: .value("Glucose", point.value)
                            )
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [MCColors.primaryTeal.opacity(0.3), MCColors.primaryTeal.opacity(0.02)],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                            .interpolationMethod(.catmullRom)
                        }

                        // Points outside range highlighted in red
                        ForEach(outOfRangePoints) { point in
                            PointMark(
                                x: .value("Time", point.date),
                                y: .value("Glucose", point.value)
                            )
                            .foregroundStyle(MCColors.error)
                            .symbolSize(40)
                        }
                    }
                    .chartYScale(domain: chartYDomain)
                    .chartYAxis {
                        AxisMarks(position: .leading, values: [70, 100, 140, 180, 200]) { value in
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
                    .frame(height: 200)
                }
            }
        }
        .padding(.horizontal, MCSpacing.screenPadding)
    }

    // MARK: - Time in Range Ring

    private var timeInRangeCard: some View {
        MCCard {
            HStack(spacing: MCSpacing.lg) {
                // Ring
                ZStack {
                    Circle()
                        .stroke(MCColors.divider, lineWidth: 8)

                    Circle()
                        .trim(from: 0, to: timeInRangePercentage)
                        .stroke(
                            timeInRangePercentage >= 0.7 ? MCColors.success : MCColors.warning,
                            style: StrokeStyle(lineWidth: 8, lineCap: .round)
                        )
                        .rotationEffect(.degrees(-90))

                    VStack(spacing: 0) {
                        Text("\(Int(timeInRangePercentage * 100))%")
                            .font(.system(size: 20, weight: .bold, design: .rounded))
                            .foregroundStyle(MCColors.textPrimary)
                        Text("in range")
                            .font(.system(size: 10))
                            .foregroundStyle(MCColors.textTertiary)
                    }
                }
                .frame(width: 90, height: 90)

                VStack(alignment: .leading, spacing: MCSpacing.xs) {
                    Text("Time in Range")
                        .font(MCTypography.headline)
                        .foregroundStyle(MCColors.textPrimary)

                    Text("Target: 70-180 mg/dL")
                        .font(MCTypography.caption)
                        .foregroundStyle(MCColors.textSecondary)

                    HStack(spacing: MCSpacing.sm) {
                        rangeIndicator(label: "Below", percent: belowRangePercent, color: MCColors.warning)
                        rangeIndicator(label: "In Range", percent: timeInRangePercentage, color: MCColors.success)
                        rangeIndicator(label: "Above", percent: aboveRangePercent, color: MCColors.error)
                    }
                    .padding(.top, MCSpacing.xxs)
                }

                Spacer()
            }
        }
        .padding(.horizontal, MCSpacing.screenPadding)
    }

    private func rangeIndicator(label: String, percent: Double, color: Color) -> some View {
        VStack(spacing: 2) {
            Text("\(Int(percent * 100))%")
                .font(.system(size: 12, weight: .bold))
                .foregroundStyle(color)
            Text(label)
                .font(.system(size: 9))
                .foregroundStyle(MCColors.textTertiary)
        }
    }

    // MARK: - Stats Row

    private var statsRow: some View {
        HStack(spacing: MCSpacing.sm) {
            statCard(title: "Average", value: averageGlucose.map { "\(Int($0))" } ?? "--", unit: "mg/dL")
            statCard(title: "Est. HbA1c", value: estimatedHbA1c.map { String(format: "%.1f", $0) } ?? "--", unit: "%")
            statCard(title: "Readings", value: "\(glucoseHistory.count)", unit: "today")
        }
        .padding(.horizontal, MCSpacing.screenPadding)
    }

    private func statCard(title: String, value: String, unit: String) -> some View {
        MCCard {
            VStack(spacing: MCSpacing.xxs) {
                Text(title)
                    .font(.system(size: 10, weight: .medium))
                    .foregroundStyle(MCColors.textTertiary)

                Text(value)
                    .font(.system(size: 22, weight: .bold, design: .rounded))
                    .foregroundStyle(MCColors.textPrimary)

                Text(unit)
                    .font(.system(size: 10))
                    .foregroundStyle(MCColors.textTertiary)
            }
            .frame(maxWidth: .infinity)
        }
    }

    // MARK: - Correlation Card

    private var correlationCard: some View {
        MCAccentCard(accent: MCColors.info) {
            VStack(alignment: .leading, spacing: MCSpacing.xs) {
                HStack(spacing: MCSpacing.xs) {
                    Image(systemName: "waveform.path.ecg")
                        .font(.system(size: 16))
                        .foregroundStyle(MCColors.info)

                    Text("Glucose-Medication Insight")
                        .font(MCTypography.captionBold)
                        .foregroundStyle(MCColors.textPrimary)
                }

                Text("Your glucose drops avg 25 mg/dL within 2 hours of taking Glycomet")
                    .font(MCTypography.insightBody)
                    .foregroundStyle(MCColors.textSecondary)

                Text("Post-meal spikes average 45 mg/dL, returning to baseline in ~3 hours")
                    .font(MCTypography.caption)
                    .foregroundStyle(MCColors.textTertiary)
                    .padding(.top, 2)
            }
        }
        .padding(.horizontal, MCSpacing.screenPadding)
    }

    // MARK: - Add Reading Button

    private var addReadingButton: some View {
        Button {
            showAddReading = true
        } label: {
            HStack(spacing: MCSpacing.xs) {
                Image(systemName: "plus.circle.fill")
                Text("Add Glucose Reading")
            }
            .font(MCTypography.bodyMedium)
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .frame(height: MCSpacing.buttonHeight)
            .background(MCColors.primaryTeal)
            .clipShape(RoundedRectangle(cornerRadius: MCSpacing.cornerRadius))
        }
        .padding(.horizontal, MCSpacing.screenPadding)
        .padding(.bottom, MCSpacing.lg)
    }

    // MARK: - Data

    private func loadData() async {
        isLoading = true
        glucoseHistory = await healthService.fetchVitalHistory(type: .bloodGlucose, days: selectedPeriod.days)
        isLoading = false
    }

    // MARK: - Computed

    private var sortedHistory: [VitalDataPoint] {
        glucoseHistory.sorted { $0.date < $1.date }
    }

    private var outOfRangePoints: [VitalDataPoint] {
        glucoseHistory.filter { $0.value < 70 || $0.value > 180 }
    }

    private var chartYDomain: ClosedRange<Double> {
        let values = glucoseHistory.map(\.value)
        let minVal = min(values.min() ?? 50, 50)
        let maxVal = max(values.max() ?? 250, 250)
        return minVal...maxVal
    }

    private var timeInRangePercentage: Double {
        guard !glucoseHistory.isEmpty else { return 0 }
        let inRange = glucoseHistory.filter { $0.value >= 70 && $0.value <= 180 }.count
        return Double(inRange) / Double(glucoseHistory.count)
    }

    private var belowRangePercent: Double {
        guard !glucoseHistory.isEmpty else { return 0 }
        let below = glucoseHistory.filter { $0.value < 70 }.count
        return Double(below) / Double(glucoseHistory.count)
    }

    private var aboveRangePercent: Double {
        guard !glucoseHistory.isEmpty else { return 0 }
        let above = glucoseHistory.filter { $0.value > 180 }.count
        return Double(above) / Double(glucoseHistory.count)
    }

    private var averageGlucose: Double? {
        guard !glucoseHistory.isEmpty else { return nil }
        return glucoseHistory.map(\.value).reduce(0, +) / Double(glucoseHistory.count)
    }

    private var estimatedHbA1c: Double? {
        guard let avg = averageGlucose else { return nil }
        // eAG formula: HbA1c = (avg + 46.7) / 28.7
        return (avg + 46.7) / 28.7
    }

    private var glucoseColor: Color {
        guard let reading = latestReading else { return MCColors.textTertiary }
        return glucoseColorForValue(reading)
    }

    private func glucoseColorForValue(_ value: Double) -> Color {
        if value < 70 || value > 200 { return MCColors.error }
        if value > 140 { return MCColors.warning }
        return MCColors.success
    }

    private func glucoseStageBadge(_ value: Double) -> String {
        if value < 70 { return "Low" }
        if value <= 140 { return "Normal" }
        if value <= 200 { return "High" }
        return "Dangerous"
    }

    private func glucoseRangeDescription(_ value: Double) -> String {
        if value < 70 { return "Below normal range - consider a snack" }
        if value <= 140 { return "Within normal range" }
        if value <= 200 { return "Above normal - monitor closely" }
        return "Dangerously high - seek medical attention"
    }
}
