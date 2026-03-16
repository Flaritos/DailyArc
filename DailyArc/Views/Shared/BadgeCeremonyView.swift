import SwiftUI

/// Overlay presented when a new badge is earned.
/// Shows emoji with spring animation, badge name, celebration message, and dismiss button.
/// Auto-dismisses after 5 seconds.
struct BadgeCeremonyView: View {
    @Bindable var badgeEngine: BadgeEngine
    @State private var emojiScale: CGFloat = 0.3
    @State private var cardOpacity: Double = 0
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        if let badge = badgeEngine.pendingCeremony {
            ZStack {
                // Semi-transparent background
                Color.black.opacity(0.5)
                    .ignoresSafeArea()
                    .onTapGesture {
                        dismiss()
                    }

                // Card
                VStack(spacing: DailyArcSpacing.xl) {
                    Text(badge.emoji)
                        .font(.system(size: 60))
                        .scaleEffect(emojiScale)

                    VStack(spacing: DailyArcSpacing.sm) {
                        Text(badge.name)
                            .typography(.titleMedium)
                            .foregroundStyle(DailyArcTokens.textPrimary)

                        Text("Badge unlocked!")
                            .typography(.bodySmall)
                            .foregroundStyle(DailyArcTokens.textSecondary)

                        Text(badge.description)
                            .typography(.caption)
                            .foregroundStyle(DailyArcTokens.textTertiary)
                    }

                    Button {
                        dismiss()
                    } label: {
                        Text("Nice!")
                            .typography(.bodySmall)
                            .fontWeight(.semibold)
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, DailyArcSpacing.md)
                            .background(
                                RoundedRectangle(cornerRadius: DailyArcTokens.cornerRadiusMedium)
                                    .fill(DailyArcTokens.accent)
                            )
                    }
                }
                .padding(DailyArcSpacing.xl)
                .background(
                    RoundedRectangle(cornerRadius: DailyArcTokens.cornerRadiusLarge)
                        .fill(DailyArcTokens.backgroundPrimary)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: DailyArcTokens.cornerRadiusLarge)
                        .stroke(DailyArcTokens.separator, lineWidth: DailyArcTokens.borderThin)
                )
                .shadow(color: DailyArcTokens.cardShadow, radius: 20, y: 8)
                .padding(.horizontal, DailyArcSpacing.xxl)
                .opacity(cardOpacity)
            }
            .transition(.opacity)
            .onAppear {
                if reduceMotion {
                    emojiScale = 1.0
                    cardOpacity = 1.0
                } else {
                    withAnimation(.spring(response: 0.5, dampingFraction: 0.6)) {
                        emojiScale = 1.0
                    }
                    withAnimation(.easeIn(duration: 0.25)) {
                        cardOpacity = 1.0
                    }
                }
                // Auto-dismiss after 5 seconds
                DispatchQueue.main.asyncAfter(deadline: .now() + 5.0) {
                    dismiss()
                }
            }
            .accessibilityElement(children: .combine)
            .accessibilityLabel("Badge unlocked: \(badge.name). \(badge.description)")
            .accessibilityAddTraits(.isModal)
        }
    }

    private func dismiss() {
        withAnimation(.easeOut(duration: 0.2)) {
            badgeEngine.pendingCeremony = nil
        }
    }
}
