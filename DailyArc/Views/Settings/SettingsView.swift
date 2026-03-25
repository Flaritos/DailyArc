import SwiftUI
import SwiftData
import StoreKit
import UniformTypeIdentifiers
import WidgetKit

struct SettingsView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.requestReview) private var requestReview
    @Environment(\.theme) private var theme
    @Query private var allHabits: [Habit]
    @Query private var allLogs: [HabitLog]
    @Query private var allMoods: [MoodEntry]

    // MARK: - Profile
    @AppStorage("userName") private var userName = ""
    @AppStorage("showStreaks") private var showStreaks = true

    // MARK: - Appearance
    @AppStorage("accentColorIndex") private var accentColorIndex = 5

    // MARK: - Notification State
    @AppStorage("morningReminderEnabled") private var morningReminderEnabled = false
    @AppStorage("eveningReminderEnabled") private var eveningReminderEnabled = false
    @AppStorage("moodReminderEnabled") private var moodReminderEnabled = false
    @AppStorage("weeklySummaryEnabled") private var weeklySummaryEnabled = true
    @AppStorage("morningReminderHour") private var morningReminderHour = 8
    @AppStorage("morningReminderMinute") private var morningReminderMinute = 0
    @AppStorage("eveningReminderHour") private var eveningReminderHour = 20
    @AppStorage("eveningReminderMinute") private var eveningReminderMinute = 0
    @AppStorage("moodReminderHour") private var moodReminderHour = 21
    @AppStorage("moodReminderMinute") private var moodReminderMinute = 0

    // MARK: - Privacy / GDPR
    @AppStorage("gdprConsentDate") private var gdprConsentDate = ""
    @AppStorage("gdprConsentWithdrawn") private var gdprConsentWithdrawn = false

    // MARK: - Premium
    @State private var storeKit = StoreKitManager.shared
    @State private var showPaywall = false

    // MARK: - Export
    @State private var isExporting = false
    @State private var exportedFileURL: URL?
    @State private var showShareSheet = false
    @State private var exportError: String?

    // MARK: - Import
    @State private var showImportPicker = false
    @State private var importResult: String?

    // MARK: - Delete All Data
    @State private var showDeleteConfirmation = false
    @State private var deleteConfirmationText = ""

    // MARK: - Notification Permission
    @State private var notificationDenied = false

    // MARK: - Easter Egg
    @AppStorage("versionTapCount") private var versionTapCount = 0
    @AppStorage("devEasterEggFound") private var devEasterEggFound = false

    // MARK: - CCPA
    @State private var showDoNotSellAlert = false

    // MARK: - Help
    @State private var showPermissionsGuide = false

    // MARK: - Computed Dates for Time Pickers

    private var morningTime: Binding<Date> {
        timeBinding(hour: $morningReminderHour, minute: $morningReminderMinute) {
            if morningReminderEnabled {
                NotificationService.shared.scheduleMorningReminder(hour: morningReminderHour, minute: morningReminderMinute)
            }
        }
    }

    private var eveningTime: Binding<Date> {
        timeBinding(hour: $eveningReminderHour, minute: $eveningReminderMinute) {
            if eveningReminderEnabled {
                NotificationService.shared.scheduleEveningReminder(hour: eveningReminderHour, minute: eveningReminderMinute)
            }
        }
    }

    private var moodTime: Binding<Date> {
        timeBinding(hour: $moodReminderHour, minute: $moodReminderMinute) {
            if moodReminderEnabled {
                NotificationService.shared.scheduleMoodReminder(hour: moodReminderHour, minute: moodReminderMinute)
            }
        }
    }

    /// Themed section header text
    private func themedSectionHeader(_ title: String, commandTitle: String? = nil) -> some View {
        Group {
            if theme.id == "command" {
                Text(commandTitle ?? "> \(title.uppercased())")
                    .font(.system(size: 12, weight: .semibold, design: .monospaced))
                    .foregroundStyle(CommandTheme.cyan)
                    .shadow(color: CommandTheme.glowCyan, radius: 6, x: 0, y: 0)
                    .tracking(0.5)
            } else {
                Text(title)
            }
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            // Custom themed header (replaces hidden navigation bar)
            HStack {
                if theme.id == "command" {
                    Text("> SETTINGS")
                        .font(.system(size: 22, weight: .semibold, design: .monospaced))
                        .foregroundStyle(CommandTheme.cyan)
                        .shadow(color: CommandTheme.glowCyan, radius: 6, x: 0, y: 0)
                } else {
                    Text("Settings")
                        .font(.system(size: 28, weight: .semibold))
                        .foregroundStyle(theme.textPrimary)
                }
                Spacer()
            }
            .padding(.horizontal, DailyArcSpacing.lg)
            .padding(.top, DailyArcSpacing.sm)
            .padding(.bottom, DailyArcSpacing.xs)

        Form {
            // MARK: - Profile
            Section {
                if theme.id == "command" {
                    // Command: monogram in hexagonal frame concept (approximated with clipped circle)
                    HStack(spacing: DailyArcSpacing.md) {
                        ZStack {
                            // Hexagonal-ish frame
                            Circle()
                                .fill(CommandTheme.panel)
                                .frame(width: 44, height: 44)
                                .overlay(
                                    Circle()
                                        .stroke(CommandTheme.cyan.opacity(0.3), lineWidth: 1)
                                )
                            Text(String(userName.prefix(2)).uppercased())
                                .font(.system(size: 16, weight: .bold, design: .monospaced))
                                .foregroundStyle(CommandTheme.cyan)
                        }
                        TextField("Your name", text: $userName)
                            .textContentType(.givenName)
                            .font(.system(.body, design: .monospaced))
                    }
                } else {
                    TextField("Your name", text: $userName)
                        .textContentType(.givenName)
                }

                Toggle("Show Streaks", isOn: $showStreaks)
                    .toggleStyle(ThemedToggleStyle(theme: theme))
            } header: {
                themedSectionHeader("Profile")
            }

            // MARK: - Appearance
            Section {
                VStack(alignment: .leading, spacing: DailyArcSpacing.sm) {
                    Text("Theme")
                        .typography(.bodyLarge)

                    ThemePickerView()
                        .padding(.vertical, DailyArcSpacing.xs)
                }

                VStack(alignment: .leading, spacing: DailyArcSpacing.sm) {
                    Text("Accent Color")
                        .typography(.bodyLarge)

                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: DailyArcSpacing.sm) {
                            ForEach(0..<HabitColorPalette.colors.count, id: \.self) { index in
                                let entry = HabitColorPalette.colors[index]
                                let color = Color(
                                    light: Color(hex: entry.hex)!,
                                    dark: Color(hex: entry.darkModeHex)!
                                )
                                Button {
                                    accentColorIndex = index
                                } label: {
                                    if theme.id == "command" {
                                        // Command: small circles, selected has cyan glow
                                        Circle()
                                            .fill(color)
                                            .frame(width: 30, height: 30)
                                            .overlay {
                                                if accentColorIndex == index {
                                                    Circle()
                                                        .stroke(CommandTheme.cyan, lineWidth: 2)
                                                }
                                            }
                                            .shadow(color: accentColorIndex == index ? CommandTheme.glowCyan : .clear,
                                                    radius: accentColorIndex == index ? 10 : 0, x: 0, y: 0)
                                    } else {
                                        // Tactile: raised neumorphic circles, selected is inset
                                        Circle()
                                            .fill(color)
                                            .frame(width: 36, height: 36)
                                            .overlay {
                                                if accentColorIndex == index {
                                                    Image(systemName: "checkmark")
                                                        .font(.system(size: 14, weight: .bold))
                                                        .foregroundStyle(.white)
                                                }
                                            }
                                            .shadow(color: accentColorIndex == index ? Color(hex: "#A3B1C6")!.opacity(0.5) : Color.white.opacity(0.7),
                                                    radius: accentColorIndex == index ? 3 : 4,
                                                    x: accentColorIndex == index ? 2 : -3,
                                                    y: accentColorIndex == index ? 2 : -3)
                                            .shadow(color: accentColorIndex == index ? Color.white.opacity(0.6) : Color(hex: "#A3B1C6")!.opacity(0.5),
                                                    radius: accentColorIndex == index ? 3 : 4,
                                                    x: accentColorIndex == index ? -2 : 3,
                                                    y: accentColorIndex == index ? -2 : 3)
                                    }
                                }
                                .buttonStyle(.plain)
                                .accessibilityLabel("\(entry.name) accent color")
                            }
                        }
                        .padding(.vertical, DailyArcSpacing.xs)
                    }
                }

                // Terminal Color picker (Premium + Command only)
                if storeKit.isPremium && theme.id == "command" {
                    VStack(alignment: .leading, spacing: DailyArcSpacing.sm) {
                        Text("Terminal Color")
                            .font(.system(.body, design: .monospaced))
                            .foregroundStyle(theme.textPrimary)

                        HStack(spacing: DailyArcSpacing.md) {
                            ForEach(commandColorSchemes, id: \.name) { scheme in
                                Button {
                                    ThemeManager.shared.commandColorScheme = scheme.name
                                } label: {
                                    Circle()
                                        .fill(scheme.color)
                                        .frame(width: 30, height: 30)
                                        .overlay {
                                            if ThemeManager.shared.commandColorScheme == scheme.name {
                                                Circle()
                                                    .stroke(Color.white, lineWidth: 2)
                                            }
                                        }
                                        .shadow(
                                            color: ThemeManager.shared.commandColorScheme == scheme.name
                                                ? scheme.color.opacity(0.6) : .clear,
                                            radius: ThemeManager.shared.commandColorScheme == scheme.name ? 10 : 0,
                                            x: 0, y: 0
                                        )
                                }
                                .buttonStyle(.plain)
                                .accessibilityLabel("\(scheme.name) terminal color")
                            }
                        }
                        .padding(.vertical, DailyArcSpacing.xs)
                    }
                }
            } header: {
                themedSectionHeader("Appearance")
            }

            // MARK: - Notifications
            Section {
                Toggle("Morning Reminder", isOn: $morningReminderEnabled)
                    .toggleStyle(ThemedToggleStyle(theme: theme))
                    .onChange(of: morningReminderEnabled) { _, enabled in
                        handleNotificationToggle(enabled: enabled) {
                            NotificationService.shared.scheduleMorningReminder(hour: morningReminderHour, minute: morningReminderMinute)
                        } onDisable: {
                            NotificationService.shared.cancelMorningReminder()
                        }
                    }

                if morningReminderEnabled {
                    DatePicker("Time", selection: morningTime, displayedComponents: .hourAndMinute)
                }

                Toggle("Evening Reminder", isOn: $eveningReminderEnabled)
                    .toggleStyle(ThemedToggleStyle(theme: theme))
                    .onChange(of: eveningReminderEnabled) { _, enabled in
                        handleNotificationToggle(enabled: enabled) {
                            NotificationService.shared.scheduleEveningReminder(hour: eveningReminderHour, minute: eveningReminderMinute)
                        } onDisable: {
                            NotificationService.shared.cancelEveningReminder()
                        }
                    }

                if eveningReminderEnabled {
                    DatePicker("Time", selection: eveningTime, displayedComponents: .hourAndMinute)
                }

                Toggle("Mood Reminder", isOn: $moodReminderEnabled)
                    .toggleStyle(ThemedToggleStyle(theme: theme))
                    .onChange(of: moodReminderEnabled) { _, enabled in
                        handleNotificationToggle(enabled: enabled) {
                            NotificationService.shared.scheduleMoodReminder(hour: moodReminderHour, minute: moodReminderMinute)
                        } onDisable: {
                            NotificationService.shared.cancelMoodReminder()
                        }
                    }

                if moodReminderEnabled {
                    DatePicker("Time", selection: moodTime, displayedComponents: .hourAndMinute)
                }

                Toggle("Weekly Summary", isOn: $weeklySummaryEnabled)
                    .toggleStyle(ThemedToggleStyle(theme: theme))
                    .onChange(of: weeklySummaryEnabled) { _, enabled in
                        if enabled {
                            NotificationService.shared.scheduleWeeklySummary(hour: 18, minute: 0)
                        } else {
                            NotificationService.shared.cancelWeeklySummary()
                        }
                    }
                if weeklySummaryEnabled {
                    Text("Sunday evening recap of your week")
                        .font(.caption)
                        .foregroundStyle(DailyArcTokens.textTertiary)
                }

                if notificationDenied {
                    HStack {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundStyle(DailyArcTokens.warning)
                        Text("Notifications are disabled.")
                            .typography(.caption)
                            .foregroundStyle(DailyArcTokens.textSecondary)
                        Spacer()
                        Button("Open Settings") {
                            if let url = URL(string: UIApplication.openSettingsURLString) {
                                UIApplication.shared.open(url)
                            }
                        }
                        .typography(.caption)
                    }
                }
            } header: {
                themedSectionHeader("Notifications")
            }

            // MARK: - Data Management
            Section {
                Button {
                    exportJSON()
                } label: {
                    HStack {
                        Label("Export JSON", systemImage: "square.and.arrow.up")
                        Spacer()
                        if isExporting { ProgressView() }
                    }
                }
                .disabled(isExporting)

                if storeKit.isPremium {
                    Button {
                        exportCSV()
                    } label: {
                        Label("Export CSV", systemImage: "tablecells")
                    }
                } else {
                    Button {
                        showPaywall = true
                    } label: {
                        HStack {
                            Label("Export CSV", systemImage: "tablecells")
                                .foregroundStyle(DailyArcTokens.textTertiary)
                            Spacer()
                            HStack(spacing: DailyArcSpacing.xxs) {
                                Image(systemName: "lock.fill")
                                    .font(.caption2)
                                Text("Premium")
                                    .typography(.caption)
                            }
                            .foregroundStyle(DailyArcTokens.accent)
                        }
                    }
                }

                if storeKit.isPremium {
                    Button {
                        showImportPicker = true
                    } label: {
                        Label("Import JSON", systemImage: "square.and.arrow.down")
                    }
                } else {
                    Button {
                        showPaywall = true
                    } label: {
                        HStack {
                            Label("Import JSON", systemImage: "square.and.arrow.down")
                                .foregroundStyle(DailyArcTokens.textTertiary)
                            Spacer()
                            HStack(spacing: DailyArcSpacing.xxs) {
                                Image(systemName: "lock.fill")
                                    .font(.caption2)
                                Text("Premium")
                                    .typography(.caption)
                            }
                            .foregroundStyle(DailyArcTokens.accent)
                        }
                    }
                }

                Button(role: .destructive) {
                    HapticManager.deleteConfirmation()
                    showDeleteConfirmation = true
                } label: {
                    Label("Delete All Data", systemImage: "trash")
                        .foregroundStyle(DailyArcTokens.error)
                }
            } header: {
                themedSectionHeader("Data Management", commandTitle: "> YOUR DATA")
            }

            // MARK: - Premium (all features unlocked)
            Section {
                HStack {
                    Image(systemName: "crown.fill")
                        .foregroundStyle(DailyArcTokens.premiumGold)
                    Text("All Features Unlocked")
                        .typography(.bodyLarge)
                        .fontWeight(.semibold)
                    Spacer()
                    Text("Free")
                        .typography(.caption)
                        .foregroundStyle(DailyArcTokens.textSecondary)
                }
            } header: {
                themedSectionHeader("Premium", commandTitle: "> PREMIUM")
            }

            // MARK: - Privacy
            Section {
                HStack {
                    Text("Data Storage")
                    Spacer()
                    Text("On-device only")
                        .foregroundStyle(DailyArcTokens.textSecondary)
                }

                if !gdprConsentDate.isEmpty {
                    HStack {
                        Text("Consent Given")
                        Spacer()
                        Text(gdprConsentDate.prefix(10))
                            .foregroundStyle(DailyArcTokens.textSecondary)
                    }
                }

                Toggle("Processing Consent Active", isOn: Binding(
                    get: { !gdprConsentWithdrawn },
                    set: { gdprConsentWithdrawn = !$0 }
                ))
                .toggleStyle(ThemedToggleStyle(theme: theme))

                if gdprConsentWithdrawn {
                    Text("Data processing paused. Your data is safe but no new data will be recorded.")
                        .font(.caption)
                        .foregroundStyle(DailyArcTokens.warning)
                }

                Button("Do Not Sell or Share My Personal Information") {
                    showDoNotSellAlert = true
                }
                .foregroundStyle(DailyArcTokens.textPrimary)

                Link("Privacy Policy", destination: URL(string: "https://dailyarc.app/privacy")!)
                    .foregroundStyle(DailyArcTokens.accent)

                Text("DailyArc is not a medical device. If you are experiencing mental health concerns, please consult a healthcare professional.")
                    .font(.footnote)
                    .foregroundStyle(DailyArcTokens.textTertiary)
            } header: {
                themedSectionHeader("Privacy", commandTitle: "> PRIVACY")
            }

            // MARK: - Help & Support
            Section {
                Button {
                    UserDefaults.standard.set(false, forKey: "hasCompletedOnboarding")
                } label: {
                    Label("Replay Onboarding", systemImage: "arrow.counterclockwise")
                }

                Button {
                    showPermissionsGuide = true
                } label: {
                    Label("Permissions Guide", systemImage: "lock.shield")
                }

                NavigationLink {
                    HelpView()
                } label: {
                    Label("Help & FAQ", systemImage: "questionmark.circle")
                }

                Button {
                    openFeedbackEmail()
                } label: {
                    Label("Send Feedback", systemImage: "envelope")
                }

                Button {
                    requestReview()
                } label: {
                    Label("Rate on App Store", systemImage: "star")
                }
            } header: {
                themedSectionHeader("Help & Support", commandTitle: "> SUPPORT")
            }

            // MARK: - About
            Section {
                if theme.id == "command" {
                    // Command: "DAILYARC v1.0 // BUILD 47" in dim monospace
                    let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
                    let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
                    Text("DAILYARC v\(version) // BUILD \(build)")
                        .font(.system(size: 11, weight: .regular, design: .monospaced))
                        .foregroundStyle(Color.white.opacity(0.3))
                        .frame(maxWidth: .infinity, alignment: .center)
                        .contentShape(Rectangle())
                        .onTapGesture {
                            versionTapCount += 1
                            if versionTapCount >= 5 && !devEasterEggFound {
                                devEasterEggFound = true
                                EasterEggManager.shared.recordDiscovery("devmode")
                            }
                        }
                } else {
                    HStack {
                        Text("Version")
                        Spacer()
                        Text(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0")
                            .foregroundStyle(.secondary)
                    }
                    .contentShape(Rectangle())
                    .onTapGesture {
                        versionTapCount += 1
                        if versionTapCount >= 5 && !devEasterEggFound {
                            devEasterEggFound = true
                            EasterEggManager.shared.recordDiscovery("devmode")
                        }
                    }
                }

                if devEasterEggFound {
                    HStack {
                        Text(theme.id == "command" ? "// SYSTEM INITIALIZED BY CAFFEINE" : "Built with \u{2764}\u{FE0F} and too much coffee.")
                            .font(theme.id == "command" ? .system(.caption, design: .monospaced) : .caption)
                            .foregroundStyle(theme.id == "command" ? CommandTheme.cyan.opacity(0.5) : DailyArcTokens.textTertiary)
                    }
                }
            } header: {
                themedSectionHeader("About", commandTitle: "> ABOUT")
            }

            #if DEBUG
            Section("Developer") {
                Button("Seed Demo Data (45 days)") {
                    DebugDataGenerator.seedData(context: modelContext)
                }

                Button("Export App Icon (1024x1024)") {
                    if let data = AppIconGenerator.generateIcon() {
                        let url = FileManager.default.temporaryDirectory.appendingPathComponent("AppIcon.png")
                        try? data.write(to: url)
                        exportedFileURL = url
                        showShareSheet = true
                    }
                }
            }
            #endif
        }
        .scrollContentBackground(.hidden)
        } // end VStack
        .background(theme.backgroundPrimary.ignoresSafeArea())
        .themedGridOverlay(theme)
        .themedScanline(theme)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar(.hidden, for: .navigationBar)
        .sheet(isPresented: $showPaywall) {
            PaywallView()
        }
        .sheet(isPresented: $showShareSheet) {
            if let url = exportedFileURL {
                ShareSheetView(items: [url])
            }
        }
        .alert("Delete All Data", isPresented: $showDeleteConfirmation) {
            TextField("Type DELETE to confirm", text: $deleteConfirmationText)
            Button("Cancel", role: .cancel) { deleteConfirmationText = "" }
            Button("Delete Everything", role: .destructive) {
                if deleteConfirmationText == "DELETE" { deleteAllData() }
                deleteConfirmationText = ""
            }
        } message: {
            Text("Delete \(allHabits.count) habits, \(allLogs.count) logs, and \(allMoods.count) mood entries? This cannot be undone.")
        }
        .alert("Do Not Sell or Share", isPresented: $showDoNotSellAlert) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("DailyArc does not sell, rent, or share your personal information for advertising or monetary consideration. Your habit and mood data stays on your device. There is nothing to opt out of.")
        }
        .fileImporter(isPresented: $showImportPicker, allowedContentTypes: [.json]) { result in
            switch result {
            case .success(let url):
                guard url.startAccessingSecurityScopedResource() else {
                    importResult = "Unable to access the selected file."
                    return
                }
                defer { url.stopAccessingSecurityScopedResource() }
                do {
                    let data = try Data(contentsOf: url)
                    Task {
                        let outcome = try await ExportService.shared.importFromJSON(
                            data: data,
                            context: modelContext,
                            mergeMode: .skipExisting
                        )
                        importResult = "Imported \(outcome.habitsImported) habits, \(outcome.logsImported) logs, \(outcome.moodsImported) moods."
                    }
                } catch {
                    importResult = "Import failed: \(error.localizedDescription)"
                }
            case .failure(let error):
                importResult = "Could not select file: \(error.localizedDescription)"
            }
        }
        .alert("Import Result", isPresented: Binding(
            get: { importResult != nil },
            set: { if !$0 { importResult = nil } }
        )) {
            Button("OK", role: .cancel) { importResult = nil }
        } message: {
            Text(importResult ?? "")
        }
        .alert("Permissions Guide", isPresented: $showPermissionsGuide) {
            Button("Open Settings") {
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(url)
                }
            }
            Button("OK", role: .cancel) {}
        } message: {
            Text("To re-enable notifications: Settings \u{2192} DailyArc \u{2192} Notifications.\n\nTo enable HealthKit: Settings \u{2192} Privacy & Security \u{2192} Health \u{2192} DailyArc.")
        }
    }

    // MARK: - Notification Helpers

    private func handleNotificationToggle(
        enabled: Bool,
        onEnable: @escaping () -> Void,
        onDisable: @escaping () -> Void
    ) {
        if enabled {
            Task {
                let granted = await NotificationService.shared.requestPermission()
                if granted {
                    notificationDenied = false
                    onEnable()
                } else {
                    notificationDenied = true
                }
            }
        } else {
            onDisable()
        }
    }

    private func timeBinding(hour: Binding<Int>, minute: Binding<Int>, onChange: @escaping () -> Void) -> Binding<Date> {
        Binding(
            get: {
                var comps = DateComponents()
                comps.hour = hour.wrappedValue
                comps.minute = minute.wrappedValue
                return Calendar.current.date(from: comps) ?? Date()
            },
            set: { newDate in
                let comps = Calendar.current.dateComponents([.hour, .minute], from: newDate)
                hour.wrappedValue = comps.hour ?? 8
                minute.wrappedValue = comps.minute ?? 0
                onChange()
            }
        )
    }

    // MARK: - Export

    private func exportJSON() {
        isExporting = true
        exportError = nil
        Task {
            do {
                let data = try await ExportService.shared.exportToJSON(habits: allHabits, logs: allLogs, moods: allMoods)
                let tempURL = FileManager.default.temporaryDirectory
                    .appendingPathComponent("DailyArc_Export_\(formattedDate()).json")
                try data.write(to: tempURL)
                exportedFileURL = tempURL
                isExporting = false
                showShareSheet = true
            } catch {
                exportError = "Export failed: \(error.localizedDescription)"
                isExporting = false
            }
        }
    }

    private func exportCSV() {
        isExporting = true
        Task {
            do {
                let data = try await ExportService.shared.exportToCSV(habits: allHabits, logs: allLogs, moods: allMoods)
                let tempURL = FileManager.default.temporaryDirectory
                    .appendingPathComponent("DailyArc_Export_\(formattedDate()).csv")
                try data.write(to: tempURL)
                exportedFileURL = tempURL
                isExporting = false
                showShareSheet = true
            } catch {
                isExporting = false
            }
        }
    }

    private func formattedDate() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: Date())
    }

    // MARK: - Delete All Data

    private func deleteAllData() {
        // Delete all SwiftData objects
        do {
            try modelContext.delete(model: HabitLog.self)
            try modelContext.delete(model: MoodEntry.self)
            try modelContext.delete(model: DailySummary.self)
            try modelContext.delete(model: Habit.self)
            try modelContext.save()
        } catch {}

        // Reset @AppStorage properties directly so SwiftUI reacts immediately.
        // Using @AppStorage setters ensures the in-memory cache updates too,
        // unlike UserDefaults.standard.removeObject which only clears on disk.
        userName = ""
        showStreaks = true
        morningReminderEnabled = false
        eveningReminderEnabled = false
        moodReminderEnabled = false
        weeklySummaryEnabled = true
        morningReminderHour = 8
        morningReminderMinute = 0
        eveningReminderHour = 20
        eveningReminderMinute = 0
        moodReminderHour = 21
        moodReminderMinute = 0
        gdprConsentDate = ""
        gdprConsentWithdrawn = false
        versionTapCount = 0
        devEasterEggFound = false

        // Clear remaining keys that don't have @AppStorage bindings here
        let defaults = UserDefaults.standard
        let keysToRemove = [
            "selectedTab",
            "isPremium", "isCOPPABlocked", "moodDisclaimerShown",
            "userGoal", "userEmail",
            "gdprConsentScope",
            "emailMarketingConsentDate",
            "hasCompletedFirstHabit", "hasLoggedFirstMood",
            "easterEggDiscoveries", "appOpenCount", "firstLaunchDate",
            "lastOpenDate", "insightNudgeShown", "accentColorIndex",
            "hasSeenDateNavNudge", "lastSeenVersion",
            "moodCorrelationConsentDate", "moodConsentPromptDismissed",
            "earnedBadges",
            "customActivityTags",
        ]
        for key in keysToRemove {
            defaults.removeObject(forKey: key)
        }

        // Clear widget shared defaults
        UserDefaults(suiteName: "group.com.dailyarc.shared")?.removePersistentDomain(forName: "group.com.dailyarc.shared")

        // Reload widgets
        WidgetCenter.shared.reloadAllTimelines()

        // Cancel all notifications
        NotificationService.shared.cancelAll()

        // Reset onboarding LAST — this triggers ContentView to swap to OnboardingView
        // because ContentView reads @AppStorage("hasCompletedOnboarding") in its body.
        defaults.set(false, forKey: "hasCompletedOnboarding")
    }

    // MARK: - Command Color Schemes

    private var commandColorSchemes: [(name: String, color: Color)] {
        [
            ("cyan", Color(hex: "#22D3EE")!),
            ("amber", Color(hex: "#F59E0B")!),
            ("green", Color(hex: "#22C55E")!),
            ("blue", Color(hex: "#3B82F6")!),
        ]
    }

    // MARK: - Feedback Email

    private func openFeedbackEmail() {
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
        let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
        let device = UIDevice.current.model
        let ios = UIDevice.current.systemVersion
        let premium = storeKit.isPremium ? "Yes" : "No"

        let body = "\n\n---\nVersion: \(version) (\(build))\niOS: \(ios)\nDevice: \(device)\nPremium: \(premium)"
        let encodedBody = body.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        let encodedSubject = "DailyArc Feedback".addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""

        if let url = URL(string: "mailto:support@dailyarc.app?subject=\(encodedSubject)&body=\(encodedBody)") {
            UIApplication.shared.open(url)
        }
    }
}

