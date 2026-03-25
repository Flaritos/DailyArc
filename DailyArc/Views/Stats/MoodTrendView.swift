import SwiftUI
import Charts

/// Redesigned mood trend chart with gradient area fill, energy overlay,
/// tap-to-inspect interaction, and period toggle (7d / 30d / 90d).
struct MoodTrendView: View {
    let moodEntries: [MoodEntry]

    @Environment(\.theme) private var theme
    @State private var period: Int = 30
    @State private var selectedDate: Date?

    private let moodEmojis = ["\u{1F614}", "\u{1F615}", "\u{1F610}", "\u{1F642}", "\u{1F604}"]
    private let moodLabels = ["Low", "Down", "Okay", "Good", "Great"]

    // MARK: - Filtered Data

    private var filteredEntries: [MoodEntry] {
        let calendar = Calendar.current
        let cutoff = calendar.date(byAdding: .day, value: -period, to: Date()) ?? Date()
        return moodEntries
            .filter { $0.moodScore > 0 && $0.date >= cutoff }
            .sorted { $0.date < $1.date }
    }

    private var hasEnergyData: Bool {
        filteredEntries.contains { $0.energyScore > 0 }
    }

    /// 3-day rolling average for smoother mood trend line
    private var smoothedMoodData: [(date: Date, value: Double)] {
        let entries = filteredEntries
        guard entries.count >= 2 else {
            return entries.map { ($0.date, Double($0.moodScore)) }
        }
        return entries.enumerated().map { i, entry in
            let windowStart = max(0, i - 1)
            let windowEnd = min(entries.count - 1, i + 1)
            let window = entries[windowStart...windowEnd]
            let avg = Double(window.reduce(0) { $0 + $1.moodScore }) / Double(window.count)
            return (entry.date, avg)
        }
    }

    /// 3-day rolling average for smoother energy trend line
    private var smoothedEnergyData: [(date: Date, value: Double)] {
        let entries = filteredEntries.filter { $0.energyScore > 0 }
        guard entries.count >= 2 else {
            return entries.map { ($0.date, Double($0.energyScore)) }
        }
        return entries.enumerated().map { i, entry in
            let windowStart = max(0, i - 1)
            let windowEnd = min(entries.count - 1, i + 1)
            let window = entries[windowStart...windowEnd]
            let avg = Double(window.reduce(0) { $0 + $1.energyScore }) / Double(window.count)
            return (entry.date, avg)
        }
    }

    private var selectedEntry: MoodEntry? {
        guard let selectedDate else { return nil }
        return filteredEntries.min(by: {
            abs($0.date.timeIntervalSince(selectedDate)) < abs($1.date.timeIntervalSince(selectedDate))
        })
    }

    // MARK: - Body

    var body: some View {
        VStack(alignment: .leading, spacing: DailyArcSpacing.md) {
            headerRow
            if filteredEntries.count < 3 {
                emptyState
            } else {
                chartView
                emojiLegend
                if hasEnergyData {
                    legendRow
                }
            }
        }
    }

    // MARK: - Header with Period Picker

    private var headerRow: some View {
        HStack(spacing: DailyArcSpacing.sm) {
            RoundedRectangle(cornerRadius: 1.5)
                .fill(theme.brandGradient)
                .frame(width: 3, height: 20)
            Text(theme.uppercaseHeaders ? "\(theme.headerPrefix)MOOD TREND" : "Mood Trend")
                .typography(.titleSmall)
                .foregroundStyle(theme.textPrimary)
                .fontDesign(theme.displayFontDesign)
            Spacer()
            periodPicker
        }
    }

