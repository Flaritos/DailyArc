import SwiftUI
import SwiftData

/// List of all habits with reorder, archive/unarchive, and delete.
struct HabitManagementView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.colorScheme) private var colorScheme
    @Query(sort: \Habit.sortOrder) private var allHabits: [Habit]

    @State private var showArchived = false
    @State private var editingHabit: Habit?
    @State private var habitToDelete: Habit?
    @State private var showDeleteConfirmation = false

    private var activeHabits: [Habit] {
        allHabits.filter { !$0.isArchived }
    }

    private var archivedHabits: [Habit] {
        allHabits.filter { $0.isArchived }
    }

    var body: some View {
        List {
            // Active Habits
            Section {
                ForEach(activeHabits) { habit in
                    habitRow(habit)
                        .swipeActions(edge: .trailing) {
                            Button {
                                archiveHabit(habit)
                            } label: {
                                Label("Archive", systemImage: "archivebox")
                            }
                            .tint(.orange)

                            Button(role: .destructive) {
                                habitToDelete = habit
                                showDeleteConfirmation = true
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                        }
                        .swipeActions(edge: .leading) {
                            Button {
                                editingHabit = habit
                            } label: {
                                Label("Edit", systemImage: "pencil")
                            }
                            .tint(DailyArcTokens.accent)
                        }
                }
                .onMove(perform: moveHabits)
            } header: {
                Text("Active Habits")
            }

            // Archived Habits
            if showArchived && !archivedHabits.isEmpty {
                Section {
                    ForEach(archivedHabits) { habit in
                        habitRow(habit)
                            .opacity(0.6)
                            .swipeActions(edge: .trailing) {
                                Button {
                                    unarchiveHabit(habit)
                                } label: {
                                    Label("Unarchive", systemImage: "arrow.uturn.backward")
                                }
                                .tint(DailyArcTokens.success)

                                Button(role: .destructive) {
                                    habitToDelete = habit
                                    showDeleteConfirmation = true
                                } label: {
                                    Label("Delete", systemImage: "trash")
                                }
                            }
                    }
                } header: {
                    Text("Archived")
                }
            }

            // Toggle archived visibility
            Section {
                Toggle("Show Archived", isOn: $showArchived)
                    .typography(.bodyLarge)
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle("Manage Habits")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                EditButton()
            }
        }
        .sheet(item: $editingHabit) { habit in
            HabitFormView(mode: .edit(habit))
        }
        .alert("Delete Habit?", isPresented: $showDeleteConfirmation) {
            Button("Cancel", role: .cancel) {
                habitToDelete = nil
            }
            Button("Delete", role: .destructive) {
                if let habit = habitToDelete {
                    deleteHabit(habit)
                }
                habitToDelete = nil
            }
        } message: {
            if let habit = habitToDelete {
                Text("Delete \(habit.emoji) \(habit.name)? This will permanently delete all log data for this habit.")
            }
        }
    }

    // MARK: - Row

    private func habitRow(_ habit: Habit) -> some View {
        HStack(spacing: DailyArcSpacing.md) {
            Text(habit.emoji)
                .font(.title2)

            VStack(alignment: .leading, spacing: DailyArcSpacing.xxs) {
                Text(habit.name)
                    .typography(.bodyLarge)
                    .foregroundStyle(DailyArcTokens.textPrimary)

                HStack(spacing: DailyArcSpacing.xs) {
                    if habit.currentStreak > 0 {
                        HStack(spacing: 2) {
                            Text("\u{1F525}")
                                .font(.caption2)
                            Text("\(habit.currentStreak)")
                                .typography(.caption)
                                .foregroundStyle(DailyArcTokens.streakFire)
                        }
                    }
                    Text(frequencyLabel(for: habit))
                        .typography(.caption)
                        .foregroundStyle(DailyArcTokens.textTertiary)
                }
            }

            Spacer()

            if habit.isArchived {
                Image(systemName: "archivebox.fill")
                    .foregroundStyle(DailyArcTokens.textTertiary)
                    .font(.caption)
            }
        }
        .padding(.vertical, DailyArcSpacing.xs)
        .contentShape(Rectangle())
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(habit.emoji) \(habit.name), streak \(habit.currentStreak) days\(habit.isArchived ? ", archived" : "")")
    }

    // MARK: - Actions

    private func moveHabits(from source: IndexSet, to destination: Int) {
        var sorted = activeHabits
        sorted.move(fromOffsets: source, toOffset: destination)
        for (index, habit) in sorted.enumerated() {
            habit.sortOrder = index
        }
        try? modelContext.save()
    }

    private func archiveHabit(_ habit: Habit) {
        habit.isArchived = true
        try? modelContext.save()
    }

    private func unarchiveHabit(_ habit: Habit) {
        habit.isArchived = false
        try? modelContext.save()
    }

    private func deleteHabit(_ habit: Habit) {
        modelContext.delete(habit)
        try? modelContext.save()
    }

    private func frequencyLabel(for habit: Habit) -> String {
        switch habit.frequency {
        case .daily: return "Daily"
        case .weekdays: return "Weekdays"
        case .weekends: return "Weekends"
        case .custom: return "Custom"
        }
    }
}

#Preview {
    NavigationStack {
        HabitManagementView()
    }
    .modelContainer(for: Habit.self, inMemory: true)
}
