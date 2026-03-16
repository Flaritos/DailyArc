import Foundation
import SwiftData
import SwiftUI

/// ViewModel for the Today View. Manages date selection, log fetching, habit completion,
/// greeting generation, undo, and integration with celebration/motivation services.
@Observable
@MainActor
final class TodayViewModel {
    var selectedDate: Date
    var moodEntry: MoodEntry?
    var habitLogs: [UUID: HabitLog] = [:]
    var streakUpdatedToday: Set<UUID> = []
    var showCelebration: Bool = false

    // Undo support
    var undoToastMessage: String? = nil
    var undoAction: (() -> Void)? = nil

    // Notes field for mood
    var moodNotes: String = ""

    init() {
        self.selectedDate = Date()
    }

    // MARK: - Greeting

    /// Personalized greeting based on time, name, streaks, day-of-week, easter eggs.
    func greetingText(habits: [Habit]) -> String {
        let name = UserDefaults.standard.string(forKey: "userName") ?? ""
        let displayName = name.isEmpty ? "" : ", \(name)"
        let hour = Calendar.current.component(.hour, from: Date())

        // Easter egg greetings first (holiday-based)
        if let easterGreeting = EasterEggManager.shared.dateGreeting(name: name.isEmpty ? "there" : name) {
            return easterGreeting
        }

        // 100th open check
        if let openMsg = EasterEggManager.shared.check100thOpen() {
            return openMsg
        }

        // Anniversary check
        if let annMsg = EasterEggManager.shared.checkAnniversary() {
            return annMsg
        }

        // Returning user check (14+ days absent)
        let lastOpenDate = UserDefaults.standard.object(forKey: "lastOpenDate") as? Date
        if let lastOpen = lastOpenDate {
            let daysSinceOpen = Calendar.current.dateComponents([.day], from: lastOpen, to: Date()).day ?? 0
            if daysSinceOpen >= 14 {
                let variants = [
                    "Welcome back\(displayName). Your arc remembers you.",
                    "Hey\(displayName) \u{2014} it\u{2019}s been a while. Ready to pick up where you left off?",
                    "Good to see you again\(displayName). Every arc has pauses \u{2014} yours continues now.",
                ]
                let index = Int(StableHash.hash(ISO8601DateFormatter().string(from: Date()))) % variants.count
                return variants[index]
            }
        }

        // Check for 7+ day streak on any habit
        let maxStreak = habits.map(\.currentStreak).max() ?? 0
        let showStreaks = UserDefaults.standard.object(forKey: "showStreaks") == nil
            || UserDefaults.standard.bool(forKey: "showStreaks")

        // Streak-aware variants
        if maxStreak >= 7 && showStreaks {
            switch hour {
            case 5..<12: return "Morning\(displayName)! Day \(maxStreak) of your arc \u{2600}\u{FE0F}"
            case 12..<17: return "Keep it going\(displayName) \u{2014} \(maxStreak) days strong \u{1F324}"
            case 17..<21: return "\(maxStreak)-day arc and counting\(displayName) \u{1F305}"
            default: return "\(maxStreak)-day arc\(displayName). Keep the momentum \u{1F319}"
            }
        }

        // Day-of-week variants
        let weekday = Calendar.current.component(.weekday, from: Date())
        let dayVariant: String? = {
            switch weekday {
            case 2: return "Fresh week\(displayName) \u{2014} keep building your arc."
            case 6: return "Friday\(displayName)! Finish the week strong."
            case 7: return "Weekend arc\(displayName) \u{2014} habits don\u{2019}t clock out."
            case 1: return "Sunday wind-down\(displayName). Reflect on your week."
            default: return nil
            }
        }()
        // 30% chance to use day variant
        if let variant = dayVariant, Int(StableHash.hash("dow-\(selectedDate.timeIntervalSince1970)")) % 3 == 0 {
            return variant
        }

        // Seasonal variants
        let month = Calendar.current.component(.month, from: Date())
        let seasonal: String? = {
            switch month {
            case 1: return "New year, new arc\(displayName)."
            case 3...5: return "Spring energy\(displayName) \u{2014} your arc is blooming."
            case 6...8: return "Summer arc\(displayName) \u{2014} keep the momentum."
            case 9...11: return "Fresh start energy\(displayName)."
            case 12: return "End-of-year arc\(displayName) \u{2014} finish strong."
            default: return nil
            }
        }()
        // 20% chance to use seasonal
        if let variant = seasonal, Int(StableHash.hash("season-\(month)")) % 5 == 0 {
            return variant
        }

        // Default time-of-day
        switch hour {
        case 5..<12: return "Good morning\(displayName) \u{2600}\u{FE0F}"
        case 12..<17: return "Good afternoon\(displayName) \u{1F324}"
        case 17..<21: return "Good evening\(displayName) \u{1F305}"
        default: return "Burning the midnight oil\(displayName)? \u{1F319}"
        }
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

    /// Save mood notes.
    func saveMoodNotes(context: ModelContext, calendar: Calendar, debouncedSave: DebouncedSave?) {
        guard let entry = moodEntry else { return }
        entry.notes = moodNotes
        debouncedSave?.trigger()
    }

    var isToday: Bool { Calendar.current.isDateInToday(selectedDate) }
    var isYesterday: Bool { Calendar.current.isDateInYesterday(selectedDate) }
    var canNavigateForward: Bool { !isToday }

    var dateLabel: String {
        if isToday { return "Today" }
        if isYesterday { return "Yesterday" }
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE, MMM d"
        return formatter.string(from: selectedDate)
    }

    func navigateBack() {
        let calendar = Calendar.current
        if let newDate = calendar.date(byAdding: .day, value: -1, to: selectedDate) {
            selectedDate = newDate
            streakUpdatedToday.removeAll()
        }
    }

    func navigateForward() {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        if let newDate = calendar.date(byAdding: .day, value: 1, to: selectedDate),
           calendar.startOfDay(for: newDate) <= today {
            selectedDate = newDate
            streakUpdatedToday.removeAll()
        }
    }

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

    func fetchMoodEntry(context: ModelContext, calendar: Calendar) {
        let normalizedDate = calendar.startOfDay(for: selectedDate)
        var descriptor = FetchDescriptor<MoodEntry>(
            predicate: #Predicate { $0.date == normalizedDate }
        )
        descriptor.fetchLimit = 1
        moodEntry = (try? context.fetch(descriptor))?.first
        moodNotes = moodEntry?.notes ?? ""
    }

    func log(for habit: Habit) -> HabitLog? {
        habitLogs[habit.id]
    }

    func completionCount(for habit: Habit) -> Int {
        habitLogs[habit.id]?.count ?? 0
    }

    func toggleHabit(
        _ habit: Habit,
        context: ModelContext,
        calendar: Calendar,
        streakEngine: StreakEngine,
        debouncedSave: DebouncedSave?
    ) {
        let log = HabitLog.fetchOrCreate(habit: habit, date: selectedDate, context: context, calendar: calendar)
        let previousCount = log.count

        if habit.targetCount == 1 {
            log.count = log.count >= habit.targetCount ? 0 : habit.targetCount
        } else {
            log.count = log.count >= habit.targetCount ? 0 : log.count + 1
        }

        habitLogs[habit.id] = log

        let habitID = habit.id
        let logDescriptor = FetchDescriptor<HabitLog>(predicate: #Predicate { $0.habitIDDenormalized == habitID })
        let allLogs = (try? context.fetch(logDescriptor)) ?? []
        let isFirst = !streakUpdatedToday.contains(habit.id)
        streakEngine.recalculateStreaks(for: habit, logs: allLogs, isFirstCallToday: isFirst, calendar: calendar)
        if isFirst { streakUpdatedToday.insert(habit.id) }

        if log.count >= habit.targetCount && previousCount < habit.targetCount {
            debouncedSave?.triggerImmediate()
        } else {
            debouncedSave?.trigger()
        }

        // Undo support
        showUndoToast(message: "\(habit.emoji) logged \u{2713}") {
            log.count = previousCount
            self.habitLogs[habit.id] = log
            debouncedSave?.trigger()
        }
    }

    func incrementHabit(
        _ habit: Habit,
        context: ModelContext,
        calendar: Calendar,
        streakEngine: StreakEngine,
        debouncedSave: DebouncedSave?
    ) {
        let log = HabitLog.fetchOrCreate(habit: habit, date: selectedDate, context: context, calendar: calendar)
        let previousCount = log.count
        log.count = min(log.count + 1, habit.targetCount)

        habitLogs[habit.id] = log

        let habitID = habit.id
        let logDescriptor = FetchDescriptor<HabitLog>(predicate: #Predicate { $0.habitIDDenormalized == habitID })
        let allLogs = (try? context.fetch(logDescriptor)) ?? []
        let isFirst = !streakUpdatedToday.contains(habit.id)
        streakEngine.recalculateStreaks(for: habit, logs: allLogs, isFirstCallToday: isFirst, calendar: calendar)
        if isFirst { streakUpdatedToday.insert(habit.id) }

        if log.count >= habit.targetCount && previousCount < habit.targetCount {
            debouncedSave?.triggerImmediate()
        } else {
            debouncedSave?.trigger()
        }

        showUndoToast(message: "\(habit.emoji) logged \u{2713}") {
            log.count = previousCount
            self.habitLogs[habit.id] = log
            debouncedSave?.trigger()
        }
    }

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

    func saveMood(score: Int, context: ModelContext, calendar: Calendar, debouncedSave: DebouncedSave?) {
        let entry = MoodEntry.fetchOrCreate(date: selectedDate, context: context, calendar: calendar)
        let previousScore = entry.moodScore
        entry.moodScore = score
        moodEntry = entry
        debouncedSave?.triggerImmediate()

        // First-ever mood celebration
        CelebrationService.shared.checkFirstEverMoodLog()

        // Undo support
        showUndoToast(message: "Mood logged \u{2713}") {
            entry.moodScore = previousScore
            self.moodEntry = entry
            debouncedSave?.trigger()
        }
    }

    /// Count total unique days the user has logged at least one habit
    func totalDaysLogged(context: ModelContext, calendar: Calendar) -> Int {
        let descriptor = FetchDescriptor<HabitLog>()
        let logs = (try? context.fetch(descriptor)) ?? []
        let uniqueDays = Set(logs.filter { $0.count > 0 }.map { calendar.startOfDay(for: $0.date) })
        return uniqueDays.count
    }

    // MARK: - Undo Toast

    private func showUndoToast(message: String, action: @escaping () -> Void) {
        undoToastMessage = message
        undoAction = action

        // Auto-dismiss after 3 seconds
        Task {
            try? await Task.sleep(for: .seconds(3))
            if undoToastMessage == message {
                withAnimation { undoToastMessage = nil }
                undoAction = nil
            }
        }
    }

    func performUndo() {
        undoAction?()
        withAnimation { undoToastMessage = nil }
        undoAction = nil
    }

    func dismissUndo() {
        withAnimation { undoToastMessage = nil }
        undoAction = nil
    }
}
