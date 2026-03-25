import SwiftUI

// MARK: - Themed Progress Ring

/// A circular progress indicator that adapts to the current theme.
/// Tactile: neumorphic dial with raised bezel and pressed face.
/// Command: concentric rings with cyan glow.
struct ThemedProgressRing: View {
    let progress: Double // 0.0 to 1.0
    let size: CGFloat
    let lineWidth: CGFloat
    let theme: any ThemeDefinition
    let habitProgresses: [(color: Color, progress: Double)]

    init(progress: Double, size: CGFloat = 220, lineWidth: CGFloat = 8, theme: any ThemeDefinition, habitProgresses: [(color: Color, progress: Double)] = []) {
        self.progress = min(max(progress, 0), 1)
        self.size = size
        self.lineWidth = lineWidth
        self.theme = theme
        self.habitProgresses = habitProgresses
    }

    var body: some View {
        if theme.id == "command" {
            commandRing
        } else {
            tactileRing
        }
    }

    // MARK: - Tactile (Neumorphic Dial)

    private var tactileRing: some View {
        ZStack {
            // Outer bezel (floating shadow)
            Circle()
                .fill(Color(hex: "#E8ECF1")!)
                .frame(width: size, height: size)
                .shadow(color: Color.white.opacity(0.9), radius: 20, x: -10, y: -10)
                .shadow(color: Color(hex: "#A3B1C6")!.opacity(0.5), radius: 20, x: 10, y: 10)

            // Inner face (pressed)
            Circle()
                .fill(Color(hex: "#E8ECF1")!)
                .frame(width: size * 0.818, height: size * 0.818)
                .shadow(color: Color(hex: "#A3B1C6")!.opacity(0.6), radius: 12, x: 6, y: 6)
                .shadow(color: Color.white.opacity(0.8), radius: 12, x: -6, y: -6)
                .clipShape(Circle())

            // Progress arc
            Circle()
                .trim(from: 0, to: progress)
                .stroke(
                    LinearGradient(
                        colors: [Color(hex: "#6366F1")!, Color(hex: "#EC4899")!],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
                )
                .frame(width: size * 0.682, height: size * 0.682)
                .rotationEffect(.degrees(-90))
                .shadow(color: Color(hex: "#6366F1")!.opacity(0.4), radius: 4, x: 0, y: 0)

            // Background track
            Circle()
                .trim(from: 0, to: 1.0) // Full circle
                .stroke(Color(hex: "#A3B1C6")!.opacity(0.2), lineWidth: lineWidth)
                .frame(width: size * 0.682, height: size * 0.682)
                .rotationEffect(.degrees(-90))

            // Center percentage
            VStack(spacing: 2) {
                Text("\(Int(progress * 100))%")
                    .font(.system(size: size * 0.2, weight: .heavy))
                    .foregroundStyle(Color(hex: "#334155")!)
                Text("COMPLETE")
                    .font(.system(size: size * 0.05, weight: .semibold))
                    .foregroundStyle(Color(hex: "#64748B")!)
                    .tracking(1)
            }
        }
    }

    // MARK: - Command (HUD Ring)

    @State private var pulseRadius: CGFloat = 10

    // Per-habit ring radii as fractions of size (outer to inner)
    private static let habitRingRadii: [CGFloat] = [0.97, 0.78, 0.65]

    private var commandRing: some View {
        ZStack {
            // Per-habit concentric rings (up to 3)
            let rings = Array(habitProgresses.prefix(3))
            if rings.isEmpty {
                // Fallback: decorative concentric rings when no habit data
                Circle()
                    .stroke(CommandTheme.cyan.opacity(0.15), lineWidth: 2)
                    .frame(width: size, height: size)
                Circle()
                    .stroke(CommandTheme.indigo.opacity(0.2), style: StrokeStyle(lineWidth: 1.5, dash: [4, 4]))
                    .frame(width: size * 0.78, height: size * 0.78)
                Circle()
                    .stroke(CommandTheme.cyan.opacity(0.1), lineWidth: 1)
                    .frame(width: size * 0.58, height: size * 0.58)
            } else {
                ForEach(Array(rings.enumerated()), id: \.offset) { index, habitRing in
                    let radius = Self.habitRingRadii[index]
                    let ringSize = size * radius

                    // Background track (270 degree arc)
                    Circle()
                        .trim(from: 0, to: 0.75)
                        .stroke(habitRing.color.opacity(0.1), lineWidth: 2)
                        .frame(width: ringSize, height: ringSize)
                        .rotationEffect(.degrees(135))

                    // Progress arc
                    Circle()
                        .trim(from: 0, to: min(habitRing.progress, 1.0) * 0.75)
                        .stroke(habitRing.color.opacity(0.8), style: StrokeStyle(lineWidth: 2, lineCap: .round))
                        .frame(width: ringSize, height: ringSize)
                        .rotationEffect(.degrees(135))
                        .shadow(color: habitRing.color.opacity(0.4), radius: 4, x: 0, y: 0)
                }
            }

            // Overall progress arc (main outer ring) — 3px stroke per spec
            Circle()
                .trim(from: 0, to: progress * 0.75) // 270 degree arc
                .stroke(
                    LinearGradient(
                        colors: [CommandTheme.cyan, CommandTheme.indigo],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    style: StrokeStyle(lineWidth: 3, lineCap: .round)
                )
                .frame(width: size * 0.94, height: size * 0.94)
                .rotationEffect(.degrees(-90))
                .shadow(color: CommandTheme.glowCyan, radius: 6, x: 0, y: 0)

            // Crosshairs
            Rectangle()
                .fill(CommandTheme.cyan.opacity(0.06))
                .frame(width: size, height: 1)
            Rectangle()
                .fill(CommandTheme.cyan.opacity(0.06))
                .frame(width: 1, height: size)

            // Center readout
            VStack(spacing: 2) {
                Text("\(Int(progress * 100))%")
                    .font(.system(size: size * 0.15, weight: .bold, design: .monospaced))
                    .foregroundStyle(CommandTheme.cyan)
                    .shadow(color: CommandTheme.glowCyan, radius: pulseRadius, x: 0, y: 0)
                    .dataFlicker(theme)
                Text("OPERATIONAL")
                    .font(.system(size: size * 0.04, weight: .semibold, design: .monospaced))
                    .foregroundStyle(Color.white.opacity(0.5))
                    .tracking(1.5)
            }
            .onAppear {
                withAnimation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true)) {
                    pulseRadius = 25
                }
            }
        }
    }
}

