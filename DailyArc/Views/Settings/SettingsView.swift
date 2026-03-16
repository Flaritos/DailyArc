import SwiftUI
import SwiftData

struct SettingsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var allHabits: [Habit]
    @Query private var allLogs: [HabitLog]
    @Query private var allMoods: [MoodEntry]

    // MARK: - Notification State

    @AppStorage("morningReminderEnabled") private var morningReminderEnabled = false
    @AppStorage("eveningReminderEnabled") private var eveningReminderEnabled = false
    @AppStorage("morningReminderHour") private var morningReminderHour = 8
    @AppStorage("morningReminderMinute") private var morningReminderMinute = 0
    @AppStorage("eveningReminderHour") private var eveningReminderHour = 20
    @AppStorage("eveningReminderMinute") private var eveningReminderMinute = 0

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

    // MARK: - Computed Dates for Time Pickers

    private var morningTime: Binding<Date> {
        Binding(
            get: {
                var comps = DateComponents()
                comps.hour = morningReminderHour
                comps.minute = morningReminderMinute
                return Calendar.current.date(from: comps) ?? Date()
            },
            set: { newDate in
                let comps = Calendar.current.dateComponents([.hour, .minute], from: newDate)
                morningReminderHour = comps.hour ?? 8
                morningReminderMinute = comps.minute ?? 0
                if morningReminderEnabled {
                    NotificationService.shared.scheduleMorningReminder(
                        hour: morningReminderHour,
                        minute: morningReminderMinute
                    )
                }
            }
        )
    }

    private var eveningTime: Binding<Date> {
        Binding(
            get: {
                var comps = DateComponents()
                comps.hour = eveningReminderHour
                comps.minute = eveningReminderMinute
                return Calendar.current.date(from: comps) ?? Date()
            },
            set: { newDate in
                let comps = Calendar.current.dateComponents([.hour, .minute], from: newDate)
                eveningReminderHour = comps.hour ?? 20
                eveningReminderMinute = comps.minute ?? 0
                if eveningReminderEnabled {
                    NotificationService.shared.scheduleEveningReminder(
                        hour: eveningReminderHour,
                        minute: eveningReminderMinute
                    )
                }
            }
        )
    }

    var body: some View {
        Form {
            // MARK: - Notifications

            Section("Notifications") {
                Toggle("Morning Reminder", isOn: $morningReminderEnabled)
                    .onChange(of: morningReminderEnabled) { _, enabled in
                        handleNotificationToggle(enabled: enabled) {
                            NotificationService.shared.scheduleMorningReminder(
                                hour: morningReminderHour,
                                minute: morningReminderMinute
                            )
                        } onDisable: {
                            NotificationService.shared.cancelMorningReminder()
                        }
                    }

                if morningReminderEnabled {
                    DatePicker(
                        "Time",
                        selection: morningTime,
                        displayedComponents: .hourAndMinute
                    )
                }

                Toggle("Evening Reminder", isOn: $eveningReminderEnabled)
                    .onChange(of: eveningReminderEnabled) { _, enabled in
                        handleNotificationToggle(enabled: enabled) {
                            NotificationService.shared.scheduleEveningReminder(
                                hour: eveningReminderHour,
                                minute: eveningReminderMinute
                            )
                        } onDisable: {
                            NotificationService.shared.cancelEveningReminder()
                        }
                    }

                if eveningReminderEnabled {
                    DatePicker(
                        "Time",
                        selection: eveningTime,
                        displayedComponents: .hourAndMinute
                    )
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
                        if isExporting {
                            ProgressView()
                        }
                    }
                }
                .disabled(isExporting)

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

                HStack {
                    Text("Analytics")
                    Spacer()
                    Text("None collected")
                        .foregroundStyle(DailyArcTokens.textSecondary)
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

                HStack {
                    Text("Build")
                    Spacer()
                    Text(Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1")
                        .foregroundStyle(.secondary)
                }

                Button {
                    UserDefaults.standard.set(false, forKey: "hasCompletedOnboarding")
                } label: {
                    Label("Replay Onboarding", systemImage: "arrow.counterclockwise")
                }

                Text("DailyArc is not a medical device. If you are experiencing mental health concerns, please consult a healthcare professional.")
                    .font(.footnote)
                    .foregroundStyle(DailyArcTokens.textTertiary)
            }

            #if DEBUG
            // MARK: - Developer

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
            Button("Cancel", role: .cancel) {
                deleteConfirmationText = ""
            }
            Button("Delete Everything", role: .destructive) {
                if deleteConfirmationText == "DELETE" {
                    deleteAllData()
                }
                deleteConfirmationText = ""
            }
        } message: {
            Text("This permanently deletes all your data. This cannot be undone. Type DELETE to confirm.")
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
                    // Revert toggle — must happen after the async call
                }
            }
        } else {
            onDisable()
        }
    }

    // MARK: - Export

    private func exportJSON() {
        isExporting = true
        exportError = nil

        Task {
            do {
                let data = try await ExportService.shared.exportToJSON(
                    habits: allHabits,
                    logs: allLogs,
                    moods: allMoods
                )

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
        } catch {
            // Silently handle — best-effort deletion
        }

        // Clear UserDefaults preferences
        let defaults = UserDefaults.standard
        let keysToRemove = [
            "hasCompletedOnboarding", "selectedTab",
            "morningReminderEnabled", "eveningReminderEnabled",
            "morningReminderHour", "morningReminderMinute",
            "eveningReminderHour", "eveningReminderMinute",
            "isPremium", "isCOPPABlocked", "moodDisclaimerShown"
        ]
        for key in keysToRemove {
            defaults.removeObject(forKey: key)
        }

        // Cancel all notifications
        NotificationService.shared.cancelAll()
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
