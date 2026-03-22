import Foundation
import HealthKit

/// Represents a single vital data point with metadata
struct VitalDataPoint: Identifiable, Sendable {
    let id = UUID()
    let value: Double
    let date: Date
    let source: String

    var sourceDisplayName: String {
        if source.localizedCaseInsensitiveContains("watch") { return "Apple Watch" }
        if source.localizedCaseInsensitiveContains("noise") { return "Noise" }
        if source.localizedCaseInsensitiveContains("medcare") { return "Manual" }
        return source.isEmpty ? "Unknown" : source
    }
}

/// Blood pressure reading with both systolic and diastolic
struct BloodPressureReading: Identifiable, Sendable {
    let id = UUID()
    let systolic: Double
    let diastolic: Double
    let date: Date
    let source: String

    var sourceDisplayName: String {
        if source.localizedCaseInsensitiveContains("watch") { return "Apple Watch" }
        if source.localizedCaseInsensitiveContains("medcare") { return "Manual" }
        return source.isEmpty ? "Unknown" : source
    }
}

/// Vital type identifiers for fetching and writing
enum VitalType: String, CaseIterable, Identifiable, Sendable {
    case heartRate = "Heart Rate"
    case spo2 = "SpO2"
    case bloodPressure = "Blood Pressure"
    case weight = "Weight"
    case bloodGlucose = "Blood Glucose"
    case steps = "Steps"
    case sleep = "Sleep"
    case bodyTemperature = "Temperature"
    case respiratoryRate = "Respiratory Rate"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .heartRate: return "heart.fill"
        case .spo2: return "lungs.fill"
        case .bloodPressure: return "heart.text.square.fill"
        case .weight: return "scalemass.fill"
        case .bloodGlucose: return "drop.fill"
        case .steps: return "figure.walk"
        case .sleep: return "moon.zzz.fill"
        case .bodyTemperature: return "thermometer.medium"
        case .respiratoryRate: return "wind"
        }
    }

    var unit: String {
        switch self {
        case .heartRate: return "BPM"
        case .spo2: return "%"
        case .bloodPressure: return "mmHg"
        case .weight: return "kg"
        case .bloodGlucose: return "mg/dL"
        case .steps: return "steps"
        case .sleep: return "hrs"
        case .bodyTemperature: return "°F"
        case .respiratoryRate: return "br/min"
        }
    }
}

/// HealthKit integration service — read/write access to Apple Health data
@Observable
final class HealthKitService {

    // MARK: - Properties

    var isAuthorized = false

    private let healthStore: HKHealthStore?
    private let isAvailable: Bool

    // MARK: - HealthKit Types

    private var readTypes: Set<HKObjectType> {
        var types = Set<HKObjectType>()
        let quantityIdentifiers: [HKQuantityTypeIdentifier] = [
            .stepCount, .heartRate, .oxygenSaturation,
            .bloodPressureSystolic, .bloodPressureDiastolic,
            .bloodGlucose, .bodyMass, .bodyTemperature,
            .respiratoryRate,
        ]
        for id in quantityIdentifiers {
            if let t = HKQuantityType.quantityType(forIdentifier: id) {
                types.insert(t)
            }
        }
        if let sleep = HKCategoryType.categoryType(forIdentifier: .sleepAnalysis) {
            types.insert(sleep)
        }
        if let workout = HKObjectType.workoutType() as HKObjectType? {
            types.insert(workout)
        }
        if let ecg = HKObjectType.electrocardiogramType() as HKObjectType? {
            types.insert(ecg)
        }
        return types
    }

    private var writeTypes: Set<HKSampleType> {
        var types = Set<HKSampleType>()
        let quantityIdentifiers: [HKQuantityTypeIdentifier] = [
            .heartRate, .oxygenSaturation,
            .bloodPressureSystolic, .bloodPressureDiastolic,
            .bloodGlucose, .bodyMass, .bodyTemperature,
            .respiratoryRate,
        ]
        for id in quantityIdentifiers {
            if let t = HKQuantityType.quantityType(forIdentifier: id) {
                types.insert(t)
            }
        }
        return types
    }

    // MARK: - Errors

