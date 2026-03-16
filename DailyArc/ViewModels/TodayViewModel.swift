import Foundation
import SwiftData
import SwiftUI

/// ViewModel for the Today View. Manages date selection, log fetching, and habit completion logic.
@Observable
@MainActor
final class TodayViewModel {
    var selectedDate: Date
    var moodEntry: MoodEntry?
    var habitLogs: [UUID: HabitLog] = [:]
    var streakUpdatedToday: Set<UUID> = []

    /// Init for creation in @State.
    init() {
        self.selectedDate = Date()
    }

    /// Whether to show the celebration overlay (all habits completed).
    var showCelebration: Bool = false

    /// Greeting text based on time of day and streak status.
    /// "Good morning" (5am-12pm), "Good afternoon" (12pm-5pm),
    /// "Good evening" (5pm-9pm), "Winding down" (9pm-5am).
    /// Adds streak-aware variant when user has a 7+ day streak.
    func greetingText(habits: [Habit]) -> String {
        let hour = Calendar.current.component(.hour, from: Date())
        let base: String
        switch hour {
        case 5..<12: base = "Good morning"
        case 12..<17: base = "Good afternoon"
        case 17..<21: base = "Good evening"
        default: base = "Winding down"
        }

        // Check for 7+ day streak on any habit
        let maxStreak = habits.map(\.currentStreak).max() ?? 0
        if maxStreak >= 7 {
            return "\(base) \u{1F525}"
        }
        return base
    }

    /// Save energy score to the current mood entry.
    func saveEnergy(score: Int, context: ModelContext, calendar: Calendar, debouncedSave: DebouncedSave?) {
        let entry = MoodEntry.fetchOrCreate(date: selectedDate, context: context, calendar: calendar)
        entry.energyScore = score
        moodEntry = entry
        debouncedSave?.trigger()
    }

    /// Toggle an activity tag on the current mood entry.
    func toggleActivity(_ tag: String, context: ModelContext, calendar: Calendar, debouncedSave: DebouncedSave?) {
        let entry = MoodEntry.fetchOrCreate(date: selectedDate, context: context, calendar: calendar)
        if entry.activityList.contains(tag) {
            entry.removeActivity(tag)
        } else {
            entry.addActivity(tag)
        }
        moodEntry = entry
        debouncedSave?.trigger()
    }

    /// Whether the selected date is today.
    var isToday: Bool {
        Calendar.current.isDateInToday(selectedDate)
    }

    /// Whether the selected date is yesterday.
    var isYesterday: Bool {
        Calendar.current.isDateInYesterday(selectedDate)
    }

    /// Whether the user can navigate forward (not past today).
    var canNavigateForward: Bool {
        !isToday
    }

    /// Formatted date label for the navigation bar.
    var dateLabel: String {
        if isToday { return "Today" }
        if isYesterday { return "Yesterday" }
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE, MMM d"
        return formatter.string(from: selectedDate)
    }

    /// Navigate to the previous day.
    func navigateBack() {
        let calendar = Calendar.current
        if let newDate = calendar.date(byAdding: .day, value: -1, to: selectedDate) {
            selectedDate = newDate
            streakUpdatedToday.removeAll()
        }
    }

    /// Navigate to the next day (capped at today).
    func navigateForward() {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        if let newDate = calendar.date(byAdding: .day, value: 1, to: selectedDate),
           calendar.startOfDay(for: newDate) <= today {
            selectedDate = newDate
            streakUpdatedToday.removeAll()
        }
    }

    /// Fetch all habit logs for the selected date.
    func fetchLogsForDate(context: ModelContext, calendar: Calendar) {
        let normalizedDate = calendar.startOfDay(for: selectedDate)
        var descriptor = FetchDescriptor<HabitLog>(
            predicate: #Predicate { $0.date == normalizedDate }
        )
        descriptor.fetchLimit = 100
        let logs = (try? context.fetch(descriptor)) ?? []
        var logMap: [UUID: HabitLog] = [:]
        for log in logs {
            logMap[log.habitIDDenormalized] = log
        }
        habitLogs = logMap
    }

    /// Fetch the mood entry for the selected date.
    func fetchMoodEntry(context: ModelContext, calendar: Calendar) {
        let normalizedDate = calendar.startOfDay(for: selectedDate)
        var descriptor = FetchDescriptor<MoodEntry>(
            predicate: #Predicate { $0.date == normalizedDate }
        )
        descriptor.fetchLimit = 1
        moodEntry = (try? context.fetch(descriptor))?.first
    }

