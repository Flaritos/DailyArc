import SwiftUI

/// A premium aurora effect that appears when any habit reaches a 30+ day streak.
/// Renders theme-specific gradient ribbons with slow oscillation animation.
/// - Tactile: Warm peach, rose, and gold gradient ribbons undulating slowly.
/// - Command: Electric cyan and green bands with interference effect and status line.
struct StreakAuroraView: View {
    let streakLength: Int
    let theme: any ThemeDefinition

    @State private var phase: CGFloat = 0

    /// Aurora opacity scales with streak length.
    private var auroraOpacity: CGFloat {
        switch streakLength {
        case 365...: return 1.0
        case 90..<365: return 0.7
        case 60..<90: return 0.5
        case 30..<60: return 0.3
        default: return 0
        }
    }

    private var isCommand: Bool { theme.id == "command" }

    var body: some View {
        VStack(spacing: 0) {
            ZStack {
                if isCommand {
                    commandAurora
                } else {
                    tactileAurora
                }

                // Command status line
                if isCommand {
                    VStack {
                        Spacer()
                        Text("[STREAK ENERGY DETECTED]")
                            .font(.system(size: 8, weight: .medium, design: .monospaced))
                            .foregroundStyle(Color(hex: "#22D3EE")!.opacity(0.5 * auroraOpacity))
                            .tracking(1.5)
                            .padding(.bottom, 6)
                    }
                }
            }
            .frame(height: 80)
            .clipped()

            Spacer()
        }
        .allowsHitTesting(false)
        .onAppear {
            withAnimation(.linear(duration: 6).repeatForever(autoreverses: false)) {
                phase = 1
            }
        }
    }

    // MARK: - Tactile Aurora

    private var tactileAurora: some View {
        Canvas { context, size in
            let time = phase * .pi * 2

            // Three ribbon layers with different phases
            for i in 0..<3 {
                let ribbonPhase = time + CGFloat(i) * (.pi / 3)
                let yOffset = sin(ribbonPhase) * 12 + CGFloat(i) * 8

                var path = Path()
                path.move(to: CGPoint(x: 0, y: 20 + yOffset))

                for x in stride(from: 0, through: size.width, by: 4) {
                    let normalizedX = x / size.width
                    let wave1 = sin(normalizedX * .pi * 3 + ribbonPhase) * 15
                    let wave2 = sin(normalizedX * .pi * 5 + ribbonPhase * 1.3) * 8
                    let y = 30 + yOffset + wave1 + wave2 + CGFloat(i) * 10
                    path.addLine(to: CGPoint(x: x, y: y))
                }

                path.addLine(to: CGPoint(x: size.width, y: size.height))
                path.addLine(to: CGPoint(x: 0, y: size.height))
                path.closeSubpath()

                let colors: [Color] = [
                    Color(hex: "#FBBF24")!,  // gold
                    Color(hex: "#F472B6")!,  // rose
                    Color(hex: "#FB923C")!,  // peach
                ]

                let gradient = Gradient(colors: [
                    colors[i].opacity(auroraOpacity * 0.6),
                    colors[i].opacity(auroraOpacity * 0.2),
                    colors[i].opacity(0),
                ])

                context.fill(
                    path,
                    with: .linearGradient(
                        gradient,
                        startPoint: CGPoint(x: size.width / 2, y: 0),
                        endPoint: CGPoint(x: size.width / 2, y: size.height)
                    )
                )
            }
        }
    }

    // MARK: - Command Aurora

    private var commandAurora: some View {
        Canvas { context, size in
            let time = phase * .pi * 2

            // Two primary bands: cyan and green
            let bandConfigs: [(color: Color, phaseOffset: CGFloat, frequency: CGFloat)] = [
                (Color(hex: "#22D3EE")!, 0, 4),            // cyan
                (Color(hex: "#22C55E")!, .pi / 2, 5),      // green
                (Color(hex: "#22D3EE")!, .pi, 3),           // cyan interference
            ]

            for config in bandConfigs {
                let ribbonPhase = time + config.phaseOffset

                var path = Path()
                path.move(to: CGPoint(x: 0, y: 15))

                for x in stride(from: 0, through: size.width, by: 3) {
                    let normalizedX = x / size.width
                    let wave1 = sin(normalizedX * .pi * config.frequency + ribbonPhase) * 12
                    let wave2 = cos(normalizedX * .pi * 2.5 + ribbonPhase * 0.7) * 6
                    // Interference pattern
                    let interference = sin(normalizedX * .pi * 8 + ribbonPhase * 2) * 3
                    let y = 25 + wave1 + wave2 + interference
                    path.addLine(to: CGPoint(x: x, y: y))
                }

                path.addLine(to: CGPoint(x: size.width, y: size.height))
                path.addLine(to: CGPoint(x: 0, y: size.height))
                path.closeSubpath()

                let gradient = Gradient(colors: [
                    config.color.opacity(auroraOpacity * 0.4),
                    config.color.opacity(auroraOpacity * 0.15),
                    config.color.opacity(0),
                ])

                context.fill(
                    path,
                    with: .linearGradient(
                        gradient,
                        startPoint: CGPoint(x: size.width / 2, y: 0),
                        endPoint: CGPoint(x: size.width / 2, y: size.height)
                    )
                )
            }

            // Scanline interference overlay for command theme
            for y in stride(from: 0, through: size.height, by: 4) {
                var line = Path()
                line.move(to: CGPoint(x: 0, y: y))
                line.addLine(to: CGPoint(x: size.width, y: y))
                context.stroke(
                    line,
                    with: .color(Color.black.opacity(0.15 * auroraOpacity)),
                    lineWidth: 1
                )
            }
        }
    }
}
