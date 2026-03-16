import SwiftUI

/// Banner shown on Today View when user reaches 14 days of paired mood+habit data.
/// One-time display, tracked via @AppStorage("insightNudgeShown").
/// Tapping navigates to Stats tab, Insights segment.
struct InsightNudgeBannerView: View {
    let onTap: () -> Void
    let onDismiss: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: DailyArcSpacing.md) {
                Image(systemName: "sparkles")
                    .font(.title3)
                    .foregroundStyle(DailyArcTokens.premiumGold)

                VStack(alignment: .leading, spacing: DailyArcSpacing.xxs) {
                    Text("Your first mood-habit pattern is ready")
                        .typography(.bodySmall)
                        .fontWeight(.semibold)
                        .foregroundStyle(DailyArcTokens.textPrimary)

                    Text("Tap to see what affects your mood.")
                        .typography(.caption)
                        .foregroundStyle(DailyArcTokens.textSecondary)
                }

                Spacer()

                Button {
                    onDismiss()
                } label: {
                    Image(systemName: "xmark")
                        .typography(.caption)
                        .foregroundStyle(DailyArcTokens.textTertiary)
                }
                .buttonStyle(.plain)
            }
            .padding(DailyArcSpacing.lg)
            .background(
                RoundedRectangle(cornerRadius: DailyArcTokens.cornerRadiusLarge)
                    .fill(DailyArcTokens.backgroundSecondary)
                    .overlay(
                        RoundedRectangle(cornerRadius: DailyArcTokens.cornerRadiusLarge)
                            .stroke(DailyArcTokens.premiumGold.opacity(0.3), lineWidth: 1)
                    )
            )
        }
        .buttonStyle(.plain)
    }
}
