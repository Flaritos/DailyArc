import SwiftUI

/// Empty state shown when the user has no habits.
/// Features a decorative 270-degree arc motif behind the icon.
struct EmptyStateView: View {
    @State private var pulseOpacity: Double = 0.6

    var body: some View {
        VStack(spacing: DailyArcSpacing.xl) {
            Spacer()

            ZStack {
                // Decorative arc motif behind the icon
                AppIconView(size: 120)
                    .opacity(pulseOpacity)
                    .onAppear {
                        withAnimation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true)) {
                            pulseOpacity = 0.3
                        }
                    }

                Image(systemName: "sparkles")
                    .font(.system(size: 40))
                    .symbolRenderingMode(.hierarchical)
                    .foregroundStyle(DailyArcTokens.accent)
            }

            VStack(spacing: DailyArcSpacing.sm) {
                Text("No habits yet")
                    .typography(.titleMedium)
                    .foregroundStyle(DailyArcTokens.textPrimary)

                Text("Tap + to create your first one.")
                    .typography(.bodySmall)
                    .foregroundStyle(DailyArcTokens.textSecondary)
            }

            Spacer()
        }
        .frame(maxWidth: .infinity)
        .padding(DailyArcSpacing.xl)
    }
}

#Preview {
    EmptyStateView()
}
