import Foundation
import SwiftUI

// MARK: - Child Care Mode Service

/// Manages child-specific features: profile detection, simplified UI, growth tracking
@Observable
final class ChildCareService {

    /// Whether the given profile is a child (age < 12)
    static func isChildProfile(_ profile: UserProfile) -> Bool {
        guard let age = profile.age else { return false }
        return age < 12
    }

    // MARK: - Growth Entry

    struct GrowthEntry: Codable, Identifiable {
        var id: UUID = UUID()
        var date: Date
        var heightCm: Double
        var weightKg: Double
        var profileId: String
    }

    private let growthKey = "ChildCareService.growthEntries"

    /// Save a growth entry
    func addGrowthEntry(profileId: UUID, heightCm: Double, weightKg: Double) {
        var entries = getGrowthEntries(profileId: profileId)
        entries.append(GrowthEntry(
            date: Date(),
            heightCm: heightCm,
            weightKg: weightKg,
            profileId: profileId.uuidString
        ))
        saveGrowthEntries(entries, profileId: profileId)
    }

    /// Get all growth entries for a profile, sorted by date
    func getGrowthEntries(profileId: UUID) -> [GrowthEntry] {
        let key = "\(growthKey).\(profileId.uuidString)"
        guard let data = UserDefaults.standard.data(forKey: key),
              let entries = try? JSONDecoder().decode([GrowthEntry].self, from: data) else {
            return []
        }
        return entries.sorted { $0.date < $1.date }
    }

    private func saveGrowthEntries(_ entries: [GrowthEntry], profileId: UUID) {
        let key = "\(growthKey).\(profileId.uuidString)"
        if let data = try? JSONEncoder().encode(entries) {
            UserDefaults.standard.set(data, forKey: key)
        }
    }

    // MARK: - Growth Percentile (simplified WHO-based)

    /// Approximate height percentile for age (simplified, Indian pediatric reference)
    static func heightPercentile(heightCm: Double, ageYears: Int, gender: Gender?) -> Int {
        // Simplified median heights (cm) by age for Indian children
        let medianHeights: [Int: (male: Double, female: Double)] = [
            1: (75, 74),
            2: (87, 86),
            3: (96, 95),
            4: (103, 102),
            5: (110, 109),
            6: (116, 115),
            7: (122, 121),
            8: (128, 127),
            9: (133, 132),
            10: (138, 137),
            11: (143, 144),
        ]

        guard let median = medianHeights[ageYears] else { return 50 }
        let medianValue = (gender == .female) ? median.female : median.male
        let deviation = (heightCm - medianValue) / medianValue * 100

        // Map deviation to approximate percentile
        switch deviation {
        case 10...: return 95
        case 5..<10: return 75
        case -5..<5: return 50
        case -10 ..< -5: return 25
        default: return 10
        }
    }

    /// Approximate weight percentile for age (simplified)
    static func weightPercentile(weightKg: Double, ageYears: Int, gender: Gender?) -> Int {
        // Simplified median weights (kg) by age for Indian children
        let medianWeights: [Int: (male: Double, female: Double)] = [
            1: (9.6, 8.9),
            2: (12.2, 11.5),
            3: (14.3, 13.9),
            4: (16.3, 16.1),
            5: (18.3, 18.2),
            6: (20.5, 20.2),
            7: (22.9, 22.4),
            8: (25.4, 25.0),
            9: (28.1, 28.2),
            10: (31.2, 31.9),
            11: (34.3, 35.9),
        ]

        guard let median = medianWeights[ageYears] else { return 50 }
        let medianValue = (gender == .female) ? median.female : median.male
        let deviation = (weightKg - medianValue) / medianValue * 100

        switch deviation {
        case 15...: return 95
        case 5..<15: return 75
        case -5..<5: return 50
        case -15 ..< -5: return 25
        default: return 10
        }
    }
}

// MARK: - Child Profile Badge View

