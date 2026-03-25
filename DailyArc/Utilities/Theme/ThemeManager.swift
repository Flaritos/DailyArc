import SwiftUI
import UIKit

/// Observable theme manager that persists theme selection and provides the current theme.
/// Access via `ThemeManager.shared` or `@Environment(\.theme)`.
@Observable
final class ThemeManager: @unchecked Sendable {
    static let shared = ThemeManager()

    /// The currently active theme, derived from persisted themeID.
    var currentTheme: any ThemeDefinition {
        switch themeID {
        case "command": return CommandTheme()
        case "tactile": return TactileTheme()
        default: return TactileTheme()
        }
    }

    /// Persisted theme identifier. "tactile" or "command".
    var themeID: String {
        get {
            access(keyPath: \.themeID)
            return UserDefaults.standard.string(forKey: "selectedThemeID") ?? "tactile"
        }
        set {
            withMutation(keyPath: \.themeID) {
                UserDefaults.standard.set(newValue, forKey: "selectedThemeID")
                applyUIKitAppearance()
            }
        }
    }

    /// Whether the current theme is Command.
    var isCommand: Bool { themeID == "command" }
    /// Whether the current theme is Tactile.
    var isTactile: Bool { themeID == "tactile" }

    // MARK: - Premium Customization

    /// Command theme color scheme. Options: "cyan", "amber", "green", "blue".
    var commandColorScheme: String {
        get {
            access(keyPath: \.commandColorScheme)
            return UserDefaults.standard.string(forKey: "commandColorScheme") ?? "cyan"
        }
        set {
            withMutation(keyPath: \.commandColorScheme) {
                UserDefaults.standard.set(newValue, forKey: "commandColorScheme")
            }
        }
    }

    private init() {}

    // MARK: - UIKit Appearance Proxies

    /// Configures UIKit appearance proxies (tab bar, nav bar, table view) to match the current theme.
    /// SwiftUI's NavigationStack, TabView, Form, and List all render via UIKit under the hood,
    /// so their backgrounds come from UIKit appearance proxies, not SwiftUI modifiers.
    func applyUIKitAppearance() {
        let theme = currentTheme
        let bgColor = UIColor(theme.backgroundPrimary)
        let bgSecondary = UIColor(theme.backgroundSecondary)
        let textPrimary = UIColor(theme.textPrimary)

        // Tab bar
        let tabBarAppearance = UITabBarAppearance()
        tabBarAppearance.configureWithOpaqueBackground()
        tabBarAppearance.backgroundColor = bgColor
        // Remove default shadow — theme background + border handle separation
        tabBarAppearance.shadowColor = UIColor(theme.separator)
        tabBarAppearance.shadowImage = UIImage()
        UITabBar.appearance().standardAppearance = tabBarAppearance
        UITabBar.appearance().scrollEdgeAppearance = tabBarAppearance

        // Navigation bar
        let navBarAppearance = UINavigationBarAppearance()
        navBarAppearance.configureWithOpaqueBackground()
        navBarAppearance.backgroundColor = bgColor
        navBarAppearance.titleTextAttributes = [.foregroundColor: textPrimary]
        navBarAppearance.largeTitleTextAttributes = [.foregroundColor: textPrimary]
        navBarAppearance.shadowColor = UIColor(theme.separator)
        UINavigationBar.appearance().standardAppearance = navBarAppearance
        UINavigationBar.appearance().scrollEdgeAppearance = navBarAppearance
        UINavigationBar.appearance().compactAppearance = navBarAppearance

        // Table/List view (Form uses UITableView internally)
        UITableView.appearance().backgroundColor = bgColor
        UITableViewCell.appearance().backgroundColor = bgSecondary
    }
}
