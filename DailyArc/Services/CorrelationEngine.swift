import Foundation

/// Caseless enum — implicitly Sendable, no instances. All computation via static methods.
/// Handles Pearson correlation between habits and mood scores.
/// CRITICAL: @Model objects are NOT Sendable. Extract data into plain Sendable structs
/// on @MainActor BEFORE dispatching to Task.detached.
enum CorrelationEngine {

    // MARK: - Sendable Input Types

    struct HabitSnapshot: Sendable {
        let id: UUID
        let name: String
        let emoji: String
        let targetCount: Int
        let frequencyRaw: Int
        let customDays: String
        let startDate: Date
        let logs: [LogSnapshot]
    }

    struct LogSnapshot: Sendable {
        let date: Date
        let count: Int
    }

    struct MoodSnapshot: Sendable {
        let date: Date
        let moodScore: Int
        let energyScore: Int
    }

    // MARK: - Sendable Output

    struct CorrelationResult: Identifiable, Sendable, Equatable {
        let id: UUID
        let habitName: String
        let emoji: String
        let coefficient: Double // -1.0 to 1.0
        let label: String // "Strong positive", "Moderate positive", etc.
        let averageMoodOnHabitDays: Double
        let averageMoodOnSkipDays: Double
        let sampleSize: Int
        let isPartial: Bool
    }

    // MARK: - Constants

    private static let minimumPairedDays = 14
    private static let maxHabits = 10

    // MARK: - Snapshot Extraction (call on @MainActor)

    @MainActor
    static func extractSnapshots(
        habits: [Habit],
        allLogs: [HabitLog],
        moods: [MoodEntry]
    ) -> ([HabitSnapshot], [MoodSnapshot]) {
        let logsByHabitID = Dictionary(grouping: allLogs.filter { !$0.isRecovered }) { $0.habitIDDenormalized }

        let habitSnapshots = habits.map { habit in
            let logs = logsByHabitID[habit.id] ?? []
            return HabitSnapshot(
                id: habit.id,
                name: habit.name,
                emoji: habit.emoji,
                targetCount: habit.targetCount,
                frequencyRaw: habit.frequencyRaw,
                customDays: habit.customDays,
                startDate: habit.startDate,
                logs: logs.map { LogSnapshot(date: $0.date, count: $0.count) }
            )
        }

        let moodSnapshots = moods.map {
            MoodSnapshot(date: $0.date, moodScore: $0.moodScore, energyScore: $0.energyScore)
        }

        return (habitSnapshots, moodSnapshots)
    }

    // MARK: - Correlation Computation (call via Task.detached)

    /// Pure computation on Sendable data. 500ms timeout with partial results.
    /// Caps at top 10 most-recently-active habits. Filters out habits with <14 days of data.
    static func computeCorrelations(
        habits: [HabitSnapshot],
        moods: [MoodSnapshot],
        calendar: Calendar
    ) -> [CorrelationResult] {
        let clock = ContinuousClock()
        let deadline = clock.now + .milliseconds(500)

        // Build mood lookup by date
        let moodByDate = Dictionary(grouping: moods) { calendar.startOfDay(for: $0.date) }

        // Sort habits by most-recently-active (latest log date descending), cap at 10
        let sortedHabits = habits
            .sorted { a, b in
                let aLatest = a.logs.map(\.date).max() ?? .distantPast
                let bLatest = b.logs.map(\.date).max() ?? .distantPast
                return aLatest > bLatest
            }
            .prefix(maxHabits)

        let totalHabits = sortedHabits.count
        var results: [CorrelationResult] = []
        var isPartial = false

        for habit in sortedHabits {
            // Check cancellation between habit iterations
            guard !Task.isCancelled else { break }

            // Check 500ms timeout
            if clock.now >= deadline {
                isPartial = true
                break
            }

            let habitLogsByDate = Dictionary(
                grouping: habit.logs,
                by: { calendar.startOfDay(for: $0.date) }
            )

            var habitValues: [Double] = []
            var moodValues: [Double] = []

            var iterationCount = 0
            for (date, moodEntries) in moodByDate {
                iterationCount += 1
                if iterationCount % 50 == 0, Task.isCancelled { break }

                guard let mood = moodEntries.first, mood.moodScore >= 1, mood.moodScore <= 5 else { continue }
                // Skip dates before this habit existed
                guard date >= habit.startDate else { continue }
                // Only consider applicable days for this habit's frequency
                guard DateHelpers.shouldAppear(
                    on: date,
                    frequencyRaw: habit.frequencyRaw,
                    customDays: habit.customDays,
                    calendar: calendar
                ) else { continue }

                let habitCount = habitLogsByDate[date]?.first?.count ?? 0
                let habitValue = Double(min(habitCount, habit.targetCount))
                habitValues.append(habitValue)
                moodValues.append(Double(mood.moodScore))
            }

            // Require minimum paired days
            guard habitValues.count >= minimumPairedDays else { continue }

            // Class imbalance guard: need at least 3 in each class
            let target = Double(habit.targetCount)
            let completedCount = habitValues.filter { $0 >= target }.count
            let skippedCount = habitValues.filter { $0 < target }.count
            guard completedCount >= 3, skippedCount >= 3 else { continue }

            guard let coefficient = pearsonCorrelation(x: habitValues, y: moodValues) else { continue }

            // Compute average mood on habit days vs skip days
            let habitDayMoods = zip(habitValues, moodValues).filter { $0.0 >= target }.map(\.1)
            let skipDayMoods = zip(habitValues, moodValues).filter { $0.0 < target }.map(\.1)

            let avgHabit = habitDayMoods.isEmpty ? 0 : habitDayMoods.reduce(0, +) / Double(habitDayMoods.count)
            let avgSkip = skipDayMoods.isEmpty ? 0 : skipDayMoods.reduce(0, +) / Double(skipDayMoods.count)

            let strengthLabel: String
            switch abs(coefficient) {
            case 0.5...: strengthLabel = coefficient > 0 ? "Strong positive" : "Strong negative"
            case 0.3..<0.5: strengthLabel = coefficient > 0 ? "Moderate positive" : "Moderate negative"
            case 0.15..<0.3: strengthLabel = coefficient > 0 ? "Mild positive" : "Mild negative"
            default: strengthLabel = "No clear link"
            }

            results.append(CorrelationResult(
                id: UUID(),
                habitName: habit.name,
                emoji: habit.emoji,
                coefficient: coefficient,
                label: strengthLabel,
                averageMoodOnHabitDays: avgHabit,
                averageMoodOnSkipDays: avgSkip,
                sampleSize: habitValues.count,
                isPartial: isPartial
            ))
        }

        // Mark all as partial if we timed out
        if isPartial {
            results = results.map { r in
                CorrelationResult(
                    id: r.id, habitName: r.habitName, emoji: r.emoji,
                    coefficient: r.coefficient, label: r.label,
                    averageMoodOnHabitDays: r.averageMoodOnHabitDays,
                    averageMoodOnSkipDays: r.averageMoodOnSkipDays,
                    sampleSize: r.sampleSize, isPartial: true
                )
            }
        }

        // Sort by absolute coefficient descending
        return results.sorted { abs($0.coefficient) > abs($1.coefficient) }
    }

