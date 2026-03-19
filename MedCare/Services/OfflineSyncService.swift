import Foundation
import Network

/// Enhancement #1: Offline-first architecture with sync queue
/// Handles dose logging even without connectivity, syncs when back online
@MainActor @Observable
final class OfflineSyncService {
    var isOnline = true
    var pendingSyncCount = 0
    var lastSyncTime: Date?

    private let monitor = NWPathMonitor()
    private let syncQueue = DispatchQueue(label: "com.medcare.sync")
    private let pendingActionsKey = "com.medcare.pendingActions"

    struct PendingAction: Codable, Identifiable {
        let id: UUID
        let type: ActionType
        let payload: Data
        let createdAt: Date
        var retryCount: Int

        enum ActionType: String, Codable {
            case logDose
            case addSymptom
            case updateEpisode
            case uploadImage
        }
    }

    init() {
        startMonitoring()
        loadPendingActions()
    }

    private func startMonitoring() {
        monitor.pathUpdateHandler = { [weak self] path in
            let satisfied = path.status == .satisfied
            Task { @MainActor in
                self?.isOnline = satisfied
                if satisfied {
                    self?.syncPendingActions()
                }
            }
        }
        monitor.start(queue: syncQueue)
    }

    /// Queue an action for sync
    func enqueue(_ action: PendingAction) {
        var actions = loadStoredActions()
        actions.append(action)
        saveActions(actions)
        pendingSyncCount = actions.count
    }

    /// Log a dose action (works offline)
    func queueDoseLog(doseLogId: UUID, status: String, notes: String?) {
        let payload = try! JSONEncoder().encode([
            "doseLogId": doseLogId.uuidString,
            "status": status,
            "notes": notes ?? "",
            "timestamp": ISO8601DateFormatter().string(from: Date())
        ])

        let action = PendingAction(
            id: UUID(),
            type: .logDose,
            payload: payload,
            createdAt: Date(),
            retryCount: 0
        )
        enqueue(action)
    }

    /// Sync all pending actions when online
    func syncPendingActions() {
        guard isOnline else { return }

        let actions = loadStoredActions()
        guard !actions.isEmpty else { return }

        // Process each action
        Task {
            var failedActions: [PendingAction] = []

            for var action in actions {
                do {
                    try await processAction(action)
                } catch {
                    action.retryCount += 1
                    if action.retryCount < 3 {
                        failedActions.append(action)
                    }
                    // Drop after 3 retries
                }
            }

            await MainActor.run {
                saveActions(failedActions)
                pendingSyncCount = failedActions.count
                if failedActions.isEmpty {
                    lastSyncTime = Date()
                }
            }
        }
    }

    private func processAction(_ action: PendingAction) async throws {
        // In production, send to backend API
        switch action.type {
        case .logDose:
            // POST /doses/:id/log
            try await Task.sleep(nanoseconds: 100_000_000)
        case .addSymptom:
            // POST /episodes/:id/symptoms
            try await Task.sleep(nanoseconds: 100_000_000)
        case .updateEpisode:
            // PATCH /episodes/:id
            try await Task.sleep(nanoseconds: 100_000_000)
        case .uploadImage:
            // POST upload to S3
            try await Task.sleep(nanoseconds: 200_000_000)
        }
    }

    // MARK: - Persistence

    private func loadStoredActions() -> [PendingAction] {
        guard let data = UserDefaults.standard.data(forKey: pendingActionsKey) else { return [] }
        return (try? JSONDecoder().decode([PendingAction].self, from: data)) ?? []
    }

    private func saveActions(_ actions: [PendingAction]) {
        let data = try? JSONEncoder().encode(actions)
        UserDefaults.standard.set(data, forKey: pendingActionsKey)
    }

    private func loadPendingActions() {
        pendingSyncCount = loadStoredActions().count
    }
}
