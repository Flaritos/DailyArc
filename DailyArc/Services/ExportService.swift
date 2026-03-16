import Foundation
import SwiftData

// MARK: - DTO Structs

/// Data Transfer Objects break @Relationship circular references for Codable encoding.
/// Explicit Sendable conformance for crossing actor boundaries via Task.detached.

struct HabitDTO: Codable, Sendable {
    let id: UUID
    let name: String
    let emoji: String
    let colorIndex: Int
    let frequencyRaw: Int
    let customDays: String
    let targetCount: Int
    let reminderEnabled: Bool
    let reminderTime: Date?
    let startDate: Date
    let isArchived: Bool
    let sortOrder: Int
    let currentStreak: Int
    let bestStreak: Int
    let createdAt: Date
}

struct HabitLogDTO: Codable, Sendable {
    let id: UUID
    let habitID: UUID
    let date: Date
    let count: Int
    let notes: String
    let isAutoLogged: Bool
    let isRecovered: Bool
    let createdAt: Date
}

struct MoodEntryDTO: Codable, Sendable {
    let id: UUID
    let date: Date
    let moodScore: Int
    let energyScore: Int
    let activities: String
    let notes: String
    let createdAt: Date
}

struct DailyArcExportPayload: Codable, Sendable {
    let schemaVersion: Int
    let exportDate: Date
    let habits: [HabitDTO]
    let habitLogs: [HabitLogDTO]
    let moodEntries: [MoodEntryDTO]
}

// MARK: - Export Event & Import Types

/// Event stream for progress-reporting JSON export.
enum ExportEvent: Sendable {
    case progress(Double)
    case completed(Data)
    case failed(any Error & Sendable)
}

/// Merge strategy for import operations.
enum ImportMergeMode: Sendable {
    case skipExisting
    case overwrite
}

/// Result summary after an import operation.
struct ImportResult: Sendable {
    let habitsImported: Int
    let logsImported: Int
    let moodsImported: Int
    let skipped: Int
}

// MARK: - ExportService

/// JSON and CSV export of all habits, logs, and moods.
/// Free users get JSON export (GDPR Article 20 -- right to data portability).
/// Conversion to DTOs happens on @MainActor BEFORE dispatching to Task.detached.
@MainActor
final class ExportService {

    static let shared = ExportService()

    private init() {}

    // MARK: - DTO Conversion Helpers

    /// Convert @Model arrays to Sendable DTOs on @MainActor.
    /// Shared by all export methods to avoid duplicating conversion logic.
    private func convertToDTOs(
        habits: [Habit],
        logs: [HabitLog],
        moods: [MoodEntry]
    ) -> (habits: [HabitDTO], logs: [HabitLogDTO], moods: [MoodEntryDTO]) {
        let habitDTOs = habits.map { habit in
            HabitDTO(
                id: habit.id,
                name: habit.name,
                emoji: habit.emoji,
                colorIndex: habit.colorIndex,
                frequencyRaw: habit.frequencyRaw,
                customDays: habit.customDays,
                targetCount: habit.targetCount,
                reminderEnabled: habit.reminderEnabled,
                reminderTime: habit.reminderTime,
                startDate: habit.startDate,
                isArchived: habit.isArchived,
                sortOrder: habit.sortOrder,
                currentStreak: habit.currentStreak,
                bestStreak: habit.bestStreak,
                createdAt: habit.createdAt
            )
        }

        let logDTOs = logs.compactMap { log -> HabitLogDTO? in
            // Exclude HealthKit auto-logged entries per Apple guidelines
            guard !log.isAutoLogged else { return nil }
            return HabitLogDTO(
                id: log.id,
                habitID: log.habitIDDenormalized,
                date: log.date,
                count: log.count,
                notes: log.notes,
                isAutoLogged: log.isAutoLogged,
                isRecovered: log.isRecovered,
                createdAt: log.createdAt
            )
        }

        let moodDTOs = moods.map { mood in
            MoodEntryDTO(
                id: mood.id,
                date: mood.date,
                moodScore: mood.moodScore,
                energyScore: mood.energyScore,
                activities: mood.activities,
                notes: mood.notes,
                createdAt: mood.createdAt
            )
        }

        return (habitDTOs, logDTOs, moodDTOs)
    }

    // MARK: - JSON Export

    /// Export all data as JSON. Returns encoded Data suitable for sharing.
    /// Must be called from @MainActor since it reads @Model objects.
    func exportToJSON(
        habits: [Habit],
        logs: [HabitLog],
        moods: [MoodEntry]
    ) async throws -> Data {
        let dtos = convertToDTOs(habits: habits, logs: logs, moods: moods)

        let payload = DailyArcExportPayload(
            schemaVersion: 1,
            exportDate: Date(),
            habits: dtos.habits,
            habitLogs: dtos.logs,
            moodEntries: dtos.moods
        )

        // Encode on detached task to avoid blocking UI
        let data = try await Task.detached { @Sendable in
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
            return try encoder.encode(payload)
        }.value

        return data
    }

