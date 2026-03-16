import UserNotifications
import SwiftUI

/// Local notification scheduling for DailyArc.
/// Morning reminder (default 8 AM), evening reminder (default 8 PM) with body variants,
/// weekly summary (Sunday 6 PM). Requests permission on first toggle.
/// Per-habit reminders, reactivation reminders, and notification budget enforcement.
@MainActor
final class NotificationService {
    static let shared = NotificationService()

    private let center = UNUserNotificationCenter.current()

    /// Maximum notifications allowed per calendar day to avoid overwhelming the user.
    private let maxDailyNotifications = 3

    // MARK: - Notification Identifiers

    private enum Identifier {
        static let morningReminder = "com.dailyarc.notification.morning"
        static let eveningReminder = "com.dailyarc.notification.evening"
        static let moodReminder = "com.dailyarc.notification.mood"
        static let streakCheckIn = "com.dailyarc.notification.streakcheckin"
        static let weeklySummary = "com.dailyarc.notification.weekly"
        static func habitReminder(_ habitID: UUID) -> String { "habit-\(habitID)" }
        static let reactivationDay3 = "com.dailyarc.notification.reactivation.day3"
        static let reactivationDay7 = "com.dailyarc.notification.reactivation.day7"
        static let reactivationDay14 = "com.dailyarc.notification.reactivation.day14"
    }

    // MARK: - Evening Body Variants

    private let eveningVariants: [String] = [
        "A quick check-in keeps the momentum going. Tap to log your day.",
        "Your arc keeps building with each day you show up.",
        "Today's check-in shapes tomorrow's trend. One tap.",
        "Even a quick log adds to your arc."
    ]

    // MARK: - Permission

    /// Request notification authorization. Returns true if granted.
    func requestPermission() async -> Bool {
        do {
            let granted = try await center.requestAuthorization(options: [.alert, .badge, .sound])
            return granted
        } catch {
            return false
        }
    }

    /// Check current authorization status.
    func checkAuthorizationStatus() async -> UNAuthorizationStatus {
        let settings = await center.notificationSettings()
        return settings.authorizationStatus
    }

    // MARK: - Morning Reminder

    /// Schedule a daily morning reminder at the given hour and minute.
    func scheduleMorningReminder(hour: Int, minute: Int) {
        let content = UNMutableNotificationContent()
        content.title = String(localized: "How are you feeling?")
        content.body = String(localized: "Take 10 seconds to check in with yourself.")
        content.sound = .default

        var dateComponents = DateComponents()
        dateComponents.hour = hour
        dateComponents.minute = minute

        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
        let request = UNNotificationRequest(
            identifier: Identifier.morningReminder,
            content: content,
            trigger: trigger
        )

        center.add(request)
    }

    /// Cancel morning reminder.
    func cancelMorningReminder() {
        center.removePendingNotificationRequests(withIdentifiers: [Identifier.morningReminder])
    }

    // MARK: - Evening Reminder

    /// Schedule a daily evening reminder at the given hour and minute.
    /// Body text rotates through variants using a date-based hash.
    func scheduleEveningReminder(hour: Int, minute: Int) {
        let content = UNMutableNotificationContent()
        content.title = String(localized: "You've got this")

        // Rotate body variant by day
        let dayOfYear = Calendar.current.ordinality(of: .day, in: .year, for: Date()) ?? 0
        let variant = eveningVariants[dayOfYear % eveningVariants.count]
        content.body = variant
        content.sound = .default

        var dateComponents = DateComponents()
        dateComponents.hour = hour
        dateComponents.minute = minute

        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
        let request = UNNotificationRequest(
            identifier: Identifier.eveningReminder,
            content: content,
            trigger: trigger
        )

        center.add(request)
    }

    /// Cancel evening reminder.
    func cancelEveningReminder() {
        center.removePendingNotificationRequests(withIdentifiers: [Identifier.eveningReminder])
    }

    // MARK: - Mood Reminder

    /// Schedule a daily mood logging reminder at the given time.
    func scheduleMoodReminder(hour: Int, minute: Int) {
        let content = UNMutableNotificationContent()
        content.title = String(localized: "How's your arc shaping up?")
        content.body = String(localized: "Take a moment to check in with how you're feeling today.")
        content.sound = .default

        var dateComponents = DateComponents()
        dateComponents.hour = hour
        dateComponents.minute = minute

        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
        let request = UNNotificationRequest(
            identifier: Identifier.moodReminder,
            content: content,
            trigger: trigger
        )
        center.add(request)
    }

    /// Cancel mood reminder.
    func cancelMoodReminder() {
        center.removePendingNotificationRequests(withIdentifiers: [Identifier.moodReminder])
    }

    // MARK: - Streak Check-In

    /// Schedule a morning-after check-in for incomplete habits (9 AM next day).
    func scheduleStreakCheckIn(hour: Int = 9, minute: Int = 0) {
        let content = UNMutableNotificationContent()
        content.title = String(localized: "Your arc continues")
        content.body = String(localized: "Yesterday had some gaps. A quick log keeps your streak alive.")
        content.sound = .default

        var dateComponents = DateComponents()
        dateComponents.hour = hour
        dateComponents.minute = minute

        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
        let request = UNNotificationRequest(
            identifier: Identifier.streakCheckIn,
            content: content,
            trigger: trigger
        )
        center.add(request)
    }

