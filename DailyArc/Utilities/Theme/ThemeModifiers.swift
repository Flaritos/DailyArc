import SwiftUI

// MARK: - Themed Card Modifier

/// Applies theme-appropriate card styling.
/// Tactile: neumorphic raised shadows on #E8ECF1 background.
/// Command: #111122 panel with cyan border and left accent bar.
struct ThemedCardModifier: ViewModifier {
    @Environment(\.colorScheme) private var colorScheme

    let theme: any ThemeDefinition

    func body(content: Content) -> some View {
        theme.applyCardStyle(to: AnyView(content), colorScheme: colorScheme)
    }
}

/// Applies theme-appropriate pressed/selected card styling.
struct ThemedCardPressedModifier: ViewModifier {
    @Environment(\.colorScheme) private var colorScheme

    let theme: any ThemeDefinition

    func body(content: Content) -> some View {
        theme.applyCardPressedStyle(to: AnyView(content), colorScheme: colorScheme)
    }
}

// MARK: - Grid Overlay

/// Adds a subtle grid line pattern overlay (Command theme only).
struct GridOverlayModifier: ViewModifier {
    let theme: any ThemeDefinition

    func body(content: Content) -> some View {
        if theme.showsGridOverlay {
            content.overlay {
                CommandGridOverlay()
                    .ignoresSafeArea()
                    .allowsHitTesting(false)
            }
        } else {
            content
        }
    }
}

/// The grid pattern for Command theme — subtle indigo lines at 30px intervals.
struct CommandGridOverlay: View {
    var body: some View {
        Canvas { context, size in
            let spacing: CGFloat = 30
            let lineColor = Color(hex: "#6366F1")!.opacity(0.08)

            // Vertical lines
            var x: CGFloat = 0
            while x < size.width {
                context.stroke(
                    Path { p in p.move(to: CGPoint(x: x, y: 0)); p.addLine(to: CGPoint(x: x, y: size.height)) },
                    with: .color(lineColor),
                    lineWidth: 1.0
                )
                x += spacing
            }
            // Horizontal lines
            var y: CGFloat = 0
            while y < size.height {
                context.stroke(
                    Path { p in p.move(to: CGPoint(x: 0, y: y)); p.addLine(to: CGPoint(x: size.width, y: y)) },
                    with: .color(lineColor),
                    lineWidth: 1.0
                )
                y += spacing
            }
        }
    }
}

// MARK: - Scanline Overlay

/// Adds a subtle CRT scanline sweep effect (Command theme only).
struct ScanlineModifier: ViewModifier {
    let theme: any ThemeDefinition
    @State private var offset: CGFloat = -2

