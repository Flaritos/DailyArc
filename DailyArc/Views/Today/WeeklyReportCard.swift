import SwiftUI
import SwiftData

/// Weekly momentum report card shown on Sundays (or if last report > 6 days ago).
/// Displays best habit, most-skipped, mood trajectory, and total completions vs last week.
struct WeeklyReportCard: View {
    @Environment(\.theme) private var theme
    @Environment(\.colorScheme) private var colorScheme

    let habits: [Habit]
    let logs: [HabitLog]
    let moods: [MoodEntry]
    let onDismiss: () -> Void

    private var isCommand: Bool { theme.id == "command" }
    private let calendar = Calendar.current

    // MARK: - Computed Report Data

    private var thisWeekRange: (start: Date, end: Date) {
        let today = calendar.startOfDay(for: Date())
        let weekday = calendar.component(.weekday, from: today)
        // Go back to last Sunday (start of week)
        let daysBack = weekday - 1
        let start = calendar.date(byAdding: .day, value: -daysBack, to: today) ?? today
        return (start, today)
    }

    private var lastWeekRange: (start: Date, end: Date) {
        let thisStart = thisWeekRange.start
        let lastEnd = calendar.date(byAdding: .day, value: -1, to: thisStart) ?? thisStart
        let lastStart = calendar.date(byAdding: .day, value: -6, to: lastEnd) ?? lastEnd
        return (lastStart, lastEnd)
    }

    private func completionsInRange(start: Date, end: Date) -> Int {
        logs.filter { log in
            let logDate = calendar.startOfDay(for: log.date)
            return logDate >= start && logDate <= end && log.count > 0
        }.count
    }

    private func habitCompletionRate(habit: Habit, start: Date, end: Date) -> Double {
        var totalDays = 0
        var completedDays = 0
        var current = start
        let logsByDate = Dictionary(grouping: logs.filter { $0.habitIDDenormalized == habit.id }) {
            calendar.startOfDay(for: $0.date)
        }

        while current <= end {
            if habit.shouldAppear(on: current, calendar: calendar) {
                totalDays += 1
                if let log = logsByDate[current]?.first, log.count >= habit.targetCount {
                    completedDays += 1
                }
            }
            current = calendar.date(byAdding: .day, value: 1, to: current) ?? current.addingTimeInterval(86400)
        }

        return totalDays > 0 ? Double(completedDays) / Double(totalDays) : 0
    }

    private var bestHabit: (name: String, emoji: String, rate: Double)? {
        let rates = habits.compactMap { habit -> (String, String, Double)? in
            let rate = habitCompletionRate(habit: habit, start: thisWeekRange.start, end: thisWeekRange.end)
            return rate > 0 ? (habit.name, habit.emoji, rate) : nil
        }
        return rates.max(by: { $0.2 < $1.2 }).map { (name: $0.0, emoji: $0.1, rate: $0.2) }
    }

    private var mostSkippedHabit: (name: String, emoji: String, rate: Double)? {
        let rates = habits.compactMap { habit -> (String, String, Double)? in
            let rate = habitCompletionRate(habit: habit, start: thisWeekRange.start, end: thisWeekRange.end)
            // Only include habits that were applicable at least once
            var current = thisWeekRange.start
            var appeared = false
            while current <= thisWeekRange.end {
                if habit.shouldAppear(on: current, calendar: calendar) { appeared = true; break }
                current = calendar.date(byAdding: .day, value: 1, to: current) ?? current.addingTimeInterval(86400)
            }
            return appeared ? (habit.name, habit.emoji, rate) : nil
        }
        return rates.min(by: { $0.2 < $1.2 }).map { (name: $0.0, emoji: $0.1, rate: $0.2) }
    }

    private enum MoodTrajectory {
        case up, down, stable
    }

    private var moodTrajectory: (direction: MoodTrajectory, thisWeekAvg: Double, lastWeekAvg: Double) {
        let thisWeekMoods = moods.filter { m in
            let d = calendar.startOfDay(for: m.date)
            return d >= thisWeekRange.start && d <= thisWeekRange.end && m.moodScore > 0
        }
        let lastWeekMoods = moods.filter { m in
            let d = calendar.startOfDay(for: m.date)
            return d >= lastWeekRange.start && d <= lastWeekRange.end && m.moodScore > 0
        }

        let thisAvg = thisWeekMoods.isEmpty ? 0 : Double(thisWeekMoods.map(\.moodScore).reduce(0, +)) / Double(thisWeekMoods.count)
        let lastAvg = lastWeekMoods.isEmpty ? 0 : Double(lastWeekMoods.map(\.moodScore).reduce(0, +)) / Double(lastWeekMoods.count)

        let diff = thisAvg - lastAvg
        let direction: MoodTrajectory
        if diff > 0.3 { direction = .up }
        else if diff < -0.3 { direction = .down }
        else { direction = .stable }

        return (direction, thisAvg, lastAvg)
    }

