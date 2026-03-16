import SwiftUI

/// Horizontal scroll of 8 pre-defined activity tags.
/// Tap toggles selection. Saves to MoodEntry.activities as pipe-delimited string.
struct ActivityTagsView: View {
    let selectedActivities: [String]
    let onToggle: (String) -> Void

    private static let tags = [
        "Exercise", "Work", "Social", "Creative",
        "Outdoors", "Rest", "Travel", "Learning"
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: DailyArcSpacing.sm) {
            Text("What have you been up to?")
                .typography(.callout)
                .foregroundStyle(DailyArcTokens.textSecondary)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: DailyArcSpacing.sm) {
                    ForEach(Self.tags, id: \.self) { tag in
                        let isSelected = selectedActivities.contains(tag)

                        Button {
                            onToggle(tag)
                        } label: {
                            Text(tag)
                                .typography(.caption)
                                .fontWeight(isSelected ? .semibold : .regular)
                                .padding(.horizontal, DailyArcSpacing.md)
                                .padding(.vertical, DailyArcSpacing.sm)
                                .background(
                                    Capsule()
                                        .fill(
                                            isSelected
                                                ? DailyArcTokens.accent.opacity(DailyArcTokens.opacityLight)
                                                : DailyArcTokens.backgroundSecondary
                                        )
                                )
                                .overlay(
                                    Capsule()
                                        .stroke(
                                            isSelected ? DailyArcTokens.accent : Color.clear,
                                            lineWidth: DailyArcTokens.borderThin
                                        )
                                )
                                .foregroundStyle(
                                    isSelected ? DailyArcTokens.accent : DailyArcTokens.textPrimary
                                )
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel("\(tag) activity")
                        .accessibilityAddTraits(isSelected ? .isSelected : [])
                    }
                }
                .padding(.horizontal, DailyArcSpacing.xs)
            }
        }
    }
}

#Preview {
    ActivityTagsView(
        selectedActivities: ["Exercise", "Creative"],
        onToggle: { _ in }
    )
    .padding()
}
