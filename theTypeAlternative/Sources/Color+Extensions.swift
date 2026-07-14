import SwiftUI
import AppKit

// MARK: - Dynamic App Color Extensions
extension Color {
    
    // MARK: - Dynamic Color Functions (use these for reactive colors)
    // These methods now use cached colors from PaletteManager for maximum energy efficiency

    /// Dynamic primary color from PaletteManager (cached)
    @MainActor static func appPrimary(from manager: PaletteManager) -> Color {
        return manager.primary
    }

    /// Dynamic secondary color from PaletteManager (cached)
    @MainActor static func appSecondary(from manager: PaletteManager) -> Color {
        return manager.secondary
    }

    /// Dynamic tertiary color from PaletteManager (cached)
    @MainActor static func appTertiary(from manager: PaletteManager) -> Color {
        return manager.tertiary
    }

    /// Dynamic surface color from PaletteManager (cached)
    @MainActor static func appSurface(from manager: PaletteManager) -> Color {
        return manager.surface
    }

    /// Dynamic background color from PaletteManager (cached)
    @MainActor static func appBackground(from manager: PaletteManager) -> Color {
        return manager.background
    }

    /// Dynamic onPrimary color from PaletteManager (cached)
    @MainActor static func appOnPrimary(from manager: PaletteManager) -> Color {
        return manager.onPrimary
    }

    /// Dynamic onSecondary color from PaletteManager (cached)
    @MainActor static func appOnSecondary(from manager: PaletteManager) -> Color {
        return manager.onSecondary
    }

    /// Dynamic onSurface color from PaletteManager (cached)
    @MainActor static func appOnSurface(from manager: PaletteManager) -> Color {
        return manager.onSurface
    }

    /// Dynamic onBackground color from PaletteManager (cached)
    @MainActor static func appOnBackground(from manager: PaletteManager) -> Color {
        return manager.onBackground
    }

    /// Dynamic accent color from PaletteManager (cached)
    @MainActor static func appAccent(from manager: PaletteManager) -> Color {
        return manager.accent
    }

    /// Dynamic error color from PaletteManager (cached)
    @MainActor static func appError(from manager: PaletteManager) -> Color {
        return manager.error
    }

    /// Dynamic warning color from PaletteManager (cached)
    @MainActor static func appWarning(from manager: PaletteManager) -> Color {
        return manager.warning
    }

    /// Dynamic success color from PaletteManager (cached)
    @MainActor static func appSuccess(from manager: PaletteManager) -> Color {
        return manager.success
    }
    
    // MARK: - Legacy Static Colors (deprecated - use dynamic versions above)
    /// Primary color that adapts to light/dark mode automatically
    @available(*, deprecated, message: "Use Color.appPrimary(from: paletteManager) instead for reactive colors")
    static var appPrimary: Color {
        return Color.adaptive(
            light: ColorPalette.current.primary.light,
            dark: ColorPalette.current.primary.dark
        )
    }
    
    @available(*, deprecated, message: "Use Color.appSecondary(from: paletteManager) instead")
    static var appSecondary: Color {
        Color.adaptive(
            light: ColorPalette.current.secondary.light,
            dark: ColorPalette.current.secondary.dark
        )
    }
    
    @available(*, deprecated, message: "Use Color.appTertiary(from: paletteManager) instead")
    static var appTertiary: Color {
        Color.adaptive(
            light: ColorPalette.current.tertiary.light,
            dark: ColorPalette.current.tertiary.dark
        )
    }
    
    @available(*, deprecated, message: "Use Color.appSurface(from: paletteManager) instead")
    static var appSurface: Color {
        Color.adaptive(
            light: ColorPalette.current.surface.light,
            dark: ColorPalette.current.surface.dark
        )
    }
    
    @available(*, deprecated, message: "Use Color.appBackground(from: paletteManager) instead")
    static var appBackground: Color {
        Color.adaptive(
            light: ColorPalette.current.background.light,
            dark: ColorPalette.current.background.dark
        )
    }
    
    @available(*, deprecated, message: "Use Color.appOnPrimary(from: paletteManager) instead")
    static var appOnPrimary: Color {
        Color.adaptive(
            light: ColorPalette.current.onPrimary.light,
            dark: ColorPalette.current.onPrimary.dark
        )
    }
    
    @available(*, deprecated, message: "Use Color.appOnSecondary(from: paletteManager) instead")
    static var appOnSecondary: Color {
        Color.adaptive(
            light: ColorPalette.current.onSecondary.light,
            dark: ColorPalette.current.onSecondary.dark
        )
    }
    
