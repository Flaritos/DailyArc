import Foundation
import SwiftUI

/// Computed struct for daily statistics — NOT a @Model.
/// Batch-computed from queries to avoid N+1 database round trips.
struct DaySnapshot: Identifiable {
    let date: Date
    let totalHabits: Int
    let completedHabits: Int
    let completionPercentage: Double
    let moodScore: Int // 0 = not logged
    let energyScore: Int // 0 = not logged

    var id: Date { date }

    /// Batch-compute snapshots from pre-fetched data.
    /// Single query + in-memory grouping — never 365 individual queries.
    static func snapshots(
        habits: [Habit],
        logs: [HabitLog],
        moods: [MoodEntry],
        from startDate: Date,
        to endDate: Date,
        calendar: Calendar
    ) -> [DaySnapshot] {
        let logsByDate = Dictionary(grouping: logs) { calendar.startOfDay(for: $0.date) }
        let moodsByDate = Dictionary(grouping: moods) { calendar.startOfDay(for: $0.date) }

        var result: [DaySnapshot] = []
        var current = calendar.startOfDay(for: startDate)
        let normalizedEnd = calendar.startOfDay(for: endDate)

        while current <= normalizedEnd {
            let dayLogs = logsByDate[current] ?? []
            let activeHabits = habits.filter { habit in
                !habit.isArchived
                    && habit.shouldAppear(on: current, calendar: calendar)
                    && calendar.startOfDay(for: habit.startDate) <= current
            }
            let completed = activeHabits.filter { habit in
                let logCount = dayLogs.first(where: { $0.habitIDDenormalized == habit.id })?.count ?? 0
                return logCount >= habit.targetCount
            }.count
            let total = activeHabits.count
            let mood = moodsByDate[current]?.first

            result.append(DaySnapshot(
                date: current,
                totalHabits: total,
                completedHabits: completed,
                completionPercentage: total > 0 ? Double(completed) / Double(total) : 0,
                moodScore: mood?.moodScore ?? 0,
                energyScore: mood?.energyScore ?? 0
            ))
            current = calendar.date(byAdding: .day, value: 1, to: current)
                ?? current.addingTimeInterval(86400)
        }
        return result
    }
}
