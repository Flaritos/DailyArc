import SwiftUI

// NOTE: This file belongs in the Widget extension target, not the main app.
// Uncomment WidgetKit import and Widget conformance after moving to widget target.

// import WidgetKit

// MARK: - Medium Today Widget

/// Shows completion % ring + top 3 habits with checkmarks + mood emoji.
/// Reads WidgetPayload from shared UserDefaults.

// MARK: - Timeline Provider (uncomment in widget target)

// struct MediumTodayProvider: TimelineProvider {
//     func placeholder(in context: Context) -> MediumTodayEntry {
//         MediumTodayEntry(
//             date: Date(),
//             completionPercent: 0.6,
//             habits: [
//                 .init(emoji: "💧", name: "Water", isComplete: true),
//                 .init(emoji: "📖", name: "Read", isComplete: false),
//                 .init(emoji: "🏃", name: "Exercise", isComplete: false),
//             ],
//             moodEmoji: "🙂"
//         )
//     }
//
//     func getSnapshot(in context: Context, completion: @escaping (MediumTodayEntry) -> Void) {
//         completion(loadEntry())
//     }
//
//     func getTimeline(in context: Context, completion: @escaping (Timeline<MediumTodayEntry>) -> Void) {
//         let entry = loadEntry()
//         let nextUpdate = Calendar.current.date(byAdding: .minute, value: 30, to: Date())!
//         completion(Timeline(entries: [entry], policy: .after(nextUpdate)))
//     }
//
//     private func loadEntry() -> MediumTodayEntry {
//         guard let defaults = UserDefaults(suiteName: "group.com.dailyarc.shared"),
//               let data = defaults.data(forKey: "widgetPayload") else {
//             return MediumTodayEntry(date: Date(), completionPercent: 0, habits: [], moodEmoji: "")
//         }
//         let decoder = JSONDecoder()
//         decoder.dateDecodingStrategy = .iso8601
//         guard let payload = try? decoder.decode(WidgetPayload.self, from: data) else {
//             return MediumTodayEntry(date: Date(), completionPercent: 0, habits: [], moodEmoji: "")
//         }
//         let topHabits = Array(payload.habits.prefix(3)).map {
//             MediumTodayEntry.HabitSummary(emoji: $0.emoji, name: $0.name, isComplete: $0.isComplete)
//         }
//         return MediumTodayEntry(
//             date: Date(),
//             completionPercent: payload.completionPercent,
//             habits: topHabits,
//             moodEmoji: payload.moodEmoji
//         )
//     }
// }

// MARK: - Timeline Entry (uncomment in widget target)

// struct MediumTodayEntry: TimelineEntry {
//     let date: Date
//     let completionPercent: Double
//     let habits: [HabitSummary]
//     let moodEmoji: String
//
//     struct HabitSummary {
//         let emoji: String
//         let name: String
//         let isComplete: Bool
//     }
// }

// MARK: - Widget View

/// Preview-safe view for the medium "Today" widget.
struct MediumTodayWidgetView: View {
    let completionPercent: Double
    let habits: [(emoji: String, name: String, isComplete: Bool)]
    let moodEmoji: String

    var body: some View {
        HStack(spacing: 16) {
            // Completion ring
            ZStack {
                Circle()
                    .stroke(Color.gray.opacity(0.2), lineWidth: 6)
                Circle()
                    .trim(from: 0, to: completionPercent)
                    .stroke(
                        LinearGradient(
                            colors: [.blue, .purple],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        style: StrokeStyle(lineWidth: 6, lineCap: .round)
                    )
                    .rotationEffect(.degrees(-90))

                Text("\(Int(completionPercent * 100))%")
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                    .foregroundStyle(.primary)
            }
            .frame(width: 60, height: 60)

            // Habit list (top 3)
            VStack(alignment: .leading, spacing: 4) {
                if habits.isEmpty {
                    Text("No habits today")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(Array(habits.prefix(3).enumerated()), id: \.offset) { _, habit in
                        HStack(spacing: 6) {
                            Text(habit.emoji)
                                .font(.system(size: 14))

                            Text(habit.name)
                                .font(.system(size: 13, weight: .medium))
                                .lineLimit(1)
                                .foregroundStyle(.primary)

                            Spacer()

                            Image(systemName: habit.isComplete ? "checkmark.circle.fill" : "circle")
                                .font(.system(size: 14))
                                .foregroundStyle(habit.isComplete ? .green : .gray.opacity(0.4))
                        }
                    }
                }
            }

            // Mood emoji (if logged)
            if !moodEmoji.isEmpty {
                VStack {
                    Text(moodEmoji)
                        .font(.system(size: 24))
                    Text("mood")
                        .font(.system(size: 10))
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding(.horizontal, 12)
    }
}

// MARK: - Widget Configuration (uncomment in widget target)

// struct MediumTodayWidget: Widget {
//     let kind: String = "MediumTodayWidget"
//
//     var body: some WidgetConfiguration {
//         StaticConfiguration(kind: kind, provider: MediumTodayProvider()) { entry in
//             MediumTodayWidgetView(
//                 completionPercent: entry.completionPercent,
//                 habits: entry.habits.map { ($0.emoji, $0.name, $0.isComplete) },
//                 moodEmoji: entry.moodEmoji
//             )
//             .containerBackground(.fill.tertiary, for: .widget)
//         }
//         .configurationDisplayName("Today")
//         .description("Your daily habit progress at a glance.")
//         .supportedFamilies([.systemMedium])
//     }
// }

// MARK: - Preview

#Preview {
    MediumTodayWidgetView(
        completionPercent: 0.66,
        habits: [
            (emoji: "\u{1F4A7}", name: "Water", isComplete: true),
            (emoji: "\u{1F4D6}", name: "Read", isComplete: false),
            (emoji: "\u{1F3C3}", name: "Exercise", isComplete: true),
        ],
        moodEmoji: "\u{1F642}"
    )
    .frame(width: 340, height: 170)
    .clipShape(RoundedRectangle(cornerRadius: 20))
}