    // MARK: - Confidence Qualifier

    static func confidenceQualifier(sampleSize: Int) -> String? {
        switch sampleSize {
        case ..<14: return nil
        case 14..<30: return "Based on limited data"
        case 30..<60: return "Early pattern"
        default: return nil
        }
    }

    // MARK: - Significance Test

    static func isSignificant(r: Double, n: Int, alpha: Double = 0.05) -> Bool {
        guard n > 2, abs(r) < 1.0 else { return false }
        let df = Double(n - 2)
        let t = r * sqrt(df / (1.0 - r * r))

        if alpha == 0.05 {
            let exactTable: [Int: Double] = [
                10: 2.228, 11: 2.201, 12: 2.179, 13: 2.160, 14: 2.145, 15: 2.131, 16: 2.120,
                17: 2.110, 18: 2.101, 19: 2.093, 20: 2.086, 22: 2.074, 25: 2.060, 28: 2.048,
                30: 2.042, 35: 2.030, 40: 2.021, 45: 2.014, 50: 2.009
            ]
            let intDf = Int(df)
            if let cv = exactTable[intDf] {
                return abs(t) > cv
            }
            if intDf > 12 && intDf < 30 {
                let keys = exactTable.keys.sorted()
                if let lower = keys.last(where: { $0 <= intDf }),
                   let upper = keys.first(where: { $0 > intDf }),
                   let cvLower = exactTable[lower], let cvUpper = exactTable[upper] {
                    let frac = Double(intDf - lower) / Double(upper - lower)
                    let cv = cvLower + frac * (cvUpper - cvLower)
                    return abs(t) > cv
                }
            }
        }

        // Abramowitz & Stegun + Cornish-Fisher approximation
        let p = alpha / 2.0
        let a = sqrt(-2.0 * log(p))
        let zAlpha = a - (2.515517 + 0.802853 * a + 0.010328 * a * a) /
                          (1.0 + 1.432788 * a + 0.189269 * a * a + 0.001308 * a * a * a)
        let g1 = (zAlpha * zAlpha * zAlpha + zAlpha) / (4.0 * df)
        let g2 = (5.0 * pow(zAlpha, 5) + 16.0 * pow(zAlpha, 3) + 3.0 * zAlpha) / (96.0 * df * df)
        let cv = zAlpha + g1 + g2
        return abs(t) > cv
    }

    // MARK: - Paired Days Count (for progress tracking)

    /// Returns the number of days where both mood and at least one habit were logged.
    /// Used to show progress toward the 14-day insight unlock.
    @MainActor
    static func pairedDataDaysCount(moods: [MoodEntry], logs: [HabitLog], calendar: Calendar) -> Int {
        let moodDates = Set(moods.filter { $0.moodScore > 0 }.map { calendar.startOfDay(for: $0.date) })
        let logDates = Set(logs.filter { !$0.isRecovered && $0.count > 0 }.map { calendar.startOfDay(for: $0.date) })
        return moodDates.intersection(logDates).count
    }

    // MARK: - Pearson Correlation (Private)

    /// Two-pass mean-centered Pearson correlation for numerical stability.
    private static func pearsonCorrelation(x: [Double], y: [Double]) -> Double? {
        guard x.count == y.count, x.count >= minimumPairedDays else { return nil }
        let n = Double(x.count)
        let meanX = x.reduce(0, +) / n
        let meanY = y.reduce(0, +) / n
        var sumXY: Double = 0, sumX2: Double = 0, sumY2: Double = 0
        for i in x.indices {
            let dx = x[i] - meanX
            let dy = y[i] - meanY
            sumXY += dx * dy
            sumX2 += dx * dx
            sumY2 += dy * dy
        }
        guard sumX2 > 1e-6, sumY2 > 1e-6 else { return nil }
        let denominator = sqrt(sumX2 * sumY2)
        guard denominator > 1e-6 else { return nil }
        return max(-1.0, min(1.0, sumXY / denominator))
    }
}
