import Foundation
import SwiftData

/// Recalculates and caches streak values on Habit models.
/// IMPORTANT: Does NOT call context.save() — the caller's DebouncedSave handles persistence.
@MainActor
final class StreakEngine {
    /// nonisolated init allows StreakEngine to be created in @State without @MainActor context.
    nonisolated init() {}

    /// Cold-launch streak reconciliation time budget (ms).
    static let coldLaunchBudgetMs: Int = 200

    /// Recalculate and cache streaks on the Habit model.
    /// - Parameters:
    ///   - habit: The habit to recalculate streaks for.
    ///   - logs: Pre-fetched logs for this habit (avoids relationship fault).
    ///   - isDeletion: True when called after a log deletion/undo/recovery (forces full bestStreak recompute).
    ///   - isFirstCallToday: REQUIRED — prevents double-increment on multi-count habits.
    ///   - calendar: Caller must pass Calendar.current captured on @MainActor.
    func recalculateStreaks(for habit: Habit, logs: [HabitLog], isDeletion: Bool = false, isFirstCallToday: Bool, calendar: Calendar) {
        // Auto-apply streak shields for premium users before calculating
        if StoreKitManager.shared.isPremium && !isDeletion {
            StreakShieldService.shared.autoApplyShields(for: habit, logs: logs, calendar: calendar)
        }

        let today = calendar.startOfDay(for: Date())
        // Include isRecovered logs in streak calculation — that's the whole point of recovery.
        let logCompletedDates = Set(
            logs
                .filter { $0.count >= habit.targetCount }
                .map { calendar.startOfDay(for: $0.date) }
        )
        // Merge shielded dates into completed dates for streak continuity
        let shieldedDates = StreakShieldService.shared.shieldedDates(for: habit.id)
        let completedDates = logCompletedDates.union(shieldedDates)

        let todayCompleted = completedDates.contains(today)
        var checkDate = todayCompleted ? today : calendar.date(byAdding: .day, value: -1, to: today)!

        // Incremental O(1) path: only when not deletion, today completed, streak > 0, and first call today
        if !isDeletion && isFirstCallToday && todayCompleted && habit.currentStreak > 0 {
            var prevDay = calendar.date(byAdding: .day, value: -1, to: today)!
            while !habit.shouldAppear(on: prevDay, calendar: calendar) && prevDay > habit.startDate {
                prevDay = calendar.date(byAdding: .day, value: -1, to: prevDay)!
            }
            let prevDayCompleted = completedDates.contains(prevDay)
            if prevDayCompleted {
                habit.currentStreak = habit.currentStreak + 1
                habit.bestStreak = max(habit.bestStreak, habit.currentStreak)
                return
            }
        }

        // Full recalculation path
        var current = todayCompleted ? 1 : 0
        if !todayCompleted {
            while !habit.shouldAppear(on: checkDate, calendar: calendar) && checkDate > habit.startDate {
                checkDate = calendar.date(byAdding: .day, value: -1, to: checkDate)!
            }
            if completedDates.contains(checkDate) {
                current = 1
            } else {
                habit.currentStreak = 0
                habit.bestStreak = computeBestStreak(habit: habit, completedDates: completedDates, calendar: calendar)
                return
            }
        }

        // Walk backward counting consecutive applicable days
        checkDate = calendar.date(byAdding: .day, value: -1, to: checkDate)!
        while checkDate >= habit.startDate {
            if !habit.shouldAppear(on: checkDate, calendar: calendar) {
                checkDate = calendar.date(byAdding: .day, value: -1, to: checkDate)!
                continue
            }
            if completedDates.contains(checkDate) {
                current += 1
                checkDate = calendar.date(byAdding: .day, value: -1, to: checkDate)!
            } else {
                break
            }
        }

        habit.currentStreak = current
        if isDeletion {
            habit.bestStreak = computeBestStreak(habit: habit, completedDates: completedDates, calendar: calendar)
        } else {
            habit.bestStreak = max(habit.bestStreak, current)
        }
    }

