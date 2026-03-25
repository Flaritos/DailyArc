import SwiftUI
import SwiftData

struct TodayView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.theme) private var theme

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

    // MARK: - Banner Priority System (Gap #7)
    @AppStorage("deferredBanners") private var deferredBannersJSON = "[]"
    private let maxVisibleBanners = 2

    // MARK: - Week Summary (A6)
    @AppStorage("lastWeekSummaryShown") private var lastWeekSummaryShown = ""
    @State private var weekSummary: TodayViewModel.WeekSummaryData?
    @State private var showWeekSummary = false

    // MARK: - Weekly Momentum Report
    @AppStorage("lastWeeklyReportDate") private var lastWeeklyReportDate = ""
    @State private var showWeeklyReport = false

    // MARK: - Scroll Anchoring (Gap #9)
    @State private var scrollAnchorID: String? = nil

    // Streak loss compassion (Gap #2)
    @AppStorage("lastStreakLossShownHabitID") private var lastStreakLossShownHabitID = ""

    // Error state (Gap #5)
    @State private var showError = false
    @State private var errorMessage = ""

    // Skeleton loading (Gap #6)
    @State private var isLoading = true

    // Accessibility
    @Environment(\.accessibilityVoiceOverEnabled) private var isVoiceOverEnabled

    // Cached streak recovery (avoids expensive recomputation on every body evaluation)
    @State private var cachedRecoverableHabit: (habit: Habit, missedDays: Int, dates: [Date])? = nil

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

    /// Computes last 7 days completed status for a habit (for context menu quick stats).
    private func last7DaysCompleted(for habit: Habit) -> [Bool] {
        let cal = calendar
        let today = cal.startOfDay(for: viewModel.selectedDate)
        let habitID = habit.id
        let habitLogs = allLogs.filter { $0.habitIDDenormalized == habitID }
        let logsByDate = Dictionary(grouping: habitLogs) { cal.startOfDay(for: $0.date) }

        return (0..<7).reversed().map { daysAgo in
            guard let date = cal.date(byAdding: .day, value: -daysAgo, to: today) else { return false }
            let dayStart = cal.startOfDay(for: date)
            return (logsByDate[dayStart]?.first?.count ?? 0) >= habit.targetCount
        }
    }

    private var allHabitsCompleted: Bool {
        let visible = visibleHabits
        guard !visible.isEmpty else { return false }
        return visible.allSatisfy { viewModel.completionCount(for: $0) >= $0.targetCount }
    }

    // MARK: - Mission Briefing (Premium + Command)

    /// Returns the command theme header text, using mission briefing language for premium users.
    private var missionBriefingHeader: String {
        if StoreKitManager.shared.isPremium && theme.id == "command" {
            return "> " + MissionBriefingEngine.dailyBriefingHeader(
                habitCount: totalProgress.total,
                completedCount: totalProgress.completed
            )
        }
        return "> YOUR HABITS"
    }

    // MARK: - Streak Aurora (Premium)

    /// The longest current streak across all visible habits, for aurora effect.
    private var maxStreakLength: Int {
        habits.map(\.currentStreak).max() ?? 0
    }

    /// Recomputes the cached recoverable habit. Call in .onAppear / .onChange, not on every body.
    private func refreshRecoverableHabit() {
        for habit in habits {
            let habitID = habit.id
            let descriptor = FetchDescriptor<HabitLog>(
                predicate: #Predicate { $0.habitIDDenormalized == habitID }
            )
            let logs = (try? context.fetch(descriptor)) ?? []
            let result = streakEngine.streakRecoveryAvailable(for: habit, logs: logs, calendar: calendar)
            if result.available {
                cachedRecoverableHabit = (habit, result.missedDates.count, result.missedDates)
                return
            }
        }
        cachedRecoverableHabit = nil
    }

    /// Whether GDPR consent is withdrawn (read-only mode)
    private var isConsentWithdrawn: Bool {
        UserDefaults.standard.bool(forKey: "gdprConsentWithdrawn")
    }

    /// Whether free tier limit hint should show
    private var showFreeTierHint: Bool {
        habits.count >= 5 && !StoreKitManager.shared.isPremium
    }

    // MARK: - Banner Priority System (Gap #7)

    /// Banner types with priority (lower number = higher priority).
    enum BannerType: String, Codable, CaseIterable {
        case streakRecovery
        case motivationCard
        case dateNavNudge
        case insightNudge
        case freeTierHint

        var priority: Int {
            switch self {
            case .streakRecovery: return 1
            case .motivationCard: return 2
            case .dateNavNudge: return 3
            case .insightNudge: return 4
            case .freeTierHint: return 5
            }
        }
    }

    /// Which banners are currently allowed to display (computed on appear, stored in state).
    @State private var activeBannerSet: Set<BannerType> = []

    /// Recomputes which banners should be visible based on priority + deferral.
    private func recomputeVisibleBanners() {
        var qualifying: [BannerType] = []
        if cachedRecoverableHabit != nil { qualifying.append(.streakRecovery) }
        if MotivationService.shared.activeCard != nil { qualifying.append(.motivationCard) }
        if showDateNavNudge { qualifying.append(.dateNavNudge) }
        if showFreeTierHint { qualifying.append(.freeTierHint) }
        qualifying.sort { $0.priority < $1.priority }

        let deferred = loadDeferredBanners()

        // Prioritize previously deferred banners that now qualify
        var prioritized: [BannerType] = []
        for banner in qualifying where deferred.contains(banner.rawValue) {
            prioritized.append(banner)
        }
        for banner in qualifying where !deferred.contains(banner.rawValue) {
            prioritized.append(banner)
        }

        activeBannerSet = Set(prioritized.prefix(maxVisibleBanners))

        // Defer the rest for next session
        let deferredNew = Array(prioritized.dropFirst(maxVisibleBanners).map(\.rawValue))
        saveDeferredBanners(deferredNew)
    }

    private func loadDeferredBanners() -> [String] {
        guard let data = deferredBannersJSON.data(using: .utf8),
              let arr = try? JSONDecoder().decode([String].self, from: data) else {
            return []
        }
        return arr
    }

    private func saveDeferredBanners(_ banners: [String]) {
        if let data = try? JSONEncoder().encode(banners),
           let str = String(data: data, encoding: .utf8) {
            deferredBannersJSON = str
        }
    }

    private func isBannerVisible(_ type: BannerType) -> Bool {
        activeBannerSet.contains(type)
    }

    // MARK: - Week Summary Helpers (A6)

    /// ISO week string for the current week (e.g. "2026-W12")
    private var currentWeekKey: String {
        let cal = Calendar.current
        let comps = cal.dateComponents([.yearForWeekOfYear, .weekOfYear], from: Date())
        return "\(comps.yearForWeekOfYear ?? 0)-W\(comps.weekOfYear ?? 0)"
    }

    private var isMonday: Bool {
        Calendar.current.component(.weekday, from: Date()) == 2
    }

    // MARK: - Extracted Sub-views (breaks up body for type checker)

    /// Command theme greeting: "CMDR [NAME] // 2026.03.24 // SOL [day count]"
    @ViewBuilder
    private var commandGreeting: some View {
        let name = UserDefaults.standard.string(forKey: "userName") ?? "PILOT"
        let displayName = name.isEmpty ? "PILOT" : name.uppercased()
        let dateFormatter: DateFormatter = {
            let f = DateFormatter()
            f.dateFormat = "yyyy.MM.dd"
            return f
        }()
        let dateString = dateFormatter.string(from: viewModel.selectedDate)

        // SOL count: days since first habit's createdAt, or since app install
        let solCount: Int = {
            if let firstHabit = habits.min(by: { $0.createdAt < $1.createdAt }) {
                return max(1, Calendar.current.dateComponents([.day], from: firstHabit.createdAt, to: Date()).day ?? 1)
            }
            return 1
        }()

        let monthFormatter: DateFormatter = {
            let f = DateFormatter()
            f.dateFormat = "MMM d"
            return f
        }()
        let friendlyDate = monthFormatter.string(from: viewModel.selectedDate).uppercased()

        Text("\(displayName) // \(friendlyDate) // DAY \(solCount)")
            .font(.system(size: 14, weight: .bold, design: .monospaced))
            .foregroundStyle(CommandTheme.cyan)
            .shadow(color: CommandTheme.glowCyan, radius: 12, x: 0, y: 0)
            .tracking(1)
    }

    @ViewBuilder
    private var moodCheckInSection: some View {
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
            .padding(.horizontal, DailyArcSpacing.lg)
        }
    }

    @ViewBuilder
    private var habitSection: some View {
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
            // Hero progress indicator (theme-forked)
            if totalProgress.total > 0 {
                let progress = Double(totalProgress.completed) / Double(totalProgress.total)
                let habitRingData: [(color: Color, progress: Double)] = visibleHabits.prefix(3).map { habit in
                    let count = Double(viewModel.completionCount(for: habit))
                    let target = Double(max(habit.targetCount, 1))
                    return (color: habit.color(for: colorScheme), progress: min(count / target, 1.0))
                }
                ThemedProgressRing(progress: progress, size: 120, theme: theme, habitProgresses: habitRingData)
                    .padding(.bottom, DailyArcSpacing.sm)
            }

            // Habits section header (theme-forked)
            HStack {
                if theme.id == "command" {
                    Text(missionBriefingHeader)
                        .font(.system(.caption, design: .monospaced).weight(.semibold))
                        .foregroundStyle(CommandTheme.cyan)
                        .tracking(1.5)
                } else {
                    Text("Habits")
                        .typography(.titleSmall)
                        .foregroundStyle(theme.textPrimary)

                    CompletionCircleView(
                        count: totalProgress.completed,
                        targetCount: totalProgress.total,
                        size: 28,
                        lineWidth: 3,
                        color: DailyArcTokens.accent,
                        useGradient: true
                    )
                }

                Spacer()

                NavigationLink {
                    HabitManagementView()
                } label: {
                    Text(theme.id == "command" ? "MANAGE" : "Manage")
                        .typography(.caption)
                        .font(theme.id == "command" ? .system(.caption, design: .monospaced) : nil)
                        .foregroundStyle(theme.id == "command" ? CommandTheme.cyan : DailyArcTokens.accent)
                }
            }
            .padding(.horizontal, DailyArcSpacing.lg)

            // Habit list (card container)
            habitListCard

            // Free tier hint (priority-managed)
            if isBannerVisible(.freeTierHint), showFreeTierHint {
                Text("Archive a habit to make room, or upgrade for unlimited.")
                    .font(.caption)
                    .foregroundStyle(DailyArcTokens.textTertiary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, DailyArcSpacing.lg)
            }
        }
    }

    private var habitListCard: some View {
        LazyVStack(spacing: theme.id == "command" ? 0 : DailyArcSpacing.md) {
            ForEach(Array(visibleHabits.enumerated()), id: \.element.id) { index, habit in
                if index > 0 && theme.id == "command" {
                    ThemedDivider(theme: theme)
                        .padding(.horizontal, DailyArcSpacing.lg)
                }
                HabitRowView(
                    habit: habit,
                    count: viewModel.completionCount(for: habit),
                    last7DaysCompleted: last7DaysCompleted(for: habit),
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
        .padding(.horizontal, DailyArcSpacing.sm)
    }

    var body: some View {
        ZStack {
            if showError {
                // Gap #5: Error state
                ScrollView {
                    VStack {
                        Spacer(minLength: DailyArcSpacing.xxxl)
                        ErrorStateView(message: errorMessage) {
                            showError = false
                            refreshData()
                        }
                        .padding(.horizontal, DailyArcSpacing.lg)
                        Spacer(minLength: DailyArcSpacing.xxxl)
                    }
                }
                .background(theme.backgroundPrimary.ignoresSafeArea())
            } else if isLoading {
                // Gap #6: Skeleton loading
                TodaySkeletonView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
                    .background(theme.backgroundPrimary.ignoresSafeArea())
            } else {
            ScrollViewReader { proxy in
                ScrollView {
                    VStack(spacing: DailyArcSpacing.xl) {
                        // Custom themed header (replaces hidden navigation bar)
                        HStack {
                            if theme.id == "command" {
                                Text("> TODAY")
                                    .font(.system(size: 22, weight: .semibold, design: .monospaced))
                                    .foregroundStyle(CommandTheme.cyan)
                                    .shadow(color: CommandTheme.glowCyan, radius: 6, x: 0, y: 0)
                            } else {
                                Text("Today")
                                    .font(.system(size: 28, weight: .semibold))
                                    .foregroundStyle(theme.textPrimary)
                            }
                            Spacer()
                            Button {
                                showAddHabitSheet = true
                            } label: {
                                Image(systemName: "plus")
                                    .font(.system(size: 18, weight: .semibold))
                                    .foregroundStyle(theme.id == "command" ? CommandTheme.cyan : DailyArcTokens.accent)
                            }
                            .accessibilityLabel("Add new habit")
                            .disabled(isConsentWithdrawn)
                        }
                        .padding(.horizontal, DailyArcSpacing.lg)
                        .padding(.top, DailyArcSpacing.sm)

                        // Consent withdrawn banner (always shown, not part of priority system)
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

                        // Greeting (theme-forked)
                        if theme.id == "command" {
                            commandGreeting
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(.horizontal, DailyArcSpacing.lg)
                                .padding(.top, DailyArcSpacing.sm)
                        } else {
                            Text(viewModel.greetingText(habits: habits))
                                .typography(.titleLarge)
                                .foregroundStyle(theme.textPrimary)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(.horizontal, DailyArcSpacing.lg)
                                .padding(.top, DailyArcSpacing.sm)
                        }

                        // A6: "Your Week" mini-summary (shown on Mondays, once per week)
                        if showWeekSummary, let summary = weekSummary {
                            Text(summary.displayText)
                                .typography(.caption)
                                .foregroundStyle(DailyArcTokens.textSecondary)
                                .padding(.horizontal, DailyArcSpacing.md)
                                .padding(.vertical, DailyArcSpacing.xs)
                                .background(
                                    Capsule()
                                        .fill(DailyArcTokens.backgroundSecondary)
                                )
                                .padding(.horizontal, DailyArcSpacing.lg)
                                .transition(.opacity.combined(with: .scale))
                                .onTapGesture {
                                    withAnimation { showWeekSummary = false }
                                    lastWeekSummaryShown = currentWeekKey
                                }
                        }

                        // Motivation card (priority-managed)
                        if isBannerVisible(.motivationCard), let card = MotivationService.shared.activeCard {
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

                        // Date navigation discovery nudge (priority-managed)
                        if isBannerVisible(.dateNavNudge), showDateNavNudge {
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

                        // Streak Recovery Banner (priority-managed)
                        if isBannerVisible(.streakRecovery), let recovery = cachedRecoverableHabit {
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

                        // Weekly Momentum Report (premium, Sundays or > 6 days)
                        if showWeeklyReport, StoreKitManager.shared.isPremium {
                            WeeklyReportCard(
                                habits: habits,
                                logs: allLogs,
                                moods: allMoods,
                                onDismiss: {
                                    withAnimation(.easeOut(duration: 0.3)) {
                                        showWeeklyReport = false
                                    }
                                    lastWeeklyReportDate = ISO8601DateFormatter().string(from: Date())
                                }
                            )
                            .transition(.opacity.combined(with: .move(edge: .top)))
                        }

                        // Mood Check-In Section
                        moodCheckInSection

                        // Premium features: Time Machine + Streak Shields + Time Capsule
                        if StoreKitManager.shared.isPremium {
                            // Streak Shield status
                            streakShieldBadge

                            // Time Machine card
                            TimeMachineCard()

                            // Time Capsule
                            timeCapsuleSection
                        }

                        ThemedDivider(theme: theme)
                            .padding(.horizontal, DailyArcSpacing.lg)

                        // Habit Section (Gap #9: anchor ID for scroll restoration)
                        habitSection
                            .id("habitSection")
                    }
                    .padding(.bottom, DailyArcSpacing.xxl)
                    .id(contentID)
                    .transition(.asymmetric(
                        insertion: .move(edge: swipeDirection),
                        removal: .move(edge: swipeDirection == .leading ? .trailing : .leading)
                    ))
                }
                .scrollDismissesKeyboard(.interactively)
                .background(theme.backgroundPrimary.ignoresSafeArea())
                .overlay(alignment: .top) {
                    // Streak Aurora: premium overlay for 30+ day streaks
                    if StoreKitManager.shared.isPremium, maxStreakLength >= 30 {
                        StreakAuroraView(streakLength: maxStreakLength, theme: theme)
                    }
                }
                .themedGridOverlay(theme)
                .themedScanline(theme)
                .gesture(
                    DragGesture(minimumDistance: 50)
                        .onEnded { value in
                            let horizontalAmount = value.translation.width

                            if horizontalAmount < -50 {
                                guard viewModel.canNavigateForward else { return }
                                navigateWithAnimation(direction: .leading) {
                                    viewModel.navigateForward()
                                }
                            } else if horizontalAmount > 50 {
                                navigateWithAnimation(direction: .trailing) {
                                    viewModel.navigateBack()
                                }
                            }
                        }
                )
                // Gap #9: Restore scroll position after celebration overlay dismisses
                .onChange(of: viewModel.showCelebration) { _, isShowing in
                    if !isShowing, scrollAnchorID != nil {
                        withAnimation(.easeOut(duration: 0.3)) {
                            proxy.scrollTo("habitSection", anchor: .top)
                        }
                        scrollAnchorID = nil
                    }
                }
                .onChange(of: CelebrationService.shared.showCelebration) { _, isShowing in
                    if !isShowing, scrollAnchorID != nil {
                        withAnimation(.easeOut(duration: 0.3)) {
                            proxy.scrollTo("habitSection", anchor: .top)
                        }
                        scrollAnchorID = nil
                    }
                }
            }
            } // end else (loading/error)

            // Celebration overlay
            CelebrationOverlay(isShowing: $viewModel.showCelebration)

            // Badge ceremony overlay
            BadgeCeremonyView(badgeEngine: BadgeEngine.shared)

            // Celebration service overlay (includes 365-day arc)
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
        .navigationBarTitleDisplayMode(.inline)
        .toolbar(.hidden, for: .navigationBar)
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

            // Dedup: remove duplicate records (runs once per launch)
            DedupService.runDedup(context: context)

            // A2: Fetch yesterday's completion for adaptive greeting
            viewModel.fetchYesterdayCompletion(habits: habits, context: context, calendar: calendar)

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

            // A6: "Your Week" summary on Mondays (or first visit of the week)
            if (isMonday || lastWeekSummaryShown != currentWeekKey) && lastWeekSummaryShown != currentWeekKey {
                weekSummary = viewModel.weekSummary(habits: habits, context: context, calendar: calendar)
                if weekSummary != nil {
                    withAnimation(.easeOut(duration: 0.4).delay(0.5)) {
                        showWeekSummary = true
                    }
                }
            }

            // Weekly Momentum Report: show on Sundays or if > 6 days since last
            if StoreKitManager.shared.isPremium,
               WeeklyReportCard.shouldShow(lastReportDateString: lastWeeklyReportDate) {
                withAnimation(.easeOut(duration: 0.4).delay(0.8)) {
                    showWeeklyReport = true
                }
            }

            // Refresh cached recoverable habit before computing banners
            refreshRecoverableHabit()

            // Gap #7: Compute visible banners based on priority
            recomputeVisibleBanners()

            // Gap #2: Streak loss compassion check
            checkStreakLossCompassion()

            // Gap #6: Flip loading off after first data load
            if isLoading {
                Task {
                    try? await Task.sleep(for: .milliseconds(100))
                    isLoading = false
                }
            }
        }
        .onChange(of: scenePhase) { _, newPhase in
            switch newPhase {
            case .active:
                debouncedSave?.userCalendar = Calendar.current
                refreshData()
                UserDefaults.standard.set(Date(), forKey: "lastOpenDate")
            case .inactive:
                debouncedSave?.flush()
                // Gap #5: Check for save errors after flush
                checkForSaveError()
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

    /// Gap #5: Surface DebouncedSave errors to the user.
    private func checkForSaveError() {
        if debouncedSave?.lastError != nil {
            errorMessage = "Couldn't save your data. Please try again."
            showError = true
        }
    }

    private func checkStreakMilestone(_ habit: Habit) {
        let milestones = [3, 7, 14, 21, 30, 42, 50, 100, 150, 200, 365]
        if milestones.contains(habit.currentStreak) {
            // Gap #9: Capture scroll anchor before celebration fires
            scrollAnchorID = "habitSection"
            // Gap #13: Pass bestStreak as previousStreak only if current < best (meaning a previous run was lost)
            let previousStreak = habit.currentStreak < habit.bestStreak ? habit.bestStreak : 0
            CelebrationService.shared.checkStreakMilestone(habit: habit, previousStreak: previousStreak)
        }

        // Gap #17: Easter egg display — show as inline toast instead of discarding
        if let easterEgg = EasterEggManager.shared.checkStreakEasterEgg(streak: habit.currentStreak) {
            viewModel.undoToastMessage = easterEgg
        }
    }

    private func checkAllComplete() {
        if allHabitsCompleted {
            // Gap #9: Capture scroll anchor before celebration fires
            scrollAnchorID = "habitSection"
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

    /// Gap #2: Check if any habit lost a streak and show compassion message (once per habit).
    private func checkStreakLossCompassion() {
        for habit in habits {
            if habit.currentStreak == 0 && habit.bestStreak > 2 {
                let habitIDString = habit.id.uuidString
                guard lastStreakLossShownHabitID != habitIDString else { continue }
                lastStreakLossShownHabitID = habitIDString
                CelebrationService.shared.showStreakLoss(habitName: habit.name, lostStreak: habit.bestStreak)
                break // Show one at a time
            }
        }
    }

    private func showArchiveToast(_ action: ArchiveToastView.ArchiveAction, name: String, emoji: String, streak: Int) {
        archiveToast = ArchiveToastInfo(action: action, name: name, emoji: emoji, streak: streak)
        let dismissDelay: Double = isVoiceOverEnabled ? 8 : 4
        Task {
            try? await Task.sleep(for: .seconds(dismissDelay))
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
                // Gap #12: Show AnnualArcView for zenith-tier celebrations
                if celebration.tier == .zenith {
                    AnnualArcView()
                        .padding(.bottom, DailyArcSpacing.sm)
                } else {
                    Text(celebration.emoji)
                        .font(.system(size: 64))
                }

                Text(celebration.title)
                    .typography(.titleLarge)
                    .foregroundStyle(celebration.tier == .zenith ? DailyArcTokens.premiumGold : DailyArcTokens.textPrimary)
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
                    .fill(theme.backgroundPrimary)
                    .shadow(radius: 20)
            )
            .padding(DailyArcSpacing.xxl)
        }
        .transition(.opacity)
    }

    // MARK: - Streak Shield Badge

    @ViewBuilder
    private var streakShieldBadge: some View {
        let remaining = StreakShieldService.shared.shieldsRemaining
        HStack(spacing: DailyArcSpacing.sm) {
            if theme.id == "command" {
                Image(systemName: "shield.fill")
                    .font(.caption)
                    .foregroundStyle(CommandTheme.cyan)
                Text("> SHIELDS: \(remaining)/\(StreakShieldService.maxShieldsPerMonth)")
                    .font(.system(.caption2, design: .monospaced))
                    .foregroundStyle(CommandTheme.cyan.opacity(0.7))
            } else {
                Image(systemName: "shield.fill")
                    .font(.caption)
                    .foregroundStyle(DailyArcTokens.premiumGold)
                Text("\(remaining) shield\(remaining == 1 ? "" : "s") remaining this month")
                    .typography(.caption)
                    .foregroundStyle(theme.textSecondary)
            }
            Spacer()
        }
        .padding(.horizontal, DailyArcSpacing.lg)
        .padding(.vertical, DailyArcSpacing.xs)
    }

    // MARK: - Time Capsule Section

    @ViewBuilder
    private var timeCapsuleSection: some View {
        let totalDays = viewModel.totalDaysLogged(context: context, calendar: calendar)
        if TimeCapsuleView.shouldShow(totalDaysLogged: totalDays) {
            TimeCapsuleView(totalDaysLogged: totalDays) {
                // Dismiss — store that user declined for this session
                UserDefaults.standard.set(true, forKey: "timeCapsuleDismissedThisSession")
            }
        }
    }
}

#Preview {
    NavigationStack {
        TodayView()
    }
    .modelContainer(for: [Habit.self, HabitLog.self, MoodEntry.self, DailySummary.self], inMemory: true)
}
