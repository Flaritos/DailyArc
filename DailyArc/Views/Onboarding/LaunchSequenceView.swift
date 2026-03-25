import SwiftUI
import UserNotifications

// MARK: - Launch Phase

enum LaunchPhase {
    case boot, assembly, interactive
}

// MARK: - Launch Sequence View

/// Cinematic "D+B" launch sequence for onboarding Page 4.
/// Adapts visually to the user's chosen theme (Tactile or Command).
struct LaunchSequenceView: View {
    private var selectedThemeID: String { ThemeManager.shared.themeID }

    // Data from onboarding flow
    let selectedTemplates: Set<String>
    let templates: [(emoji: String, name: String, targetCount: Int)]
    @Binding var previewMood: Int?
    @Binding var enableReminder: Bool
    @Binding var emailInput: String
    @Binding var emailMarketingConsent: Bool
    let onLaunch: () -> Void

    @State private var phase: LaunchPhase = .boot
    @State private var showSkip = false

    // Command boot state
    @State private var visibleLines: Int = 0
    @State private var cursorVisible = true
    @State private var bootTextOpacity: Double = 1.0
    @State private var ringProgress: Double = 0.0
    @State private var showRing = false
    @State private var protocolsLabel = false

    // Tactile state
    @State private var cardShadowRadius: CGFloat = 0
    @State private var cardsAppeared = false

    // Interactive state
    @State private var ringSize: CGFloat = 200
    @State private var launchPressed = false
    @State private var pulseGlow = false

    private var isCommand: Bool { selectedThemeID == "command" }

    // Command boot lines
    private let bootLines: [(text: String, suffix: String?, suffixColor: Color?)] = [
        ("> DAILYARC", nil, nil),
        ("> LOADING...", nil, nil),
        ("> HABITS .............. ", "READY", Color(hex: "#22C55E")!),
        ("> MOOD TRACKING ....... ", "READY", Color(hex: "#22C55E")!),
        ("> INSIGHTS ............ ", "READY", Color(hex: "#22C55E")!),
        ("> REMINDERS ........... ", "SET", Color(hex: "#F97316")!),
        ("", nil, nil),
        ("> ALL SET", nil, nil),
        ("> LET'S GO.", nil, nil)
    ]

    var body: some View {
        ZStack {
            // Background
            if isCommand {
                Color.black.ignoresSafeArea()
                CommandGridOverlay()
                    .allowsHitTesting(false)
                    .opacity(0.5)
            } else {
                Color(hex: "#E8ECF1")!.ignoresSafeArea()
            }

            // Content
            if isCommand {
                commandContent
            } else {
                tactileContent
            }

            // Skip button
            if showSkip && phase != .interactive {
                VStack {
                    HStack {
                        Spacer()
                        Button {
                            skipToInteractive()
                        } label: {
                            Text("Skip")
                                .font(isCommand
                                    ? .system(.caption, design: .monospaced)
                                    : .system(.caption))
                                .foregroundStyle(isCommand
                                    ? CommandTheme.cyan.opacity(0.6)
                                    : Color(hex: "#64748B")!)
                        }
                        .padding(.trailing, 24)
                        .padding(.top, 16)
                    }
                    Spacer()
                }
            }
        }
        .onAppear {
            startSequence()
        }
    }

    // MARK: - Sequence Control

    private func startSequence() {
        Task { @MainActor in
            // Show skip after 1 second
            try? await Task.sleep(for: .seconds(1.0))
            withAnimation(.easeIn(duration: 0.3)) {
                showSkip = true
            }
        }

        if isCommand {
            startCommandSequence()
        } else {
            startTactileSequence()
        }
    }

    private func skipToInteractive() {
        withAnimation(.easeInOut(duration: 0.4)) {
            phase = .interactive
            showRing = true
            ringProgress = 1.0
            ringSize = 100
            bootTextOpacity = 0.2
            cardsAppeared = true
            cardShadowRadius = 12
            protocolsLabel = true
        }
    }

    // MARK: - Command Sequence

