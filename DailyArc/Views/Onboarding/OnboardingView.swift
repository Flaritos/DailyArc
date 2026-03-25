import SwiftUI
import SwiftData
import UserNotifications

struct OnboardingView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    @AppStorage("isCOPPABlocked") private var isCOPPABlocked = false
    @AppStorage("userGoal") private var userGoal = ""
    @AppStorage("userEmail") private var userEmail = ""
    @AppStorage("emailMarketingConsentDate") private var emailConsentDate = ""
    @AppStorage("gdprConsentDate") private var gdprConsentDate = ""
    @AppStorage("gdprConsentScope") private var gdprConsentScope = ""
    @State private var currentPage = 0

    // Page 1 (Welcome) state
    @State private var showConsent = false
    @State private var consentProcessing = false
    @State private var dobYear = 2000

    // Page 0 (Intro) state
    @State private var showProps = false

    // Page 2 (Habits) state
    @State private var selectedTemplates: Set<String> = []
    @State private var templateTimes: [String: String] = [:]

    // Page 3 (Preview) state
    @State private var previewMood: Int? = nil
    @State private var enableReminder = true
    @State private var emailInput = ""
    @State private var emailMarketingConsent = false

    private let templates: [(emoji: String, name: String, targetCount: Int)] = [
        ("\u{1F3C3}", "Exercise", 1), ("\u{1F4DA}", "Reading", 1),
        ("\u{1F9D8}", "Meditate", 1), ("\u{1F4A4}", "Sleep 8hrs", 1),
        ("\u{1F4A7}", "Drink Water", 8), ("\u{1F4DD}", "Journal", 1),
        ("\u{1F6B6}", "Walk", 1), ("\u{1F3A8}", "Creative Time", 1)
    ]

    /// Templates reordered based on user goal
    private var orderedTemplates: [(emoji: String, name: String, targetCount: Int)] {
        switch userGoal {
        case "Get healthier":
            let prioritized = ["Exercise", "Walk", "Drink Water", "Sleep 8hrs"]
            return templates.sorted { a, b in
                let aIdx = prioritized.firstIndex(of: a.name) ?? 99
                let bIdx = prioritized.firstIndex(of: b.name) ?? 99
                return aIdx < bIdx
            }
        case "Be more productive":
            let prioritized = ["Journal", "Reading", "Creative Time"]
            return templates.sorted { a, b in
                let aIdx = prioritized.firstIndex(of: a.name) ?? 99
                let bIdx = prioritized.firstIndex(of: b.name) ?? 99
                return aIdx < bIdx
            }
        case "Build mindfulness":
            let prioritized = ["Meditate", "Journal", "Walk"]
            return templates.sorted { a, b in
                let aIdx = prioritized.firstIndex(of: a.name) ?? 99
                let bIdx = prioritized.firstIndex(of: b.name) ?? 99
                return aIdx < bIdx
            }
        default:
            return templates
        }
    }

    var body: some View {
        TabView(selection: $currentPage) {
            introPage.tag(0)
            welcomePage.tag(1)
            habitPickerPage.tag(2)
            themePickerPage.tag(3)
            previewPage.tag(4)
        }
        .tabViewStyle(.page(indexDisplayMode: .always))
        .indexViewStyle(.page(backgroundDisplayMode: .always))
        .interactiveDismissDisabled()
    }

    // MARK: - Page 0: Warm Welcome

    private var introPage: some View {
        let props: [(icon: String, color: Color, text: String)] = [
            ("checkmark.circle.fill", .blue, "Track what matters to you"),
            ("chart.line.uptrend.xyaxis", .green, "Understand your patterns"),
            ("arrow.up.right.circle.fill", .purple, "Watch your arc grow")
        ]

        return VStack(spacing: DailyArcSpacing.xxl) {
            Spacer()

            DailyArcLogo(size: 140, animated: true)

            VStack(spacing: DailyArcSpacing.sm) {
                Text("DailyArc")
                    .typography(.displayLarge)

                Text("Every day adds to your arc.")
                    .typography(.titleSmall)
                    .foregroundStyle(DailyArcTokens.textSecondary)
            }

            VStack(alignment: .leading, spacing: DailyArcSpacing.lg) {
                ForEach(Array(props.enumerated()), id: \.offset) { index, prop in
                    HStack(spacing: DailyArcSpacing.md) {
                        Image(systemName: prop.icon)
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(.white)
                            .frame(width: 32, height: 32)
                            .background(prop.color)
                            .clipShape(Circle())

                        Text(prop.text)
                            .font(.body)
                            .foregroundStyle(DailyArcTokens.textPrimary)
                    }
                    .opacity(showProps ? 1 : 0)
                    .offset(y: showProps ? 0 : 10)
                    .animation(.easeOut(duration: 0.5).delay(Double(index) * 0.3), value: showProps)
                }
            }
            .padding(.horizontal, DailyArcSpacing.xxl)

            Spacer()

            Button {
                withAnimation { currentPage = 1 }
            } label: {
                Text("Let\u{2019}s begin \u{2192}")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .tint(.blue)
            .padding(.horizontal, DailyArcSpacing.xl)
            .padding(.bottom, DailyArcSpacing.jumbo)
        }
        .background(Color(uiColor: .systemBackground))
        .onAppear { showProps = true }
    }

    // MARK: - Page 1: Card Stack Welcome

    private var welcomePage: some View {
        let cardData: [(icon: String, color: Color, text: String)] = [
            ("lock.fill", .blue, "Your data stays on your device"),
            ("iphone", .green, "No accounts, no cloud"),
            ("heart.fill", .pink, "Built with care for your wellbeing")
        ]

        return ScrollView {
            VStack(spacing: DailyArcSpacing.xl) {
                Text("Welcome")
                    .font(.system(size: 24, weight: .bold))
                    .padding(.top, DailyArcSpacing.xxxl)

                // Card stack / dealt cards
                VStack(spacing: showConsent ? DailyArcSpacing.md : 0) {
                    ForEach(Array(cardData.enumerated()), id: \.offset) { index, card in
                        HStack(spacing: DailyArcSpacing.md) {
                            Image(systemName: card.icon)
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundStyle(.white)
                                .frame(width: 36, height: 36)
                                .background(card.color)
                                .clipShape(Circle())

                            Text(card.text)
                                .font(.body.weight(.medium))
                                .foregroundStyle(DailyArcTokens.textPrimary)

                            Spacer()
                        }
                        .padding(DailyArcSpacing.lg)
                        .background(DailyArcTokens.backgroundSecondary)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                        .shadow(color: .black.opacity(0.06), radius: 8, x: 0, y: 2)
                        .offset(y: showConsent ? 0 : CGFloat(index) * 8)
                        .zIndex(Double(cardData.count - index))
                    }
                }
                .padding(.horizontal)
                .animation(.spring(response: 0.5, dampingFraction: 0.8), value: showConsent)

                // "Continue" button (Step 1 -> Step 2)
                if !showConsent {
                    Button {
                        withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                            showConsent = true
                        }
                    } label: {
                        Text("Continue")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
                    .padding(.horizontal, DailyArcSpacing.xl)
                }

                // Step 2: Age + consent (revealed after Continue)
                VStack(alignment: .leading, spacing: DailyArcSpacing.lg) {
                    // Birth year — prominent display
                    VStack(spacing: DailyArcSpacing.sm) {
                        Text("Birth year")
                            .font(.subheadline)
                            .foregroundStyle(DailyArcTokens.textSecondary)

                        HStack {
                            Spacer()
                            Button {
                                if dobYear > 1920 { dobYear -= 1 }
                            } label: {
                                Image(systemName: "minus.circle.fill")
                                    .font(.title2)
                                    .foregroundStyle(DailyArcTokens.textSecondary)
                            }
                            .buttonStyle(.plain)

                            Text(String(dobYear))
                                .font(.system(size: 24, weight: .bold))
                                .monospacedDigit()
                                .frame(width: 80)
                                .multilineTextAlignment(.center)

                            Button {
                                if dobYear < 2020 { dobYear += 1 }
                            } label: {
                                Image(systemName: "plus.circle.fill")
                                    .font(.title2)
                                    .foregroundStyle(DailyArcTokens.textSecondary)
                            }
                            .buttonStyle(.plain)
                            Spacer()
                        }
                    }

                    Toggle("I consent to on-device data processing", isOn: $consentProcessing)
                        .tint(DailyArcTokens.accent)

                    HStack(spacing: DailyArcSpacing.xs) {
                        Image(systemName: "lock.shield.fill")
                            .font(.footnote)
                            .foregroundStyle(DailyArcTokens.textTertiary)
                        Text("Your data never leaves this device.")
                            .font(.footnote)
                            .foregroundStyle(DailyArcTokens.textTertiary)
                    }

                    Text("Data controller: DailyArc. Contact: privacy@dailyarc.app")
                        .font(.caption2)
                        .foregroundStyle(DailyArcTokens.textTertiary)
                }
                .padding()
                .background(DailyArcTokens.backgroundSecondary)
                .clipShape(RoundedRectangle(cornerRadius: DailyArcTokens.cornerRadiusLarge))
                .padding(.horizontal)
                .opacity(showConsent ? 1 : 0)
                .offset(y: showConsent ? 0 : 20)
                .animation(.easeOut(duration: 0.3), value: showConsent)

                if isUnderAge && showConsent {
                    VStack(spacing: DailyArcSpacing.md) {
                        Image(systemName: "hand.raised.fill")
                            .font(.system(size: 40))
                            .foregroundStyle(DailyArcTokens.textSecondary)

                        Text("DailyArc is built for users 13 and older. We want to make sure everyone is safe, and that means following important privacy rules.")
                            .typography(.bodySmall)
                            .foregroundStyle(DailyArcTokens.textSecondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding()
                    .background(DailyArcTokens.backgroundSecondary)
                    .clipShape(RoundedRectangle(cornerRadius: DailyArcTokens.cornerRadiusLarge))
                    .padding(.horizontal)
                    .onAppear {
                        isCOPPABlocked = true
                        KeychainDOBService.setCOPPABlocked(true)
                        KeychainDOBService.deleteDOB()
                    }
                }

                if showConsent {
                    Button {
                        KeychainDOBService.saveDOBYear(dobYear)
                        gdprConsentDate = ISO8601DateFormatter().string(from: Date())
                        gdprConsentScope = "processing"
                        withAnimation { currentPage = 2 }
                    } label: {
                        Text("Get Started \u{2192}")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
                    .padding(.horizontal, DailyArcSpacing.xl)
                    .disabled(!consentProcessing || isUnderAge)
                }

                Spacer(minLength: DailyArcSpacing.jumbo)
            }
            .onChange(of: dobYear) { _, _ in
                isCOPPABlocked = isUnderAge
            }
        }
        .background(Color(uiColor: .systemBackground))
    }

    // MARK: - Page 2: Checklist Habits

    private let templateDescriptions: [String: String] = [
        "Exercise": "Build a daily movement habit",
        "Reading": "Expand your mind each day",
        "Meditate": "Find your calm center",
        "Sleep 8hrs": "Prioritize rest and recovery",
        "Drink Water": "Stay hydrated throughout the day",
        "Journal": "Reflect on your thoughts",
        "Walk": "Step outside and explore",
        "Creative Time": "Express yourself daily"
    ]

    private var habitPickerPage: some View {
        ScrollView {
            VStack(spacing: DailyArcSpacing.lg) {
                VStack(spacing: DailyArcSpacing.sm) {
                    Text("Pick 3\u{2013}5 habits to start")
                        .font(.system(size: 24, weight: .bold))

                    Text("You can always add more later")
                        .font(.subheadline)
                        .foregroundStyle(DailyArcTokens.textSecondary)
                }
                .padding(.top, DailyArcSpacing.xxxl)

                // Goal filter as segmented control
                Picker("Goal", selection: $userGoal) {
                    Text("All").tag("")
                    Text("Health").tag("Get healthier")
                    Text("Productive").tag("Be more productive")
                    Text("Mindful").tag("Build mindfulness")
                }
                .pickerStyle(.segmented)
                .padding(.horizontal)

                // Clean vertical list of habits
                VStack(spacing: 0) {
                    ForEach(orderedTemplates, id: \.name) { template in
                        let isSelected = selectedTemplates.contains(template.name)

                        Button {
                            withAnimation(.spring(response: 0.25)) {
                                if isSelected {
                                    selectedTemplates.remove(template.name)
                                    templateTimes.removeValue(forKey: template.name)
                                } else {
                                    selectedTemplates.insert(template.name)
                                    templateTimes[template.name] = "Morning"
                                }
                            }
                        } label: {
                            HStack(spacing: DailyArcSpacing.md) {
                                Text(template.emoji)
                                    .font(.system(size: 36))
                                    .frame(width: 44)

                                VStack(alignment: .leading, spacing: 2) {
                                    Text(template.name)
                                        .font(.body.weight(.semibold))
                                        .foregroundStyle(DailyArcTokens.textPrimary)
                                    Text(templateDescriptions[template.name] ?? "")
                                        .font(.subheadline)
                                        .foregroundStyle(DailyArcTokens.textSecondary)
                                        .lineLimit(1)
                                }

                                Spacer()

                                // Circular checkbox
                                ZStack {
                                    Circle()
                                        .stroke(isSelected ? Color.clear : DailyArcTokens.textSecondary.opacity(0.4), lineWidth: 2)
                                        .frame(width: 28, height: 28)

                                    if isSelected {
                                        Circle()
                                            .fill(DailyArcTokens.accent)
                                            .frame(width: 28, height: 28)
                                        Image(systemName: "checkmark")
                                            .font(.system(size: 14, weight: .bold))
                                            .foregroundStyle(.white)
                                    }
                                }
                            }
                            .padding(.vertical, DailyArcSpacing.md)
                            .padding(.horizontal, DailyArcSpacing.lg)
                            .frame(minHeight: 56)
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)

                        if template.name != orderedTemplates.last?.name {
                            Divider()
                                .padding(.leading, 72)
                        }
                    }
                }
                .background(DailyArcTokens.backgroundSecondary)
                .clipShape(RoundedRectangle(cornerRadius: DailyArcTokens.cornerRadiusLarge))
                .padding(.horizontal)

                // Selected count with dot indicators
                HStack(spacing: DailyArcSpacing.sm) {
                    Text("\(selectedTemplates.count) of \(templates.count) selected")
                        .font(.subheadline)
                        .foregroundStyle(DailyArcTokens.textSecondary)

                    HStack(spacing: 4) {
                        ForEach(0..<templates.count, id: \.self) { index in
                            Circle()
                                .fill(index < selectedTemplates.count ? DailyArcTokens.accent : DailyArcTokens.textTertiary.opacity(0.3))
                                .frame(width: 6, height: 6)
                        }
                    }
                }

                Button {
                    withAnimation { currentPage = 3 }
                } label: {
                    Text("Next")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .padding(.horizontal, DailyArcSpacing.xl)
                .disabled(selectedTemplates.isEmpty)

                // Skip link
                Button {
                    selectedTemplates.removeAll()
                    withAnimation { currentPage = 3 }
                } label: {
                    Text("Skip \u{2014} I\u{2019}ll create custom habits")
                        .font(.caption)
                        .foregroundStyle(DailyArcTokens.textTertiary)
                }

                Spacer(minLength: DailyArcSpacing.jumbo)
            }
        }
        .background(Color(uiColor: .systemBackground))
    }

    // MARK: - Page 3: Theater Curtain Theme Picker

    // Read theme selection through ThemeManager so @Observable tracking works
    private var selectedThemeID: String { ThemeManager.shared.themeID }

    private var themePickerPage: some View {
        VStack(spacing: DailyArcSpacing.xxl) {
            Spacer()

            VStack(spacing: DailyArcSpacing.sm) {
                Text("Choose Your Style")
                    .font(.system(size: 24, weight: .semibold))
                    .foregroundStyle(Color(hex: "#334155")!)

                Text("You can change this anytime in Settings")
                    .font(.system(size: 13))
                    .foregroundStyle(Color(hex: "#64748B")!)
            }

            // Theme cards
            HStack(spacing: 14) {
                ThemePreviewCard(
                    themeID: "tactile",
                    isSelected: selectedThemeID == "tactile",
                    onSelect: { ThemeManager.shared.themeID = "tactile" }
                )

                ThemePreviewCard(
                    themeID: "command",
                    isSelected: selectedThemeID == "command",
                    onSelect: { ThemeManager.shared.themeID = "command" }
                )
            }
            .padding(.horizontal, DailyArcSpacing.lg)

            // Continue button
            Button {
                withAnimation { currentPage = 4 }
            } label: {
                Text("Continue")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, DailyArcSpacing.md)
            }
            .buttonStyle(.borderedProminent)
            .padding(.horizontal, DailyArcSpacing.xxl)

            Spacer()
        }
        .padding(DailyArcSpacing.xl)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(uiColor: .systemBackground))
    }

    // MARK: - Page 4: Launch Sequence

    private var previewPage: some View {
        LaunchSequenceView(
            selectedTemplates: selectedTemplates,
            templates: templates,
            previewMood: $previewMood,
            enableReminder: $enableReminder,
            emailInput: $emailInput,
            emailMarketingConsent: $emailMarketingConsent,
            onLaunch: createHabitsAndFinish
        )
    }

    private var isUnderAge: Bool {
        let currentYear = Calendar.current.component(.year, from: Date())
        return (currentYear - dobYear) < 13
    }

    // MARK: - Helpers

    private func valuePropRow(icon: String, text: String) -> some View {
        HStack(alignment: .top, spacing: DailyArcSpacing.md) {
            Image(systemName: icon)
                .foregroundStyle(DailyArcTokens.accent)
                .font(.title3)
            Text(text)
                .typography(.bodySmall)
                .foregroundStyle(DailyArcTokens.textPrimary)
        }
    }

    private func binding(for name: String) -> Binding<String> {
        Binding(
            get: { templateTimes[name] ?? "Morning" },
            set: { templateTimes[name] = $0 }
        )
    }

    private func createHabitsAndFinish() {
        let calendar = Calendar.current
        var order = 0

        for name in selectedTemplates.sorted() {
            guard let template = templates.first(where: { $0.name == name }) else { continue }
            let habit = Habit(
                name: template.name,
                emoji: template.emoji,
                colorIndex: order % 10,
                targetCount: template.targetCount,
                startDate: calendar.startOfDay(for: Date()),
                sortOrder: order
            )

            if let timeOfDay = templateTimes[name] {
                habit.reminderEnabled = true
                var components = calendar.dateComponents([.year, .month, .day], from: Date())
                switch timeOfDay {
                case "Morning": components.hour = 8
                case "Afternoon": components.hour = 13
                case "Evening": components.hour = 20
                default: components.hour = 9
                }
                habit.reminderTime = calendar.date(from: components)
            }

            context.insert(habit)
            order += 1
        }

        // Save email if provided with consent
        if !emailInput.isEmpty && emailInput.contains("@") && emailInput.contains(".") {
            userEmail = emailInput
            if emailMarketingConsent {
                emailConsentDate = ISO8601DateFormatter().string(from: Date())
            }
        }

        try? context.save()

        // Request notification permission if reminder enabled
        if enableReminder {
            Task {
                let granted = try? await UNUserNotificationCenter.current()
                    .requestAuthorization(options: [.alert, .badge, .sound])
                if granted == true {
                    await MainActor.run {
                        NotificationService.shared.scheduleEveningReminder(hour: 20, minute: 0)
                    }
                }
            }
        }

        hasCompletedOnboarding = true
        dismiss()
    }
}
