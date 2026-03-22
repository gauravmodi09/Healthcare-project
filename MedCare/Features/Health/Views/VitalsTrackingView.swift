import SwiftUI
import HealthKit

// MARK: - Vitals Tracking Dashboard

struct VitalsTrackingView: View {
    @State private var healthService = HealthKitService()
    @State private var vitals = HealthKitService.LatestVitals()
    @State private var isLoading = true
    @State private var showAddVital = false
    @State private var expandedCard: VitalType?
    @State private var historyData: [VitalDataPoint] = []
    @State private var bpHistory: [BloodPressureReading] = []

    // Sparkline data (last 7 points per vital)
    @State private var hrSparkline: [VitalDataPoint] = []
    @State private var spo2Sparkline: [VitalDataPoint] = []
    @State private var weightSparkline: [VitalDataPoint] = []
    @State private var glucoseSparkline: [VitalDataPoint] = []
    @State private var stepsSparkline: [VitalDataPoint] = []
    @State private var sleepSparkline: [VitalDataPoint] = []

    private let columns = [
        GridItem(.flexible(), spacing: MCSpacing.sm),
        GridItem(.flexible(), spacing: MCSpacing.sm),
    ]

    var body: some View {
        ScrollView {
            VStack(spacing: MCSpacing.lg) {
                if isLoading {
                    loadingView
                } else if !healthService.isAuthorized {
                    authorizationPrompt
                } else {
                    vitalsGrid
                }
            }
            .padding(.vertical, MCSpacing.md)
        }
        .sheet(isPresented: $showAddVital) {
            AddVitalEntryView(healthService: healthService) {
                Task { await refreshData() }
            }
        }
        .sheet(item: $expandedCard) { vitalType in
            VitalDetailSheet(
                vitalType: vitalType,
                vitals: vitals,
                historyData: historyData,
                bpHistory: bpHistory,
                healthService: healthService
            )
            .presentationDetents([.large])
        }
        .task {
            await authorizeAndFetch()
        }
    }

    // MARK: - Loading

    private var loadingView: some View {
        VStack(spacing: MCSpacing.md) {
            ProgressView()
                .controlSize(.large)
            Text("Connecting to Apple Health...")
                .font(MCTypography.body)
                .foregroundStyle(MCColors.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, MCSpacing.xxl)
    }

    // MARK: - Authorization Prompt

    private var authorizationPrompt: some View {
        VStack(spacing: MCSpacing.lg) {
            Image(systemName: "heart.text.square.fill")
                .font(.system(size: 56))
                .foregroundStyle(MCColors.primaryTeal)

            Text("Connect Apple Health")
                .font(MCTypography.title)
                .foregroundStyle(MCColors.textPrimary)

            Text("Allow MedCare to read your vitals from Apple Health for a complete picture of your health.")
                .font(MCTypography.body)
                .foregroundStyle(MCColors.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, MCSpacing.lg)

            Button {
                Task { await authorizeAndFetch() }
            } label: {
                Text("Allow Access")
                    .font(MCTypography.bodyMedium)
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: MCSpacing.buttonHeight)
                    .background(MCColors.primaryTeal)
                    .clipShape(RoundedRectangle(cornerRadius: MCSpacing.cornerRadius))
            }
            .padding(.horizontal, MCSpacing.screenPadding)
        }
        .padding(.top, MCSpacing.xxl)
    }

    // MARK: - Vitals Grid