/// Badge indicating this is a child profile
struct ChildProfileBadge: View {
    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: "figure.child")
                .font(.system(size: 11, weight: .bold))
            Text("Child Profile")
                .font(.system(size: 11, weight: .bold))
        }
        .foregroundColor(.white)
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(
            Capsule(style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [Color(hex: "F59E0B"), Color(hex: "F97316")],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
        )
    }
}

// MARK: - Child Growth Chart Card

struct ChildGrowthChartCard: View {
    let profile: UserProfile
    @State private var childCareService = ChildCareService()
    @State private var showAddEntry = false
    @State private var newHeight: String = ""
    @State private var newWeight: String = ""

    private var entries: [ChildCareService.GrowthEntry] {
        childCareService.getGrowthEntries(profileId: profile.id)
    }

    private var latestEntry: ChildCareService.GrowthEntry? {
        entries.last
    }

    var body: some View {
        MCCard {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Image(systemName: "chart.line.uptrend.xyaxis")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(Color(hex: "F59E0B"))
                    Text("Growth Tracker")
                        .font(.headline)
                        .foregroundColor(MCColors.textPrimary)
                    Spacer()
                    Button {
                        showAddEntry.toggle()
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 22))
                            .foregroundColor(MCColors.primaryTeal)
                    }
                }

                if let latest = latestEntry, let age = profile.age {
                    HStack(spacing: 20) {
                        growthStat(
                            label: "Height",
                            value: String(format: "%.1f cm", latest.heightCm),
                            percentile: ChildCareService.heightPercentile(
                                heightCm: latest.heightCm,
                                ageYears: age,
                                gender: profile.gender
                            )
                        )
                        growthStat(
                            label: "Weight",
                            value: String(format: "%.1f kg", latest.weightKg),
                            percentile: ChildCareService.weightPercentile(
                                weightKg: latest.weightKg,
                                ageYears: age,
                                gender: profile.gender
                            )
                        )
                    }
                } else {
                    Text("No growth data recorded yet. Tap + to add.")
                        .font(.subheadline)
                        .foregroundColor(MCColors.textSecondary)
                }
            }
        }
        .alert("Add Growth Entry", isPresented: $showAddEntry) {
            TextField("Height (cm)", text: $newHeight)
                .keyboardType(.decimalPad)
            TextField("Weight (kg)", text: $newWeight)
                .keyboardType(.decimalPad)
            Button("Save") {
                if let h = Double(newHeight), let w = Double(newWeight) {
                    childCareService.addGrowthEntry(profileId: profile.id, heightCm: h, weightKg: w)
                    newHeight = ""
                    newWeight = ""
                }
            }
            Button("Cancel", role: .cancel) {
                newHeight = ""
                newWeight = ""
            }
        }
    }

    private func growthStat(label: String, value: String, percentile: Int) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(.caption)
                .foregroundColor(MCColors.textSecondary)
            Text(value)
                .font(.title3.weight(.semibold))
                .foregroundColor(MCColors.textPrimary)
            Text("\(ordinal(percentile)) percentile")
                .font(.caption2.weight(.medium))
                .foregroundColor(percentileColor(percentile))
        }
    }

    private func percentileColor(_ p: Int) -> Color {
        switch p {
        case 75...: return MCColors.success
        case 25..<75: return MCColors.primaryTeal
        default: return MCColors.warning
        }
    }

    private func ordinal(_ n: Int) -> String {
        let suffix: String
        let ones = n % 10
        let tens = (n / 10) % 10
        if tens == 1 {
            suffix = "th"
        } else {
            switch ones {
            case 1: suffix = "st"
            case 2: suffix = "nd"
            case 3: suffix = "rd"
            default: suffix = "th"
            }
        }
        return "\(n)\(suffix)"
    }
}

// MARK: - Child-Friendly Dose Card Modifier

extension View {
    /// Applies child-friendly styling: larger elements, colorful accents
    @ViewBuilder
    func childFriendlyStyle(_ isChild: Bool) -> some View {
        if isChild {
            self
                .scaleEffect(1.05)
                .padding(.vertical, 2)
        } else {
            self
        }
    }
}
