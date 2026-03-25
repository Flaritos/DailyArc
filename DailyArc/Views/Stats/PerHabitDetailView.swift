import SwiftUI
import SwiftData
import Charts

/// Drill-down from per-habit card. Shows total completions, streaks,
/// monthly bar chart.
struct PerHabitDetailView: View {
    let habit: Habit

    @Environment(\.modelContext) private var modelContext
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.dismiss) private var dismiss
    @Environment(\.theme) private var theme

    @State private var editingHabit: Habit?
    @State private var showArchiveConfirmation = false
    @State private var showDeleteConfirmation = false
    @State private var monthlyData: [(month: Date, count: Int)] = []
    @State private var dailyThisMonthData: [(day: Int, count: Int)] = []
    @State private var totalCompletionCount = 0

    private let calendar = Calendar.current

    var body: some View {
        ScrollView {
            VStack(spacing: DailyArcSpacing.xl) {
                // Header
                headerSection

                // Stat panels
                statPanels

                // This Month daily bar chart
                thisMonthChart

                Divider()
                    .padding(.horizontal, DailyArcSpacing.sm)

                // Last 12 Months bar chart
                monthlyChart

                // Actions
                actionButtons
            }
            .padding(.horizontal, DailyArcSpacing.lg)
            .padding(.vertical, DailyArcSpacing.xl)
        }
        .background(theme.backgroundPrimary)
        .navigationTitle(habit.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("Edit") {
                    editingHabit = habit
                }
            }
        }
        .sheet(item: $editingHabit) { h in
            HabitFormView(mode: .edit(h))
        }
        .alert("Archive Habit?", isPresented: $showArchiveConfirmation) {
            Button("Cancel", role: .cancel) {}
            Button("Archive", role: .destructive) {
                habit.isArchived = true
                try? modelContext.save()
                dismiss()
            }
        } message: {
            Text("This will hide \(habit.emoji) \(habit.name) from your daily list. You can unarchive it later.")
        }
        .alert("Delete Habit?", isPresented: $showDeleteConfirmation) {
            Button("Cancel", role: .cancel) {}
            Button("Delete", role: .destructive) {
                modelContext.delete(habit)
                try? modelContext.save()
                dismiss()
            }
        } message: {
            Text("Delete \(habit.emoji) \(habit.name)? This will permanently delete all log data for this habit.")
        }
        .onAppear { loadData() }
    }

    // MARK: - Sections

    private var headerSection: some View {
        HStack(spacing: DailyArcSpacing.md) {
            Text(habit.emoji)
                .font(.system(size: 48))

            VStack(alignment: .leading, spacing: DailyArcSpacing.xxs) {
                Text(habit.name)
                    .typography(.titleMedium)
                    .fontDesign(theme.displayFontDesign)
                    .foregroundStyle(theme.textPrimary)

                Text(frequencyLabel)
                    .typography(.bodySmall)
                    .foregroundStyle(theme.textSecondary)
            }

            Spacer()

            // Completion ring (larger for detail view)
            completionRing
        }
    }

    private var statPanels: some View {
        VStack(spacing: DailyArcSpacing.md) {
            HStack(spacing: DailyArcSpacing.md) {
                statCard(title: "Total Completions", value: "\(totalCompletionCount)", icon: "checkmark.circle.fill")
                statCard(title: "Current Streak", value: "\(habit.currentStreak) days", icon: "flame.fill", valueColor: DailyArcTokens.streakFire)
            }

            HStack(spacing: DailyArcSpacing.md) {
                statCard(title: "Best Streak", value: "\(habit.bestStreak) days", icon: "trophy.fill", valueColor: DailyArcTokens.textSecondary)
                statCard(title: "Target", value: "\(habit.targetCount)/day", icon: "target")
            }
        }
    }

    private func statCard(title: String, value: String, icon: String, valueColor: Color = DailyArcTokens.textPrimary) -> some View {
        VStack(alignment: .leading, spacing: DailyArcSpacing.sm) {
            HStack(spacing: DailyArcSpacing.xs) {
                Image(systemName: icon)
                    .font(.caption)
                    .foregroundStyle(theme.textTertiary)
                Text(title)
                    .typography(.caption)
                    .foregroundStyle(theme.textSecondary)
            }
            Text(value)
                .typography(.titleSmall)
                .fontDesign(theme.displayFontDesign)
                .foregroundStyle(valueColor)
                .contentTransition(.numericText())
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(DailyArcSpacing.md)
        .background(theme.id == "command" ? CommandTheme.panel : theme.backgroundSecondary)
        .clipShape(RoundedRectangle(cornerRadius: theme.cornerRadiusMedium))
        .overlay(
            theme.id == "command"
                ? RoundedRectangle(cornerRadius: theme.cornerRadiusMedium).stroke(theme.border, lineWidth: DailyArcTokens.borderThin)
                : nil
        )
    }

    private var thisMonthChart: some View {
        let monthName = Date().formatted(.dateTime.month(.wide))
        return VStack(alignment: .leading, spacing: DailyArcSpacing.sm) {
            Text(theme.uppercaseHeaders ? "\(theme.headerPrefix)THIS MONTH" : "This Month")
                .typography(.titleSmall)
                .fontDesign(theme.displayFontDesign)
                .foregroundStyle(theme.textPrimary)

            Text(monthName)
                .typography(.caption)
                .foregroundStyle(theme.textSecondary)

            if dailyThisMonthData.isEmpty {
                Text("No data yet")
                    .typography(.bodySmall)
                    .foregroundStyle(theme.textTertiary)
                    .frame(maxWidth: .infinity, minHeight: 150)
            } else {
                Chart {
                    ForEach(dailyThisMonthData, id: \.day) { item in
                        BarMark(
                            x: .value("Day", item.day),
                            y: .value("Count", max(item.count, 0))
                        )
                        .foregroundStyle(barColor(for: item.count))
                        .cornerRadius(2)
                    }
                }
                .chartXAxis {
                    AxisMarks(values: .automatic(desiredCount: 8)) { value in
                        AxisValueLabel {
                            if let day = value.as(Int.self) {
                                Text("\(day)")
                                    .font(.caption2)
                            }
                        }
                    }
                }
                .chartYScale(domain: 0...max(habit.targetCount, 1))
                .frame(height: 150)
            }
        }
        .padding(DailyArcSpacing.md)
        .background(theme.id == "command" ? CommandTheme.panel : theme.backgroundSecondary)
        .clipShape(RoundedRectangle(cornerRadius: theme.cornerRadiusLarge))
        .overlay(
            theme.id == "command"
                ? RoundedRectangle(cornerRadius: theme.cornerRadiusLarge).stroke(theme.border, lineWidth: DailyArcTokens.borderThin)
                : nil
        )
    }

    private func barColor(for count: Int) -> Color {
        if count <= 0 {
            return Color(hex: "#E5E5EA")!
        } else if count >= habit.targetCount {
            return habit.color(for: colorScheme)
        } else {
            return habit.color(for: colorScheme).opacity(0.5)
        }
    }

    private var monthlyChart: some View {
        VStack(alignment: .leading, spacing: DailyArcSpacing.sm) {
            Text(theme.uppercaseHeaders ? "\(theme.headerPrefix)LAST 12 MONTHS" : "Last 12 Months")
                .typography(.titleSmall)
                .fontDesign(theme.displayFontDesign)
                .foregroundStyle(theme.textPrimary)

            if monthlyData.isEmpty {
                Text("No data yet")
                    .typography(.bodySmall)
                    .foregroundStyle(theme.textTertiary)
                    .frame(maxWidth: .infinity, minHeight: 150)
            } else {
                Chart {
                    ForEach(monthlyData, id: \.month) { item in
                        BarMark(
                            x: .value("Month", item.month, unit: .month),
                            y: .value("Completions", item.count)
                        )
                        .foregroundStyle(habit.color(for: colorScheme))
                        .cornerRadius(4)
                    }
                }
                .chartXAxis {
                    AxisMarks(values: .stride(by: .month)) { _ in
                        AxisValueLabel(format: .dateTime.month(.narrow))
                    }
                }
                .frame(height: 180)
            }
        }
        .padding(DailyArcSpacing.md)
        .background(theme.id == "command" ? CommandTheme.panel : theme.backgroundSecondary)
        .clipShape(RoundedRectangle(cornerRadius: theme.cornerRadiusLarge))
        .overlay(
            theme.id == "command"
                ? RoundedRectangle(cornerRadius: theme.cornerRadiusLarge).stroke(theme.border, lineWidth: DailyArcTokens.borderThin)
                : nil
        )
    }

    private var actionButtons: some View {
        VStack(spacing: DailyArcSpacing.md) {
            Button {
                showArchiveConfirmation = true
            } label: {
                HStack {
                    Image(systemName: "archivebox")
                    Text("Archive Habit")
                }
                .typography(.bodyLarge)
                .frame(maxWidth: .infinity, minHeight: 50)
                .background(theme.warning.opacity(0.15))
                .foregroundStyle(theme.warning)
                .clipShape(RoundedRectangle(cornerRadius: theme.cornerRadiusMedium))
            }

            Button {
                showDeleteConfirmation = true
            } label: {
                HStack {
                    Image(systemName: "trash")
                    Text("Delete Habit")
                }
                .typography(.bodyLarge)
                .frame(maxWidth: .infinity, minHeight: 50)
                .background(theme.error.opacity(0.15))
                .foregroundStyle(theme.error)
                .clipShape(RoundedRectangle(cornerRadius: theme.cornerRadiusMedium))
            }
        }
    }

    // MARK: - Completion Ring (60pt for detail)

    private var completionRing: some View {
        let rate = computeRate()
        return ZStack {
            Circle()
                .stroke(Color(hex: "#E5E5EA")!, lineWidth: 4)
                .frame(width: 60, height: 60)
            Circle()
                .trim(from: 0, to: rate)
                .stroke(
                    habit.color(for: colorScheme),
                    style: StrokeStyle(lineWidth: 4, lineCap: .round)
                )
                .frame(width: 60, height: 60)
                .rotationEffect(.degrees(-90))
                .animation(.easeInOut(duration: 0.6), value: rate)
            Text("\(Int(rate * 100))%")
                .typography(.caption)
                .fontWeight(.bold)
                .foregroundStyle(theme.textPrimary)
                .contentTransition(.numericText())
        }
    }

    // MARK: - Helpers

    private var frequencyLabel: String {
        switch habit.frequency {
        case .daily: return "Daily"
        case .weekdays: return "Weekdays"
        case .weekends: return "Weekends"
        case .custom: return "Custom schedule"
        }
    }

    private func computeRate() -> Double {
        let logs = habit.logs
        let startDate = calendar.startOfDay(for: habit.startDate)
        let today = calendar.startOfDay(for: Date())
        var totalDays = 0
        var completedDays = 0
        var current = startDate
        let logsByDate = Dictionary(grouping: logs) { calendar.startOfDay(for: $0.date) }

        while current <= today {
            if habit.shouldAppear(on: current, calendar: calendar) {
                totalDays += 1
                if let log = logsByDate[current]?.first, log.count >= habit.targetCount {
                    completedDays += 1
                }
            }
            current = calendar.date(byAdding: .day, value: 1, to: current)
                ?? current.addingTimeInterval(86400)
        }
        return totalDays > 0 ? Double(completedDays) / Double(totalDays) : 0
    }

    private func loadData() {
        // Total completions
        totalCompletionCount = habit.logs.filter { $0.count >= habit.targetCount }.count

        // Daily completions for current month
        let now = Date()
        let currentMonthComps = calendar.dateComponents([.year, .month], from: now)
        let daysInMonth = calendar.range(of: .day, in: .month, for: now)?.count ?? 31
        let todayDay = calendar.component(.day, from: now)

        let logsByDate = Dictionary(grouping: habit.logs) { calendar.startOfDay(for: $0.date) }

        var daily: [(day: Int, count: Int)] = []
        for day in 1...daysInMonth {
            var comps = currentMonthComps
            comps.day = day
            if let dayDate = calendar.date(from: comps) {
                let dayStart = calendar.startOfDay(for: dayDate)
                let count = logsByDate[dayStart]?.first?.count ?? 0
                // Only show data up to today
                if day <= todayDay {
                    daily.append((day: day, count: count))
                } else {
                    daily.append((day: day, count: 0))
                }
            }
        }
        dailyThisMonthData = daily

        // Monthly completions (last 12 months)
        let completedLogs = habit.logs.filter { $0.count >= habit.targetCount }
        let grouped = Dictionary(grouping: completedLogs) { log -> Date in
            let comps = calendar.dateComponents([.year, .month], from: log.date)
            return calendar.date(from: comps) ?? log.date
        }

        var result: [(month: Date, count: Int)] = []
        for i in (0..<12).reversed() {
            if let monthDate = calendar.date(byAdding: .month, value: -i, to: now) {
                let comps = calendar.dateComponents([.year, .month], from: monthDate)
                let key = calendar.date(from: comps) ?? monthDate
                result.append((month: key, count: grouped[key]?.count ?? 0))
            }
        }
        monthlyData = result
    }
}