    private var vitalsGrid: some View {
        VStack(spacing: MCSpacing.sm) {
            // Header with Add button
            HStack {
                Text("Your Vitals")
                    .font(MCTypography.headline)
                    .foregroundStyle(MCColors.textPrimary)

                Spacer()

                Button {
                    showAddVital = true
                } label: {
                    Label("Add Entry", systemImage: "plus.circle.fill")
                        .font(MCTypography.subheadline)
                        .foregroundStyle(MCColors.primaryTeal)
                }
            }
            .padding(.horizontal, MCSpacing.screenPadding)

            LazyVGrid(columns: columns, spacing: MCSpacing.sm) {
                // Heart Rate
                VitalCard(
                    title: "Heart Rate",
                    value: vitals.heartRate.map { "\(Int($0.value))" },
                    unit: "BPM",
                    icon: "heart.fill",
                    iconColor: .red,
                    source: vitals.heartRate?.sourceDisplayName,
                    sparklineData: hrSparkline.map(\.value),
                    sparklineColor: .red
                ) {
                    loadHistoryAndExpand(.heartRate)
                }

                // SpO2
                VitalCard(
                    title: "SpO2",
                    value: vitals.spo2.map { "\(Int($0.value))" },
                    unit: "%",
                    icon: "lungs.fill",
                    iconColor: spo2Color(vitals.spo2?.value),
                    source: vitals.spo2?.sourceDisplayName,
                    sparklineData: spo2Sparkline.map(\.value),
                    sparklineColor: spo2Color(vitals.spo2?.value),
                    badge: spo2Badge(vitals.spo2?.value)
                ) {
                    loadHistoryAndExpand(.spo2)
                }

                // Blood Pressure
                VitalCard(
                    title: "Blood Pressure",
                    value: vitals.bloodPressure.map { "\(Int($0.systolic))/\(Int($0.diastolic))" },
                    unit: "mmHg",
                    icon: "heart.text.square.fill",
                    iconColor: bpColor(vitals.bloodPressure),
                    source: vitals.bloodPressure?.sourceDisplayName,
                    sparklineData: [],
                    sparklineColor: bpColor(vitals.bloodPressure),
                    badge: bpBadge(vitals.bloodPressure)
                ) {
                    loadHistoryAndExpand(.bloodPressure)
                }

                // Weight
                VitalCard(
                    title: "Weight",
                    value: vitals.weight.map { String(format: "%.1f", $0.value) },
                    unit: "kg",
                    icon: "scalemass.fill",
                    iconColor: MCColors.info,
                    source: vitals.weight?.sourceDisplayName,
                    sparklineData: weightSparkline.map(\.value),
                    sparklineColor: MCColors.info,
                    badge: weightTrendBadge()
                ) {
                    loadHistoryAndExpand(.weight)
                }

                // Blood Glucose
                VitalCard(
                    title: "Blood Glucose",
                    value: vitals.bloodGlucose.map { "\(Int($0.value))" },
                    unit: "mg/dL",
                    icon: "drop.fill",
                    iconColor: glucoseColor(vitals.bloodGlucose?.value),
                    source: vitals.bloodGlucose?.sourceDisplayName,
                    sparklineData: glucoseSparkline.map(\.value),
                    sparklineColor: glucoseColor(vitals.bloodGlucose?.value),
                    badge: glucoseBadge(vitals.bloodGlucose?.value)
                ) {
                    loadHistoryAndExpand(.bloodGlucose)
                }

                // Steps
                StepsVitalCard(
                    steps: Int(vitals.steps?.value ?? 0),
                    sparklineData: stepsSparkline.map(\.value)
                ) {
                    loadHistoryAndExpand(.steps)
                }

                // Sleep — full width
                SleepVitalCard(
                    hours: vitals.sleep?.value,
                    sparklineData: sleepSparkline.map(\.value)
                ) {
                    loadHistoryAndExpand(.sleep)
                }
            }
            .padding(.horizontal, MCSpacing.screenPadding)
        }
    }

    // MARK: - Actions

    private func authorizeAndFetch() async {
        do {
            try await healthService.requestAuthorization()
        } catch {
            print("HealthKit auth error: \(error.localizedDescription)")
        }
        await refreshData()
        isLoading = false
    }

