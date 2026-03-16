import SwiftUI

/// Shows emoji + name + completion circle for a single habit.
/// Tap toggles for targetCount==1, stepper UI for targetCount > 1.
/// Swipe actions for edit/archive.
/// Completion triggers a ripple effect in the habit's color.
struct HabitRowView: View {
    let habit: Habit
    let count: Int
    let onToggle: () -> Void
    let onIncrement: () -> Void
    let onDecrement: () -> Void
    let onEdit: () -> Void
    let onArchive: () -> Void

    @Environment(\.colorScheme) private var colorScheme

    /// Tracks whether the ripple animation is active.
    @State private var showRipple: Bool = false

    /// Stores the previous count to detect completion transitions.
    @State private var previousCount: Int = -1

    /// Brief scale bounce on completion
    @State private var completionBounce: Bool = false

    /// Bounce for multi-count increment
    @State private var countBounce: Bool = false

    private var habitColor: Color {
        habit.color(for: colorScheme)
    }

    private var isComplete: Bool {
        count >= habit.targetCount
    }

    var body: some View {
        Button(action: {
            if habit.targetCount == 1 {
                triggerRippleIfCompleting()
                onToggle()
            }
        }) {
            HStack(spacing: DailyArcSpacing.md) {
                // Emoji
                Text(habit.emoji)
                    .font(.system(size: 32))
                    .frame(width: 40, height: 40)

                // Name + streak
                VStack(alignment: .leading, spacing: DailyArcSpacing.xxs) {
                    Text(habit.name)
                        .typography(.bodyLarge)
                        .foregroundStyle(DailyArcTokens.textPrimary)
                        .lineLimit(1)

                    if habit.currentStreak > 0 {
                        HStack(spacing: DailyArcSpacing.xxs) {
                            Text("\u{1F525}")
                                .font(.caption2)
                            Text("\(habit.currentStreak)")
                                .typography(.caption)
                                .foregroundStyle(DailyArcTokens.streakFire)
                        }
                    }
                }

                Spacer()

                // Stepper for multi-count habits
                if habit.targetCount > 1 {
                    HStack(spacing: DailyArcSpacing.sm) {
                        Button {
                            onDecrement()
                        } label: {
                            Image(systemName: "minus.circle.fill")
                                .font(.system(size: 24))
                                .symbolRenderingMode(.hierarchical)
                                .foregroundStyle(count > 0 ? habitColor : DailyArcTokens.disabled)
                        }
                        .buttonStyle(.plain)
                        .disabled(count <= 0)

                        Text("\(count)/\(habit.targetCount)")
                            .typography(.callout)
                            .foregroundStyle(DailyArcTokens.textSecondary)
                            .frame(minWidth: 36)
                            .scaleEffect(countBounce ? 1.2 : 1.0)
                            .animation(.spring(response: 0.3, dampingFraction: 0.5), value: countBounce)

                        Button {
                            onIncrement()
                        } label: {
                            Image(systemName: "plus.circle.fill")
                                .font(.system(size: 24))
                                .symbolRenderingMode(.hierarchical)
                                .foregroundStyle(count < habit.targetCount ? habitColor : DailyArcTokens.disabled)
                        }
                        .buttonStyle(.plain)
                        .disabled(count >= habit.targetCount)
                    }
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
            .padding(.vertical, DailyArcSpacing.sm)
            .padding(.horizontal, DailyArcSpacing.lg)
            .background(
                RoundedRectangle(cornerRadius: DailyArcTokens.cornerRadiusMedium)
                    .fill(isComplete ? habitColor.opacity(DailyArcTokens.opacitySubtle) : Color.clear)
            )
            .clipShape(RoundedRectangle(cornerRadius: DailyArcTokens.cornerRadiusMedium))
            .overlay(
                // Ripple effect overlay — expanding circle in habit color
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
            // Detect when a multi-count habit reaches completion via increment
            if newValue >= habit.targetCount && oldValue < habit.targetCount {
                fireRipple()
            } else if habit.targetCount > 1 && newValue != oldValue {
                // Bounce count text on multi-count change
                fireCountBounce()
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(habit.emoji) \(habit.name), \(count) of \(habit.targetCount) complete")
        .accessibilityHint(habit.targetCount == 1 ? "Double tap to toggle" : "Use stepper to adjust count")
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
}

#Preview {
    List {
        HabitRowView(
            habit: {
                let h = Habit(name: "Exercise", emoji: "\u{1F3C3}", targetCount: 1)
                h.currentStreak = 5
                return h
            }(),
            count: 0,
            onToggle: {},
            onIncrement: {},
            onDecrement: {},
            onEdit: {},
            onArchive: {}
        )
        HabitRowView(
            habit: Habit(name: "Drink Water", emoji: "\u{1F4A7}", targetCount: 5),
            count: 3,
            onToggle: {},
            onIncrement: {},
            onDecrement: {},
            onEdit: {},
            onArchive: {}
        )
    }
}
