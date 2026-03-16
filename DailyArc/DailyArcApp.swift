import SwiftUI
import SwiftData

@main
struct DailyArcApp: App {
    let container: ModelContainer

    init() {
        do {
            let config = ModelConfiguration(isStoredInMemoryOnly: false)
            container = try ModelContainer(
                for: Habit.self, HabitLog.self, MoodEntry.self, DailySummary.self,
                configurations: config
            )
            // Disable autosave — DebouncedSave manages all saves
            container.mainContext.autosaveEnabled = false
        } catch {
            fatalError("Failed to create ModelContainer: \(error)")
        }
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(container)
    }
}