    private func refreshData() async {
        vitals = await healthService.fetchLatestVitals()

        // Fetch sparkline data in parallel
        async let hr = healthService.fetchVitalHistory(type: .heartRate, days: 7)
        async let sp = healthService.fetchVitalHistory(type: .spo2, days: 7)
        async let wt = healthService.fetchVitalHistory(type: .weight, days: 30)
        async let gl = healthService.fetchVitalHistory(type: .bloodGlucose, days: 7)
        async let st = healthService.fetchVitalHistory(type: .steps, days: 7)
        async let sl = healthService.fetchVitalHistory(type: .sleep, days: 7)

        hrSparkline = Array((await hr).prefix(7))
        spo2Sparkline = Array((await sp).prefix(7))
        weightSparkline = Array((await wt).prefix(7))
        glucoseSparkline = Array((await gl).prefix(7))
        stepsSparkline = Array((await st).prefix(7))
        sleepSparkline = Array((await sl).prefix(7))
    }

    private func loadHistoryAndExpand(_ type: VitalType) {
        Task {
            historyData = await healthService.fetchVitalHistory(type: type, days: 30)
            if type == .bloodPressure {
                bpHistory = await healthService.fetchBloodPressureHistory(days: 30)
            }
            expandedCard = type
        }
    }

    // MARK: - Color/Badge Helpers

    private func spo2Color(_ value: Double?) -> Color {
        guard let v = value else { return MCColors.textTertiary }
        if v > 95 { return MCColors.success }
        if v >= 90 { return MCColors.warning }
        return MCColors.error
    }

    private func spo2Badge(_ value: Double?) -> VitalBadge? {
        guard let v = value else { return nil }
        if v > 95 { return VitalBadge(text: "Normal", color: MCColors.success) }
        if v >= 90 { return VitalBadge(text: "Low", color: MCColors.warning) }
        return VitalBadge(text: "Critical", color: MCColors.error)
    }

    private func bpColor(_ bp: BloodPressureReading?) -> Color {
        guard let bp else { return MCColors.textTertiary }
        let sys = bp.systolic
        if sys < 120 { return MCColors.success }
        if sys < 130 { return MCColors.warning }
        if sys < 140 { return Color.orange }
        if sys < 180 { return MCColors.error }
        return MCColors.error
    }

    private func bpBadge(_ bp: BloodPressureReading?) -> VitalBadge? {
        guard let bp else { return nil }
        let sys = bp.systolic
        let dia = bp.diastolic
        if sys < 120 && dia < 80 { return VitalBadge(text: "Normal", color: MCColors.success) }
        if sys < 130 && dia < 80 { return VitalBadge(text: "Elevated", color: MCColors.warning) }
        if sys < 140 || dia < 90 { return VitalBadge(text: "Stage 1", color: Color.orange) }
        if sys < 180 || dia < 120 { return VitalBadge(text: "Stage 2", color: MCColors.error) }
        return VitalBadge(text: "Crisis", color: MCColors.error)
    }

    private func weightTrendBadge() -> VitalBadge? {
        guard weightSparkline.count >= 2 else { return nil }
        let sorted = weightSparkline.sorted { $0.date < $1.date }
        let first = sorted.first!.value
        let last = sorted.last!.value
        let diff = last - first
        if abs(diff) < 0.3 { return VitalBadge(text: "Stable \u{2192}", color: MCColors.info) }
        if diff > 0 { return VitalBadge(text: "Gaining \u{2191}", color: MCColors.warning) }
        return VitalBadge(text: "Losing \u{2193}", color: MCColors.success)
    }

    private func glucoseColor(_ value: Double?) -> Color {
        guard let v = value else { return MCColors.textTertiary }
        if v < 70 { return MCColors.warning }
        if v <= 100 { return MCColors.success }
        if v <= 125 { return MCColors.warning }
        return MCColors.error
    }

    private func glucoseBadge(_ value: Double?) -> VitalBadge? {
        guard let v = value else { return nil }
        if v < 70 { return VitalBadge(text: "Low", color: MCColors.warning) }
        if v <= 100 { return VitalBadge(text: "Normal", color: MCColors.success) }
        if v <= 125 { return VitalBadge(text: "Pre-diabetic", color: MCColors.warning) }
        return VitalBadge(text: "High", color: MCColors.error)
    }
}

// MARK: - Badge Model

