import SwiftUI

struct ContentView: View {
    @AppStorage("selectedTab") private var selectedTab = 0
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    @AppStorage("isCOPPABlocked") private var isCOPPABlocked = false
    @AppStorage("lastSeenVersion") private var lastSeenVersion = ""
    @State private var showWhatsNew = false

    private var currentVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
    }

    var body: some View {
        if isCOPPABlocked {
            coppaBlockScreen
        } else if !hasCompletedOnboarding {
            OnboardingView()
        } else {
            mainContent
                .onAppear {
                    if !lastSeenVersion.isEmpty && lastSeenVersion != currentVersion {
                        showWhatsNew = true
                    }
                    lastSeenVersion = currentVersion
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
    }
}
