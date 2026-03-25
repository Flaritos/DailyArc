import SwiftUI

/// Semantic design tokens for the DailyArc design system.
/// All color/geometry properties delegate to ThemeManager.shared.currentTheme,
/// making every view that references DailyArcTokens automatically theme-aware.
enum DailyArcTokens {
    private static var theme: any ThemeDefinition {
        ThemeManager.shared.currentTheme
    }

    // MARK: - Backgrounds (theme-delegated)
    static var backgroundPrimary: Color { theme.backgroundPrimary }
    static var backgroundSecondary: Color { theme.backgroundSecondary }
    static var backgroundTertiary: Color { theme.backgroundTertiary }

    // MARK: - Text (theme-delegated)
    static var textPrimary: Color { theme.textPrimary }
    static var textSecondary: Color { theme.textSecondary }
    static var textTertiary: Color { theme.textTertiary }

    // MARK: - Borders & Separators (theme-delegated)
    static var separator: Color { theme.separator }
    static var border: Color { theme.border }

    // MARK: - Feedback States (theme-delegated)
    static var success: Color { theme.success }
    static var warning: Color { theme.warning }
    static var error: Color { theme.error }
    static var info: Color { theme.info }
    static var accent: Color {
        let index = UserDefaults.standard.integer(forKey: "accentColorIndex")
        let safeIndex = (0..<HabitColorPalette.colors.count).contains(index) ? index : 5
        let entry = HabitColorPalette.colors[safeIndex]
        return Color(
            light: Color(hex: entry.hex)!,
            dark: Color(hex: entry.darkModeHex)!
        )
    }

    // MARK: - Specific UI Elements (theme-delegated)
    static var streakFire: Color { theme.streakFire }
    static var moodSelected: Color { Color.accentColor }
    static var cardShadow: Color { theme.cardShadowColor }
    static var premiumGold: Color { theme.premiumGold }
    static var disabled: Color { theme.disabled }
    static var disabledText: Color { theme.disabledText }

    // MARK: - Brand Gradient (theme-delegated)
    static var brandGradient: LinearGradient { theme.brandGradient }

    // MARK: - Corner Radii (theme-delegated)
    static var cornerRadiusSmall: CGFloat { theme.cornerRadiusSmall }
    static var cornerRadiusMedium: CGFloat { theme.cornerRadiusMedium }
    static var cornerRadiusLarge: CGFloat { theme.cornerRadiusLarge }
    static var cornerRadiusCapsule: CGFloat { theme.cornerRadiusCapsule }

    // MARK: - Card Style shortcuts
    static var cornerS: CGFloat { theme.cornerRadiusSmall }
    static var cornerM: CGFloat { theme.cornerRadiusMedium }
    static var cornerL: CGFloat { theme.cornerRadiusLarge }
    static let spacingM: CGFloat = 12
    static let spacingL: CGFloat = 16
    static let spacingXL: CGFloat = 24

    // MARK: - Pressed/Active States (theme-delegated)
    static var pressedOpacity: CGFloat { theme.pressedOpacity }
    static var pressedScale: CGFloat { theme.pressedScale }

    // MARK: - Focus State
    static let focusRingColor = Color.accentColor
    static let focusRingWidth: CGFloat = 2
    static let focusRingOffset: CGFloat = 2

    // MARK: - Opacity Scale
    static let opacitySubtle: CGFloat = 0.08
    static let opacityLight: CGFloat = 0.12
    static let opacityMedium: CGFloat = 0.16
    static let opacityHeavy: CGFloat = 0.24

    // MARK: - Border Widths
    static let borderThin: CGFloat = 1
    static let borderMedium: CGFloat = 2
    static let borderThick: CGFloat = 4
}

// MARK: - Spacing

/// Spacing scale based on 4pt base unit.
enum DailyArcSpacing {
    static let xxs: CGFloat = 2
    static let xs: CGFloat = 4
    static let sm: CGFloat = 8
    static let md: CGFloat = 12
    static let lg: CGFloat = 16
    static let xl: CGFloat = 24
    static let xxl: CGFloat = 32
    static let xxxl: CGFloat = 48
    static let jumbo: CGFloat = 64
}

// MARK: - Typography

/// ViewModifier for the DailyArc typography scale.
/// Display sizes use @ScaledMetric for Dynamic Type scaling.
/// All other sizes use semantic SwiftUI font styles.
struct DailyArcTypography: ViewModifier {
    enum Style {
        case displayLarge, displayMedium, displaySmall
        case titleLarge, titleMedium, titleSmall
        case bodyLarge, bodySmall
        case callout, caption, caption2, footnote
    }

    let style: Style

    @ScaledMetric(relativeTo: .largeTitle) private var displayLargeSize: CGFloat = 44
    @ScaledMetric(relativeTo: .largeTitle) private var displayMediumSize: CGFloat = 36
    @ScaledMetric(relativeTo: .largeTitle) private var displaySmallSize: CGFloat = 32

    func body(content: Content) -> some View {
        switch style {
        case .displayLarge:  content.font(.system(size: displayLargeSize, weight: .bold).leading(.tight)).tracking(-2)
        case .displayMedium: content.font(.system(size: displayMediumSize, weight: .bold).leading(.tight))
        case .displaySmall:  content.font(.system(size: displaySmallSize, weight: .bold).leading(.tight))
        case .titleLarge:    content.font(.title)
        case .titleMedium:   content.font(.title2.weight(.semibold))
        case .titleSmall:    content.font(.title3.weight(.semibold))
        case .bodyLarge:     content.font(.body)
        case .bodySmall:     content.font(.subheadline)
        case .callout:       content.font(.callout)
        case .caption:       content.font(.caption)
        case .caption2:      content.font(.caption2)
        case .footnote:      content.font(.footnote)
        }
    }
}

extension View {
    /// Apply DailyArc typography style to a view.
    func typography(_ style: DailyArcTypography.Style) -> some View {
        modifier(DailyArcTypography(style: style))
    }

    /// Card styling: elevated background, rounded corners, subtle shadow.
    /// In dark mode: reduced shadow opacity, subtle separator border.
    func cardStyle() -> some View {
        modifier(CardStyleModifier())
    }
}

/// Theme-aware card styling. Delegates to the active theme's card style.
struct CardStyleModifier: ViewModifier {
    @Environment(\.colorScheme) private var colorScheme

    func body(content: Content) -> some View {
        let theme = ThemeManager.shared.currentTheme
        theme.applyCardStyle(to: AnyView(content), colorScheme: colorScheme)
    }
}
