import SwiftUI
import StoreKit

/// Premium purchase sheet.
/// Shows feature benefits, localized price from StoreKit, purchase & restore actions.
/// Deep theme fork: Tactile uses neumorphic cards, Command uses dark panels with terminal aesthetics.
struct PaywallView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.theme) private var theme
    @State private var storeKit = StoreKitManager.shared
    @State private var showCelebration = false

    private var isCommand: Bool { theme.id == "command" }

    private struct FeatureItem: Identifiable {
        let id = UUID()
        let tactileText: String
        let commandText: String
    }

    private let features: [FeatureItem] = [
        FeatureItem(tactileText: "Track as many habits as matter to you", commandText: "Unlimited habit protocols"),
        FeatureItem(tactileText: "See how your habits and mood connect", commandText: "Mood-habit correlation engine"),
        FeatureItem(tactileText: "Suggestions that learn your rhythm", commandText: "Adaptive suggestion system"),
        FeatureItem(tactileText: "Trends across weeks and months", commandText: "Extended trend analysis"),
        FeatureItem(tactileText: "Export everything, anytime, any format", commandText: "Full-spectrum data export"),
        FeatureItem(tactileText: "Widgets that keep your arc close", commandText: "Home screen system widgets"),
    ]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: DailyArcSpacing.xl) {
                    // Price prominently near the top
                    if let product = storeKit.premiumProduct {
                        if isCommand {
                            commandPriceDisplay(product: product)
                        } else {
                            tactilePriceDisplay(product: product)
                        }
                    } else {
                        ProgressView()
                            .padding()
                    }

                    // Title
                    if isCommand {
                        Text("> ALL FEATURES")
                            .font(.system(size: 22, weight: .bold, design: .monospaced))
                            .foregroundStyle(CommandTheme.cyan)
                            .tracking(1.5)
                            .shadow(color: CommandTheme.glowCyan, radius: 8)
                            .multilineTextAlignment(.center)
                    } else {
                        Text("Your Full Arc")
                            .font(.system(size: 28, weight: .bold))
                            .multilineTextAlignment(.center)
                    }

                    // Subtitle
                    Text(isCommand ? "YOURS FOREVER" : "One payment. Yours forever.")
                        .font(isCommand ? .system(size: 14, design: .monospaced) : .system(size: 16))
                        .foregroundStyle(isCommand ? Color.white.opacity(0.5) : DailyArcTokens.textSecondary)
                        .tracking(isCommand ? 1.0 : 0)

                    // Feature list
                    if isCommand {
                        commandFeatureList
                    } else {
                        tactileFeatureList
                    }

                    // Purchase Button
                    purchaseButton

                    // Social proof
                    Text(isCommand ? "> START BUILDING" : "Start building your arc")
                        .font(isCommand ? .system(size: 11, design: .monospaced) : .system(size: 14))
                        .foregroundStyle(isCommand ? Color.white.opacity(0.3) : DailyArcTokens.textTertiary)
                        .tracking(isCommand ? 0.5 : 0)

                    // Restore
                    Button {
                        Task { await storeKit.restorePurchases() }
                    } label: {
                        if isCommand {
                            Text("> RESTORE PURCHASE")
                                .font(.system(size: 13, weight: .medium, design: .monospaced))
                                .foregroundStyle(CommandTheme.cyan.opacity(0.7))
                                .padding(.vertical, DailyArcSpacing.sm)
                                .padding(.horizontal, DailyArcSpacing.lg)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 4)
                                        .stroke(CommandTheme.cyan.opacity(0.3), lineWidth: 1)
                                )
                        } else {
                            Text("Restore Previous Purchase")
                                .typography(.bodySmall)
                                .fontWeight(.medium)
                                .foregroundStyle(DailyArcTokens.accent)
                                .padding(.vertical, DailyArcSpacing.sm)
                                .padding(.horizontal, DailyArcSpacing.lg)
                                .background(
                                    RoundedRectangle(cornerRadius: DailyArcTokens.cornerRadiusMedium)
                                        .stroke(DailyArcTokens.accent.opacity(0.3), lineWidth: 1)
                                )
                        }
                    }

                    // Error
                    if let error = storeKit.errorMessage {
                        Text(error)
                            .typography(.caption)
                            .foregroundStyle(DailyArcTokens.error)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, DailyArcSpacing.lg)
                    }

                    // Not Now — dismiss immediately
                    Button {
                        dismiss()
                    } label: {
                        Text("Not now")
                            .typography(.bodySmall)
                            .foregroundStyle(DailyArcTokens.textTertiary)
                    }

                    Spacer(minLength: DailyArcSpacing.xxl)
                }
                .padding(.horizontal, DailyArcSpacing.lg)
                .padding(.top, DailyArcSpacing.lg)
            }
            .background(theme.backgroundPrimary)
            .themedGridOverlay(theme)
            .themedScanline(theme)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .foregroundStyle(DailyArcTokens.textSecondary)
                    }
                }
            }
            .onChange(of: storeKit.purchaseState) { _, newValue in
                if newValue == .success {
                    showCelebration = true
                }
            }
            .fullScreenCover(isPresented: $showCelebration) {
                PurchaseCelebrationView {
                    showCelebration = false
                    dismiss()
                }
            }
        }
    }

    // MARK: - Tactile Feature List (Neumorphic Cards)

    private var tactileFeatureList: some View {
        VStack(spacing: DailyArcSpacing.sm) {
            ForEach(features) { feature in
                HStack(alignment: .top, spacing: DailyArcSpacing.sm) {
                    Image(systemName: "checkmark")
                        .font(.body.bold())
                        .foregroundStyle(DailyArcTokens.success)
                        .frame(width: 24)
                    Text(feature.tactileText)
                        .typography(.bodyLarge)
                        .foregroundStyle(DailyArcTokens.textPrimary)
                    Spacer()
                }
                .padding(DailyArcSpacing.md)
                .background(Color(hex: "#E8ECF1")!)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .shadow(color: Color.white.opacity(0.8), radius: 6, x: -3, y: -3)
                .shadow(color: Color(hex: "#A3B1C6")!.opacity(0.5), radius: 6, x: 3, y: 3)
            }
        }
        .padding(.horizontal, DailyArcSpacing.sm)
    }

    // MARK: - Command Feature List (Terminal Style)

    private var commandFeatureList: some View {
        VStack(alignment: .leading, spacing: DailyArcSpacing.xs) {
            ForEach(features) { feature in
                HStack(alignment: .top, spacing: DailyArcSpacing.sm) {
                    Text("[READY]")
                        .font(.system(size: 11, weight: .bold, design: .monospaced))
                        .foregroundStyle(CommandTheme.cyan)
                        .frame(width: 72, alignment: .leading)
                    Text(feature.commandText)
                        .font(.system(size: 13, design: .monospaced))
                        .foregroundStyle(Color.white.opacity(0.7))
                }
            }
        }
        .padding(DailyArcSpacing.md)
        .background(CommandTheme.panel)
        .clipShape(RoundedRectangle(cornerRadius: 4))
        .overlay(
            RoundedRectangle(cornerRadius: 4)
                .stroke(CommandTheme.cyan.opacity(0.15), lineWidth: 1)
        )
        .overlay(alignment: .leading) {
            Rectangle()
                .fill(CommandTheme.cyan.opacity(0.5))
                .frame(width: 3)
        }
        .padding(.horizontal, DailyArcSpacing.sm)
    }

    // MARK: - Tactile Price Display

    private func tactilePriceDisplay(product: Product) -> some View {
        VStack(spacing: DailyArcSpacing.xs) {
            Text("\(product.displayPrice) one-time")
                .font(.system(size: 32, weight: .bold))
                .foregroundStyle(DailyArcTokens.accent)

            Text("No subscriptions. No recurring charges.")
                .font(.system(size: 14))
                .foregroundStyle(DailyArcTokens.textTertiary)
        }
    }

    // MARK: - Command Price Display (Monospace Terminal)

    private func commandPriceDisplay(product: Product) -> some View {
        VStack(spacing: DailyArcSpacing.xs) {
            Text(product.displayPrice)
                .font(.system(size: 36, weight: .bold, design: .monospaced))
                .foregroundStyle(CommandTheme.cyan)
                .shadow(color: CommandTheme.glowCyan, radius: 12)

            Text("YOURS FOREVER")
                .font(.system(size: 11, weight: .semibold, design: .monospaced))
                .foregroundStyle(Color.white.opacity(0.4))
                .tracking(1.5)
        }
        .padding(DailyArcSpacing.md)
        .background(CommandTheme.panel)
        .clipShape(RoundedRectangle(cornerRadius: 4))
        .overlay(
            RoundedRectangle(cornerRadius: 4)
                .stroke(CommandTheme.cyan.opacity(0.2), lineWidth: 1)
        )
    }

    // MARK: - Purchase Button

    @ViewBuilder
    private var purchaseButton: some View {
        Button {
            Task { await storeKit.purchase() }
        } label: {
            Group {
                switch storeKit.purchaseState {
                case .idle, .error:
                    if isCommand {
                        Text("> GET IT")
                            .font(.system(size: 16, weight: .semibold, design: .monospaced))
                            .tracking(1.0)
                    } else {
                        Text("Continue Your Arc")
                            .typography(.bodyLarge)
                            .fontWeight(.semibold)
                    }
                case .loading:
                    ProgressView()
                        .tint(.white)
                case .success:
                    if isCommand {
                        Text("[AUTHORIZED]")
                            .font(.system(size: 16, weight: .bold, design: .monospaced))
                    } else {
                        Image(systemName: "checkmark")
                            .font(.title2.bold())
                    }
                }
            }
            .frame(maxWidth: .infinity, minHeight: 50)
            .background(
                Group {
                    if isCommand {
                        Color.clear
                    } else {
                        LinearGradient(
                            colors: [Color(hex: "#6366F1")!, Color(hex: "#818CF8")!],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    }
                }
            )
            .foregroundStyle(isCommand ? CommandTheme.cyan : .white)
            .clipShape(RoundedRectangle(cornerRadius: isCommand ? 4 : theme.cornerRadiusMedium))
            .overlay(
                Group {
                    if isCommand {
                        RoundedRectangle(cornerRadius: 4)
                            .stroke(CommandTheme.cyan, lineWidth: 1.5)
                    }
                }
            )
            .shadow(color: isCommand ? CommandTheme.glowCyan : .clear, radius: isCommand ? 15 : 0)
        }
        .disabled(storeKit.purchaseState == .loading || storeKit.purchaseState == .success)
        .padding(.horizontal, DailyArcSpacing.lg)
    }
}

