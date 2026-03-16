import UIKit

/// Centralized haptic feedback manager.
/// Uses UIImpactFeedbackGenerator for taps and UINotificationFeedbackGenerator for completions/milestones.
@MainActor
enum HapticManager {
    private static let lightImpact = UIImpactFeedbackGenerator(style: .light)
    private static let notification = UINotificationFeedbackGenerator()

    /// Light impact for habit tap interactions.
    static func habitTap() {
        lightImpact.impactOccurred()
    }

    /// Success notification for habit completion (reaching targetCount).
    static func habitCompletion() {
        notification.notificationOccurred(.success)
    }

    /// Success notification for streak milestones (7, 14, 30, etc.).
    static func streakMilestone() {
        notification.notificationOccurred(.success)
    }
}
