import SwiftUI

/// Cinematic full-screen modal that presents a single correlation result dramatically.
/// Command theme: intelligence briefing with typewriter text.
/// Tactile theme: warm card with large stats.
struct InsightTheaterView: View {
    @Environment(\.theme) private var theme
    @Environment(\.dismiss) private var dismiss

    let result: CorrelationEngine.CorrelationResult

    // Command typing animation state
    @State private var visibleLineCount = 0
    @State private var cursorVisible = true
    @State private var dismissed = false

    private var isCommand: Bool { theme.id == "command" }

    // MARK: - Computed Data

    private var differentialPercent: Int {
        guard result.averageMoodOnSkipDays > 0 else { return 0 }
        return Int(((result.averageMoodOnHabitDays - result.averageMoodOnSkipDays) / result.averageMoodOnSkipDays) * 100)
    }

    private var confidenceLabel: String {
        switch result.sampleSize {
        case ..<20: return "LOW"
        case 20..<40: return "MODERATE"
        default: return "HIGH"
        }
    }

    private var isStrongCorrelation: Bool {
        abs(result.coefficient) >= 0.3
    }

    // Command briefing lines
    private var briefingLines: [String] {
        let diffSign = differentialPercent >= 0 ? "+" : ""
        return [
            "> PATTERN DETECTED",
            "> CORRELATION: \(result.habitName.uppercased()) \u{2194} MOOD",
            "> ON \(result.habitName.uppercased()) DAYS, MOOD AVERAGES \(String(format: "%.1f", result.averageMoodOnHabitDays))",
            "> ON NON-\(result.habitName.uppercased()) DAYS, MOOD AVERAGES \(String(format: "%.1f", result.averageMoodOnSkipDays))",
            "> DIFFERENTIAL: \(diffSign)\(differentialPercent)%",
            "> CONFIDENCE: \(confidenceLabel) (\(result.sampleSize) DATA POINTS)",
            "> RECOMMENDATION: KEEP DOING \(result.habitName.uppercased())"
        ]
    }

    var body: some View {
        if isCommand {
            commandPresentation
        } else {
            tactilePresentation
        }
    }

    // MARK: - Command Theme

