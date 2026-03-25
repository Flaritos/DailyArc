import Foundation
import SwiftData

/// Manages Streak Shield premium feature.
/// Premium users get 2 shields per month that automatically protect streaks when a day is missed.
/// Shielded dates are stored in UserDefaults as JSON (avoids SwiftData model changes).
@MainActor
final class StreakShieldService {

    // MARK: - Singleton

    static let shared = StreakShieldService()
    private init() { resetMonthIfNeeded() }

    // MARK: - Constants

    static let maxShieldsPerMonth = 2

    // MARK: - Storage Keys

    private static let shieldsUsedKey = "streakShieldsUsedThisMonth"
    private static let shieldsMonthKey = "streakShieldsMonth"
    private static let shieldedDatesKey = "streakShieldedDates"

    // MARK: - Computed Properties

    /// Number of shields used this month.
    var shieldsUsedThisMonth: Int {
        UserDefaults.standard.integer(forKey: Self.shieldsUsedKey)
    }

    /// Number of shields remaining this month.
    var shieldsRemaining: Int {
        max(0, Self.maxShieldsPerMonth - shieldsUsedThisMonth)
    }

    /// All shielded dates, keyed by habit ID string.
    var allShieldedDates: [String: [String]] {
        guard let data = UserDefaults.standard.data(forKey: Self.shieldedDatesKey),
              let decoded = try? JSONDecoder().decode([String: [String]].self, from: data) else {
            return [:]
        }
        return decoded
    }

    /// Get shielded dates for a specific habit.
    func shieldedDates(for habitID: UUID) -> Set<Date> {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withFullDate]
        guard let dateStrings = allShieldedDates[habitID.uuidString] else { return [] }
        return Set(dateStrings.compactMap { formatter.date(from: $0) })
    }

    /// Check if a specific date is shielded for a habit.
    func isDateShielded(_ date: Date, for habitID: UUID, calendar: Calendar) -> Bool {
        let normalizedDate = calendar.startOfDay(for: date)
        return shieldedDates(for: habitID).contains { calendar.isDate($0, inSameDayAs: normalizedDate) }
    }

    // MARK: - Shield Application

    /// Attempt to apply a shield for a missed date on a habit.
    /// Returns true if shield was successfully applied.
    @discardableResult
    func applyShield(for habitID: UUID, on date: Date, calendar: Calendar) -> Bool {
        resetMonthIfNeeded()
        guard shieldsRemaining > 0 else { return false }

        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withFullDate]
        let normalizedDate = calendar.startOfDay(for: date)
        let dateString = formatter.string(from: normalizedDate)

        // Check if already shielded
        var allDates = allShieldedDates
        let habitKey = habitID.uuidString
        var habitDates = allDates[habitKey] ?? []
        guard !habitDates.contains(dateString) else { return false }

        // Apply shield
        habitDates.append(dateString)
        allDates[habitKey] = habitDates
        saveShieldedDates(allDates)

        // Increment usage
        UserDefaults.standard.set(shieldsUsedThisMonth + 1, forKey: Self.shieldsUsedKey)
        return true
    }

    /// Auto-apply shields for a habit's missed days in its current streak window.
    /// Called during streak recalculation to retroactively protect streaks.
    /// Returns the set of dates that were shielded.
    func autoApplyShields(
        for habit: Habit,
        logs: [HabitLog],
        calendar: Calendar
    ) -> Set<Date> {
        guard StoreKitManager.shared.isPremium else { return [] }
        resetMonthIfNeeded()
        guard shieldsRemaining > 0 else { return [] }

        let today = calendar.startOfDay(for: Date())
        let completedDates = Set(
            logs.filter { $0.count >= habit.targetCount }
                .map { calendar.startOfDay(for: $0.date) }
        )
        let existingShielded = shieldedDates(for: habit.id)

        // Walk backward from yesterday to find gaps in the streak
        var missedDates: [Date] = []
        var checkDate = calendar.date(byAdding: .day, value: -1, to: today)!
        let scanLimit = 14 // Look back up to 14 days

        for _ in 0..<scanLimit {
            guard checkDate >= habit.startDate else { break }

            if habit.shouldAppear(on: checkDate, calendar: calendar) {
                if completedDates.contains(checkDate) || existingShielded.contains(where: { calendar.isDate($0, inSameDayAs: checkDate) }) {
                    // Completed or already shielded, continue backward
                } else {
                    // Missed day found
                    missedDates.append(checkDate)
                    if missedDates.count >= shieldsRemaining {
                        break
                    }
                }
            }

            checkDate = calendar.date(byAdding: .day, value: -1, to: checkDate)!
        }

        // Only shield if there's an active streak beyond the gap
        guard !missedDates.isEmpty else { return [] }

        // Verify there's a completed day before the earliest missed day
        let earliestMiss = missedDates.sorted().first!
        var prevDay = calendar.date(byAdding: .day, value: -1, to: earliestMiss)!
        var foundCompletedBefore = false
        for _ in 0..<7 {
            guard prevDay >= habit.startDate else { break }
            if habit.shouldAppear(on: prevDay, calendar: calendar) {
                if completedDates.contains(prevDay) || existingShielded.contains(where: { calendar.isDate($0, inSameDayAs: prevDay) }) {
                    foundCompletedBefore = true
                    break
                } else {
                    break // Another gap — don't shield
                }
            }
            prevDay = calendar.date(byAdding: .day, value: -1, to: prevDay)!
        }

        guard foundCompletedBefore else { return [] }

        // Apply shields
        var shieldedSet: Set<Date> = []
        for date in missedDates {
            if applyShield(for: habit.id, on: date, calendar: calendar) {
                shieldedSet.insert(calendar.startOfDay(for: date))
            }
        }

        return shieldedSet
    }

    // MARK: - Month Reset

    /// Reset shield count at the start of each month.
    private func resetMonthIfNeeded() {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM"
        let currentMonth = formatter.string(from: Date())
        let storedMonth = UserDefaults.standard.string(forKey: Self.shieldsMonthKey) ?? ""

        if storedMonth != currentMonth {
            UserDefaults.standard.set(0, forKey: Self.shieldsUsedKey)
            UserDefaults.standard.set(currentMonth, forKey: Self.shieldsMonthKey)
        }
    }

    // MARK: - Private

    private func saveShieldedDates(_ dates: [String: [String]]) {
        if let data = try? JSONEncoder().encode(dates) {
            UserDefaults.standard.set(data, forKey: Self.shieldedDatesKey)
        }
    }
}
