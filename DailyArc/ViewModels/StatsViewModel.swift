import Foundation
import SwiftData
import SwiftUI

/// ViewModel for the Stats tab. Manages snapshot computation, correlation engine, and suggestions.
/// @Query lives in the View — this ViewModel receives data via method calls.
@Observable
@MainActor
final class StatsViewModel {

    // MARK: - Published State

    var snapshots: [DaySnapshot] = []
    var selectedSnapshot: DaySnapshot?
    var isLoading = false
    var selectedSegment: StatsSegment = .yourArc

    // Correlation state
    var correlationResults: [CorrelationEngine.CorrelationResult] = []
    var isComputingCorrelations = false
    var correlationError: String?

    // Suggestion state
    var suggestions: [RuleEngine.Suggestion] = []

    // Data readiness
    var pairedDataDays: Int = 0

    enum StatsSegment: String, CaseIterable {
        case yourArc = "Your Arc"
        case insights = "Insights"
    }

    // MARK: - Task Handles

    private var correlationTask: Task<[CorrelationEngine.CorrelationResult], Never>?
    private var correlationRetryTask: Task<Void, Never>?

    // MARK: - Date Range

    private let calendar = Calendar.current

    var yearStartDate: Date {
        calendar.date(byAdding: .day, value: -364, to: calendar.startOfDay(for: Date()))
            ?? Date()
    }

    var yearEndDate: Date {
        calendar.startOfDay(for: Date())
    }

    // MARK: - Data Loading

    /// Compute snapshots from pre-fetched data (View passes @Query results here).
    func loadSnapshots(habits: [Habit], logs: [HabitLog], moods: [MoodEntry]) {
        isLoading = true
        snapshots = DaySnapshot.snapshots(
            habits: habits,
            logs: logs,
            moods: moods,
            from: yearStartDate,
            to: yearEndDate,
            calendar: calendar
        )
        isLoading = false

        // Compute paired data days for insight progress
        pairedDataDays = CorrelationEngine.pairedDataDaysCount(
            moods: moods, logs: logs, calendar: calendar
        )
    }

    /// Mood entries for the last 30 days, filtered to those with actual mood data.
    func recentMoodEntries(from moods: [MoodEntry]) -> [MoodEntry] {
        let thirtyDaysAgo = calendar.date(byAdding: .day, value: -30, to: Date()) ?? Date()
        return moods
            .filter { $0.moodScore > 0 && $0.date >= thirtyDaysAgo }
            .sorted { $0.date < $1.date }
    }

    // MARK: - Correlation Computation

    func computeCorrelations(habits: [Habit], logs: [HabitLog], moods: [MoodEntry]) {
        // Cancel previous in-flight computation
        correlationTask?.cancel()
        correlationRetryTask?.cancel()

        guard pairedDataDays >= 14 else {
            correlationResults = []
            return
        }

        isComputingCorrelations = true
        correlationError = nil

        // Extract Sendable snapshots on @MainActor
        let (habitSnapshots, moodSnapshots) = CorrelationEngine.extractSnapshots(
            habits: habits, allLogs: logs, moods: moods
        )
        let cal = calendar

        correlationTask = Task.detached { @Sendable in
            CorrelationEngine.computeCorrelations(
                habits: habitSnapshots, moods: moodSnapshots, calendar: cal
            )
        }

        // Await results back on @MainActor via Task
        Task { @MainActor in
            guard let task = correlationTask else { return }
            let results = await task.value
            guard !task.isCancelled else { return }

            correlationResults = results
            isComputingCorrelations = false

            // Check for partial results — if timed out with zero results
            if results.isEmpty && results.contains(where: { $0.isPartial }) {
                correlationError = "Still crunching your data \u{2014} check back in a moment."
            }

            // Generate suggestions using correlations
            computeSuggestions(habits: habits, logs: logs, moods: moods)
        }
    }

    // MARK: - Suggestion Computation

    func computeSuggestions(habits: [Habit], logs: [HabitLog], moods: [MoodEntry]) {
        let (habitSnaps, logSnaps, moodSnaps) = RuleEngine.extractSnapshots(
            habits: habits, logs: logs, moods: moods
        )
        let cal = calendar
        let correlations = correlationResults

        Task.detached { @Sendable in
            let results = RuleEngine.generateSuggestions(
                habits: habitSnaps, logs: logSnaps, moods: moodSnaps,
                correlations: correlations, calendar: cal
            )
            await MainActor.run {
                self.suggestions = results
            }
        }
    }

    // MARK: - Cleanup