    enum HealthKitError: LocalizedError {
        case notAvailable
        case authorizationFailed
        case queryFailed(String)
        case unsupportedType

        var errorDescription: String? {
            switch self {
            case .notAvailable:
                return "HealthKit is not available on this device."
            case .authorizationFailed:
                return "HealthKit authorization was denied."
            case .queryFailed(let reason):
                return "HealthKit query failed: \(reason)"
            case .unsupportedType:
                return "This vital type is not supported for writing."
            }
        }
    }

    // MARK: - Init

    init() {
        isAvailable = HKHealthStore.isHealthDataAvailable()
        healthStore = isAvailable ? HKHealthStore() : nil
    }

    // MARK: - Authorization

    func requestAuthorization() async throws {
        guard isAvailable, let store = healthStore else {
            throw HealthKitError.notAvailable
        }

        try await store.requestAuthorization(toShare: writeTypes, read: readTypes)
        isAuthorized = true
    }

    // MARK: - Fetch Latest Vitals (all at once)

    struct LatestVitals: Sendable {
        var heartRate: VitalDataPoint?
        var spo2: VitalDataPoint?
        var bloodPressure: BloodPressureReading?
        var weight: VitalDataPoint?
        var bloodGlucose: VitalDataPoint?
        var steps: VitalDataPoint?
        var sleep: VitalDataPoint?
        var bodyTemperature: VitalDataPoint?
        var respiratoryRate: VitalDataPoint?
    }

    func fetchLatestVitals() async -> LatestVitals {
        async let hr = fetchLatestVitalDataPoint(identifier: .heartRate, unit: HKUnit.count().unitDivided(by: .minute()))
        async let spo2 = fetchLatestVitalDataPoint(identifier: .oxygenSaturation, unit: .percent())
        async let bp = fetchLatestBloodPressureReading()
        async let weight = fetchLatestVitalDataPoint(identifier: .bodyMass, unit: .gramUnit(with: .kilo))
        async let glucose = fetchLatestVitalDataPoint(identifier: .bloodGlucose, unit: HKUnit.gramUnit(with: .milli).unitDivided(by: .literUnit(with: .deci)))
        async let steps = fetchTodayStepsDataPoint()
        async let sleep = fetchLatestSleepDataPoint()
        async let temp = fetchLatestVitalDataPoint(identifier: .bodyTemperature, unit: .degreeFahrenheit())
        async let resp = fetchLatestVitalDataPoint(identifier: .respiratoryRate, unit: HKUnit.count().unitDivided(by: .minute()))

        var vitals = LatestVitals()
        vitals.heartRate = await hr
        // Convert SpO2 from fraction to percentage for display
        if var spo2Point = await spo2 {
            spo2Point = VitalDataPoint(value: spo2Point.value * 100, date: spo2Point.date, source: spo2Point.source)
            vitals.spo2 = spo2Point
        }
        vitals.bloodPressure = await bp
        vitals.weight = await weight
        vitals.bloodGlucose = await glucose
        vitals.steps = await steps
        vitals.sleep = await sleep
        vitals.bodyTemperature = await temp
        vitals.respiratoryRate = await resp
        return vitals
    }

    // MARK: - Fetch Vital History

    func fetchVitalHistory(type: VitalType, days: Int) async -> [VitalDataPoint] {
        switch type {
        case .heartRate:
            return await fetchQuantityHistory(identifier: .heartRate, unit: HKUnit.count().unitDivided(by: .minute()), days: days)
        case .spo2:
            let raw = await fetchQuantityHistory(identifier: .oxygenSaturation, unit: .percent(), days: days)
            return raw.map { VitalDataPoint(value: $0.value * 100, date: $0.date, source: $0.source) }
        case .weight:
            return await fetchQuantityHistory(identifier: .bodyMass, unit: .gramUnit(with: .kilo), days: days)
        case .bloodGlucose:
            return await fetchQuantityHistory(identifier: .bloodGlucose, unit: HKUnit.gramUnit(with: .milli).unitDivided(by: .literUnit(with: .deci)), days: days)
        case .steps:
            return await fetchDailyStepsHistory(days: days)
        case .sleep:
            return await fetchSleepHistory(days: days)
        case .bodyTemperature:
            return await fetchQuantityHistory(identifier: .bodyTemperature, unit: .degreeFahrenheit(), days: days)
        case .respiratoryRate:
            return await fetchQuantityHistory(identifier: .respiratoryRate, unit: HKUnit.count().unitDivided(by: .minute()), days: days)
        case .bloodPressure:
            // For BP, return systolic values as data points
            return await fetchQuantityHistory(identifier: .bloodPressureSystolic, unit: .millimeterOfMercury(), days: days)
        }
    }

