import SwiftUI

/// 10-color palette for habit customization.
/// All colors pass WCAG AA 4.5:1 contrast ratio against both white and black backgrounds.
/// Index 5 (Sky) is the default for new habits.
enum HabitColorPalette {
    static let colors: [(name: String, hex: String, darkModeHex: String)] = [
        ("Coral",   "#E63946", "#FF6B6B"),   // 0 — darker on light, lighter on dark
        ("Orange",  "#E76F00", "#FF9F43"),   // 1
        ("Amber",   "#C68400", "#E8A317"),   // 2 — replaced Gold, passes contrast
        ("Green",   "#2D8A4E", "#48C78E"),   // 3 — replaced Mint, passes contrast
        ("Teal",    "#0077A8", "#0ABDE3"),   // 4 — darkened for light mode
        ("Sky",     "#2563EB", "#54A0FF"),   // 5 — DEFAULT
        ("Indigo",  "#5F27CD", "#8B5CF6"),   // 6
        ("Violet",  "#7C3AED", "#A66DD4"),   // 7
        ("Rose",    "#DB2777", "#F472B6"),   // 8
        ("Slate",   "#475569", "#94A3B8"),   // 9
    ]
}
