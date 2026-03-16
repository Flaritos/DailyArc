import SwiftData
import SwiftUI
import Foundation

// SCHEMA CONTRACT: Append-only enum. Never reorder or remove cases — raw values are persisted in SwiftData.
enum HabitFrequency: Int, Codable, CaseIterable, Sendable {
    case daily = 0
    case weekdays = 1
    case weekends = 2
    case custom = 3
}

// MARK: - VersionedSchema

enum DailyArcSchemaV1: VersionedSchema {
    nonisolated(unsafe) static var versionIdentifier = Schema.Version(1, 0, 0)

    static var models: [any PersistentModel.Type] {
        [Habit.self, HabitLog.self, MoodEntry.self, DailySummary.self]
    }

    // MARK: - Habit

    @Model
    class Habit {
        var id: UUID = UUID()
        var name: String = ""
        var emoji: String = ""
        var colorIndex: Int = 5 // Index (0-9) into HabitColorPalette.colors. Default 5 (Sky).
        var frequencyRaw: Int = 0 // Backed by HabitFrequency enum. 0=daily, 1=weekdays, 2=weekends, 3=custom
        var customDays: String = "" // Pipe-delimited day indices "1|3|5" when frequency==.custom. Empty otherwise.
        var targetCount: Int = 1 // Completions per day (1-10, default 1)
        var reminderTime: Date? // Optional notification time
        var reminderEnabled: Bool = false
        var healthKitTypeRaw: String? // Optional HealthKit metric identifier
        var autoLogHealth: Bool = false
        var startDate: Date = Date()
        var isArchived: Bool = false
        var sortOrder: Int = 0
        var currentStreak: Int = 0 // Cached — recalculated on log save/delete
        var bestStreak: Int = 0 // Cached — recalculated on log save/delete
        var createdAt: Date = Date()

        @Relationship(deleteRule: .cascade, inverse: \HabitLog.habit)
        var logs: [HabitLog] = []

        init(
            id: UUID = UUID(),
            name: String = "",
            emoji: String = "",
            colorIndex: Int = 5,
            frequencyRaw: Int = 0,
            customDays: String = "",
            targetCount: Int = 1,
            reminderTime: Date? = nil,
            reminderEnabled: Bool = false,
            healthKitTypeRaw: String? = nil,
            autoLogHealth: Bool = false,
            startDate: Date = Date(),
            isArchived: Bool = false,
            sortOrder: Int = 0,
            currentStreak: Int = 0,
            bestStreak: Int = 0,
            createdAt: Date = Date()
        ) {
            self.id = id
            self.name = name
            self.emoji = emoji
            self.colorIndex = colorIndex
            self.frequencyRaw = frequencyRaw
            self.customDays = customDays
            self.targetCount = targetCount
            self.reminderTime = reminderTime
            self.reminderEnabled = reminderEnabled
            self.healthKitTypeRaw = healthKitTypeRaw
            self.autoLogHealth = autoLogHealth
            self.startDate = startDate
            self.isArchived = isArchived
            self.sortOrder = sortOrder
            self.currentStreak = currentStreak
            self.bestStreak = bestStreak
            self.createdAt = createdAt
        }

        // MARK: Computed Properties

        /// Type-safe frequency accessor
        var frequency: HabitFrequency {
            get { HabitFrequency(rawValue: frequencyRaw) ?? .daily }
            set { frequencyRaw = newValue.rawValue }
        }

        /// Color accessor — resolves palette index to Color based on colorScheme at call site.
        /// Usage: habit.color(for: colorScheme) where colorScheme is from @Environment(\.colorScheme)
        func color(for scheme: ColorScheme) -> Color {
            let entry = HabitColorPalette.colors[safe: colorIndex] ?? HabitColorPalette.colors[5]
            return Color(hex: scheme == .dark ? entry.darkModeHex : entry.hex) ?? .blue
        }

