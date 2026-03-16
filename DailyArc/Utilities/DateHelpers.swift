import Foundation

/// Date utility functions for habit frequency and date normalization.
/// Centralizes all weekday logic — Habit.shouldAppear delegates here.
enum DateHelpers {
    /// Check if a habit should appear on a given date based on its frequency settings.
    ///
    /// - Parameters:
    ///   - date: The date to check.
    ///   - frequencyRaw: Raw value of HabitFrequency (0=daily, 1=weekdays, 2=weekends, 3=custom).
    ///   - customDays: Pipe-delimited day indices (e.g., "0|2|4") for custom frequency.
    ///                 Day indices: 1=Sunday, 2=Monday, ..., 7=Saturday (Calendar.component(.weekday)).
    ///   - calendar: The calendar to use for weekday calculation. Caller MUST pass explicitly.
    /// - Returns: Whether the habit should appear on the given date.
    static func shouldAppear(
        on date: Date,
        frequencyRaw: Int,
        customDays: String,
        calendar: Calendar
    ) -> Bool {
        let frequency = HabitFrequency(rawValue: frequencyRaw) ?? .daily

        switch frequency {
        case .daily:
            return true

        case .weekdays:
            let weekday = calendar.component(.weekday, from: date)
            // weekday: 1=Sunday, 7=Saturday — weekdays are 2-6
            return (2...6).contains(weekday)

        case .weekends:
            let weekday = calendar.component(.weekday, from: date)
            // weekday: 1=Sunday, 7=Saturday
            return weekday == 1 || weekday == 7

        case .custom:
            guard !customDays.isEmpty else { return false }
            let weekday = calendar.component(.weekday, from: date)
            let dayIndices = customDays.split(separator: "|").compactMap { Int($0) }
            return dayIndices.contains(weekday)
        }
    }

    /// Normalize a date to the start of day using the provided calendar.
    static func startOfDay(for date: Date, calendar: Calendar) -> Date {
        calendar.startOfDay(for: date)
    }

    /// Get the date for yesterday relative to a given date.
    static func yesterday(from date: Date, calendar: Calendar) -> Date {
        calendar.date(byAdding: .day, value: -1, to: calendar.startOfDay(for: date))
            ?? date.addingTimeInterval(-86400)
    }

    /// Get a date range from a start date going back a number of days.
    static func dateRange(endingOn endDate: Date, days: Int, calendar: Calendar) -> (start: Date, end: Date) {
        let end = calendar.startOfDay(for: endDate)
        let start = calendar.date(byAdding: .day, value: -(days - 1), to: end)
            ?? end.addingTimeInterval(Double(-days * 86400))
        return (start, end)
    }

    /// Check if two dates are the same calendar day.
    static func isSameDay(_ date1: Date, _ date2: Date, calendar: Calendar) -> Bool {
        calendar.isDate(date1, inSameDayAs: date2)
    }
}
