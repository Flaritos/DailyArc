import SwiftUI
import SwiftData

/// Single-writer actor for all HabitLog mutations.
/// Routes all writes through one serial queue to prevent race conditions.
/// Currently a stub -- production implementation should use @ModelActor.
@MainActor
final class HabitLogWriteActor {
    static let shared = HabitLogWriteActor()
    private init() {}

    /// Write a habit log entry. Currently delegates to main context directly.
    /// TODO: Migrate to @ModelActor for true actor isolation.
    func writeLog(habitID: UUID, date: Date, count: Int, context: ModelContext, calendar: Calendar) {
        let startOfDay = calendar.startOfDay(for: date)
        let descriptor = FetchDescriptor<HabitLog>(
            predicate: #Predicate { $0.habitIDDenormalized == habitID && $0.date == startOfDay }
        )
        if let existing = try? context.fetch(descriptor).first {
            existing.count = count
        } else {
            let log = HabitLog(date: startOfDay, count: count)
            log.habitIDDenormalized = habitID
            context.insert(log)
        }
    }
}
