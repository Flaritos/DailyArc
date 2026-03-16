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

    private var currentVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
    }

    var body: some View {
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
                .foregroundStyle(DailyArcTokens.textSecondary)

            Text("DailyArc is built for users 13 and older. We want to make sure everyone is safe, and that means following important privacy rules.")
                .multilineTextAlignment(.center)
                .foregroundStyle(DailyArcTokens.textSecondary)
                .padding(.horizontal, 32)

            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(DailyArcTokens.backgroundPrimary)
    }

    private var mainContent: some View {
        TabView(selection: $selectedTab) {
            NavigationStack {
                TodayView()
            }
            .tabItem {
                Label("Today", systemImage: "circle.dotted.and.circle")
                    .symbolRenderingMode(.hierarchical)
            }
            .tag(0)

            NavigationStack {
                StatsView()
                    .toolbar {
                        ToolbarItem(placement: .primaryAction) {
                            NavigationLink(value: "badges") {
                                Image(systemName: "medal.fill")
                                    .symbolRenderingMode(.hierarchical)
                            }
                            .accessibilityLabel("Badges")
                        }
                    }
                    .navigationDestination(for: String.self) { destination in
                        if destination == "badges" {
                            BadgesView()
                        }
                    }
            }
            .tabItem {
                Label("Stats", systemImage: "chart.line.uptrend.xyaxis")
                    .symbolRenderingMode(.hierarchical)
            }
            .tag(1)

            NavigationStack {
                SettingsView()
            }
            .tabItem {
                Label("Settings", systemImage: "gear")
            }
            .tag(2)
        }
        .tint(DailyArcTokens.accent)
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
}