struct VitalBadge {
    let text: String
    let color: Color
}

// MARK: - Generic Vital Card

private struct VitalCard: View {
    let title: String
    let value: String?
    let unit: String
    let icon: String
    let iconColor: Color
    let source: String?
    let sparklineData: [Double]
    let sparklineColor: Color
    var badge: VitalBadge? = nil
    let onTap: () -> Void

    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: MCSpacing.xs) {
                // Header
                HStack(spacing: MCSpacing.xxs) {
                    Image(systemName: icon)
                        .font(.system(size: 14))
                        .foregroundStyle(iconColor)
                    Text(title)
                        .font(MCTypography.caption)
                        .foregroundStyle(MCColors.textSecondary)
                    Spacer()
                }

                // Value
                if let value {
                    HStack(alignment: .firstTextBaseline, spacing: 2) {
                        Text(value)
                            .font(.system(size: 26, weight: .bold, design: .rounded))
                            .foregroundStyle(MCColors.textPrimary)
                        Text(unit)
                            .font(MCTypography.caption)
                            .foregroundStyle(MCColors.textTertiary)
                    }
                } else {
                    Text("--")
                        .font(.system(size: 26, weight: .bold, design: .rounded))
                        .foregroundStyle(MCColors.textTertiary)
                }

                // Sparkline
                if !sparklineData.isEmpty {
                    SparklineView(data: sparklineData, color: sparklineColor)
                        .frame(height: 28)
                }

                // Badge + Source
                HStack(spacing: MCSpacing.xxs) {
                    if let badge {
                        Text(badge.text)
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundStyle(badge.color)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(badge.color.opacity(0.12))
                            .clipShape(Capsule())
                    }

                    Spacer()

                    if let source {
                        Text(source)
                            .font(.system(size: 9))
                            .foregroundStyle(MCColors.textTertiary)
                    }
                }
            }
            .padding(MCSpacing.sm)
            .background(MCColors.cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: MCSpacing.cornerRadius))
            .shadow(color: .black.opacity(colorScheme == .dark ? 0.2 : 0.06), radius: 8, y: 2)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Steps Card (with progress ring)

private struct StepsVitalCard: View {
    let steps: Int
    let sparklineData: [Double]
    let onTap: () -> Void

    private let goal: Double = 10000

    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: MCSpacing.xs) {
                HStack(spacing: MCSpacing.xxs) {
                    Image(systemName: "figure.walk")
                        .font(.system(size: 14))
                        .foregroundStyle(MCColors.primaryTeal)
                    Text("Steps")
                        .font(MCTypography.caption)
                        .foregroundStyle(MCColors.textSecondary)
                    Spacer()
                }

                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("\(steps)")
                            .font(.system(size: 26, weight: .bold, design: .rounded))
                            .foregroundStyle(MCColors.textPrimary)
                        Text("of 10K goal")
                            .font(.system(size: 10))
                            .foregroundStyle(MCColors.textTertiary)
                    }

                    Spacer()

                    // Progress ring
                    ZStack {
                        Circle()
                            .stroke(MCColors.divider, lineWidth: 5)
                        Circle()
                            .trim(from: 0, to: min(Double(steps) / goal, 1.0))
                            .stroke(MCColors.primaryTeal, style: StrokeStyle(lineWidth: 5, lineCap: .round))
                            .rotationEffect(.degrees(-90))
                        Text("\(Int(min(Double(steps) / goal, 1.0) * 100))%")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundStyle(MCColors.primaryTeal)
                    }
                    .frame(width: 44, height: 44)
                }

                if !sparklineData.isEmpty {
                    SparklineView(data: sparklineData, color: MCColors.primaryTeal)
                        .frame(height: 28)
                }
            }
            .padding(MCSpacing.sm)
            .background(MCColors.cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: MCSpacing.cornerRadius))
            .shadow(color: .black.opacity(colorScheme == .dark ? 0.2 : 0.06), radius: 8, y: 2)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Sleep Card

private struct SleepVitalCard: View {
    let hours: Double?
    let sparklineData: [Double]
    let onTap: () -> Void

