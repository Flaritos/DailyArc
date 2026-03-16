import SwiftUI

/// Compassion toast shown when archiving or unarchiving a habit.
/// Archive: acknowledges the streak and reassures the user.
/// Unarchive: welcomes the habit back with encouragement.
/// Posts VoiceOver announcements on appearance for accessibility.
struct ArchiveToastView: View {
    let action: ArchiveAction
    let habitName: String
    let habitEmoji: String
    let streak: Int

    enum ArchiveAction {
        case archive
        case unarchive
    }

    private var message: String {
        switch action {
        case .archive:
            return "\(streak) days of \(habitEmoji) \(habitName). A pause in your arc \u{2014} it\u{2019}ll be here when you\u{2019}re ready."
        case .unarchive:
            return "Welcome back, \(habitEmoji) \(habitName)! Ready to continue your arc?"
        }
    }

    var body: some View {
        HStack(spacing: DailyArcSpacing.sm) {
            Text(message)
                .typography(.bodySmall)
                .foregroundStyle(DailyArcTokens.textPrimary)
                .multilineTextAlignment(.leading)
        }
        .padding(.horizontal, DailyArcSpacing.lg)
        .padding(.vertical, DailyArcSpacing.md)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: DailyArcTokens.cornerRadiusMedium)
                .fill(DailyArcTokens.backgroundSecondary)
                .shadow(color: .black.opacity(0.1), radius: 8, y: 4)
        )
        .padding(.horizontal, DailyArcSpacing.lg)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(message)
        .onAppear {
            AccessibilityNotification.Announcement(message)
                .post()
        }
    }
}

// MARK: - Previews

#Preview("Archive Toast") {
    VStack {
        Spacer()
        ArchiveToastView(
            action: .archive,
            habitName: "Meditation",
            habitEmoji: "\u{1F9D8}",
            streak: 42
        )
    }
    .padding(.bottom, 40)
}

#Preview("Unarchive Toast") {
    VStack {
        Spacer()
        ArchiveToastView(
            action: .unarchive,
            habitName: "Reading",
            habitEmoji: "\u{1F4DA}",
            streak: 0
        )
    }
    .padding(.bottom, 40)
}