    func fetchBloodPressureHistory(days: Int) async -> [BloodPressureReading] {
        guard let store = healthStore,
              let sysType = HKQuantityType.quantityType(forIdentifier: .bloodPressureSystolic)
        else { return [] }

        let calendar = Calendar.current
        let startDate = calendar.date(byAdding: .day, value: -days, to: Date())!
        let predicate = HKQuery.predicateForSamples(withStart: startDate, end: Date(), options: .strictStartDate)

        let sysSamples = await fetchSamples(store: store, type: sysType, predicate: predicate, limit: 50)
        let diaType = HKQuantityType.quantityType(forIdentifier: .bloodPressureDiastolic)!
        let diaSamples = await fetchSamples(store: store, type: diaType, predicate: predicate, limit: 50)

        let mmHg = HKUnit.millimeterOfMercury()
        var readings: [BloodPressureReading] = []

        for sysSample in sysSamples {
            let sysValue = sysSample.quantity.doubleValue(for: mmHg)
            // Find matching diastolic reading close in time
            if let matching = diaSamples.first(where: { abs($0.startDate.timeIntervalSince(sysSample.startDate)) < 60 }) {
                let diaValue = matching.quantity.doubleValue(for: mmHg)
                let source = sysSample.sourceRevision.source.name
                readings.append(BloodPressureReading(systolic: sysValue, diastolic: diaValue, date: sysSample.startDate, source: source))
            }
        }

        return readings.sorted { $0.date > $1.date }
    }

    // MARK: - Background Delivery

    func startBackgroundDelivery() {
        guard let store = healthStore else { return }

        let typesToObserve: [HKQuantityTypeIdentifier] = [
            .heartRate, .oxygenSaturation, .stepCount,
            .bloodPressureSystolic, .bloodGlucose, .bodyMass,
        ]

        for identifier in typesToObserve {
            guard let type = HKQuantityType.quantityType(forIdentifier: identifier) else { continue }
            store.enableBackgroundDelivery(for: type, frequency: .hourly) { success, error in
                #if DEBUG
                if let error {
                    print("Background delivery failed for \(identifier.rawValue): \(error.localizedDescription)")
                }
                #endif
            }
        }
    }

    // MARK: - Write to HealthKit

    func writeToHealthKit(type: VitalType, value: Double, date: Date) async throws {
        guard let store = healthStore else { throw HealthKitError.notAvailable }

        switch type {
        case .heartRate:
            try await writeSample(store: store, identifier: .heartRate, value: value, unit: HKUnit.count().unitDivided(by: .minute()), date: date)
        case .spo2:
            try await writeSample(store: store, identifier: .oxygenSaturation, value: value / 100.0, unit: .percent(), date: date)
        case .weight:
            try await writeSample(store: store, identifier: .bodyMass, value: value, unit: .gramUnit(with: .kilo), date: date)
        case .bloodGlucose:
            try await writeSample(store: store, identifier: .bloodGlucose, value: value, unit: HKUnit.gramUnit(with: .milli).unitDivided(by: .literUnit(with: .deci)), date: date)
        case .bodyTemperature:
            try await writeSample(store: store, identifier: .bodyTemperature, value: value, unit: .degreeFahrenheit(), date: date)
        case .respiratoryRate:
            try await writeSample(store: store, identifier: .respiratoryRate, value: value, unit: HKUnit.count().unitDivided(by: .minute()), date: date)
        case .bloodPressure, .steps, .sleep:
            throw HealthKitError.unsupportedType
        }
    }