    private func startCommandSequence() {
        // Phase 1: Boot -- staggered text lines
        let lineDelay: Double = 0.3
        for i in 0..<bootLines.count {
            let lineIndex = i
            Task { @MainActor in
                try? await Task.sleep(for: .seconds(Double(lineIndex) * lineDelay))
                withAnimation(.easeOut(duration: 0.15)) {
                    visibleLines = lineIndex + 1
                }
            }
        }

        // Start cursor blink
        withAnimation(.easeInOut(duration: 0.5).repeatForever(autoreverses: true)) {
            cursorVisible = false
        }

        Task { @MainActor in
            // Phase 2: Assembly (2.5s)
            try? await Task.sleep(for: .seconds(2.5))
            withAnimation(.easeInOut(duration: 0.5)) {
                bootTextOpacity = 0.2
                showRing = true
            }
            withAnimation(.easeInOut(duration: 1.2)) {
                ringProgress = 1.0
            }

            try? await Task.sleep(for: .seconds(0.8))
            withAnimation(.easeIn(duration: 0.3)) {
                protocolsLabel = true
            }

            // Phase 3: Interactive (1.5s after phase 2 protocols)
            try? await Task.sleep(for: .seconds(0.7))
            withAnimation(.easeInOut(duration: 0.6)) {
                phase = .interactive
                ringSize = 100
            }
        }
    }

    // MARK: - Tactile Sequence

    private func startTactileSequence() {
        Task { @MainActor in
            // Phase 1: Surface Formation
            try? await Task.sleep(for: .seconds(0.2))
            withAnimation(.easeOut(duration: 0.3)) {
                cardsAppeared = true
            }
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            withAnimation(.easeOut(duration: 1.0)) {
                cardShadowRadius = 12
            }

            // Phase 2: Dial Reveal (1.5s total from start)
            try? await Task.sleep(for: .seconds(1.3))
            withAnimation(.easeOut(duration: 0.3)) {
                showRing = true
            }
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            withAnimation(.easeInOut(duration: 1.2)) {
                ringProgress = 1.0
            }

            // Phase 3: Interactive (3s total from start)
            try? await Task.sleep(for: .seconds(1.5))
            withAnimation(.easeInOut(duration: 0.6)) {
                phase = .interactive
                ringSize = 100
            }
        }
    }

    // MARK: - Command Content

    private var commandContent: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Boot text
                if phase == .boot || bootTextOpacity < 1.0 {
                    commandBootText
                        .opacity(bootTextOpacity)
                        .padding(.top, 60)
                }

                // Ring
                if showRing {
                    ThemedProgressRing(
                        progress: ringProgress,
                        size: ringSize,
                        theme: CommandTheme()
                    )
                    .transition(.opacity.combined(with: .scale(scale: 0.8)))
                    .padding(.vertical, 16)
                }

                if protocolsLabel && phase != .interactive {
                    Text("\(selectedTemplates.count) PROTOCOLS LOADED")
                        .font(.system(.caption, design: .monospaced))
                        .foregroundStyle(CommandTheme.cyan.opacity(0.7))
                        .tracking(1.5)
                        .transition(.opacity)
                }

                // Interactive elements
                if phase == .interactive {
                    commandInteractiveContent
                        .transition(.opacity.combined(with: .move(edge: .bottom)))
                }