    @available(*, deprecated, message: "Use Color.appOnSurface(from: paletteManager) instead")
    static var appOnSurface: Color {
        Color.adaptive(
            light: ColorPalette.current.onSurface.light,
            dark: ColorPalette.current.onSurface.dark
        )
    }
    
    @available(*, deprecated, message: "Use Color.appOnBackground(from: paletteManager) instead")
    static var appOnBackground: Color {
        Color.adaptive(
            light: ColorPalette.current.onBackground.light,
            dark: ColorPalette.current.onBackground.dark
        )
    }
    
    @available(*, deprecated, message: "Use Color.appAccent(from: paletteManager) instead")
    static var appAccent: Color {
        Color.adaptive(
            light: ColorPalette.current.accent.light,
            dark: ColorPalette.current.accent.dark
        )
    }
    
    @available(*, deprecated, message: "Use Color.appError(from: paletteManager) instead")
    static var appError: Color {
        Color.adaptive(
            light: ColorPalette.current.error.light,
            dark: ColorPalette.current.error.dark
        )
    }
    
    @available(*, deprecated, message: "Use Color.appWarning(from: paletteManager) instead")
    static var appWarning: Color {
        Color.adaptive(
            light: ColorPalette.current.warning.light,
            dark: ColorPalette.current.warning.dark
        )
    }
    
    @available(*, deprecated, message: "Use Color.appSuccess(from: paletteManager) instead")
    static var appSuccess: Color {
        Color.adaptive(
            light: ColorPalette.current.success.light,
            dark: ColorPalette.current.success.dark
        )
    }
    
    // MARK: - Convenience Methods
    /// Creates a color that automatically adapts to light/dark mode
    /// Note: Called only once per color due to static let in palette structs
    static func adaptive(light: Color, dark: Color) -> Color {
        // Create adaptive color with NSColor dynamic provider
        return Color(NSColor(name: nil) { appearance in
            // Check if the appearance is dark mode
            // This handles both .darkAqua and .vibrantDark cases
            let isDark = appearance.bestMatch(from: [.darkAqua, .vibrantDark]) != nil ||
                         appearance.name.rawValue.lowercased().contains("dark")
            return isDark ? NSColor(dark) : NSColor(light)
        })
    }
    
    // MARK: - Legacy Support (for gradual migration)
    /// Use this temporarily while migrating from system colors
    @available(*, deprecated, message: "Use .appPrimary instead")
    static var legacyBlue: Color { .appPrimary }
    
    @available(*, deprecated, message: "Use .appError instead")
    static var legacyRed: Color { .appError }
}

// MARK: - Color to NSColor Conversion Utility
extension Color {
    /// Convert SwiftUI Color to NSColor for AppKit components
    var nsColor: NSColor {
        NSColor(self)
    }
    
    /// Convert SwiftUI Color to NSColor with dynamic light/dark mode support
    static func adaptiveNSColor(light: Color, dark: Color) -> NSColor {
        NSColor(name: nil) { appearance in
            // Check if the appearance is dark mode
            // This handles both .darkAqua and .vibrantDark cases
            let isDark = appearance.bestMatch(from: [.darkAqua, .vibrantDark]) != nil || 
                         appearance.name.rawValue.lowercased().contains("dark")
            return isDark ? NSColor(dark) : NSColor(light)
        }
    }
}

// MARK: - Dynamic NSColor Helpers (using cached colors)
extension Color {
    /// Get NSColor version of dynamic app primary color (cached)
    @MainActor static func nsAppPrimary(from manager: PaletteManager) -> NSColor {
        return NSColor(manager.primary)
    }

    /// Get NSColor version of dynamic app surface color (cached)
    @MainActor static func nsAppSurface(from manager: PaletteManager) -> NSColor {
        return NSColor(manager.surface)
    }

    /// Get NSColor version of dynamic app accent color (cached)
    @MainActor static func nsAppAccent(from manager: PaletteManager) -> NSColor {
        return NSColor(manager.accent)
    }
}

// MARK: - SwiftUI Environment Extensions
extension EnvironmentValues {
    private struct PaletteManagerKey: EnvironmentKey {
        static let defaultValue: PaletteManager? = nil
    }
    
    var paletteManager: PaletteManager? {
        get { self[PaletteManagerKey.self] }
        set { self[PaletteManagerKey.self] = newValue }
    }
}

// MARK: - Simple Palette Change Modifier (only recreates on actual palette change)
extension View {
    /// Apply this to root views to ensure palette changes propagate correctly
    func withPaletteSupport() -> some View {
        // Views will automatically update via PaletteManager's objectWillChange
        self
    }
}