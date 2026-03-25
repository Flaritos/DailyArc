import SwiftUI
import SwiftData

/// Full-screen view showing every day of the year as a colored pixel based on mood.
/// Grid: 12 rows (months) x 31 columns (days), like GitHub's contribution graph.
struct YearInPixelsView: View {
    @Environment(\.theme) private var theme
    @Environment(\.colorScheme) private var colorScheme

    let moods: [MoodEntry]
    let habits: [Habit]
    let logs: [HabitLog]

    @State private var selectedYear: Int
    @State private var selectedDayInfo: DayInfo?
    @State private var showPopover = false

    private var isCommand: Bool { theme.id == "command" }
    private let calendar = Calendar.current

    struct DayInfo: Identifiable {
        let id = UUID()
        let date: Date
        let moodScore: Int
        let habitCompletions: [(name: String, emoji: String, completed: Bool)]
        let journalExcerpt: String
    }

    init(moods: [MoodEntry], habits: [Habit], logs: [HabitLog]) {
        self.moods = moods
        self.habits = habits
        self.logs = logs
        self._selectedYear = State(initialValue: Calendar.current.component(.year, from: Date()))
    }

    // MARK: - Data

    private var availableYears: [Int] {
        let currentYear = calendar.component(.year, from: Date())
        guard let earliestMood = moods.min(by: { $0.date < $1.date }) else {
            return [currentYear]
        }
        let earliestYear = calendar.component(.year, from: earliestMood.date)
        return Array(earliestYear...currentYear)
    }

    private var moodByDate: [Date: MoodEntry] {
        Dictionary(
            moods.map { (calendar.startOfDay(for: $0.date), $0) },
            uniquingKeysWith: { first, _ in first }
        )
    }

    private var logsByDate: [Date: [HabitLog]] {
        Dictionary(grouping: logs) { calendar.startOfDay(for: $0.date) }
    }

    private func moodForDate(_ date: Date) -> Int {
        moodByDate[calendar.startOfDay(for: date)]?.moodScore ?? 0
    }

    private func dayInfoForDate(_ date: Date) -> DayInfo {
        let normalizedDate = calendar.startOfDay(for: date)
        let mood = moodByDate[normalizedDate]
        let dayLogs = logsByDate[normalizedDate] ?? []

        let habitCompletions = habits.map { habit -> (String, String, Bool) in
            let log = dayLogs.first { $0.habitIDDenormalized == habit.id }
            let completed = (log?.count ?? 0) >= habit.targetCount
            return (habit.name, habit.emoji, completed)
        }

        let excerpt = mood?.notes ?? ""
        let truncated = excerpt.count > 80 ? String(excerpt.prefix(80)) + "..." : excerpt

        return DayInfo(
            date: date,
            moodScore: mood?.moodScore ?? 0,
            habitCompletions: habitCompletions,
            journalExcerpt: truncated
        )
    }

    // MARK: - Colors

    private func colorForMood(_ score: Int) -> Color {
        if isCommand {
            switch score {
            case 0: return Color.white.opacity(0.06)
            case 1: return Color(hex: "#4338CA")!  // deep indigo
            case 2: return Color(hex: "#7C3AED")!  // purple
            case 3: return Color(hex: "#EAB308")!.opacity(0.6) // amber
            case 4: return Color(hex: "#22C55E")!  // green
            case 5: return Color(hex: "#22D3EE")!  // cyan/gold
            default: return Color.white.opacity(0.06)
            }
        } else {
            switch score {
            case 0: return Color(hex: "#CBD5E1")!.opacity(0.4)
            case 1: return Color(hex: "#4338CA")!.opacity(0.7)
            case 2: return Color(hex: "#7C3AED")!.opacity(0.7)
            case 3: return Color(hex: "#D97706")!.opacity(0.6)
            case 4: return Color(hex: "#10B981")!.opacity(0.8)
            case 5: return Color(hex: "#F59E0B")!  // bright gold
            default: return Color(hex: "#CBD5E1")!.opacity(0.4)
            }
        }
    }

