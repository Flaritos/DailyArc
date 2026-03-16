import SwiftUI
import WidgetKit

// MARK: - Small Streak Widget

/// Displays the user's top streak — emoji (40pt) + streak count (bold 24pt) + "Tap to log" subtitle.
/// Uses a sky-to-indigo gradient at 15% opacity as the background.

// MARK: - Timeline Provider (uncomment in widget target)

// struct SmallStreakProvider: TimelineProvider {
//     func placeholder(in context: Context) -> SmallStreakEntry {
//         SmallStreakEntry(date: Date(), emoji: "🔥", streakCount: 7)
//     }
//
//     func getSnapshot(in context: Context, completion: @escaping (SmallStreakEntry) -> Void) {
//         completion(loadEntry())
//     }
//
//     func getTimeline(in context: Context, completion: @escaping (Timeline<SmallStreakEntry>) -> Void) {
//         let entry = loadEntry()
//         let nextUpdate = Calendar.current.date(byAdding: .minute, value: 30, to: Date())!
//         completion(Timeline(entries: [entry], policy: .after(nextUpdate)))
//     }
//
//     private func loadEntry() -> SmallStreakEntry {
//         guard let defaults = UserDefaults(suiteName: "group.com.dailyarc.shared"),
//               let data = defaults.data(forKey: "widgetPayload") else {
//             return SmallStreakEntry(date: Date(), emoji: "", streakCount: 0)
//         }
//         let decoder = JSONDecoder()
//         decoder.dateDecodingStrategy = .iso8601
//         guard let payload = try? decoder.decode(WidgetPayload.self, from: data) else {
//             return SmallStreakEntry(date: Date(), emoji: "", streakCount: 0)
//         }
//         return SmallStreakEntry(
//             date: Date(),
//             emoji: payload.topStreakEmoji,
//             streakCount: payload.topStreakCount
//         )
//     }
// }

// MARK: - Timeline Entry (uncomment in widget target)

// struct SmallStreakEntry: TimelineEntry {
//     let date: Date
//     let emoji: String
//     let streakCount: Int
// }

// MARK: - Widget View

/// Preview-safe view that can be used in both main app and widget target.
struct SmallStreakWidgetView: View {
    let emoji: String
    let streakCount: Int

    var body: some View {
        ZStack {
            // Sky-to-indigo gradient at 15% opacity
            LinearGradient(
                colors: [
                    Color(red: 0.53, green: 0.81, blue: 0.98).opacity(0.15),
                    Color(red: 0.29, green: 0.0, blue: 0.51).opacity(0.15)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            VStack(spacing: 6) {
                if emoji.isEmpty {
                    Text("--")
                        .font(.system(size: 40))
                } else {
                    Text(emoji)
                        .font(.system(size: 40))
                }

                if streakCount > 0 {
                    Text("\(streakCount)")
                        .font(.system(size: 24, weight: .bold, design: .rounded))
                        .foregroundStyle(.primary)

                    // Mini arc indicator showing streak progress
                    MiniArcView(progress: min(Double(streakCount) / 30.0, 1.0))
                        .frame(width: 40, height: 20)

                    Text("day streak")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                } else {
                    Text("No streak")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(.secondary)
                }

                Text("Tap to log")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }
        }
        .widgetURL(URL(string: "dailyarc://today")!)
    }
}

// MARK: - Mini Arc Shape

/// A small arc shape used in the streak widget to visualize progress.
struct MiniArcView: View {
    let progress: Double

    var body: some View {
        Canvas { context, size in
            let center = CGPoint(x: size.width / 2, y: size.height)
            let radius = min(size.width / 2, size.height) - 2

            // Background arc
            var bgPath = Path()
            bgPath.addArc(center: center, radius: radius, startAngle: .degrees(180), endAngle: .degrees(0), clockwise: false)
            context.stroke(bgPath, with: .color(.gray.opacity(0.3)), lineWidth: 3)

            // Progress arc
            let endAngle = 180.0 + (progress * 180.0)
            var fgPath = Path()
            fgPath.addArc(center: center, radius: radius, startAngle: .degrees(180), endAngle: .degrees(endAngle), clockwise: false)
            context.stroke(fgPath, with: .linearGradient(
                Gradient(colors: [.blue, .purple]),
                startPoint: CGPoint(x: 0, y: size.height),
                endPoint: CGPoint(x: size.width, y: size.height)
            ), lineWidth: 3)
        }
    }
}

// MARK: - Widget Configuration (uncomment in widget target)

// struct SmallStreakWidget: Widget {
//     let kind: String = "SmallStreakWidget"
//
//     var body: some WidgetConfiguration {
//         StaticConfiguration(kind: kind, provider: SmallStreakProvider()) { entry in
//             SmallStreakWidgetView(emoji: entry.emoji, streakCount: entry.streakCount)
//                 .containerBackground(.fill.tertiary, for: .widget)
//         }
//         .configurationDisplayName("Streak")
//         .description("Your top habit streak at a glance.")
//         .supportedFamilies([.systemSmall])
//     }
// }

// MARK: - Preview

#Preview {
    SmallStreakWidgetView(emoji: "\u{1F525}", streakCount: 7)
        .frame(width: 170, height: 170)
        .clipShape(RoundedRectangle(cornerRadius: 20))
}
