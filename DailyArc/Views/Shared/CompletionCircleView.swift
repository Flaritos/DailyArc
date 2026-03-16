import SwiftUI

/// A 270-degree arc that fills proportionally based on count/targetCount.
/// Used in habit rows and the overall progress header.
/// Animates from 0 to current progress on appear, and smoothly transitions on change.
struct CompletionCircleView: View {
    let count: Int
    let targetCount: Int
    let size: CGFloat
    let lineWidth: CGFloat
    let color: Color
    var useGradient: Bool = false

    /// The arc sweep angle in degrees (270 degrees total).
    private let totalArcDegrees: Double = 270

    /// Start angle offset: bottom-left of the arc (135 degrees from the top).
    private let startAngle: Double = 135

    /// Animated progress drives the arc fill — starts at 0, animates to actual progress.
    @State private var animatedProgress: CGFloat = 0

    /// Flash effect: briefly scales stroke to 1.5x on completion
    @State private var flashStroke: Bool = false

    private var progress: Double {
        guard targetCount > 0 else { return 0 }
        return min(Double(count) / Double(targetCount), 1.0)
    }

    private var isComplete: Bool {
        count >= targetCount
    }

    private var currentLineWidth: CGFloat {
        flashStroke ? lineWidth * 1.5 : lineWidth
    }

    private var fillStyle: some ShapeStyle {
        if useGradient {
            return AnyShapeStyle(DailyArcTokens.brandGradient)
        }
        return AnyShapeStyle(color)
    }

    var body: some View {
        ZStack {
            // Track
            Circle()
                .trim(from: 0, to: totalArcDegrees / 360)
                .rotation(.degrees(startAngle))
                .stroke(
                    DailyArcTokens.border.opacity(0.3),
                    style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
                )

            // Fill — uses animatedProgress for smooth draw-on animation
            Circle()
                .trim(from: 0, to: animatedProgress * (totalArcDegrees / 360))
                .rotation(.degrees(startAngle))
                .stroke(
                    fillStyle,
                    style: StrokeStyle(lineWidth: currentLineWidth, lineCap: .round)
                )
                .animation(.easeOut(duration: 0.2), value: flashStroke)

            // Checkmark for complete
            if isComplete {
                Image(systemName: "checkmark")
                    .font(.system(size: size * 0.35, weight: .bold))
                    .foregroundStyle(color)
            } else if targetCount > 1 {
                Text("\(count)")
                    .font(.system(size: size * 0.3, weight: .semibold))
                    .foregroundStyle(DailyArcTokens.textSecondary)
            }
        }
        .frame(width: size, height: size)
        .onAppear {
            // Animate from 0 to current progress on first appearance
            withAnimation(.easeOut(duration: 0.8)) {
                animatedProgress = progress
            }
        }
        .onChange(of: count) { _, _ in
            // Smoothly animate to new progress when habits are completed
            withAnimation(.easeInOut(duration: 0.6)) {
                animatedProgress = progress
            }
            // Completion ring flash — 1.5x stroke for 0.2s
            if progress >= 1.0 {
                flashStroke = true
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                    flashStroke = false
                }
            }
        }
    }
}

#Preview {
    HStack(spacing: 20) {
        CompletionCircleView(count: 0, targetCount: 1, size: 40, lineWidth: 4, color: .blue)
        CompletionCircleView(count: 1, targetCount: 1, size: 40, lineWidth: 4, color: .blue)
        CompletionCircleView(count: 2, targetCount: 5, size: 40, lineWidth: 4, color: .green)
        CompletionCircleView(count: 5, targetCount: 5, size: 40, lineWidth: 4, color: .green)
    }
    .padding()
}