// MARK: - Help View

struct HelpView: View {
    @Environment(\.theme) private var theme

    var body: some View {
        List {
            Section("Getting Started") {
                faqItem("How does DailyArc work?",
                        "DailyArc tracks your daily habits and mood, then discovers patterns between what you do and how you feel. All data stays on your device.")
                faqItem("How do I create a habit?",
                        "Tap the + button on the Today tab, choose from a template or create custom, set your schedule, and save.")
                faqItem("How do I log my mood?",
                        "On the Today tab, tap one of the 5 mood emojis. You can also add energy level and activity tags.")
                faqItem("Can I log past days?",
                        "Yes! Use the < > arrows on the Today tab to navigate to past dates and log habits or mood retroactively.")
            }

            Section("Habits & Streaks") {
                faqItem("How do streaks work?",
                        "Complete a habit every scheduled day to build a streak. Your current and best streaks are tracked per habit.")
                faqItem("What is streak recovery?",
                        "If you miss 1-2 days, you can recover your streak (up to twice per month). Look for the recovery banner on the Today tab.")
                faqItem("What are custom frequencies?",
                        "Choose Daily, Weekdays, Weekends, or pick specific days of the week for each habit.")
            }

            Section("Mood & Insights") {
                faqItem("What are correlation insights?",
                        "After 14 days of logging both mood and habits, DailyArc shows which habits are associated with better or worse mood.")
                faqItem("Why do I need 14 days of data?",
                        "Statistical patterns need enough data points to be meaningful. 14 days is the minimum for reliable mood-habit correlations.")
            }

            Section("Premium & Billing") {
                faqItem("What's included in Premium?",
                        "Unlimited habits (free is 5), mood-habit correlation insights, full smart suggestions, CSV export, and medium/large widgets.")
                faqItem("How do I restore purchases?",
                        "Go to Settings \u{2192} Premium \u{2192} Restore Purchases. Make sure you're signed into the same Apple ID.")
            }

            Section("Privacy & Data") {
                faqItem("Where is my data stored?",
                        "All data is stored locally on your device only. DailyArc never sends your data to external servers.")
                faqItem("How do I export my data?",
                        "Settings \u{2192} Data Management \u{2192} Export JSON. This creates a file you can save or share.")
                faqItem("How do I transfer to a new phone?",
                        "Use an encrypted backup via iTunes/Finder. This preserves all your data including settings. We also recommend exporting your data as a safety net.")
            }
        }
        .scrollContentBackground(.hidden)
        .background(theme.backgroundPrimary)
        .navigationTitle("Help & FAQ")
    }

    private func faqItem(_ question: String, _ answer: String) -> some View {
        DisclosureGroup(question) {
            Text(answer)
                .font(.subheadline)
                .foregroundStyle(DailyArcTokens.textSecondary)
                .padding(.vertical, DailyArcSpacing.xs)
        }
    }
}

// MARK: - Share Sheet UIKit Bridge

struct ShareSheetView: UIViewControllerRepresentable {
    let items: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
