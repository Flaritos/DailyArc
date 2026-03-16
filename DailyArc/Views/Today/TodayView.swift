import SwiftUI
import SwiftData

struct TodayView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.colorScheme) private var colorScheme

    @Query(filter: #Predicate<Habit> { !$0.isArchived }, sort: \Habit.sortOrder)
    private var habits: [Habit]

    @Query(sort: \HabitLog.date)
    private var allLogs: [HabitLog]

    @Query(sort: \MoodEntry.date)
    private var allMoods: [MoodEntry]

    @State private var viewModel = TodayViewModel()
    @State private var debouncedSave: DebouncedSave?
    @State private var streakEngine = StreakEngine()
    @State private var showAddHabitSheet = false

    private var calendar: Calendar {
        debouncedSave?.userCalendar ?? Calendar.current
    }

    /// Habits filtered to those that should appear on the selected date.
    private var visibleHabits: [Habit] {
        habits.filter { $0.shouldAppear(on: viewModel.selectedDate, calendar: calendar) }
    }

    /// Total completion progress for the overall arc indicator.
    private var totalProgress: (completed: Int, total: Int) {
        let total = visibleHabits.count
        let completed = visibleHabits.filter { viewModel.completionCount(for: $0) >= $0.targetCount }.count
        return (completed, total)
    }

    /// Whether all visible habits are completed.
    private var allHabitsCompleted: Bool {
        let visible = visibleHabits
        guard !visible.isEmpty else { return false }
        return visible.allSatisfy { viewModel.completionCount(for: $0) >= $0.targetCount }
    }

    /// Streak recovery info for display.
    private var recoverableHabit: (habit: Habit, missedDays: Int, dates: [Date])? {
        for habit in habits {
            let habitID = habit.id
            let descriptor = FetchDescriptor<HabitLog>(
                predicate: #Predicate { $0.habitIDDenormalized == habitID }
            )
            let logs = (try? context.fetch(descriptor)) ?? []
            let result = streakEngine.streakRecoveryAvailable(for: habit, logs: logs, calendar: calendar)
            if result.available {
                return (habit, result.missedDates.count, result.missedDates)
            }
        }
        return nil
    }

    var body: some View {
        ZStack {
            ScrollView {
                VStack(spacing: DailyArcSpacing.xl) {
                    // Greeting
                    Text(viewModel.greetingText(habits: habits))
                        .typography(.titleLarge)
                        .foregroundStyle(DailyArcTokens.textPrimary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, DailyArcSpacing.lg)
                        .padding(.top, DailyArcSpacing.sm)

                    // Date Navigation
                    DateNavigationBar(
                        dateLabel: viewModel.dateLabel,
                        canNavigateForward: viewModel.canNavigateForward,
                        onBack: {
                            viewModel.navigateBack()
                            refreshData()
                        },
                        onForward: {
                            viewModel.navigateForward()
                            refreshData()
                        }
                    )
                    .padding(.horizontal, DailyArcSpacing.sm)

                    // Streak Recovery Banner
                    if let recovery = recoverableHabit {
                        Button {
                            streakEngine.applyRecovery(
                                for: recovery.habit,
                                dates: recovery.dates,
                                context: context,
                                calendar: calendar
                            )
                            debouncedSave?.triggerImmediate()
                            refreshData()
                            HapticManager.streakMilestone()
                        } label: {
                            HStack(spacing: DailyArcSpacing.sm) {
                                Image(systemName: "flame.fill")
                                    .foregroundStyle(DailyArcTokens.streakFire)

                                VStack(alignment: .leading, spacing: DailyArcSpacing.xxs) {
                                    Text("You missed \(recovery.missedDays) day\(recovery.missedDays == 1 ? "" : "s").")
                                        .typography(.bodySmall)
                                        .fontWeight(.semibold)
                                        .foregroundStyle(DailyArcTokens.textPrimary)

                                    Text("Tap to recover your streak.")
                                        .typography(.caption)
                                        .foregroundStyle(DailyArcTokens.textSecondary)
                                }

                                Spacer()

                                Image(systemName: "chevron.right")
                                    .font(.caption)
                                    .foregroundStyle(DailyArcTokens.textTertiary)
                            }
                            .padding(DailyArcSpacing.md)
                            .background(
                                RoundedRectangle(cornerRadius: DailyArcTokens.cornerRadiusMedium)
                                    .fill(DailyArcTokens.warning.opacity(DailyArcTokens.opacityLight))
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: DailyArcTokens.cornerRadiusMedium)
                                    .stroke(DailyArcTokens.warning.opacity(DailyArcTokens.opacityMedium), lineWidth: DailyArcTokens.borderThin)
                            )
                        }
                        .buttonStyle(.plain)
                        .padding(.horizontal, DailyArcSpacing.lg)
                        .accessibilityLabel("Streak recovery available. You missed \(recovery.missedDays) day\(recovery.missedDays == 1 ? "" : "s"). Tap to recover.")
                    }

                    // Mood Check-In Section
                    VStack(spacing: DailyArcSpacing.sm) {
                        MoodCheckInView(
                            selectedScore: viewModel.moodEntry?.moodScore ?? 0,
                            onSelect: { score in
                                viewModel.saveMood(
                                    score: score,
                                    context: context,
                                    calendar: calendar,
                                    debouncedSave: debouncedSave
                                )
                                HapticManager.habitTap()
                                checkBadgesAfterChange()
                            }
                        )

                        // Energy picker — shown after mood is selected
                        if (viewModel.moodEntry?.moodScore ?? 0) > 0 {
                            EnergyPickerView(
                                selectedScore: viewModel.moodEntry?.energyScore ?? 0,
                                onSelect: { score in
                                    viewModel.saveEnergy(
                                        score: score,
                                        context: context,
                                        calendar: calendar,
                                        debouncedSave: debouncedSave
                                    )
                                    HapticManager.habitTap()
                                }
                            )

                            // Activity tags — shown below energy picker
                            ActivityTagsView(
                                selectedActivities: viewModel.moodEntry?.activityList ?? [],
                                onToggle: { tag in
                                    viewModel.toggleActivity(
                                        tag,
                                        context: context,
                                        calendar: calendar,
                                        debouncedSave: debouncedSave
                                    )
                                    HapticManager.habitTap()
                                }
                            )
                        }
                    }
                    .padding(.horizontal, DailyArcSpacing.lg)

                    Divider()
                        .padding(.horizontal, DailyArcSpacing.lg)

                    // Habit Section
                    if visibleHabits.isEmpty && habits.isEmpty {
                        EmptyStateView()
                    } else if visibleHabits.isEmpty {
                        VStack(spacing: DailyArcSpacing.md) {
                            Text("No habits scheduled for this day")
                                .typography(.bodySmall)
                                .foregroundStyle(DailyArcTokens.textSecondary)
                        }
                        .padding(.vertical, DailyArcSpacing.xxxl)
                    } else {
                        // Habits header with arc progress
                        HStack {
                            Text("Habits")
                                .typography(.titleSmall)
                                .foregroundStyle(DailyArcTokens.textPrimary)

                            CompletionCircleView(
                                count: totalProgress.completed,
                                targetCount: totalProgress.total,
                                size: 28,
                                lineWidth: 3,
                                color: DailyArcTokens.accent
                            )

                            Spacer()
                        }
                        .padding(.horizontal, DailyArcSpacing.lg)

                        // Habit list
                        LazyVStack(spacing: DailyArcSpacing.xs) {
                            ForEach(visibleHabits, id: \.id) { habit in
                                HabitRowView(
                                    habit: habit,
                                    count: viewModel.completionCount(for: habit),
                                    onToggle: {
                                        let wasComplete = viewModel.completionCount(for: habit) >= habit.targetCount
                                        viewModel.toggleHabit(
                                            habit,
                                            context: context,
                                            calendar: calendar,
                                            streakEngine: streakEngine,
                                            debouncedSave: debouncedSave
                                        )
                                        let nowComplete = viewModel.completionCount(for: habit) >= habit.targetCount
                                        if !wasComplete && nowComplete {
                                            HapticManager.habitCompletion()
                                            checkStreakMilestone(habit)
                                            checkAllComplete()
                                            checkBadgesAfterChange()
                                        } else {
                                            HapticManager.habitTap()
                                        }
                                    },
                                    onIncrement: {
                                        let wasComplete = viewModel.completionCount(for: habit) >= habit.targetCount
                                        viewModel.incrementHabit(
                                            habit,
                                            context: context,
                                            calendar: calendar,
                                            streakEngine: streakEngine,
                                            debouncedSave: debouncedSave
                                        )
                                        let nowComplete = viewModel.completionCount(for: habit) >= habit.targetCount
                                        if !wasComplete && nowComplete {
                                            HapticManager.habitCompletion()
                                            checkStreakMilestone(habit)
                                            checkAllComplete()
                                            checkBadgesAfterChange()
                                        } else {
                                            HapticManager.habitTap()
                                        }
                                    },
                                    onDecrement: {
                                        viewModel.decrementHabit(
                                            habit,
                                            context: context,
                                            calendar: calendar,
                                            streakEngine: streakEngine,
                                            debouncedSave: debouncedSave
                                        )
                                        HapticManager.habitTap()
                                    },
                                    onEdit: {
                                        // TODO: Present HabitFormView in edit mode
                                    },
                                    onArchive: {
                                        habit.isArchived = true
                                        debouncedSave?.trigger()
                                    }
                                )
                            }
                        }
                        .padding(.horizontal, DailyArcSpacing.sm)
                    }
                }
                .padding(.bottom, DailyArcSpacing.xxl)
            }
            .scrollDismissesKeyboard(.interactively)
            .background(DailyArcTokens.backgroundPrimary)

            // Celebration overlay
            CelebrationOverlay(isShowing: $viewModel.showCelebration)

            // Badge ceremony overlay
            BadgeCeremonyView(badgeEngine: BadgeEngine.shared)
        }
        .navigationTitle("Today")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    showAddHabitSheet = true
                } label: {
                    Image(systemName: "plus")
                }
                .accessibilityLabel("Add new habit")
            }
        }
        .sheet(isPresented: $showAddHabitSheet) {
            HabitFormView(mode: .add)
        }
        .onAppear {
            if debouncedSave == nil {
                debouncedSave = DebouncedSave(context: context)
            }
            refreshData()
        }
        .onChange(of: scenePhase) { _, newPhase in
            switch newPhase {
            case .active:
                debouncedSave?.userCalendar = Calendar.current
                refreshData()
            case .inactive:
                debouncedSave?.flush()
            default:
                break
            }
        }
    }

    private func refreshData() {
        viewModel.fetchLogsForDate(context: context, calendar: calendar)
        viewModel.fetchMoodEntry(context: context, calendar: calendar)
    }

    /// Check if a habit just hit a streak milestone (7, 14, 21, 30, 50, 100, ...).
    private func checkStreakMilestone(_ habit: Habit) {
        let milestones = [7, 14, 21, 30, 50, 100, 150, 200, 365]
        if milestones.contains(habit.currentStreak) {
            HapticManager.streakMilestone()
        }
    }

    /// Check if all habits are now completed and trigger celebration.
    private func checkAllComplete() {
        if allHabitsCompleted {
            withAnimation {
                viewModel.showCelebration = true
            }
        }
    }

    /// Check badges after a habit or mood change.
    private func checkBadgesAfterChange() {
        BadgeEngine.shared.checkBadges(
            habits: habits,
            logs: allLogs,
            moods: allMoods,
            calendar: calendar
        )
    }
}

#Preview {
    NavigationStack {
        TodayView()
    }
    .modelContainer(for: [Habit.self, HabitLog.self, MoodEntry.self, DailySummary.self], inMemory: true)
}
