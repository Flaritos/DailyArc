import SwiftUI

/// Energy level picker displayed after mood is selected.
/// 5 circles (44pt) labeled 1-5 with "Low" and "High" endpoints.
/// Auto-saves to MoodEntry.energyScore.
struct EnergyPickerView: View {
    let selectedScore: Int
    let onSelect: (Int) -> Void

    var body: some View {
        VStack(spacing: DailyArcSpacing.sm) {
            Text("Energy level")
                .typography(.callout)
                .foregroundStyle(DailyArcTokens.textSecondary)

            HStack(spacing: DailyArcSpacing.sm) {
                Text("Low")
                    .typography(.caption)
                    .foregroundStyle(DailyArcTokens.textTertiary)

                ForEach(1...5, id: \.self) { score in
                    Button {
                        HapticManager.energySelection()
                        onSelect(score)
                    } label: {
                        Text("\(score)")
                            .typography(.bodyLarge)
                            .fontWeight(selectedScore == score ? .semibold : .regular)
                            .frame(width: 44, height: 44)
                            .background(
                                Circle()
                                    .fill(
                                        selectedScore == score
                                            ? DailyArcTokens.accent.opacity(DailyArcTokens.opacityLight)
                                            : DailyArcTokens.backgroundSecondary
                                    )
                            )
                            .overlay(
                                Circle()
                                    .stroke(
                                        selectedScore == score ? DailyArcTokens.accent : Color.clear,
                                        lineWidth: DailyArcTokens.borderMedium
                                    )
                            )
                            .foregroundStyle(
                                selectedScore == score
                                    ? DailyArcTokens.accent
                                    : DailyArcTokens.textPrimary
                            )
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Energy level \(score), \(energyDescription(for: score))")
                    .accessibilityAddTraits(selectedScore == score ? .isSelected : [])
                }

                Text("High")
                    .typography(.caption)
                    .foregroundStyle(DailyArcTokens.textTertiary)
            }
        }
        .padding(.vertical, DailyArcSpacing.sm)
    }
    private func energyDescription(for score: Int) -> String {
        switch score {
        case 1: return "low"
        case 2: return "below average"
        case 3: return "moderate"
        case 4: return "above average"
        case 5: return "high"
        default: return ""
        }
    }
}

#Preview {
    VStack(spacing: 40) {
        EnergyPickerView(selectedScore: 0, onSelect: { _ in })
        EnergyPickerView(selectedScore: 3, onSelect: { _ in })
    }
    .padding()
}