    // MARK: - JSON Export with Progress

    /// Export all data as JSON with progress reporting via AsyncStream.
    /// Emits `.progress(0.0...1.0)` during DTO conversion and encoding,
    /// then `.completed(Data)` on success or `.failed(Error)` on failure.
    func exportToJSONWithProgress(
        habits: [Habit],
        logs: [HabitLog],
        moods: [MoodEntry]
    ) -> AsyncStream<ExportEvent> {
        // Capture DTOs on @MainActor before entering the stream
        let dtos = convertToDTOs(habits: habits, logs: logs, moods: moods)

        return AsyncStream { continuation in
            continuation.yield(.progress(0.1))

            let payload = DailyArcExportPayload(
                schemaVersion: 1,
                exportDate: Date(),
                habits: dtos.habits,
                habitLogs: dtos.logs,
                moodEntries: dtos.moods
            )

            continuation.yield(.progress(0.5))

            Task.detached { @Sendable in
                do {
                    let encoder = JSONEncoder()
                    encoder.dateEncodingStrategy = .iso8601
                    encoder.outputFormatting = [.prettyPrinted, .sortedKeys]

                    continuation.yield(.progress(0.8))

                    let data = try encoder.encode(payload)

                    continuation.yield(.progress(1.0))
                    continuation.yield(.completed(data))
                } catch {
                    continuation.yield(.failed(error))
                }
                continuation.finish()
            }
        }
    }

    // MARK: - CSV Export

    /// Export data as flat CSV. One row per habit-log per day.
    /// Columns: Date, HabitName, HabitEmoji, Count, TargetCount, MoodScore, EnergyScore, Activities, Notes
    func exportToCSV(
        habits: [Habit],
        logs: [HabitLog],
        moods: [MoodEntry]
    ) async throws -> Data {
        let dtos = convertToDTOs(habits: habits, logs: logs, moods: moods)

        // Build lookup maps on detached task
        let data = try await Task.detached { @Sendable () -> Data in
            // Index habits by ID for fast lookup
            let habitsByID = Dictionary(uniqueKeysWithValues: dtos.habits.map { ($0.id, $0) })

            // Index moods by normalized date string for joining
            let dateFormatter = ISO8601DateFormatter()
            dateFormatter.formatOptions = [.withFullDate]
            let moodsByDate = Dictionary(
                dtos.moods.map { (dateFormatter.string(from: $0.date), $0) },
                uniquingKeysWith: { first, _ in first }
            )

            // CSV header
            var csv = "Date,HabitName,HabitEmoji,Count,TargetCount,MoodScore,EnergyScore,Activities,Notes\n"

            // One row per log entry, joined with habit metadata and mood for that day
            for log in dtos.logs {
                let habit = habitsByID[log.habitID]
                let dateKey = dateFormatter.string(from: log.date)
                let mood = moodsByDate[dateKey]

                let dateStr = dateFormatter.string(from: log.date)
                let habitName = Self.csvEscape(habit?.name ?? "Unknown")
                let habitEmoji = Self.csvEscape(habit?.emoji ?? "")
                let count = log.count
                let targetCount = habit?.targetCount ?? 1
                let moodScore = mood?.moodScore ?? 0
                let energyScore = mood?.energyScore ?? 0
                let activities = Self.csvEscape(mood?.activities.replacingOccurrences(of: "|", with: ", ") ?? "")
                let notes = Self.csvEscape(log.notes)

                csv += "\(dateStr),\(habitName),\(habitEmoji),\(count),\(targetCount),\(moodScore),\(energyScore),\(activities),\(notes)\n"
            }

            guard let csvData = csv.data(using: .utf8) else {
                throw ExportError.encodingFailed
            }
            return csvData
        }.value

        return data
    }

    /// Escape a string for CSV: wrap in quotes if it contains commas, quotes, or newlines.
    nonisolated private static func csvEscape(_ value: String) -> String {
        let needsQuoting = value.contains(",") || value.contains("\"") || value.contains("\n") || value.contains("\r")
        if needsQuoting {
            let escaped = value.replacingOccurrences(of: "\"", with: "\"\"")
            return "\"\(escaped)\""
        }
        return value
    }

    // MARK: - JSON Import

