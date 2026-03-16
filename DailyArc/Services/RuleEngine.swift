import Foundation

/// On-device rule engine — caseless enum (implicitly Sendable, no instances).
/// Generates personalized suggestions based on habit completion patterns.
enum RuleEngine {

    struct Suggestion: Identifiable, Sendable {
        let id: UUID
        let emoji: String
        let text: String
        let priority: Int // 0 = highest

        init(emoji: String, text: String, priority: Int) {
            self.id = UUID()
            self.emoji = emoji
            self.text = text
            self.priority = priority
        }
    }

    struct HabitSnapshot: Sendable {
        let id: UUID
        let name: String
        let emoji: String
        let targetCount: Int
        let isArchived: Bool
        let currentStreak: Int
        let startDate: Date
        let frequencyRaw: Int
        let customDays: String
    }

    struct LogSnapshot: Sendable {
        let habitID: UUID
        let date: Date
        let count: Int
        let isRecovered: Bool
    }

    struct MoodSnapshot: Sendable {
        let date: Date
        let moodScore: Int
        let energyScore: Int
    }

    // MARK: - Snapshot Extraction (call on @MainActor)

    @MainActor
    static func extractSnapshots(
        habits: [Habit],
        logs: [HabitLog],
        moods: [MoodEntry]
    ) -> ([HabitSnapshot], [LogSnapshot], [MoodSnapshot]) {
        let habitSnaps = habits.map { habit in
            HabitSnapshot(
                id: habit.id, name: habit.name, emoji: habit.emoji,
                targetCount: habit.targetCount, isArchived: habit.isArchived,
                currentStreak: habit.currentStreak, startDate: habit.startDate,
                frequencyRaw: habit.frequencyRaw, customDays: habit.customDays
            )
        }
        let logSnaps = logs.map { log in
            LogSnapshot(
                habitID: log.habitIDDenormalized, date: log.date,
                count: log.count, isRecovered: log.isRecovered
            )
        }
        let moodSnaps = moods.map { mood in
            MoodSnapshot(date: mood.date, moodScore: mood.moodScore, energyScore: mood.energyScore)
        }
        return (habitSnaps, logSnaps, moodSnaps)
    }

    // MARK: - Generate Suggestions

    static func generateSuggestions(
        habits: [HabitSnapshot],
        logs: [LogSnapshot],
        moods: [MoodSnapshot],
        correlations: [CorrelationEngine.CorrelationResult],
        calendar: Calendar
    ) -> [Suggestion] {
        var suggestions: [Suggestion] = []
        let today = calendar.startOfDay(for: Date())
        let thirtyDaysAgo = calendar.date(byAdding: .day, value: -30, to: today) ?? today

        // O(L) pre-grouping
        let logsByHabitID = Dictionary(
            grouping: logs.filter { !$0.isRecovered && $0.date >= thirtyDaysAgo },
            by: \.habitID
        )

        for habit in habits where !habit.isArchived {
            let streak = habit.currentStreak
            let monthLogs = logsByHabitID[habit.id] ?? []

            let applicableDays = (0..<30).filter { dayOffset in
                let date = calendar.date(byAdding: .day, value: -dayOffset, to: today) ?? today
                return DateHelpers.shouldAppear(
                    on: date, frequencyRaw: habit.frequencyRaw,
                    customDays: habit.customDays, calendar: calendar
                ) && date >= habit.startDate
            }.count

            let completedDays = monthLogs.filter { $0.count >= habit.targetCount }.count
            let completionRate = applicableDays > 0 ? Double(completedDays) / Double(applicableDays) : 0

            // Rule 1: Active streak celebration
            if streak > 7 {
                suggestions.append(Suggestion(
                    emoji: "\u{1F525}",
                    text: "\(streak)-day streak on \(habit.emoji) \(habit.name). Keep going!",
                    priority: 1
                ))
            }

            // Rule 2: Low completion encouragement
            if completionRate < 0.5 && applicableDays >= 7 {
                suggestions.append(Suggestion(
                    emoji: "\u{1F4AA}",
                    text: "\(habit.emoji) \(habit.name) is at \(Int(completionRate * 100))% this month \u{2014} small steps count!",
                    priority: 2
                ))
            }

            // Rule 3: High completion praise
            if completionRate >= 0.9 && applicableDays >= 7 {
                suggestions.append(Suggestion(
                    emoji: "\u{2B50}",
                    text: "You're crushing \(habit.emoji) \(habit.name) at \(Int(completionRate * 100))% this month!",
                    priority: 1
                ))
            }

            // Rule 4: Long streak milestone
            if streak > 30 {
                suggestions.append(Suggestion(
                    emoji: "\u{1F3C6}",
                    text: "\(streak) days of \(habit.emoji) \(habit.name). This arc speaks for itself.",
                    priority: 0
                ))
            }
        }

        // Rule 5: Mood-habit correlation suggestions
        for correlation in correlations where abs(correlation.coefficient) >= 0.15 {
            if correlation.coefficient > 0 {
                let moodDiff = correlation.averageMoodOnHabitDays - correlation.averageMoodOnSkipDays
                if moodDiff > 0.3 {
                    suggestions.append(Suggestion(
                        emoji: correlation.emoji,
                        text: "You tend to feel better on days you \(correlation.habitName). Consider doing it more consistently.",
                        priority: 1
                    ))
                }
            } else {
                suggestions.append(Suggestion(
                    emoji: correlation.emoji,
                    text: "Your mood tends to be lower on \(correlation.habitName) days. Worth reflecting on.",
                    priority: 3
                ))
            }
        }

        return suggestions.sorted { $0.priority < $1.priority }
    }
}
