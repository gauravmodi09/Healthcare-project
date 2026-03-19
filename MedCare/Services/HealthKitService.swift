import Foundation
import HealthKit

/// HealthKit integration service — read-only access to Apple Health data
@Observable
final class HealthKitService {

    // MARK: - Properties

    var isAuthorized = false

    private let healthStore: HKHealthStore?
    private let isAvailable: Bool

    // MARK: - HealthKit Types

    private let readTypes: Set<HKObjectType> = {
        var types = Set<HKObjectType>()
        if let steps = HKQuantityType.quantityType(forIdentifier: .stepCount) { types.insert(steps) }
        if let hr = HKQuantityType.quantityType(forIdentifier: .heartRate) { types.insert(hr) }
        if let sleep = HKCategoryType.categoryType(forIdentifier: .sleepAnalysis) { types.insert(sleep) }
        if let bpSys = HKQuantityType.quantityType(forIdentifier: .bloodPressureSystolic) { types.insert(bpSys) }
        if let bpDia = HKQuantityType.quantityType(forIdentifier: .bloodPressureDiastolic) { types.insert(bpDia) }
        if let glucose = HKQuantityType.quantityType(forIdentifier: .bloodGlucose) { types.insert(glucose) }
        if let weight = HKQuantityType.quantityType(forIdentifier: .bodyMass) { types.insert(weight) }
        if let height = HKQuantityType.quantityType(forIdentifier: .height) { types.insert(height) }
        return types
    }()

    // MARK: - Errors

    enum HealthKitError: LocalizedError {
        case notAvailable
        case authorizationFailed
        case queryFailed(String)

        var errorDescription: String? {
            switch self {
            case .notAvailable:
                return "HealthKit is not available on this device."
            case .authorizationFailed:
                return "HealthKit authorization was denied."
            case .queryFailed(let reason):
                return "HealthKit query failed: \(reason)"
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

        try await store.requestAuthorization(toShare: [], read: readTypes)
        isAuthorized = true
    }

    // MARK: - Steps

    func fetchTodaySteps() async -> Int {
        guard let store = healthStore,
              let stepsType = HKQuantityType.quantityType(forIdentifier: .stepCount)
        else { return 0 }

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
                continuation.resume(returning: Int(steps))
            }
            store.execute(query)
        }
    }

    // MARK: - Heart Rate

    func fetchLatestHeartRate() async -> Double? {
        guard let store = healthStore,
              let hrType = HKQuantityType.quantityType(forIdentifier: .heartRate)
        else { return nil }

        return await fetchLatestQuantity(store: store, type: hrType, unit: HKUnit.count().unitDivided(by: .minute()))
    }

    // MARK: - Sleep

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

                // Only count asleep categories (not inBed or awake)
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

    // MARK: - Blood Pressure

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

    // MARK: - Blood Glucose

    func fetchLatestBloodGlucose() async -> Double? {
        guard let store = healthStore,
              let glucoseType = HKQuantityType.quantityType(forIdentifier: .bloodGlucose)
        else { return nil }

        let mgPerDL = HKUnit.gramUnit(with: .milli).unitDivided(by: .literUnit(with: .deci))
        return await fetchLatestQuantity(store: store, type: glucoseType, unit: mgPerDL)
    }

    // MARK: - Weekly Steps Trend

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
}
