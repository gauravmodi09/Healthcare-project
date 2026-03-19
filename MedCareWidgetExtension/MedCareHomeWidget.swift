import WidgetKit
import SwiftUI

// MARK: - Timeline Provider

struct MedCareHomeWidgetProvider: TimelineProvider {
    private let suiteName = "group.com.medcare.shared"

    func placeholder(in context: Context) -> MedCareHomeWidgetEntry {
        MedCareHomeWidgetEntry(
            date: Date(),
            nextDoseName: "Augmentin 625",
            nextDoseTime: Calendar.current.date(byAdding: .hour, value: 1, to: Date()),
            upcomingDoses: [
                UpcomingDoseItem(name: "Augmentin 625", dosage: "625mg", time: Date()),
                UpcomingDoseItem(name: "Pan 40", dosage: "40mg", time: Date())
            ],
            taken: 3,
            total: 6,
            adherencePercentage: 0.85,
            streak: 7
        )
    }

    func getSnapshot(in context: Context, completion: @escaping (MedCareHomeWidgetEntry) -> Void) {
        let entry = loadEntry()
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<MedCareHomeWidgetEntry>) -> Void) {
        let entry = loadEntry()
        // Refresh every 15 minutes
        let nextUpdate = Calendar.current.date(byAdding: .minute, value: 15, to: Date()) ?? Date()
        let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))
        completion(timeline)
    }

    private func loadEntry() -> MedCareHomeWidgetEntry {
        guard let defaults = UserDefaults(suiteName: suiteName),
              let data = defaults.data(forKey: "widgetData") else {
            return MedCareHomeWidgetEntry(
                date: Date(),
                nextDoseName: nil,
                nextDoseTime: nil,
                upcomingDoses: [],
                taken: 0,
                total: 0,
                adherencePercentage: 0,
                streak: 0
            )
        }

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .secondsSince1970

        // Decode the shared WidgetData format
        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            return MedCareHomeWidgetEntry(date: Date(), nextDoseName: nil, nextDoseTime: nil, upcomingDoses: [], taken: 0, total: 0, adherencePercentage: 0, streak: 0)
        }

        let todayProgress = json["todayProgress"] as? [String: Any]
        let taken = todayProgress?["taken"] as? Int ?? 0
        let total = todayProgress?["total"] as? Int ?? 0
        let percentage = todayProgress?["percentage"] as? Double ?? 0

        let nextDoseDict = json["nextDose"] as? [String: Any]
        let nextDoseName = nextDoseDict?["medicineName"] as? String
        var nextDoseTime: Date?
        if let timeInterval = nextDoseDict?["scheduledTime"] as? TimeInterval {
            nextDoseTime = Date(timeIntervalSince1970: timeInterval)
        }

        let streak = json["adherenceStreak"] as? Int ?? 0

        // Build upcoming doses list (from shared data we get at least the next dose)
        var upcomingDoses: [UpcomingDoseItem] = []
        if let name = nextDoseName, let time = nextDoseTime {
            let dosage = nextDoseDict?["dosage"] as? String ?? ""
            upcomingDoses.append(UpcomingDoseItem(name: name, dosage: dosage, time: time))
        }

        // Check for additional upcoming doses stored as array
        if let upcomingArray = json["upcomingDoses"] as? [[String: Any]] {
            for doseDict in upcomingArray {
                guard let name = doseDict["medicineName"] as? String,
                      let timeInterval = doseDict["scheduledTime"] as? TimeInterval else { continue }
                let dosage = doseDict["dosage"] as? String ?? ""
                let item = UpcomingDoseItem(name: name, dosage: dosage, time: Date(timeIntervalSince1970: timeInterval))
                if !upcomingDoses.contains(where: { $0.name == item.name && $0.time == item.time }) {
                    upcomingDoses.append(item)
                }
            }
        }

        return MedCareHomeWidgetEntry(
            date: Date(),
            nextDoseName: nextDoseName,
            nextDoseTime: nextDoseTime,
            upcomingDoses: Array(upcomingDoses.prefix(3)),
            taken: taken,
            total: total,
            adherencePercentage: percentage,
            streak: streak
        )
    }
}

// MARK: - Entry

struct UpcomingDoseItem {
    let name: String
    let dosage: String
    let time: Date
}

struct MedCareHomeWidgetEntry: TimelineEntry {
    let date: Date
    let nextDoseName: String?
    let nextDoseTime: Date?
    let upcomingDoses: [UpcomingDoseItem]
    let taken: Int
    let total: Int
    let adherencePercentage: Double
    let streak: Int
}

// MARK: - Small Widget View

struct MedCareSmallWidgetView: View {
    let entry: MedCareHomeWidgetEntry

