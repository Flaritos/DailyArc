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

    @State private var editingHabit: Habit?
    @State private var showArchiveConfirmation = false
    @State private var showDeleteConfirmation = false
    @State private var monthlyData: [(month: Date, count: Int)] = []
    @State private var totalCompletionCount = 0

    private let calendar = Calendar.current

    var body: some View {
        ScrollView {
            VStack(spacing: DailyArcSpacing.xl) {
                // Header
                headerSection

                // Stat panels
                statPanels

                // Monthly bar chart
                monthlyChart

                // Actions
                actionButtons
            }
            .padding(.horizontal, DailyArcSpacing.lg)
            .padding(.vertical, DailyArcSpacing.xl)
        }
        .background(DailyArcTokens.backgroundPrimary)
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
                    .foregroundStyle(DailyArcTokens.textPrimary)

                Text(frequencyLabel)
                    .typography(.bodySmall)
                    .foregroundStyle(DailyArcTokens.textSecondary)
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
                    .foregroundStyle(DailyArcTokens.textTertiary)
                Text(title)
                    .typography(.caption)
                    .foregroundStyle(DailyArcTokens.textSecondary)
            }
            Text(value)
                .typography(.titleSmall)
                .foregroundStyle(valueColor)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(DailyArcSpacing.md)
        .background(DailyArcTokens.backgroundSecondary)
        .clipShape(RoundedRectangle(cornerRadius: DailyArcTokens.cornerRadiusMedium))
    }

    private var monthlyChart: some View {
        VStack(alignment: .leading, spacing: DailyArcSpacing.sm) {
            Text("Last 12 Months")
                .typography(.titleSmall)
                .foregroundStyle(DailyArcTokens.textPrimary)

            if monthlyData.isEmpty {
                Text("No data yet")
                    .typography(.bodySmall)
                    .foregroundStyle(DailyArcTokens.textTertiary)
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
        .background(DailyArcTokens.backgroundSecondary)
        .clipShape(RoundedRectangle(cornerRadius: DailyArcTokens.cornerRadiusLarge))
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
                .background(DailyArcTokens.warning.opacity(0.15))
                .foregroundStyle(DailyArcTokens.warning)
                .clipShape(RoundedRectangle(cornerRadius: DailyArcTokens.cornerRadiusMedium))
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
                .background(DailyArcTokens.error.opacity(0.15))
                .foregroundStyle(DailyArcTokens.error)
                .clipShape(RoundedRectangle(cornerRadius: DailyArcTokens.cornerRadiusMedium))
            }
        }
    }

    // MARK: - Completion Ring (60pt for detail)

    private var completionRing: some View {
        let rate = computeRate()
        return ZStack {
            Circle()
                .stroke(Color(.systemGray5), lineWidth: 4)
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
                .foregroundStyle(DailyArcTokens.textPrimary)
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

        // Monthly completions
        let completedLogs = habit.logs.filter { $0.count >= habit.targetCount }
        let grouped = Dictionary(grouping: completedLogs) { log -> Date in
            let comps = calendar.dateComponents([.year, .month], from: log.date)
            return calendar.date(from: comps) ?? log.date
        }

        let now = Date()
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
