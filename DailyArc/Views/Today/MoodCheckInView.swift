import SwiftUI

/// 5 emoji mood buttons in an HStack. Selected state shows accent border ring.
/// Emoji scale: 1=Pensive, 2=Confused, 3=Neutral, 4=Slightly smiling, 5=Grinning.
///
/// Deep theme fork:
/// Tactile: neumorphic raised/pressed mood circles on #E8ECF1 background.
/// Command: #111122 panel with cyan borders, glow on selection, monospace status text.
struct MoodCheckInView: View {
    @Environment(\.theme) private var theme

    let selectedScore: Int
    let onSelect: (Int) -> Void

    @AppStorage("moodDisclaimerShown") private var moodDisclaimerShown = false
    @State private var showDisclaimer = false
    @State private var pendingScore: Int? = nil

    private let moods: [(score: Int, emoji: String, label: String)] = [
        (1, "\u{1F614}", "Rough"),
        (2, "\u{1F615}", "Meh"),
        (3, "\u{1F610}", "Okay"),
        (4, "\u{1F642}", "Good"),
        (5, "\u{1F604}", "Great"),
    ]

    private var isCommand: Bool { theme.id == "command" }

    var body: some View {
        if isCommand {
            commandContainer
        } else {
            tactileContainer
        }
    }

    // MARK: - Tactile Container (Neumorphic)