    @Environment(\.colorScheme) private var colorScheme

    private var qualityIndicator: (text: String, color: Color) {
        guard let h = hours else { return ("No data", MCColors.textTertiary) }
        if h >= 7 { return ("Good", MCColors.success) }
        if h >= 5 { return ("Fair", MCColors.warning) }
        return ("Poor", MCColors.error)
    }

    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: MCSpacing.xs) {
                HStack(spacing: MCSpacing.xxs) {
                    Image(systemName: "moon.zzz.fill")
                        .font(.system(size: 14))
                        .foregroundStyle(.indigo)
                    Text("Sleep")
                        .font(MCTypography.caption)
                        .foregroundStyle(MCColors.textSecondary)
                    Spacer()

                    let q = qualityIndicator
                    Text(q.text)
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundStyle(q.color)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(q.color.opacity(0.12))
                        .clipShape(Capsule())
                }

                HStack {
                    if let hours {
                        HStack(alignment: .firstTextBaseline, spacing: 2) {
                            Text(String(format: "%.1f", hours))
                                .font(.system(size: 26, weight: .bold, design: .rounded))
                                .foregroundStyle(MCColors.textPrimary)
                            Text("hrs")
                                .font(MCTypography.caption)
                                .foregroundStyle(MCColors.textTertiary)
                        }
                    } else {
                        Text("--")
                            .font(.system(size: 26, weight: .bold, design: .rounded))
                            .foregroundStyle(MCColors.textTertiary)
                    }

                    Spacer()

                    if !sparklineData.isEmpty {
                        SparklineView(data: sparklineData, color: .indigo)
                            .frame(width: 80, height: 28)
                    }
                }

                Text("Last night")
                    .font(.system(size: 9))
                    .foregroundStyle(MCColors.textTertiary)
            }
            .padding(MCSpacing.sm)
            .background(MCColors.cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: MCSpacing.cornerRadius))
            .shadow(color: .black.opacity(colorScheme == .dark ? 0.2 : 0.06), radius: 8, y: 2)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Sparkline View

struct SparklineView: View {
    let data: [Double]
    let color: Color

    var body: some View {
        GeometryReader { geo in
            if data.count >= 2 {
                let minVal = data.min() ?? 0
                let maxVal = data.max() ?? 1
                let range = max(maxVal - minVal, 0.001)

                Path { path in
                    for (index, value) in data.enumerated() {
                        let x = geo.size.width * CGFloat(index) / CGFloat(data.count - 1)
                        let y = geo.size.height * (1 - CGFloat((value - minVal) / range))

                        if index == 0 {
                            path.move(to: CGPoint(x: x, y: y))
                        } else {
                            path.addLine(to: CGPoint(x: x, y: y))
                        }
                    }
                }
                .stroke(color, style: StrokeStyle(lineWidth: 2, lineCap: .round, lineJoin: .round))

                // Fill gradient
                Path { path in
                    for (index, value) in data.enumerated() {
                        let x = geo.size.width * CGFloat(index) / CGFloat(data.count - 1)
                        let y = geo.size.height * (1 - CGFloat((value - minVal) / range))

                        if index == 0 {
                            path.move(to: CGPoint(x: x, y: y))
                        } else {
                            path.addLine(to: CGPoint(x: x, y: y))
                        }
                    }
                    path.addLine(to: CGPoint(x: geo.size.width, y: geo.size.height))
                    path.addLine(to: CGPoint(x: 0, y: geo.size.height))
                    path.closeSubpath()
                }
                .fill(LinearGradient(colors: [color.opacity(0.3), color.opacity(0.0)], startPoint: .top, endPoint: .bottom))
            }
        }
    }
}

// MARK: - Vital Detail Sheet

