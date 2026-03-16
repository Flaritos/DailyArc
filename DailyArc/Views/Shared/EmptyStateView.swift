import SwiftUI

/// Empty state shown when the user has no habits.
/// "No habits yet. Tap + to create your first one."
struct EmptyStateView: View {
    var body: some View {
        VStack(spacing: DailyArcSpacing.xl) {
            Spacer()

            Image(systemName: "sparkles")
                .font(.system(size: 56))
                .foregroundStyle(DailyArcTokens.accent.opacity(0.6))

            VStack(spacing: DailyArcSpacing.sm) {
                Text("No habits yet")
                    .typography(.titleMedium)
                    .foregroundStyle(DailyArcTokens.textPrimary)

                Text("Tap + to create your first one.")
                    .typography(.bodySmall)
                    .foregroundStyle(DailyArcTokens.textSecondary)
            }

            Spacer()
        }
        .frame(maxWidth: .infinity)
        .padding(DailyArcSpacing.xl)
    }
}

#Preview {
    EmptyStateView()
}
