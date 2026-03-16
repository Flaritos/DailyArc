import SwiftUI

/// Day-N motivation touchpoints that encourage continued engagement.
/// Shows contextual messages at key day counts (3, 5, 8, 10, 12, 15, 21, 25, 45, 60, 75, 90).
/// Messages reference upcoming badges and milestones to create anticipation.
@MainActor
@Observable
final class MotivationService {
    static let shared = MotivationService()

    struct MotivationCard: Identifiable {
        let id = UUID()
        let message: String
        let style: CardStyle

        enum CardStyle {
            case toast      // Brief inline text
            case card       // Dismissible card
            case goldCard   // Card with gold border (premium milestone tease)
        }
    }

    var activeCard: MotivationCard? = nil

    // MARK: - Day Milestone Check

    /// Check what motivation touchpoint to show based on total days the user has logged.
    /// - Parameters:
    ///   - totalDaysLogged: Number of unique days with at least one habit completion.
    ///   - userName: User's display name for personalization (reserved for future use).
    func checkDayMilestone(totalDaysLogged: Int, userName: String) {
        switch totalDaysLogged {
        case 3:
            activeCard = MotivationCard(
                message: "3 days in \u{2014} you\u{2019}re past the hardest part!",
                style: .toast
            )
        case 5:
            activeCard = MotivationCard(
                message: "By Day 7, you\u{2019}ll earn your Rising Arc badge.",
                style: .card
            )
        case 8:
            activeCard = MotivationCard(
                message: "One week down! Here\u{2019}s your first weekly trend.",
                style: .card
            )
        case 10:
            activeCard = MotivationCard(
                message: "10 days \u{2014} your arc is taking shape!",
                style: .toast
            )
        case 12:
            activeCard = MotivationCard(
                message: "Two more days until your first insights unlock!",
                style: .card
            )
        case 15:
            activeCard = MotivationCard(
                message: "15 days \u{2014} you\u{2019}re halfway to your Blazing Arc badge.",
                style: .goldCard
            )
        case 21:
            activeCard = MotivationCard(
                message: "21 days \u{2014} you\u{2019}re building something real.",
                style: .toast
            )
        case 25:
            activeCard = MotivationCard(
                message: "5 more days to Blazing Arc. Keep it going!",
                style: .card
            )
        case 45:
            activeCard = MotivationCard(
                message: "Six weeks in. That\u{2019}s longer than most gym memberships last.",
                style: .toast
            )
        case 60:
            activeCard = MotivationCard(
                message: "Two months. Your arc is one of the long ones now.",
                style: .toast
            )
        case 75:
            activeCard = MotivationCard(
                message: "75 days \u{2014} three quarters of the way to your Golden Arc.",
                style: .card
            )
        case 90:
            activeCard = MotivationCard(
                message: "90 days. Ten more to Gold. Almost there.",
                style: .goldCard
            )
        default:
            break
        }
    }

    // MARK: - Dismiss

    func dismiss() {
        withAnimation(.easeOut(duration: 0.2)) {
            activeCard = nil
        }
    }
}