    private var commandPresentation: some View {
        ZStack {
            // Dark background with subtle grid
            Color.black
                .ignoresSafeArea()
                .overlay(
                    Canvas { context, size in
                        let spacing: CGFloat = 30
                        let color = Color(hex: "#6366F1")!.opacity(0.06)
                        for x in stride(from: 0, to: size.width, by: spacing) {
                            var path = Path()
                            path.move(to: CGPoint(x: x, y: 0))
                            path.addLine(to: CGPoint(x: x, y: size.height))
                            context.stroke(path, with: .color(color), lineWidth: 0.5)
                        }
                        for y in stride(from: 0, to: size.height, by: spacing) {
                            var path = Path()
                            path.move(to: CGPoint(x: 0, y: y))
                            path.addLine(to: CGPoint(x: size.width, y: y))
                            context.stroke(path, with: .color(color), lineWidth: 0.5)
                        }
                    }
                    .ignoresSafeArea()
                )

            VStack(alignment: .leading, spacing: DailyArcSpacing.lg) {
                Spacer()

                // Header
                Text("[INSIGHT]")
                    .font(.system(size: 14, weight: .bold, design: .monospaced))
                    .foregroundStyle(CommandTheme.cyan)
                    .shadow(color: CommandTheme.glowCyan, radius: 12, x: 0, y: 0)
                    .tracking(2)

                // Priority badge
                if isStrongCorrelation {
                    Text("PRIORITY ALPHA")
                        .font(.system(size: 11, weight: .bold, design: .monospaced))
                        .foregroundStyle(.black)
                        .padding(.horizontal, DailyArcSpacing.sm)
                        .padding(.vertical, DailyArcSpacing.xxs)
                        .background(CommandTheme.cyan)
                        .clipShape(RoundedRectangle(cornerRadius: 2))
                }

                // Typing lines
                VStack(alignment: .leading, spacing: DailyArcSpacing.sm) {
                    ForEach(Array(briefingLines.enumerated()), id: \.offset) { index, line in
                        if index < visibleLineCount {
                            HStack(spacing: 0) {
                                Text(line)
                                    .font(.system(size: 13, weight: .medium, design: .monospaced))
                                    .foregroundStyle(
                                        index == briefingLines.count - 1
                                            ? CommandTheme.cyan
                                            : Color.white.opacity(0.85)
                                    )
                                    .shadow(
                                        color: index == briefingLines.count - 1 ? CommandTheme.glowCyanStrong : .clear,
                                        radius: index == briefingLines.count - 1 ? 8 : 0,
                                        x: 0, y: 0
                                    )

                                // Blinking cursor on last visible line
                                if index == visibleLineCount - 1 {
                                    Text("\u{2588}")
                                        .font(.system(size: 13, weight: .medium, design: .monospaced))
                                        .foregroundStyle(CommandTheme.cyan)
                                        .opacity(cursorVisible ? 1 : 0)
                                }
                            }
                            .transition(.opacity.combined(with: .move(edge: .leading)))
                        }
                    }
                }

                Spacer()

                // Dismiss button
                if visibleLineCount >= briefingLines.count {
                    Button {
                        dismiss()
                    } label: {
                        Text("[ GOT IT ]")
                            .font(.system(size: 14, weight: .bold, design: .monospaced))
                            .foregroundStyle(CommandTheme.cyan)
                            .tracking(1)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, DailyArcSpacing.md)
                            .background(CommandTheme.cyan.opacity(0.08))
                            .overlay(
                                RoundedRectangle(cornerRadius: 2)
                                    .stroke(CommandTheme.cyan.opacity(0.4), lineWidth: 1)
                            )
                            .shadow(color: CommandTheme.glowCyan, radius: 12, x: 0, y: 0)
                    }
                    .transition(.opacity)
                }
            }
            .padding(DailyArcSpacing.xl)
        }
        .onAppear {
            startCommandSequence()
        }
    }

    private func startCommandSequence() {
        // Cursor blink using SwiftUI animation (auto-cancels on view disappear)
        withAnimation(.easeInOut(duration: 0.5).repeatForever(autoreverses: true)) {
            cursorVisible = false
        }

        // Type each line using Task (auto-cancels when view disappears)
        Task {
            for i in 0..<briefingLines.count {
                try? await Task.sleep(for: .milliseconds(300))
                guard !Task.isCancelled else { break }
                withAnimation(.easeOut(duration: 0.15)) {
                    visibleLineCount = i + 1
                }
            }
        }
    }

    // MARK: - Tactile Theme

    private var tactilePresentation: some View {
        ZStack {
            Color(hex: "#E8ECF1")!
                .ignoresSafeArea()

            VStack(spacing: DailyArcSpacing.xxl) {
                Spacer()

                // Emoji
                Text(result.emoji)
                    .font(.system(size: 64))
                    .scaleEffect(dismissed ? 0.8 : 1.0)

                // Big stat
                let diffSign = differentialPercent >= 0 ? "+" : ""
                Text("\(diffSign)\(differentialPercent)% mood improvement")
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundStyle(Color(hex: "#334155")!)
                    .multilineTextAlignment(.center)

                // Supporting detail
                VStack(spacing: DailyArcSpacing.sm) {
                    Text("On \(result.sampleSize) days when you did \(result.habitName),")
                        .typography(.bodySmall)
                        .foregroundStyle(Color(hex: "#64748B")!)

                    Text("your mood averaged \(String(format: "%.1f", result.averageMoodOnHabitDays)) vs \(String(format: "%.1f", result.averageMoodOnSkipDays))")
                        .typography(.bodySmall)
                        .foregroundStyle(Color(hex: "#64748B")!)
                }
                .multilineTextAlignment(.center)
                .padding(.horizontal, DailyArcSpacing.xl)
                .padding(DailyArcSpacing.lg)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color(hex: "#E8ECF1")!)
                        .shadow(color: Color.white.opacity(0.8), radius: 12, x: -6, y: -6)
                        .shadow(color: Color(hex: "#A3B1C6")!.opacity(0.6), radius: 12, x: 6, y: 6)
                )

                Spacer()

                // Dismiss button
                Button {
                    dismiss()
                } label: {
                    Text("Got it")
                        .font(.system(size: 17, weight: .semibold, design: .rounded))
                        .foregroundStyle(Color(hex: "#334155")!)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, DailyArcSpacing.md)
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(Color(hex: "#E8ECF1")!)
                                .shadow(color: Color.white.opacity(0.8), radius: 8, x: -4, y: -4)
                                .shadow(color: Color(hex: "#A3B1C6")!.opacity(0.5), radius: 8, x: 4, y: 4)
                        )
                }
            }
            .padding(DailyArcSpacing.xl)
        }
        .scaleEffect(dismissed ? 0.95 : 1.0)
        .animation(.spring(response: 0.5, dampingFraction: 0.8), value: dismissed)
    }
}
