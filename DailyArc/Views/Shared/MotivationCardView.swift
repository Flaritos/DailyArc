import SwiftUI

/// A card view for Day N motivation touchpoints.
/// Supports three visual styles: subtle toast, standard card, and gold-accented card.
struct MotivationCardView: View {
    let message: String
    let style: MotivationCardStyle
    let onDismiss: () -> Void

    enum MotivationCardStyle {
        case toast      // Subtle inline text
        case card       // Dismissible card with backgroundSecondary
        case goldCard   // Card with gold border accent
    }

    var body: some View {
        switch style {
        case .toast:
            toastContent

        case .card:
            cardContent(borderColor: .clear)

        case .goldCard:
            cardContent(borderColor: DailyArcTokens.premiumGold)
        }
    }

    // MARK: - Toast Style

    private var toastContent: some View {
        HStack(spacing: DailyArcSpacing.sm) {
            Text(message)
                .typography(.bodySmall)
                .foregroundStyle(DailyArcTokens.textSecondary)
                .multilineTextAlignment(.leading)

            Spacer()

            Button {
                onDismiss()
            } label: {
                Image(systemName: "xmark")
                    .font(.caption2)
                    .foregroundStyle(DailyArcTokens.textTertiary)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, DailyArcSpacing.lg)
        .padding(.vertical, DailyArcSpacing.xs)
    }

    // MARK: - Card Style

    private func cardContent(borderColor: Color) -> some View {
        HStack(alignment: .top, spacing: DailyArcSpacing.md) {
            Text(message)
                .typography(.bodySmall)
                .foregroundStyle(DailyArcTokens.textPrimary)
                .multilineTextAlignment(.leading)

            Spacer()

            Button {
                onDismiss()
            } label: {
                Image(systemName: "xmark")
                    .font(.caption)
                    .foregroundStyle(DailyArcTokens.textTertiary)
            }
            .buttonStyle(.plain)
        }
        .padding(DailyArcSpacing.lg)
        .background(
            RoundedRectangle(cornerRadius: DailyArcTokens.cornerRadiusMedium)
                .fill(DailyArcTokens.backgroundSecondary)
                .overlay(
                    RoundedRectangle(cornerRadius: DailyArcTokens.cornerRadiusMedium)
                        .stroke(borderColor, lineWidth: borderColor == .clear ? 0 : DailyArcTokens.borderMedium)
                )
                .shadow(color: DailyArcTokens.cardShadow, radius: 6, y: 2)
        )
        .padding(.horizontal, DailyArcSpacing.lg)
    }
}

// MARK: - Previews

#Preview("Toast Style") {
    MotivationCardView(
        message: "Day 3 -- habits take shape through repetition. Keep going!",
        style: .toast,
        onDismiss: {}
    )
}

#Preview("Card Style") {
    MotivationCardView(
        message: "Day 7 -- you've built a full week of momentum. That's real progress.",
        style: .card,
        onDismiss: {}
    )
}

#Preview("Gold Card Style") {
    MotivationCardView(
        message: "Day 30 -- a full month of consistency. You're building something lasting.",
        style: .goldCard,
        onDismiss: {}
    )
}
