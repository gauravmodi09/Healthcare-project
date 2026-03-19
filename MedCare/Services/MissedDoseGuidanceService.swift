import Foundation

// MARK: - Missed Dose Guidance Service

/// Provides contextual guidance when a user misses a medication dose.
/// Recommendations are based on time elapsed, dose frequency, and medicine category.
@Observable
final class MissedDoseGuidanceService {

    // MARK: - Types

    struct MissedDoseGuidance: Identifiable {
        let id = UUID()
        let title: String
        let message: String
        let recommendation: MissedDoseAction
        let icon: String
        let severity: GuidanceSeverity
    }

    enum MissedDoseAction: String {
        case takeNow = "Take Now"
        case skipAndContinue = "Skip & Continue"
        case takeHalfDose = "Take Half Dose"
        case contactDoctor = "Contact Doctor"
    }

    enum GuidanceSeverity: String {
        case safe = "Safe"
        case caution = "Caution"
        case warning = "Warning"
    }

    // MARK: - Constants

    private static let disclaimer = "This is general guidance. Always consult your doctor."

    // MARK: - Guidance Logic

    /// Returns contextual guidance for a missed dose based on medicine type, time elapsed, and frequency.
    /// - Parameters:
    ///   - medicineName: Display name of the medicine
    ///   - medicineCategory: Category string such as "antibiotic", "blood_thinner", "insulin", etc.
    ///   - scheduledTime: The time the dose was originally scheduled
    ///   - currentTime: The current time (allows injection for testing)
    ///   - dosesPerDay: Number of doses per day (1 = once daily, 2+ = multiple daily)
    /// - Returns: A `MissedDoseGuidance` with title, message, recommendation, and severity
    func getGuidance(
        medicineName: String,
        medicineCategory: String,
        scheduledTime: Date,
        currentTime: Date = Date(),
        dosesPerDay: Int
    ) -> MissedDoseGuidance {
        let hoursLate = currentTime.timeIntervalSince(scheduledTime) / 3600.0
        let category = medicineCategory.lowercased().trimmingCharacters(in: .whitespaces)

        // Special category rules take precedence
        if let specialGuidance = specialCategoryGuidance(
            category: category,
            medicineName: medicineName,
            hoursLate: hoursLate
        ) {
            return specialGuidance
        }

        // General rules based on time elapsed
        return generalGuidance(
            medicineName: medicineName,
            hoursLate: hoursLate,
            dosesPerDay: dosesPerDay
        )
    }

    // MARK: - Special Category Rules

    private func specialCategoryGuidance(
        category: String,
        medicineName: String,
        hoursLate: Double
    ) -> MissedDoseGuidance? {
        switch category {
        case "blood_thinner", "blood thinner", "anticoagulant":
            return MissedDoseGuidance(
                title: "Missed Blood Thinner",
                message: "Blood thinners require strict dosing schedules. Contact your doctor about the missed dose of \(medicineName). Do NOT double up on your next dose. \(Self.disclaimer)",
                recommendation: .contactDoctor,
                icon: "heart.circle.fill",
                severity: .warning
            )

        case "insulin":
            return MissedDoseGuidance(
                title: "Missed Insulin Dose",
                message: "Never double up on insulin. Check your blood sugar level and adjust accordingly. If unsure, contact your doctor about the missed dose of \(medicineName). \(Self.disclaimer)",
                recommendation: .contactDoctor,
                icon: "syringe",
                severity: .warning
            )

        case "antibiotic":
            return antibioticGuidance(medicineName: medicineName, hoursLate: hoursLate)

        default:
            return nil
        }
    }

    private func antibioticGuidance(medicineName: String, hoursLate: Double) -> MissedDoseGuidance {
        if hoursLate < 4 {
            return MissedDoseGuidance(
                title: "Take Your Antibiotic Now",
                message: "It's important to complete the full course of \(medicineName). Since it's been less than 4 hours, take it now and continue your regular schedule. \(Self.disclaimer)",
                recommendation: .takeNow,
                icon: "pills.circle.fill",
                severity: .caution
            )
        } else {
            return MissedDoseGuidance(
                title: "Missed Antibiotic Dose",
                message: "It's been over 4 hours since your scheduled dose of \(medicineName). Skip this dose and take the next one at the regular time. Do NOT double up. Completing your antibiotic course is important — contact your doctor if you miss multiple doses. \(Self.disclaimer)",
                recommendation: .skipAndContinue,
                icon: "pills.circle.fill",
                severity: .warning
            )
        }
    }

    // MARK: - General Rules

    private func generalGuidance(
        medicineName: String,
        hoursLate: Double,
        dosesPerDay: Int
    ) -> MissedDoseGuidance {
        if hoursLate < 2 {
            // Less than 2 hours late — safe to take
            return MissedDoseGuidance(
                title: "You Can Still Take It",
                message: "It's only been \(formattedHours(hoursLate)) since your scheduled dose of \(medicineName). You can still take it safely. \(Self.disclaimer)",
                recommendation: .takeNow,
                icon: "checkmark.circle.fill",
                severity: .safe
            )
        } else if hoursLate < 4 {
            if dosesPerDay <= 1 {
                // 2-4 hours late, once-daily
                return MissedDoseGuidance(
                    title: "Take It Now",
                    message: "It's been \(formattedHours(hoursLate)) since your scheduled dose of \(medicineName). Take it now and adjust tomorrow's dose time if needed. \(Self.disclaimer)",
                    recommendation: .takeNow,
                    icon: "clock.badge.checkmark",
                    severity: .caution
                )
            } else {
                // 2-4 hours late, multiple daily doses
                return MissedDoseGuidance(
                    title: "Skip This Dose",
                    message: "It's been \(formattedHours(hoursLate)) since your scheduled dose of \(medicineName). Since you take it multiple times a day, skip this dose and take the next one as scheduled. Do NOT double up. \(Self.disclaimer)",
                    recommendation: .skipAndContinue,
                    icon: "clock.badge.xmark",
                    severity: .caution
                )
            }
        } else {
            // More than 4 hours late
            return MissedDoseGuidance(
                title: "Skip This Dose",
                message: "It's been over 4 hours since your scheduled dose of \(medicineName). Skip this dose entirely and take the next one at the regular time. Do NOT double up. \(Self.disclaimer)",
                recommendation: .skipAndContinue,
                icon: "exclamationmark.triangle.fill",
                severity: .warning
            )
        }
    }

    // MARK: - Helpers

    private func formattedHours(_ hours: Double) -> String {
        let wholeHours = Int(hours)
        let minutes = Int((hours - Double(wholeHours)) * 60)
        if wholeHours == 0 {
            return "\(minutes) minute\(minutes == 1 ? "" : "s")"
        } else if minutes == 0 {
            return "\(wholeHours) hour\(wholeHours == 1 ? "" : "s")"
        } else {
            return "\(wholeHours)h \(minutes)m"
        }
    }
}
