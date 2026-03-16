import SwiftUI
import Charts

/// Swift Charts LineMark for last 30 days of mood entries.
/// X-axis: dates. Y-axis: mood 1-5. Line color: accent.
/// Empty state if < 3 entries.
struct MoodTrendView: View {
    let moodEntries: [MoodEntry]

    private var validEntries: [MoodEntry] {
        moodEntries
            .filter { $0.moodScore > 0 }
            .sorted { $0.date < $1.date }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: DailyArcSpacing.sm) {
            Text("Mood Trend")
                .typography(.titleSmall)
                .foregroundStyle(DailyArcTokens.textPrimary)

            if validEntries.count < 3 {
                emptyState
            } else {
                chartView
            }
        }
    }

    // MARK: - Chart

    private var chartView: some View {
        Chart {
            ForEach(validEntries, id: \.id) { entry in
                LineMark(
                    x: .value("Date", entry.date, unit: .day),
                    y: .value("Mood", entry.moodScore)
                )
                .foregroundStyle(DailyArcTokens.accent)
                .interpolationMethod(.catmullRom)
                .lineStyle(StrokeStyle(lineWidth: 2))

                PointMark(
                    x: .value("Date", entry.date, unit: .day),
                    y: .value("Mood", entry.moodScore)
                )
                .foregroundStyle(DailyArcTokens.accent)
                .symbolSize(30)
            }
        }
        .chartYScale(domain: 1...5)
        .chartYAxis {
            AxisMarks(values: [1, 2, 3, 4, 5]) { value in
                AxisGridLine()
                AxisValueLabel {
                    if let score = value.as(Int.self) {
                        let emojis = ["", "\u{1F614}", "\u{1F615}", "\u{1F610}", "\u{1F642}", "\u{1F604}"]
                        Text(emojis[safe: score] ?? "")
                            .font(.caption2)
                    }
                }
            }
        }
        .chartXAxis {
            AxisMarks(values: .stride(by: .day, count: 7)) { _ in
                AxisGridLine()
                AxisValueLabel(format: .dateTime.month(.abbreviated).day())
            }
        }
        .frame(height: 200)
        .accessibilityLabel("Mood trend chart showing \(validEntries.count) entries over the last 30 days")
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: DailyArcSpacing.md) {
            Image(systemName: "chart.line.uptrend.xyaxis")
                .font(.system(size: 32))
                .foregroundStyle(DailyArcTokens.textTertiary)

            Text("Log your mood for 3+ days to see trends")
                .typography(.bodySmall)
                .foregroundStyle(DailyArcTokens.textSecondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 150)
        .background(DailyArcTokens.backgroundSecondary)
        .clipShape(RoundedRectangle(cornerRadius: DailyArcTokens.cornerRadiusLarge))
    }
}