    /// Compute best streak ever by walking all completed dates. O(n log n) due to sort.
    /// Called only on deletion/undo/recovery path.
    func computeBestStreak(habit: Habit, completedDates: Set<Date>, calendar: Calendar) -> Int {
        guard !completedDates.isEmpty else { return 0 }
        let sorted = completedDates.sorted()
        var best = 1
        var current = 1

        for i in 1..<sorted.count {
            var expectedDate = calendar.date(byAdding: .day, value: 1, to: sorted[i - 1])!
            // Skip non-applicable days
            while !habit.shouldAppear(on: expectedDate, calendar: calendar) && expectedDate < sorted[i] {
                expectedDate = calendar.date(byAdding: .day, value: 1, to: expectedDate)!
            }
            if sorted[i] == expectedDate {
                current += 1
                best = max(best, current)
            } else {
                current = 1
            }
        }
        return best
    }

    /// Check if streak recovery is possible (missed 1-2 applicable days).
    func streakRecoveryAvailable(for habit: Habit, logs: [HabitLog], calendar: Calendar) -> (available: Bool, missedDates: [Date]) {
        let today = calendar.startOfDay(for: Date())
        var applicableDays: [Date] = []
        var scanDate = calendar.date(byAdding: .day, value: -1, to: today)!
        for _ in 0..<7 {
            if habit.shouldAppear(on: scanDate, calendar: calendar) {
                applicableDays.append(scanDate)
                if applicableDays.count == 3 { break }
            }
            scanDate = calendar.date(byAdding: .day, value: -1, to: scanDate)!
        }
        guard !applicableDays.isEmpty else { return (false, []) }

        let completedDates = Set(logs.filter { $0.count >= habit.targetCount }.map { calendar.startOfDay(for: $0.date) })
        let missedDates = applicableDays.filter { !completedDates.contains($0) }
        guard missedDates.count >= 1 && missedDates.count <= 2 else { return (false, []) }

        // Verify there's an active streak to recover
        let earliestMiss = missedDates.sorted().first!
        var prevDay = calendar.date(byAdding: .day, value: -1, to: earliestMiss)!
        while !habit.shouldAppear(on: prevDay, calendar: calendar) && prevDay > habit.startDate {
            prevDay = calendar.date(byAdding: .day, value: -1, to: prevDay)!
        }
        guard completedDates.contains(prevDay) else { return (false, []) }

        // Rolling 30-day recovery count check
        let thirtyDaysAgo = calendar.date(byAdding: .day, value: -30, to: today)!
        if let data = UserDefaults.standard.data(forKey: "allRecoveryDates"),
           let allDates = try? JSONDecoder().decode([String: [String]].self, from: data),
           let habitDates = allDates[habit.id.uuidString] {
            let recentCount = habitDates.compactMap { ISO8601DateFormatter().date(from: $0) }
                .filter { $0 >= thirtyDaysAgo }.count
            guard recentCount < 2 else { return (false, []) }
        }

        return (true, missedDates.sorted())
    }

    /// Apply streak recovery by backfilling HabitLogs with isRecovered=true.
    func applyRecovery(for habit: Habit, dates: [Date], context: ModelContext, calendar: Calendar) {
        for date in dates {
            let log = HabitLog.fetchOrCreate(habit: habit, date: date, context: context, calendar: calendar)
            log.count = habit.targetCount
            log.isRecovered = true
        }
        let habitID = habit.id
        let descriptor = FetchDescriptor<HabitLog>(predicate: #Predicate { $0.habitIDDenormalized == habitID })
        let allLogs = (try? context.fetch(descriptor)) ?? []
        recalculateStreaks(for: habit, logs: allLogs, isDeletion: false, isFirstCallToday: false, calendar: calendar)
    }
}