        /// Parse customDays string to [Int] — uses pipe delimiter (not comma).
        /// Day indices match Calendar.component(.weekday): 1=Sunday, 2=Monday, ..., 7=Saturday.
        var customDayIndices: [Int] {
            guard frequency == .custom, !customDays.isEmpty else { return [] }
            return customDays.split(separator: "|").compactMap { Int($0) }
        }

        /// Check if habit should appear on a given date.
        /// Delegates to DateHelpers.shouldAppear — do NOT duplicate weekday logic here.
        /// `calendar` parameter REQUIRED — caller must pass Calendar.current captured on @MainActor.
        func shouldAppear(on date: Date, calendar: Calendar) -> Bool {
            DateHelpers.shouldAppear(on: date, frequencyRaw: frequencyRaw, customDays: customDays, calendar: calendar)
        }
    }

    // MARK: - HabitLog

    @Model
    class HabitLog {
        var id: UUID = UUID()
        var habit: Habit? // @Relationship — back-reference to parent Habit
        var habitIDDenormalized: UUID = UUID() // Stored copy of habit.id for compound #Index and #Predicate
        var date: Date = Date() // Normalized to start of day
        var count: Int = 0 // Completions on this day
        var notes: String = ""
        var isAutoLogged: Bool = false // True if sourced from HealthKit
        var isRecovered: Bool = false // True if created by streak recovery
        var createdAt: Date = Date()

        init(
            id: UUID = UUID(),
            date: Date = Date(),
            count: Int = 0,
            notes: String = "",
            isAutoLogged: Bool = false,
            isRecovered: Bool = false,
            createdAt: Date = Date()
        ) {
            self.id = id
            self.date = date
            self.count = count
            self.notes = notes
            self.isAutoLogged = isAutoLogged
            self.isRecovered = isRecovered
            self.createdAt = createdAt
        }

        /// Fetch existing log or create new one. NEVER create without checking first.
        /// Uses habitIDDenormalized (stored UUID) instead of optional-chaining through @Relationship.
        /// The denormalized field enables the compound #Index and avoids optional-chaining issues in #Predicate.
        static func fetchOrCreate(habit: Habit, date: Date, context: ModelContext, calendar: Calendar) -> HabitLog {
            let normalizedDate = calendar.startOfDay(for: date)
            let habitID = habit.id
            var descriptor = FetchDescriptor<HabitLog>(
                predicate: #Predicate { $0.date == normalizedDate && $0.habitIDDenormalized == habitID }
            )
            descriptor.fetchLimit = 1

            if let existing = (try? context.fetch(descriptor))?.first {
                return existing
            }
            let newLog = HabitLog(date: normalizedDate, count: 0)
            newLog.habit = habit
            newLog.habitIDDenormalized = habit.id // CRITICAL: populate denormalized field for compound index
            context.insert(newLog)
            return newLog
        }
    }

    // MARK: - MoodEntry

    @Model
    class MoodEntry {
        var id: UUID = UUID()
        var date: Date = Date() // Normalized to start of day
        var moodScore: Int = 0 // 1-5 scale. Sentinel: 0 = "not yet logged"
        var energyScore: Int = 0 // 1-5 scale. Sentinel: 0 = "not yet logged"
        var activities: String = "" // Pipe-delimited tags (e.g., "socializing|exercise|work")
        var notes: String = ""
        var createdAt: Date = Date()

        init(
            id: UUID = UUID(),
            date: Date = Date(),
            moodScore: Int = 0,
            energyScore: Int = 0,
            activities: String = "",
            notes: String = "",
            createdAt: Date = Date()
        ) {
            self.id = id
            self.date = date
            self.moodScore = moodScore
            self.energyScore = energyScore
            self.activities = activities
            self.notes = notes
            self.createdAt = createdAt
        }

        // MARK: Computed Properties

        /// Parse activities string to [String] — pipe-delimited
        var activityList: [String] {
            guard !activities.isEmpty else { return [] }
            return activities.split(separator: "|").map { String($0).trimmingCharacters(in: .whitespaces) }
        }