    /// Cancel streak check-in.
    func cancelStreakCheckIn() {
        center.removePendingNotificationRequests(withIdentifiers: [Identifier.streakCheckIn])
    }

    // MARK: - Weekly Summary

    /// Schedule weekly summary for Sunday at the given hour.
    func scheduleWeeklySummary(hour: Int, minute: Int) {
        let content = UNMutableNotificationContent()
        content.title = String(localized: "Your week in review")
        content.body = String(localized: "See how your week shaped your arc. Tap to view your stats.")
        content.sound = .default

        var dateComponents = DateComponents()
        dateComponents.weekday = 1 // Sunday
        dateComponents.hour = hour
        dateComponents.minute = minute

        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
        let request = UNNotificationRequest(
            identifier: Identifier.weeklySummary,
            content: content,
            trigger: trigger
        )

        center.add(request)
    }

    /// Cancel weekly summary.
    func cancelWeeklySummary() {
        center.removePendingNotificationRequests(withIdentifiers: [Identifier.weeklySummary])
    }

    // MARK: - Per-Habit Reminders

    /// Schedule a daily reminder for a specific habit at the given time.
    /// Identifier: "habit-{habitID}" for easy cancellation.
    func scheduleHabitReminder(habitID: UUID, habitName: String, emoji: String, hour: Int, minute: Int) {
        Task { @MainActor in
            guard await canScheduleForToday(hour: hour, minute: minute) else { return }

            let content = UNMutableNotificationContent()
            content.title = String(localized: "Habit Reminder")
            content.body = "\(emoji) Time for \(habitName)!"
            content.sound = .default

            var dateComponents = DateComponents()
            dateComponents.hour = hour
            dateComponents.minute = minute

            let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
            let request = UNNotificationRequest(
                identifier: Identifier.habitReminder(habitID),
                content: content,
                trigger: trigger
            )

            try? await center.add(request)
        }
    }

    /// Cancel a per-habit reminder.
    func cancelHabitReminder(habitID: UUID) {
        center.removePendingNotificationRequests(withIdentifiers: [Identifier.habitReminder(habitID)])
    }

    // MARK: - Reactivation Reminders

    /// Schedule reactivation reminders at days 3, 7, and (conditionally) 14 after first launch.
    /// Fires only once — guarded by `@AppStorage("reactivationScheduled")`.
    /// Per spec, max 2 reactivation notifications; Day 14 is omitted if user has been active
    /// (defined as 3+ app opens).
    func scheduleReactivationReminders() {
        let defaults = UserDefaults.standard
        guard !defaults.bool(forKey: "reactivationScheduled") else { return }

        // Read firstLaunchDate stored as ISO8601 string by EasterEggManager
        guard let firstLaunchString = defaults.string(forKey: "firstLaunchDate"),
              !firstLaunchString.isEmpty,
              let firstLaunch = ISO8601DateFormatter().date(from: firstLaunchString) else {
            return
        }

        let calendar = Calendar.current

        // Day 3
        if let day3 = calendar.date(byAdding: .day, value: 3, to: firstLaunch) {
            scheduleReactivationNotification(
                identifier: Identifier.reactivationDay3,
                date: day3,
                title: String(localized: "Your arc is growing"),
                body: String(localized: "Your arc is taking shape! Open DailyArc to keep building.")
            )
        }

        // Day 7
        if let day7 = calendar.date(byAdding: .day, value: 7, to: firstLaunch) {
            scheduleReactivationNotification(
                identifier: Identifier.reactivationDay7,
                date: day7,
                title: String(localized: "One week milestone"),
                body: String(localized: "One week in — your patterns are starting to emerge.")
            )
        }

        // Day 14 — only if user has NOT been active (fewer than 3 app opens)
        let appOpenCount = defaults.integer(forKey: "appOpenCount")
        if appOpenCount < 3, let day14 = calendar.date(byAdding: .day, value: 14, to: firstLaunch) {
            scheduleReactivationNotification(
                identifier: Identifier.reactivationDay14,
                date: day14,
                title: String(localized: "Insights ready"),
                body: String(localized: "Your mood insights are ready! Open DailyArc to see what affects your mood.")
            )
        }

        defaults.set(true, forKey: "reactivationScheduled")
    }

    /// Helper to schedule a one-shot reactivation notification at a specific date (10 AM).
    private func scheduleReactivationNotification(identifier: String, date: Date, title: String, body: String) {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default

        var components = Calendar.current.dateComponents([.year, .month, .day], from: date)
        components.hour = 10
        components.minute = 0

        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
        center.add(request)
    }

    // MARK: - Notification Budget

    /// Check whether scheduling another notification for the given time today would exceed the daily budget.
    /// Returns true if we can still schedule.
    private func canScheduleForToday(hour: Int, minute: Int) async -> Bool {
        let pending = await center.pendingNotificationRequests()
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())

        var todayCount = 0
        for request in pending {
            guard let calTrigger = request.trigger as? UNCalendarNotificationTrigger else { continue }
            if calTrigger.repeats {
                // Repeating daily notifications always count toward today's budget
                todayCount += 1
            } else if let nextDate = calTrigger.nextTriggerDate(),
                      calendar.isDate(nextDate, inSameDayAs: today) {
                todayCount += 1
            }
        }

        return todayCount < maxDailyNotifications
    }

    // MARK: - Cancel All

    /// Remove all scheduled DailyArc notifications.
    func cancelAll() {
        center.removeAllPendingNotificationRequests()
    }
}
