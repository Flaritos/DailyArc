import SwiftUI

/// Overlay presented when a new badge is earned.
/// Shows emoji with spring animation, badge name, celebration message, and dismiss button.
/// Auto-dismisses after 5 seconds.
struct BadgeCeremonyView: View {
    @Bindable var badgeEngine: BadgeEngine
    @State private var emojiScale: CGFloat = 0.3
    @State private var cardOpacity: Double = 0
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.theme) private var theme

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
                            .fontDesign(theme.displayFontDesign)
                            .foregroundStyle(theme.textPrimary)

                        Text(theme.uppercaseHeaders ? "\(theme.headerPrefix)BADGE UNLOCKED!" : "Badge unlocked!")
                            .typography(.bodySmall)
                            .foregroundStyle(theme.textSecondary)

                        Text(badge.description)
                            .typography(.caption)
                            .foregroundStyle(theme.textTertiary)
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
                    RoundedRectangle(cornerRadius: theme.cornerRadiusLarge)
                        .fill(theme.backgroundPrimary)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: theme.cornerRadiusLarge)
                        .stroke(theme.id == "command" ? CommandTheme.cyan.opacity(0.4) : theme.separator, lineWidth: DailyArcTokens.borderThin)
                )
                .shadow(color: theme.id == "command" ? CommandTheme.glowCyan : theme.cardShadowColor, radius: 20, y: 8)
                .padding(.horizontal, DailyArcSpacing.xxl)
                .opacity(cardOpacity)
            }
            .transition(.opacity)
            .onAppear {
                HapticManager.badgeUnlock()
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
