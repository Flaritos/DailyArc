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
    @State private var editingHabit: Habit?
    @State private var showCalendarPicker = false
    @State private var calendarPickerDate = Date()

    /// Tracks swipe navigation direction for slide transition.
    @State private var swipeDirection: Edge = .trailing

    /// Unique ID that changes on date navigation to trigger transition.
    @State private var contentID = UUID()

    /// Date navigation discovery nudge — shown once during first week
    @AppStorage("hasSeenDateNavNudge") private var hasSeenDateNavNudge = false
    @State private var showDateNavNudge = false

    // Archive toast
    @State private var archiveToast: ArchiveToastInfo? = nil
    struct ArchiveToastInfo: Identifiable {
        let id = UUID()
        let action: ArchiveToastView.ArchiveAction
        let name: String
        let emoji: String
        let streak: Int
    }

    private var calendar: Calendar {
        debouncedSave?.userCalendar ?? Calendar.current
    }

    private var visibleHabits: [Habit] {
        habits.filter { $0.shouldAppear(on: viewModel.selectedDate, calendar: calendar) }
    }

    private var totalProgress: (completed: Int, total: Int) {
        let total = visibleHabits.count
        let completed = visibleHabits.filter { viewModel.completionCount(for: $0) >= $0.targetCount }.count
        return (completed, total)
    }

    private var allHabitsCompleted: Bool {
        let visible = visibleHabits
        guard !visible.isEmpty else { return false }
        return visible.allSatisfy { viewModel.completionCount(for: $0) >= $0.targetCount }
    }

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

    /// Whether GDPR consent is withdrawn (read-only mode)
    private var isConsentWithdrawn: Bool {
        UserDefaults.standard.bool(forKey: "gdprConsentWithdrawn")
    }

    /// Whether free tier limit hint should show
    private var showFreeTierHint: Bool {
        habits.count >= 3 && !StoreKitManager.shared.isPremium
    }

    var body: some View {
        ZStack {
            ScrollView {
                VStack(spacing: DailyArcSpacing.xl) {
                    // Consent withdrawn banner
                    if isConsentWithdrawn {
                        HStack {
                            Image(systemName: "pause.circle.fill")
                                .symbolRenderingMode(.hierarchical)
                                .foregroundStyle(DailyArcTokens.warning)
                            Text("Data processing paused. Re-enable in Settings \u{2192} Privacy.")
                                .typography(.caption)
                                .foregroundStyle(DailyArcTokens.textSecondary)
                        }
                        .padding(DailyArcSpacing.md)
                        .background(DailyArcTokens.warning.opacity(DailyArcTokens.opacityLight))
                        .clipShape(RoundedRectangle(cornerRadius: DailyArcTokens.cornerRadiusMedium))
                        .padding(.horizontal, DailyArcSpacing.lg)
                    }

                    // Greeting
                    Text(viewModel.greetingText(habits: habits))
                        .typography(.titleLarge)
                        .foregroundStyle(DailyArcTokens.textPrimary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, DailyArcSpacing.lg)
                        .padding(.top, DailyArcSpacing.sm)

                    // Motivation card
                    if let card = MotivationService.shared.activeCard {
                        let style: MotivationCardView.MotivationCardStyle = {
                            switch card.style {
                            case .toast: return .toast
                            case .card: return .card
                            case .goldCard: return .goldCard
                            }
                        }()
                        MotivationCardView(
                            message: card.message,
                            style: style,
                            onDismiss: { MotivationService.shared.dismiss() }
                        )
                        .transition(.opacity.combined(with: .move(edge: .top)))
                    }

                    // Date Navigation (tap center for calendar)
                    HStack {
                        DateNavigationBar(
                            dateLabel: viewModel.dateLabel,
                            canNavigateForward: viewModel.canNavigateForward,
                            onBack: {
                                navigateWithAnimation(direction: .trailing) {
                                    viewModel.navigateBack()
                                }
                            },
                            onForward: {
                                navigateWithAnimation(direction: .leading) {
                                    viewModel.navigateForward()
                                }
                            }
                        )
                    }
                    .padding(.horizontal, DailyArcSpacing.sm)
                    .onTapGesture {
                        calendarPickerDate = viewModel.selectedDate
                        showCalendarPicker = true
                    }

                    // Date navigation discovery nudge
                    if showDateNavNudge {
                        HStack(spacing: DailyArcSpacing.xs) {
                            Image(systemName: "arrow.left")
                                .font(.caption.weight(.bold))
                            Text("Missed a day? Tap \u{2190} to go back")
                                .typography(.caption)
                        }
                        .foregroundStyle(.white)
                        .padding(.horizontal, DailyArcSpacing.md)
                        .padding(.vertical, DailyArcSpacing.sm)
                        .background(DailyArcTokens.accent, in: Capsule())
                        .transition(.scale.combined(with: .opacity))
                        .onTapGesture {
                            withAnimation { showDateNavNudge = false }
                            hasSeenDateNavNudge = true
                        }
                    }

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
                                    .symbolRenderingMode(.hierarchical)
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
                        .accessibilityLabel("Streak recovery available")
                    }

                    // Mood Check-In Section
                    if !isConsentWithdrawn {
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

                                // Notes field with journaling prompt
                                VStack(alignment: .leading, spacing: DailyArcSpacing.xs) {
                                    TextField(
                                        JournalingPrompts.prompt(for: viewModel.selectedDate),
                                        text: $viewModel.moodNotes,
                                        axis: .vertical
                                    )
                                    .lineLimit(2...6)
                                    .textFieldStyle(.roundedBorder)
                                    .onChange(of: viewModel.moodNotes) { _, _ in
                                        viewModel.saveMoodNotes(
                                            context: context,
                                            calendar: calendar,
                                            debouncedSave: debouncedSave
                                        )
                                    }
                                }
                            }
                        }
                        .cardStyle()
                        .padding(.horizontal, DailyArcSpacing.sm)
                    }

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
                        // Habits header with arc progress + Manage link
                        HStack {
                            Text("Habits")
                                .typography(.titleSmall)
                                .foregroundStyle(DailyArcTokens.textPrimary)

                            CompletionCircleView(
                                count: totalProgress.completed,
                                targetCount: totalProgress.total,
                                size: 28,
                                lineWidth: 3,
                                color: DailyArcTokens.accent,
                                useGradient: true
                            )

                            Spacer()

                            NavigationLink {
                                HabitManagementView()
                            } label: {
                                Text("Manage")
                                    .typography(.caption)
                                    .foregroundStyle(DailyArcTokens.accent)
                            }
                        }
                        .padding(.horizontal, DailyArcSpacing.lg)

                        // Habit list (card container)
                        LazyVStack(spacing: 0) {
                            ForEach(Array(visibleHabits.enumerated()), id: \.element.id) { index, habit in
                                if index > 0 {
                                    Divider().padding(.horizontal, DailyArcSpacing.lg)
                                }
                                HabitRowView(
                                    habit: habit,
                                    count: viewModel.completionCount(for: habit),
                                    onToggle: {
                                        guard !isConsentWithdrawn else { return }
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
                                            CelebrationService.shared.checkFirstEverHabitCompletion()
                                            checkStreakMilestone(habit)
                                            checkAllComplete()
                                            checkBadgesAfterChange()
                                        } else {
                                            HapticManager.habitTap()
                                        }
                                    },
                                    onIncrement: {
                                        guard !isConsentWithdrawn else { return }
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
                                            CelebrationService.shared.checkFirstEverHabitCompletion()
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
                                        editingHabit = habit
                                    },
                                    onArchive: {
                                        let streak = habit.currentStreak
                                        let name = habit.name
                                        let emoji = habit.emoji
                                        habit.isArchived = true
                                        debouncedSave?.trigger()
                                        showArchiveToast(.archive, name: name, emoji: emoji, streak: streak)
                                    }
                                )
                            }
                        }
                        .background(DailyArcTokens.backgroundSecondary)
                        .clipShape(RoundedRectangle(cornerRadius: DailyArcTokens.cornerRadiusMedium))
                        .shadow(color: .black.opacity(0.06), radius: 8, x: 0, y: 2)
                        .padding(.horizontal, DailyArcSpacing.sm)

                        // Free tier hint
                        if showFreeTierHint {
                            Text("Archive a habit to make room, or upgrade for unlimited.")
                                .font(.caption)
                                .foregroundStyle(DailyArcTokens.textTertiary)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, DailyArcSpacing.lg)
                        }
                    }
                }
                .padding(.bottom, DailyArcSpacing.xxl)
                .id(contentID)
                .transition(.asymmetric(
                    insertion: .move(edge: swipeDirection),
                    removal: .move(edge: swipeDirection == .leading ? .trailing : .leading)
                ))
            }
            .scrollDismissesKeyboard(.interactively)
            .background(DailyArcTokens.backgroundPrimary)
            .gesture(
                DragGesture(minimumDistance: 50)
                    .onEnded { value in
                        let horizontalAmount = value.translation.width

                        if horizontalAmount < -50 {
                            // Swipe left = next day (but not past today)
                            guard viewModel.canNavigateForward else { return }
                            navigateWithAnimation(direction: .leading) {
                                viewModel.navigateForward()
                            }
                        } else if horizontalAmount > 50 {
                            // Swipe right = previous day
                            navigateWithAnimation(direction: .trailing) {
                                viewModel.navigateBack()
                            }
                        }
                    }
            )

            // Celebration overlay
            CelebrationOverlay(isShowing: $viewModel.showCelebration)

            // Badge ceremony overlay
            BadgeCeremonyView(badgeEngine: BadgeEngine.shared)

            // Celebration service overlay
            if CelebrationService.shared.showCelebration, let celebration = CelebrationService.shared.activeCelebration {
                celebrationOverlay(celebration)
            }

            // Undo toast
            if let message = viewModel.undoToastMessage {
                VStack {
                    Spacer()
                    UndoToastView(message: message) {
                        viewModel.performUndo()
                    }
                    .padding(.bottom, DailyArcSpacing.xl)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                }
                .animation(.spring(response: 0.3), value: viewModel.undoToastMessage != nil)
            }

            // Archive toast
            if let toast = archiveToast {
                VStack {
                    Spacer()
                    ArchiveToastView(
                        action: toast.action,
                        habitName: toast.name,
                        habitEmoji: toast.emoji,
                        streak: toast.streak
                    )
                    .padding(.bottom, DailyArcSpacing.xl)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                }
                .animation(.spring(response: 0.3), value: archiveToast != nil)
            }
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
                .disabled(isConsentWithdrawn)
            }
        }
        .sheet(isPresented: $showAddHabitSheet) {
            HabitFormView(mode: .add)
        }
        .sheet(item: $editingHabit) { habit in
            HabitFormView(mode: .edit(habit))
        }
        .sheet(isPresented: $showCalendarPicker) {
            NavigationStack {
                DatePicker(
                    "Jump to date",
                    selection: $calendarPickerDate,
                    in: ...Date(),
                    displayedComponents: .date
                )
                .datePickerStyle(.graphical)
                .tint(DailyArcTokens.accent)
                .padding()
                .navigationTitle("Select Date")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Done") {
                            viewModel.selectedDate = calendarPickerDate
                            showCalendarPicker = false
                            refreshData()
                        }
                    }
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Cancel") { showCalendarPicker = false }
                    }
                }
            }
            .presentationDetents([.medium])
        }
        .onAppear {
            if debouncedSave == nil {
                debouncedSave = DebouncedSave(context: context)
            }
            refreshData()

            // Track app opens and last open date
            EasterEggManager.shared.incrementAppOpen()
            UserDefaults.standard.set(Date(), forKey: "lastOpenDate")

            // Date nav nudge: show once during first week
            if !hasSeenDateNavNudge {
                if let firstLaunch = UserDefaults.standard.object(forKey: "firstLaunchDate") as? Date,
                   Date().timeIntervalSince(firstLaunch) < 7 * 24 * 3600 {
                    withAnimation(.easeOut(duration: 0.4).delay(1.5)) {
                        showDateNavNudge = true
                    }
                    // Auto-dismiss after 5 seconds
                    DispatchQueue.main.asyncAfter(deadline: .now() + 6.5) {
                        withAnimation { showDateNavNudge = false }
                        hasSeenDateNavNudge = true
                    }
                } else {
                    hasSeenDateNavNudge = true
                }
            }

            // Check motivation milestones
            let totalDays = viewModel.totalDaysLogged(context: context, calendar: calendar)
            let userName = UserDefaults.standard.string(forKey: "userName") ?? ""
            MotivationService.shared.checkDayMilestone(totalDaysLogged: totalDays, userName: userName)
        }
        .onChange(of: scenePhase) { _, newPhase in
            switch newPhase {
            case .active:
                debouncedSave?.userCalendar = Calendar.current
                refreshData()
                UserDefaults.standard.set(Date(), forKey: "lastOpenDate")
            case .inactive:
                debouncedSave?.flush()
            default:
                break
            }
        }
    }

    // MARK: - Navigation with Slide Animation

    /// Navigates to a new date with a directional slide transition.
    private func navigateWithAnimation(direction: Edge, action: () -> Void) {
        swipeDirection = direction
        withAnimation(.easeInOut(duration: 0.25)) {
            contentID = UUID()
        }
        action()
        refreshData()
    }

    private func refreshData() {
        viewModel.fetchLogsForDate(context: context, calendar: calendar)
        viewModel.fetchMoodEntry(context: context, calendar: calendar)
    }

    private func checkStreakMilestone(_ habit: Habit) {
        let milestones = [3, 7, 14, 21, 30, 42, 50, 100, 150, 200, 365]
        if milestones.contains(habit.currentStreak) {
            CelebrationService.shared.checkStreakMilestone(habit: habit, previousStreak: habit.bestStreak)
        }

        // Easter egg: streak-based
        if let easterEgg = EasterEggManager.shared.checkStreakEasterEgg(streak: habit.currentStreak) {
            // The message is handled by the easter egg manager's recording
            _ = easterEgg
        }
    }

    private func checkAllComplete() {
        if allHabitsCompleted {
            withAnimation {
                viewModel.showCelebration = true
            }
        }
    }

    private func checkBadgesAfterChange() {
        BadgeEngine.shared.checkBadges(
            habits: habits,
            logs: allLogs,
            moods: allMoods,
            calendar: calendar
        )
    }

    private func showArchiveToast(_ action: ArchiveToastView.ArchiveAction, name: String, emoji: String, streak: Int) {
        archiveToast = ArchiveToastInfo(action: action, name: name, emoji: emoji, streak: streak)
        Task {
            try? await Task.sleep(for: .seconds(4))
            withAnimation { archiveToast = nil }
        }
    }

    @ViewBuilder
    private func celebrationOverlay(_ celebration: CelebrationService.Celebration) -> some View {
        ZStack {
            Color.black.opacity(0.4)
                .ignoresSafeArea()
                .onTapGesture { CelebrationService.shared.dismiss() }

            VStack(spacing: DailyArcSpacing.lg) {
                Text(celebration.emoji)
                    .font(.system(size: 64))

                Text(celebration.title)
                    .typography(.titleLarge)
                    .foregroundStyle(DailyArcTokens.textPrimary)
                    .multilineTextAlignment(.center)

                Text(celebration.message)
                    .typography(.bodySmall)
                    .foregroundStyle(DailyArcTokens.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, DailyArcSpacing.xl)

                HStack(spacing: DailyArcSpacing.md) {
                    if celebration.showShareCard, let habitName = celebration.habitName {
                        ShareButton(
                            cardType: .streakMilestone(
                                habitName: habitName,
                                emoji: celebration.emoji,
                                streak: 0,
                                message: celebration.message
                            ),
                            label: "Share"
                        )
                        .buttonStyle(.bordered)
                    }

                    Button("Nice!") {
                        CelebrationService.shared.dismiss()
                    }
                    .buttonStyle(.borderedProminent)
                }
            }
            .padding(DailyArcSpacing.xxl)
            .background(
                RoundedRectangle(cornerRadius: DailyArcTokens.cornerRadiusLarge)
                    .fill(DailyArcTokens.backgroundPrimary)
                    .shadow(radius: 20)
            )
            .padding(DailyArcSpacing.xxl)
        }
        .transition(.opacity)
    }
}

#Preview {
    NavigationStack {
        TodayView()
    }
    .modelContainer(for: [Habit.self, HabitLog.self, MoodEntry.self, DailySummary.self], inMemory: true)
}
