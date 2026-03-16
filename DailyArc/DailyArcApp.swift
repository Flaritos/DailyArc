import SwiftUI
import SwiftData

@main
struct DailyArcApp: App {
    let container: ModelContainer
    @State private var containerError: String?

    init() {
        do {
            let config = ModelConfiguration(isStoredInMemoryOnly: false)
            container = try ModelContainer(
                for: Habit.self, HabitLog.self, MoodEntry.self, DailySummary.self,
                configurations: config
            )
            // Disable autosave — DebouncedSave manages all saves
            container.mainContext.autosaveEnabled = false
            // Schedule reactivation reminders on first launch (fires only once)
            NotificationService.shared.scheduleReactivationReminders()
        } catch {
            // Fallback: in-memory container so app doesn't crash
            // User will see empty state; data from previous version lost
            do {
                let fallbackConfig = ModelConfiguration(isStoredInMemoryOnly: true)
                container = try ModelContainer(
                    for: Habit.self, HabitLog.self, MoodEntry.self, DailySummary.self,
                    configurations: fallbackConfig
                )
                container.mainContext.autosaveEnabled = false
                _containerError = State(initialValue: "Your data couldn't be loaded. Please try restarting the app.")
            } catch {
                // This should never happen with in-memory, but satisfy the compiler
                fatalError("Failed to create even in-memory ModelContainer: \(error)")
            }
        }
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .alert("Data Error", isPresented: Binding(
                    get: { containerError != nil },
                    set: { if !$0 { containerError = nil } }
                )) {
                    Button("OK", role: .cancel) { containerError = nil }
                } message: {
                    Text(containerError ?? "")
                }
        }
        .modelContainer(container)
    }
}
