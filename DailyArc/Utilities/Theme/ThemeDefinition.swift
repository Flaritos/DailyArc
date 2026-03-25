import SwiftUI

// MARK: - Theme Definition Protocol

/// Defines all visual axes a theme controls.
/// Concrete implementations: TactileTheme, CommandTheme.
protocol ThemeDefinition {
    // Identity
    var id: String { get }
    var name: String { get }
    var forcedColorScheme: ColorScheme? { get }

    // MARK: - Colors

    // Backgrounds
    var backgroundPrimary: Color { get }
    var backgroundSecondary: Color { get }
    var backgroundTertiary: Color { get }

    // Text
    var textPrimary: Color { get }
    var textSecondary: Color { get }
    var textTertiary: Color { get }

    // Borders & Separators
    var separator: Color { get }
    var border: Color { get }

    // Feedback
    var success: Color { get }
    var warning: Color { get }
    var error: Color { get }
    var info: Color { get }

    // Special
    var streakFire: Color { get }
    var premiumGold: Color { get }
    var disabled: Color { get }
    var disabledText: Color { get }
    var brandGradient: LinearGradient { get }

    // Card
    var cardBackground: Color { get }
    var cardShadowColor: Color { get }

    // MARK: - Geometry

    var cornerRadiusSmall: CGFloat { get }
    var cornerRadiusMedium: CGFloat { get }
    var cornerRadiusLarge: CGFloat { get }
    var cornerRadiusCapsule: CGFloat { get }

    // MARK: - Typography

    /// Font design for display/data text. `.default` = SF Pro, `.monospaced` = Courier.
    var displayFontDesign: Font.Design { get }
    /// Font design for body text.
    var bodyFontDesign: Font.Design { get }
    /// Whether section headers should be uppercased with wide letter-spacing.
    var uppercaseHeaders: Bool { get }
    /// Prefix string for section headers (e.g., "> " for Command theme).
    var headerPrefix: String { get }

    // MARK: - Interaction

    var pressedOpacity: CGFloat { get }
    var pressedScale: CGFloat { get }

    // MARK: - Card Styling

    /// Apply theme-specific card styling to a view.
    func applyCardStyle(to content: AnyView, colorScheme: ColorScheme) -> AnyView
    /// Apply theme-specific pressed/selected card styling.
    func applyCardPressedStyle(to content: AnyView, colorScheme: ColorScheme) -> AnyView

    // MARK: - Theme-Specific Overlays

    /// Whether to show grid overlay (Command only).
    var showsGridOverlay: Bool { get }
    /// Whether to show scanline overlay (Command only).
    var showsScanline: Bool { get }
    /// Grid line color (if applicable).
    var gridColor: Color { get }
}

// MARK: - Shadow Specification

/// Describes a shadow with all parameters needed for SwiftUI's `.shadow()`.
struct ShadowSpec {
    let color: Color
    let radius: CGFloat
    let x: CGFloat
    let y: CGFloat

    static let none = ShadowSpec(color: .clear, radius: 0, x: 0, y: 0)
}

// MARK: - Neumorphic Shadow Pair

/// Dual-shadow specification for neumorphic depth effects.
struct NeumorphicShadow {
    let lightShadow: ShadowSpec
    let darkShadow: ShadowSpec

    static let raisedLarge = NeumorphicShadow(
        lightShadow: ShadowSpec(color: Color.white.opacity(0.8), radius: 12, x: -6, y: -6),
        darkShadow: ShadowSpec(color: Color(hex: "#A3B1C6")!.opacity(0.6), radius: 12, x: 6, y: 6)
    )

    static let raisedSmall = NeumorphicShadow(
        lightShadow: ShadowSpec(color: Color.white.opacity(0.7), radius: 6, x: -3, y: -3),
        darkShadow: ShadowSpec(color: Color(hex: "#A3B1C6")!.opacity(0.5), radius: 6, x: 3, y: 3)
    )

    static let pressedLarge = NeumorphicShadow(
        lightShadow: ShadowSpec(color: Color.white.opacity(0.8), radius: 8, x: -4, y: -4),
        darkShadow: ShadowSpec(color: Color(hex: "#A3B1C6")!.opacity(0.6), radius: 8, x: 4, y: 4)
    )

    static let floating = NeumorphicShadow(
        lightShadow: ShadowSpec(color: Color.white.opacity(0.9), radius: 20, x: -10, y: -10),
        darkShadow: ShadowSpec(color: Color(hex: "#A3B1C6")!.opacity(0.5), radius: 20, x: 10, y: 10)
    )
}

// MARK: - Environment Key

struct ThemeEnvironmentKey: EnvironmentKey {
    nonisolated(unsafe) static let defaultValue: any ThemeDefinition = TactileTheme()
}

extension EnvironmentValues {
    var theme: any ThemeDefinition {
        get { self[ThemeEnvironmentKey.self] }
        set { self[ThemeEnvironmentKey.self] = newValue }
    }
}
