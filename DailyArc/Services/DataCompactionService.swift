import SwiftUI
import SwiftData

/// Compacts HabitLog/MoodEntry records older than 365 days into DailySummary rows.
/// TODO: Wire to BGAppRefreshTask for background execution.
enum DataCompactionService {
    @MainActor
    static func compactIfNeeded(context: ModelContext) {
        // Stub — compaction only needed after 365+ days of use.
        // Will compact old records into DailySummary for efficient queries.
    }
}
