# DailyArc MVP Implementation Plan

## Phase 1: Xcode Project + Data Models (Step 1a)

**Create Xcode project** via command line, then implement:

1. **DailyArcSchemaV1.swift** — VersionedSchema enum containing all @Model classes:
   - Habit (18 properties), HabitLog (9 properties), MoodEntry (8 properties), DailySummary (5 properties)
   - All with computed properties, HabitFrequency enum, fetchOrCreate statics
   - #Index macros on HabitLog and MoodEntry
   - Typealiases at module scope

2. **HabitColorPalette.swift** — 10 colors with light/dark hex pairs

3. **DailyArcTokens.swift** — Semantic colors, typography ViewModifiers, spacing enum

4. **DateHelpers.swift** — shouldAppear(on:), startOfDay normalization

5. **Color+Hex.swift** — Color(hex:) initializer, Color(light:dark:) adaptive init

6. **DailyArcApp.swift** — ModelContainer setup with autosaveEnabled=false, tab persistence

7. **ContentView.swift** — 3-tab TabView with NavigationStacks

**Verification:** Project compiles, models create in-memory, DateHelpers tests pass

## Phase 2: Services Layer (Step 1b)

1. **StreakEngine.swift** — @MainActor, recalculateStreaks, computeBestStreak, streakRecoveryAvailable
2. **DebouncedSave.swift** — 300ms debounce, trigger(), triggerImmediate(), flush()
3. **HabitLogWriteActor.swift** — @ModelActor single write path, saveLog(), saveMood()
4. **RuleEngine.swift** — generateSuggestions with 6+ rules
5. **DedupService.swift** — 30-day scan, sorted-walk dedup

**Verification:** StreakEngine unit tests pass, DebouncedSave compiles

## Phase 3: Today View (Step 2)

1. **TodayViewModel.swift** — @Observable @MainActor, fetchLogsForDate
2. **TodayView.swift** — Main dashboard with @Query for habits, date navigation
3. **DateNavigationBar.swift** — Left/right arrows, center date label, long-press calendar
4. **MoodCheckInView.swift** — 5 emoji circles (60pt), auto-save
5. **EnergyPickerView.swift** — 5 circles (44pt), auto-save
6. **HabitRowView.swift** — Toggle/stepper based on targetCount, swipe actions
7. **HabitListView.swift** — Filtered by shouldAppear, sorted by sortOrder
8. **CompletionCircleView.swift** — 270-degree arc, proportional fill
9. **CelebrationOverlay.swift** — Canvas confetti (50 particles)
10. **EmptyStateView.swift** — "No habits yet" with add button

**Verification:** Can view Today tab, tap habits, log mood, see streaks update

## Phase 4: Habit Form (Step 3)

1. **HabitFormViewModel.swift** — Form state, validation, save logic
2. **HabitFormView.swift** — 2-step form (Details/Schedule → Reminders)
3. **EmojiPickerView.swift** — 8x6 grid
4. **HabitManagementView.swift** — Reorder, archive/unarchive list
5. **HabitTemplatesView.swift** — 8 one-tap templates for onboarding

**Verification:** Can add/edit/archive habits, free tier enforces 3-habit limit

## Phase 5: Stats View (Step 4)

1. **StatsViewModel.swift** — DaySnapshot computation, mood trend data
2. **StatsView.swift** — Segmented control ("Your Arc" | "Insights" locked)
3. **HeatMapCanvasView.swift** — Canvas 365-cell grid, horizontal scroll
4. **MoodTrendView.swift** — Swift Charts LineMark, 30-day trend
5. **PerHabitCardView.swift** — LazyVGrid 2-column cards with streaks
6. **PerHabitDetailView.swift** — Drill-down with monthly bar charts
7. **DaySnapshot.swift** — Computed struct, batch computation

**Verification:** Heat map renders <100ms, mood chart shows data, drill-down works

## Phase 6: Polish + Sim Launch

1. Add DebugDataGenerator for synthetic test data (30 days)
2. Wire up navigation between all views
3. Test in Simulator: full flow from launch → add habit → log → view stats
4. Dark mode verification
