import SwiftUI

struct ContentView: View {
    // NOTE: SceneStorage for NavigationPath serialization is deferred.
    // Full implementation requires NavigationPath Codable conformance and
    // per-tab path persistence, which is a larger refactor. Using @AppStorage
    // for tab selection is sufficient for now.
    @AppStorage("selectedTab") private var selectedTab = 0
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    @AppStorage("isCOPPABlocked") private var isCOPPABlocked = false
    @AppStorage("lastSeenVersion") private var lastSeenVersion = ""
    @State private var showWhatsNew = false
    @State private var pendingDeepLink: URL?
    @AppStorage("selectedThemeID") private var selectedThemeID = "tactile"
    @Environment(\.theme) private var theme
    @State private var isTransitioning = false
    @State private var transitionGlowColor: Color = .clear
    @State private var previousThemeID = "tactile"

    private var currentVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
    }

    var body: some View {
        Group {
            if isCOPPABlocked {
                coppaBlockScreen
            } else if !hasCompletedOnboarding {
                OnboardingView()
                    .onOpenURL { url in
                        pendingDeepLink = url
                    }
                    .onChange(of: hasCompletedOnboarding) { _, completed in
                        if completed, let url = pendingDeepLink {
                            handleDeepLink(url)
                            pendingDeepLink = nil
                        }
                    }
            } else {
                mainContent
                    .onAppear {
                        if !lastSeenVersion.isEmpty && lastSeenVersion != currentVersion {
                            showWhatsNew = true
                        }
                        lastSeenVersion = currentVersion
                        // Process any pending deep link from before onboarding completed
                        if let url = pendingDeepLink {
                            handleDeepLink(url)
                            pendingDeepLink = nil
                        }
                    }
                    .sheet(isPresented: $showWhatsNew) {
                        WhatsNewView()
                    }
            }
        }
        .id(hasCompletedOnboarding ? selectedThemeID : "onboarding") // Only force re-render after onboarding — during onboarding, theme changes should NOT reset the flow
        .preferredColorScheme(hasCompletedOnboarding ? ThemeManager.shared.currentTheme.forcedColorScheme : nil)
        .overlay(themeTransitionOverlay)
        .onChange(of: selectedThemeID) { oldValue, newValue in
            previousThemeID = oldValue
            transitionGlowColor = newValue == "command"
                ? Color(hex: "#22D3EE")!   // cyan for switching TO Command
                : Color(hex: "#6366F1")!   // indigo for switching TO Tactile
            withAnimation(.easeInOut(duration: 0.5)) {
                isTransitioning = true
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                withAnimation(.easeOut(duration: 0.3)) {
                    isTransitioning = false
                }
            }
        }
    }

    private func checkKeychainCOPPA() {
        if KeychainDOBService.isCOPPABlocked() {
            isCOPPABlocked = true
        }
    }

    private var coppaBlockScreen: some View {
        VStack(spacing: 24) {
            Spacer()

            Image(systemName: "hand.raised.fill")
                .font(.system(size: 56))
                .foregroundStyle(theme.textSecondary)

            Text("DailyArc is built for users 13 and older. We want to make sure everyone is safe, and that means following important privacy rules.")
                .multilineTextAlignment(.center)
                .foregroundStyle(theme.textSecondary)
                .padding(.horizontal, 32)

            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(theme.backgroundPrimary)
    }

    private var mainContent: some View {
        TabView(selection: $selectedTab) {
            NavigationStack {
                TodayView()
            }
            .tag(0)

            NavigationStack {
                StatsView()
            }
            .tag(1)

            NavigationStack {
                SettingsView()
            }
            .tag(2)
        }
        .toolbar(.hidden, for: .tabBar)
        .safeAreaInset(edge: .bottom) {
            ThemedTabBar(selectedTab: $selectedTab)
        }
        .tint(theme.id == "command" ? CommandTheme.cyan : DailyArcTokens.accent)
        .onAppear {
            checkKeychainCOPPA()
        }
        .onOpenURL { url in
            handleDeepLink(url)
        }
    }

    private func handleDeepLink(_ url: URL) {
        guard let host = url.host() else { return }
        switch host {
        case "today": selectedTab = 0
        case "stats": selectedTab = 1
        case "settings": selectedTab = 2
        default: selectedTab = 0 // malformed → Today
        }
    }

    // MARK: - Theme Transition Overlay

    @ViewBuilder
    private var themeTransitionOverlay: some View {
        if isTransitioning {
            ZStack {
                // Full-screen fade overlay
                theme.backgroundPrimary
                    .opacity(isTransitioning ? 0.85 : 0)
                    .ignoresSafeArea()

                // Central glowing "crack" line
                Rectangle()
                    .fill(transitionGlowColor)
                    .frame(width: 4, height: UIScreen.main.bounds.height)
                    .shadow(color: transitionGlowColor.opacity(0.8), radius: 20, x: 0, y: 0)
                    .shadow(color: transitionGlowColor.opacity(0.4), radius: 40, x: 0, y: 0)
                    .opacity(isTransitioning ? 1 : 0)
            }
            .allowsHitTesting(false)
            .transition(.opacity)
        }
    }
}