// MARK: - Themed Status Dot

/// A small colored indicator dot.
/// Tactile: simple colored circle.
/// Command: blinking dot with glow effect.
struct ThemedStatusDot: View {
    enum Status {
        case active, warning, error, inactive
    }

    let status: Status
    let theme: any ThemeDefinition
    @State private var isBlinking = false

    private var color: Color {
        switch status {
        case .active: return theme.success
        case .warning: return theme.warning
        case .error: return theme.error
        case .inactive: return theme.disabled
        }
    }

    private var blinkDuration: Double {
        switch status {
        case .active: return 2.0
        case .warning: return 1.5
        case .error: return 1.0
        case .inactive: return 0
        }
    }

    var body: some View {
        Circle()
            .fill(color)
            .frame(width: 8, height: 8)
            .shadow(color: theme.id == "command" ? color.opacity(0.3) : .clear, radius: theme.id == "command" ? 8 : 0)
            .opacity(isBlinking && theme.id == "command" && status != .inactive ? (status == .warning ? 0.4 : 0.3) : 1.0)
            .onAppear {
                guard theme.id == "command" && status != .inactive else { return }
                withAnimation(.easeInOut(duration: blinkDuration).repeatForever(autoreverses: true)) {
                    isBlinking = true
                }
            }
    }
}

// MARK: - Themed Divider

/// A section divider that adapts to the theme.
/// Tactile: soft gradient fade.
/// Command: thin cyan line.
struct ThemedDivider: View {
    let theme: any ThemeDefinition

    var body: some View {
        if theme.id == "command" {
            Rectangle()
                .fill(CommandTheme.cyan.opacity(0.15))
                .frame(height: 1)
        } else {
            Rectangle()
                .fill(
                    LinearGradient(
                        colors: [.clear, Color(hex: "#A3B1C6")!.opacity(0.3), .clear],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .frame(height: 1)
        }
    }
}

// MARK: - Themed Toggle

/// A toggle switch styled for the current theme.
/// Tactile: pill-shaped with sliding ball and neumorphic shadows.
/// Command: rectangular with sliding indicator and glow.
struct ThemedToggleStyle: ToggleStyle {
    let theme: any ThemeDefinition

    func makeBody(configuration: Configuration) -> some View {
        HStack {
            configuration.label
            Spacer()
            if theme.id == "command" {
                commandToggle(isOn: configuration.isOn, toggle: { configuration.isOn.toggle() })
            } else {
                tactileToggle(isOn: configuration.isOn, toggle: { configuration.isOn.toggle() })
            }
        }
    }

    private func tactileToggle(isOn: Bool, toggle: @escaping () -> Void) -> some View {
        ZStack {
            RoundedRectangle(cornerRadius: 15)
                .fill(isOn
                    ? LinearGradient(colors: [Color(hex: "#6366F1")!, Color(hex: "#818CF8")!], startPoint: .topLeading, endPoint: .bottomTrailing)
                    : LinearGradient(colors: [Color(hex: "#E8ECF1")!, Color(hex: "#E8ECF1")!], startPoint: .leading, endPoint: .trailing)
                )
                .frame(width: 56, height: 30)
                .shadow(color: isOn ? .clear : Color(hex: "#A3B1C6")!.opacity(0.5), radius: 6, x: 3, y: 3)
                .shadow(color: isOn ? .clear : Color.white.opacity(0.7), radius: 6, x: -3, y: -3)

            Circle()
                .fill(Color(hex: "#E8ECF1")!)
                .frame(width: 24, height: 24)
                .shadow(color: Color(hex: "#A3B1C6")!.opacity(0.5), radius: 4, x: 2, y: 2)
                .shadow(color: Color.white.opacity(0.7), radius: 4, x: -2, y: -2)
                .offset(x: isOn ? 13 : -13)
        }
        .animation(.spring(response: 0.3), value: isOn)
        .onTapGesture(perform: toggle)
    }

    private func commandToggle(isOn: Bool, toggle: @escaping () -> Void) -> some View {
        ZStack(alignment: isOn ? .trailing : .leading) {
            RoundedRectangle(cornerRadius: 2)
                .fill(CommandTheme.panel)
                .overlay(
                    RoundedRectangle(cornerRadius: 2)
                        .stroke(Color.white.opacity(0.15), lineWidth: 1)
                )
                .frame(width: 44, height: 22)
                .shadow(color: isOn ? CommandTheme.glowGreen : .clear, radius: 10, x: 0, y: 0)

            RoundedRectangle(cornerRadius: 1)
                .fill(isOn ? Color(hex: "#22C55E")! : Color.white.opacity(0.3))
                .frame(width: 14, height: 14)
                .padding(3)
                .shadow(color: isOn ? Color(hex: "#22C55E")!.opacity(0.5) : .clear, radius: 8, x: 0, y: 0)
        }
        .animation(.spring(response: 0.3), value: isOn)
        .onTapGesture(perform: toggle)
    }
}
