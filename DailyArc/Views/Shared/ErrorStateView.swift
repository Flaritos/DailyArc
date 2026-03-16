import SwiftUI

/// Reusable error state with arc motif, message, retry button, and help link.
struct ErrorStateView: View {
    let message: String
    let onRetry: () -> Void

    var body: some View {
        VStack(spacing: DailyArcSpacing.xl) {
            // Arc motif illustration (dimmed AppIconView)
            AppIconView(size: 80)
                .opacity(0.4)

            // Error message
            Text(message)
                .typography(.bodyLarge)
                .foregroundStyle(DailyArcTokens.textPrimary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, DailyArcSpacing.lg)

            // Retry button
            Button(action: onRetry) {
                Text("Retry")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .tint(DailyArcTokens.accent)
            .padding(.horizontal, DailyArcSpacing.lg)

            // Help link
            Text("Need help? Contact us")
                .typography(.caption)
                .foregroundStyle(DailyArcTokens.textTertiary)
        }
        .padding(DailyArcSpacing.xl)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(DailyArcTokens.backgroundSecondary)
        )
    }
}

#Preview {
    ErrorStateView(
        message: "Something went wrong loading your data.",
        onRetry: {}
    )
    .padding()
}