    private let teal = Color(red: 10/255, green: 126/255, blue: 140/255)

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Adherence ring + branding
            HStack {
                ZStack {
                    Circle()
                        .stroke(teal.opacity(0.2), lineWidth: 4)
                        .frame(width: 36, height: 36)
                    Circle()
                        .trim(from: 0, to: entry.adherencePercentage)
                        .stroke(teal, style: StrokeStyle(lineWidth: 4, lineCap: .round))
                        .frame(width: 36, height: 36)
                        .rotationEffect(.degrees(-90))
                    Text("\(Int(entry.adherencePercentage * 100))%")
                        .font(.system(size: 9, weight: .bold))
                        .foregroundStyle(teal)
                }

                Spacer()

                Image(systemName: "pills.fill")
                    .font(.system(size: 14))
                    .foregroundStyle(teal)
            }

            Spacer()

            // Next dose info
            if let name = entry.nextDoseName, let time = entry.nextDoseTime {
                VStack(alignment: .leading, spacing: 2) {
                    Text("NEXT DOSE")
                        .font(.system(size: 9, weight: .semibold))
                        .foregroundStyle(.secondary)

                    Text(name)
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(.primary)
                        .lineLimit(1)

                    Text(time, style: .time)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(teal)
                }
            } else {
                VStack(alignment: .leading, spacing: 2) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 20))
                        .foregroundStyle(Color(red: 52/255, green: 199/255, blue: 89/255))

                    Text("All done!")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(.primary)

                    Text("No upcoming doses")
                        .font(.system(size: 11))
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding(14)
        .containerBackground(for: .widget) {
            Color(.systemBackground)
        }
    }
}

// MARK: - Medium Widget View

struct MedCareMediumWidgetView: View {
    let entry: MedCareHomeWidgetEntry

    private let teal = Color(red: 10/255, green: 126/255, blue: 140/255)

    var body: some View {
        HStack(spacing: 12) {
            // Left column: header + stats
            VStack(alignment: .leading, spacing: 8) {
                // Header
                HStack(spacing: 4) {
                    Image(systemName: "pills.fill")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(teal)
                    Text("MedCare")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundStyle(teal)
                }

                // Date
                Text(entry.date, format: .dateTime.weekday(.wide).month().day())
                    .font(.system(size: 11))
                    .foregroundStyle(.secondary)

                Spacer()

                // Taken counter
                HStack(spacing: 4) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 12))
                        .foregroundStyle(Color(red: 52/255, green: 199/255, blue: 89/255))
                    Text("\(entry.taken)/\(entry.total)")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(.primary)
                    Text("taken")
                        .font(.system(size: 11))
                        .foregroundStyle(.secondary)
                }

                // Streak badge
                if entry.streak > 0 {
                    HStack(spacing: 3) {
                        Image(systemName: "flame.fill")
                            .font(.system(size: 10))
                            .foregroundStyle(.orange)
                        Text("\(entry.streak)d streak")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundStyle(.orange)
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(Color.orange.opacity(0.12))
                    .clipShape(Capsule())
                }
            }

            // Divider
            Rectangle()
                .fill(Color(.separator).opacity(0.3))
                .frame(width: 1)
                .padding(.vertical, 4)

            // Right column: upcoming doses
            VStack(alignment: .leading, spacing: 6) {
                Text("UPCOMING")
                    .font(.system(size: 9, weight: .bold))
                    .foregroundStyle(.secondary)

                if entry.upcomingDoses.isEmpty {
                    Spacer()
                    HStack {
                        Spacer()
                        VStack(spacing: 4) {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 18))
                                .foregroundStyle(Color(red: 52/255, green: 199/255, blue: 89/255))
                            Text("All done for today")
                                .font(.system(size: 11))
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                    }
                    Spacer()
                } else {
                    ForEach(Array(entry.upcomingDoses.prefix(3).enumerated()), id: \.offset) { _, dose in
                        HStack(spacing: 6) {
                            Circle()
                                .fill(teal.opacity(0.15))
                                .frame(width: 24, height: 24)
                                .overlay(
                                    Image(systemName: "pills")
                                        .font(.system(size: 10))
                                        .foregroundStyle(teal)
                                )

                            VStack(alignment: .leading, spacing: 0) {
                                Text(dose.name)
                                    .font(.system(size: 12, weight: .semibold))
                                    .foregroundStyle(.primary)
                                    .lineLimit(1)
                                Text(dose.time, style: .time)
                                    .font(.system(size: 10))
                                    .foregroundStyle(.secondary)
                            }

                            Spacer()
                        }
                    }

                    Spacer(minLength: 0)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(14)
        .containerBackground(for: .widget) {
            Color(.systemBackground)
        }
    }
}

// MARK: - Widget Definition

struct MedCareHomeWidget: Widget {
    let kind = "MedCareHomeWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: MedCareHomeWidgetProvider()) { entry in
            MedCareHomeWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("MedCare")
        .description("Track your medications and upcoming doses.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

struct MedCareHomeWidgetEntryView: View {
    @Environment(\.widgetFamily) var family
    let entry: MedCareHomeWidgetEntry

    var body: some View {
        switch family {
        case .systemSmall:
            MedCareSmallWidgetView(entry: entry)
        case .systemMedium:
            MedCareMediumWidgetView(entry: entry)
        default:
            MedCareSmallWidgetView(entry: entry)
        }
    }
}