// MARK: - Post-Purchase Celebration

/// Full-screen celebration shown after a successful premium purchase.
/// Tactile: animated logo + confetti + serif heading.
/// Command: terminal boot sequence with cyan glow.
struct PurchaseCelebrationView: View {
    @Environment(\.theme) private var theme
    @State private var showContent = false
    @State private var showConfetti = true
    var onComplete: () -> Void

    private var isCommand: Bool { theme.id == "command" }

    // Command boot lines for staggered animation
    private let bootLines = [
        "> AUTHORIZATION CONFIRMED",
        "> ALL MODULES UNLOCKED",
        "> SYSTEM EXPANDED",
    ]
    @State private var visibleBootLines = 0
    @State private var cyanPulse = false

    var body: some View {
        ZStack {
            // Background
            theme.backgroundPrimary
                .ignoresSafeArea()

            if isCommand {
                commandCelebration
            } else {
                tactileCelebration
            }
        }
        .onAppear {
            HapticManager.habitCompletion()
            withAnimation(.easeOut(duration: 0.6)) {
                showContent = true
            }

            if isCommand {
                // Stagger boot lines
                for i in 0..<bootLines.count {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3 * Double(i + 1)) {
                        withAnimation(.easeOut(duration: 0.3)) {
                            visibleBootLines = i + 1
                        }
                    }
                }
                // Start cyan pulse
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    withAnimation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true)) {
                        cyanPulse = true
                    }
                }
            }

            // Auto-dismiss after 3 seconds
            DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                onComplete()
            }
        }
    }

    // MARK: - Tactile Celebration

    private var tactileCelebration: some View {
        ZStack {
            // Confetti
            if showConfetti {
                CelebrationOverlay(isShowing: $showConfetti)
                    .allowsHitTesting(false)
            }

            VStack(spacing: DailyArcSpacing.xl) {
                Spacer()

                // Animated logo
                DailyArcLogo(size: 120, animated: true)
                    .opacity(showContent ? 1 : 0)
                    .scaleEffect(showContent ? 1 : 0.5)

                Text("Your full arc awaits")
                    .font(.system(size: 28, weight: .bold, design: .serif))
                    .foregroundStyle(DailyArcTokens.textPrimary)
                    .multilineTextAlignment(.center)
                    .opacity(showContent ? 1 : 0)
                    .offset(y: showContent ? 0 : 20)

                Spacer()

                // CTA
                Button {
                    onComplete()
                } label: {
                    Text("Create your next habit")
                        .typography(.bodyLarge)
                        .fontWeight(.semibold)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity, minHeight: 50)
                        .background(DailyArcTokens.accent)
                        .clipShape(RoundedRectangle(cornerRadius: DailyArcTokens.cornerRadiusMedium))
                }
                .padding(.horizontal, DailyArcSpacing.xxl)
                .opacity(showContent ? 1 : 0)

                Spacer()
                    .frame(height: DailyArcSpacing.xxxl)
            }
        }
    }

    // MARK: - Command Celebration

    private var commandCelebration: some View {
        VStack(spacing: DailyArcSpacing.lg) {
            Spacer()

            // Main title with glow
            Text("[SYSTEM EXPANDED]")
                .font(.system(size: 24, weight: .bold, design: .monospaced))
                .foregroundStyle(CommandTheme.cyan)
                .shadow(color: CommandTheme.glowCyan, radius: cyanPulse ? 20 : 8)
                .opacity(showContent ? 1 : 0)
                .tracking(2.0)

            // Boot lines
            VStack(alignment: .leading, spacing: DailyArcSpacing.sm) {
                ForEach(0..<bootLines.count, id: \.self) { index in
                    if index < visibleBootLines {
                        Text(bootLines[index])
                            .font(.system(size: 14, design: .monospaced))
                            .foregroundStyle(CommandTheme.cyan.opacity(0.7))
                            .transition(.opacity.combined(with: .move(edge: .bottom)))
                    }
                }
            }

            Spacer()

            // Proceed button
            Button {
                onComplete()
            } label: {
                Text("PROCEED")
                    .font(.system(size: 16, weight: .semibold, design: .monospaced))
                    .foregroundStyle(CommandTheme.cyan)
                    .tracking(1.0)
                    .frame(maxWidth: .infinity, minHeight: 50)
                    .overlay(
                        RoundedRectangle(cornerRadius: 4)
                            .stroke(CommandTheme.cyan, lineWidth: 1.5)
                    )
                    .shadow(color: CommandTheme.glowCyan, radius: 10)
            }
            .padding(.horizontal, DailyArcSpacing.xxl)
            .opacity(showContent ? 1 : 0)

            Spacer()
                .frame(height: DailyArcSpacing.xxxl)
        }
    }
}
