import SwiftUI
import SwiftData

/// Premium feature: Shows what the user was doing on this date 1 month, 3 months, and 1 year ago.
/// Displays mood, completed habits, and journal excerpts for each lookback period.
struct TimeMachineCard: View {
    @Environment(\.modelContext) private var context
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.theme) private var theme

    @State private var selectedTab = 0
    @State private var snapshots: [LookbackSnapshot] = []

    private let lookbackPeriods: [(label: String, months: Int)] = [
        ("1 month ago", 1),
        ("3 months ago", 3),
        ("1 year ago", 12)
    ]

    struct LookbackSnapshot: Identifiable {
        let id = UUID()
        let label: String
        let date: Date
        let moodScore: Int
        let moodEmoji: String
        let energyScore: Int
        let completedHabits: [String] // Habit names + emoji
        let totalHabits: Int
        let journalExcerpt: String
        let hasData: Bool
    }

    var body: some View {
        VStack(alignment: .leading, spacing: DailyArcSpacing.md) {
            // Header
            if theme.id == "command" {
                Text("> TIME MACHINE")
                    .font(.system(.caption, design: .monospaced).weight(.semibold))
                    .foregroundStyle(CommandTheme.cyan)
                    .tracking(1.5)
            } else {
                HStack(spacing: DailyArcSpacing.sm) {
                    Image(systemName: "clock.arrow.circlepath")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(DailyArcTokens.premiumGold)
                    Text("Time Machine")
                        .typography(.titleSmall)
                        .foregroundStyle(theme.textPrimary)
                }
            }

            // Tab picker
            HStack(spacing: 0) {
                ForEach(Array(lookbackPeriods.enumerated()), id: \.offset) { index, period in
                    Button {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            selectedTab = index
                        }
                    } label: {
                        Text(period.label)
                            .font(theme.id == "command"
                                  ? .system(.caption2, design: .monospaced).weight(.medium)
                                  : .caption.weight(.medium))
                            .foregroundStyle(selectedTab == index
                                             ? (theme.id == "command" ? CommandTheme.cyan : .white)
                                             : theme.textSecondary)
                            .padding(.horizontal, DailyArcSpacing.sm)
                            .padding(.vertical, DailyArcSpacing.xs)
                            .background {
                                if selectedTab == index {
                                    Capsule()
                                        .fill(theme.id == "command"
                                              ? CommandTheme.cyan.opacity(0.2)
                                              : DailyArcTokens.accent)
                                }
                            }
                    }
                    .buttonStyle(.plain)
                }
            }

            // Content
            if snapshots.indices.contains(selectedTab) {
                let snapshot = snapshots[selectedTab]
                if snapshot.hasData {
                    snapshotContent(snapshot)
                        .transition(.opacity)
                } else {
                    noDataView(snapshot)
                        .transition(.opacity)
                }
            }
        }
        .padding(DailyArcSpacing.lg)
        .background(
            RoundedRectangle(cornerRadius: DailyArcTokens.cornerRadiusMedium)
                .fill(theme.id == "command"
                      ? CommandTheme.cyan.opacity(0.04)
                      : DailyArcTokens.backgroundSecondary)
        )
        .overlay(
            RoundedRectangle(cornerRadius: DailyArcTokens.cornerRadiusMedium)
                .stroke(theme.id == "command"
                        ? CommandTheme.cyan.opacity(0.15)
                        : DailyArcTokens.border.opacity(0.3),
                        lineWidth: DailyArcTokens.borderThin)
        )
        .padding(.horizontal, DailyArcSpacing.lg)
        .onAppear { loadSnapshots() }
    }

    // MARK: - Snapshot Content

    @ViewBuilder
    private func snapshotContent(_ snapshot: LookbackSnapshot) -> some View {
        VStack(alignment: .leading, spacing: DailyArcSpacing.sm) {
            // Date
            Text(formattedDate(snapshot.date))
                .font(theme.id == "command"
                      ? .system(.caption, design: .monospaced)
                      : .caption)
                .foregroundStyle(theme.textTertiary)

            // Mood row
            if snapshot.moodScore > 0 {
                HStack(spacing: DailyArcSpacing.sm) {
                    Text(snapshot.moodEmoji)
                        .font(.title3)
                    Text(moodLabel(for: snapshot.moodScore))
                        .typography(.bodySmall)
                        .foregroundStyle(theme.textPrimary)
                    if snapshot.energyScore > 0 {
                        Text("\u{26A1}\u{FE0F} \(snapshot.energyScore)/5")
                            .typography(.caption)
                            .foregroundStyle(theme.textSecondary)
                    }
                }
            }

            // Habits completed
            if !snapshot.completedHabits.isEmpty {
                VStack(alignment: .leading, spacing: DailyArcSpacing.xxs) {
                    Text(theme.id == "command"
                         ? "> COMPLETED: \(snapshot.completedHabits.count)/\(snapshot.totalHabits)"
                         : "\(snapshot.completedHabits.count) of \(snapshot.totalHabits) habits completed")
                        .font(theme.id == "command"
                              ? .system(.caption2, design: .monospaced)
                              : .caption.weight(.medium))
                        .foregroundStyle(theme.id == "command" ? CommandTheme.cyan : theme.textSecondary)

                    // Show habit names (first 4)
                    let displayHabits = Array(snapshot.completedHabits.prefix(4))
                    ForEach(displayHabits, id: \.self) { habit in
                        Text(habit)
                            .font(theme.id == "command"
                                  ? .system(.caption2, design: .monospaced)
                                  : .caption)
                            .foregroundStyle(theme.textSecondary)
                    }
                    if snapshot.completedHabits.count > 4 {
                        Text("+\(snapshot.completedHabits.count - 4) more")
                            .font(.caption2)
                            .foregroundStyle(theme.textTertiary)
                    }
                }
            }

            // Journal excerpt
            if !snapshot.journalExcerpt.isEmpty {
                VStack(alignment: .leading, spacing: DailyArcSpacing.xxs) {
                    Text(theme.id == "command" ? "> LOG ENTRY" : "Journal")
                        .font(theme.id == "command"
                              ? .system(.caption2, design: .monospaced).weight(.semibold)
                              : .caption.weight(.semibold))
                        .foregroundStyle(theme.id == "command" ? CommandTheme.cyan : theme.textSecondary)

                    Text("\"\(snapshot.journalExcerpt)\"")
                        .font(theme.id == "command"
                              ? .system(.caption, design: .monospaced)
                              : .caption)
                        .foregroundStyle(theme.textSecondary)
                        .italic()
                        .lineLimit(3)
                }
            }
        }
    }

    @ViewBuilder
    private func noDataView(_ snapshot: LookbackSnapshot) -> some View {
        HStack(spacing: DailyArcSpacing.sm) {
            Image(systemName: "clock")
                .font(.title3)
                .foregroundStyle(theme.textTertiary)
            VStack(alignment: .leading, spacing: DailyArcSpacing.xxs) {
                Text(formattedDate(snapshot.date))
                    .font(theme.id == "command"
                          ? .system(.caption, design: .monospaced)
                          : .caption)
                    .foregroundStyle(theme.textTertiary)
                Text(theme.id == "command"
                     ? "> NO DATA LOGGED — KEEP TRACKING"
                     : "No data yet — keep tracking!")
                    .font(theme.id == "command"
                          ? .system(.caption, design: .monospaced)
                          : .caption)
                    .foregroundStyle(theme.textSecondary)
            }
        }
        .padding(.vertical, DailyArcSpacing.sm)
    }

    // MARK: - Data Loading

    private func loadSnapshots() {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())

        snapshots = lookbackPeriods.map { period in
            guard let lookbackDate = calendar.date(byAdding: .month, value: -period.months, to: today) else {
                return LookbackSnapshot(
                    label: period.label, date: today,
                    moodScore: 0, moodEmoji: "", energyScore: 0,
                    completedHabits: [], totalHabits: 0,
                    journalExcerpt: "", hasData: false
                )
            }
            let normalizedDate = calendar.startOfDay(for: lookbackDate)
            return fetchSnapshot(for: normalizedDate, label: period.label, calendar: calendar)
        }
    }

    private func fetchSnapshot(for date: Date, label: String, calendar: Calendar) -> LookbackSnapshot {
        // Fetch mood for the date
        var moodDescriptor = FetchDescriptor<MoodEntry>(
            predicate: #Predicate { $0.date == date }
        )
        moodDescriptor.fetchLimit = 1
        let moodEntry = (try? context.fetch(moodDescriptor))?.first

        // Fetch all habit logs for the date
        let logDescriptor = FetchDescriptor<HabitLog>(
            predicate: #Predicate { $0.date == date }
        )
        let logs = (try? context.fetch(logDescriptor)) ?? []

        // Fetch all habits that existed at that date
        let habitDescriptor = FetchDescriptor<Habit>()
        let allHabits = (try? context.fetch(habitDescriptor)) ?? []
        let activeHabits = allHabits.filter { habit in
            calendar.startOfDay(for: habit.startDate) <= date
                && habit.shouldAppear(on: date, calendar: calendar)
        }

        let completedHabits = activeHabits.compactMap { habit -> String? in
            let logCount = logs.first(where: { $0.habitIDDenormalized == habit.id })?.count ?? 0
            guard logCount >= habit.targetCount else { return nil }
            return "\(habit.emoji) \(habit.name)"
        }

        let journalExcerpt: String = {
            guard let notes = moodEntry?.notes, !notes.isEmpty else { return "" }
            if notes.count <= 100 { return notes }
            return String(notes.prefix(100)) + "..."
        }()

        let hasData = (moodEntry?.moodScore ?? 0) > 0 || !completedHabits.isEmpty

        return LookbackSnapshot(
            label: label,
            date: date,
            moodScore: moodEntry?.moodScore ?? 0,
            moodEmoji: moodEntry?.moodEmoji ?? "",
            energyScore: moodEntry?.energyScore ?? 0,
            completedHabits: completedHabits,
            totalHabits: activeHabits.count,
            journalExcerpt: journalExcerpt,
            hasData: hasData
        )
    }

    // MARK: - Helpers

    private func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }

    private func moodLabel(for score: Int) -> String {
        switch score {
        case 1: return "Rough day"
        case 2: return "Not great"
        case 3: return "Okay"
        case 4: return "Good"
        case 5: return "Great"
        default: return ""
        }
    }
}
