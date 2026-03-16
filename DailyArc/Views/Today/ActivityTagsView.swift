import SwiftUI

/// Horizontal scroll of 8 pre-defined activity tags + custom tags.
/// Tap toggles selection. Saves to MoodEntry.activities as pipe-delimited string.
struct ActivityTagsView: View {
    let selectedActivities: [String]
    let onToggle: (String) -> Void

    @State private var showAddCustomTag = false
    @State private var customTagName = ""
    @AppStorage("customActivityTags") private var customActivityTagsJSON = "[]"

    private static let defaultTags: [(emoji: String, name: String)] = [
        ("\u{1F3C3}", "Exercise"),
        ("\u{1F4BC}", "Work"),
        ("\u{1F465}", "Social"),
        ("\u{1F3A8}", "Creative"),
        ("\u{1F3B5}", "Music"),
        ("\u{1F4DA}", "Reading"),
        ("\u{1F9D8}", "Mindful"),
        ("\u{1F634}", "Rest"),
    ]

    private var customTags: [String] {
        (try? JSONDecoder().decode([String].self, from: Data(customActivityTagsJSON.utf8))) ?? []
    }

    private func saveCustomTags(_ tags: [String]) {
        if let data = try? JSONEncoder().encode(tags),
           let json = String(data: data, encoding: .utf8) {
            customActivityTagsJSON = json
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: DailyArcSpacing.sm) {
            Text("What have you been up to?")
                .typography(.callout)
                .foregroundStyle(DailyArcTokens.textSecondary)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: DailyArcSpacing.sm) {
                    // Default tags
                    ForEach(Self.defaultTags, id: \.name) { tag in
                        tagButton(label: "\(tag.emoji) \(tag.name)", value: tag.name)
                    }

                    // Custom tags
                    ForEach(customTags, id: \.self) { tag in
                        tagButton(label: tag, value: tag)
                    }

                    // Add custom tag button
                    Button {
                        showAddCustomTag = true
                    } label: {
                        Image(systemName: "plus")
                            .font(.system(size: 14, weight: .semibold))
                            .frame(width: 36, height: 36)
                            .background(
                                Circle()
                                    .fill(DailyArcTokens.backgroundSecondary)
                            )
                            .overlay(
                                Circle()
                                    .stroke(DailyArcTokens.separator, lineWidth: DailyArcTokens.borderThin)
                            )
                            .foregroundStyle(DailyArcTokens.textSecondary)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Add custom activity tag")
                }
                .padding(.horizontal, DailyArcSpacing.xs)
            }
        }
        .alert("Add Custom Tag", isPresented: $showAddCustomTag) {
            TextField("Tag name", text: $customTagName)
            Button("Cancel", role: .cancel) {
                customTagName = ""
            }
            Button("Add") {
                let trimmed = customTagName.trimmingCharacters(in: .whitespacesAndNewlines)
                if !trimmed.isEmpty {
                    var tags = customTags
                    if tags.count < 10 && !tags.contains(trimmed) {
                        tags.append(trimmed)
                        saveCustomTags(tags)
                    }
                }
                customTagName = ""
            }
        } message: {
            let remaining = max(0, 10 - customTags.count)
            Text("Enter a name for your custom tag. \(remaining) slots remaining.")
        }
    }

    private func tagButton(label: String, value: String) -> some View {
        let isSelected = selectedActivities.contains(value)

        return Button {
            HapticManager.activityTag()
            onToggle(value)
        } label: {
            Text(label)
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
        .accessibilityLabel("\(value) activity")
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}

#Preview {
    ActivityTagsView(
        selectedActivities: ["Exercise", "Creative"],
        onToggle: { _ in }
    )
    .padding()
}
