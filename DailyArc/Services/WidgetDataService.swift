import Foundation
import SwiftData

// MARK: - Widget Payload

/// JSON payload written to shared UserDefaults for widget consumption.
/// Schema version enables forward-compatible widget updates without breaking older app versions.
struct WidgetPayload: Codable, Sendable {
    let schemaVersion: Int
    let completionPercent: Double    // 0.0-1.0
    let totalHabits: Int
    let completedHabits: Int
    let topStreakEmoji: String
    let topStreakCount: Int
    let moodEmoji: String           // "" if no mood logged
    let habits: [WidgetHabit]
    let lastUpdated: Date

    struct WidgetHabit: Codable, Sendable {
        let emoji: String
        let name: String
        let isComplete: Bool
        let count: Int
        let targetCount: Int
    }

    init(
        completionPercent: Double,
        totalHabits: Int,
        completedHabits: Int,
        topStreakEmoji: String,
        topStreakCount: Int,
        moodEmoji: String,
        habits: [WidgetHabit],
        lastUpdated: Date
    ) {
        self.schemaVersion = 1
        self.completionPercent = completionPercent
        self.totalHabits = totalHabits
        self.completedHabits = completedHabits
        self.topStreakEmoji = topStreakEmoji
        self.topStreakCount = topStreakCount
        self.moodEmoji = moodEmoji
        self.habits = habits
        self.lastUpdated = lastUpdated
    }
}

// MARK: - Widget Data Service

/// Writes a WidgetPayload to the shared app group UserDefaults so widgets can read it.
/// Called after every successful SwiftData save via DebouncedSave.
@MainActor
enum WidgetDataService {

    /// App group suite name — must match the App Group capability in both the main app and widget extension targets.
    static let suiteName = "group.com.dailyarc.shared"

    /// UserDefaults key for the encoded widget payload.
    static let payloadKey = "widgetPayload"

    /// Build and write the current day's widget payload to shared UserDefaults.
    /// - Parameters:
    ///   - context: The SwiftData ModelContext to fetch from.
    ///   - calendar: The user's calendar (must be captured on @MainActor).
    static func writeNow(context: ModelContext, calendar: Calendar) throws {
        let today = calendar.startOfDay(for: Date())

        // 1. Fetch today's active habits (non-archived, should appear today)
        let allHabits = try context.fetch(
            FetchDescriptor<Habit>(predicate: #Predicate { !$0.isArchived })
        )
        let todayHabits = allHabits
            .filter { $0.shouldAppear(on: today, calendar: calendar) }
            .sorted { $0.sortOrder < $1.sortOrder }

        // 2. Fetch today's logs for those habits
        let habitIDs = todayHabits.map(\.id)
        let allLogs = try context.fetch(
            FetchDescriptor<HabitLog>(predicate: #Predicate { $0.date == today })
        )
        let logsByHabitID: [UUID: HabitLog] = Dictionary(
            allLogs.compactMap { log in
                guard let habitID = log.habit?.id, habitIDs.contains(habitID) else { return nil }
                return (habitID, log)
            },
            uniquingKeysWith: { first, _ in first }
        )

        // 3. Fetch today's mood
        var moodDescriptor = FetchDescriptor<MoodEntry>(
            predicate: #Predicate { $0.date == today }
        )
        moodDescriptor.fetchLimit = 1
        let moodEntry = try context.fetch(moodDescriptor).first

        // 4. Build per-habit widget data
        var widgetHabits: [WidgetPayload.WidgetHabit] = []
        var completedCount = 0

        for habit in todayHabits {
            let log = logsByHabitID[habit.id]
            let count = log?.count ?? 0
            let isComplete = count >= habit.targetCount
            if isComplete { completedCount += 1 }

            widgetHabits.append(WidgetPayload.WidgetHabit(
                emoji: habit.emoji,
                name: habit.name,
                isComplete: isComplete,
                count: count,
                targetCount: habit.targetCount
            ))
        }

        // 5. Find top streak habit
        let topStreakHabit = allHabits
            .filter { $0.currentStreak > 0 }
            .max { $0.currentStreak < $1.currentStreak }

        // 6. Compute completion percentage
        let totalHabits = todayHabits.count
        let completionPercent = totalHabits > 0
            ? Double(completedCount) / Double(totalHabits)
            : 0.0

        // 7. Build payload
        let payload = WidgetPayload(
            completionPercent: completionPercent,
            totalHabits: totalHabits,
            completedHabits: completedCount,
            topStreakEmoji: topStreakHabit?.emoji ?? "",
            topStreakCount: topStreakHabit?.currentStreak ?? 0,
            moodEmoji: moodEntry?.moodEmoji ?? "",
            habits: widgetHabits,
            lastUpdated: Date()
        )

        // 8. Encode and write to shared UserDefaults
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let data = try encoder.encode(payload)

        guard let defaults = UserDefaults(suiteName: suiteName) else {
            return
        }
        defaults.set(data, forKey: payloadKey)
    }
}