    private var completionsVsLastWeek: (thisWeek: Int, lastWeek: Int, percentChange: Int) {
        let thisWeek = completionsInRange(start: thisWeekRange.start, end: thisWeekRange.end)
        let lastWeek = completionsInRange(start: lastWeekRange.start, end: lastWeekRange.end)
        let pctChange = lastWeek > 0 ? Int(((Double(thisWeek) - Double(lastWeek)) / Double(lastWeek)) * 100) : 0
        return (thisWeek, lastWeek, pctChange)
    }

    // MARK: - Pre-computed Mood Trend Values (avoid let/switch in ViewBuilder)

    private var commandMoodArrowText: String {
        switch moodTrajectory.direction {
        case .up: return "\u{2191} IMPROVING"
        case .down: return "\u{2193} DECLINING"
        case .stable: return "\u{2192} STABLE"
        }
    }

    private var commandMoodArrowColor: Color {
        switch moodTrajectory.direction {
        case .up: return Color(hex: "#22C55E")!
        case .down: return Color(hex: "#EAB308")!
        case .stable: return CommandTheme.cyan
        }
    }

    private var tactileMoodArrowIcon: String {
        switch moodTrajectory.direction {
        case .up: return "arrow.up.right"
        case .down: return "arrow.down.right"
        case .stable: return "arrow.right"
        }
    }

    private var tactileMoodArrowColor: Color {
        switch moodTrajectory.direction {
        case .up: return Color(hex: "#10B981")!
        case .down: return Color(hex: "#F97316")!
        case .stable: return Color(hex: "#6366F1")!
        }
    }

    private var tactileMoodArrowLabel: String {
        switch moodTrajectory.direction {
        case .up: return "Trending up"
        case .down: return "Trending down"
        case .stable: return "Stable"
        }
    }

    // MARK: - Body

    var body: some View {
        if isCommand {
            commandReport
        } else {
            tactileReport
        }
    }

    // MARK: - Command Theme

