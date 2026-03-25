import SwiftUI

/// Sci-fi "Command Center" theme.
/// OLED black, cyan accents, monospace readouts, grid overlays, glow effects.
/// Values match mockups/redesign-scifi-command.html and THEME_SPECS.md exactly.
struct CommandTheme: ThemeDefinition {
    let id = "command"
    let name = "Command"
    let forcedColorScheme: ColorScheme? = .dark // always dark

    // MARK: - Colors

    let backgroundPrimary = Color(hex: "#000000")!      // OLED black
    let backgroundSecondary = Color(hex: "#0A0A14")!     // surface
    let backgroundTertiary = Color(hex: "#111122")!      // panel

    let textPrimary = Color(hex: "#E2E8F0")!
    let textSecondary = Color.white.opacity(0.5)
    let textTertiary = Color.white.opacity(0.3)

    let separator = Color.white.opacity(0.04)
    let border = Color(hex: "#6366F1")!.opacity(0.12)

    let success = Color(hex: "#22C55E")!
    let warning = Color(hex: "#EAB308")!
    let error = Color(hex: "#EF4444")!
    let info = Color(hex: "#22D3EE")!

    let streakFire = Color(hex: "#F97316")!
    let premiumGold = Color(hex: "#FFE44D")!
    let disabled = Color.white.opacity(0.15)
    let disabledText = Color.white.opacity(0.3)

    let brandGradient = LinearGradient(
        colors: [Color(hex: "#22D3EE")!, Color(hex: "#6366F1")!],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    let cardBackground = Color(hex: "#111122")!
    let cardShadowColor = Color.clear // no drop shadows, use glows

    // MARK: - Command-Specific Colors

    /// Accent color that adapts to the user's selected command color scheme.
    /// Reads from ThemeManager.shared.commandColorScheme so all references
    /// throughout the app automatically pick up the custom scheme.
    static var cyan: Color {
        accentForScheme(
            UserDefaults.standard.string(forKey: "commandColorScheme") ?? "cyan"
        )
    }

    /// Returns the accent color for a given command color scheme name.
    static func accentForScheme(_ scheme: String) -> Color {
        switch scheme {
        case "amber": return Color(hex: "#F59E0B")!
        case "green": return Color(hex: "#22C55E")!
        case "blue": return Color(hex: "#3B82F6")!
        default: return Color(hex: "#22D3EE")! // cyan (default)
        }
    }

    static let indigo = Color(hex: "#6366F1")!
    static let panel = Color(hex: "#111122")!
    static let surface = Color(hex: "#0A0A14")!

    // Glow colors — these are computed to follow the accent scheme
    static var glowCyan: Color { cyan.opacity(0.3) }
    static var glowCyanStrong: Color { cyan.opacity(0.5) }
    static let glowIndigo = Color(hex: "#6366F1")!.opacity(0.3)
    static let glowGreen = Color(hex: "#22C55E")!.opacity(0.3)
    static let glowOrange = Color(hex: "#F97316")!.opacity(0.3)

    // MARK: - Geometry

    let cornerRadiusSmall: CGFloat = 2   // angular, minimal
    let cornerRadiusMedium: CGFloat = 2
    let cornerRadiusLarge: CGFloat = 4
    let cornerRadiusCapsule: CGFloat = 4

    // MARK: - Typography

    let displayFontDesign: Font.Design = .monospaced
    let bodyFontDesign: Font.Design = .default
    let uppercaseHeaders = true
    let headerPrefix = "> "

    // MARK: - Interaction

    let pressedOpacity: CGFloat = 0.7
    let pressedScale: CGFloat = 0.97

    // MARK: - Overlays

    let showsGridOverlay = true
    let showsScanline = true
    let gridColor = Color(hex: "#6366F1")!.opacity(0.08)

    // MARK: - Card Styling

    func applyCardStyle(to content: AnyView, colorScheme: ColorScheme) -> AnyView {
        AnyView(
            content
                .padding(DailyArcSpacing.lg)
                .background(Color(hex: "#111122")!)
                .clipShape(RoundedRectangle(cornerRadius: 2))
                .overlay(
                    RoundedRectangle(cornerRadius: 2)
                        .stroke(Color(hex: "#6366F1")!.opacity(0.12), lineWidth: 1)
                )
                // Left accent bar
                .overlay(alignment: .leading) {
                    Rectangle()
                        .fill(Color(hex: "#6366F1")!.opacity(0.5))
                        .frame(width: 3)
                }
        )
    }

    func applyCardPressedStyle(to content: AnyView, colorScheme: ColorScheme) -> AnyView {
        AnyView(
            content
                .padding(DailyArcSpacing.lg)
                .background(Color(hex: "#111122")!)
                .clipShape(RoundedRectangle(cornerRadius: 2))
                .overlay(
                    RoundedRectangle(cornerRadius: 2)
                        .stroke(CommandTheme.cyan, lineWidth: 1)
                )
                .shadow(color: CommandTheme.glowCyan, radius: 20, x: 0, y: 0)
                .background(CommandTheme.cyan.opacity(0.05))
        )
    }
}
