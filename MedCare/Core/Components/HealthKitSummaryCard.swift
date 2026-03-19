import SwiftUI

struct HealthKitSummaryCard: View {
    let service: HealthKitService

    @State private var steps: Int = 0
    @State private var heartRate: Double?
    @State private var sleepHours: Double?
    @State private var isLoading = false

    var body: some View {
        Group {
            if service.isAuthorized {
                authorizedContent
            } else {
                connectButton
            }
        }
        .padding()
        .background(MCColors.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
    }

    // MARK: - Authorized Content

    private var authorizedContent: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "heart.fill")
                    .foregroundStyle(MCColors.accentCoral)
                Text("Apple Health")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(MCColors.textPrimary)
                Spacer()
            }

            HStack(spacing: 0) {
                metricItem(
                    icon: "figure.walk",
                    value: formatSteps(steps),
                    label: "Steps",
                    color: MCColors.primaryTeal
                )

                Spacer()

                metricItem(
                    icon: "heart.fill",
                    value: heartRate.map { "\(Int($0))" } ?? "--",
                    label: "BPM",
                    color: MCColors.accentCoral
                )

                Spacer()

                metricItem(
                    icon: "moon.fill",
                    value: sleepHours.map { String(format: "%.1f", $0) } ?? "--",
                    label: "Hours",
                    color: MCColors.info
                )
            }
        }
        .overlay {
            if isLoading {
                ProgressView()
                    .tint(MCColors.primaryTeal)
            }
        }
        .task {
            await loadData()
        }
    }

    // MARK: - Connect Button

    private var connectButton: some View {
        Button {
            Task {
                do {
                    try await service.requestAuthorization()
                    await loadData()
                } catch {
                    // Authorization denied or unavailable — fail silently
                }
            }
        } label: {
            HStack(spacing: 10) {
                Image(systemName: "heart.text.clipboard")
                    .font(.title3)
                    .foregroundStyle(MCColors.accentCoral)
                VStack(alignment: .leading, spacing: 2) {
                    Text("Connect Apple Health")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(MCColors.textPrimary)
                    Text("View steps, heart rate & sleep")
                        .font(.caption)
                        .foregroundStyle(MCColors.textSecondary)
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(MCColors.textTertiary)
            }
        }
        .buttonStyle(.plain)
    }

    // MARK: - Metric Item

    private func metricItem(icon: String, value: String, label: String, color: Color) -> some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundStyle(color)
            Text(value)
                .font(.title3.weight(.bold).monospacedDigit())
                .foregroundStyle(MCColors.textPrimary)
            Text(label)
                .font(.caption2)
                .foregroundStyle(MCColors.textSecondary)
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Helpers

    private func loadData() async {
        isLoading = true
        defer { isLoading = false }

        async let s = service.fetchTodaySteps()
        async let hr = service.fetchLatestHeartRate()
        async let sl = service.fetchSleepHours(for: Date())

        steps = await s
        heartRate = await hr
        sleepHours = await sl
    }

    private func formatSteps(_ count: Int) -> String {
        if count >= 1000 {
            let k = Double(count) / 1000.0
            return String(format: "%.1fk", k)
        }
        return "\(count)"
    }
}

#Preview {
    HealthKitSummaryCard(service: HealthKitService())
        .padding()
        .background(MCColors.backgroundLight)
}
