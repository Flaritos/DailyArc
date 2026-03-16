import SwiftUI

// NOTE: This file belongs in the Widget extension target, not the main app.
// Uncomment WidgetKit import and Widget conformance after moving to widget target.

// import WidgetKit

// MARK: - Large Stats Widget

/// Shows weekly completion %, 7-day mini heat map (colored squares), and streak highlights.
/// Reads WidgetPayload from shared UserDefaults (group.com.dailyarc.shared).

// MARK: - Timeline Provider (uncomment in widget target)

// struct LargeStatsProvider: TimelineProvider {
//     func placeholder(in context: Context) -> LargeStatsEntry {
//         LargeStatsEntry(
//             date: Date(),
//             weeklyCompletionPercent: 0.72,
//             dailyCompletions: [0.8, 1.0, 0.6, 0.4, 1.0, 0.0, 0.5],
//             topStreaks: [
//                 .init(emoji: "💧", name: "Water", count: 14),
//                 .init(emoji: "📖", name: "Read", count: 7),
//             ]
//         )
//     }
//
//     func getSnapshot(in context: Context, completion: @escaping (LargeStatsEntry) -> Void) {
//         completion(loadEntry())
//     }
//
//     func getTimeline(in context: Context, completion: @escaping (Timeline<LargeStatsEntry>) -> Void) {
//         let entry = loadEntry()
//         let nextUpdate = Calendar.current.date(byAdding: .hour, value: 1, to: Date())!
//         completion(Timeline(entries: [entry], policy: .after(nextUpdate)))
//     }
//
//     private func loadEntry() -> LargeStatsEntry {
//         guard let defaults = UserDefaults(suiteName: "group.com.dailyarc.shared"),
//               let data = defaults.data(forKey: "widgetPayload") else {
//             return LargeStatsEntry(date: Date(), weeklyCompletionPercent: 0, dailyCompletions: Array(repeating: 0, count: 7), topStreaks: [])
//         }
//         let decoder = JSONDecoder()
//         decoder.dateDecodingStrategy = .iso8601
//         guard let payload = try? decoder.decode(WidgetPayload.self, from: data) else {
//             return LargeStatsEntry(date: Date(), weeklyCompletionPercent: 0, dailyCompletions: Array(repeating: 0, count: 7), topStreaks: [])
//         }
//         // For now, use today's completion as the last day in the 7-day array
//         // A full implementation would store 7 days of data in the payload
//         var dailyCompletions = Array(repeating: 0.0, count: 7)
//         dailyCompletions[6] = payload.completionPercent
//         let streaks: [LargeStatsEntry.StreakHighlight] = payload.topStreakCount > 0
//             ? [.init(emoji: payload.topStreakEmoji, name: "", count: payload.topStreakCount)]
//             : []
//         return LargeStatsEntry(
//             date: Date(),
//             weeklyCompletionPercent: payload.completionPercent,
//             dailyCompletions: dailyCompletions,
//             topStreaks: streaks
//         )
//     }
// }

// MARK: - Timeline Entry (uncomment in widget target)

// struct LargeStatsEntry: TimelineEntry {
//     let date: Date
//     let weeklyCompletionPercent: Double
//     let dailyCompletions: [Double]  // 7 values, Mon-Sun, each 0.0-1.0
//     let topStreaks: [StreakHighlight]
//
//     struct StreakHighlight {
//         let emoji: String
//         let name: String
//         let count: Int
//     }
// }

// MARK: - Widget View

/// Preview-safe view for the large stats widget.
struct LargeStatsWidgetView: View {
    let weeklyCompletionPercent: Double
    let dailyCompletions: [Double] // 7 values, Mon-Sun, each 0.0-1.0
    let topStreaks: [(emoji: String, name: String, count: Int)]

    private let dayLabels = ["M", "T", "W", "T", "F", "S", "S"]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header: Weekly completion %
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("This Week")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(.secondary)
                        .textCase(.uppercase)

