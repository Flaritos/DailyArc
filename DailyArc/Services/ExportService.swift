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

// MARK: - ExportService

/// JSON export of all habits, logs, and moods.
/// Free users get JSON export (GDPR Article 20 — right to data portability).
/// Conversion to DTOs happens on @MainActor BEFORE dispatching to Task.detached.
@MainActor
final class ExportService {

    static let shared = ExportService()

    private init() {}

    /// Export all data as JSON. Returns encoded Data suitable for sharing.
    /// Must be called from @MainActor since it reads @Model objects.
    func exportToJSON(
        habits: [Habit],
        logs: [HabitLog],
        moods: [MoodEntry]
    ) async throws -> Data {
        // Convert @Model to DTOs on @MainActor
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

        let payload = DailyArcExportPayload(
            schemaVersion: 1,
            exportDate: Date(),
            habits: habitDTOs,
            habitLogs: logDTOs,
            moodEntries: moodDTOs
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
}