    private var commandReport: some View {
        VStack(alignment: .leading, spacing: DailyArcSpacing.md) {
            // Header
            Text("> WEEK IN REVIEW")
                .font(.system(size: 13, weight: .bold, design: .monospaced))
                .foregroundStyle(CommandTheme.cyan)
                .shadow(color: CommandTheme.glowCyan, radius: 8, x: 0, y: 0)
                .tracking(0.5)

            // Stats readout
            VStack(alignment: .leading, spacing: DailyArcSpacing.sm) {
                if let best = bestHabit {
                    commandStatRow(label: "TOP PROTOCOL", value: "\(best.emoji) \(best.name) (\(Int(best.rate * 100))%)")
                }

                if let skipped = mostSkippedHabit, skipped.rate < 1.0 {
                    commandStatRow(label: "NEEDS ATTENTION", value: "\(skipped.emoji) \(skipped.name) (\(Int(skipped.rate * 100))%)")
                }

                // Mood trend
                commandStatRow(
                    label: "MOOD TREND",
                    value: commandMoodArrowText,
                    valueColor: commandMoodArrowColor
                )

                // Completions
                commandStatRow(
                    label: "COMPLETIONS",
                    value: "\(completionsVsLastWeek.thisWeek) (\(completionsVsLastWeek.percentChange >= 0 ? "+" : "")\(completionsVsLastWeek.percentChange)% vs last week)"
                )
            }

            // Dismiss
            Button {
                onDismiss()
            } label: {
                Text("[ GOT IT ]")
                    .font(.system(size: 12, weight: .bold, design: .monospaced))
                    .foregroundStyle(CommandTheme.cyan.opacity(0.7))
                    .tracking(0.5)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, DailyArcSpacing.sm)
            }
        }
        .padding(DailyArcSpacing.lg)
        .background(CommandTheme.panel)
        .clipShape(RoundedRectangle(cornerRadius: 2))
        .overlay(
            RoundedRectangle(cornerRadius: 2)
                .stroke(Color(hex: "#6366F1")!.opacity(0.12), lineWidth: 1)
        )
        .overlay(alignment: .leading) {
            Rectangle()
                .fill(CommandTheme.cyan.opacity(0.5))
                .frame(width: 3)
        }
        .padding(.horizontal, DailyArcSpacing.lg)
    }

    private func commandStatRow(label: String, value: String, valueColor: Color = .white.opacity(0.85)) -> some View {
        HStack(alignment: .top, spacing: DailyArcSpacing.sm) {
            Text(label + ":")
                .font(.system(size: 11, weight: .semibold, design: .monospaced))
                .foregroundStyle(Color.white.opacity(0.4))
                .frame(width: 120, alignment: .leading)

            Text(value)
                .font(.system(size: 11, weight: .medium, design: .monospaced))
                .foregroundStyle(valueColor)
        }
    }

    // MARK: - Tactile Theme

    private var tactileReport: some View {
        VStack(alignment: .leading, spacing: DailyArcSpacing.lg) {
            // Header
            Text("Your Week in Review")
                .font(.system(size: 18, weight: .bold, design: .rounded))
                .foregroundStyle(Color(hex: "#334155")!)

            VStack(spacing: DailyArcSpacing.md) {
                if let best = bestHabit {
                    tactileStatRow(
                        icon: "star.fill",
                        iconColor: Color(hex: "#F97316")!,
                        label: "Best habit",
                        value: "\(best.emoji) \(best.name) \u{2014} \(Int(best.rate * 100))%"
                    )
                }

                if let skipped = mostSkippedHabit, skipped.rate < 1.0 {
                    tactileStatRow(
                        icon: "arrow.uturn.backward",
                        iconColor: Color(hex: "#94A3B8")!,
                        label: "Most skipped",
                        value: "\(skipped.emoji) \(skipped.name) \u{2014} \(Int(skipped.rate * 100))%"
                    )
                }

                // Mood trend
                tactileStatRow(
                    icon: tactileMoodArrowIcon,
                    iconColor: tactileMoodArrowColor,
                    label: "Mood trend",
                    value: tactileMoodArrowLabel
                )

                // Completions
                tactileStatRow(
                    icon: "checkmark.circle.fill",
                    iconColor: Color(hex: "#10B981")!,
                    label: "Completions",
                    value: "\(completionsVsLastWeek.thisWeek) (\(completionsVsLastWeek.percentChange >= 0 ? "+" : "")\(completionsVsLastWeek.percentChange)% vs last week)"
                )
            }

            // Dismiss
            Button {
                onDismiss()
            } label: {
                Text("Got it")
                    .font(.system(size: 15, weight: .semibold, design: .rounded))
                    .foregroundStyle(Color(hex: "#64748B")!)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, DailyArcSpacing.sm)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color(hex: "#E8ECF1")!)
                            .shadow(color: Color.white.opacity(0.7), radius: 6, x: -3, y: -3)
                            .shadow(color: Color(hex: "#A3B1C6")!.opacity(0.4), radius: 6, x: 3, y: 3)
                    )
            }
        }
        .padding(DailyArcSpacing.lg)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(hex: "#E8ECF1")!)
                .shadow(color: Color.white.opacity(0.8), radius: 12, x: -6, y: -6)
                .shadow(color: Color(hex: "#A3B1C6")!.opacity(0.6), radius: 12, x: 6, y: 6)
        )
        .padding(.horizontal, DailyArcSpacing.lg)
    }

    private func tactileStatRow(icon: String, iconColor: Color, label: String, value: String) -> some View {
        HStack(spacing: DailyArcSpacing.md) {
            Image(systemName: icon)
                .font(.system(size: 14))
                .foregroundStyle(iconColor)
                .frame(width: 24)

            VStack(alignment: .leading, spacing: 2) {
                Text(label)
                    .typography(.caption)
                    .foregroundStyle(Color(hex: "#94A3B8")!)

                Text(value)
                    .typography(.bodySmall)
                    .foregroundStyle(Color(hex: "#334155")!)
            }

            Spacer()
        }
    }

    // MARK: - Eligibility Check

    /// Returns true if the weekly report should be shown (Sunday, or > 6 days since last report).
    static func shouldShow(lastReportDateString: String) -> Bool {
        let today = Date()
        let cal = Calendar.current
        let weekday = cal.component(.weekday, from: today)
        let isSunday = weekday == 1

        if lastReportDateString.isEmpty {
            return isSunday
        }

        let formatter = ISO8601DateFormatter()
        guard let lastDate = formatter.date(from: lastReportDateString) else {
            return isSunday
        }

        let daysSinceLast = cal.dateComponents([.day], from: lastDate, to: today).day ?? 0
        return isSunday || daysSinceLast > 6
    }
}