    /// Get the log for a specific habit on the selected date.
    func log(for habit: Habit) -> HabitLog? {
        habitLogs[habit.id]
    }

    /// Get completion count for a habit on the selected date.
    func completionCount(for habit: Habit) -> Int {
        habitLogs[habit.id]?.count ?? 0
    }

    /// Toggle or increment a habit's completion.
    func toggleHabit(
        _ habit: Habit,
        context: ModelContext,
        calendar: Calendar,
        streakEngine: StreakEngine,
        debouncedSave: DebouncedSave?
    ) {
        let log = HabitLog.fetchOrCreate(habit: habit, date: selectedDate, context: context, calendar: calendar)

        if habit.targetCount == 1 {
            // Toggle: 0 -> 1, 1 -> 0
            log.count = log.count >= habit.targetCount ? 0 : habit.targetCount
        } else {
            // Increment, wrap to 0 after reaching target
            log.count = log.count >= habit.targetCount ? 0 : log.count + 1
        }

        // Update local cache
        habitLogs[habit.id] = log

        // Recalculate streaks
        let habitID = habit.id
        let logDescriptor = FetchDescriptor<HabitLog>(predicate: #Predicate { $0.habitIDDenormalized == habitID })
        let habitLogs = (try? context.fetch(logDescriptor)) ?? []
        let isFirst = !streakUpdatedToday.contains(habit.id)
        streakEngine.recalculateStreaks(for: habit, logs: habitLogs, isFirstCallToday: isFirst, calendar: calendar)
        if isFirst { streakUpdatedToday.insert(habit.id) }

        // Streak-critical: immediate save when habit reaches targetCount
        if log.count >= habit.targetCount && (log.count - 1) < habit.targetCount {
            debouncedSave?.triggerImmediate()
        } else {
            debouncedSave?.trigger()
        }
    }

    /// Increment a stepper habit's count.
    func incrementHabit(
        _ habit: Habit,
        context: ModelContext,
        calendar: Calendar,
        streakEngine: StreakEngine,
        debouncedSave: DebouncedSave?
    ) {
        let log = HabitLog.fetchOrCreate(habit: habit, date: selectedDate, context: context, calendar: calendar)
        log.count = min(log.count + 1, habit.targetCount)

        habitLogs[habit.id] = log

        let habitID = habit.id
        let logDescriptor = FetchDescriptor<HabitLog>(predicate: #Predicate { $0.habitIDDenormalized == habitID })
        let allLogs = (try? context.fetch(logDescriptor)) ?? []
        let isFirst = !streakUpdatedToday.contains(habit.id)
        streakEngine.recalculateStreaks(for: habit, logs: allLogs, isFirstCallToday: isFirst, calendar: calendar)
        if isFirst { streakUpdatedToday.insert(habit.id) }

        if log.count >= habit.targetCount && (log.count - 1) < habit.targetCount {
            debouncedSave?.triggerImmediate()
        } else {
            debouncedSave?.trigger()
        }
    }

    /// Decrement a stepper habit's count.
    func decrementHabit(
        _ habit: Habit,
        context: ModelContext,
        calendar: Calendar,
        streakEngine: StreakEngine,
        debouncedSave: DebouncedSave?
    ) {
        let log = HabitLog.fetchOrCreate(habit: habit, date: selectedDate, context: context, calendar: calendar)
        log.count = max(log.count - 1, 0)

        habitLogs[habit.id] = log

        let habitID = habit.id
        let logDescriptor = FetchDescriptor<HabitLog>(predicate: #Predicate { $0.habitIDDenormalized == habitID })
        let allLogs = (try? context.fetch(logDescriptor)) ?? []
        streakEngine.recalculateStreaks(for: habit, logs: allLogs, isDeletion: true, isFirstCallToday: false, calendar: calendar)

        debouncedSave?.trigger()
    }

    /// Save mood selection.
    func saveMood(score: Int, context: ModelContext, calendar: Calendar, debouncedSave: DebouncedSave?) {
        let entry = MoodEntry.fetchOrCreate(date: selectedDate, context: context, calendar: calendar)
        entry.moodScore = score
        moodEntry = entry
        // Mood is streak-critical — immediate save
        debouncedSave?.triggerImmediate()
    }
}