    private var periodPicker: some View {
        HStack(spacing: 0) {
            ForEach([7, 30, 90], id: \.self) { days in
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        period = days
                        selectedDate = nil
                    }
                } label: {
                    Text("\(days)d")
                        .typography(.caption)
                        .fontDesign(theme.displayFontDesign)
                        .foregroundStyle(period == days ? Color.white : theme.textSecondary)
                        .padding(.horizontal, DailyArcSpacing.sm)
                        .padding(.vertical, DailyArcSpacing.xs)
                        .background {
                            if period == days {
                                Capsule()
                                    .fill(DailyArcTokens.accent)
                            }
                        }
                }
                .buttonStyle(.plain)
            }
        }
        .padding(DailyArcSpacing.xxs)
        .background(
            Capsule()
                .fill(theme.backgroundSecondary)
        )
    }

    // MARK: - Chart

    private var chartView: some View {
        Chart {
            // Area fill under smoothed mood line
            ForEach(Array(smoothedMoodData.enumerated()), id: \.offset) { _, point in
                AreaMark(
                    x: .value("Date", point.date, unit: .day),
                    yStart: .value("Baseline", 1),
                    yEnd: .value("Mood", point.value)
                )
                .foregroundStyle(
                    .linearGradient(
                        colors: [
                            (theme.id == "command" ? CommandTheme.cyan : DailyArcTokens.accent).opacity(0.10),
                            (theme.id == "command" ? CommandTheme.cyan : DailyArcTokens.accent).opacity(0.01)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .interpolationMethod(.monotone)
            }

            // Smoothed mood line (3-day rolling average)
            ForEach(Array(smoothedMoodData.enumerated()), id: \.offset) { _, point in
                LineMark(
                    x: .value("Date", point.date, unit: .day),
                    y: .value("Mood", point.value)
                )
                .foregroundStyle(theme.id == "command" ? CommandTheme.cyan : DailyArcTokens.accent)
                .interpolationMethod(.monotone)
                .lineStyle(StrokeStyle(lineWidth: 2.5))
                .shadow(color: theme.id == "command" ? CommandTheme.glowCyan : .clear, radius: 4)
            }

            // Smoothed energy dashed overlay
            if hasEnergyData {
                ForEach(Array(smoothedEnergyData.enumerated()), id: \.offset) { _, point in
                    LineMark(
                        x: .value("Date", point.date, unit: .day),
                        y: .value("Energy", point.value),
                        series: .value("Series", "Energy")
                    )
                    .foregroundStyle((theme.id == "command" ? CommandTheme.cyan : DailyArcTokens.accent).opacity(0.25))
                    .interpolationMethod(.monotone)
                    .lineStyle(StrokeStyle(lineWidth: 1.5, dash: [6, 4]))
                }
            }

            // Selected point indicator with annotation tooltip
            if let entry = selectedEntry {
                RuleMark(x: .value("Selected", entry.date, unit: .day))
                    .foregroundStyle(theme.textTertiary.opacity(0.5))
                    .lineStyle(StrokeStyle(lineWidth: 1, dash: [3, 3]))

                PointMark(
                    x: .value("Date", entry.date, unit: .day),
                    y: .value("Mood", entry.moodScore)
                )
                .foregroundStyle(theme.id == "command" ? CommandTheme.cyan : DailyArcTokens.accent)
                .symbolSize(50)
                .annotation(position: .top, spacing: 6) {
                    tooltipView(for: entry)
                }
            }
        }
        .chartYScale(domain: 1...5)
        .chartYAxis {
            AxisMarks(values: [1, 2, 3, 4, 5]) { value in
                AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5))
                    .foregroundStyle(theme.separator.opacity(0.5))
                AxisValueLabel {
                    if let score = value.as(Int.self) {
                        Text("\(score)")
                            .font(.caption2)
                            .fontDesign(theme.displayFontDesign)
                            .foregroundStyle(theme.textTertiary)
                    }
                }
            }
        }
        .chartXAxis {
            AxisMarks(values: .stride(by: .day, count: xAxisStride)) { _ in
                AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5))
                    .foregroundStyle(theme.separator.opacity(0.3))
                AxisValueLabel(format: .dateTime.month(.abbreviated).day())
                    .font(.caption2.monospaced())
                    .foregroundStyle(theme.textTertiary)
            }
        }
        .frame(height: 200)
        .chartOverlay { proxy in
            GeometryReader { _ in
                Rectangle()
                    .fill(Color.clear)
                    .contentShape(Rectangle())
                    .gesture(
                        DragGesture(minimumDistance: 0)
                            .onChanged { value in
                                if let date: Date = proxy.value(atX: value.location.x) {
                                    selectedDate = date
                                }
                            }
                            .onEnded { _ in
                                // Keep selection visible until next interaction
                            }
                    )
            }
        }
        .accessibilityLabel(moodChartAccessibilityLabel)
    }

    private var moodChartAccessibilityLabel: String {
        let count = filteredEntries.count
        guard count > 0 else {
            return "Mood trend chart with no data"
        }
        let avgMood = Double(filteredEntries.reduce(0) { $0 + $1.moodScore }) / Double(count)
        let avgLabel = String(format: "%.1f", avgMood)
        return "Mood trend chart showing \(count) entries over \(period) days, average mood \(avgLabel) out of 5"
    }

    private var xAxisStride: Int {
        switch period {
        case 7: return 1
        case 90: return 14
        default: return 7
        }
    }

    // MARK: - Tooltip

    private func tooltipView(for entry: MoodEntry) -> some View {
        VStack(spacing: DailyArcSpacing.xxs) {
            Text(entry.date, format: .dateTime.month(.abbreviated).day())
                .typography(.caption2)
                .foregroundStyle(theme.textSecondary)
            HStack(spacing: DailyArcSpacing.xs) {
                Text(entry.moodEmoji)
                    .font(.caption)
                if entry.energyScore > 0 {
                    Text("\u{26A1}\(entry.energyScore)")
                        .typography(.caption2)
                        .foregroundStyle(theme.textSecondary)
                }
            }
        }
        .padding(.horizontal, DailyArcSpacing.sm)
        .padding(.vertical, DailyArcSpacing.xs)
        .background(
            RoundedRectangle(cornerRadius: theme.cornerRadiusSmall)
                .fill(theme.backgroundTertiary)
                .shadow(color: theme.cardShadowColor, radius: 4, y: 2)
        )
    }

    // MARK: - Emoji Legend

    private var emojiLegend: some View {
        HStack {
            ForEach(0..<5, id: \.self) { index in
                VStack(spacing: DailyArcSpacing.xxs) {
                    Text(moodEmojis[index])
                        .font(.caption)
                    Text("\(index + 1)")
                        .typography(.caption2)
                        .fontDesign(theme.displayFontDesign)
                        .foregroundStyle(theme.textTertiary)
                }
                if index < 4 { Spacer() }
            }
        }
        .padding(.horizontal, DailyArcSpacing.sm)
    }

    // MARK: - Legend Row (when energy is shown)

    private var legendRow: some View {
        HStack(spacing: DailyArcSpacing.lg) {
            HStack(spacing: DailyArcSpacing.xs) {
                RoundedRectangle(cornerRadius: 1)
                    .fill(theme.id == "command" ? CommandTheme.cyan : DailyArcTokens.accent)
                    .frame(width: 16, height: 2)
                Text("Mood")
                    .typography(.caption2)
                    .foregroundStyle(theme.textSecondary)
            }
            HStack(spacing: DailyArcSpacing.xs) {
                StrokeLine()
                    .stroke((theme.id == "command" ? CommandTheme.cyan : DailyArcTokens.accent).opacity(0.4), style: StrokeStyle(lineWidth: 1.5, dash: [5, 3]))
                    .frame(width: 16, height: 2)
                Text("Energy")
                    .typography(.caption2)
                    .foregroundStyle(theme.textSecondary)
            }
            Spacer()
        }
        .padding(.horizontal, DailyArcSpacing.sm)
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: DailyArcSpacing.md) {
            Image(systemName: "chart.line.uptrend.xyaxis")
                .font(.system(size: 32))
                .foregroundStyle(theme.textTertiary)

            Text("Log your mood for 3+ days to see trends")
                .typography(.bodySmall)
                .foregroundStyle(theme.textSecondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 150)
        .background(theme.backgroundSecondary)
        .clipShape(RoundedRectangle(cornerRadius: theme.cornerRadiusLarge))
    }
}

// MARK: - Dashed Line Shape for Legend

private struct StrokeLine: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: 0, y: rect.midY))
        path.addLine(to: CGPoint(x: rect.width, y: rect.midY))
        return path
    }
}
