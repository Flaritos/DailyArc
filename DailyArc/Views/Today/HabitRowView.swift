import SwiftUI

/// Shows emoji + name + completion circle for a single habit.
/// Tap toggles for targetCount==1, stepper UI for targetCount > 1.
/// Swipe actions for edit/archive.
/// Completion triggers a ripple effect in the habit's color.
/// Long-press shows quick stats popover with streak info and 7-day visualization.
///
/// Deep theme fork: Tactile renders raised neumorphic cards; Command renders
/// full-width status rows with blinking dots, monospace text, and linear progress bars.
struct HabitRowView: View {
    let habit: Habit
    let count: Int
    let last7DaysCompleted: [Bool]
    let onToggle: () -> Void
    let onIncrement: () -> Void
    let onDecrement: () -> Void
    let onEdit: () -> Void
    let onArchive: () -> Void

    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.theme) private var theme

    /// Tracks whether the ripple animation is active.
    @State private var showRipple: Bool = false

    /// Stores the previous count to detect completion transitions.
    @State private var previousCount: Int = -1

    /// Brief scale bounce on completion
    @State private var completionBounce: Bool = false

    /// Bounce for multi-count increment
    @State private var countBounce: Bool = false

    /// Controls the quick stats popover on long-press
    @State private var showQuickStats: Bool = false

    init(
        habit: Habit,
        count: Int,
        last7DaysCompleted: [Bool] = [],
        onToggle: @escaping () -> Void,
        onIncrement: @escaping () -> Void,
        onDecrement: @escaping () -> Void,
        onEdit: @escaping () -> Void,
        onArchive: @escaping () -> Void
    ) {
        self.habit = habit
        self.count = count
        self.last7DaysCompleted = last7DaysCompleted
        self.onToggle = onToggle
        self.onIncrement = onIncrement
        self.onDecrement = onDecrement
        self.onEdit = onEdit
        self.onArchive = onArchive
    }

    private var habitColor: Color {
        habit.color(for: colorScheme)
    }

    private var isComplete: Bool {
        count >= habit.targetCount
    }

    // MARK: - Body (Theme Fork)

    var body: some View {
        if theme.id == "command" {
            commandRow
        } else {
            tactileRow
        }
    }

    // MARK: - Tactile Row (Neumorphic Card)

    private var tactileRow: some View {
        Button(action: {
            if habit.targetCount == 1 {
                triggerRippleIfCompleting()
                onToggle()
            }
        }) {
            HStack(spacing: DailyArcSpacing.md) {
                // Emoji in pressed neumorphic circle
                Text(habit.emoji)
                    .font(.system(size: 32))
                    .frame(width: 48, height: 48)
                    .background(
                        Circle()
                            .fill(Color(hex: "#E8ECF1")!)
                            .shadow(color: Color(hex: "#A3B1C6")!.opacity(0.5), radius: 4, x: 3, y: 3)
                            .shadow(color: Color.white.opacity(0.7), radius: 4, x: -3, y: -3)
                    )
                    .clipShape(Circle())

                // Name + streak
                VStack(alignment: .leading, spacing: DailyArcSpacing.xxs) {
                    Text(habit.name)
                        .typography(.bodyLarge)
                        .foregroundStyle(theme.textPrimary)
                        .lineLimit(1)

                    if habit.currentStreak > 0 {
                        HStack(spacing: DailyArcSpacing.xxs) {
                            Text("\u{1F525}")
                                .font(.caption2)
                            Text("\(habit.currentStreak)")
                                .typography(.caption)
                                .foregroundStyle(theme.streakFire)
                                .contentTransition(.numericText())
                            // Streak Shield indicator
                            if StoreKitManager.shared.isPremium,
                               !StreakShieldService.shared.shieldedDates(for: habit.id).isEmpty {
                                Image(systemName: "shield.fill")
                                    .font(.system(size: 9))
                                    .foregroundStyle(DailyArcTokens.premiumGold)
                            }
                        }
                    }
                }

                Spacer()

                // Stepper for multi-count habits
                if habit.targetCount > 1 {
                    tactileStepper
                }

                // Completion circle
                CompletionCircleView(
                    count: count,
                    targetCount: habit.targetCount,
                    size: 36,
                    lineWidth: 3.5,
                    color: habitColor
                )
            }
            .padding(.vertical, DailyArcSpacing.md)
            .padding(.horizontal, DailyArcSpacing.lg)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color(hex: "#E8ECF1")!)
            )
            // Neumorphic raised shadows
            .shadow(color: Color.white.opacity(0.8), radius: 12, x: -6, y: -6)
            .shadow(color: Color(hex: "#A3B1C6")!.opacity(0.6), radius: 12, x: 6, y: 6)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            // Completion gradient overlay
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .fill(
                        isComplete
                            ? LinearGradient(
                                colors: [
                                    Color(hex: "#6366F1")!.opacity(0.12),
                                    Color(hex: "#EC4899")!.opacity(0.10)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                            : LinearGradient(colors: [Color.clear], startPoint: .top, endPoint: .bottom)
                    )
                    .allowsHitTesting(false)
            )
            .overlay(
                // Ripple effect overlay
                Circle()
                    .fill(habitColor)
                    .scaleEffect(showRipple ? 2.0 : 0.5)
                    .opacity(showRipple ? 0 : 0.3)
                    .animation(.easeOut(duration: 0.4), value: showRipple)
                    .allowsHitTesting(false)
            )
            .clipped()
            .contentShape(Rectangle())
            .scaleEffect(completionBounce ? 1.03 : 1.0)
            .animation(.spring(response: 0.15, dampingFraction: 0.5), value: completionBounce)
        }
        .buttonStyle(.plain)
        .sharedModifiers(
            habit: habit,
            count: count,
            last7DaysCompleted: last7DaysCompleted,
            isComplete: isComplete,
            habitAccessibilityLabel: habitAccessibilityLabel,
            onEdit: onEdit,
            onArchive: onArchive,
            onChangeCount: handleCountChange
        )
    }

    // MARK: - Tactile Neumorphic Stepper

    private var tactileStepper: some View {
        HStack(spacing: DailyArcSpacing.sm) {
            Button {
                onDecrement()
            } label: {
                Image(systemName: "minus")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(count > 0 ? habitColor : DailyArcTokens.disabled)
                    .frame(width: 32, height: 32)
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .fill(Color(hex: "#E8ECF1")!)
                            .shadow(color: Color.white.opacity(0.7), radius: 3, x: -3, y: -3)
                            .shadow(color: Color(hex: "#A3B1C6")!.opacity(0.5), radius: 3, x: 3, y: 3)
                    )
            }
            .buttonStyle(.plain)
            .disabled(count <= 0)

            Text("\(count)/\(habit.targetCount)")
                .font(.system(size: 17, weight: .bold))
                .foregroundStyle(habitColor)
                .contentTransition(.numericText())
                .frame(minWidth: 36, minHeight: 32)
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color(hex: "#E8ECF1")!)
                        .shadow(color: Color(hex: "#A3B1C6")!.opacity(0.5), radius: 3, x: 2, y: 2)
                        .shadow(color: Color.white.opacity(0.7), radius: 3, x: -2, y: -2)
                )
                .scaleEffect(countBounce ? 1.2 : 1.0)
                .animation(.spring(response: 0.3, dampingFraction: 0.5), value: countBounce)

            Button {
                onIncrement()
            } label: {
                Image(systemName: "plus")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(count < habit.targetCount ? habitColor : DailyArcTokens.disabled)
                    .frame(width: 32, height: 32)
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .fill(Color(hex: "#E8ECF1")!)
                            .shadow(color: Color.white.opacity(0.7), radius: 3, x: -3, y: -3)
                            .shadow(color: Color(hex: "#A3B1C6")!.opacity(0.5), radius: 3, x: 3, y: 3)
                    )
            }
            .buttonStyle(.plain)
            .disabled(count >= habit.targetCount)
        }
    }

    // MARK: - Command Row (Sci-Fi Status Row)

    private var commandRow: some View {
        Button(action: {
            if habit.targetCount == 1 {
                triggerRippleIfCompleting()
                onToggle()
            }
        }) {
            HStack(spacing: DailyArcSpacing.md) {
                // Blinking status dot
                ThemedStatusDot(
                    status: commandDotStatus,
                    theme: theme
                )

                // Emoji (smaller, functional)
                Text(habit.emoji)
                    .font(.system(size: 14))

                // Name in monospace uppercase (mission briefing for premium)
                Text(commandDisplayName)
                    .font(.system(size: 12, weight: .semibold, design: .monospaced))
                    .foregroundStyle(theme.textPrimary)
                    .lineLimit(1)
                    .tracking(0.5)

                Spacer()

                // Status text
                commandStatusText

                // Stepper for multi-count (compact)
                if habit.targetCount > 1 {
                    commandStepper
                }
            }
            .padding(.vertical, DailyArcSpacing.sm)
            .padding(.horizontal, DailyArcSpacing.md)
            .background(CommandTheme.panel)
            // Left accent bar
            .overlay(alignment: .leading) {
                Rectangle()
                    .fill(commandAccentColor)
                    .frame(width: 3)
            }
            // Bottom border
            .overlay(alignment: .bottom) {
                Rectangle()
                    .fill(Color.white.opacity(0.04))
                    .frame(height: 1)
            }
            // Linear progress bar at the very bottom
            .overlay(alignment: .bottomLeading) {
                GeometryReader { geo in
                    let progress = habit.targetCount > 0
                        ? CGFloat(min(count, habit.targetCount)) / CGFloat(habit.targetCount)
                        : 0
                    Rectangle()
                        .fill(
                            LinearGradient(
                                colors: [CommandTheme.cyan, CommandTheme.indigo],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: geo.size.width * progress, height: 4)
                        .shadow(color: CommandTheme.glowCyan, radius: 4, x: 0, y: 0)
                        .animation(.easeInOut(duration: 0.6), value: count)
                }
                .frame(height: 4)
            }
            .clipShape(RoundedRectangle(cornerRadius: 2))
            .overlay(
                RoundedRectangle(cornerRadius: 2)
                    .stroke(CommandTheme.indigo.opacity(0.12), lineWidth: 1)
            )
            .overlay(
                // Ripple effect overlay
                Circle()
                    .fill(habitColor)
                    .scaleEffect(showRipple ? 2.0 : 0.5)
                    .opacity(showRipple ? 0 : 0.3)
                    .animation(.easeOut(duration: 0.4), value: showRipple)
                    .allowsHitTesting(false)
            )
            .clipped()
            .contentShape(Rectangle())
            .scaleEffect(completionBounce ? 1.03 : 1.0)
            .animation(.spring(response: 0.15, dampingFraction: 0.5), value: completionBounce)
        }
        .buttonStyle(.plain)
        .sharedModifiers(
            habit: habit,
            count: count,
            last7DaysCompleted: last7DaysCompleted,
            isComplete: isComplete,
            habitAccessibilityLabel: habitAccessibilityLabel,
            onEdit: onEdit,
            onArchive: onArchive,
            onChangeCount: handleCountChange
        )
    }

    // MARK: - Command Helpers

    private var commandDotStatus: ThemedStatusDot.Status {
        if isComplete { return .active }
        if count > 0 { return .warning }
        return .inactive
    }

    private var commandAccentColor: Color {
        if isComplete { return Color(hex: "#22C55E")! }
        if count > 0 { return Color(hex: "#EAB308")!.opacity(0.7) }
        return CommandTheme.indigo.opacity(0.5)
    }

    @ViewBuilder
    private var commandStatusText: some View {
        let statusText: String = {
            if isPremiumCommand {
                return MissionBriefingEngine.completionStatus(
                    completed: isComplete,
                    count: count,
                    target: habit.targetCount
                )
            } else if habit.targetCount > 1 {
                return "[\(count)/\(habit.targetCount)]"
            } else {
                return isComplete ? "[DONE]" : "[PENDING]"
            }
        }()

        Text(statusText)
            .font(.system(size: habit.targetCount > 1 ? 11 : 9, weight: .bold, design: .monospaced))
            .foregroundStyle(isComplete ? Color(hex: "#22C55E")! : (habit.targetCount > 1 ? CommandTheme.cyan.opacity(0.7) : Color.white.opacity(0.3)))
            .tracking(habit.targetCount > 1 ? 0.5 : 1)
    }

    private var commandStepper: some View {
        HStack(spacing: DailyArcSpacing.xs) {
            Button {
                onDecrement()
            } label: {
                Text("-")
                    .font(.system(size: 14, weight: .bold, design: .monospaced))
                    .foregroundStyle(count > 0 ? CommandTheme.cyan : Color.white.opacity(0.15))
                    .frame(width: 24, height: 24)
                    .background(
                        RoundedRectangle(cornerRadius: 2)
                            .stroke(count > 0 ? CommandTheme.cyan.opacity(0.3) : Color.white.opacity(0.08), lineWidth: 1)
                    )
            }
            .buttonStyle(.plain)
            .disabled(count <= 0)

            Button {
                onIncrement()
            } label: {
                Text("+")
                    .font(.system(size: 14, weight: .bold, design: .monospaced))
                    .foregroundStyle(count < habit.targetCount ? CommandTheme.cyan : Color.white.opacity(0.15))
                    .frame(width: 24, height: 24)
                    .background(
                        RoundedRectangle(cornerRadius: 2)
                            .stroke(count < habit.targetCount ? CommandTheme.cyan.opacity(0.3) : Color.white.opacity(0.08), lineWidth: 1)
                    )
            }
            .buttonStyle(.plain)
            .disabled(count >= habit.targetCount)
        }
    }

    // MARK: - Mission Briefing (Premium + Command)

    private var isPremiumCommand: Bool {
        StoreKitManager.shared.isPremium && theme.id == "command"
    }

    private var commandDisplayName: String {
        if isPremiumCommand {
            return MissionBriefingEngine.habitDisplayName(habit.name)
        }
        return habit.name.uppercased()
    }

    // MARK: - Shared State

    private var habitAccessibilityLabel: String {
        var label = "\(habit.emoji) \(habit.name), \(count) of \(habit.targetCount) complete"
        if habit.currentStreak > 0 {
            label += ", streak \(habit.currentStreak) days"
        }
        if isComplete {
            label += ", done"
        }
        return label
    }

    // MARK: - Ripple Effect

    /// For binary habits, check if this tap will cause completion and trigger ripple.
    private func triggerRippleIfCompleting() {
        if habit.targetCount == 1 && count == 0 {
            fireRipple()
        }
    }

    /// Fires the expanding circle ripple animation, then resets after duration.
    private func fireRipple() {
        showRipple = true
        completionBounce = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
            completionBounce = false
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
            showRipple = false
        }
    }

    /// Bounces the count text on multi-count increment
    private func fireCountBounce() {
        countBounce = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            countBounce = false
        }
    }

    private func handleCountChange(oldValue: Int, newValue: Int) {
        if newValue >= habit.targetCount && oldValue < habit.targetCount {
            fireRipple()
        } else if habit.targetCount > 1 && newValue != oldValue {
            fireCountBounce()
        }
    }
}

