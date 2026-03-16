import SwiftUI

/// Card displaying a single habit-mood correlation result.
/// Shows emoji + habit name + correlation label + bar visualization.
/// Green for positive, red for negative, gray for neutral.
/// Tap expands to show sample size and explanation.
struct CorrelationCardView: View {
    let result: CorrelationEngine.CorrelationResult

    @State private var isExpanded = false

    private var barColor: Color {
        switch result.coefficient {
        case 0.15...: return DailyArcTokens.success
        case ..<(-0.15): return DailyArcTokens.error
        default: return DailyArcTokens.disabled
        }
    }

    private var barWidth: CGFloat {
        CGFloat(abs(result.coefficient))
    }

    var body: some View {
        VStack(alignment: .leading, spacing: DailyArcSpacing.sm) {
            // Header: emoji + name + label
            Button {
                withAnimation(.easeInOut(duration: 0.25)) {
                    isExpanded.toggle()
                }
            } label: {
                HStack(spacing: DailyArcSpacing.sm) {
                    Text(result.emoji)
                        .font(.title2)

                    VStack(alignment: .leading, spacing: DailyArcSpacing.xxs) {
                        Text(result.habitName)
                            .typography(.bodyLarge)
                            .fontWeight(.medium)
                            .foregroundStyle(DailyArcTokens.textPrimary)

                        Text(result.label)
                            .typography(.caption)
                            .foregroundStyle(barColor)
                    }

                    Spacer()

                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .typography(.caption)
                        .foregroundStyle(DailyArcTokens.textTertiary)
                }
            }
            .buttonStyle(.plain)

            // Bar visualization
            GeometryReader { geo in
                ZStack(alignment: result.coefficient >= 0 ? .leading : .trailing) {
                    // Background track
                    RoundedRectangle(cornerRadius: 4)
                        .fill(DailyArcTokens.backgroundSecondary)
                        .frame(height: 8)

                    // Filled bar
                    RoundedRectangle(cornerRadius: 4)
                        .fill(barColor)
                        .frame(width: max(geo.size.width * barWidth, 4), height: 8)
                }
            }
            .frame(height: 8)

            // Expanded details
            if isExpanded {
                VStack(alignment: .leading, spacing: DailyArcSpacing.xs) {
                    // Plain language explanation
                    if result.averageMoodOnHabitDays > 0 {
                        Text("On \(result.habitName) days, your mood averages \(String(format: "%.1f", result.averageMoodOnHabitDays))")
                            .typography(.bodySmall)
                            .foregroundStyle(DailyArcTokens.textSecondary)
                    }

                    if result.averageMoodOnSkipDays > 0 {
                        Text("On skip days, your mood averages \(String(format: "%.1f", result.averageMoodOnSkipDays))")
                            .typography(.bodySmall)
                            .foregroundStyle(DailyArcTokens.textSecondary)
                    }

                    // Sample size
                    HStack(spacing: DailyArcSpacing.xs) {
                        Image(systemName: "calendar")
                            .foregroundStyle(DailyArcTokens.textTertiary)
                        Text("Based on \(result.sampleSize) days of data")
                            .typography(.caption)
                            .foregroundStyle(DailyArcTokens.textTertiary)
                    }

                    // Confidence qualifier
                    if let qualifier = CorrelationEngine.confidenceQualifier(sampleSize: result.sampleSize) {
                        Text(qualifier)
                            .typography(.caption)
                            .foregroundStyle(DailyArcTokens.textTertiary)
                            .italic()
                    }
                }
                .padding(.top, DailyArcSpacing.xxs)
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .padding(DailyArcSpacing.lg)
        .background(DailyArcTokens.backgroundSecondary.opacity(0.5))
        .clipShape(RoundedRectangle(cornerRadius: DailyArcTokens.cornerRadiusLarge))
        .overlay(
            RoundedRectangle(cornerRadius: DailyArcTokens.cornerRadiusLarge)
                .stroke(DailyArcTokens.separator.opacity(0.3), lineWidth: 1)
        )
    }
}
