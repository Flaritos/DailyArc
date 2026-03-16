import Foundation
import SwiftData

/// Generates 45 days of realistic synthetic data for development and testing.
/// Includes 4 habits with ~80% completion rate, mood entries, and recalculated streaks.
#if DEBUG
@MainActor
struct DebugDataGenerator {

    // MARK: - Templates

    private struct HabitTemplate {
        let emoji: String
        let name: String
        let targetCount: Int
        let colorIndex: Int
    }

    private static let templates: [HabitTemplate] = [
        HabitTemplate(emoji: "🏃", name: "Exercise", targetCount: 1, colorIndex: 0),
        HabitTemplate(emoji: "📚", name: "Reading", targetCount: 1, colorIndex: 1),
        HabitTemplate(emoji: "💧", name: "Drink Water", targetCount: 8, colorIndex: 2),
        HabitTemplate(emoji: "🧘", name: "Meditate", targetCount: 1, colorIndex: 3),
    ]

    private static let activityTags = ["Exercise", "Work", "Social", "Creative", "Outdoors", "Rest"]

    // MARK: - Seed

    /// Seeds the ModelContext with 45 days of realistic demo data.
    /// Creates 4 habits, habit logs with ~80% completion, mood entries, and recalculated streaks.
    static func seedData(context: ModelContext) {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())

        // Create habits with start dates 45 days ago
        guard let startDate = calendar.date(byAdding: .day, value: -44, to: today) else { return }

        var habits: [Habit] = []
        for (index, template) in templates.enumerated() {
            let habit = Habit(
                name: template.name,
                emoji: template.emoji,
                colorIndex: template.colorIndex,
                targetCount: template.targetCount,
                startDate: startDate,
                sortOrder: index
            )
            context.insert(habit)
            habits.append(habit)
        }

        // Generate logs and mood entries for each day
        for dayOffset in 0..<45 {
            guard let date = calendar.date(byAdding: .day, value: dayOffset, to: startDate) else { continue }

            // Habit logs with ~80% completion
            for habit in habits {
                let completed = Double.random(in: 0...1) < 0.80
                if completed {
                    let log = HabitLog(date: date, count: habit.targetCount > 1 ? Int.random(in: 5...8) : 1)
                    log.habit = habit
                    log.habitIDDenormalized = habit.id
                    context.insert(log)
                }
            }

            // Mood entry with scores weighted toward 3-4
            let moodWeights = [2, 3, 3, 3, 4, 4, 4, 4, 5, 5]
            let energyWeights = [2, 3, 3, 3, 4, 4, 4, 4, 5, 5]
            let moodScore = moodWeights.randomElement() ?? 3
            let energyScore = energyWeights.randomElement() ?? 3

            // Pick 1-3 random activity tags
            let tagCount = Int.random(in: 1...3)
            let shuffled = activityTags.shuffled()
            let selectedTags = Array(shuffled.prefix(tagCount))

            let mood = MoodEntry(
                date: date,
                moodScore: moodScore,
                energyScore: energyScore,
                activities: selectedTags.joined(separator: "|")
            )
            context.insert(mood)
        }

        // Recalculate streaks for each habit
        let streakEngine = StreakEngine()
        for habit in habits {
            let habitID = habit.id
            var descriptor = FetchDescriptor<HabitLog>(
                predicate: #Predicate { $0.habitIDDenormalized == habitID }
            )
            descriptor.sortBy = [SortDescriptor(\.date)]
            let logs = (try? context.fetch(descriptor)) ?? []
            streakEngine.recalculateStreaks(
                for: habit,
                logs: logs,
                isDeletion: false,
                isFirstCallToday: false,
                calendar: calendar
            )
        }

        try? context.save()
    }
}
#endif
