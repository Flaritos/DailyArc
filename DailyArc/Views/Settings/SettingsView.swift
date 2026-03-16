import SwiftUI
import SwiftData
import StoreKit
import WidgetKit

struct SettingsView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.requestReview) private var requestReview
    @Query private var allHabits: [Habit]
    @Query private var allLogs: [HabitLog]
    @Query private var allMoods: [MoodEntry]

    // MARK: - Profile
    @AppStorage("userName") private var userName = ""
    @AppStorage("showStreaks") private var showStreaks = true

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

    var body: some View {
        Form {
            // MARK: - Profile
            Section("Profile") {
                TextField("Your name", text: $userName)
                    .textContentType(.givenName)

                Toggle("Show Streaks", isOn: $showStreaks)
            }

            // MARK: - Notifications
            Section("Notifications") {
                Toggle("Morning Reminder", isOn: $morningReminderEnabled)
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
            }

            // MARK: - Data Management
            Section("Data Management") {
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
                }

                Button(role: .destructive) {
                    showDeleteConfirmation = true
                } label: {
                    Label("Delete All Data", systemImage: "trash")
                        .foregroundStyle(DailyArcTokens.error)
                }
            }

            // MARK: - Premium
            Section("Premium") {
                if storeKit.isPremium {
                    HStack {
                        Image(systemName: "crown.fill")
                            .foregroundStyle(DailyArcTokens.premiumGold)
                        Text("Premium Active")
                            .typography(.bodyLarge)
                            .fontWeight(.semibold)
                        Spacer()
                        Text("Lifetime")
                            .typography(.caption)
                            .foregroundStyle(DailyArcTokens.textSecondary)
                    }
                } else {
                    Button {
                        showPaywall = true
                    } label: {
                        HStack {
                            Image(systemName: "crown")
                                .foregroundStyle(DailyArcTokens.premiumGold)
                            Text("Upgrade to Premium")
                                .foregroundStyle(DailyArcTokens.textPrimary)
                            Spacer()
                            Image(systemName: "chevron.right")
                                .foregroundStyle(DailyArcTokens.textTertiary)
                        }
                    }

                    Button {
                        Task { await storeKit.restorePurchases() }
                    } label: {
                        Text("Restore Purchases")
                            .typography(.bodySmall)
                            .foregroundStyle(DailyArcTokens.accent)
                    }
                }
            }

            // MARK: - Privacy
            Section("Privacy") {
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
                .tint(DailyArcTokens.accent)

                if gdprConsentWithdrawn {
                    Text("Data processing paused. Your data is safe but no new data will be recorded.")
                        .font(.caption)
                        .foregroundStyle(DailyArcTokens.warning)
                }

                Button("Do Not Sell or Share My Personal Information") {
                    showDoNotSellAlert = true
                }
                .foregroundStyle(DailyArcTokens.textPrimary)

                Text("DailyArc is not a medical device. If you are experiencing mental health concerns, please consult a healthcare professional.")
                    .font(.footnote)
                    .foregroundStyle(DailyArcTokens.textTertiary)
            }

            // MARK: - Help & Support
            Section("Help & Support") {
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
            }

            // MARK: - About
            Section("About") {
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

                if devEasterEggFound {
                    HStack {
                        Text("Built with \u{2764}\u{FE0F} and too much coffee.")
                            .font(.caption)
                            .foregroundStyle(DailyArcTokens.textTertiary)
                    }
                }
            }

            #if DEBUG
            Section("Developer") {
                Button("Seed Demo Data (45 days)") {
                    DebugDataGenerator.seedData(context: modelContext)
                }
            }
            #endif
        }
        .navigationTitle("Settings")
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
            "lastOpenDate", "insightNudgeShown",
            "moodCorrelationConsentDate", "moodConsentPromptDismissed",
            "earnedBadges",
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
                        "Unlimited habits (free is 3), mood-habit correlation insights, full smart suggestions, CSV export, and medium/large widgets.")
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
