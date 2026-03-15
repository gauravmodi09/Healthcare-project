import Foundation

/// Enhancement #4: Smart Scheduling Engine
/// Intelligently schedules doses based on user's routine and medicine requirements
@Observable
final class SmartSchedulingService {

    struct ScheduleSuggestion: Identifiable {
        let id = UUID()
        let medicineName: String
        let suggestedTimes: [Date]
        let reasoning: String
    }

    /// User's typical routine (learned over time)
    struct UserRoutine {
        var wakeUpTime: DateComponents = DateComponents(hour: 7, minute: 0)
        var breakfastTime: DateComponents = DateComponents(hour: 8, minute: 0)
        var lunchTime: DateComponents = DateComponents(hour: 13, minute: 0)
        var dinnerTime: DateComponents = DateComponents(hour: 20, minute: 0)
        var bedTime: DateComponents = DateComponents(hour: 22, minute: 30)
    }

    private var routine = UserRoutine()

    /// Generate optimal schedule for medicines in an episode
    func generateSchedule(medicines: [Medicine]) -> [ScheduleSuggestion] {
        medicines.map { medicine in
            let times = suggestTimes(for: medicine)
            let reasoning = generateReasoning(for: medicine, times: times)
            return ScheduleSuggestion(
                medicineName: medicine.brandName,
                suggestedTimes: times,
                reasoning: reasoning
            )
        }
    }

    private func suggestTimes(for medicine: Medicine) -> [Date] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        var times: [Date] = []

        let instructions = (medicine.instructions ?? "").lowercased()
        let isBeforeFood = instructions.contains("before food") || instructions.contains("empty stomach")
        let isAfterFood = instructions.contains("after food") || instructions.contains("with meal")

        for timing in medicine.timing.sorted() {
            var components = calendar.dateComponents([.year, .month, .day], from: today)

            switch timing {
            case .morning:
                if isBeforeFood {
                    // 30 mins before breakfast
                    components.hour = routine.breakfastTime.hour
                    components.minute = (routine.breakfastTime.minute ?? 0) - 30
                } else if isAfterFood {
                    // 30 mins after breakfast
                    components.hour = routine.breakfastTime.hour
                    components.minute = (routine.breakfastTime.minute ?? 0) + 30
                } else {
                    components.hour = routine.wakeUpTime.hour
                    components.minute = routine.wakeUpTime.minute
                }

            case .afternoon:
                if isBeforeFood {
                    components.hour = routine.lunchTime.hour
                    components.minute = (routine.lunchTime.minute ?? 0) - 30
                } else if isAfterFood {
                    components.hour = routine.lunchTime.hour
                    components.minute = (routine.lunchTime.minute ?? 0) + 30
                } else {
                    components.hour = 14
                    components.minute = 0
                }

            case .evening:
                components.hour = 18
                components.minute = 0

            case .night:
                if isBeforeFood {
                    components.hour = routine.dinnerTime.hour
                    components.minute = (routine.dinnerTime.minute ?? 0) - 30
                } else if isAfterFood {
                    components.hour = routine.dinnerTime.hour
                    components.minute = (routine.dinnerTime.minute ?? 0) + 30
                } else {
                    components.hour = routine.bedTime.hour
                    components.minute = routine.bedTime.minute
                }

            case .custom(let hour, let minute):
                components.hour = hour
                components.minute = minute
            }

            if let date = calendar.date(from: components) {
                times.append(date)
            }
        }

        return times
    }

    private func generateReasoning(for medicine: Medicine, times: [Date]) -> String {
        let instructions = (medicine.instructions ?? "").lowercased()
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"

        let timeStrings = times.map { formatter.string(from: $0) }.joined(separator: ", ")

        if instructions.contains("before food") {
            return "Scheduled \(timeStrings) — 30 minutes before meals for optimal absorption"
        } else if instructions.contains("empty stomach") {
            return "Scheduled \(timeStrings) — on empty stomach as prescribed"
        } else if instructions.contains("after food") {
            return "Scheduled \(timeStrings) — 30 minutes after meals to reduce stomach irritation"
        } else {
            return "Scheduled \(timeStrings) — spaced evenly throughout the day"
        }
    }

    /// Learn from user's dose logging patterns
    func updateRoutine(from doseLogs: [DoseLog]) {
        let takenLogs = doseLogs.filter { $0.status == .taken && $0.actualTime != nil }
        guard !takenLogs.isEmpty else { return }

        // Group by time-of-day
        let calendar = Calendar.current
        let morningLogs = takenLogs.filter {
            let hour = calendar.component(.hour, from: $0.actualTime!)
            return hour >= 5 && hour < 12
        }

        if !morningLogs.isEmpty {
            let avgHour = morningLogs.map { calendar.component(.hour, from: $0.actualTime!) }.reduce(0, +) / morningLogs.count
            let avgMinute = morningLogs.map { calendar.component(.minute, from: $0.actualTime!) }.reduce(0, +) / morningLogs.count
            routine.wakeUpTime = DateComponents(hour: avgHour, minute: avgMinute)
        }
    }
}
