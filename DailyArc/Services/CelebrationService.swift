import SwiftUI

/// Manages milestone celebrations, streak loss compassion, and first-ever moments.
/// Uses deterministic message selection via stable hashing for consistent per-habit messaging.
@MainActor
@Observable
final class CelebrationService {
    static let shared = CelebrationService()

    var activeCelebration: Celebration? = nil
    var showCelebration = false
    var show365Celebration = false

    struct Celebration: Identifiable {
        let id = UUID()
        let tier: CelebrationTier
        let title: String
        let message: String
        let emoji: String
        let showShareCard: Bool
        let habitName: String?
    }

    enum CelebrationTier {
        case starter    // 3d, 7d -- inline toast
        case milestone  // 14d, 30d -- modal card + chime
        case summit     // 100d -- modal + confetti + fanfare
        case zenith     // 365d -- full-screen takeover
    }

    // MARK: - Streak Milestones

    /// Milestone messages keyed by streak day count.
    /// Each entry: (title, message, tier, showShareCard). 2-3 variants per milestone.
    private static let milestoneMessages: [Int: [(String, String, CelebrationTier, Bool)]] = [
        3: [
            ("Your arc begins!", "Three days in \u{2014} your arc is taking shape.", .starter, false),
            ("Day 3!", "Day 3 \u{2014} the first arc is the hardest.", .starter, false),
        ],
        7: [
            ("One week on your arc!", "7 days \u{2014} your arc is rising.", .starter, false),
            ("A whole week!", "A whole week of building your arc!", .starter, false),
        ],
        14: [
            ("Two weeks strong!", "14 days \u{2014} your arc is becoming a pattern.", .milestone, false),
            ("Two weeks!", "Two weeks of showing up for your arc.", .milestone, false),
        ],
        30: [
            ("A month-long arc!", "30 days. This arc tells a story.", .milestone, true),
            ("A whole month!", "A whole month. That\u{2019}s an arc worth celebrating.", .milestone, true),
        ],
        100: [
            ("100 days!", "100 days of choosing yourself. Your arc speaks for itself.", .summit, true),
            ("One hundred days!", "One hundred days. This arc is undeniable.", .summit, true),
        ],
        365: [
            ("A complete arc!", "365 days. Your arc has come full circle.", .zenith, true),
            ("One year!", "One year of showing up. A complete arc \u{2014} you\u{2019}ve earned it.", .zenith, true),
        ],
    ]

    /// Check whether the habit's current streak matches a milestone and present the appropriate celebration.
    /// - Parameters:
    ///   - habit: The habit whose streak changed.
    ///   - previousStreak: The streak value before the latest change (used for comeback detection).
    func checkStreakMilestone(habit: Habit, previousStreak: Int) {
        let streak = habit.currentStreak

        if let variants = Self.milestoneMessages[streak] {
            let index = Int(stableHash(habit.id.uuidString)) % variants.count
            let variant = variants[index]
            activeCelebration = Celebration(
                tier: variant.2,
                title: variant.0,
                message: variant.1,
                emoji: "",
                showShareCard: variant.3,
                habitName: habit.name
            )
            showCelebration = true

            // Trigger the 365-day golden arc animation
            if streak == 365 {
                show365Celebration = true
            }

            // Haptic feedback scaled to tier
            switch variant.2 {
            case .starter:
                HapticManager.habitCompletion()
            case .milestone, .summit, .zenith:
                HapticManager.streakMilestone()
            }
        }

        // Comeback Arc: rebuilt streak to 7+ after losing a 30+ day streak
        if streak == 7 && previousStreak >= 30 {
            let comebackMessages = [
                "Your Comeback Arc! You lost a \(previousStreak)-day streak and came back stronger.",
                "You rebuilt. \(previousStreak) days fell, and you started again. That takes real strength.",
                "A \(previousStreak)-day streak ended. But here you are, 7 days into a new arc.",
            ]
            let index = Int(stableHash(habit.id.uuidString + "comeback")) % comebackMessages.count
            activeCelebration = Celebration(
                tier: .milestone,
                title: "Comeback Arc!",
                message: comebackMessages[index],
                emoji: "\u{1F525}",
                showShareCard: true,
                habitName: habit.name
            )
            showCelebration = true
            HapticManager.streakMilestone()
        }
    }

    // MARK: - First-Ever Moments

    /// Show a celebration for the user's very first habit completion. Fires once per lifetime.
    func checkFirstEverHabitCompletion() {
        guard !UserDefaults.standard.bool(forKey: "hasCompletedFirstHabit") else { return }
        UserDefaults.standard.set(true, forKey: "hasCompletedFirstHabit")
        activeCelebration = Celebration(
            tier: .starter,
            title: "Your arc begins here.",
            message: "You just completed your first habit.",
            emoji: "\u{2728}",
            showShareCard: false,
            habitName: nil
        )
        showCelebration = true
        HapticManager.habitCompletion()
    }

    /// Show a celebration for the user's very first mood log. Fires once per lifetime.
    func checkFirstEverMoodLog() {
        guard !UserDefaults.standard.bool(forKey: "hasLoggedFirstMood") else { return }
        UserDefaults.standard.set(true, forKey: "hasLoggedFirstMood")
        activeCelebration = Celebration(
            tier: .starter,
            title: "Your first reflection",
            message: "Your arc just got richer.",
            emoji: "\u{1F31F}",
            showShareCard: false,
            habitName: nil
        )
        showCelebration = true
        HapticManager.habitCompletion()
    }

    // MARK: - Streak Loss Compassion

    /// Show a compassionate message when a streak is lost.
    /// - Parameters:
    ///   - habitName: Display name of the habit.
    ///   - lostStreak: The streak value that was lost.
    func showStreakLoss(habitName: String, lostStreak: Int) {
        let messages = [
            "Your \(lostStreak)-day streak on \(habitName) ended, but your arc continues.",
            "A pause in your \(habitName) arc. \(lostStreak) days is still something to be proud of.",
            "Every arc has pauses. Your \(lostStreak) days of \(habitName) still count.",
        ]
        let index = Int(stableHash(habitName + String(lostStreak))) % messages.count
        activeCelebration = Celebration(
            tier: .starter,
            title: "A pause in your arc",
            message: messages[index],
            emoji: "",
            showShareCard: false,
            habitName: habitName
        )
        showCelebration = true
    }

    // MARK: - Dismiss

    func dismiss() {
        withAnimation(.easeOut(duration: 0.2)) {
            showCelebration = false
            show365Celebration = false
        }
        activeCelebration = nil
    }

    // MARK: - Stable Hash

    /// Simple deterministic hash for consistent variant selection across launches.
    /// Uses djb2 algorithm for stability (no dependency on Hashable which can vary between runs).
    private func stableHash(_ input: String) -> UInt {
        var hash: UInt = 5381
        for byte in input.utf8 {
            hash = ((hash &<< 5) &+ hash) &+ UInt(byte)
        }
        return hash
    }
}