// MARK: - Shared Modifiers Extension

/// Encapsulates context menu, swipe actions, onChange, and accessibility
/// that are shared between both theme variants.
private extension View {
    func sharedModifiers(
        habit: Habit,
        count: Int,
        last7DaysCompleted: [Bool],
        isComplete: Bool,
        habitAccessibilityLabel: String,
        onEdit: @escaping () -> Void,
        onArchive: @escaping () -> Void,
        onChangeCount: @escaping (Int, Int) -> Void
    ) -> some View {
        self
            .contextMenu {
                Section {
                    Label {
                        Text("\(habit.emoji) \(habit.name)")
                    } icon: {
                        Image(systemName: "chart.bar.fill")
                    }

                    Label {
                        Text("\u{1F525} \(habit.currentStreak) day streak")
                    } icon: {
                        Image(systemName: "flame.fill")
                    }

                    Label {
                        Text("Best: \(habit.bestStreak) days")
                    } icon: {
                        Image(systemName: "trophy.fill")
                    }
                }

                if !last7DaysCompleted.isEmpty {
                    let dots = last7DaysCompleted.suffix(7).map { $0 ? "\u{25CF}" : "\u{25CB}" }.joined(separator: " ")
                    Section("Last 7 Days") {
                        Text(dots)
                    }
                }
            }
            .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                Button {
                    onArchive()
                } label: {
                    Label("Archive", systemImage: "archivebox")
                }
                .tint(DailyArcTokens.warning)

                Button {
                    onEdit()
                } label: {
                    Label("Edit", systemImage: "pencil")
                }
                .tint(DailyArcTokens.info)
            }
            .onChange(of: count) { oldValue, newValue in
                onChangeCount(oldValue, newValue)
            }
            .accessibilityElement(children: .combine)
            .accessibilityLabel(habitAccessibilityLabel)
            .accessibilityHint(habit.targetCount == 1 ? "Double tap to toggle" : "Use stepper to adjust count")
    }
}

#Preview {
    List {
        HabitRowView(
            habit: {
                let h = Habit(name: "Exercise", emoji: "\u{1F3C3}", targetCount: 1)
                h.currentStreak = 5
                h.bestStreak = 47
                return h
            }(),
            count: 0,
            last7DaysCompleted: [true, true, false, true, true, true, false],
            onToggle: {},
            onIncrement: {},
            onDecrement: {},
            onEdit: {},
            onArchive: {}
        )
        HabitRowView(
            habit: Habit(name: "Drink Water", emoji: "\u{1F4A7}", targetCount: 5),
            count: 3,
            last7DaysCompleted: [true, false, true, true, false, true, true],
            onToggle: {},
            onIncrement: {},
            onDecrement: {},
            onEdit: {},
            onArchive: {}
        )
    }
}