    func writeBloodPressure(systolic: Double, diastolic: Double, date: Date) async throws {
        guard let store = healthStore else { throw HealthKitError.notAvailable }

        let mmHg = HKUnit.millimeterOfMercury()
        guard let sysType = HKQuantityType.quantityType(forIdentifier: .bloodPressureSystolic),
              let diaType = HKQuantityType.quantityType(forIdentifier: .bloodPressureDiastolic)
        else { throw HealthKitError.unsupportedType }

        let sysSample = HKQuantitySample(type: sysType, quantity: HKQuantity(unit: mmHg, doubleValue: systolic), start: date, end: date)
        let diaSample = HKQuantitySample(type: diaType, quantity: HKQuantity(unit: mmHg, doubleValue: diastolic), start: date, end: date)

        try await store.save([sysSample, diaSample])
    }

    // MARK: - Legacy Methods (backward compat)

    func fetchTodaySteps() async -> Int {
        let dp = await fetchTodayStepsDataPoint()
        return Int(dp?.value ?? 0)
    }

    func fetchLatestHeartRate() async -> Double? {
        guard let store = healthStore,
              let hrType = HKQuantityType.quantityType(forIdentifier: .heartRate)
        else { return nil }
        return await fetchLatestQuantity(store: store, type: hrType, unit: HKUnit.count().unitDivided(by: .minute()))
    }

    func fetchSleepHours(for date: Date) async -> Double? {
        guard let store = healthStore,
              let sleepType = HKCategoryType.categoryType(forIdentifier: .sleepAnalysis)
        else { return nil }

        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: date)
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!
        let predicate = HKQuery.predicateForSamples(withStart: startOfDay, end: endOfDay, options: .strictStartDate)