    func body(content: Content) -> some View {
        if theme.showsScanline {
            content
                // Static CRT scanline pattern: 2px transparent, 2px dark at 3% opacity
                .overlay {
                    Canvas { context, size in
                        var y: CGFloat = 0
                        while y < size.height {
                            context.fill(
                                Path(CGRect(x: 0, y: y + 2, width: size.width, height: 2)),
                                with: .color(Color.black.opacity(0.03))
                            )
                            y += 4
                        }
                    }
                    .ignoresSafeArea()
                    .allowsHitTesting(false)
                }
                // Animated sweep overlay
                .overlay {
                    GeometryReader { geo in
                        Rectangle()
                            .fill(
                                LinearGradient(
                                    colors: [.clear, Color.white.opacity(0.03), .clear],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                            .frame(height: 4)
                            .offset(y: offset)
                            .onAppear {
                                withAnimation(.linear(duration: 4).repeatForever(autoreverses: false)) {
                                    offset = geo.size.height
                                }
                            }
                    }
                    .ignoresSafeArea()
                    .allowsHitTesting(false)
                }
        } else {
            content
        }
    }
}

// MARK: - Glow Effect

/// Adds a colored glow shadow effect (Command theme only, no-op on Tactile).
struct GlowModifier: ViewModifier {
    let color: Color
    let radius: CGFloat
    let theme: any ThemeDefinition

    func body(content: Content) -> some View {
        if theme.id == "command" {
            content.shadow(color: color.opacity(0.3), radius: radius, x: 0, y: 0)
        } else {
            content
        }
    }
}

// MARK: - Themed Section Header

/// Renders section headers with theme-appropriate styling.
/// Tactile: standard semibold text.
/// Command: uppercase monospace with ">" prefix and cyan color.
struct ThemedSectionHeaderModifier: ViewModifier {
    let theme: any ThemeDefinition

    func body(content: Content) -> some View {
        if theme.id == "command" {
            HStack(spacing: 0) {
                Text("> ")
                    .font(.system(.caption, design: .monospaced).weight(.semibold))
                    .foregroundStyle(CommandTheme.cyan)
                content
                    .font(.system(.caption, design: .monospaced).weight(.semibold))
                    .foregroundStyle(CommandTheme.cyan)
                    .textCase(.uppercase)
            }
            .tracking(1.5)
        } else {
            content
        }
    }
}

// MARK: - Data Flicker Effect

/// Adds a subtle data flicker effect (Command theme only).
/// Periodically dips opacity briefly to simulate CRT display refresh.
struct DataFlickerModifier: ViewModifier {
    let theme: any ThemeDefinition
    @State private var flickerPhase: Int = 0

    func body(content: Content) -> some View {
        if theme.id == "command" {
            content
                .opacity(flickerOpacity)
                .task {
                    while !Task.isCancelled {
                        try? await Task.sleep(for: .seconds(5))
                        guard !Task.isCancelled else { break }
                        withAnimation(.easeInOut(duration: 0.1)) { flickerPhase = 1 }
                        try? await Task.sleep(for: .milliseconds(100))
                        guard !Task.isCancelled else { break }
                        withAnimation(.easeInOut(duration: 0.1)) { flickerPhase = 2 }
                        try? await Task.sleep(for: .milliseconds(100))
                        guard !Task.isCancelled else { break }
                        withAnimation(.easeInOut(duration: 0.1)) { flickerPhase = 0 }
                    }
                }
        } else {
            content
        }
    }

    private var flickerOpacity: Double {
        switch flickerPhase {
        case 1: return 0.7
        case 2: return 0.9
        default: return 1.0
        }
    }
}

// MARK: - View Extensions

extension View {
    /// Apply theme-specific card styling (neumorphic or sci-fi panel).
    func themedCard(_ theme: any ThemeDefinition) -> some View {
        modifier(ThemedCardModifier(theme: theme))
    }

    /// Apply theme-specific pressed/selected card styling.
    func themedCardPressed(_ theme: any ThemeDefinition) -> some View {
        modifier(ThemedCardPressedModifier(theme: theme))
    }

    /// Add grid overlay (Command only, no-op on Tactile).
    func themedGridOverlay(_ theme: any ThemeDefinition) -> some View {
        modifier(GridOverlayModifier(theme: theme))
    }

    /// Add scanline sweep effect (Command only, no-op on Tactile).
    func themedScanline(_ theme: any ThemeDefinition) -> some View {
        modifier(ScanlineModifier(theme: theme))
    }

    /// Add glow shadow (Command only, no-op on Tactile).
    func themedGlow(_ theme: any ThemeDefinition, color: Color = CommandTheme.cyan, radius: CGFloat = 20) -> some View {
        modifier(GlowModifier(color: color, radius: radius, theme: theme))
    }

    /// Apply themed section header styling.
    func themedSectionHeader(_ theme: any ThemeDefinition) -> some View {
        modifier(ThemedSectionHeaderModifier(theme: theme))
    }

    /// Add data flicker effect (Command only, no-op on Tactile).
    func dataFlicker(_ theme: any ThemeDefinition) -> some View {
        modifier(DataFlickerModifier(theme: theme))
    }
}
