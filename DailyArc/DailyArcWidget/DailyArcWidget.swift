import WidgetKit
import SwiftUI

// MARK: - Shared Data

struct WidgetData: Codable {
    let completionPercent: Double
    let habits: [WidgetHabit]
    let topStreak: Int
    let topStreakEmoji: String
    let topStreakName: String
    let moodEmoji: String

    struct WidgetHabit: Codable {
        let name: String
        let emoji: String
        let completed: Bool
    }

    static func load() -> WidgetData {
        guard let defaults = UserDefaults(suiteName: "group.com.dailyarc.shared"),
              let data = defaults.data(forKey: "widgetPayload"),
              let payload = try? JSONDecoder().decode(WidgetData.self, from: data) else {
            return WidgetData(completionPercent: 0, habits: [], topStreak: 0, topStreakEmoji: "\u{1F3C3}", topStreakName: "Exercise", moodEmoji: "")
        }
        return payload
    }
}

// MARK: - Timeline

struct DailyArcEntry: TimelineEntry {
    let date: Date
    let data: WidgetData
}

struct DailyArcProvider: TimelineProvider {
    func placeholder(in context: Context) -> DailyArcEntry {
        DailyArcEntry(date: .now, data: .load())
    }

    func getSnapshot(in context: Context, completion: @escaping (DailyArcEntry) -> Void) {
        completion(DailyArcEntry(date: .now, data: .load()))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<DailyArcEntry>) -> Void) {
        let entry = DailyArcEntry(date: .now, data: .load())
        let nextUpdate = Calendar.current.date(byAdding: .minute, value: 30, to: .now)!
        completion(Timeline(entries: [entry], policy: .after(nextUpdate)))
    }
}

// MARK: - Small Streak Widget

struct SmallStreakWidget: Widget {
    let kind = "SmallStreakWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: DailyArcProvider()) { entry in
            SmallStreakView(entry: entry)
                .containerBackground(.fill.tertiary, for: .widget)
        }
        .configurationDisplayName("Streak")
        .description("See your top habit streak at a glance.")
        .supportedFamilies([.systemSmall, .accessoryCircular])
    }
}

struct SmallStreakView: View {
    let entry: DailyArcEntry

    var body: some View {
        VStack(spacing: 8) {
            Text(entry.data.topStreakEmoji)
                .font(.system(size: 36))

            Text("\(entry.data.topStreak)")
                .font(.system(size: 28, weight: .bold, design: .rounded))

            Text("day streak")
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .widgetURL(URL(string: "dailyarc://today"))
    }
}

// MARK: - Medium Today Widget

struct MediumTodayWidget: Widget {
    let kind = "MediumTodayWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: DailyArcProvider()) { entry in
            MediumTodayView(entry: entry)
                .containerBackground(.fill.tertiary, for: .widget)
        }
        .configurationDisplayName("Today")
        .description("See today's habits and mood.")
        .supportedFamilies([.systemMedium])
    }
}

struct MediumTodayView: View {
    let entry: DailyArcEntry

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 6) {
                Text("Today")
                    .font(.headline)

                Text("\(Int(entry.data.completionPercent * 100))%")
                    .font(.system(size: 32, weight: .bold, design: .rounded))

                if !entry.data.moodEmoji.isEmpty {
                    Text(entry.data.moodEmoji)
                        .font(.title2)
                }
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 4) {
                ForEach(entry.data.habits.prefix(4), id: \.name) { habit in
                    HStack(spacing: 4) {
                        Text(habit.emoji)
                            .font(.caption)
                        Text(habit.name)
                            .font(.caption2)
                            .lineLimit(1)
                        Image(systemName: habit.completed ? "checkmark.circle.fill" : "circle")
                            .font(.caption2)
                            .foregroundStyle(habit.completed ? .green : .secondary)
                    }
                }
            }
        }
        .widgetURL(URL(string: "dailyarc://today"))
    }
}

// MARK: - Large Stats Widget

struct LargeStatsWidget: Widget {
    let kind = "LargeStatsWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: DailyArcProvider()) { entry in
            LargeStatsView(entry: entry)
                .containerBackground(.fill.tertiary, for: .widget)
        }
        .configurationDisplayName("Stats")
        .description("Weekly completion and streak highlights.")
        .supportedFamilies([.systemLarge])
    }
}

struct LargeStatsView: View {
    let entry: DailyArcEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Your Arc")
                .font(.headline)

            HStack {
                Text("\(Int(entry.data.completionPercent * 100))%")
                    .font(.system(size: 44, weight: .bold, design: .rounded))

                Spacer()

                VStack(alignment: .trailing) {
                    Text(entry.data.topStreakEmoji)
                        .font(.title)
                    Text("\(entry.data.topStreak) days")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Divider()

            ForEach(entry.data.habits.prefix(5), id: \.name) { habit in
                HStack {
                    Text(habit.emoji)
                    Text(habit.name)
                        .font(.subheadline)
                    Spacer()
                    Image(systemName: habit.completed ? "checkmark.circle.fill" : "circle")
                        .foregroundStyle(habit.completed ? .green : .secondary)
                }
            }

            Spacer()
        }
        .widgetURL(URL(string: "dailyarc://stats"))
    }
}
