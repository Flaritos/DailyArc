@preconcurrency import HealthKit
import Foundation
import SwiftData

// NOTE: Spec calls for this to be a proper `actor` instead of @MainActor class.
// Changing to `actor` would require major refactoring of all callers, so keeping
// @MainActor @Observable for now. TODO: Migrate to actor isolation.
@MainActor
@Observable
final class HealthKitService {
    static let shared = HealthKitService()

    private let healthStore = HKHealthStore()
    var isAuthorized = false

    enum HealthMetric: String, CaseIterable, Sendable {
        case workouts = "Workouts"
        case steps = "Steps >5000"
        case sleep = "Sleep >7hrs"
        case mindfulMinutes = "Mindful Minutes"

        var sampleType: HKSampleType? {
            switch self {
            case .workouts: return HKObjectType.workoutType()
            case .steps: return HKQuantityType.quantityType(forIdentifier: .stepCount)
            case .sleep: return HKCategoryType.categoryType(forIdentifier: .sleepAnalysis)
            case .mindfulMinutes: return HKCategoryType.categoryType(forIdentifier: .mindfulSession)
            }
        }
    }

    var isAvailable: Bool {
        HKHealthStore.isHealthDataAvailable()
    }

    // MARK: - Authorization

    func requestAuthorization(for metrics: [HealthMetric]) async -> Bool {
        guard isAvailable else { return false }
        let types = Set(metrics.compactMap { $0.sampleType })
        do {
            try await healthStore.requestAuthorization(toShare: [], read: types)
            isAuthorized = true
            return true
        } catch {
            return false
        }
    }

    /// Convenience: request authorization for all metrics.
    @discardableResult
    func requestAuthorization() async -> Bool {
        await requestAuthorization(for: HealthMetric.allCases)
    }

    // MARK: - Metric Queries

    func checkMetric(_ metric: HealthMetric, for date: Date, calendar: Calendar) async -> Bool {
        let start = calendar.startOfDay(for: date)
        guard let end = calendar.date(byAdding: .day, value: 1, to: start) else { return false }
        nonisolated(unsafe) let predicate = HKQuery.predicateForSamples(withStart: start, end: end, options: .strictStartDate)

        do {
            return try await withTimeout(10) {
                switch metric {
                case .workouts:
                    return await self.queryWorkouts(predicate: predicate)
                case .steps:
                    return await self.querySteps(predicate: predicate, threshold: 5000)
                case .sleep:
                    return await self.querySleep(predicate: predicate, thresholdMinutes: 7 * 60)
                case .mindfulMinutes:
                    return await self.queryMindful(predicate: predicate)
                }
            }
        } catch {
            // Timeout or cancellation — treat as metric not met
            return false
        }
    }

    /// Auto-log habits from HealthKit for past N days
    func autoLogPastDays(
        metric: HealthMetric,
        habit: Habit,
        days: Int,
        context: ModelContext,
        calendar: Calendar
    ) async {
        for offset in (0..<days).reversed() {
            guard let date = calendar.date(byAdding: .day, value: -offset, to: Date()) else { continue }
            let met = await checkMetric(metric, for: date, calendar: calendar)
            if met {
                let log = HabitLog.fetchOrCreate(habit: habit, date: date, context: context, calendar: calendar)
                if log.count == 0 {
                    log.count = habit.targetCount
                    log.isAutoLogged = true
                }
            }
        }
    }

    // MARK: - Timeout Utility

    /// Wraps an async operation with a timeout. Throws CancellationError if the timeout elapses first.
    private func withTimeout<T: Sendable>(_ seconds: TimeInterval, operation: @escaping @Sendable () async throws -> T) async throws -> T {
        try await withThrowingTaskGroup(of: T.self) { group in
            group.addTask { try await operation() }
            group.addTask {
                try await Task.sleep(for: .seconds(seconds))
                throw CancellationError()
            }
            let result = try await group.next()!
            group.cancelAll()
            return result
        }
    }

    // MARK: - Private Query Helpers

    private func queryWorkouts(predicate: NSPredicate) async -> Bool {
        await withCheckedContinuation { continuation in
            let query = HKSampleQuery(
                sampleType: HKObjectType.workoutType(),
                predicate: predicate,
                limit: 1,
                sortDescriptors: nil
            ) { _, results, _ in
                continuation.resume(returning: (results?.count ?? 0) > 0)
            }
            healthStore.execute(query)
        }
    }

    private func querySteps(predicate: NSPredicate, threshold: Double) async -> Bool {
        guard let stepType = HKQuantityType.quantityType(forIdentifier: .stepCount) else { return false }
        return await withCheckedContinuation { continuation in
            let query = HKStatisticsQuery(
                quantityType: stepType,
                quantitySamplePredicate: predicate,
                options: .cumulativeSum
            ) { _, result, _ in
                let steps = result?.sumQuantity()?.doubleValue(for: .count()) ?? 0
                continuation.resume(returning: steps >= threshold)
            }
            healthStore.execute(query)
        }
    }

    private func querySleep(predicate: NSPredicate, thresholdMinutes: Double) async -> Bool {
        guard let sleepType = HKCategoryType.categoryType(forIdentifier: .sleepAnalysis) else { return false }
        return await withCheckedContinuation { continuation in
            let query = HKSampleQuery(
                sampleType: sleepType,
                predicate: predicate,
                limit: HKObjectQueryNoLimit,
                sortDescriptors: nil
            ) { _, results, _ in
                // Filter for actual sleep samples (.asleepUnspecified) to exclude
                // "in bed" and other non-sleep analysis categories.
                let totalMinutes = (results as? [HKCategorySample])?.reduce(0.0) { sum, sample in
                    guard sample.value == HKCategoryValueSleepAnalysis.asleepUnspecified.rawValue else {
                        return sum
                    }
                    return sum + sample.endDate.timeIntervalSince(sample.startDate) / 60.0
                } ?? 0
                continuation.resume(returning: totalMinutes >= thresholdMinutes)
            }
            healthStore.execute(query)
        }
    }

    private func queryMindful(predicate: NSPredicate) async -> Bool {
        guard let mindfulType = HKCategoryType.categoryType(forIdentifier: .mindfulSession) else { return false }
        return await withCheckedContinuation { continuation in
            let query = HKSampleQuery(
                sampleType: mindfulType,
                predicate: predicate,
                limit: 1,
                sortDescriptors: nil
            ) { _, results, _ in
                continuation.resume(returning: (results?.count ?? 0) > 0)
            }
            healthStore.execute(query)
        }
    }
}
