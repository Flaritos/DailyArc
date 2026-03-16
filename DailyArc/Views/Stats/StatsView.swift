import SwiftUI
import SwiftData

/// Stats tab with segmented control: "Your Arc" | "Insights".
/// "Your Arc" shows heat map, mood trend, per-habit cards.
/// "Insights" shows correlation results, suggestions, or data collection progress.
struct StatsView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.colorScheme) private var colorScheme

    @Query(filter: #Predicate<Habit> { !$0.isArchived }, sort: \Habit.sortOrder)
    private var activeHabits: [Habit]

    @Query(sort: \HabitLog.date)
    private var allLogs: [HabitLog]

    @Query(sort: \MoodEntry.date)
    private var allMoods: [MoodEntry]

    @State private var viewModel = StatsViewModel()
    @State private var showPaywall = false
    @State private var showMoodConsentPrompt = false
    @AppStorage("moodCorrelationConsentDate") private var moodConsentDate = ""
    @AppStorage("moodConsentPromptDismissed") private var moodConsentDismissed = false

    private let columns = [
        GridItem(.flexible(), spacing: DailyArcSpacing.md),
        GridItem(.flexible(), spacing: DailyArcSpacing.md)
    ]

    var body: some View {
        VStack(spacing: 0) {
            // Segmented control
            Picker("Section", selection: $viewModel.selectedSegment) {
                ForEach(StatsViewModel.StatsSegment.allCases, id: \.self) { segment in
                    Text(segment.rawValue).tag(segment)
                }
            }
            .pickerStyle(.segmented)
            .padding(.horizontal, DailyArcSpacing.lg)
            .padding(.vertical, DailyArcSpacing.sm)

            // Content
            Group {
                switch viewModel.selectedSegment {
                case .yourArc:
                    yourArcContent
                case .insights:
                    insightsContent
                }
            }
        }
        .background(DailyArcTokens.backgroundPrimary)
        .navigationTitle("Stats")
        .onAppear {
            viewModel.loadSnapshots(habits: activeHabits, logs: allLogs, moods: allMoods)
            viewModel.computeCorrelations(habits: activeHabits, logs: allLogs, moods: allMoods)
        }
        .onDisappear {
            viewModel.cancelTasks()
        }
        .onChange(of: activeHabits.count) {
            viewModel.loadSnapshots(habits: activeHabits, logs: allLogs, moods: allMoods)
            viewModel.computeCorrelations(habits: activeHabits, logs: allLogs, moods: allMoods)
        }
    }

    // MARK: - Your Arc

    private var yourArcContent: some View {
        ScrollView {
            VStack(spacing: DailyArcSpacing.xl) {
                // Heat Map
                HeatMapCanvasView(
                    snapshots: viewModel.snapshots,
                    selectedSnapshot: $viewModel.selectedSnapshot
                )
                .padding(.horizontal, DailyArcSpacing.lg)

                // Mood Trend
                MoodTrendView(
                    moodEntries: viewModel.recentMoodEntries(from: allMoods)
                )
                .padding(.horizontal, DailyArcSpacing.lg)

                // Per-Habit Cards
                if activeHabits.isEmpty {
                    emptyHabitsState
                } else {
                    VStack(alignment: .leading, spacing: DailyArcSpacing.sm) {
                        Text("Per-Habit Stats")
                            .typography(.titleSmall)
                            .foregroundStyle(DailyArcTokens.textPrimary)
                            .padding(.horizontal, DailyArcSpacing.lg)

                        LazyVGrid(columns: columns, spacing: DailyArcSpacing.md) {
                            ForEach(activeHabits) { habit in
                                NavigationLink(value: habit.id) {
                                    PerHabitCardView(
                                        habit: habit,
                                        completionRate: viewModel.completionRate(for: habit, logs: allLogs)
                                    )
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(.horizontal, DailyArcSpacing.lg)
                    }
                }
            }
            .padding(.vertical, DailyArcSpacing.lg)
        }
        .navigationDestination(for: UUID.self) { habitID in
            if let habit = activeHabits.first(where: { $0.id == habitID }) {
                PerHabitDetailView(habit: habit)
            }
        }
    }

    // MARK: - Insights

    private var insightsContent: some View {
        ScrollView {
            VStack(spacing: DailyArcSpacing.xl) {
                if viewModel.pairedDataDays < 14 {
                    // Not enough data — show progress + teaser
                    dataCollectionProgressView

                    // Pre-activation teaser
                    insightTeaserCard
                } else if !StoreKitManager.shared.isPremium {
                    // Free user with enough data — show teaser + paywall CTA
                    freeUserInsightTeaser
                } else if viewModel.isComputingCorrelations {
                    computingView
                } else if viewModel.correlationResults.isEmpty {
                    if let error = viewModel.correlationError {
                        stillCrunchingView(message: error)
                    } else {
                        noCorrelationsView
                    }
                } else {
                    correlationResultsView
                }
            }
            .padding(.vertical, DailyArcSpacing.lg)
        }
        .background(DailyArcTokens.backgroundPrimary)
        .sheet(isPresented: $showPaywall) {
            PaywallView()
        }
        .onAppear {
            // Mood correlation consent prompt (single-shot)
            if moodConsentDate.isEmpty && !moodConsentDismissed {
                showMoodConsentPrompt = true
            }
        }
        .alert("Enable mood insights?", isPresented: $showMoodConsentPrompt) {
            Button("Enable") {
                moodConsentDate = ISO8601DateFormatter().string(from: Date())
            }
            Button("Not Now", role: .cancel) {
                moodConsentDismissed = true
            }
        } message: {
            Text("DailyArc can show how your habits affect your mood \u{2014} all analysis stays on your device.")
        }
    }

    // MARK: - Data Collection Progress

    private var dataCollectionProgressView: some View {
        VStack(spacing: DailyArcSpacing.xl) {
            Spacer(minLength: DailyArcSpacing.xxxl)

            Image(systemName: "chart.line.uptrend.xyaxis")
                .font(.system(size: 40))
                .foregroundStyle(DailyArcTokens.textTertiary)

            Text("Building Your Insights")
                .typography(.titleMedium)
                .foregroundStyle(DailyArcTokens.textPrimary)

            // Progress indicator
            let daysRemaining = max(0, 14 - viewModel.pairedDataDays)
            VStack(spacing: DailyArcSpacing.sm) {
                ProgressView(value: Double(viewModel.pairedDataDays), total: 14)
                    .tint(DailyArcTokens.accent)
                    .padding(.horizontal, DailyArcSpacing.xxl)

                Text("\(daysRemaining) more days until your first insights")
                    .typography(.bodySmall)
                    .foregroundStyle(DailyArcTokens.textSecondary)
            }

            Text("Log your mood and complete habits daily. After 14 days of data, we'll show you how your habits affect your mood.")
                .typography(.bodySmall)
                .foregroundStyle(DailyArcTokens.textTertiary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, DailyArcSpacing.xxl)

            Spacer(minLength: DailyArcSpacing.xxxl)
        }
    }

    // MARK: - Computing View

    private var computingView: some View {
        VStack(spacing: DailyArcSpacing.lg) {
            Spacer(minLength: DailyArcSpacing.xxxl)

            ProgressView()
                .scaleEffect(1.2)

            Text("Analyzing your patterns...")
                .typography(.bodySmall)
                .foregroundStyle(DailyArcTokens.textSecondary)

            Spacer(minLength: DailyArcSpacing.xxxl)
        }
    }

    // MARK: - Still Crunching

    private func stillCrunchingView(message: String) -> some View {
        VStack(spacing: DailyArcSpacing.lg) {
            Spacer(minLength: DailyArcSpacing.xxxl)

            ProgressView()

            Text(message)
                .typography(.bodySmall)
                .foregroundStyle(DailyArcTokens.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, DailyArcSpacing.xxl)

            Spacer(minLength: DailyArcSpacing.xxxl)
        }
    }

    // MARK: - No Correlations Found

    private var noCorrelationsView: some View {
        VStack(spacing: DailyArcSpacing.lg) {
            Spacer(minLength: DailyArcSpacing.xxxl)

            Image(systemName: "equal.circle")
                .font(.system(size: 40))
                .foregroundStyle(DailyArcTokens.textTertiary)

            Text("No Clear Patterns Yet")
                .typography(.titleMedium)
                .foregroundStyle(DailyArcTokens.textPrimary)

            Text("Keep logging your mood and habits. Clearer patterns emerge over time as more data is collected.")
                .typography(.bodySmall)
                .foregroundStyle(DailyArcTokens.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, DailyArcSpacing.xxl)

            Spacer(minLength: DailyArcSpacing.xxxl)
        }
    }

    // MARK: - Correlation Results

    private var correlationResultsView: some View {
        VStack(alignment: .leading, spacing: DailyArcSpacing.lg) {
            // Section header
            Text("Mood-Habit Patterns")
                .typography(.titleSmall)
                .foregroundStyle(DailyArcTokens.textPrimary)
                .padding(.horizontal, DailyArcSpacing.lg)

            // Correlation cards
            ForEach(viewModel.correlationResults) { result in
                CorrelationCardView(result: result)
                    .padding(.horizontal, DailyArcSpacing.lg)
            }

            // Partial results indicator
            if viewModel.correlationResults.contains(where: { $0.isPartial }) {
                let completed = viewModel.correlationResults.count
                Text("Based on partial analysis (\(completed) habits)")
                    .typography(.bodySmall)
                    .foregroundStyle(DailyArcTokens.textTertiary)
                    .padding(.horizontal, DailyArcSpacing.lg)
            }

            // Multiple comparisons disclaimer
            if viewModel.correlationResults.count >= 3 {
                Text("We analyzed \(viewModel.correlationResults.count) habits. Some patterns may be coincidental \u{2014} look for ones that match your experience.")
                    .typography(.caption)
                    .foregroundStyle(DailyArcTokens.textTertiary)
                    .padding(.horizontal, DailyArcSpacing.lg)
            }

            // Suggestions section
            if !viewModel.suggestions.isEmpty {
                VStack(alignment: .leading, spacing: DailyArcSpacing.sm) {
                    Text("Suggestions")
                        .typography(.titleSmall)
                        .foregroundStyle(DailyArcTokens.textPrimary)
                        .padding(.horizontal, DailyArcSpacing.lg)
                        .padding(.top, DailyArcSpacing.sm)

                    ForEach(viewModel.suggestions) { suggestion in
                        SuggestionCardView(suggestion: suggestion)
                            .padding(.horizontal, DailyArcSpacing.lg)
                    }
                }
            }

            // Mental health disclaimer (Apple Guideline 1.4.1)
            Text("These are statistical patterns, not medical advice. If you have mental health concerns, please consult a healthcare professional.")
                .typography(.caption)
                .foregroundStyle(DailyArcTokens.textTertiary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, DailyArcSpacing.lg)
                .padding(.top, DailyArcSpacing.sm)
        }
    }

    // MARK: - Insight Teaser (Pre-14 days)

    private var insightTeaserCard: some View {
        VStack(spacing: DailyArcSpacing.md) {
            HStack {
                Image(systemName: "lock.fill")
                    .font(.caption)
                    .foregroundStyle(DailyArcTokens.textTertiary)
                Text("Preview")
                    .typography(.caption)
                    .foregroundStyle(DailyArcTokens.textTertiary)
                Spacer()
            }

            HStack(spacing: DailyArcSpacing.sm) {
                Text("\u{1F3C3}")
                    .font(.title3)
                VStack(alignment: .leading, spacing: DailyArcSpacing.xxs) {
                    Text("On exercise days, users average mood 4.2 vs 3.1 on skip days")
                        .typography(.bodySmall)
                        .foregroundStyle(DailyArcTokens.textSecondary)
                    Text("Sample data \u{2014} your real insights unlock soon")
                        .typography(.caption)
                        .foregroundStyle(DailyArcTokens.textTertiary)
                }
            }
        }
        .padding(DailyArcSpacing.lg)
        .background(
            RoundedRectangle(cornerRadius: DailyArcTokens.cornerRadiusMedium)
                .fill(DailyArcTokens.backgroundSecondary.opacity(0.5))
        )
        .padding(.horizontal, DailyArcSpacing.lg)
    }

    // MARK: - Free User Insight Teaser (Post-14 days, not premium)

    private var freeUserInsightTeaser: some View {
        VStack(spacing: DailyArcSpacing.xl) {
            // Show the single strongest correlation as a freebie
            if let topResult = viewModel.correlationResults.first {
                VStack(alignment: .leading, spacing: DailyArcSpacing.sm) {
                    Text("Your strongest pattern")
                        .typography(.titleSmall)
                        .foregroundStyle(DailyArcTokens.textPrimary)

                    CorrelationCardView(result: topResult)
                }
                .padding(.horizontal, DailyArcSpacing.lg)
            } else {
                // Correlations still computing or empty
                VStack(spacing: DailyArcSpacing.md) {
                    Image(systemName: "chart.line.uptrend.xyaxis")
                        .font(.system(size: 40))
                        .foregroundStyle(DailyArcTokens.accent)

                    Text("Your data is ready!")
                        .typography(.titleMedium)
                        .foregroundStyle(DailyArcTokens.textPrimary)

                    Text("14+ days of paired mood and habit data \u{2014} your insights are waiting.")
                        .typography(.bodySmall)
                        .foregroundStyle(DailyArcTokens.textSecondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, DailyArcSpacing.xl)
                }
            }

            // Paywall CTA
            VStack(spacing: DailyArcSpacing.md) {
                Text("Want to see all your insights?")
                    .typography(.bodySmall)
                    .foregroundStyle(DailyArcTokens.textSecondary)

                Button {
                    showPaywall = true
                } label: {
                    HStack {
                        Image(systemName: "crown.fill")
                            .foregroundStyle(DailyArcTokens.premiumGold)
                        Text("See all insights")
                    }
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .padding(.horizontal, DailyArcSpacing.xxl)
            }
            .padding(DailyArcSpacing.lg)
            .background(
                RoundedRectangle(cornerRadius: DailyArcTokens.cornerRadiusMedium)
                    .fill(DailyArcTokens.backgroundSecondary)
            )
            .padding(.horizontal, DailyArcSpacing.lg)

            // Free suggestions (limited set)
            if !viewModel.suggestions.isEmpty {
                let freeSuggestions = viewModel.suggestions.prefix(4)
                VStack(alignment: .leading, spacing: DailyArcSpacing.sm) {
                    Text("Suggestions")
                        .typography(.titleSmall)
                        .foregroundStyle(DailyArcTokens.textPrimary)
                        .padding(.horizontal, DailyArcSpacing.lg)

                    ForEach(Array(freeSuggestions)) { suggestion in
                        SuggestionCardView(suggestion: suggestion)
                            .padding(.horizontal, DailyArcSpacing.lg)
                    }
                }
            }
        }
    }

    // MARK: - Empty State

    private var emptyHabitsState: some View {
        VStack(spacing: DailyArcSpacing.md) {
            Image(systemName: "chart.bar")
                .font(.system(size: 32))
                .foregroundStyle(DailyArcTokens.textTertiary)

            Text("Create habits to see your stats here")
                .typography(.bodySmall)
                .foregroundStyle(DailyArcTokens.textSecondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, DailyArcSpacing.xxxl)
    }
}

#Preview {
    NavigationStack {
        StatsView()
    }
    .modelContainer(for: [Habit.self, HabitLog.self, MoodEntry.self, DailySummary.self], inMemory: true)
}
