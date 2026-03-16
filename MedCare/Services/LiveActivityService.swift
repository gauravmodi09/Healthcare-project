import ActivityKit
import Foundation
import SwiftUI

/// Manages Live Activity lifecycle for dose reminders on Dynamic Island
/// Starts activities ~15 min before a dose, updates countdown, ends on action
@Observable
final class LiveActivityService {
    private var activeActivities: [String: String] = [:]  // doseLogId -> activityId
    private var updateTimer: Timer?

    // MARK: - Public API

    /// Check if Live Activities are available on this device
    var isSupported: Bool {
        ActivityAuthorizationInfo().areActivitiesEnabled
    }

    /// Start a Live Activity for an upcoming dose
    func startActivity(
        doseLogId: UUID,
        medicineId: UUID,
        medicineName: String,
        dosage: String,
        scheduledTime: Date,
        timingIcon: String,
        timingLabel: String,
        instructions: String?
    ) {
        guard isSupported else { return }

        let key = doseLogId.uuidString
        guard activeActivities[key] == nil else { return } // Already active

        let attributes = DoseReminderAttributes(
            medicineId: medicineId.uuidString,
            doseLogId: key,
            medicineName: medicineName,
            dosage: dosage,
            scheduledTime: scheduledTime,
            timingIcon: timingIcon,
            timingLabel: timingLabel,
            instructions: instructions
        )

        let minutesRemaining = max(0, Int(scheduledTime.timeIntervalSinceNow / 60))
        let status: DoseActivityStatus = minutesRemaining > 0 ? .upcoming : .due

        let state = DoseReminderAttributes.ContentState(
            status: status,
            minutesRemaining: minutesRemaining
        )

        let content = ActivityContent(state: state, staleDate: scheduledTime.addingTimeInterval(30 * 60))

        do {
            let activity = try Activity.request(
                attributes: attributes,
                content: content,
                pushType: nil
            )
            activeActivities[key] = activity.id
            startUpdateTimerIfNeeded()
        } catch {
            // Live Activity failed to start — notifications still work as backup
        }
    }

    /// Update the status/countdown of an active activity
    func updateActivity(doseLogId: UUID, status: DoseActivityStatus, minutesRemaining: Int, snoozedUntil: Date? = nil) async {
        let key = doseLogId.uuidString
        guard let activityId = activeActivities[key] else { return }

        let state = DoseReminderAttributes.ContentState(
            status: status,
            minutesRemaining: minutesRemaining,
            snoozedUntil: snoozedUntil
        )

        for activity in Activity<DoseReminderAttributes>.activities where activity.id == activityId {
            await activity.update(ActivityContent(state: state, staleDate: nil))
        }
    }

    /// End a Live Activity (dose taken, skipped, or missed)
    func endActivity(doseLogId: UUID, status: DoseActivityStatus = .completed) async {
        let key = doseLogId.uuidString
        guard let activityId = activeActivities[key] else { return }

        let finalState = DoseReminderAttributes.ContentState(
            status: .completed,
            minutesRemaining: 0
        )

        for activity in Activity<DoseReminderAttributes>.activities where activity.id == activityId {
            await activity.end(
                ActivityContent(state: finalState, staleDate: nil),
                dismissalPolicy: .after(.now.addingTimeInterval(5))
            )
        }

        activeActivities.removeValue(forKey: key)
        stopUpdateTimerIfEmpty()
    }

    /// End all active Live Activities (cleanup on app termination)
    func endAllActivities() async {
        for activity in Activity<DoseReminderAttributes>.activities {
            let finalState = DoseReminderAttributes.ContentState(
                status: .completed,
                minutesRemaining: 0
            )
            await activity.end(
                ActivityContent(state: finalState, staleDate: nil),
                dismissalPolicy: .immediate
            )
        }
        activeActivities.removeAll()
        stopUpdateTimerIfEmpty()
    }

    /// Evaluate upcoming doses and start/update activities as needed
    func evaluateUpcomingDoses(from doseLogs: [DoseLog]) {
        guard isSupported else { return }

        let now = Date()
        let fifteenMinutesFromNow = now.addingTimeInterval(15 * 60)

        for dose in doseLogs {
            guard dose.status == .pending,
                  let medicine = dose.medicine,
                  dose.scheduledTime <= fifteenMinutesFromNow,
                  dose.scheduledTime > now.addingTimeInterval(-30 * 60)  // Not more than 30 min overdue
            else { continue }

            let key = dose.id.uuidString
            if activeActivities[key] != nil { continue } // Already has an activity

            // Determine timing icon/label from the hour
            let hour = Calendar.current.component(.hour, from: dose.scheduledTime)
            let (icon, label) = timingInfo(for: hour)

            startActivity(
                doseLogId: dose.id,
                medicineId: medicine.id,
                medicineName: medicine.brandName,
                dosage: medicine.dosage,
                scheduledTime: dose.scheduledTime,
                timingIcon: icon,
                timingLabel: label,
                instructions: medicine.instructions
            )
        }

        // Update existing activities with current countdown
        Task {
            await updateAllCountdowns()
        }
    }

    // MARK: - Private

    /// Periodic countdown update for all active activities
    private func updateAllCountdowns() async {
        let now = Date()

        for (key, activityId) in activeActivities {
            for activity in Activity<DoseReminderAttributes>.activities where activity.id == activityId {
                let scheduledTime = activity.attributes.scheduledTime
                let minutesRemaining = Int(scheduledTime.timeIntervalSince(now) / 60)

                let status: DoseActivityStatus
                if minutesRemaining > 0 {
                    status = .upcoming
                } else if minutesRemaining >= -5 {
                    status = .due
                } else if minutesRemaining >= -30 {
                    status = .overdue
                } else {
                    // 30+ min overdue — end the activity
                    await endActivity(doseLogId: UUID(uuidString: key) ?? UUID())
                    continue
                }

                let state = DoseReminderAttributes.ContentState(
                    status: status,
                    minutesRemaining: minutesRemaining
                )
                await activity.update(ActivityContent(state: state, staleDate: nil))
            }
        }
    }

    private func startUpdateTimerIfNeeded() {
        guard updateTimer == nil else { return }
        updateTimer = Timer.scheduledTimer(withTimeInterval: 60, repeats: true) { [weak self] _ in
            guard let self else { return }
            Task { @MainActor in
                await self.updateAllCountdowns()
            }
        }
    }

    private func stopUpdateTimerIfEmpty() {
        guard activeActivities.isEmpty else { return }
        updateTimer?.invalidate()
        updateTimer = nil
    }

    private func timingInfo(for hour: Int) -> (icon: String, label: String) {
        switch hour {
        case 5..<12: return ("sunrise", "Morning")
        case 12..<17: return ("sun.max", "Afternoon")
        case 17..<21: return ("sunset", "Evening")
        default: return ("moon.stars", "Night")
        }
    }
}
