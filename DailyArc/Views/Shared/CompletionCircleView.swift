import SwiftUI

/// A 270-degree arc that fills proportionally based on count/targetCount.
/// Used in habit rows and the overall progress header.
struct CompletionCircleView: View {
    let count: Int
    let targetCount: Int
    let size: CGFloat
    let lineWidth: CGFloat
    let color: Color

    /// The arc sweep angle in degrees (270 degrees total).
    private let totalArcDegrees: Double = 270

    /// Start angle offset: bottom-left of the arc (135 degrees from the top).
    private let startAngle: Double = 135

    private var progress: Double {
        guard targetCount > 0 else { return 0 }
        return min(Double(count) / Double(targetCount), 1.0)
    }

    private var isComplete: Bool {
        count >= targetCount
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

            // Fill
            Circle()
                .trim(from: 0, to: progress * (totalArcDegrees / 360))
                .rotation(.degrees(startAngle))
                .stroke(
                    color,
                    style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
                )

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
        .animation(.easeInOut(duration: 0.3), value: count)
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
