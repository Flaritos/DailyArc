import SwiftUI
import Charts

/// Card in a 2-column LazyVGrid showing emoji, name, current streak,
/// best streak, completion ring, and 7-day sparkline for a single habit.
/// Deep visual fork: Tactile (neumorphic) vs Command (sci-fi panel).
struct PerHabitCardView: View {
    let habit: Habit
    let completionRate: Double
    let last7DaysCounts: [Int]

    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.theme) private var theme

    var body: some View {
        if theme.id == "command" {
            commandCard
        } else {
            tactileCard
        }
    }

    // MARK: - Tactile (Neumorphic) Card

    private var tactileCard: some View {
        VStack(alignment: .leading, spacing: DailyArcSpacing.sm) {
            // Header: emoji in pressed neumorphic circle + name
            HStack(spacing: DailyArcSpacing.sm) {
                // Emoji in pressed neumorphic circle
                ZStack {
                    Circle()
                        .fill(Color(hex: "#E8ECF1")!)
                        .frame(width: 44, height: 44)
                        .shadow(color: Color(hex: "#A3B1C6")!.opacity(0.6), radius: 6, x: 3, y: 3)
                        .shadow(color: Color.white.opacity(0.7), radius: 6, x: -3, y: -3)
                        .clipShape(Circle())

                    Text(habit.emoji)
                        .font(.system(size: 22))
                }

                VStack(alignment: .leading, spacing: DailyArcSpacing.xxs) {
                    Text(habit.name)
                        .typography(.callout)
                        .fontWeight(.semibold)
                        .foregroundStyle(Color(hex: "#334155")!)
                        .lineLimit(1)
                }
            }

            // Soft gradient divider
            Rectangle()
                .fill(
                    LinearGradient(
                        colors: [.clear, Color(hex: "#A3B1C6")!.opacity(0.3), .clear],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .frame(height: 1)

            // Streaks
            HStack(spacing: DailyArcSpacing.md) {
                VStack(alignment: .leading, spacing: DailyArcSpacing.xxs) {
                    HStack(spacing: 2) {
                        Text("\u{1F525}")
                            .font(.caption)
                        Text("\(habit.currentStreak)")
                            .typography(.titleSmall)
                            .fontWeight(.bold)
                            .foregroundStyle(Color(hex: "#F97316")!)
                            .contentTransition(.numericText())
                    }
                    Text("Current")
                        .typography(.caption2)
                        .foregroundStyle(Color(hex: "#94A3B8")!)
                }

                Spacer()

                VStack(alignment: .trailing, spacing: DailyArcSpacing.xxs) {
                    Text("\(habit.bestStreak)")
                        .typography(.titleSmall)
                        .foregroundStyle(Color(hex: "#64748B")!)
                        .contentTransition(.numericText())
                    Text("Best")
                        .typography(.caption2)
                        .foregroundStyle(Color(hex: "#94A3B8")!)
                }
            }

            // Completion ring with neumorphic bezel
            HStack {
                Spacer()
                tactileCompletionRing
                Spacer()
            }

            // 7-day sparkline
            sparkline(lineColor: habit.color(for: colorScheme), glowing: false)
        }
        .padding(DailyArcSpacing.md)
        .background(Color(hex: "#E8ECF1")!)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: Color.white.opacity(0.8), radius: 12, x: -6, y: -6)
        .shadow(color: Color(hex: "#A3B1C6")!.opacity(0.6), radius: 12, x: 6, y: 6)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(habit.emoji) \(habit.name), current streak \(habit.currentStreak) days, best streak \(habit.bestStreak) days, \(Int(completionRate * 100)) percent completion rate")
    }

    // MARK: - Tactile Completion Ring (Mini Neumorphic Bezel)

    private var tactileCompletionRing: some View {
        ZStack {
            // Outer raised circle (bezel)
            Circle()
                .fill(Color(hex: "#E8ECF1")!)
                .frame(width: 52, height: 52)
                .shadow(color: Color.white.opacity(0.7), radius: 4, x: -3, y: -3)
                .shadow(color: Color(hex: "#A3B1C6")!.opacity(0.5), radius: 4, x: 3, y: 3)

            // Inner pressed circle (face)
            Circle()
                .fill(Color(hex: "#E8ECF1")!)
                .frame(width: 42, height: 42)
                .shadow(color: Color(hex: "#A3B1C6")!.opacity(0.5), radius: 3, x: 2, y: 2)
                .shadow(color: Color.white.opacity(0.6), radius: 3, x: -2, y: -2)
                .clipShape(Circle())

            // Background track
            Circle()
                .stroke(Color(hex: "#A3B1C6")!.opacity(0.2), lineWidth: 3)
                .frame(width: 40, height: 40)

            // Gradient arc fill
            Circle()
                .trim(from: 0, to: completionRate)
                .stroke(
                    LinearGradient(
                        colors: [Color(hex: "#6366F1")!, Color(hex: "#EC4899")!],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    style: StrokeStyle(lineWidth: 3, lineCap: .round)
                )
                .frame(width: 40, height: 40)
                .rotationEffect(.degrees(-90))
                .shadow(color: Color(hex: "#6366F1")!.opacity(0.4), radius: 2, x: 0, y: 0)
                .animation(.easeInOut(duration: 0.6), value: completionRate)

            // Center percentage
            Text("\(Int(completionRate * 100))%")
                .font(.system(size: 11, weight: .bold))
                .foregroundStyle(Color(hex: "#334155")!)
                .contentTransition(.numericText())
        }
    }

    // MARK: - Command (Sci-Fi Panel) Card

    private var commandCard: some View {
        VStack(alignment: .leading, spacing: DailyArcSpacing.sm) {
            // Header: emoji + name
            HStack(spacing: DailyArcSpacing.sm) {
                Text(habit.emoji)
                    .font(.system(size: 24))

                VStack(alignment: .leading, spacing: DailyArcSpacing.xxs) {
                    Text(habit.name)
                        .font(.system(.callout, design: .monospaced).weight(.semibold))
                        .foregroundStyle(Color(hex: "#E2E8F0")!)
                        .lineLimit(1)
                }
            }

            // Thin cyan divider
            Rectangle()
                .fill(CommandTheme.cyan.opacity(0.15))
                .frame(height: 1)

            // Streaks — monospace cyan
            HStack(spacing: DailyArcSpacing.md) {
                VStack(alignment: .leading, spacing: DailyArcSpacing.xxs) {
                    Text("\(habit.currentStreak)")
                        .font(.system(.title3, design: .monospaced).weight(.bold))
                        .foregroundStyle(CommandTheme.cyan)
                        .shadow(color: CommandTheme.glowCyan, radius: 8, x: 0, y: 0)
                        .contentTransition(.numericText())
                    Text("DAY STREAK")
                        .font(.system(size: 9, weight: .semibold, design: .monospaced))
                        .foregroundStyle(Color.white.opacity(0.4))
                        .tracking(0.5)
                }

                Spacer()

                VStack(alignment: .trailing, spacing: DailyArcSpacing.xxs) {
                    Text("\(habit.bestStreak)")
                        .font(.system(.callout, design: .monospaced).weight(.semibold))
                        .foregroundStyle(Color.white.opacity(0.5))
                        .contentTransition(.numericText())
                    Text("BEST")
                        .font(.system(size: 9, weight: .semibold, design: .monospaced))
                        .foregroundStyle(Color.white.opacity(0.3))
                        .tracking(0.5)
                }
            }

            // Completion as large monospace percentage (not a ring)
            HStack {
                Spacer()
                Text("\(Int(completionRate * 100))%")
                    .font(.system(size: 28, weight: .bold, design: .monospaced))
                    .foregroundStyle(CommandTheme.cyan)
                    .shadow(color: CommandTheme.glowCyan, radius: 12, x: 0, y: 0)
                    .contentTransition(.numericText())
                Spacer()
            }

            // Cyan sparkline with glow
            sparkline(lineColor: CommandTheme.cyan, glowing: true)
        }
        .padding(DailyArcSpacing.md)
        .background(CommandTheme.panel)
        .clipShape(RoundedRectangle(cornerRadius: 2))
        .overlay(
            RoundedRectangle(cornerRadius: 2)
                .stroke(Color(hex: "#6366F1")!.opacity(0.12), lineWidth: 1)
        )
        // Left colored accent bar (habit color)
        .overlay(alignment: .leading) {
            RoundedRectangle(cornerRadius: 1)
                .fill(habit.color(for: colorScheme).opacity(0.7))
                .frame(width: 3)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(habit.emoji) \(habit.name), current streak \(habit.currentStreak) days, best streak \(habit.bestStreak) days, \(Int(completionRate * 100)) percent completion rate")
    }

    // MARK: - Sparkline

    private func sparkline(lineColor: Color, glowing: Bool) -> some View {
        Chart {
            ForEach(Array(last7DaysCounts.enumerated()), id: \.offset) { index, count in
                LineMark(
                    x: .value("Day", index),
                    y: .value("Count", count)
                )
                .interpolationMethod(.catmullRom)
                .foregroundStyle(lineColor)
                .lineStyle(StrokeStyle(lineWidth: glowing ? 2 : 1.5))
            }
        }
        .chartXAxis(.hidden)
        .chartYAxis(.hidden)
        .chartLegend(.hidden)
        .frame(height: 30)
        .shadow(color: glowing ? lineColor.opacity(0.4) : .clear, radius: glowing ? 6 : 0, x: 0, y: 0)
    }
}
