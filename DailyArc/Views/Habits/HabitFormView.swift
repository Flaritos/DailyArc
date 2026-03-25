import SwiftUI
import SwiftData

/// 2-step habit creation/editing form presented as a sheet.
/// Step 1: Emoji, color, name, frequency, target count.
/// Step 2: Reminder toggle + time picker, save button.
struct HabitFormView: View {
    enum Mode: Identifiable {
        case add
        case edit(Habit)

        var id: String {
            switch self {
            case .add: return "add"
            case .edit(let habit): return "edit-\(habit.id.uuidString)"
            }
        }
    }

    let mode: Mode
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.theme) private var theme
    @Query(filter: #Predicate<Habit> { !$0.isArchived }) private var activeHabits: [Habit]
    @State private var showPaywall = false

    // MARK: - Form State

    @State private var step = 1
    @State private var emoji = "\u{2705}" // checkmark default
    @State private var name = ""
    @State private var colorIndex = 5
    @State private var frequencyRaw = 0
    @State private var customDays: Set<Int> = []
    @State private var targetCount = 1
    @State private var reminderEnabled = false
    @State private var reminderTime = {
        var comps = DateComponents()
        comps.hour = 9
        comps.minute = 0
        return Calendar.current.date(from: comps) ?? Date()
    }()
    @State private var autoLogHealth = false
    @State private var healthKitType = "workouts"

    @State private var selectedTemplate: String? = nil
    @FocusState private var nameFieldFocused: Bool

    // MARK: - Template Data

    private let formTemplates: [(emoji: String, name: String, targetCount: Int)] = [
        ("\u{1F3C3}", "Exercise", 1), ("\u{1F4DA}", "Reading", 1),
        ("\u{1F9D8}", "Meditate", 1), ("\u{1F4A4}", "Sleep 8hrs", 1),
        ("\u{1F4A7}", "Drink Water", 8), ("\u{1F4DD}", "Journal", 1),
        ("\u{1F6B6}", "Walk", 1), ("\u{1F3A8}", "Creative Time", 1)
    ]

    // MARK: - Emoji Grid Data

    private let commonEmojis: [String] = [
        "\u{1F3C3}", "\u{1F4AA}", "\u{1F9D8}", "\u{1F4DA}", "\u{2708}\u{FE0F}", "\u{1F4A7}", "\u{1F34E}", "\u{1F3B5}",
        "\u{1F4BB}", "\u{1F3A8}", "\u{270D}\u{FE0F}", "\u{1F6B6}", "\u{1F6B4}", "\u{1F3CA}", "\u{2615}", "\u{1F4DD}",
        "\u{1F333}", "\u{1F31E}", "\u{1F4F5}", "\u{1F6CC}", "\u{1F9F9}", "\u{1F3AF}", "\u{1F9E0}", "\u{2764}\u{FE0F}",
        "\u{1F4B0}", "\u{1F64F}", "\u{1F60A}", "\u{1F468}\u{200D}\u{1F4BB}", "\u{1F3B8}", "\u{1F4F8}", "\u{1F37D}\u{FE0F}", "\u{1F3D3}",
        "\u{1F4F0}", "\u{1F3C0}", "\u{26BD}", "\u{1F3B3}", "\u{1F6E0}\u{FE0F}", "\u{1F30D}", "\u{1F48A}", "\u{1F3C6}",
        "\u{2B50}", "\u{1F525}", "\u{1F48E}", "\u{1F680}", "\u{1F331}", "\u{1F4A1}", "\u{1F3DD}\u{FE0F}", "\u{1F308}"
    ]

    private let dayNames = ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"]
    private let dayIndices = [1, 2, 3, 4, 5, 6, 7] // Calendar weekday values

    // MARK: - Initialization

    private var isEditing: Bool {
        if case .edit = mode { return true }
        return false
    }

    private var editingHabit: Habit? {
        if case .edit(let habit) = mode { return habit }
        return nil
    }

    /// Whether the habit name/emoji suggests a health-related category that can auto-log from HealthKit.
    private var canAutoLog: Bool {
        let keywords = ["exercise", "workout", "run", "walk", "sleep", "meditat", "mindful", "steps", "gym", "yoga", "swim", "cycle", "bike"]
        let healthEmojis = ["\u{1F3C3}", "\u{1F6B6}", "\u{1F9D8}", "\u{1F4A4}", "\u{1F6B4}", "\u{1F3CA}", "\u{1F4AA}", "\u{1F6CC}"]
        let lowerName = name.lowercased()
        let nameMatch = keywords.contains { lowerName.contains($0) }
        let emojiMatch = healthEmojis.contains(emoji)
        return nameMatch || emojiMatch
    }

    /// Whether the free tier limit is hit (5 active habits, adding a new one, not premium).
    private var isAtFreeLimit: Bool {
        if case .add = mode {
            return activeHabits.count >= 5 && !StoreKitManager.shared.isPremium
        }
        return false
    }

    var body: some View {
        if isAtFreeLimit {
            habitLimitView
                .sheet(isPresented: $showPaywall) {
                    PaywallView()
                }
        } else {
            formContent
        }
    }

    // MARK: - Habit Limit Reached

    private var habitLimitView: some View {
        NavigationStack {
            VStack(spacing: DailyArcSpacing.xl) {
                Spacer(minLength: DailyArcSpacing.lg)

                Image(systemName: "tray.full")
                    .font(.system(size: 48))
                    .foregroundStyle(DailyArcTokens.textTertiary)

                Text("You're using all your free habits")
                    .font(.system(size: 22, weight: .bold))
                    .multilineTextAlignment(.center)

                // Show current habits
                VStack(spacing: DailyArcSpacing.sm) {
                    ForEach(activeHabits) { habit in
                        HStack(spacing: DailyArcSpacing.sm) {
                            Text(habit.emoji)
                                .font(.title3)
                            Text(habit.name)
                                .typography(.bodyLarge)
                                .foregroundStyle(DailyArcTokens.textPrimary)
                            Spacer()
                        }
                        .padding(.horizontal, DailyArcSpacing.md)
                        .padding(.vertical, DailyArcSpacing.sm)
                        .background(DailyArcTokens.backgroundSecondary)
                        .clipShape(RoundedRectangle(cornerRadius: DailyArcTokens.cornerRadiusSmall))
                    }
                }
                .padding(.horizontal, DailyArcSpacing.lg)

                Spacer()

                // Archive option
                NavigationLink {
                    HabitManagementView()
                } label: {
                    Text("Archive a habit to make room")
                        .typography(.bodyLarge)
                        .fontWeight(.semibold)
                        .frame(maxWidth: .infinity, minHeight: 50)
                        .background(DailyArcTokens.accent)
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: DailyArcTokens.cornerRadiusMedium))
                }
                .padding(.horizontal, DailyArcSpacing.lg)

                // Upgrade option
                Button {
                    showPaywall = true
                } label: {
                    Text("Upgrade to unlock unlimited")
                        .typography(.bodyLarge)
                        .foregroundStyle(DailyArcTokens.accent)
                        .frame(maxWidth: .infinity, minHeight: 50)
                        .background(
                            RoundedRectangle(cornerRadius: DailyArcTokens.cornerRadiusMedium)
                                .stroke(DailyArcTokens.accent, lineWidth: 1.5)
                        )
                }
                .padding(.horizontal, DailyArcSpacing.lg)

                Spacer(minLength: DailyArcSpacing.xxl)
            }
            .background(DailyArcTokens.backgroundPrimary)
            .navigationTitle("New Habit")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }

    private var formContent: some View {
        NavigationStack {
            Group {
                if step == 1 {
                    step1View
                } else {
                    step2View
                }
            }
            .navigationTitle(isEditing ? "Edit Habit" : "New Habit")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    if step == 2 {
                        Button("Back") {
                            withAnimation { step = 1 }
                        }
                    } else {
                        Button("Cancel") { dismiss() }
                    }
                }
                if step == 1 {
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Cancel") { dismiss() }
                            .opacity(isEditing ? 0 : 0)
                    }
                }
            }
            .toolbar {
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button("Done") { nameFieldFocused = false }
                }
            }
        }
        .onAppear { populateFromEditMode() }
        .interactiveDismissDisabled(false)
    }

    // MARK: - Step 1: Details & Schedule

    private var step1View: some View {
        ScrollView {
            VStack(spacing: DailyArcSpacing.xl) {
                // Template Quick-Start (Add mode only)
                if !isEditing {
                    VStack(alignment: .leading, spacing: DailyArcSpacing.sm) {
                        Text(theme.uppercaseHeaders ? "\(theme.headerPrefix)START FROM A TEMPLATE" : "Start from a template")
                            .typography(.callout)
                            .fontDesign(theme.displayFontDesign)
                            .foregroundStyle(theme.textSecondary)

                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: DailyArcSpacing.sm) {
                                ForEach(formTemplates, id: \.name) { template in
                                    let isSelected = selectedTemplate == template.name
                                    Button {
                                        selectedTemplate = template.name
                                        emoji = template.emoji
                                        name = template.name
                                        targetCount = template.targetCount
                                        frequencyRaw = 0
                                    } label: {
                                        VStack(spacing: DailyArcSpacing.xs) {
                                            Text(template.emoji)
                                                .font(.system(size: 28))
                                            Text(template.name)
                                                .font(.caption)
                                                .foregroundStyle(theme.textPrimary)
                                                .lineLimit(1)
                                        }
                                        .frame(width: 80, height: 80)
                                        .background(
                                            isSelected
                                                ? DailyArcTokens.accent.opacity(DailyArcTokens.opacityLight)
                                                : theme.backgroundSecondary
                                        )
                                        .clipShape(RoundedRectangle(cornerRadius: theme.cornerRadiusSmall))
                                        .overlay(
                                            RoundedRectangle(cornerRadius: DailyArcTokens.cornerRadiusSmall)
                                                .stroke(isSelected ? DailyArcTokens.accent : .clear, lineWidth: 2)
                                        )
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                        }
                    }

                    HStack {
                        VStack { Divider() }
                        Text("or create custom")
                            .font(.caption)
                            .foregroundStyle(theme.textTertiary)
                        VStack { Divider() }
                    }
                }

                // Emoji Picker
                VStack(alignment: .leading, spacing: DailyArcSpacing.sm) {
                    Text(theme.uppercaseHeaders ? "\(theme.headerPrefix)EMOJI" : "Emoji")
                        .typography(.callout)
                        .fontDesign(theme.displayFontDesign)
                        .foregroundStyle(theme.textSecondary)

                    LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: DailyArcSpacing.xs), count: 8), spacing: DailyArcSpacing.sm) {
                        ForEach(commonEmojis, id: \.self) { emojiOption in
                            Button {
                                emoji = emojiOption
                            } label: {
                                Text(emojiOption)
                                    .font(.title2)
                                    .frame(width: 44, height: 44)
                                    .background(
                                        emoji == emojiOption
                                            ? DailyArcTokens.accent.opacity(DailyArcTokens.opacityLight)
                                            : Color.clear
                                    )
                                    .clipShape(RoundedRectangle(cornerRadius: DailyArcTokens.cornerRadiusSmall))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: DailyArcTokens.cornerRadiusSmall)
                                            .stroke(emoji == emojiOption ? DailyArcTokens.accent : Color.clear, lineWidth: 2)
                                    )
                            }
                            .buttonStyle(.plain)
                            .accessibilityLabel("Emoji \(emojiOption)")
                        }
                    }
                }

                // Color Picker
                VStack(alignment: .leading, spacing: DailyArcSpacing.sm) {
                    Text(theme.uppercaseHeaders ? "\(theme.headerPrefix)COLOR" : "Color")
                        .typography(.callout)
                        .fontDesign(theme.displayFontDesign)
                        .foregroundStyle(theme.textSecondary)

                    HStack(spacing: DailyArcSpacing.sm) {
                        ForEach(0..<HabitColorPalette.colors.count, id: \.self) { index in
                            let entry = HabitColorPalette.colors[index]
                            let color = Color(hex: colorScheme == .dark ? entry.darkModeHex : entry.hex) ?? .blue
                            Button {
                                colorIndex = index
                            } label: {
                                ZStack {
                                    Circle()
                                        .fill(color)
                                        .frame(width: 32, height: 32)
                                    if colorIndex == index {
                                        Image(systemName: "checkmark")
                                            .font(.caption.bold())
                                            .foregroundStyle(.white)
                                    }
                                }
                                .frame(width: 44, height: 44)
                            }
                            .buttonStyle(.plain)
                            .accessibilityLabel("\(entry.name) color")
                            .accessibilityAddTraits(colorIndex == index ? .isSelected : [])
                        }
                    }
                }

                // Name TextField
                VStack(alignment: .leading, spacing: DailyArcSpacing.sm) {
                    Text(theme.uppercaseHeaders ? "\(theme.headerPrefix)NAME" : "Name")
                        .typography(.callout)
                        .fontDesign(theme.displayFontDesign)
                        .foregroundStyle(theme.textSecondary)

                    TextField("e.g., Exercise", text: $name)
                        .focused($nameFieldFocused)
                        .textFieldStyle(.roundedBorder)
                        .submitLabel(.done)
                        .onSubmit { nameFieldFocused = false }
                }

                // Frequency
                VStack(alignment: .leading, spacing: DailyArcSpacing.sm) {
                    Text(theme.uppercaseHeaders ? "\(theme.headerPrefix)FREQUENCY" : "Frequency")
                        .typography(.callout)
                        .fontDesign(theme.displayFontDesign)
                        .foregroundStyle(theme.textSecondary)

                    Picker("Frequency", selection: $frequencyRaw) {
                        Text("Daily").tag(0)
                        Text("Weekdays").tag(1)
                        Text("Weekends").tag(2)
                        Text("Custom").tag(3)
                    }
                    .pickerStyle(.segmented)

                    if frequencyRaw == 3 {
                        // Custom day toggles
                        HStack(spacing: DailyArcSpacing.sm) {
                            ForEach(Array(zip(dayIndices, dayNames)), id: \.0) { index, name in
                                Button {
                                    if customDays.contains(index) {
                                        customDays.remove(index)
                                    } else {
                                        customDays.insert(index)
                                    }
                                } label: {
                                    Text(name)
                                        .typography(.caption)
                                        .frame(width: 40, height: 40)
                                        .background(
                                            customDays.contains(index)
                                                ? DailyArcTokens.accent
                                                : theme.backgroundSecondary
                                        )
                                        .foregroundStyle(
                                            customDays.contains(index) ? .white : theme.textPrimary
                                        )
                                        .clipShape(Circle())
                                }
                                .buttonStyle(.plain)
                                .accessibilityLabel(name)
                                .accessibilityAddTraits(customDays.contains(index) ? .isSelected : [])
                            }
                        }

                        if !customDays.isEmpty {
                            let selectedNames = dayIndices
                                .filter { customDays.contains($0) }
                                .map { dayNames[$0 - 1] }
                            Text("Selected: \(selectedNames.joined(separator: ", "))")
                                .typography(.caption)
                                .foregroundStyle(theme.textSecondary)
                        }
                    }
                }

                // Target Count
                VStack(alignment: .leading, spacing: DailyArcSpacing.sm) {
                    Text(theme.uppercaseHeaders ? "\(theme.headerPrefix)TIMES PER DAY" : "Times per day")
                        .typography(.callout)
                        .fontDesign(theme.displayFontDesign)
                        .foregroundStyle(theme.textSecondary)

                    Stepper("\(targetCount)", value: $targetCount, in: 1...10)
                        .typography(.bodyLarge)
                }

                // Next Button
                Button {
                    withAnimation { step = 2 }
                } label: {
                    Text("Next")
                        .typography(.bodyLarge)
                        .fontWeight(.semibold)
                        .frame(maxWidth: .infinity, minHeight: 50)
                        .background(DailyArcTokens.accent)
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: DailyArcTokens.cornerRadiusMedium))
                }
                .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty || (frequencyRaw == 3 && customDays.isEmpty))
                .opacity(name.trimmingCharacters(in: .whitespaces).isEmpty || (frequencyRaw == 3 && customDays.isEmpty) ? 0.5 : 1.0)
            }
            .padding(.horizontal, DailyArcSpacing.lg)
            .padding(.vertical, DailyArcSpacing.xl)
        }
        .scrollDismissesKeyboard(.interactively)
        .background(theme.backgroundPrimary)
    }

    // MARK: - Step 2: Reminders & Save

    private var step2View: some View {
        ScrollView {
            VStack(spacing: DailyArcSpacing.xl) {
                // Preview
                HStack(spacing: DailyArcSpacing.md) {
                    Text(emoji)
                        .font(.largeTitle)
                    VStack(alignment: .leading, spacing: DailyArcSpacing.xxs) {
                        Text(name)
                            .typography(.titleSmall)
                            .fontDesign(theme.displayFontDesign)
                            .foregroundStyle(theme.textPrimary)
                        Text(frequencyLabel)
                            .typography(.caption)
                            .foregroundStyle(theme.textSecondary)
                    }
                    Spacer()
                    let entry = HabitColorPalette.colors[safe: colorIndex] ?? HabitColorPalette.colors[5]
                    Circle()
                        .fill(Color(hex: colorScheme == .dark ? entry.darkModeHex : entry.hex) ?? .blue)
                        .frame(width: 24, height: 24)
                }
                .padding(DailyArcSpacing.lg)
                .background(theme.backgroundSecondary)
                .clipShape(RoundedRectangle(cornerRadius: theme.cornerRadiusLarge))

                // Reminder
                VStack(alignment: .leading, spacing: DailyArcSpacing.sm) {
                    Toggle("Daily Reminder", isOn: $reminderEnabled)
                        .typography(.bodyLarge)

                    if reminderEnabled {
                        DatePicker(
                            "Reminder Time",
                            selection: $reminderTime,
                            displayedComponents: .hourAndMinute
                        )
                        .datePickerStyle(.compact)
                    }
                }
                .padding(DailyArcSpacing.lg)
                .background(theme.backgroundSecondary)
                .clipShape(RoundedRectangle(cornerRadius: theme.cornerRadiusLarge))

                // Health Integration (only for health-related habits)
                if canAutoLog {
                    VStack(alignment: .leading, spacing: DailyArcSpacing.sm) {
                        Text(theme.uppercaseHeaders ? "\(theme.headerPrefix)HEALTH INTEGRATION" : "Health Integration")
                            .typography(.callout)
                            .fontDesign(theme.displayFontDesign)
                            .foregroundStyle(theme.textSecondary)

                        Toggle("Auto-log from Apple Health", isOn: $autoLogHealth)
                            .typography(.bodyLarge)
                            .onChange(of: autoLogHealth) { _, enabled in
                                if enabled {
                                    Task { await HealthKitService.shared.requestAuthorization() }
                                }
                            }

                        if autoLogHealth {
                            Picker("Health Metric", selection: $healthKitType) {
                                Text("Workouts").tag("workouts")
                                Text("Steps (5,000+)").tag("steps")
                                Text("Sleep (7+ hrs)").tag("sleep")
                                Text("Mindful Minutes").tag("mindful")
                            }
                        }
                    }
                    .padding(DailyArcSpacing.lg)
                    .background(DailyArcTokens.backgroundSecondary)
                    .clipShape(RoundedRectangle(cornerRadius: DailyArcTokens.cornerRadiusLarge))
                }

                Spacer(minLength: DailyArcSpacing.xxl)

                // Save Button
                Button(action: saveHabit) {
                    Text("Save Habit")
                        .typography(.bodyLarge)
                        .fontWeight(.semibold)
                        .frame(maxWidth: .infinity, minHeight: 50)
                        .background(DailyArcTokens.accent)
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: DailyArcTokens.cornerRadiusMedium))
                }
            }
            .padding(.horizontal, DailyArcSpacing.lg)
            .padding(.vertical, DailyArcSpacing.xl)
        }
        .background(theme.backgroundPrimary)
    }

    // MARK: - Helpers

    private var frequencyLabel: String {
        switch frequencyRaw {
        case 0: return "Daily"
        case 1: return "Weekdays"
        case 2: return "Weekends"
        case 3:
            let selected = dayIndices.filter { customDays.contains($0) }.map { dayNames[$0 - 1] }
            return selected.isEmpty ? "Custom" : selected.joined(separator: ", ")
        default: return "Daily"
        }
    }

    private func populateFromEditMode() {
        guard let habit = editingHabit else { return }
        emoji = habit.emoji
        name = habit.name
        colorIndex = habit.colorIndex
        frequencyRaw = habit.frequencyRaw
        targetCount = habit.targetCount
        reminderEnabled = habit.reminderEnabled
        if let time = habit.reminderTime {
            reminderTime = time
        }
        if habit.frequency == .custom {
            customDays = Set(habit.customDayIndices)
        }
        autoLogHealth = habit.autoLogHealth
        healthKitType = habit.healthKitTypeRaw ?? "workouts"
    }

    private func saveHabit() {
        let trimmedName = name.trimmingCharacters(in: .whitespaces)
        guard !trimmedName.isEmpty else { return }

        let customDaysString = frequencyRaw == 3
            ? customDays.sorted().map(String.init).joined(separator: "|")
            : ""

        if let habit = editingHabit {
            // Edit mode: update existing
            habit.name = trimmedName
            habit.emoji = emoji
            habit.colorIndex = colorIndex
            habit.frequencyRaw = frequencyRaw
            habit.customDays = customDaysString
            habit.targetCount = targetCount
            habit.reminderEnabled = reminderEnabled
            habit.reminderTime = reminderEnabled ? reminderTime : nil
            habit.autoLogHealth = autoLogHealth
            habit.healthKitTypeRaw = autoLogHealth ? healthKitType : nil
        } else {
            // Add mode: create new with sortOrder = max + 1
            let descriptor = FetchDescriptor<Habit>(
                sortBy: [SortDescriptor(\.sortOrder, order: .reverse)]
            )
            let maxOrder = (try? modelContext.fetch(descriptor))?.first?.sortOrder ?? -1

            let habit = Habit(
                name: trimmedName,
                emoji: emoji,
                colorIndex: colorIndex,
                frequencyRaw: frequencyRaw,
                customDays: customDaysString,
                targetCount: targetCount,
                reminderTime: reminderEnabled ? reminderTime : nil,
                reminderEnabled: reminderEnabled,
                healthKitTypeRaw: autoLogHealth ? healthKitType : nil,
                autoLogHealth: autoLogHealth,
                startDate: Date(),
                sortOrder: maxOrder + 1
            )
            modelContext.insert(habit)
        }

        try? modelContext.save()
        dismiss()
    }
}

#Preview("Add") {
    HabitFormView(mode: .add)
        .modelContainer(for: Habit.self, inMemory: true)
}
