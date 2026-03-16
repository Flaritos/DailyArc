import SwiftUI

/// A reusable undo toast component.
/// Displays a message with an "Undo" action button in a floating card.
/// Posts VoiceOver announcements on appearance for accessibility.
struct UndoToastView: View {
    let message: String
    let onUndo: () -> Void

    var body: some View {
        HStack(spacing: DailyArcSpacing.sm) {
            Text(message)
                .typography(.bodySmall)
                .foregroundStyle(DailyArcTokens.textPrimary)

            Spacer()

            Button("Undo") {
                onUndo()
            }
            .typography(.bodySmall)
            .fontWeight(.semibold)
            .foregroundStyle(DailyArcTokens.accent)
            .accessibilityAddTraits(.isButton)
        }
        .padding(.horizontal, DailyArcSpacing.lg)
        .padding(.vertical, DailyArcSpacing.sm)
        .background(
            RoundedRectangle(cornerRadius: DailyArcTokens.cornerRadiusMedium)
                .fill(DailyArcTokens.backgroundSecondary)
                .shadow(color: .black.opacity(0.1), radius: 8, y: 4)
        )
        .padding(.horizontal, DailyArcSpacing.lg)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(message). Undo available.")
        .onAppear {
            AccessibilityNotification.Announcement("\(message). Double tap to undo.")
                .post()
        }
    }
}

#Preview("Undo Toast") {
    VStack {
        Spacer()
        UndoToastView(message: "Habit archived") {
            // Undo action
        }
    }
    .padding(.bottom, 40)
}
