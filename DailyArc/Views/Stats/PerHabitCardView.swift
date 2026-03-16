import SwiftUI
import Charts

/// Card in a 2-column LazyVGrid showing emoji, name, current streak,
/// best streak, completion ring, and 7-day sparkline for a single habit.
struct PerHabitCardView: View {
    let habit: Habit
    let completionRate: Double
    let last7DaysCounts: [Int]

    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        VStack(alignment: .leading, spacing: DailyArcSpacing.sm) {
            // Header: emoji + name
            HStack(spacing: DailyArcSpacing.sm) {
                Text(habit.emoji)
                    .font(.system(size: 32))

                VStack(alignment: .leading, spacing: DailyArcSpacing.xxs) {
                    Text(habit.name)
                        .typography(.callout)
                        .fontWeight(.semibold)
                        .foregroundStyle(DailyArcTokens.textPrimary)
                        .lineLimit(1)
                }
            }

            Divider()

            // Streaks
            HStack(spacing: DailyArcSpacing.md) {
                VStack(alignment: .leading, spacing: DailyArcSpacing.xxs) {
                    HStack(spacing: 2) {
                        Text("\u{1F525}")
                            .font(.caption)
                        Text("\(habit.currentStreak)")
                            .typography(.titleSmall)
                            .foregroundStyle(DailyArcTokens.streakFire)
                            .contentTransition(.numericText())
                    }
                    Text("Current")
                        .typography(.caption2)
                        .foregroundStyle(DailyArcTokens.textTertiary)
                }

                Spacer()

                VStack(alignment: .trailing, spacing: DailyArcSpacing.xxs) {
                    Text("\(habit.bestStreak)")
                        .typography(.titleSmall)
                        .foregroundStyle(DailyArcTokens.textSecondary)
                        .contentTransition(.numericText())
                    Text("Best")
                        .typography(.caption2)
                        .foregroundStyle(DailyArcTokens.textTertiary)
                }
            }

            // Completion ring + sparkline
            HStack {
                Spacer()
                completionRing
                Spacer()
            }

            // 7-day sparkline
            sparkline
        }
        .padding(DailyArcSpacing.md)
        .background(DailyArcTokens.backgroundSecondary)
        .clipShape(RoundedRectangle(cornerRadius: DailyArcTokens.cornerRadiusLarge))
        .shadow(color: DailyArcTokens.cardShadow, radius: 8, x: 0, y: 2)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(habit.emoji) \(habit.name), current streak \(habit.currentStreak) days, best streak \(habit.bestStreak) days, \(Int(completionRate * 100)) percent completion rate")
    }

    // MARK: - Completion Ring

    private var completionRing: some View {
        ZStack {
            // Track
            Circle()
                .stroke(Color(.systemGray5), lineWidth: 3)
                .frame(width: 40, height: 40)

            // Fill
            Circle()
                .trim(from: 0, to: completionRate)
                .stroke(
                    habit.color(for: colorScheme),
                    style: StrokeStyle(lineWidth: 3, lineCap: .round)
                )
                .frame(width: 40, height: 40)
                .rotationEffect(.degrees(-90))
                .animation(.easeInOut(duration: 0.6), value: completionRate)

            // Center text — completion rate percentage
            Text("\(Int(completionRate * 100))%")
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(DailyArcTokens.textPrimary)
                .contentTransition(.numericText())
        }
    }

    // MARK: - Sparkline

    private var sparkline: some View {
        Chart {
            ForEach(Array(last7DaysCounts.enumerated()), id: \.offset) { index, count in
                LineMark(
                    x: .value("Day", index),
                    y: .value("Count", count)
                )
                .interpolationMethod(.catmullRom)
                .foregroundStyle(habit.color(for: colorScheme))
                .lineStyle(StrokeStyle(lineWidth: 1.5))
            }
        }
        .chartXAxis(.hidden)
        .chartYAxis(.hidden)
        .chartLegend(.hidden)
        .frame(height: 30)
    }
}