                Spacer(minLength: 60)
            }
            .padding(.horizontal, 20)
        }
        .scrollIndicators(.hidden)
    }

    private var commandBootText: some View {
        VStack(alignment: .leading, spacing: 6) {
            ForEach(0..<min(visibleLines, bootLines.count), id: \.self) { index in
                let line = bootLines[index]
                HStack(spacing: 0) {
                    Text(line.text)
                        .font(.system(.subheadline, design: .monospaced))
                        .foregroundStyle(Color(hex: "#E2E8F0")!)

                    if let suffix = line.suffix, let color = line.suffixColor {
                        Text(suffix)
                            .font(.system(.subheadline, design: .monospaced))
                            .foregroundStyle(color)
                    }

                    // Blinking cursor on last visible line
                    if index == visibleLines - 1 {
                        Rectangle()
                            .fill(CommandTheme.cyan)
                            .frame(width: 8, height: 16)
                            .opacity(cursorVisible ? 1.0 : 0.0)
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var commandInteractiveContent: some View {
        VStack(spacing: 24) {
            // Mission Briefing header
            Text("> GETTING STARTED")
                .font(.system(.headline, design: .monospaced))
                .foregroundStyle(CommandTheme.cyan)
                .tracking(1.5)
                .frame(maxWidth: .infinity, alignment: .leading)

            // Mood selector
            VStack(alignment: .leading, spacing: 12) {
                Text("> HOW ARE YOU FEELING?")
                    .font(.system(.caption, design: .monospaced))
                    .foregroundStyle(CommandTheme.cyan.opacity(0.7))
                    .tracking(1)

                commandMoodSelector
            }
            .padding()
            .background(CommandTheme.panel)
            .clipShape(RoundedRectangle(cornerRadius: 2))
            .overlay(
                RoundedRectangle(cornerRadius: 2)
                    .stroke(CommandTheme.indigo.opacity(0.12), lineWidth: 1)
            )

            // Active protocols
            if !selectedTemplates.isEmpty {
                VStack(alignment: .leading, spacing: 12) {
                    Text("> YOUR HABITS:")
                        .font(.system(.caption, design: .monospaced))
                        .foregroundStyle(CommandTheme.cyan.opacity(0.7))
                        .tracking(1)

                    ForEach(Array(selectedTemplates.sorted()), id: \.self) { name in
                        let emoji = templates.first(where: { $0.name == name })?.emoji ?? ""
                        HStack(spacing: 8) {
                            Circle()
                                .fill(Color(hex: "#22C55E")!)
                                .frame(width: 6, height: 6)
                                .shadow(color: Color(hex: "#22C55E")!.opacity(0.5), radius: 4)
                            Text("\(emoji) \(name.uppercased())")
                                .font(.system(.subheadline, design: .monospaced))
                                .foregroundStyle(Color(hex: "#E2E8F0")!)
                            Spacer()
                            Text("[ACTIVE]")
                                .font(.system(.caption2, design: .monospaced))
                                .foregroundStyle(Color(hex: "#22C55E")!)
                        }
                    }
                }
                .padding()
                .background(CommandTheme.panel)
                .clipShape(RoundedRectangle(cornerRadius: 2))
                .overlay(
                    RoundedRectangle(cornerRadius: 2)
                        .stroke(CommandTheme.indigo.opacity(0.12), lineWidth: 1)
                )
            }

            // Daily briefing alert (notification toggle)
            VStack(alignment: .leading, spacing: 12) {
                Text("> DAILY REMINDER:")
                    .font(.system(.caption, design: .monospaced))
                    .foregroundStyle(CommandTheme.cyan.opacity(0.7))
                    .tracking(1)

                Toggle("Evening status report", isOn: $enableReminder)
                    .font(.system(.subheadline, design: .monospaced))
                    .foregroundStyle(Color(hex: "#E2E8F0")!)
                    .toggleStyle(ThemedToggleStyle(theme: CommandTheme()))
            }
            .padding()
            .background(CommandTheme.panel)
            .clipShape(RoundedRectangle(cornerRadius: 2))
            .overlay(
                RoundedRectangle(cornerRadius: 2)
                    .stroke(CommandTheme.indigo.opacity(0.12), lineWidth: 1)
            )

            // Email input
            VStack(alignment: .leading, spacing: 8) {
                TextField("COMMS CHANNEL (OPTIONAL)", text: $emailInput)
                    .font(.system(.subheadline, design: .monospaced))
                    .foregroundStyle(Color(hex: "#E2E8F0")!)
                    .keyboardType(.emailAddress)
                    .textContentType(.emailAddress)
                    .autocorrectionDisabled()
                    .textInputAutocapitalization(.never)
                    .padding(12)
                    .background(Color(hex: "#0A0A14")!)
                    .clipShape(RoundedRectangle(cornerRadius: 2))
                    .overlay(
                        RoundedRectangle(cornerRadius: 2)
                            .stroke(CommandTheme.cyan.opacity(0.2), lineWidth: 1)
                    )

                if !emailInput.isEmpty {
                    Toggle("Receive weekly intel summary", isOn: $emailMarketingConsent)
                        .font(.system(.caption, design: .monospaced))
                        .foregroundStyle(Color(hex: "#E2E8F0")!.opacity(0.7))
                        .toggleStyle(ThemedToggleStyle(theme: CommandTheme()))
                }
            }
            .padding()
            .background(CommandTheme.panel)
            .clipShape(RoundedRectangle(cornerRadius: 2))
            .overlay(
                RoundedRectangle(cornerRadius: 2)
                    .stroke(CommandTheme.indigo.opacity(0.12), lineWidth: 1)
            )

            // Launch button
            Button {
                onLaunch()
            } label: {
                Text("[ START ]")
                    .font(.system(.headline, design: .monospaced))
                    .foregroundStyle(CommandTheme.cyan)
                    .tracking(2)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(Color.black)
                    .clipShape(RoundedRectangle(cornerRadius: 2))
                    .overlay(
                        RoundedRectangle(cornerRadius: 2)
                            .stroke(CommandTheme.cyan, lineWidth: 1.5)
                    )
                    .shadow(color: CommandTheme.glowCyan.opacity(pulseGlow ? 0.8 : 0.3),
                            radius: pulseGlow ? 20 : 8, x: 0, y: 0)
            }
            .onAppear {
                withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
                    pulseGlow = true
                }
            }
        }
    }

    private var commandMoodSelector: some View {
        HStack(spacing: 16) {
            ForEach(1...5, id: \.self) { score in
                let emojis = ["", "\u{1F614}", "\u{1F615}", "\u{1F610}", "\u{1F642}", "\u{1F604}"]
                Button {
                    withAnimation(.spring(response: 0.3)) {
                        previewMood = score
                    }
                } label: {
                    Text(emojis[score])
                        .font(.system(size: 36))
                        .scaleEffect(previewMood == score ? 1.2 : 1.0)
                        .opacity(previewMood == nil || previewMood == score ? 1.0 : 0.3)
                        .shadow(color: previewMood == score ? CommandTheme.glowCyan : .clear,
                                radius: 12, x: 0, y: 0)
                }
            }
        }
    }

    // MARK: - Tactile Content

    private var tactileContent: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Ring area
                if showRing {
                    ThemedProgressRing(
                        progress: ringProgress,
                        size: ringSize,
                        theme: TactileTheme()
                    )
                    .transition(.opacity.combined(with: .scale(scale: 0.8)))
                    .padding(.top, 40)
                } else if cardsAppeared {
                    // Placeholder cards during surface formation
                    VStack(spacing: 16) {
                        ForEach(0..<3, id: \.self) { _ in
                            RoundedRectangle(cornerRadius: 16)
                                .fill(Color(hex: "#E8ECF1")!)
                                .frame(height: 24)
                                .shadow(color: Color.white.opacity(0.8), radius: cardShadowRadius, x: -6, y: -6)
                                .shadow(color: Color(hex: "#A3B1C6")!.opacity(0.6), radius: cardShadowRadius, x: 6, y: 6)
                        }
                    }
                    .padding(.horizontal, 40)
                    .padding(.top, 60)
                    .opacity(cardsAppeared ? 1 : 0)
                } else {
                    Spacer()
                        .frame(height: 120)
                }

                // Interactive elements
                if phase == .interactive {
                    tactileInteractiveContent
                        .transition(.opacity.combined(with: .move(edge: .bottom)))
                }

                Spacer(minLength: 60)
            }
            .padding(.horizontal, 20)
        }
        .scrollIndicators(.hidden)
    }

    private var tactileInteractiveContent: some View {
        VStack(spacing: 24) {
            Text("Let\u{2019}s shape your space")
                .font(.system(.title2, weight: .bold))
                .foregroundStyle(Color(hex: "#334155")!)

            // Mood selector
            VStack(spacing: 12) {
                Text("How does this moment feel?")
                    .font(.subheadline)
                    .foregroundStyle(Color(hex: "#64748B")!)

                tactileMoodSelector
            }
            .padding(20)
            .background(Color(hex: "#E8ECF1")!)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .shadow(color: Color.white.opacity(0.8), radius: 12, x: -6, y: -6)
            .shadow(color: Color(hex: "#A3B1C6")!.opacity(0.6), radius: 12, x: 6, y: 6)

            // Habits list
            if !selectedTemplates.isEmpty {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Your daily practice")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(Color(hex: "#64748B")!)

                    ForEach(Array(selectedTemplates.sorted()), id: \.self) { name in
                        let emoji = templates.first(where: { $0.name == name })?.emoji ?? ""
                        HStack {
                            Text("\(emoji) \(name)")
                                .font(.body)
                                .foregroundStyle(Color(hex: "#334155")!)
                            Spacer()
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundStyle(Color(hex: "#6366F1")!)
                        }
                        .padding(.vertical, 8)
                        .padding(.horizontal, 16)
                        .background(Color(hex: "#E8ECF1")!)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .shadow(color: Color.white.opacity(0.7), radius: 6, x: -3, y: -3)
                        .shadow(color: Color(hex: "#A3B1C6")!.opacity(0.5), radius: 6, x: 3, y: 3)
                    }
                }
                .padding(20)
                .background(Color(hex: "#E8ECF1")!)
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .shadow(color: Color.white.opacity(0.8), radius: 12, x: -6, y: -6)
                .shadow(color: Color(hex: "#A3B1C6")!.opacity(0.6), radius: 12, x: 6, y: 6)
            }

            // Morning reminder toggle
            VStack(alignment: .leading, spacing: 8) {
                Text("Morning reminder")
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(Color(hex: "#334155")!)

                Toggle("Get a gentle evening reminder", isOn: $enableReminder)
                    .font(.subheadline)
                    .foregroundStyle(Color(hex: "#64748B")!)
                    .toggleStyle(ThemedToggleStyle(theme: TactileTheme()))
            }
            .padding(20)
            .background(Color(hex: "#E8ECF1")!)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .shadow(color: Color.white.opacity(0.8), radius: 12, x: -6, y: -6)
            .shadow(color: Color(hex: "#A3B1C6")!.opacity(0.6), radius: 12, x: 6, y: 6)

            // Email
            VStack(alignment: .leading, spacing: 8) {
                TextField("Your email (optional)", text: $emailInput)
                    .keyboardType(.emailAddress)
                    .textContentType(.emailAddress)
                    .autocorrectionDisabled()
                    .textInputAutocapitalization(.never)
                    .font(.subheadline)
                    .padding(12)
                    .background(Color(hex: "#E8ECF1")!)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .shadow(color: Color(hex: "#A3B1C6")!.opacity(0.4), radius: 4, x: 2, y: 2)
                    .shadow(color: Color.white.opacity(0.7), radius: 4, x: -2, y: -2)

                if !emailInput.isEmpty {
                    Toggle("I agree to receive weekly summary emails", isOn: $emailMarketingConsent)
                        .font(.caption)
                        .foregroundStyle(Color(hex: "#64748B")!)
                        .tint(Color(hex: "#6366F1")!)
                }
            }
            .padding(20)
            .background(Color(hex: "#E8ECF1")!)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .shadow(color: Color.white.opacity(0.8), radius: 12, x: -6, y: -6)
            .shadow(color: Color(hex: "#A3B1C6")!.opacity(0.6), radius: 12, x: 6, y: 6)

            // Begin button
            Button {
                // Haptic on press
                UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
                withAnimation(.spring(response: 0.2)) {
                    launchPressed = true
                }
                Task { @MainActor in
                    try? await Task.sleep(for: .seconds(0.25))
                    onLaunch()
                }
            } label: {
                Text("Begin")
                    .font(.headline)
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(
                        LinearGradient(
                            colors: [Color(hex: "#6366F1")!, Color(hex: "#818CF8")!],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .shadow(color: launchPressed
                        ? Color(hex: "#A3B1C6")!.opacity(0.6)
                        : Color.white.opacity(0.8),
                        radius: launchPressed ? 4 : 10,
                        x: launchPressed ? 2 : -5,
                        y: launchPressed ? 2 : -5)
                    .shadow(color: launchPressed
                        ? Color.white.opacity(0.8)
                        : Color(hex: "#A3B1C6")!.opacity(0.6),
                        radius: launchPressed ? 4 : 10,
                        x: launchPressed ? -2 : 5,
                        y: launchPressed ? -2 : 5)
                    .scaleEffect(launchPressed ? 0.95 : 1.0)
            }
        }
    }

    private var tactileMoodSelector: some View {
        HStack(spacing: 12) {
            ForEach(1...5, id: \.self) { score in
                let emojis = ["", "\u{1F614}", "\u{1F615}", "\u{1F610}", "\u{1F642}", "\u{1F604}"]
                Button {
                    withAnimation(.spring(response: 0.3)) {
                        previewMood = score
                    }
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                } label: {
                    Text(emojis[score])
                        .font(.system(size: 36))
                        .frame(width: 52, height: 52)
                        .background(
                            Circle()
                                .fill(Color(hex: "#E8ECF1")!)
                                .shadow(
                                    color: previewMood == score
                                        ? Color(hex: "#A3B1C6")!.opacity(0.6)
                                        : Color.white.opacity(0.7),
                                    radius: previewMood == score ? 4 : 6,
                                    x: previewMood == score ? 2 : -3,
                                    y: previewMood == score ? 2 : -3
                                )
                                .shadow(
                                    color: previewMood == score
                                        ? Color.white.opacity(0.7)
                                        : Color(hex: "#A3B1C6")!.opacity(0.5),
                                    radius: previewMood == score ? 4 : 6,
                                    x: previewMood == score ? -2 : 3,
                                    y: previewMood == score ? -2 : 3
                                )
                        )
                        .scaleEffect(previewMood == score ? 1.15 : 1.0)
                        .opacity(previewMood == nil || previewMood == score ? 1.0 : 0.4)
                }
            }
        }
    }
}
