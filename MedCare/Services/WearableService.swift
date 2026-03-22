import Foundation

// MARK: - Wearable Source

enum WearableSource: String, CaseIterable, Identifiable, Sendable {
    case appleWatch = "Apple Watch"
    case noise = "Noise"
    case boat = "boAt"
    case fitbit = "Fitbit"
    case garmin = "Garmin"
    case oura = "Oura"
    case ultrahuman = "Ultrahuman"
    case freestyleLibre = "FreeStyle Libre"
    case manual = "Manual"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .appleWatch: return "applewatch"
        case .noise: return "headphones"
        case .boat: return "headphones"
        case .fitbit: return "figure.walk"
        case .garmin: return "figure.run"
        case .oura: return "circle.circle"
        case .ultrahuman: return "waveform.path.ecg"
        case .freestyleLibre: return "sensor.tag.radiowaves.forward"
        case .manual: return "hand.tap"
        }
    }

    var brandColor: String {
        switch self {
        case .appleWatch: return "333333"
        case .noise: return "FF4444"
        case .boat: return "FF6B00"
        case .fitbit: return "00B0B9"
        case .garmin: return "007DC5"
        case .oura: return "D4AF37"
        case .ultrahuman: return "6366F1"
        case .freestyleLibre: return "FFC107"
        case .manual: return "6B7280"
        }
    }

    var supportedVitals: [VitalType] {
        switch self {
        case .appleWatch:
            return [.heartRate, .spo2, .bloodPressure, .steps, .sleep, .bloodGlucose, .bodyTemperature, .respiratoryRate]
        case .noise, .boat:
            return [.heartRate, .spo2, .steps, .sleep]
        case .fitbit:
            return [.heartRate, .spo2, .steps, .sleep, .weight]
        case .garmin:
            return [.heartRate, .spo2, .steps, .sleep, .respiratoryRate]
        case .oura:
            return [.heartRate, .spo2, .sleep, .bodyTemperature, .respiratoryRate]
        case .ultrahuman:
            return [.heartRate, .bloodGlucose, .sleep]
        case .freestyleLibre:
            return [.bloodGlucose]
        case .manual:
            return VitalType.allCases
        }
    }

    /// Whether this source connects via HealthKit (local) vs Terra API (cloud)
    var connectionMethod: ConnectionMethod {
        switch self {
        case .appleWatch, .manual: return .healthKit
        default: return .terraAPI
        }
    }

    enum ConnectionMethod {
        case healthKit
        case terraAPI
    }
}

// MARK: - Wearable Device

struct WearableDevice: Identifiable, Sendable {
    let id = UUID()
    let name: String
    let source: WearableSource
    var lastSyncDate: Date?
    var isConnected: Bool

    var supportedVitals: [VitalType] {
        source.supportedVitals
    }

    var lastSyncDisplay: String {
        guard let date = lastSyncDate else { return "Never synced" }
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .short
        return "Synced \(formatter.localizedString(for: date, relativeTo: Date()))"
    }
}

// MARK: - Wearable Service

@Observable
final class WearableService {

    // MARK: - Properties

    var connectedDevices: [WearableDevice] = []
    var availableSources: [WearableSource] = WearableSource.allCases
    var isSyncing: Bool = false
    var syncError: String?

    // Terra API config (placeholder)
    private let terraAPIKey: String = ""
    private let terraDevID: String = ""

    // MARK: - Init

    init() {
        // Apple Watch is always available via HealthKit
        connectedDevices = [
            WearableDevice(
                name: "Apple Watch",
                source: .appleWatch,
                lastSyncDate: Date(),
                isConnected: true
            )
        ]
    }

    // MARK: - Connect Device

    /// Initiate OAuth/connection flow for a wearable source
    /// Currently mocked — will integrate Terra API for real connections
    func connectDevice(source: WearableSource) async throws {
        // For Apple Watch, it's always connected via HealthKit
        if source == .appleWatch {
            if !connectedDevices.contains(where: { $0.source == .appleWatch }) {
                connectedDevices.append(
                    WearableDevice(name: source.rawValue, source: source, lastSyncDate: Date(), isConnected: true)
                )
            }
            return
        }

        // TODO: Integrate Terra API OAuth flow
        // 1. Call Terra's authenticate endpoint for the given provider
        // 2. Open the returned auth URL in an in-app browser
        // 3. Handle the callback with the user's Terra user ID
        // 4. Store the Terra user ID for subsequent data fetches

        // Mock: simulate connection
        try await Task.sleep(for: .seconds(1))

        let device = WearableDevice(
            name: source.rawValue,
            source: source,
            lastSyncDate: Date(),
            isConnected: true
        )
        connectedDevices.append(device)
    }

    // MARK: - Disconnect Device

    func disconnectDevice(source: WearableSource) {
        connectedDevices.removeAll { $0.source == source }

        // TODO: Call Terra deauthenticate endpoint for the given provider
    }

    // MARK: - Sync Data

    /// Fetch latest data from a connected source
    func syncData(from source: WearableSource) async {
        guard connectedDevices.contains(where: { $0.source == source }) else { return }

        isSyncing = true
        syncError = nil

        do {
            // TODO: For HealthKit sources, trigger a background refresh
            // TODO: For Terra sources, call Terra's data endpoint
            //   - GET /v2/body?user_id=...&start_date=...&end_date=...
            //   - GET /v2/activity?user_id=...
            //   - GET /v2/sleep?user_id=...
            //   - GET /v2/daily?user_id=...

            try await Task.sleep(for: .seconds(1))

            // Update last sync date
            if let index = connectedDevices.firstIndex(where: { $0.source == source }) {
                connectedDevices[index] = WearableDevice(
                    name: connectedDevices[index].name,
                    source: source,
                    lastSyncDate: Date(),
                    isConnected: true
                )
            }
        } catch {
            syncError = "Sync failed: \(error.localizedDescription)"
        }

        isSyncing = false
    }

    // MARK: - Get Latest Vital

    /// Get the latest vital reading from a specific source
    func getLatestVital(type: VitalType, from source: WearableSource) -> VitalDataPoint? {
        // TODO: Query local cache of Terra data for the given vital type and source
        // For now, return nil — data will come from HealthKit or Terra API
        return nil
    }

    // MARK: - Sync All Connected

    func syncAllConnected() async {
        for device in connectedDevices where device.isConnected {
            await syncData(from: device.source)
        }
    }

    // MARK: - Connection Status

    func isDeviceConnected(_ source: WearableSource) -> Bool {
        connectedDevices.contains { $0.source == source && $0.isConnected }
    }

    func device(for source: WearableSource) -> WearableDevice? {
        connectedDevices.first { $0.source == source }
    }
}
