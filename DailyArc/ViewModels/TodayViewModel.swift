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

    /// Personalized greeting based on time, name, streaks, day-of-week, easter eggs,
    /// and completion-aware weather metaphors (A2).
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

        // A2: Completion-aware weather metaphor greetings
        // Based on yesterday's completion percentage
        let yesterdayCompletion = lastYesterdayCompletionRate
        if yesterdayCompletion >= 0 {
            let completionGreeting: String? = {
                let seed = Int(StableHash.hash("comp-\(selectedDate.timeIntervalSince1970)"))
                if yesterdayCompletion >= 1.0 {
                    let variants = [
                        "Clear skies ahead\(displayName).",
                        "Riding the momentum\(displayName).",
                    ]
                    return variants[seed % variants.count]
                } else if yesterdayCompletion >= 0.5 {
                    let variants = [
                        "Building momentum\(displayName).",
                        "Your arc continues\(displayName).",
                    ]
                    return variants[seed % variants.count]
                } else {
                    let variants = [
                        "Every day is a fresh start\(displayName).",
                        "Your arc awaits\(displayName).",
                    ]
                    return variants[seed % variants.count]
                }
            }()
            // 40% chance to use completion-aware greeting
            if let greeting = completionGreeting,
               Int(StableHash.hash("comp-show-\(selectedDate.timeIntervalSince1970)")) % 5 < 2 {
                return greeting
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

    /// Yesterday's completion rate for adaptive greetings (A2).
    /// Returns -1 if no data available; 0.0-1.0 otherwise.
    private var lastYesterdayCompletionRate: Double {
        // This is set by fetchYesterdayCompletion when data is available
        _yesterdayCompletionRate
    }

    /// Cached yesterday completion rate. -1 means not computed.
    private var _yesterdayCompletionRate: Double = -1

    /// Fetch yesterday's completion rate from the context for adaptive greeting.
    func fetchYesterdayCompletion(habits: [Habit], context: ModelContext, calendar: Calendar) {
        guard let yesterday = calendar.date(byAdding: .day, value: -1, to: calendar.startOfDay(for: Date())) else {
            _yesterdayCompletionRate = -1
            return
        }
        let normalizedYesterday = calendar.startOfDay(for: yesterday)
        let visibleYesterday = habits.filter { !$0.isArchived && $0.shouldAppear(on: normalizedYesterday, calendar: calendar) }
        guard !visibleYesterday.isEmpty else {
            _yesterdayCompletionRate = -1
            return
        }

        var descriptor = FetchDescriptor<HabitLog>(
            predicate: #Predicate { $0.date == normalizedYesterday }
        )
        descriptor.fetchLimit = 100
        let logs = (try? context.fetch(descriptor)) ?? []
        let logMap = Dictionary(grouping: logs) { $0.habitIDDenormalized }

        let completed = visibleYesterday.filter { habit in
            (logMap[habit.id]?.first?.count ?? 0) >= habit.targetCount
        }.count

        _yesterdayCompletionRate = Double(completed) / Double(visibleYesterday.count)
    }

    // MARK: - Week Summary (A6)

    /// Compute "Your Week" summary for the last 7 days.
    /// Returns nil if insufficient data or not applicable.
    func weekSummary(habits: [Habit], context: ModelContext, calendar: Calendar) -> WeekSummaryData? {
        let today = calendar.startOfDay(for: Date())
        guard let weekAgo = calendar.date(byAdding: .day, value: -7, to: today) else { return nil }

        // Fetch logs for the past 7 days
        var logDescriptor = FetchDescriptor<HabitLog>(
            predicate: #Predicate { $0.date >= weekAgo && $0.date < today }
        )
        logDescriptor.fetchLimit = 500
        let logs = (try? context.fetch(logDescriptor)) ?? []

        // Fetch moods for the past 7 days
        var moodDescriptor = FetchDescriptor<MoodEntry>(
            predicate: #Predicate { $0.date >= weekAgo && $0.date < today }
        )
        moodDescriptor.fetchLimit = 7
        let moods = (try? context.fetch(moodDescriptor)) ?? []

        // Compute completion rate
        var totalScheduled = 0
        var totalCompleted = 0
        var bestDayName = ""
        var bestDayRate = 0.0

        for dayOffset in 0..<7 {
            guard let day = calendar.date(byAdding: .day, value: -6 + dayOffset, to: today) else { continue }
            let normalizedDay = calendar.startOfDay(for: day)
            let visible = habits.filter { !$0.isArchived && $0.shouldAppear(on: normalizedDay, calendar: calendar) }
            guard !visible.isEmpty else { continue }

            totalScheduled += visible.count
            let dayLogs = logs.filter { calendar.isDate($0.date, inSameDayAs: normalizedDay) }
            let logMap = Dictionary(grouping: dayLogs) { $0.habitIDDenormalized }
            let completed = visible.filter { (logMap[$0.id]?.first?.count ?? 0) >= $0.targetCount }.count
            totalCompleted += completed

            let dayRate = Double(completed) / Double(visible.count)
            if dayRate > bestDayRate {
                bestDayRate = dayRate
                let formatter = DateFormatter()
                formatter.dateFormat = "EEEE"
                bestDayName = formatter.string(from: normalizedDay)
            }
        }

        guard totalScheduled > 0 else { return nil }

        let completionPercent = Int(round(Double(totalCompleted) / Double(totalScheduled) * 100))

        // Compute average mood
        let scoredMoods = moods.filter { $0.moodScore > 0 }
        let avgMood: Double? = scoredMoods.isEmpty ? nil : Double(scoredMoods.map(\.moodScore).reduce(0, +)) / Double(scoredMoods.count)

        // Mood emoji for average
        let moodEmoji: String = {
            guard let avg = avgMood else { return "" }
            switch Int(round(avg)) {
            case 1: return "\u{1F614}"
            case 2: return "\u{1F615}"
            case 3: return "\u{1F610}"
            case 4: return "\u{1F642}"
            case 5: return "\u{1F604}"
            default: return ""
            }
        }()

        return WeekSummaryData(
            completionPercent: completionPercent,
            avgMood: avgMood,
            moodEmoji: moodEmoji,
            bestDayName: bestDayName.isEmpty ? nil : bestDayName
        )
    }

    struct WeekSummaryData {
        let completionPercent: Int
        let avgMood: Double?
        let moodEmoji: String
        let bestDayName: String?

        var displayText: String {
            var parts = ["Last week: \(completionPercent)% complete"]
            if let avg = avgMood {
                parts.append("avg mood \(String(format: "%.1f", avg)) \(moodEmoji)")
            }
            if let best = bestDayName {
                parts.append("best day \(best)")
            }
            return parts.joined(separator: ", ")
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
