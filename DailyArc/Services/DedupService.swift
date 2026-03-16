import SwiftUI
import SwiftData

/// Detects and removes duplicate HabitLog and MoodEntry records.
/// Runs on app launch, scoped to last 30 days.
enum DedupService {
    /// Static flag to ensure dedup runs only once per launch.
    @MainActor
    private(set) static var hasRunThisLaunch = false

    @MainActor
    static func runDedup(context: ModelContext) {
        guard !hasRunThisLaunch else { return }
        hasRunThisLaunch = true

        let calendar = Calendar.current
        let cutoff = calendar.date(byAdding: .day, value: -30, to: Date()) ?? Date()

        // Dedup HabitLogs: same habitIDDenormalized + same date
        let logDescriptor = FetchDescriptor<HabitLog>(
            predicate: #Predicate { $0.date >= cutoff },
            sortBy: [SortDescriptor(\.date)]
        )
        if let logs = try? context.fetch(logDescriptor) {
            var seen: Set<String> = []
            var dupeCount = 0
            for log in logs {
                let key = "\(log.habitIDDenormalized)-\(calendar.startOfDay(for: log.date).timeIntervalSince1970)"
                if seen.contains(key) {
                    context.delete(log)
                    dupeCount += 1
                } else {
                    seen.insert(key)
                }
            }
            if dupeCount > 0 {
                try? context.save()
            }
        }

        // Dedup MoodEntries: same date
        let moodDescriptor = FetchDescriptor<MoodEntry>(
            predicate: #Predicate { $0.date >= cutoff },
            sortBy: [SortDescriptor(\.date)]
        )
        if let moods = try? context.fetch(moodDescriptor) {
            var seen: Set<String> = []
            var dupeCount = 0
            for mood in moods {
                let key = "\(calendar.startOfDay(for: mood.date).timeIntervalSince1970)"
                if seen.contains(key) {
                    context.delete(mood)
                    dupeCount += 1
                } else {
                    seen.insert(key)
                }
            }
            if dupeCount > 0 {
                try? context.save()
            }
        }
    }
}
