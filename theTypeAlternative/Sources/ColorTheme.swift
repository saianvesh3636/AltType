import SwiftUI
import AppKit

// MARK: - Appearance Mode Options

enum AppearanceMode: String, CaseIterable, Identifiable {
    case system = "system"
    case light = "light"
    case dark = "dark"
    
    var id: String { self.rawValue }
    
    var displayName: String {
        switch self {
        case .system: return "System"
        case .light: return "Light"
        case .dark: return "Dark"
        }
    }
    
    var systemImage: String {
        switch self {
        case .system: return "circle.lefthalf.filled"
        case .light: return "sun.max"
        case .dark: return "moon"
        }
    }
}

// MARK: - Appearance Settings Manager

class AppearanceSettings: ObservableObject {
    @Published var preferredMode: AppearanceMode {
        didSet {
            UserDefaults.standard.set(preferredMode.rawValue, forKey: "appearance_mode")
        }
    }
    
    init() {
        let savedMode = UserDefaults.standard.string(forKey: "appearance_mode") ?? AppearanceMode.system.rawValue
        self.preferredMode = AppearanceMode(rawValue: savedMode) ?? .system
    }
    
    /// Get the effective color scheme based on preference and system setting
    func effectiveColorScheme(systemColorScheme: ColorScheme) -> ColorScheme {
        switch preferredMode {
        case .system:
            return systemColorScheme
        case .light:
            return .light
        case .dark:
            return .dark
        }
    }
}

// MARK: - Color Theme

struct ColorTheme {
    let colorScheme: ColorScheme
    
    init(colorScheme: ColorScheme) {
        self.colorScheme = colorScheme
    }
    
    /// Create ColorTheme with appearance settings override
    init(systemColorScheme: ColorScheme, appearanceSettings: AppearanceSettings) {
        switch appearanceSettings.preferredMode {
        case .system:
            self.colorScheme = systemColorScheme
        case .light:
            self.colorScheme = .light
        case .dark:
            self.colorScheme = .dark
        }
    }
    
    // MARK: - Background Colors
    
    var primaryBackground: Color {
        Color(NSColor.windowBackgroundColor)
    }
    
    var secondaryBackground: Color {
        Color(NSColor.controlBackgroundColor)
    }
    
    var cardBackground: Color {
        colorScheme == .dark
            ? Color(NSColor.controlBackgroundColor).opacity(0.8)
            : Color(NSColor.controlBackgroundColor)
    }
    
    var hotkeyBackground: Color {
        Color(NSColor.quaternaryLabelColor)
    }
    
    // MARK: - Text Colors
    
    var primaryText: Color {
        Color(NSColor.labelColor)
    }
    
    var secondaryText: Color {
        Color(NSColor.secondaryLabelColor)
    }
    
    var tertiaryText: Color {
        Color(NSColor.tertiaryLabelColor)
    }
    
    // MARK: - State Colors
    
    var successColor: Color {
        colorScheme == .dark
            ? Color(red: 0.2, green: 0.8, blue: 0.2)
            : Color(red: 0.0, green: 0.7, blue: 0.0)
    }
    
    var errorColor: Color {
        colorScheme == .dark
            ? Color(red: 1.0, green: 0.4, blue: 0.4)
            : Color(red: 0.8, green: 0.0, blue: 0.0)
    }
    
    var listeningColor: Color {
        colorScheme == .dark
            ? Color(red: 0.4, green: 0.7, blue: 1.0)
            : Color(red: 0.0, green: 0.5, blue: 1.0)
    }
    
    // MARK: - Button Colors
    
    var primaryButtonBackground: Color {
        colorScheme == .dark
            ? Color(red: 0.2, green: 0.5, blue: 1.0)
            : Color(red: 0.0, green: 0.4, blue: 0.9)
    }
    
    var secondaryButtonBackground: Color {
        Color(NSColor.controlColor)
    }
    
    var destructiveButtonBackground: Color {
        colorScheme == .dark
            ? Color(red: 0.9, green: 0.3, blue: 0.3)
            : Color(red: 0.8, green: 0.2, blue: 0.2)
    }
    
    // MARK: - Border Colors
    
    var primaryBorder: Color {
        Color(NSColor.separatorColor)
    }
    
    var cardBorder: Color {
        colorScheme == .dark
            ? Color.white.opacity(0.1)
            : Color.black.opacity(0.1)
    }
    
    // MARK: - Shadow Colors
    
    var cardShadow: Color {
        colorScheme == .dark
            ? Color.black.opacity(0.3)
            : Color.black.opacity(0.1)
    }
    
    // MARK: - Permission Status Colors
    
    func permissionColor(isGranted: Bool) -> Color {
        isGranted ? successColor : errorColor
    }
    
    func permissionBorderColor(isGranted: Bool) -> Color {
        isGranted ? successColor.opacity(0.3) : errorColor.opacity(0.3)
    }
    
    // MARK: - State-based Colors
    
    func statusColor(for state: AppState) -> Color {
        switch state {
        case .idle:
            return successColor
        case .listening:
            return listeningColor
        case .error:
            return errorColor
        }
    }
    
    // MARK: - Activity Indicator Colors
    
    var activityIndicator: Color {
        listeningColor
    }
    
    // MARK: - Accessibility Support
    
    /// Returns high contrast version of colors when accessibility is enabled
    var accessibilityAdjusted: ColorTheme {
        // In a full implementation, this would check for high contrast preferences
        // and return adjusted colors accordingly
        return self
    }
}

// MARK: - SwiftUI Environment Extension

extension EnvironmentValues {
    private struct ColorThemeKey: EnvironmentKey {
        static let defaultValue = ColorTheme(colorScheme: .light)
    }
    
    var colorTheme: ColorTheme {
        get { self[ColorThemeKey.self] }
        set { self[ColorThemeKey.self] = newValue }
    }
}

// MARK: - View Extension for Easy Access

extension View {
    func colorTheme(_ colorScheme: ColorScheme) -> some View {
        environment(\.colorTheme, ColorTheme(colorScheme: colorScheme))
    }
}