        return await withCheckedContinuation { continuation in
            let query = HKSampleQuery(
                sampleType: sleepType,
                predicate: predicate,
                limit: HKObjectQueryNoLimit,
                sortDescriptors: [NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: true)]
            ) { _, samples, error in
                guard error == nil, let samples = samples as? [HKCategorySample] else {
                    continuation.resume(returning: nil)
                    return
                }

                let asleepValues: Set<Int> = [
                    HKCategoryValueSleepAnalysis.asleepCore.rawValue,
                    HKCategoryValueSleepAnalysis.asleepDeep.rawValue,
                    HKCategoryValueSleepAnalysis.asleepREM.rawValue,
                    HKCategoryValueSleepAnalysis.asleepUnspecified.rawValue,
                ]

                let totalSeconds = samples
                    .filter { asleepValues.contains($0.value) }
                    .reduce(0.0) { total, sample in
                        total + sample.endDate.timeIntervalSince(sample.startDate)
                    }

                let hours = totalSeconds / 3600.0
                continuation.resume(returning: hours > 0 ? hours : nil)
            }
            store.execute(query)
        }
    }

    func fetchLatestBloodPressure() async -> (systolic: Double, diastolic: Double)? {
        guard let store = healthStore,
              let sysType = HKQuantityType.quantityType(forIdentifier: .bloodPressureSystolic),
              let diaType = HKQuantityType.quantityType(forIdentifier: .bloodPressureDiastolic)
        else { return nil }

        let mmHg = HKUnit.millimeterOfMercury()

        async let systolic = fetchLatestQuantity(store: store, type: sysType, unit: mmHg)
        async let diastolic = fetchLatestQuantity(store: store, type: diaType, unit: mmHg)

        guard let sys = await systolic, let dia = await diastolic else { return nil }
        return (systolic: sys, diastolic: dia)
    }

    func fetchLatestBloodGlucose() async -> Double? {
        guard let store = healthStore,
              let glucoseType = HKQuantityType.quantityType(forIdentifier: .bloodGlucose)
        else { return nil }

        let mgPerDL = HKUnit.gramUnit(with: .milli).unitDivided(by: .literUnit(with: .deci))
        return await fetchLatestQuantity(store: store, type: glucoseType, unit: mgPerDL)
    }

    func fetchWeeklyStepsTrend() async -> [(date: Date, steps: Int)] {
        guard let store = healthStore,
              let stepsType = HKQuantityType.quantityType(forIdentifier: .stepCount)
        else { return [] }

        let calendar = Calendar.current
        let endDate = calendar.startOfDay(for: Date())
        guard let startDate = calendar.date(byAdding: .day, value: -6, to: endDate) else { return [] }

        let predicate = HKQuery.predicateForSamples(withStart: startDate, end: Date(), options: .strictStartDate)
        var interval = DateComponents()
        interval.day = 1

        return await withCheckedContinuation { continuation in
            let query = HKStatisticsCollectionQuery(
                quantityType: stepsType,
                quantitySamplePredicate: predicate,
                options: .cumulativeSum,
                anchorDate: startDate,
                intervalComponents: interval
            )

            query.initialResultsHandler = { _, results, error in
                guard error == nil, let results else {
                    continuation.resume(returning: [])
                    return
                }

                var trend: [(date: Date, steps: Int)] = []
                results.enumerateStatistics(from: startDate, to: endDate) { statistics, _ in
                    let steps = statistics.sumQuantity()?.doubleValue(for: .count()) ?? 0
                    trend.append((date: statistics.startDate, steps: Int(steps)))
                }

                continuation.resume(returning: trend)
            }

            store.execute(query)
        }
    }

    // MARK: - Private Helpers

    private func fetchLatestQuantity(store: HKHealthStore, type: HKQuantityType, unit: HKUnit) async -> Double? {
        return await withCheckedContinuation { continuation in
            let query = HKSampleQuery(
                sampleType: type,
                predicate: nil,
                limit: 1,
                sortDescriptors: [NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: false)]
            ) { _, samples, error in
                guard error == nil,
                      let sample = samples?.first as? HKQuantitySample
                else {
                    continuation.resume(returning: nil)
                    return
                }
                continuation.resume(returning: sample.quantity.doubleValue(for: unit))
            }
            store.execute(query)
        }
    }

    private func fetchLatestVitalDataPoint(identifier: HKQuantityTypeIdentifier, unit: HKUnit) async -> VitalDataPoint? {
        guard let store = healthStore,
              let type = HKQuantityType.quantityType(forIdentifier: identifier)
        else { return nil }

        return await withCheckedContinuation { continuation in
            let query = HKSampleQuery(
                sampleType: type,
                predicate: nil,
                limit: 1,
                sortDescriptors: [NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: false)]
            ) { _, samples, error in
                guard error == nil,
                      let sample = samples?.first as? HKQuantitySample
                else {
                    continuation.resume(returning: nil)
                    return
                }
                let value = sample.quantity.doubleValue(for: unit)
                let source = sample.sourceRevision.source.name
                continuation.resume(returning: VitalDataPoint(value: value, date: sample.startDate, source: source))
            }
            store.execute(query)
        }
    }

    private func fetchLatestBloodPressureReading() async -> BloodPressureReading? {
        guard let store = healthStore,
              let sysType = HKQuantityType.quantityType(forIdentifier: .bloodPressureSystolic),
              let diaType = HKQuantityType.quantityType(forIdentifier: .bloodPressureDiastolic)
        else { return nil }

        let mmHg = HKUnit.millimeterOfMercury()

        async let sysPoint = fetchLatestVitalDataPoint(identifier: .bloodPressureSystolic, unit: mmHg)
        async let diaPoint = fetchLatestVitalDataPoint(identifier: .bloodPressureDiastolic, unit: mmHg)

        guard let sys = await sysPoint, let dia = await diaPoint else { return nil }
        return BloodPressureReading(systolic: sys.value, diastolic: dia.value, date: sys.date, source: sys.source)
    }

    private func fetchTodayStepsDataPoint() async -> VitalDataPoint? {
        guard let store = healthStore,
              let stepsType = HKQuantityType.quantityType(forIdentifier: .stepCount)
        else { return nil }

        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: Date())
        let predicate = HKQuery.predicateForSamples(withStart: startOfDay, end: Date(), options: .strictStartDate)

        return await withCheckedContinuation { continuation in
            let query = HKStatisticsQuery(
                quantityType: stepsType,
                quantitySamplePredicate: predicate,
                options: .cumulativeSum
            ) { _, result, _ in
                let steps = result?.sumQuantity()?.doubleValue(for: .count()) ?? 0
                if steps > 0 {
                    continuation.resume(returning: VitalDataPoint(value: steps, date: Date(), source: "Apple Health"))
                } else {
                    continuation.resume(returning: nil)
                }
            }
            store.execute(query)
        }
    }

    private func fetchLatestSleepDataPoint() async -> VitalDataPoint? {
        let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: Date()) ?? Date()
        if let hours = await fetchSleepHours(for: yesterday) {
            return VitalDataPoint(value: hours, date: yesterday, source: "Apple Health")
        }
        return nil
    }

    private func fetchQuantityHistory(identifier: HKQuantityTypeIdentifier, unit: HKUnit, days: Int) async -> [VitalDataPoint] {
        guard let store = healthStore,
              let type = HKQuantityType.quantityType(forIdentifier: identifier)
        else { return [] }

        let calendar = Calendar.current
        let startDate = calendar.date(byAdding: .day, value: -days, to: Date())!
        let predicate = HKQuery.predicateForSamples(withStart: startDate, end: Date(), options: .strictStartDate)

        let samples = await fetchSamples(store: store, type: type, predicate: predicate, limit: 100)
        return samples.map { sample in
            VitalDataPoint(
                value: sample.quantity.doubleValue(for: unit),
                date: sample.startDate,
                source: sample.sourceRevision.source.name
            )
        }.sorted { $0.date > $1.date }
    }

    private func fetchSamples(store: HKHealthStore, type: HKQuantityType, predicate: NSPredicate, limit: Int) async -> [HKQuantitySample] {
        return await withCheckedContinuation { continuation in
            let query = HKSampleQuery(
                sampleType: type,
                predicate: predicate,
                limit: limit,
                sortDescriptors: [NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: false)]
            ) { _, samples, error in
                guard error == nil, let samples = samples as? [HKQuantitySample] else {
                    continuation.resume(returning: [])
                    return
                }
                continuation.resume(returning: samples)
            }
            store.execute(query)
        }
    }

    private func fetchDailyStepsHistory(days: Int) async -> [VitalDataPoint] {
        guard let store = healthStore,
              let stepsType = HKQuantityType.quantityType(forIdentifier: .stepCount)
        else { return [] }

        let calendar = Calendar.current
        let endDate = calendar.startOfDay(for: Date())
        guard let startDate = calendar.date(byAdding: .day, value: -(days - 1), to: endDate) else { return [] }

        let predicate = HKQuery.predicateForSamples(withStart: startDate, end: Date(), options: .strictStartDate)
        var interval = DateComponents()
        interval.day = 1

        return await withCheckedContinuation { continuation in
            let query = HKStatisticsCollectionQuery(
                quantityType: stepsType,
                quantitySamplePredicate: predicate,
                options: .cumulativeSum,
                anchorDate: startDate,
                intervalComponents: interval
            )

            query.initialResultsHandler = { _, results, error in
                guard error == nil, let results else {
                    continuation.resume(returning: [])
                    return
                }

                var points: [VitalDataPoint] = []
                results.enumerateStatistics(from: startDate, to: endDate) { statistics, _ in
                    let steps = statistics.sumQuantity()?.doubleValue(for: .count()) ?? 0
                    points.append(VitalDataPoint(value: steps, date: statistics.startDate, source: "Apple Health"))
                }

                continuation.resume(returning: points.reversed())
            }

            store.execute(query)
        }
    }

    private func fetchSleepHistory(days: Int) async -> [VitalDataPoint] {
        var points: [VitalDataPoint] = []
        let calendar = Calendar.current

        for offset in 1...days {
            let date = calendar.date(byAdding: .day, value: -offset, to: Date())!
            if let hours = await fetchSleepHours(for: date) {
                points.append(VitalDataPoint(value: hours, date: date, source: "Apple Health"))
            }
        }

        return points
    }

    private func writeSample(store: HKHealthStore, identifier: HKQuantityTypeIdentifier, value: Double, unit: HKUnit, date: Date) async throws {
        guard let type = HKQuantityType.quantityType(forIdentifier: identifier) else {
            throw HealthKitError.unsupportedType
        }

        let quantity = HKQuantity(unit: unit, doubleValue: value)
        let sample = HKQuantitySample(type: type, quantity: quantity, start: date, end: date)
        try await store.save(sample)
    }
}
