import SwiftUI

/// Semantic design tokens for the DailyArc design system.
/// All colors are adaptive (automatic light/dark mode switching).
enum DailyArcTokens {
    // MARK: - Backgrounds
    static let backgroundPrimary = Color(.systemBackground)            // #FFFFFF / #000000
    static let backgroundSecondary = Color(.secondarySystemBackground) // #F2F2F7 / #1C1C1E
    static let backgroundTertiary = Color(.tertiarySystemBackground)   // #FFFFFF / #2C2C2E

    // MARK: - Text
    static let textPrimary = Color(.label)                             // #000000 / #FFFFFF
    static let textSecondary = Color(.secondaryLabel)                  // #3C3C43@60% / #EBEBF5@60%
    static let textTertiary = Color(.tertiaryLabel)                    // #3C3C43@30% / #EBEBF5@30%

    // MARK: - Borders & Separators
    static let separator = Color(.separator)                           // #3C3C43@29% / #545458@65%
    static let border = Color(.systemGray4)                            // #D1D1D6 / #3A3A3C

    // MARK: - Feedback States (adaptive light/dark)
    static let success = Color(light: Color(hex: "#2D8A4E")!, dark: Color(hex: "#48C78E")!)
    static let warning = Color(light: Color(hex: "#C68400")!, dark: Color(hex: "#E8A317")!)
    static let error = Color(light: Color(hex: "#CC2936")!, dark: Color(hex: "#FF6B6B")!)
    static let info = Color(light: Color(hex: "#1976D2")!, dark: Color(hex: "#64B5F6")!)
    static var accent: Color {
        let index = UserDefaults.standard.integer(forKey: "accentColorIndex")
        let safeIndex = (0..<HabitColorPalette.colors.count).contains(index) ? index : 5
        let entry = HabitColorPalette.colors[safeIndex]
        return Color(
            light: Color(hex: entry.hex)!,
            dark: Color(hex: entry.darkModeHex)!
        )
    }

    // MARK: - Specific UI Elements (adaptive)
    static let streakFire = Color(light: Color(hex: "#E8590C")!, dark: Color(hex: "#FB923C")!)
    static let moodSelected = Color.accentColor
    static let cardShadow = Color(light: Color.black.opacity(0.08), dark: Color.black.opacity(0.24))
    static let premiumGold = Color(light: Color(hex: "#B8860B")!, dark: Color(hex: "#FFE44D")!)
    static let disabled = Color(.systemGray3)
    static let disabledText = Color(.systemGray)

    // MARK: - Brand Gradient
    static let brandGradient = LinearGradient(
        colors: [Color(hex: "2563EB")!, Color(hex: "5F27CD")!],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    // MARK: - Card Style
    static let cornerS: CGFloat = 10
    static let cornerM: CGFloat = 12
    static let cornerL: CGFloat = 16
    static let spacingM: CGFloat = 12
    static let spacingL: CGFloat = 16
    static let spacingXL: CGFloat = 24

    // MARK: - Pressed/Active States
    static let pressedOpacity: CGFloat = 0.7
    static let pressedScale: CGFloat = 0.97

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

    // MARK: - Corner Radii
    static let cornerRadiusSmall: CGFloat = 10
    static let cornerRadiusMedium: CGFloat = 12
    static let cornerRadiusLarge: CGFloat = 16
    static let cornerRadiusCapsule: CGFloat = 20
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

    @ScaledMetric(relativeTo: .largeTitle) private var displayLargeSize: CGFloat = 42
    @ScaledMetric(relativeTo: .largeTitle) private var displayMediumSize: CGFloat = 36
    @ScaledMetric(relativeTo: .largeTitle) private var displaySmallSize: CGFloat = 32

    func body(content: Content) -> some View {
        switch style {
        case .displayLarge:  content.font(.system(size: displayLargeSize, weight: .bold).leading(.tight))
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

    /// Card styling: elevated background, rounded corners, subtle shadow
    func cardStyle() -> some View {
        self
            .padding(DailyArcSpacing.lg)
            .background(DailyArcTokens.backgroundSecondary)
            .clipShape(RoundedRectangle(cornerRadius: DailyArcTokens.cornerRadiusMedium))
            .shadow(color: .black.opacity(0.06), radius: 8, x: 0, y: 2)
    }
}
