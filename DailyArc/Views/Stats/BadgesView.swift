import SwiftUI

struct BadgesView: View {
    @Environment(\.theme) private var theme
    private var badgeEngine = BadgeEngine.shared

    private let columns = [
        GridItem(.flexible(), spacing: DailyArcSpacing.md),
        GridItem(.flexible(), spacing: DailyArcSpacing.md)
    ]

    /// All badge definitions with earned status merged in.
    private var allBadges: [Badge] {
        let earnedMap = Dictionary(
            uniqueKeysWithValues: badgeEngine.earnedBadges.map { ($0.id, $0) }
        )
        return BadgeEngine.allBadges.map { definition in
            if let earned = earnedMap[definition.id] {
                return earned
            }
            return definition
        }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: DailyArcSpacing.lg) {
                // Summary
                let earnedCount = badgeEngine.earnedBadges.count
                let totalCount = BadgeEngine.allBadges.count
                Text(theme.uppercaseHeaders ? "\(theme.headerPrefix)\(earnedCount) OF \(totalCount) EARNED" : "\(earnedCount) of \(totalCount) earned")
                    .typography(.bodySmall)
                    .fontDesign(theme.displayFontDesign)
                    .foregroundStyle(theme.textSecondary)
                    .padding(.horizontal, DailyArcSpacing.lg)

                LazyVGrid(columns: columns, spacing: DailyArcSpacing.md) {
                    ForEach(allBadges) { badge in
                        BadgeCardView(badge: badge, theme: theme)
                    }
                }
                .padding(.horizontal, DailyArcSpacing.lg)
            }
            .padding(.vertical, DailyArcSpacing.lg)
        }
        .background(theme.backgroundPrimary)
        .navigationTitle("Badges")
    }
}

// MARK: - Badge Card

private struct BadgeCardView: View {
    let badge: Badge
    let theme: any ThemeDefinition

    var body: some View {
        VStack(spacing: DailyArcSpacing.sm) {
            if badge.isEarned {
                Text(badge.emoji)
                    .font(.system(size: 40))

                Text(badge.name)
                    .typography(.bodySmall)
                    .fontWeight(.bold)
                    .fontDesign(theme.displayFontDesign)
                    .foregroundStyle(theme.textPrimary)
                    .lineLimit(1)

                if let date = badge.earnedDate {
                    Text(date, style: .date)
                        .typography(.caption)
                        .foregroundStyle(theme.textTertiary)
                }
            } else {
                Image(systemName: "lock.fill")
                    .font(.system(size: 32))
                    .foregroundStyle(theme.textTertiary)

                Text(badge.name)
                    .typography(.bodySmall)
                    .fontWeight(.semibold)
                    .fontDesign(theme.displayFontDesign)
                    .foregroundStyle(theme.textTertiary)
                    .lineLimit(1)

                Text(badge.description)
                    .typography(.caption)
                    .foregroundStyle(theme.textTertiary)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, DailyArcSpacing.lg)
        .padding(.horizontal, DailyArcSpacing.sm)
        .background(
            RoundedRectangle(cornerRadius: theme.cornerRadiusMedium)
                .fill(theme.id == "command" ? CommandTheme.panel : theme.backgroundSecondary)
        )
        .overlay(
            RoundedRectangle(cornerRadius: theme.cornerRadiusMedium)
                .stroke(
                    badge.isEarned
                        ? (theme.id == "command" ? CommandTheme.cyan.opacity(0.5) : DailyArcTokens.accent.opacity(0.3))
                        : theme.separator,
                    lineWidth: DailyArcTokens.borderThin
                )
        )
        .shadow(color: badge.isEarned && theme.id == "command" ? CommandTheme.glowCyan.opacity(0.3) : .clear, radius: 6)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(badge.isEarned
            ? "\(badge.name) badge earned"
            : "\(badge.name) badge locked. \(badge.description)")
    }
}

#Preview {
    NavigationStack {
        BadgesView()
    }
}