    // MARK: - Grid Computation

    private let monthAbbreviations = ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"]

    private func daysInMonth(_ month: Int, year: Int) -> Int {
        let comps = DateComponents(year: year, month: month)
        guard let date = calendar.date(from: comps),
              let range = calendar.range(of: .day, in: .month, for: date) else { return 30 }
        return range.count
    }

    private func dateForCell(month: Int, day: Int) -> Date? {
        let comps = DateComponents(year: selectedYear, month: month, day: day)
        return calendar.date(from: comps)
    }

    // MARK: - Body

    var body: some View {
        ScrollView {
            VStack(spacing: DailyArcSpacing.lg) {
                // Year selector
                yearSelector

                // Month labels + grid
                gridContent

                // Legend
                legendView
            }
            .padding(.vertical, DailyArcSpacing.lg)
        }
        .background(theme.backgroundPrimary)
        .themedGridOverlay(theme)
        .themedScanline(theme)
        .navigationTitle(isCommand ? "> YOUR YEAR" : "Your Year")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(item: $selectedDayInfo) { info in
            dayDetailSheet(info: info)
                .presentationDetents([.medium])
        }
    }

    // MARK: - Year Selector

    private var yearSelector: some View {
        HStack(spacing: DailyArcSpacing.lg) {
            ForEach(availableYears, id: \.self) { year in
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        selectedYear = year
                    }
                } label: {
                    Text(String(year))
                        .font(isCommand
                            ? .system(size: 14, weight: .bold, design: .monospaced)
                            : .system(size: 16, weight: .semibold, design: .rounded))
                        .foregroundStyle(selectedYear == year
                            ? (isCommand ? CommandTheme.cyan : theme.textPrimary)
                            : theme.textTertiary)
                        .padding(.horizontal, DailyArcSpacing.md)
                        .padding(.vertical, DailyArcSpacing.sm)
                        .background(
                            selectedYear == year
                                ? (isCommand
                                    ? AnyShapeStyle(CommandTheme.cyan.opacity(0.1))
                                    : AnyShapeStyle(theme.cardBackground))
                                : AnyShapeStyle(Color.clear)
                        )
                        .clipShape(RoundedRectangle(cornerRadius: isCommand ? 2 : 10))
                        .overlay(
                            selectedYear == year && isCommand
                                ? RoundedRectangle(cornerRadius: 2)
                                    .stroke(CommandTheme.cyan.opacity(0.3), lineWidth: 1)
                                : nil
                        )
                }
            }
        }
        .padding(.horizontal, DailyArcSpacing.lg)
    }

    // MARK: - Grid Content

    private var gridContent: some View {
        let cellSize: CGFloat = isCommand ? 10 : 12
        let cellSpacing: CGFloat = 2
        let labelWidth: CGFloat = 36

        return ScrollView(.horizontal, showsIndicators: false) {
            VStack(alignment: .leading, spacing: cellSpacing) {
                // Day number header row (show every 5th to avoid crowding)
                HStack(spacing: cellSpacing) {
                    Text("")
                        .frame(width: labelWidth) // spacer for month label column

                    ForEach(1...31, id: \.self) { day in
                        if day % 5 == 0 {
                            Text("\(day)")
                                .font(isCommand
                                    ? .system(size: 7, design: .monospaced)
                                    : .system(size: 8))
                                .foregroundStyle(theme.textTertiary)
                                .frame(width: cellSize, height: cellSize)
                        } else {
                            Color.clear
                                .frame(width: cellSize, height: cellSize)
                        }
                    }
                }

                // Month rows (Jan-Dec)
                ForEach(1...12, id: \.self) { month in
                    HStack(spacing: cellSpacing) {
                        // Month label
                        Text(isCommand
                            ? monthAbbreviations[month - 1].uppercased()
                            : monthAbbreviations[month - 1])
                            .font(isCommand
                                ? .system(size: 9, weight: .semibold, design: .monospaced)
                                : .system(size: 10, weight: .medium))
                            .foregroundStyle(isCommand ? CommandTheme.cyan.opacity(0.7) : theme.textSecondary)
                            .frame(width: labelWidth, alignment: .trailing)

                        // Day cells (1-31)
                        let maxDays = daysInMonth(month, year: selectedYear)
                        ForEach(1...31, id: \.self) { day in
                            if day <= maxDays, let date = dateForCell(month: month, day: day) {
                                let today = calendar.startOfDay(for: Date())
                                let cellDate = calendar.startOfDay(for: date)

                                if cellDate > today {
                                    RoundedRectangle(cornerRadius: isCommand ? 1 : 2)
                                        .fill(Color.clear)
                                        .frame(width: cellSize, height: cellSize)
                                } else {
                                    cellView(mood: moodForDate(date), cellSize: cellSize, date: date)
                                }
                            } else {
                                Color.clear
                                    .frame(width: cellSize, height: cellSize)
                            }
                        }
                    }
                }
            }
            .padding(DailyArcSpacing.md)
            .background(
                RoundedRectangle(cornerRadius: isCommand ? 4 : 12)
                    .fill(isCommand
                        ? Color.white.opacity(0.03)
                        : theme.cardBackground.opacity(0.6))
            )
            .padding(.horizontal, DailyArcSpacing.lg)
        }
    }

    private func cellView(mood: Int, cellSize: CGFloat, date: Date) -> some View {
        let color = colorForMood(mood)

        return Button {
            selectedDayInfo = dayInfoForDate(date)
        } label: {
            RoundedRectangle(cornerRadius: isCommand ? 1 : 2)
                .fill(color)
                .frame(width: cellSize, height: cellSize)
                .shadow(
                    color: (isCommand && mood >= 4) ? color.opacity(0.5) : .clear,
                    radius: (isCommand && mood >= 4) ? 3 : 0,
                    x: 0, y: 0
                )
                .overlay(
                    !isCommand && mood > 0
                        ? RoundedRectangle(cornerRadius: 2)
                            .shadow(color: Color.white.opacity(0.3), radius: 1, x: -0.5, y: -0.5)
                            .clipShape(RoundedRectangle(cornerRadius: 2))
                        : nil
                )
        }
        .buttonStyle(.plain)
    }

    // MARK: - Legend

    private var legendView: some View {
        VStack(spacing: DailyArcSpacing.sm) {
            Text(isCommand ? "> LEGEND" : "Legend")
                .font(isCommand
                    ? .system(size: 11, weight: .semibold, design: .monospaced)
                    : .system(size: 13, weight: .semibold, design: .rounded))
                .foregroundStyle(isCommand ? CommandTheme.cyan.opacity(0.6) : theme.textSecondary)

            HStack(spacing: DailyArcSpacing.md) {
                ForEach([0, 1, 2, 3, 4, 5], id: \.self) { score in
                    HStack(spacing: 4) {
                        RoundedRectangle(cornerRadius: isCommand ? 1 : 2)
                            .fill(colorForMood(score))
                            .frame(width: 12, height: 12)

                        Text(score == 0 ? (isCommand ? "N/A" : "No data") : "\(score)")
                            .font(isCommand
                                ? .system(size: 9, weight: .medium, design: .monospaced)
                                : .system(size: 10, weight: .medium))
                            .foregroundStyle(theme.textTertiary)
                    }
                }
            }
        }
        .padding(.horizontal, DailyArcSpacing.lg)
    }

    // MARK: - Day Detail Sheet

    private func dayDetailSheet(info: DayInfo) -> some View {
        VStack(alignment: .leading, spacing: DailyArcSpacing.lg) {
            if isCommand {
                commandDayDetail(info: info)
            } else {
                tactileDayDetail(info: info)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(DailyArcSpacing.xl)
        .background(isCommand ? Color.black : Color(hex: "#E8ECF1")!)
    }

    private func commandDayDetail(info: DayInfo) -> some View {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy.MM.dd"
        let dateStr = formatter.string(from: info.date)

        return VStack(alignment: .leading, spacing: DailyArcSpacing.md) {
            Text("> DATA READOUT // \(dateStr)")
                .font(.system(size: 13, weight: .bold, design: .monospaced))
                .foregroundStyle(CommandTheme.cyan)
                .shadow(color: CommandTheme.glowCyan, radius: 8, x: 0, y: 0)

            if info.moodScore > 0 {
                Text("> MOOD LEVEL: \(info.moodScore)/5")
                    .font(.system(size: 12, weight: .medium, design: .monospaced))
                    .foregroundStyle(Color.white.opacity(0.85))
            } else {
                Text("> MOOD: NO DATA")
                    .font(.system(size: 12, weight: .medium, design: .monospaced))
                    .foregroundStyle(Color.white.opacity(0.4))
            }

            if !info.habitCompletions.isEmpty {
                Text("> PROTOCOLS:")
                    .font(.system(size: 11, weight: .semibold, design: .monospaced))
                    .foregroundStyle(Color.white.opacity(0.5))

                ForEach(info.habitCompletions, id: \.name) { habit in
                    Text(">   \(habit.emoji) \(habit.name.uppercased()) ... [\(habit.completed ? "COMPLETE" : "MISSED")]")
                        .font(.system(size: 11, weight: .medium, design: .monospaced))
                        .foregroundStyle(habit.completed ? Color(hex: "#22C55E")! : Color(hex: "#EAB308")!)
                }
            }

            if !info.journalExcerpt.isEmpty {
                Text("> NOTES: \(info.journalExcerpt)")
                    .font(.system(size: 11, weight: .medium, design: .monospaced))
                    .foregroundStyle(Color.white.opacity(0.6))
            }
        }
    }

    private func tactileDayDetail(info: DayInfo) -> some View {
        let formatter = DateFormatter()
        formatter.dateStyle = .long

        return VStack(alignment: .leading, spacing: DailyArcSpacing.md) {
            Text(formatter.string(from: info.date))
                .font(.system(size: 18, weight: .bold, design: .rounded))
                .foregroundStyle(Color(hex: "#334155")!)

            if info.moodScore > 0 {
                HStack(spacing: DailyArcSpacing.sm) {
                    let moodEntry = MoodEntry(moodScore: info.moodScore)
                    Text(moodEntry.moodEmoji)
                        .font(.title2)
                    Text("Mood: \(info.moodScore)/5")
                        .typography(.bodySmall)
                        .foregroundStyle(Color(hex: "#64748B")!)
                }
            } else {
                Text("No mood logged")
                    .typography(.bodySmall)
                    .foregroundStyle(Color(hex: "#94A3B8")!)
            }

            if !info.habitCompletions.isEmpty {
                VStack(alignment: .leading, spacing: DailyArcSpacing.xs) {
                    ForEach(info.habitCompletions, id: \.name) { habit in
                        HStack(spacing: DailyArcSpacing.sm) {
                            Text(habit.emoji)
                            Text(habit.name)
                                .typography(.bodySmall)
                                .foregroundStyle(Color(hex: "#334155")!)
                            Spacer()
                            Image(systemName: habit.completed ? "checkmark.circle.fill" : "circle")
                                .foregroundStyle(habit.completed ? Color(hex: "#10B981")! : Color(hex: "#CBD5E1")!)
                        }
                    }
                }
            }

            if !info.journalExcerpt.isEmpty {
                Text(info.journalExcerpt)
                    .typography(.bodySmall)
                    .foregroundStyle(Color(hex: "#64748B")!)
                    .italic()
                    .padding(DailyArcSpacing.md)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color(hex: "#E8ECF1")!)
                            .shadow(color: Color.white.opacity(0.7), radius: 6, x: -3, y: -3)
                            .shadow(color: Color(hex: "#A3B1C6")!.opacity(0.4), radius: 6, x: 3, y: 3)
                    )
            }
        }
    }
}
