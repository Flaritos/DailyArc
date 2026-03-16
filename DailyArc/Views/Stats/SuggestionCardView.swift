import SwiftUI

/// Card displaying a RuleEngine suggestion.
/// Shows emoji + suggestion text in a compact card format.
struct SuggestionCardView: View {
    let suggestion: RuleEngine.Suggestion

    var body: some View {
        HStack(alignment: .top, spacing: DailyArcSpacing.md) {
            Text(suggestion.emoji)
                .font(.title2)

            Text(suggestion.text)
                .typography(.bodySmall)
                .foregroundStyle(DailyArcTokens.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(DailyArcSpacing.lg)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(DailyArcTokens.backgroundSecondary.opacity(0.5))
        .clipShape(RoundedRectangle(cornerRadius: DailyArcTokens.cornerRadiusLarge))
        .overlay(
            RoundedRectangle(cornerRadius: DailyArcTokens.cornerRadiusLarge)
                .stroke(DailyArcTokens.separator.opacity(0.3), lineWidth: 1)
        )
    }
}
