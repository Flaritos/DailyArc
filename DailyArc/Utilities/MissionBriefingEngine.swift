import Foundation

/// Text transformation layer for Command theme premium users.
/// Reframes habits as military operations with themed language.
struct MissionBriefingEngine {

    /// Returns the habit name in uppercase — the monospace + uppercase styling
    /// already makes it feel Command-y without needing jargon.
    static func habitDisplayName(_ name: String) -> String {
        return name.uppercased()
    }

    /// Returns a military-style status string for habit completion state.
    static func completionStatus(completed: Bool, count: Int, target: Int) -> String {
        if completed { return "[DONE]" }
        if count > 0 { return "[\(count)/\(target)]" }
        return "[PENDING]"
    }

    /// Generates a daily briefing header with objective counts.
    static func dailyBriefingHeader(habitCount: Int, completedCount: Int) -> String {
        "TODAY'S OVERVIEW \u{2014} \(completedCount)/\(habitCount) DONE"
    }

    /// Returns an end-of-day performance summary based on completion percentage.
    static func endOfDaySummary(completionPercent: Int) -> String {
        switch completionPercent {
        case 90...100: return "ALL SYSTEMS GO"
        case 70..<90: return "SOLID PROGRESS"
        case 50..<70: return "HALFWAY THERE"
        default: return "TOMORROW'S ANOTHER DAY"
        }
    }
}
