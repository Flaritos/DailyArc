import SwiftUI
import SwiftData

struct OnboardingView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    @AppStorage("isCOPPABlocked") private var isCOPPABlocked = false
    @State private var currentPage = 0

    // Page 2 (Welcome) state
    @State private var showConsent = false
    @State private var consentProcessing = false
    @State private var dobYear = 2000

    // Page 3 (Habits) state
    @State private var selectedTemplates: Set<String> = []
    @State private var templateTimes: [String: String] = [:]

    // Page 4 (Preview) state
    @State private var previewMood: Int? = nil

    private let templates: [(emoji: String, name: String, targetCount: Int)] = [
        ("🏃", "Exercise", 1), ("📚", "Reading", 1), ("🧘", "Meditate", 1), ("💤", "Sleep 8hrs", 1),
        ("💧", "Drink Water", 8), ("📝", "Journal", 1), ("🚶", "Walk", 1), ("🎨", "Creative Time", 1)
    ]

    var body: some View {
        TabView(selection: $currentPage) {
            introPage.tag(0)
            welcomePage.tag(1)
            habitPickerPage.tag(2)
            previewPage.tag(3)
        }
        .tabViewStyle(.page(indexDisplayMode: .always))
        .indexViewStyle(.page(backgroundDisplayMode: .always))
        .interactiveDismissDisabled()
    }

    // MARK: - Page 0: Philosophy Intro

    private var introPage: some View {
        VStack(spacing: DailyArcSpacing.xxl) {
            Spacer()

            Image(systemName: "circle.hexagongrid.fill")
                .font(.system(size: 100))
                .foregroundStyle(
                    LinearGradient(
                        colors: [
                            Color(hex: "#2563EB") ?? .blue,
                            Color(hex: "#5F27CD") ?? .purple
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )

            Text("DailyArc")
                .typography(.displayLarge)

            Text("Every day adds to your arc.")
                .typography(.titleSmall)
                .foregroundStyle(DailyArcTokens.textSecondary)

            VStack(spacing: DailyArcSpacing.lg) {
                Text("We believe self-knowledge is the foundation of well-being.")
                    .multilineTextAlignment(.center)

                Text("DailyArc helps you understand yourself better through the simple act of showing up each day — connecting what you do to how you feel.")
                    .multilineTextAlignment(.center)
                    .foregroundStyle(DailyArcTokens.textSecondary)

                Text("No accounts. No cloud. Your data stays on your device, always.")
                    .multilineTextAlignment(.center)
                    .foregroundStyle(DailyArcTokens.textTertiary)
                    .font(.subheadline)
            }
            .padding(.horizontal, DailyArcSpacing.xl)

            Spacer()

            Button {
                withAnimation { currentPage = 1 }
            } label: {
                Text("Let's begin")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .padding(.horizontal, DailyArcSpacing.xl)
            .padding(.bottom, DailyArcSpacing.jumbo)
        }
    }

    // MARK: - Page 1: Welcome + Age + Consent

    private var welcomePage: some View {
        ScrollView {
            VStack(spacing: DailyArcSpacing.xl) {
                VStack(spacing: DailyArcSpacing.md) {
                    Text("Before we start")
                        .typography(.titleLarge)
                    Text("A few quick things to set up.")
                        .typography(.bodySmall)
                        .foregroundStyle(DailyArcTokens.textSecondary)
                }
                .padding(.top, DailyArcSpacing.xxxl)

                VStack(alignment: .leading, spacing: DailyArcSpacing.md) {
                    valuePropRow(icon: "arrow.up.right.circle.fill", text: "Your daily habits shape an arc of growth")
                    valuePropRow(icon: "link.circle.fill", text: "Discover the connection between what you do and how you feel")
                    valuePropRow(icon: "lock.shield.fill", text: "Your arc lives on your device. Only yours.")
                }
                .padding(.horizontal, DailyArcSpacing.lg)

                // Consent section (always visible on this page)
                VStack(alignment: .leading, spacing: DailyArcSpacing.lg) {
                    // Age picker
                    HStack {
                        Text("Birth year")
                            .foregroundStyle(DailyArcTokens.textSecondary)
                        Spacer()
                        Picker("Year", selection: $dobYear) {
                            ForEach((1920...2020).reversed(), id: \.self) { year in
                                Text(String(year)).tag(year)
                            }
                        }
                        .pickerStyle(.menu)
                    }

                    Toggle("I consent to on-device data processing", isOn: $consentProcessing)
                        .tint(DailyArcTokens.accent)

                    Text("Your data is stored on your device only and retained until you delete it.")
                        .font(.footnote)
                        .foregroundStyle(DailyArcTokens.textTertiary)
                }
                .padding()
                .background(DailyArcTokens.backgroundSecondary)
                .clipShape(RoundedRectangle(cornerRadius: DailyArcTokens.cornerRadiusLarge))
                .padding(.horizontal)

                if isUnderAge {
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
                    }
                }

                Button {
                    withAnimation { currentPage = 2 }
                } label: {
                    Text("Get Started")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .padding(.horizontal, DailyArcSpacing.xl)
                .disabled(!consentProcessing || isUnderAge)

                Spacer(minLength: DailyArcSpacing.jumbo)
            }
            .onChange(of: dobYear) { _, _ in
                isCOPPABlocked = isUnderAge
            }
        }
    }

    // MARK: - Page 2: Habit Templates

    private var habitPickerPage: some View {
        ScrollView {
            VStack(spacing: DailyArcSpacing.xl) {
                Text("Choose your habits")
                    .typography(.titleLarge)
                    .padding(.top, DailyArcSpacing.xxxl)

                Text("Pick 1–3 to start. You can always add more later.")
                    .typography(.bodySmall)
                    .foregroundStyle(DailyArcTokens.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)

                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: DailyArcSpacing.md) {
                    ForEach(templates, id: \.name) { template in
                        templateCard(template)
                    }
                }
                .padding(.horizontal)

                if !selectedTemplates.isEmpty {
                    VStack(alignment: .leading, spacing: DailyArcSpacing.md) {
                        Text("When will you do these?")
                            .typography(.bodySmall)
                            .foregroundStyle(DailyArcTokens.textSecondary)

                        ForEach(Array(selectedTemplates.sorted()), id: \.self) { name in
                            let emoji = templates.first(where: { $0.name == name })?.emoji ?? ""
                            VStack(alignment: .leading, spacing: DailyArcSpacing.xs) {
                                Text("\(emoji) \(name)")
                                    .font(.subheadline.weight(.medium))
                                Picker("Time of day", selection: binding(for: name)) {
                                    Text("Morning").tag("Morning")
                                    Text("Afternoon").tag("Afternoon")
                                    Text("Evening").tag("Evening")
                                }
                                .pickerStyle(.segmented)
                            }
                        }
                    }
                    .padding()
                    .background(DailyArcTokens.backgroundSecondary)
                    .clipShape(RoundedRectangle(cornerRadius: DailyArcTokens.cornerRadiusLarge))
                    .padding(.horizontal)
                }

                Text("Start with up to 3 habits free. Upgrade anytime for unlimited.")
                    .font(.caption)
                    .foregroundStyle(DailyArcTokens.textTertiary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)

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

                Spacer(minLength: DailyArcSpacing.jumbo)
            }
        }
    }

    // MARK: - Page 3: Preview + Launch

    private var previewPage: some View {
        ScrollView {
            VStack(spacing: DailyArcSpacing.xl) {
                Text("Your arc starts here")
                    .typography(.titleLarge)
                    .padding(.top, DailyArcSpacing.xxxl)

                Text("How are you feeling?")
                    .typography(.bodySmall)
                    .foregroundStyle(DailyArcTokens.textSecondary)

                HStack(spacing: DailyArcSpacing.lg) {
                    ForEach(1...5, id: \.self) { score in
                        let emojis = ["", "😔", "😕", "😐", "🙂", "😄"]
                        Button {
                            withAnimation(.spring(response: 0.3)) {
                                previewMood = score
                            }
                        } label: {
                            Text(emojis[score])
                                .font(.system(size: 44))
                                .scaleEffect(previewMood == score ? 1.2 : 1.0)
                                .opacity(previewMood == nil || previewMood == score ? 1.0 : 0.4)
                        }
                    }
                }

                // Sample insight card
                VStack(spacing: DailyArcSpacing.sm) {
                    Image(systemName: "lightbulb.fill")
                        .foregroundStyle(.yellow)
                        .font(.title2)
                    Text("On exercise days, mood averages 4.2")
                        .typography(.bodySmall)
                        .multilineTextAlignment(.center)
                    Text("This is what you'll discover after 2 weeks of logging.")
                        .font(.caption)
                        .foregroundStyle(DailyArcTokens.textTertiary)
                        .multilineTextAlignment(.center)
                }
                .padding()
                .background(DailyArcTokens.backgroundSecondary)
                .clipShape(RoundedRectangle(cornerRadius: DailyArcTokens.cornerRadiusMedium))
                .padding(.horizontal)

                // Selected habits preview
                if !selectedTemplates.isEmpty {
                    VStack(alignment: .leading, spacing: DailyArcSpacing.sm) {
                        Text("Your habits")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(DailyArcTokens.textSecondary)
                        ForEach(Array(selectedTemplates.sorted()), id: \.self) { name in
                            let emoji = templates.first(where: { $0.name == name })?.emoji ?? ""
                            HStack {
                                Text("\(emoji) \(name)")
                                    .font(.body)
                                Spacer()
                                Image(systemName: "circle")
                                    .foregroundStyle(DailyArcTokens.textTertiary)
                            }
                        }
                    }
                    .padding()
                    .background(DailyArcTokens.backgroundSecondary)
                    .clipShape(RoundedRectangle(cornerRadius: DailyArcTokens.cornerRadiusMedium))
                    .padding(.horizontal)
                }

                Button {
                    createHabitsAndFinish()
                } label: {
                    Text("Start Your Arc")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .padding(.horizontal, DailyArcSpacing.xl)

                Spacer(minLength: DailyArcSpacing.jumbo)
            }
        }
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

    private func templateCard(_ template: (emoji: String, name: String, targetCount: Int)) -> some View {
        let isSelected = selectedTemplates.contains(template.name)
        return Button {
            withAnimation(.spring(response: 0.25)) {
                if isSelected {
                    selectedTemplates.remove(template.name)
                    templateTimes.removeValue(forKey: template.name)
                } else if selectedTemplates.count < 3 {
                    selectedTemplates.insert(template.name)
                    templateTimes[template.name] = "Morning"
                }
            }
        } label: {
            VStack(spacing: DailyArcSpacing.sm) {
                Text(template.emoji)
                    .font(.system(size: 36))
                Text(template.name)
                    .font(.subheadline)
                    .foregroundStyle(DailyArcTokens.textPrimary)
                if template.targetCount > 1 {
                    Text("\(template.targetCount)× daily")
                        .font(.caption2)
                        .foregroundStyle(DailyArcTokens.textTertiary)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, DailyArcSpacing.md)
            .background(isSelected ? DailyArcTokens.accent.opacity(0.1) : DailyArcTokens.backgroundSecondary)
            .clipShape(RoundedRectangle(cornerRadius: DailyArcTokens.cornerRadiusMedium))
            .overlay(
                RoundedRectangle(cornerRadius: DailyArcTokens.cornerRadiusMedium)
                    .stroke(isSelected ? DailyArcTokens.accent : .clear, lineWidth: 2)
            )
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

        try? context.save()
        hasCompletedOnboarding = true
        dismiss()
    }
}
