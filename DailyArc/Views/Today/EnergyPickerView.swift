import SwiftUI

/// Energy level picker displayed after mood is selected.
/// 5 circles (44pt) labeled 1-5 with "Low" and "High" endpoints.
/// Auto-saves to MoodEntry.energyScore.
/// Theme-forked: Tactile uses neumorphic raised/pressed circles;
/// Command uses diamond indicators with cyan glow.
struct EnergyPickerView: View {
    let selectedScore: Int
    let onSelect: (Int) -> Void
    @Environment(\.theme) private var theme

    var body: some View {
        if theme.id == "command" {
            commandEnergyPicker
        } else {
            tactileEnergyPicker
        }
    }

    // MARK: - Tactile (Neumorphic)

    private var tactileEnergyPicker: some View {
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
                                    .fill(Color(hex: "#E8ECF1")!)
                            )
                            .overlay(
                                Group {
                                    if selectedScore == score {
                                        // Selected: accent gradient fill
                                        Circle()
                                            .fill(
                                                LinearGradient(
                                                    colors: [
                                                        Color(hex: "#6366F1")!.opacity(0.2),
                                                        Color(hex: "#6366F1")!.opacity(0.35)
                                                    ],
                                                    startPoint: .leading,
                                                    endPoint: .trailing
                                                )
                                            )
                                    }
                                }
                            )
                            .overlay(
                                Circle()
                                    .stroke(
                                        selectedScore == score
                                            ? Color(hex: "#6366F1")!.opacity(0.3)
                                            : Color.clear,
                                        lineWidth: 2
                                    )
                            )
                            .shadow(
                                color: selectedScore == score
                                    ? Color(hex: "#A3B1C6")!.opacity(0.6)
                                    : Color.white.opacity(0.7),
                                radius: selectedScore == score ? 2 : 6,
                                x: selectedScore == score ? 1 : -3,
                                y: selectedScore == score ? 1 : -3
                            )
                            .shadow(
                                color: selectedScore == score
                                    ? Color.white.opacity(0.4)
                                    : Color(hex: "#A3B1C6")!.opacity(0.5),
                                radius: selectedScore == score ? 2 : 6,
                                x: selectedScore == score ? -1 : 3,
                                y: selectedScore == score ? -1 : 3
                            )
                            .foregroundStyle(
                                selectedScore == score
                                    ? Color(hex: "#6366F1")!
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

    // MARK: - Command (HUD Diamond Indicators)

    private var commandEnergyPicker: some View {
        VStack(spacing: DailyArcSpacing.xs) {
            Text("POWER LEVEL:")
                .font(.system(size: 10, weight: .semibold, design: .monospaced))
                .foregroundStyle(CommandTheme.cyan.opacity(0.7))
                .tracking(1.5)

            HStack(spacing: DailyArcSpacing.md) {
                Text("LOW")
                    .font(.system(size: 9, weight: .medium, design: .monospaced))
                    .foregroundStyle(Color.white.opacity(0.25))

                HStack(spacing: 10) {
                    ForEach(1...5, id: \.self) { score in
                        Button {
                            HapticManager.energySelection()
                            onSelect(score)
                        } label: {
                            commandDiamond(score: score, isSelected: selectedScore >= score)
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel("Energy level \(score), \(energyDescription(for: score))")
                        .accessibilityAddTraits(selectedScore == score ? .isSelected : [])
                    }
                }

                Text("HIGH")
                    .font(.system(size: 9, weight: .medium, design: .monospaced))
                    .foregroundStyle(Color.white.opacity(0.25))
            }
        }
        .padding(.vertical, DailyArcSpacing.sm)
    }

    private func commandDiamond(score: Int, isSelected: Bool) -> some View {
        Rectangle()
            .fill(
                isSelected
                    ? CommandTheme.cyan
                    : CommandTheme.cyan.opacity(0.1)
            )
            .frame(width: 14, height: 14)
            .rotationEffect(.degrees(45))
            .overlay(
                Rectangle()
                    .stroke(
                        isSelected
                            ? CommandTheme.cyan.opacity(0.8)
                            : CommandTheme.cyan.opacity(0.2),
                        lineWidth: 1
                    )
                    .rotationEffect(.degrees(45))
            )
            .shadow(
                color: isSelected ? CommandTheme.glowCyan : .clear,
                radius: isSelected ? 8 : 0,
                x: 0, y: 0
            )
            .frame(width: 22, height: 22) // Tap target
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
