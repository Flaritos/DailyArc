import Foundation
import SwiftData

struct Badge: Identifiable, Codable, Sendable {
    let id: String
    let name: String
    let emoji: String
    let description: String
    let category: Category
    var earnedDate: Date?

    enum Category: String, Codable, Sendable {
        case streak, milestone
    }

    var isEarned: Bool { earnedDate != nil }
}

@MainActor @Observable
class BadgeEngine {
    static let shared = BadgeEngine()

    var earnedBadges: [Badge] = []
    var pendingCeremony: Badge? = nil

    private static let storageKey = "earnedBadges"

    static let allBadges: [Badge] = [
        // Streak badges
        Badge(id: "sprout", name: "Sprout", emoji: "\u{1F331}", description: "3-day streak", category: .streak),
        Badge(id: "rising_arc", name: "Rising Arc", emoji: "\u{1F305}", description: "7-day streak", category: .streak),
        Badge(id: "steady_arc", name: "Steady Arc", emoji: "\u{2B50}", description: "14-day streak", category: .streak),
        Badge(id: "blazing_arc", name: "Blazing Arc", emoji: "\u{1F525}", description: "30-day streak", category: .streak),
        Badge(id: "golden_arc", name: "Golden Arc", emoji: "\u{1F3C6}", description: "100-day streak", category: .streak),
        Badge(id: "zenith", name: "Zenith", emoji: "\u{1F48E}", description: "365-day streak", category: .streak),
        // Milestone badges
        Badge(id: "inner_arc", name: "Inner Arc", emoji: "\u{1F4AD}", description: "Log your first mood", category: .milestone),
        Badge(id: "spectrum_arc", name: "Spectrum Arc", emoji: "\u{1F308}", description: "Use all 5 mood scores", category: .milestone),
        Badge(id: "century_arc", name: "Century Arc", emoji: "\u{1F4AF}", description: "100 total completions", category: .milestone),
        Badge(id: "mindful_arc", name: "Mindful Arc", emoji: "\u{1F9D8}", description: "Log mood 7 days in a row", category: .milestone),
    ]

    private init() {
        loadFromStorage()
    }

    // MARK: - Check Badges

    func checkBadges(habits: [Habit], logs: [HabitLog], moods: [MoodEntry], calendar: Calendar) {
        let now = Date()
        let earnedIDs = Set(earnedBadges.map(\.id))

        // --- Streak badges ---
        let maxCurrentStreak = habits.map(\.currentStreak).max() ?? 0
        let maxBestStreak = habits.map(\.bestStreak).max() ?? 0
        let maxStreak = max(maxCurrentStreak, maxBestStreak)

        let streakThresholds: [(id: String, threshold: Int)] = [
            ("sprout", 3),
            ("rising_arc", 7),
            ("steady_arc", 14),
            ("blazing_arc", 30),
            ("golden_arc", 100),
            ("zenith", 365),
        ]

        for (badgeID, threshold) in streakThresholds {
            if !earnedIDs.contains(badgeID) && maxStreak >= threshold {
                awardBadge(id: badgeID, date: now)
            }
        }

        // --- inner_arc: Log your first mood ---
        if !earnedIDs.contains("inner_arc") {
            let hasMood = moods.contains { $0.moodScore > 0 }
            if hasMood {
                awardBadge(id: "inner_arc", date: now)
            }
        }

        // --- spectrum_arc: Use all 5 mood scores ---
        if !earnedIDs.contains("spectrum_arc") {
            let usedScores = Set(moods.map(\.moodScore).filter { $0 >= 1 && $0 <= 5 })
            if usedScores.count == 5 {
                awardBadge(id: "spectrum_arc", date: now)
            }
        }

        // --- century_arc: 100 total completions ---
        if !earnedIDs.contains("century_arc") {
            let totalCompletions = logs.reduce(0) { $0 + $1.count }
            if totalCompletions >= 100 {
                awardBadge(id: "century_arc", date: now)
            }
        }

        // --- mindful_arc: Log mood 7 days in a row ---
        if !earnedIDs.contains("mindful_arc") {
            let moodDates = Set(
                moods
                    .filter { $0.moodScore > 0 }
                    .map { calendar.startOfDay(for: $0.date) }
            )
            if hasConsecutiveDays(dates: moodDates, count: 7, calendar: calendar) {
                awardBadge(id: "mindful_arc", date: now)
            }
        }

        saveToStorage()
    }

    // MARK: - Helpers

    private func hasConsecutiveDays(dates: Set<Date>, count: Int, calendar: Calendar) -> Bool {
        guard dates.count >= count else { return false }
        let sorted = dates.sorted()
        var consecutive = 1
        for i in 1..<sorted.count {
            let expected = calendar.date(byAdding: .day, value: 1, to: sorted[i - 1])!
            if sorted[i] == expected {
                consecutive += 1
                if consecutive >= count { return true }
            } else {
                consecutive = 1
            }
        }
        return false
    }

    private func awardBadge(id: String, date: Date) {
        guard let definition = Self.allBadges.first(where: { $0.id == id }) else { return }
        var badge = definition
        badge.earnedDate = date
        earnedBadges.append(badge)
        // Only set ceremony if none is pending (first-come wins, avoid stacking)
        if pendingCeremony == nil {
            pendingCeremony = badge
        }
    }

    // MARK: - Persistence

    private func saveToStorage() {
        guard let data = try? JSONEncoder().encode(earnedBadges) else { return }
        UserDefaults.standard.set(data, forKey: Self.storageKey)
    }

    private func loadFromStorage() {
        guard let data = UserDefaults.standard.data(forKey: Self.storageKey),
              let badges = try? JSONDecoder().decode([Badge].self, from: data) else { return }
        earnedBadges = badges
    }
}
