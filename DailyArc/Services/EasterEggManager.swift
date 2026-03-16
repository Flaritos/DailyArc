import SwiftUI

/// Manages discovery-based easter eggs: date-based greetings, streak curiosities,
/// app-open milestones, and anniversary detection.
/// Discovered eggs are persisted via @AppStorage and count toward the "Detail Arc" badge.
@MainActor
@Observable
final class EasterEggManager {
    static let shared = EasterEggManager()

    @ObservationIgnored
    @AppStorage("easterEggDiscoveries") private var discoveryList = ""

    @ObservationIgnored
    @AppStorage("appOpenCount") private var appOpenCount = 0

    @ObservationIgnored
    @AppStorage("firstLaunchDate") private var firstLaunchDateString = ""

    var activeEasterEgg: String? = nil

    // MARK: - Discovery Tracking

    var discoveries: Set<String> {
        Set(discoveryList.split(separator: ",").map(String.init))
    }

    func recordDiscovery(_ id: String) {
        var set = discoveries
        guard !set.contains(id) else { return }
        set.insert(id)
        discoveryList = set.sorted().joined(separator: ",")
    }

    var discoveryCount: Int { discoveries.count }

    /// True when 5+ easter eggs have been found (unlocks Detail Arc badge).
    var hasDetailArcBadge: Bool { discoveryCount >= 5 }

    // MARK: - App Open Tracking

    func incrementAppOpen() {
        appOpenCount += 1
        if firstLaunchDateString.isEmpty {
            firstLaunchDateString = ISO8601DateFormatter().string(from: Date())
        }
    }

    // MARK: - Date-Based Easter Eggs

    /// Returns an easter egg ID if today matches a special date. Does not auto-record.
    func checkDateEasterEggs() -> String? {
        let cal = Calendar.current
        let month = cal.component(.month, from: Date())
        let day = cal.component(.day, from: Date())
        let weekday = cal.component(.weekday, from: Date())

        if month == 3 && day == 14 { return "piday" }
        if month == 2 && day == 14 { return "valentines" }
        if month == 1 && day <= 3 { return "newyear" }
        if month == 10 && day == 31 { return "halloween" }
        // Calendar.component(.weekday): 1=Sun ... 6=Fri 7=Sat
        if weekday == 6 && day == 13 { return "friday13" }

        return nil
    }

    // MARK: - Streak-Based Easter Eggs

    /// Returns a special message for curiosity streaks (42, palindromes).
    func checkStreakEasterEgg(streak: Int) -> String? {
        // 42 -- the answer
        if streak == 42 {
            recordDiscovery("streak42")
            return "The answer to life, the universe, and everything? Showing up 42 days in a row."
        }
        // Palindrome streaks >= 11
        let str = String(streak)
        if streak >= 11 && str == String(str.reversed()) {
            recordDiscovery("palindrome\(streak)")
            return "Palindrome streak! That\u{2019}s oddly satisfying."
        }
        return nil
    }

    // MARK: - App-Open Milestones

    /// Returns a message on the 100th app open. Records discovery automatically.
    func check100thOpen() -> String? {
        if appOpenCount == 100 {
            recordDiscovery("100opens")
            return "Welcome back for the 100th time! You really love this, huh?"
        }
        return nil
    }

    // MARK: - Anniversary

    /// Returns a message on the 1-year anniversary of first launch.
    func checkAnniversary() -> String? {
        guard !firstLaunchDateString.isEmpty,
              let firstDate = ISO8601DateFormatter().date(from: firstLaunchDateString) else { return nil }
        let cal = Calendar.current
        let components = cal.dateComponents([.year, .month, .day], from: firstDate, to: Date())
        if (components.year ?? 0) >= 1 && components.month == 0 && components.day == 0 {
            recordDiscovery("anniversary")
            return "Happy DailyArc-iversary! One year of building better habits."
        }
        return nil
    }

    // MARK: - Date-Based Greeting Variants

    /// Returns a personalized greeting for special dates. Records discovery on match.
    func dateGreeting(name: String) -> String? {
        let cal = Calendar.current
        let month = cal.component(.month, from: Date())
        let day = cal.component(.day, from: Date())
        let weekday = cal.component(.weekday, from: Date())

        if month == 3 && day == 14 {
            recordDiscovery("piday")
            return "Happy Pi Day, \(name)! Your arc is approximately 3.14 radians."
        }
        if month == 2 && day == 14 {
            recordDiscovery("valentines")
            return "Spreading love through your arc, \(name)."
        }
        if month == 1 && day <= 3 {
            recordDiscovery("newyear")
            return "New year, new arc, \(name)."
        }
        if month == 10 && day == 31 {
            recordDiscovery("halloween")
            return "Spooky arc, \(name)!"
        }
        if weekday == 6 && day == 13 {
            recordDiscovery("friday13")
            return "Spooky Friday, \(name)!"
        }

        return nil
    }
}
