import SwiftUI

/// 365-day celebration: full 360 golden arc that draws itself, then pulses.
/// Triggered by CelebrationService when a habit reaches a 365-day streak.
struct AnnualArcView: View {
    @State private var progress: CGFloat = 0
    @State private var pulseScale: CGFloat = 1.0

    var body: some View {
        ZStack {
            // Track ring (subtle)
            Circle()
                .stroke(
                    DailyArcTokens.premiumGold.opacity(0.15),
                    style: StrokeStyle(lineWidth: 6, lineCap: .round)
                )
                .frame(width: 200, height: 200)

            // Golden arc that draws from 0 to 360 degrees
            Circle()
                .trim(from: 0, to: progress)
                .rotation(.degrees(-90))
                .stroke(
                    DailyArcTokens.premiumGold,
                    style: StrokeStyle(lineWidth: 6, lineCap: .round)
                )
                .frame(width: 200, height: 200)
                .scaleEffect(pulseScale)

            // Center label
            VStack(spacing: DailyArcSpacing.xs) {
                Text("365")
                    .font(.system(size: 48, weight: .bold, design: .rounded))
                    .foregroundStyle(DailyArcTokens.premiumGold)
                    .scaleEffect(pulseScale)

                Text("days")
                    .typography(.caption)
                    .foregroundStyle(DailyArcTokens.textSecondary)
            }
        }
        .onAppear {
            // Phase 1: Draw the full arc over 1.5 seconds
            withAnimation(.easeInOut(duration: 1.5)) {
                progress = 1.0
            }

            // Phase 2: Pulse scale 1.0 -> 1.15 after arc completes
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                withAnimation(.easeInOut(duration: 0.3)) {
                    pulseScale = 1.15
                }

                // Phase 3: Scale back to 1.0
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        pulseScale = 1.0
                    }
                }
            }
        }
    }
}

#Preview {
    AnnualArcView()
        .padding()
}