    /// Import data from a DailyArc JSON export into the given ModelContext.
    /// - Parameters:
    ///   - data: Raw JSON data from a previous export
    ///   - context: The SwiftData ModelContext to insert into
    ///   - mergeMode: `.skipExisting` ignores records with matching IDs; `.overwrite` replaces them
    /// - Returns: An `ImportResult` summarizing what was imported
    func importFromJSON(
        data: Data,
        context: ModelContext,
        mergeMode: ImportMergeMode
    ) async throws -> ImportResult {
        // Decode on detached task
        let payload = try await Task.detached { @Sendable () -> DailyArcExportPayload in
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            return try decoder.decode(DailyArcExportPayload.self, from: data)
        }.value

        // Insert into context on @MainActor
        var habitsImported = 0
        var logsImported = 0
        var moodsImported = 0
        var skipped = 0

        // Build existing ID sets for duplicate detection
        let existingHabitIDs = try fetchExistingIDs(for: Habit.self, context: context)
        let existingLogIDs = try fetchExistingIDs(for: HabitLog.self, context: context)
        let existingMoodIDs = try fetchExistingIDs(for: MoodEntry.self, context: context)

        // Import habits
        for dto in payload.habits {
            if existingHabitIDs.contains(dto.id) {
                switch mergeMode {
                case .skipExisting:
                    skipped += 1
                    continue
                case .overwrite:
                    // Delete existing before re-inserting
                    if let existing = try fetchByID(dto.id, type: Habit.self, context: context) {
                        context.delete(existing)
                    }
                }
            }

            let habit = Habit(
                id: dto.id,
                name: dto.name,
                emoji: dto.emoji,
                colorIndex: dto.colorIndex,
                frequencyRaw: dto.frequencyRaw,
                customDays: dto.customDays,
                targetCount: dto.targetCount,
                reminderTime: dto.reminderTime,
                reminderEnabled: dto.reminderEnabled,
                startDate: dto.startDate,
                isArchived: dto.isArchived,
                sortOrder: dto.sortOrder,
                currentStreak: dto.currentStreak,
                bestStreak: dto.bestStreak,
                createdAt: dto.createdAt
            )
            context.insert(habit)
            habitsImported += 1
        }

        // Import habit logs
        for dto in payload.habitLogs {
            if existingLogIDs.contains(dto.id) {
                switch mergeMode {
                case .skipExisting:
                    skipped += 1
                    continue
                case .overwrite:
                    if let existing = try fetchByID(dto.id, type: HabitLog.self, context: context) {
                        context.delete(existing)
                    }
                }
            }

            let log = HabitLog(
                id: dto.id,
                date: dto.date,
                count: dto.count,
                notes: dto.notes,
                isAutoLogged: dto.isAutoLogged,
                isRecovered: dto.isRecovered,
                createdAt: dto.createdAt
            )
            log.habitIDDenormalized = dto.habitID
            // Attempt to link to parent habit
            if let parentHabit = try fetchByID(dto.habitID, type: Habit.self, context: context) {
                log.habit = parentHabit
            }
            context.insert(log)
            logsImported += 1
        }

        // Import mood entries
        for dto in payload.moodEntries {
            if existingMoodIDs.contains(dto.id) {
                switch mergeMode {
                case .skipExisting:
                    skipped += 1
                    continue
                case .overwrite:
                    if let existing = try fetchByID(dto.id, type: MoodEntry.self, context: context) {
                        context.delete(existing)
                    }
                }
            }

            let mood = MoodEntry(
                id: dto.id,
                date: dto.date,
                moodScore: dto.moodScore,
                energyScore: dto.energyScore,
                activities: dto.activities,
                notes: dto.notes,
                createdAt: dto.createdAt
            )
            context.insert(mood)
            moodsImported += 1
        }

        try context.save()

        return ImportResult(
            habitsImported: habitsImported,
            logsImported: logsImported,
            moodsImported: moodsImported,
            skipped: skipped
        )
    }

    // MARK: - Import Helpers

    /// Fetch all existing UUIDs for a model type to check for duplicates.
    private func fetchExistingIDs<T: PersistentModel>(
        for type: T.Type,
        context: ModelContext
    ) throws -> Set<UUID> {
        let descriptor = FetchDescriptor<T>()
        let models = try context.fetch(descriptor)
        // Access `id` via key path — all our models have `var id: UUID`
        let ids = models.compactMap { model -> UUID? in
            let mirror = Mirror(reflecting: model)
            return mirror.children.first(where: { $0.label == "id" })?.value as? UUID
        }
        return Set(ids)
    }

    /// Fetch a single model by UUID.
    private func fetchByID<T: PersistentModel>(
        _ id: UUID,
        type: T.Type,
        context: ModelContext
    ) throws -> T? {
        var descriptor = FetchDescriptor<T>()
        descriptor.fetchLimit = 1
        // We can't use #Predicate with generic T, so fetch all and filter
        // For small datasets this is acceptable; for large datasets consider type-specific methods
        let all = try context.fetch(descriptor)
        return all.first { model in
            let mirror = Mirror(reflecting: model)
            return (mirror.children.first(where: { $0.label == "id" })?.value as? UUID) == id
        }
    }
}

// MARK: - Export Errors

enum ExportError: LocalizedError, Sendable {
    case encodingFailed

    var errorDescription: String? {
        switch self {
        case .encodingFailed:
            return "Failed to encode export data."
        }
    }
}
