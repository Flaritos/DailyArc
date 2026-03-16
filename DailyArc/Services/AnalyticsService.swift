import Foundation

/// Analytics event tracking stub.
/// TODO: Integrate TelemetryDeck SDK before launch.
enum AnalyticsService {
    static var isEnabled: Bool {
        UserDefaults.standard.bool(forKey: "analyticsEnabled")
    }

    static func track(_ event: String, properties: [String: String] = [:]) {
        guard isEnabled else { return }
        // TODO: TelemetryDeck.signal(event, parameters: properties)
        #if DEBUG
        print("[Analytics] \(event) \(properties)")
        #endif
    }

    // Common events
    static func appLaunched() { track("app_launched") }
    static func habitCompleted(habitName: String) { track("habit_completed", properties: ["habit": habitName]) }
    static func moodLogged(score: Int) { track("mood_logged", properties: ["score": "\(score)"]) }
    static func paywallViewed(trigger: String) { track("paywall_viewed", properties: ["trigger": trigger]) }
    static func shareCardGenerated(type: String) { track("share_card_generated", properties: ["type": type]) }
    static func streakMilestone(days: Int) { track("streak_milestone", properties: ["days": "\(days)"]) }
    static func insightViewed() { track("insight_viewed") }
    static func exportCompleted(format: String) { track("export_completed", properties: ["format": format]) }
}
