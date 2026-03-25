import SwiftUI

/// Custom themed tab bar that replaces the standard UIKit tab bar.
/// Renders neumorphic "Tactile" style or sci-fi "Command" style based on active theme.
struct ThemedTabBar: View {
    @Binding var selectedTab: Int
    @Environment(\.theme) private var theme

    private let tabs: [(icon: String, label: String)] = [
        ("circle.dotted.and.circle", "Today"),
        ("chart.line.uptrend.xyaxis", "Stats"),
        ("gear", "Settings")
    ]

    var body: some View {
        if theme.id == "command" {
            commandTabBar
        } else {
            tactileTabBar
        }
    }

    // MARK: - Tactile (Neumorphic) Tab Bar

    private var tactileTabBar: some View {
        HStack(spacing: 0) {
            ForEach(Array(tabs.enumerated()), id: \.offset) { index, tab in
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        selectedTab = index
                    }
                } label: {
                    VStack(spacing: 4) {
                        tactileIcon(systemName: tab.icon, isActive: selectedTab == index)
                        Text(tab.label)
                            .font(.system(size: 10, weight: .medium))
                            .foregroundStyle(selectedTab == index ? DailyArcTokens.accent : theme.textSecondary)
                    }
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(.plain)
                .accessibilityLabel(tab.label)
                .accessibilityAddTraits(selectedTab == index ? .isSelected : [])
            }
        }
        .padding(.horizontal, 16)
        .padding(.top, 12)
        .padding(.bottom, 8)
        .background {
            Rectangle()
                .fill(Color(hex: "#E8ECF1")!
                    .shadow(.drop(color: Color(hex: "#A3B1C6")!.opacity(0.3), radius: 6, x: 0, y: -4)))
                .ignoresSafeArea(.container, edges: .bottom)
        }
    }

    @ViewBuilder
    private func tactileIcon(systemName: String, isActive: Bool) -> some View {
        let circleSize: CGFloat = 44
        let cornerRadius: CGFloat = 14

        ZStack {
            if isActive {
                // Pressed / inset neumorphic effect
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(Color(hex: "#E8ECF1")!)
                    .frame(width: circleSize, height: circleSize)
                    .overlay(
                        RoundedRectangle(cornerRadius: cornerRadius)
                            .stroke(Color(hex: "#D1D5DB")!.opacity(0.5), lineWidth: 0.5)
                    )
                    .overlay(
                        // Simulate inset shadow with inner shadow technique
                        RoundedRectangle(cornerRadius: cornerRadius)
                            .fill(
                                .shadow(.inner(color: Color(hex: "#A3B1C6")!.opacity(0.5), radius: 3, x: 3, y: 3))
                                .shadow(.inner(color: Color.white.opacity(0.7), radius: 3, x: -3, y: -3))
                            )
                            .foregroundStyle(Color(hex: "#E8ECF1")!)
                    )
            } else {
                // Raised neumorphic effect
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(Color(hex: "#E8ECF1")!)
                    .frame(width: circleSize, height: circleSize)
                    .shadow(color: Color(hex: "#A3B1C6")!.opacity(0.5), radius: 3, x: 3, y: 3)
                    .shadow(color: Color.white.opacity(0.7), radius: 3, x: -3, y: -3)
            }

            Image(systemName: systemName)
                .font(.system(size: 18, weight: .medium))
                .symbolRenderingMode(.hierarchical)
                .foregroundStyle(isActive ? DailyArcTokens.accent : theme.textSecondary)
        }
        .frame(width: circleSize, height: circleSize)
    }

    // MARK: - Command (Sci-Fi) Tab Bar

    private var commandTabBar: some View {
        HStack(spacing: 0) {
            ForEach(Array(tabs.enumerated()), id: \.offset) { index, tab in
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        selectedTab = index
                    }
                } label: {
                    VStack(spacing: 6) {
                        Image(systemName: tab.icon)
                            .font(.system(size: 20, weight: .medium))
                            .foregroundStyle(selectedTab == index ? CommandTheme.cyan : Color.white)
                            .opacity(selectedTab == index ? 1.0 : 0.4)

                        Text(tab.label.uppercased())
                            .font(.system(size: 9, weight: .semibold))
                            .tracking(1.0) // letter-spacing 0.1em equivalent
                            .foregroundStyle(selectedTab == index ? CommandTheme.cyan : Color.white.opacity(0.35))

                        // Active indicator dot
                        Circle()
                            .fill(selectedTab == index ? CommandTheme.cyan : Color.clear)
                            .frame(width: 4, height: 4)
                            .shadow(
                                color: selectedTab == index ? CommandTheme.cyan.opacity(0.5) : .clear,
                                radius: 4, x: 0, y: 0
                            )
                    }
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(.plain)
                .accessibilityLabel(tab.label)
                .accessibilityAddTraits(selectedTab == index ? .isSelected : [])
            }
        }
        .padding(.horizontal, 16)
        .padding(.top, 10)
        .padding(.bottom, 6)
        .background(
            ZStack {
                Color.black.opacity(0.9)
                    .background(.ultraThinMaterial)
            }
            .ignoresSafeArea(.container, edges: .bottom)
        )
        .overlay(alignment: .top) {
            Rectangle()
                .fill(Color(hex: "#6366F1")!.opacity(0.1))
                .frame(height: 1)
        }
    }
}