                    Text("\(Int(weeklyCompletionPercent * 100))%")
                        .font(.system(size: 34, weight: .bold, design: .rounded))
                        .foregroundStyle(.primary)
                }

                Spacer()

                // Completion ring
                ZStack {
                    Circle()
                        .stroke(Color.gray.opacity(0.2), lineWidth: 5)
                    Circle()
                        .trim(from: 0, to: weeklyCompletionPercent)
                        .stroke(
                            LinearGradient(
                                colors: [.blue, .purple],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            style: StrokeStyle(lineWidth: 5, lineCap: .round)
                        )
                        .rotationEffect(.degrees(-90))
                }
                .frame(width: 44, height: 44)
            }

            Divider()
                .opacity(0.5)

            // 7-day mini heat map
            VStack(alignment: .leading, spacing: 6) {
                Text("7-Day Activity")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(.secondary)

                HStack(spacing: 6) {
                    ForEach(0..<7, id: \.self) { index in
                        VStack(spacing: 4) {
                            RoundedRectangle(cornerRadius: 4)
                                .fill(heatMapColor(for: completionValue(at: index)))
                                .frame(height: 28)

                            Text(dayLabels[index])
                                .font(.system(size: 9, weight: .medium))
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }

            Divider()
                .opacity(0.5)

            // Streak highlights
            VStack(alignment: .leading, spacing: 6) {
                Text("Streak Highlights")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(.secondary)

                if topStreaks.isEmpty {
                    Text("Complete habits to start a streak")
                        .font(.system(size: 13))
                        .foregroundStyle(.tertiary)
                } else {
                    ForEach(Array(topStreaks.prefix(3).enumerated()), id: \.offset) { _, streak in
                        HStack(spacing: 8) {
                            Text(streak.emoji)
                                .font(.system(size: 18))

                            if !streak.name.isEmpty {
                                Text(streak.name)
                                    .font(.system(size: 13, weight: .medium))
                                    .lineLimit(1)
                                    .foregroundStyle(.primary)
                            }

                            Spacer()

                            Text("\(streak.count) days")
                                .font(.system(size: 13, weight: .semibold, design: .rounded))
                                .foregroundStyle(.purple)
                        }
                    }
                }
            }

            Spacer(minLength: 0)
        }
        .padding(14)
        .widgetURL(URL(string: "dailyarc://stats")!)
    }

    // MARK: - Helpers

    private func completionValue(at index: Int) -> Double {
        guard index < dailyCompletions.count else { return 0 }
        return dailyCompletions[index]
    }

    /// Returns a color ranging from gray (no activity) through blue to purple (full completion).
    private func heatMapColor(for value: Double) -> Color {
        if value <= 0 {
            return Color.gray.opacity(0.15)
        } else if value < 0.5 {
            return Color.blue.opacity(0.3 + value * 0.4)
        } else if value < 1.0 {
            return Color.purple.opacity(0.4 + value * 0.4)
        } else {
            return Color.purple.opacity(0.9)
        }
    }
}

// MARK: - Widget Configuration (uncomment in widget target)

// struct LargeStatsWidget: Widget {
//     let kind: String = "LargeStatsWidget"
//
//     var body: some WidgetConfiguration {
//         StaticConfiguration(kind: kind, provider: LargeStatsProvider()) { entry in
//             LargeStatsWidgetView(
//                 weeklyCompletionPercent: entry.weeklyCompletionPercent,
//                 dailyCompletions: entry.dailyCompletions,
//                 topStreaks: entry.topStreaks.map { ($0.emoji, $0.name, $0.count) }
//             )
//             .containerBackground(.fill.tertiary, for: .widget)
//         }
//         .configurationDisplayName("Weekly Stats")
//         .description("Your weekly habit completion and streak highlights.")
//         .supportedFamilies([.systemLarge])
//     }
// }

// MARK: - Preview

#Preview {
    LargeStatsWidgetView(
        weeklyCompletionPercent: 0.72,
        dailyCompletions: [0.8, 1.0, 0.6, 0.4, 1.0, 0.0, 0.5],
        topStreaks: [
            (emoji: "\u{1F4A7}", name: "Water", count: 14),
            (emoji: "\u{1F4D6}", name: "Read", count: 7),
            (emoji: "\u{1F3C3}", name: "Exercise", count: 3),
        ]
    )
    .frame(width: 340, height: 340)
    .clipShape(RoundedRectangle(cornerRadius: 20))
}
