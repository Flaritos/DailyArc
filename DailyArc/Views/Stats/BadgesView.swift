import SwiftUI

struct BadgesView: View {
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
                Text("\(earnedCount) of \(totalCount) earned")
                    .typography(.bodySmall)
                    .foregroundStyle(DailyArcTokens.textSecondary)
                    .padding(.horizontal, DailyArcSpacing.lg)

                LazyVGrid(columns: columns, spacing: DailyArcSpacing.md) {
                    ForEach(allBadges) { badge in
                        BadgeCardView(badge: badge)
                    }
                }
                .padding(.horizontal, DailyArcSpacing.lg)
            }
            .padding(.vertical, DailyArcSpacing.lg)
        }
        .background(DailyArcTokens.backgroundPrimary)
        .navigationTitle("Badges")
    }
}

// MARK: - Badge Card

private struct BadgeCardView: View {
    let badge: Badge

    var body: some View {
        VStack(spacing: DailyArcSpacing.sm) {
            if badge.isEarned {
                Text(badge.emoji)
                    .font(.system(size: 40))

                Text(badge.name)
                    .typography(.bodySmall)
                    .fontWeight(.bold)
                    .foregroundStyle(DailyArcTokens.textPrimary)
                    .lineLimit(1)

                if let date = badge.earnedDate {
                    Text(date, style: .date)
                        .typography(.caption)
                        .foregroundStyle(DailyArcTokens.textTertiary)
                }
            } else {
                Image(systemName: "lock.fill")
                    .font(.system(size: 32))
                    .foregroundStyle(DailyArcTokens.textTertiary)

                Text(badge.name)
                    .typography(.bodySmall)
                    .fontWeight(.semibold)
                    .foregroundStyle(DailyArcTokens.textTertiary)
                    .lineLimit(1)

                Text(badge.description)
                    .typography(.caption)
                    .foregroundStyle(DailyArcTokens.textTertiary)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, DailyArcSpacing.lg)
        .padding(.horizontal, DailyArcSpacing.sm)
        .background(
            RoundedRectangle(cornerRadius: DailyArcTokens.cornerRadiusMedium)
                .fill(DailyArcTokens.backgroundSecondary)
        )
        .overlay(
            RoundedRectangle(cornerRadius: DailyArcTokens.cornerRadiusMedium)
                .stroke(
                    badge.isEarned ? DailyArcTokens.accent.opacity(0.3) : DailyArcTokens.separator,
                    lineWidth: DailyArcTokens.borderThin
                )
        )
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