    func cancelTasks() {
        correlationTask?.cancel()
        correlationRetryTask?.cancel()
    }

    // MARK: - Per-Habit Stats

    func completionRate(for habit: Habit, logs: [HabitLog]) -> Double {
        let habitLogs = logs.filter { $0.habitIDDenormalized == habit.id }
        let startDate = calendar.startOfDay(for: habit.startDate)
        let today = calendar.startOfDay(for: Date())

        var totalDays = 0
        var completedDays = 0
        var current = startDate

        let logsByDate = Dictionary(grouping: habitLogs) { calendar.startOfDay(for: $0.date) }

        while current <= today {
            if habit.shouldAppear(on: current, calendar: calendar) {
                totalDays += 1
                if let log = logsByDate[current]?.first, log.count >= habit.targetCount {
                    completedDays += 1
                }
            }
            current = calendar.date(byAdding: .day, value: 1, to: current)
                ?? current.addingTimeInterval(86400)
        }

        return totalDays > 0 ? Double(completedDays) / Double(totalDays) : 0
    }

    /// Returns an array of 7 Ints representing the completion count for the habit
    /// over the last 7 days (index 0 = 6 days ago, index 6 = today).
    func last7DaysCounts(for habit: Habit, logs: [HabitLog]) -> [Int] {
        let habitLogs = logs.filter { $0.habitIDDenormalized == habit.id }
        let today = calendar.startOfDay(for: Date())
        let logsByDate = Dictionary(grouping: habitLogs) { calendar.startOfDay(for: $0.date) }

        var counts: [Int] = []
        for i in (0..<7).reversed() {
            let day = calendar.date(byAdding: .day, value: -i, to: today)
                ?? today.addingTimeInterval(Double(-i) * 86400)
            let dayStart = calendar.startOfDay(for: day)
            let count = logsByDate[dayStart]?.first?.count ?? 0
            counts.append(count)
        }
        return counts
    }

    // MARK: - Mood Day-of-Week Pattern (A4)

    /// Checks for consistent below-average mood on a specific weekday.
    /// Returns an annotation string like "Your mood tends to dip on Mondays." if a pattern
    /// is detected (3+ occurrences of below-average mood on the same weekday).
    func moodDayOfWeekInsight(moods: [MoodEntry]) -> String? {
        let scoredMoods = moods.filter { $0.moodScore > 0 }
        guard scoredMoods.count >= 7 else { return nil }

        let overallAvg = Double(scoredMoods.map(\.moodScore).reduce(0, +)) / Double(scoredMoods.count)

        // Group moods by weekday (1=Sunday ... 7=Saturday)
        var weekdayScores: [Int: [Int]] = [:]
        for mood in scoredMoods {
            let weekday = calendar.component(.weekday, from: mood.date)
            weekdayScores[weekday, default: []].append(mood.moodScore)
        }

        // Find weekdays where mood consistently dips below average
        let dayNames = ["", "Sundays", "Mondays", "Tuesdays", "Wednesdays", "Thursdays", "Fridays", "Saturdays"]
        for (weekday, scores) in weekdayScores {
            let belowAvg = scores.filter { Double($0) < overallAvg }
            if belowAvg.count >= 3 {
                let dayAvg = Double(scores.reduce(0, +)) / Double(scores.count)
                // Only flag if the day average is meaningfully below overall
                if dayAvg < overallAvg - 0.3, weekday >= 1, weekday <= 7 {
                    return "Your mood tends to dip on \(dayNames[weekday])."
                }
            }
        }

        return nil
    }

    func totalCompletions(for habit: Habit, logs: [HabitLog]) -> Int {
        logs.filter { $0.habitIDDenormalized == habit.id && $0.count >= habit.targetCount }.count
    }

    func monthlyCompletions(for habit: Habit, logs: [HabitLog]) -> [(month: Date, count: Int)] {
        let habitLogs = logs.filter { $0.habitIDDenormalized == habit.id && $0.count >= habit.targetCount }
        let grouped = Dictionary(grouping: habitLogs) { log -> Date in
            let comps = calendar.dateComponents([.year, .month], from: log.date)
            return calendar.date(from: comps) ?? log.date
        }

        let now = Date()
        var result: [(month: Date, count: Int)] = []
        for i in (0..<12).reversed() {
            if let monthDate = calendar.date(byAdding: .month, value: -i, to: now) {
                let comps = calendar.dateComponents([.year, .month], from: monthDate)
                let key = calendar.date(from: comps) ?? monthDate
                result.append((month: key, count: grouped[key]?.count ?? 0))
            }
        }
        return result
    }
}