    private var tactileContainer: some View {
        VStack(spacing: DailyArcSpacing.md) {
            tactileHeader

            HStack(spacing: DailyArcSpacing.lg) {
                ForEach(moods, id: \.score) { mood in
                    tactileMoodButton(mood)
                }
            }
        }
        .padding(.vertical, DailyArcSpacing.md)
        .padding(.horizontal, DailyArcSpacing.md)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color(hex: "#E8ECF1")!)
        )
        // Neumorphic raised shadow on the background shape
        .compositingGroup()
        .shadow(color: Color.white.opacity(0.8), radius: 12, x: -6, y: -6)
        .shadow(color: Color(hex: "#A3B1C6")!.opacity(0.6), radius: 12, x: 6, y: 6)
        .disclaimerAlert(
            showDisclaimer: $showDisclaimer,
            moodDisclaimerShown: $moodDisclaimerShown,
            pendingScore: $pendingScore,
            onSelect: onSelect
        )
    }

    @ViewBuilder
    private var tactileHeader: some View {
        if selectedScore == 0 {
            Text("How are you feeling?")
                .typography(.callout)
                .foregroundStyle(Color(hex: "#64748B")!)
        } else {
            let selectedMood = moods.first(where: { $0.score == selectedScore })
            if let mood = selectedMood {
                Text("Feeling \(mood.label.lowercased())!")
                    .typography(.callout)
                    .foregroundStyle(Color(hex: "#64748B")!)
            }
        }
    }

    private func tactileMoodButton(_ mood: (score: Int, emoji: String, label: String)) -> some View {
        let isSelected = selectedScore == mood.score

        return Button {
            HapticManager.moodSelection()
            if !moodDisclaimerShown {
                pendingScore = mood.score
                showDisclaimer = true
            } else {
                onSelect(mood.score)
            }
        } label: {
            Text(mood.emoji)
                .font(.system(size: 24))
                .frame(width: 52, height: 52)
                .background(
                    Circle()
                        .fill(
                            isSelected
                                ? LinearGradient(
                                    colors: [
                                        Color(hex: "#6366F1")!.opacity(0.12),
                                        Color(hex: "#EC4899")!.opacity(0.10)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                                : LinearGradient(
                                    colors: [Color(hex: "#E8ECF1")!],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                        )
                        // Neumorphic shadow: raised when unselected, pressed/inset when selected
                        .shadow(
                            color: isSelected ? Color.clear : Color.white.opacity(0.7),
                            radius: isSelected ? 0 : 6,
                            x: isSelected ? 0 : -3,
                            y: isSelected ? 0 : -3
                        )
                        .shadow(
                            color: isSelected ? Color.clear : Color(hex: "#A3B1C6")!.opacity(0.5),
                            radius: isSelected ? 0 : 6,
                            x: isSelected ? 0 : 3,
                            y: isSelected ? 0 : 3
                        )
                )
                // Convincing inner shadow for pressed/selected state
                .overlay(
                    Group {
                        if isSelected {
                            // Dark inner shadow from top-left (concave depth)
                            Circle()
                                .stroke(Color(hex: "#A3B1C6")!.opacity(0.4), lineWidth: 4)
                                .blur(radius: 4)
                                .offset(x: 2, y: 2)
                                .mask(
                                    Circle()
                                        .fill(
                                            LinearGradient(
                                                colors: [Color.black, Color.clear],
                                                startPoint: .topLeading,
                                                endPoint: .bottomTrailing
                                            )
                                        )
                                )
                            // Light inner shadow from bottom-right (rim highlight)
                            Circle()
                                .stroke(Color.white.opacity(0.6), lineWidth: 4)
                                .blur(radius: 4)
                                .offset(x: -2, y: -2)
                                .mask(
                                    Circle()
                                        .fill(
                                            LinearGradient(
                                                colors: [Color.clear, Color.black],
                                                startPoint: .topLeading,
                                                endPoint: .bottomTrailing
                                            )
                                        )
                                )
                        }
                    }
                )
                .contentShape(Circle())
                .scaleEffect(isSelected ? 1.1 : 1.0)
                .animation(.spring(response: 0.3, dampingFraction: 0.6), value: selectedScore)
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Mood: \(mood.label.lowercased()), \(mood.score) of 5")
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }

    // MARK: - Command Container (Sci-Fi Panel)

    private var commandContainer: some View {
        VStack(spacing: DailyArcSpacing.md) {
            commandHeader

            HStack(spacing: DailyArcSpacing.lg) {
                ForEach(moods, id: \.score) { mood in
                    commandMoodButton(mood)
                }
            }

            // Status readout below selection
            if selectedScore > 0 {
                commandStatusReadout
            }
        }
        .padding(.vertical, DailyArcSpacing.md)
        .padding(.horizontal, DailyArcSpacing.md)
        .background(CommandTheme.panel)
        .clipShape(RoundedRectangle(cornerRadius: 4))
        .overlay(
            RoundedRectangle(cornerRadius: 4)
                .stroke(CommandTheme.indigo.opacity(0.12), lineWidth: 1)
        )
        // Left accent bar
        .overlay(alignment: .leading) {
            Rectangle()
                .fill(CommandTheme.indigo.opacity(0.5))
                .frame(width: 3)
        }
        // Grid overlay feel
        .themedGridOverlay(theme)
        .themedGlow(theme, color: CommandTheme.cyan, radius: 15)
        .disclaimerAlert(
            showDisclaimer: $showDisclaimer,
            moodDisclaimerShown: $moodDisclaimerShown,
            pendingScore: $pendingScore,
            onSelect: onSelect
        )
    }

    @ViewBuilder
    private var commandHeader: some View {
        if selectedScore == 0 {
            Text("> HOW YOU'RE FEELING")
                .font(.system(size: 10, weight: .semibold, design: .monospaced))
                .foregroundStyle(CommandTheme.cyan)
                .tracking(1.5)
                .frame(maxWidth: .infinity, alignment: .leading)
        } else {
            Text("> HOW YOU'RE FEELING: LOGGED")
                .font(.system(size: 10, weight: .semibold, design: .monospaced))
                .foregroundStyle(CommandTheme.cyan)
                .tracking(1.5)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private func commandMoodButton(_ mood: (score: Int, emoji: String, label: String)) -> some View {
        let isSelected = selectedScore == mood.score

        return Button {
            HapticManager.moodSelection()
            if !moodDisclaimerShown {
                pendingScore = mood.score
                showDisclaimer = true
            } else {
                onSelect(mood.score)
            }
        } label: {
            Text(mood.emoji)
                .font(.system(size: 44))
                .frame(width: 60, height: 60)
                .background(
                    Circle()
                        .fill(isSelected ? CommandTheme.cyan.opacity(0.15) : Color.clear)
                )
                .overlay(
                    Circle()
                        .stroke(
                            isSelected ? CommandTheme.cyan : Color.white.opacity(0.15),
                            lineWidth: 2
                        )
                )
                .shadow(color: isSelected ? CommandTheme.glowCyan : .clear, radius: isSelected ? 12 : 0)
                .scaleEffect(isSelected ? 1.1 : 1.0)
                .animation(.spring(response: 0.3, dampingFraction: 0.6), value: selectedScore)
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Mood: \(mood.label.lowercased()), \(mood.score) of 5")
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }

    @ViewBuilder
    private var commandStatusReadout: some View {
        let selectedMood = moods.first(where: { $0.score == selectedScore })
        if let mood = selectedMood {
            let statusText: String = {
                switch mood.score {
                case 1: return "TOUGH DAY"
                case 2: return "HANGING IN THERE"
                case 3: return "HOLDING STEADY"
                case 4: return "DOING WELL"
                case 5: return "FEELING GREAT"
                default: return "STATUS: UNKNOWN"
                }
            }()

            Text(statusText)
                .font(.system(size: 10, weight: .bold, design: .monospaced))
                .foregroundStyle(mood.score >= 4 ? CommandTheme.cyan : (mood.score <= 2 ? Color(hex: "#EAB308")! : Color.white.opacity(0.5)))
                .tracking(1.5)
                .shadow(color: mood.score >= 4 ? CommandTheme.glowCyan : .clear, radius: 8)
        }
    }
}

// MARK: - Disclaimer Alert Modifier

private extension View {
    func disclaimerAlert(
        showDisclaimer: Binding<Bool>,
        moodDisclaimerShown: Binding<Bool>,
        pendingScore: Binding<Int?>,
        onSelect: @escaping (Int) -> Void
    ) -> some View {
        self.alert("Just so you know", isPresented: showDisclaimer) {
            Button("Got it") {
                moodDisclaimerShown.wrappedValue = true
                if let score = pendingScore.wrappedValue {
                    onSelect(score)
                }
                pendingScore.wrappedValue = nil
            }
        } message: {
            Text("DailyArc helps you spot patterns, not diagnose conditions. Talk to a professional about health concerns.")
        }
    }
}

#Preview {
    VStack(spacing: 40) {
        MoodCheckInView(selectedScore: 0, onSelect: { _ in })
        MoodCheckInView(selectedScore: 4, onSelect: { _ in })
    }
    .padding()
}
