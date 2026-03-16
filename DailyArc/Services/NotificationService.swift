import UserNotifications
import SwiftUI

/// Local notification scheduling for DailyArc.
/// Morning reminder (default 8 AM), evening reminder (default 8 PM) with body variants,
/// weekly summary (Sunday 6 PM). Requests permission on first toggle.
@MainActor
final class NotificationService {
    static let shared = NotificationService()

    private let center = UNUserNotificationCenter.current()

    // MARK: - Notification Identifiers

    private enum Identifier {
        static let morningReminder = "com.dailyarc.notification.morning"
        static let eveningReminder = "com.dailyarc.notification.evening"
        static let weeklySummary = "com.dailyarc.notification.weekly"
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

    // MARK: - Cancel All

    /// Remove all scheduled DailyArc notifications.
    func cancelAll() {
        center.removeAllPendingNotificationRequests()
    }
}