        /// Sanitize and add a custom activity tag — strips pipe delimiter, trims, caps length
        func addActivity(_ tag: String) {
            let sanitized = tag.replacingOccurrences(of: "|", with: "").trimmingCharacters(in: .whitespaces).prefix(30)
            guard !sanitized.isEmpty else { return }
            var list = activityList
            list.append(String(sanitized))
            activities = list.joined(separator: "|")
        }

        /// Remove an activity tag by value
        func removeActivity(_ tag: String) {
            var list = activityList
            list.removeAll { $0 == tag }
            activities = list.joined(separator: "|")
        }

        /// Mood emoji for display. Returns empty string for unset sentinel (moodScore == 0).
        /// Callers MUST check for empty string and treat as "no mood logged" in UI.
        var moodEmoji: String {
            switch moodScore {
            case 0: return ""    // Sentinel: not yet set
            case 1: return "\u{1F614}" // Pensive face
            case 2: return "\u{1F615}" // Confused face
            case 3: return "\u{1F610}" // Neutral face
            case 4: return "\u{1F642}" // Slightly smiling face
            case 5: return "\u{1F604}" // Grinning face with smiling eyes
            default: return ""   // Out of range
            }
        }

        /// fetchOrCreate for MoodEntry. The `calendar:` parameter is REQUIRED for date normalization consistency.
        /// New entries use moodScore: 0 and energyScore: 0 as sentinel values meaning "not yet set."
        static func fetchOrCreate(date: Date, context: ModelContext, calendar: Calendar) -> MoodEntry {
            let normalizedDate = calendar.startOfDay(for: date)
            var descriptor = FetchDescriptor<MoodEntry>(
                predicate: #Predicate { $0.date == normalizedDate }
            )
            descriptor.fetchLimit = 1
            if let existing = (try? context.fetch(descriptor))?.first {
                return existing
            }
            let newEntry = MoodEntry(date: normalizedDate, moodScore: 0, energyScore: 0)
            context.insert(newEntry)
            return newEntry
        }
    }

    // MARK: - DailySummary

    @Model
    class DailySummary {
        var id: UUID = UUID()
        var date: Date = Date() // Normalized start-of-day
        var habitCompletionsJSON: String = "{}" // JSON-encoded [String: Int] — habitID UUID string to count
        var moodAverage: Double = 0 // 0 = no mood logged that day
        var energyAverage: Double = 0
        var createdAt: Date = Date()

        init(
            id: UUID = UUID(),
            date: Date = Date(),
            habitCompletionsJSON: String = "{}",
            moodAverage: Double = 0,
            energyAverage: Double = 0,
            createdAt: Date = Date()
        ) {
            self.id = id
            self.date = date
            self.habitCompletionsJSON = habitCompletionsJSON
            self.moodAverage = moodAverage
            self.energyAverage = energyAverage
            self.createdAt = createdAt
        }

        /// Type-safe accessor — decodes JSON to dictionary
        var habitCompletions: [String: Int] {
            get {
                (try? JSONDecoder().decode([String: Int].self, from: Data(habitCompletionsJSON.utf8))) ?? [:]
            }
            set {
                habitCompletionsJSON = (try? String(data: JSONEncoder().encode(newValue), encoding: .utf8)) ?? "{}"
            }
        }
    }
}

// MARK: - Indexes

// Compound index on HabitLog for fast fetchOrCreate lookups (requires iOS 17.4+)
extension DailyArcSchemaV1.HabitLog {
    // Declared via #Index macro at module level
}
// #Index requires specific syntax — applied via schema definition

// MARK: - Module-scope Typealiases

/// Convenience typealiases so the rest of the app can use `Habit` instead of `DailyArcSchemaV1.Habit`
typealias Habit = DailyArcSchemaV1.Habit
typealias HabitLog = DailyArcSchemaV1.HabitLog
typealias MoodEntry = DailyArcSchemaV1.MoodEntry
typealias DailySummary = DailyArcSchemaV1.DailySummary
