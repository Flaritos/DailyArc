import SwiftUI

/// 5 emoji mood buttons in an HStack. Selected state shows accent border ring.
/// Emoji scale: 1=Pensive, 2=Confused, 3=Neutral, 4=Slightly smiling, 5=Grinning.
struct MoodCheckInView: View {
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

    var body: some View {
        VStack(spacing: DailyArcSpacing.md) {
            if selectedScore == 0 {
                Text("How are you feeling?")
                    .typography(.callout)
                    .foregroundStyle(DailyArcTokens.textSecondary)
            } else {
                let selectedMood = moods.first(where: { $0.score == selectedScore })
                if let mood = selectedMood {
                    Text("Feeling \(mood.label.lowercased())!")
                        .typography(.callout)
                        .foregroundStyle(DailyArcTokens.textSecondary)
                }
            }

            HStack(spacing: DailyArcSpacing.lg) {
                ForEach(moods, id: \.score) { mood in
                    Button {
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
                                    .fill(selectedScore == mood.score
                                          ? DailyArcTokens.moodSelected.opacity(DailyArcTokens.opacityLight)
                                          : Color.clear)
                            )
                            .overlay(
                                Circle()
                                    .stroke(
                                        selectedScore == mood.score ? DailyArcTokens.moodSelected : Color.clear,
                                        lineWidth: DailyArcTokens.borderThick
                                    )
                            )
                            .scaleEffect(selectedScore == mood.score ? 1.1 : 1.0)
                            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: selectedScore)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("\(mood.label) mood, score \(mood.score) of 5")
                }
            }
        }
        .padding(.vertical, DailyArcSpacing.md)
        .alert("Just so you know", isPresented: $showDisclaimer) {
            Button("Got it") {
                moodDisclaimerShown = true
                if let score = pendingScore {
                    onSelect(score)
                }
                pendingScore = nil
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
