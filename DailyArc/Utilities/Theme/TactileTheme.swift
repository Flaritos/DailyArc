import SwiftUI

/// Neumorphic "Tactile Depth" theme.
/// Soft 3D surfaces, raised/pressed shadows, warm gray backgrounds.
/// Values match mockups/redesign-neomorphic.html and THEME_SPECS.md exactly.
struct TactileTheme: ThemeDefinition {
    let id = "tactile"
    let name = "Tactile"
    let forcedColorScheme: ColorScheme? = .light // neumorphic design requires light mode

    // MARK: - Colors

    // Neumorphic base gray
    let backgroundPrimary = Color(hex: "#E8ECF1")!
    let backgroundSecondary = Color(hex: "#E8ECF1")! // same base for neumorphic
    let backgroundTertiary = Color(hex: "#E8ECF1")!

    let textPrimary = Color(hex: "#334155")!
    let textSecondary = Color(hex: "#64748B")!
    let textTertiary = Color(hex: "#94A3B8")!

    let separator = Color(hex: "#A3B1C6")!.opacity(0.3)
    let border = Color(hex: "#A3B1C6")!.opacity(0.4)

    let success = Color(hex: "#10B981")!
    let warning = Color(hex: "#F97316")!
    let error = Color(hex: "#EF4444")!
    let info = Color(hex: "#6366F1")!

    let streakFire = Color(hex: "#F97316")!
    let premiumGold = Color(hex: "#B8860B")!
    let disabled = Color(hex: "#94A3B8")!
    let disabledText = Color(hex: "#94A3B8")!

    let brandGradient = LinearGradient(
        colors: [Color(hex: "#6366F1")!, Color(hex: "#EC4899")!],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    let cardBackground = Color(hex: "#E8ECF1")!
    let cardShadowColor = Color(hex: "#A3B1C6")!.opacity(0.6)

    // MARK: - Geometry

    let cornerRadiusSmall: CGFloat = 10
    let cornerRadiusMedium: CGFloat = 16
    let cornerRadiusLarge: CGFloat = 20
    let cornerRadiusCapsule: CGFloat = 24

    // MARK: - Typography

    let displayFontDesign: Font.Design = .default
    let bodyFontDesign: Font.Design = .default
    let uppercaseHeaders = false
    let headerPrefix = ""

    // MARK: - Interaction

    let pressedOpacity: CGFloat = 0.7
    let pressedScale: CGFloat = 0.95 // deeper press-in for tactile feel

    // MARK: - Overlays

    let showsGridOverlay = false
    let showsScanline = false
    let gridColor = Color.clear

    // MARK: - Card Styling

    func applyCardStyle(to content: AnyView, colorScheme: ColorScheme) -> AnyView {
        AnyView(
            content
                .padding(DailyArcSpacing.lg)
                .background(Color(hex: "#E8ECF1")!)
                .clipShape(RoundedRectangle(cornerRadius: 16))
                // Neumorphic raised shadow: light from top-left
                .shadow(color: Color.white.opacity(0.8), radius: 12, x: -6, y: -6)
                // Neumorphic dark shadow: dark from bottom-right
                .shadow(color: Color(hex: "#A3B1C6")!.opacity(0.6), radius: 12, x: 6, y: 6)
        )
    }

    func applyCardPressedStyle(to content: AnyView, colorScheme: ColorScheme) -> AnyView {
        AnyView(
            content
                .padding(DailyArcSpacing.lg)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color(hex: "#E8ECF1")!)
                )
                .clipShape(RoundedRectangle(cornerRadius: 16))
                // Brand gradient tint overlay
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color(hex: "#6366F1")!.opacity(0.12),
                                    Color(hex: "#EC4899")!.opacity(0.1)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                )
                // Inner shadow: dark from top-left for concave appearance
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color(hex: "#A3B1C6")!.opacity(0.4), lineWidth: 4)
                        .blur(radius: 4)
                        .offset(x: 2, y: 2)
                        .mask(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(
                                    LinearGradient(
                                        colors: [Color.black, Color.clear],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                        )
                )
                // Inner shadow: light from bottom-right for rim highlight
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.white.opacity(0.6), lineWidth: 4)
                        .blur(radius: 4)
                        .offset(x: -2, y: -2)
                        .mask(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(
                                    LinearGradient(
                                        colors: [Color.clear, Color.black],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                        )
                )
        )
    }
}