private struct VitalDetailSheet: View {
    let vitalType: VitalType
    let vitals: HealthKitService.LatestVitals
    let historyData: [VitalDataPoint]
    let bpHistory: [BloodPressureReading]
    let healthService: HealthKitService

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: MCSpacing.lg) {
                    // Chart
                    if vitalType == .bloodPressure && !bpHistory.isEmpty {
                        bpChartView
                    } else if !historyData.isEmpty {
                        chartView
                    } else {
                        MCEmptyState(
                            icon: vitalType.icon,
                            title: "No history yet",
                            message: "Start tracking your \(vitalType.rawValue.lowercased()) to see trends over time.",
                            iconColor: MCColors.primaryTeal
                        )
                        .padding(.top, MCSpacing.xl)
                    }

                    // History list
                    if vitalType == .bloodPressure {
                        bpHistoryList
                    } else if !historyData.isEmpty {
                        historyList
                    }
                }
                .padding(.vertical, MCSpacing.md)
            }
            .background(MCColors.backgroundLight)
            .navigationTitle(vitalType.rawValue)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                        .foregroundStyle(MCColors.primaryTeal)
                }
            }
        }
    }

    private var chartView: some View {
        MCCard {
            VStack(alignment: .leading, spacing: MCSpacing.sm) {
                Text("Last 30 days")
                    .font(MCTypography.subheadline)
                    .foregroundStyle(MCColors.textSecondary)

                SparklineView(
                    data: historyData.reversed().map(\.value),
                    color: MCColors.primaryTeal
                )
                .frame(height: 120)
            }
        }
        .padding(.horizontal, MCSpacing.screenPadding)
    }

    private var bpChartView: some View {
        MCCard {
            VStack(alignment: .leading, spacing: MCSpacing.sm) {
                Text("Blood Pressure History")
                    .font(MCTypography.subheadline)
                    .foregroundStyle(MCColors.textSecondary)

                SparklineView(
                    data: bpHistory.reversed().map(\.systolic),
                    color: MCColors.error
                )
                .frame(height: 120)
            }
        }
        .padding(.horizontal, MCSpacing.screenPadding)
    }

    private var historyList: some View {
        VStack(alignment: .leading, spacing: MCSpacing.sm) {
            Text("Readings")
                .font(MCTypography.headline)
                .foregroundStyle(MCColors.textPrimary)
                .padding(.horizontal, MCSpacing.screenPadding)

            ForEach(historyData.prefix(20)) { point in
                MCCard {
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("\(formatValue(point.value)) \(vitalType.unit)")
                                .font(MCTypography.bodyMedium)
                                .foregroundStyle(MCColors.textPrimary)
                            Text(point.date.formatted(date: .abbreviated, time: .shortened))
                                .font(MCTypography.caption)
                                .foregroundStyle(MCColors.textSecondary)
                        }
                        Spacer()
                        Text(point.sourceDisplayName)
                            .font(MCTypography.caption)
                            .foregroundStyle(MCColors.textTertiary)
                    }
                }
                .padding(.horizontal, MCSpacing.screenPadding)
            }
        }
    }

    private var bpHistoryList: some View {
        VStack(alignment: .leading, spacing: MCSpacing.sm) {
            Text("Readings")
                .font(MCTypography.headline)
                .foregroundStyle(MCColors.textPrimary)
                .padding(.horizontal, MCSpacing.screenPadding)

            ForEach(bpHistory.prefix(20)) { reading in
                MCCard {
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("\(Int(reading.systolic))/\(Int(reading.diastolic)) mmHg")
                                .font(MCTypography.bodyMedium)
                                .foregroundStyle(MCColors.textPrimary)
                            Text(reading.date.formatted(date: .abbreviated, time: .shortened))
                                .font(MCTypography.caption)
                                .foregroundStyle(MCColors.textSecondary)
                        }
                        Spacer()
                        Text(reading.sourceDisplayName)
                            .font(MCTypography.caption)
                            .foregroundStyle(MCColors.textTertiary)
                    }
                }
                .padding(.horizontal, MCSpacing.screenPadding)
            }
        }
    }

    private func formatValue(_ value: Double) -> String {
        if value == value.rounded() {
            return "\(Int(value))"
        }
        return String(format: "%.1f", value)
    }
}
