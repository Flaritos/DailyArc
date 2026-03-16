import UIKit

/// Centralized haptic feedback manager.
/// Uses UIImpactFeedbackGenerator for taps and UINotificationFeedbackGenerator for completions/milestones.
@MainActor
enum HapticManager {
    private static let lightImpact = UIImpactFeedbackGenerator(style: .light)
    private static let mediumImpact = UIImpactFeedbackGenerator(style: .medium)
    private static let selectionGenerator = UISelectionFeedbackGenerator()
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

    /// Light feedback for subtle moments (streak loss compassion, etc.).
    static func light() {
        lightImpact.impactOccurred()
    }

    /// Selection feedback for mood emoji tap.
    static func moodSelection() {
        selectionGenerator.selectionChanged()
    }

    /// Selection feedback for energy level pick.
    static func energySelection() {
        selectionGenerator.selectionChanged()
    }

    /// Light impact for activity tag toggle.
    static func activityTag() {
        lightImpact.impactOccurred()
    }

    /// Light impact for date navigation arrow tap.
    static func dateNavigation() {
        lightImpact.impactOccurred()
    }

    /// Success notification for badge unlock ceremony.
    static func badgeUnlock() {
        notification.notificationOccurred(.success)
    }

    /// Warning notification before destructive delete action.
    static func deleteConfirmation() {
        notification.notificationOccurred(.warning)
    }

    /// Light impact for undo tap.
    static func undoTap() {
        lightImpact.impactOccurred()
    }

    /// Success notification when export completes.
    static func exportComplete() {
        notification.notificationOccurred(.success)
    }

    /// Medium impact for paywall interaction.
    static func paywallTap() {
        mediumImpact.impactOccurred()
    }
}
