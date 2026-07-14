import SwiftUI
import AppKit

// MARK: - Simple Color Extension (No Caching - Colors Created Once via static let)

extension Color {
    /// Initialize Color from hex string (simple parsing, no caching needed)
    init(hex: String) {
        let cleanHex = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        let scanner = Scanner(string: cleanHex)
        var rgbValue: UInt64 = 0

        if cleanHex.hasPrefix("#") {
            scanner.currentIndex = cleanHex.index(after: cleanHex.startIndex)
        }

        scanner.scanHexInt64(&rgbValue)

        let red = Double((rgbValue & 0xFF0000) >> 16) / 255.0
        let green = Double((rgbValue & 0x00FF00) >> 8) / 255.0
        let blue = Double(rgbValue & 0x0000FF) / 255.0

        self.init(red: red, green: green, blue: blue)
    }
}

// MARK: - Color Scheme Protocol
protocol ColorSchemeProtocol: Sendable {
    var primary: (light: Color, dark: Color) { get }
    var secondary: (light: Color, dark: Color) { get }
    var tertiary: (light: Color, dark: Color) { get }
    var surface: (light: Color, dark: Color) { get }
    var background: (light: Color, dark: Color) { get }
    var onPrimary: (light: Color, dark: Color) { get }
    var onSecondary: (light: Color, dark: Color) { get }
    var onSurface: (light: Color, dark: Color) { get }
    var onBackground: (light: Color, dark: Color) { get }
    var accent: (light: Color, dark: Color) { get }
    var error: (light: Color, dark: Color) { get }
    var warning: (light: Color, dark: Color) { get }
    var success: (light: Color, dark: Color) { get }
}

// MARK: - Available Color Palettes

// MARK: - Sage Lavender Peach Palette
struct SageLavenderPeachPalette: ColorSchemeProtocol {
    // Simple static let colors - created once, reused everywhere (energy efficient)
    static let primaryLight = Color(hex: "A8C5A1")
    static let primaryDark = Color(hex: "5A7A52")
    static let secondaryLight = Color(hex: "C8B5DB")
    static let secondaryDark = Color(hex: "8A6B9A")
    static let tertiaryLight = Color(hex: "F0D4C7")
    static let tertiaryDark = Color(hex: "D4A574")
    static let surfaceLight = Color(hex: "FEFEFE")
    static let surfaceDark = Color(hex: "1A1C19")
    static let backgroundLight = Color(hex: "FDFCFC")
    static let backgroundDark = Color(hex: "0F110E")
    static let onPrimaryLight = Color(hex: "2A3D26")
    static let onPrimaryDark = Color(hex: "E8F0E6")
    static let onSecondaryLight = Color(hex: "4A3555")
    static let onSecondaryDark = Color(hex: "E5D9F0")
    static let onSurfaceLight = Color(hex: "1A1C19")
    static let onSurfaceDark = Color(hex: "E8E9E6")
    static let onBackgroundLight = Color(hex: "1A1C19")
    static let onBackgroundDark = Color(hex: "E8E9E6")
    static let accentLight = Color(hex: "8FB087")
    static let accentDark = Color(hex: "6B8A61")
    static let errorLight = Color(hex: "E57373")
    static let errorDark = Color(hex: "EF5350")
    static let warningLight = Color(hex: "FFB74D")
    static let warningDark = Color(hex: "FF9800")
    static let successLight = Color(hex: "A8C5A1")
    static let successDark = Color(hex: "6B8A61")

    var primary: (light: Color, dark: Color) { (Self.primaryLight, Self.primaryDark) }
    var secondary: (light: Color, dark: Color) { (Self.secondaryLight, Self.secondaryDark) }
    var tertiary: (light: Color, dark: Color) { (Self.tertiaryLight, Self.tertiaryDark) }
    var surface: (light: Color, dark: Color) { (Self.surfaceLight, Self.surfaceDark) }
    var background: (light: Color, dark: Color) { (Self.backgroundLight, Self.backgroundDark) }
    var onPrimary: (light: Color, dark: Color) { (Self.onPrimaryLight, Self.onPrimaryDark) }
    var onSecondary: (light: Color, dark: Color) { (Self.onSecondaryLight, Self.onSecondaryDark) }
    var onSurface: (light: Color, dark: Color) { (Self.onSurfaceLight, Self.onSurfaceDark) }
    var onBackground: (light: Color, dark: Color) { (Self.onBackgroundLight, Self.onBackgroundDark) }
    var accent: (light: Color, dark: Color) { (Self.accentLight, Self.accentDark) }
    var error: (light: Color, dark: Color) { (Self.errorLight, Self.errorDark) }
    var warning: (light: Color, dark: Color) { (Self.warningLight, Self.warningDark) }
    var success: (light: Color, dark: Color) { (Self.successLight, Self.successDark) }
}

// MARK: - Arctic Minimalist Palette
struct ArcticMinimalistPalette: ColorSchemeProtocol {
    // Simple static let colors - created once, reused everywhere (energy efficient)
    static let primaryLight = Color(hex: "4A90E2")
    static let primaryDark = Color(hex: "5BA0F2")
    static let secondaryLight = Color(hex: "8BB6E8")
    static let secondaryDark = Color(hex: "7AA3D1")
    static let tertiaryLight = Color(hex: "E8F2FF")
    static let tertiaryDark = Color(hex: "2A3A4A")
    static let surfaceLight = Color(hex: "FAFBFC")
    static let surfaceDark = Color(hex: "1C1C1E")
    static let backgroundLight = Color(hex: "F5F7FA")
    static let backgroundDark = Color(hex: "0A0A0B")
    static let onPrimaryLight = Color(hex: "FFFFFF")
    static let onPrimaryDark = Color(hex: "FFFFFF")
    static let onSecondaryLight = Color(hex: "2C3E50")
    static let onSecondaryDark = Color(hex: "ECF0F1")
    static let onSurfaceLight = Color(hex: "2C3E50")
    static let onSurfaceDark = Color(hex: "F8F9FA")
    static let onBackgroundLight = Color(hex: "34495E")
    static let onBackgroundDark = Color(hex: "E8E9EA")
    static let accentLight = Color(hex: "007AFF")
    static let accentDark = Color(hex: "0A84FF")
    static let errorLight = Color(hex: "FF3B30")
    static let errorDark = Color(hex: "FF453A")
    static let warningLight = Color(hex: "FF9500")
    static let warningDark = Color(hex: "FF9F0A")
    static let successLight = Color(hex: "34C759")
    static let successDark = Color(hex: "30D158")

    var primary: (light: Color, dark: Color) { (Self.primaryLight, Self.primaryDark) }
    var secondary: (light: Color, dark: Color) { (Self.secondaryLight, Self.secondaryDark) }
    var tertiary: (light: Color, dark: Color) { (Self.tertiaryLight, Self.tertiaryDark) }
    var surface: (light: Color, dark: Color) { (Self.surfaceLight, Self.surfaceDark) }
    var background: (light: Color, dark: Color) { (Self.backgroundLight, Self.backgroundDark) }
    var onPrimary: (light: Color, dark: Color) { (Self.onPrimaryLight, Self.onPrimaryDark) }
    var onSecondary: (light: Color, dark: Color) { (Self.onSecondaryLight, Self.onSecondaryDark) }
    var onSurface: (light: Color, dark: Color) { (Self.onSurfaceLight, Self.onSurfaceDark) }
    var onBackground: (light: Color, dark: Color) { (Self.onBackgroundLight, Self.onBackgroundDark) }
    var accent: (light: Color, dark: Color) { (Self.accentLight, Self.accentDark) }
    var error: (light: Color, dark: Color) { (Self.errorLight, Self.errorDark) }
    var warning: (light: Color, dark: Color) { (Self.warningLight, Self.warningDark) }
    var success: (light: Color, dark: Color) { (Self.successLight, Self.successDark) }
}

// MARK: - Vibrant Duotone Palette
struct VibrantDuotonePalette: ColorSchemeProtocol {
    // Simple static let colors - created once, reused everywhere (energy efficient)
    static let primaryLight = Color(hex: "667EEA")
    static let primaryDark = Color(hex: "764BA2")
    static let secondaryLight = Color(hex: "F093FB")
    static let secondaryDark = Color(hex: "F25CA2")
    static let tertiaryLight = Color(hex: "C471ED")
    static let tertiaryDark = Color(hex: "A855F7")
    static let surfaceLight = Color(hex: "FFFFFF")
    static let surfaceDark = Color(hex: "1A1A1F")
    static let backgroundLight = Color(hex: "FAFAFA")
    static let backgroundDark = Color(hex: "0F0F14")
    static let onPrimaryLight = Color(hex: "FFFFFF")
    static let onPrimaryDark = Color(hex: "FFFFFF")
    static let onSecondaryLight = Color(hex: "FFFFFF")
    static let onSecondaryDark = Color(hex: "FFFFFF")
    static let onSurfaceLight = Color(hex: "1A1A1F")
    static let onSurfaceDark = Color(hex: "F0F0F3")
    static let onBackgroundLight = Color(hex: "1A1A1F")
    static let onBackgroundDark = Color(hex: "F0F0F3")
    static let accentLight = Color(hex: "8B5CF6")
    static let accentDark = Color(hex: "A78BFA")
    static let errorLight = Color(hex: "EF4444")
    static let errorDark = Color(hex: "F87171")
    static let warningLight = Color(hex: "F59E0B")
    static let warningDark = Color(hex: "FBBF24")
    static let successLight = Color(hex: "10B981")
    static let successDark = Color(hex: "34D399")

    var primary: (light: Color, dark: Color) { (Self.primaryLight, Self.primaryDark) }
    var secondary: (light: Color, dark: Color) { (Self.secondaryLight, Self.secondaryDark) }
    var tertiary: (light: Color, dark: Color) { (Self.tertiaryLight, Self.tertiaryDark) }
    var surface: (light: Color, dark: Color) { (Self.surfaceLight, Self.surfaceDark) }
    var background: (light: Color, dark: Color) { (Self.backgroundLight, Self.backgroundDark) }
    var onPrimary: (light: Color, dark: Color) { (Self.onPrimaryLight, Self.onPrimaryDark) }
    var onSecondary: (light: Color, dark: Color) { (Self.onSecondaryLight, Self.onSecondaryDark) }
    var onSurface: (light: Color, dark: Color) { (Self.onSurfaceLight, Self.onSurfaceDark) }
    var onBackground: (light: Color, dark: Color) { (Self.onBackgroundLight, Self.onBackgroundDark) }
    var accent: (light: Color, dark: Color) { (Self.accentLight, Self.accentDark) }
    var error: (light: Color, dark: Color) { (Self.errorLight, Self.errorDark) }
    var warning: (light: Color, dark: Color) { (Self.warningLight, Self.warningDark) }
    var success: (light: Color, dark: Color) { (Self.successLight, Self.successDark) }
}

// MARK: - Nature-Inspired Monochromatic Palette
struct NatureMonochromaticPalette: ColorSchemeProtocol {
    // Simple static let colors - created once, reused everywhere (energy efficient)
    static let primaryLight = Color(hex: "2ECC71")
    static let primaryDark = Color(hex: "27AE60")
    static let secondaryLight = Color(hex: "A8E6CF")
    static let secondaryDark = Color(hex: "6A9D7A")
    static let tertiaryLight = Color(hex: "D5E8D4")
    static let tertiaryDark = Color(hex: "4A5E4A")
    static let surfaceLight = Color(hex: "FEFFFE")
    static let surfaceDark = Color(hex: "1A1C1A")
    static let backgroundLight = Color(hex: "F8FBF8")
    static let backgroundDark = Color(hex: "0F120F")
    static let onPrimaryLight = Color(hex: "FFFFFF")
    static let onPrimaryDark = Color(hex: "FFFFFF")
    static let onSecondaryLight = Color(hex: "2C3E2C")
    static let onSecondaryDark = Color(hex: "E8F0E8")
    static let onSurfaceLight = Color(hex: "1A1C1A")
    static let onSurfaceDark = Color(hex: "E8E9E8")
    static let onBackgroundLight = Color(hex: "1A1C1A")
    static let onBackgroundDark = Color(hex: "E8E9E8")
    static let accentLight = Color(hex: "16A085")
    static let accentDark = Color(hex: "1ABC9C")
    static let errorLight = Color(hex: "E74C3C")
    static let errorDark = Color(hex: "EC7063")
    static let warningLight = Color(hex: "F39C12")
    static let warningDark = Color(hex: "F8C471")
    static let successLight = Color(hex: "2ECC71")
    static let successDark = Color(hex: "58D68D")

    var primary: (light: Color, dark: Color) { (Self.primaryLight, Self.primaryDark) }
    var secondary: (light: Color, dark: Color) { (Self.secondaryLight, Self.secondaryDark) }
    var tertiary: (light: Color, dark: Color) { (Self.tertiaryLight, Self.tertiaryDark) }
    var surface: (light: Color, dark: Color) { (Self.surfaceLight, Self.surfaceDark) }
    var background: (light: Color, dark: Color) { (Self.backgroundLight, Self.backgroundDark) }
    var onPrimary: (light: Color, dark: Color) { (Self.onPrimaryLight, Self.onPrimaryDark) }
    var onSecondary: (light: Color, dark: Color) { (Self.onSecondaryLight, Self.onSecondaryDark) }
    var onSurface: (light: Color, dark: Color) { (Self.onSurfaceLight, Self.onSurfaceDark) }
    var onBackground: (light: Color, dark: Color) { (Self.onBackgroundLight, Self.onBackgroundDark) }
    var accent: (light: Color, dark: Color) { (Self.accentLight, Self.accentDark) }
    var error: (light: Color, dark: Color) { (Self.errorLight, Self.errorDark) }
    var warning: (light: Color, dark: Color) { (Self.warningLight, Self.warningDark) }
    var success: (light: Color, dark: Color) { (Self.successLight, Self.successDark) }
}

// MARK: - Premium Dark-Light Contrast Palette
struct PremiumContrastPalette: ColorSchemeProtocol {
    // Simple static let colors - created once, reused everywhere (energy efficient)
    static let primaryLight = Color(hex: "007AFF")
    static let primaryDark = Color(hex: "0A84FF")
    static let secondaryLight = Color(hex: "8E8E93")
    static let secondaryDark = Color(hex: "636366")
    static let tertiaryLight = Color(hex: "F2F2F7")
    static let tertiaryDark = Color(hex: "2C2C2E")
    static let surfaceLight = Color(hex: "FFFFFF")
    static let surfaceDark = Color(hex: "161618")
    static let backgroundLight = Color(hex: "F8F9FA")
    static let backgroundDark = Color(hex: "212124")
    static let onPrimaryLight = Color(hex: "FFFFFF")
    static let onPrimaryDark = Color(hex: "FFFFFF")
    static let onSecondaryLight = Color(hex: "FFFFFF")
    static let onSecondaryDark = Color(hex: "FFFFFF")
    static let onSurfaceLight = Color(hex: "000000")
    static let onSurfaceDark = Color(hex: "FFFFFF")
    static let onBackgroundLight = Color(hex: "1C1C1E")
    static let onBackgroundDark = Color(hex: "F2F2F7")
    static let accentLight = Color(hex: "007AFF")
    static let accentDark = Color(hex: "0A84FF")
    static let errorLight = Color(hex: "FF3B30")
    static let errorDark = Color(hex: "FF453A")
    static let warningLight = Color(hex: "FF9500")
    static let warningDark = Color(hex: "FF9F0A")
    static let successLight = Color(hex: "34C759")
    static let successDark = Color(hex: "30D158")

    var primary: (light: Color, dark: Color) { (Self.primaryLight, Self.primaryDark) }
    var secondary: (light: Color, dark: Color) { (Self.secondaryLight, Self.secondaryDark) }
    var tertiary: (light: Color, dark: Color) { (Self.tertiaryLight, Self.tertiaryDark) }
    var surface: (light: Color, dark: Color) { (Self.surfaceLight, Self.surfaceDark) }
    var background: (light: Color, dark: Color) { (Self.backgroundLight, Self.backgroundDark) }
    var onPrimary: (light: Color, dark: Color) { (Self.onPrimaryLight, Self.onPrimaryDark) }
    var onSecondary: (light: Color, dark: Color) { (Self.onSecondaryLight, Self.onSecondaryDark) }
    var onSurface: (light: Color, dark: Color) { (Self.onSurfaceLight, Self.onSurfaceDark) }
    var onBackground: (light: Color, dark: Color) { (Self.onBackgroundLight, Self.onBackgroundDark) }
    var accent: (light: Color, dark: Color) { (Self.accentLight, Self.accentDark) }
    var error: (light: Color, dark: Color) { (Self.errorLight, Self.errorDark) }
    var warning: (light: Color, dark: Color) { (Self.warningLight, Self.warningDark) }
    var success: (light: Color, dark: Color) { (Self.successLight, Self.successDark) }
}

// MARK: - Palette Options Enum
enum PaletteOption: String, CaseIterable, Identifiable {
    case sageLavenderPeach = "sage_lavender_peach"
    case arcticMinimalist = "arctic_minimalist"
    case vibrantDuotone = "vibrant_duotone"
    case natureMonochromatic = "nature_monochromatic"
    case premiumContrast = "premium_contrast"
    
    var id: String { self.rawValue }
    
    var displayName: String {
        switch self {
        case .sageLavenderPeach: return "Sage Lavender Peach"
        case .arcticMinimalist: return "Arctic Minimalist"
        case .vibrantDuotone: return "Vibrant Duotone"
        case .natureMonochromatic: return "Nature Monochromatic"
        case .premiumContrast: return "Premium Contrast"
        }
    }
    
    var description: String {
        switch self {
        case .sageLavenderPeach: return "Nature-inspired, calming colors"
        case .arcticMinimalist: return "Clean, modern minimalist design"
        case .vibrantDuotone: return "Bold, energetic gradient colors"
        case .natureMonochromatic: return "Accessibility-friendly forest greens"
        case .premiumContrast: return "High-end dark-light contrast design"
        }
    }
    
    var systemImage: String {
        switch self {
        case .sageLavenderPeach: return "leaf.fill"
        case .arcticMinimalist: return "snow"
        case .vibrantDuotone: return "paintpalette.fill"
        case .natureMonochromatic: return "tree.fill"
        case .premiumContrast: return "rectangle.split.2x1.fill"
        }
    }
    
    func createPalette() -> ColorSchemeProtocol {
        switch self {
        case .sageLavenderPeach: return SageLavenderPeachPalette()
        case .arcticMinimalist: return ArcticMinimalistPalette()
        case .vibrantDuotone: return VibrantDuotonePalette()
        case .natureMonochromatic: return NatureMonochromaticPalette()
        case .premiumContrast: return PremiumContrastPalette()
        }
    }
}

// MARK: - Simple Palette Manager (No Caching - Colors Already Created Once)
@MainActor
class PaletteManager: ObservableObject {
    @Published var selectedPalette: PaletteOption {
        didSet {
            guard selectedPalette != oldValue else { return }
            print("🎨 PaletteManager: Palette changed from \(oldValue.displayName) to \(selectedPalette.displayName)")
            UserDefaults.standard.set(selectedPalette.rawValue, forKey: "selected_color_palette")
            updateCurrentPalette()
        }
    }

    // NOT @Published - prevents cascading view updates
    // Views only update when objectWillChange.send() is called explicitly
    private(set) var currentPalette: ColorSchemeProtocol

    init() {
        let savedPalette = UserDefaults.standard.string(forKey: "selected_color_palette") ?? PaletteOption.arcticMinimalist.rawValue
        let palette = PaletteOption(rawValue: savedPalette) ?? .arcticMinimalist
        print("🎨 PaletteManager: Initialized with palette: \(palette.displayName)")
        self.selectedPalette = palette
        self.currentPalette = palette.createPalette()
    }

    private func updateCurrentPalette() {
        print("🎨 PaletteManager: Updating current palette to \(selectedPalette.displayName)")
        currentPalette = selectedPalette.createPalette()
        print("🎨 PaletteManager: Current palette updated. Primary light color: \(currentPalette.primary.light)")

        // Manually trigger update - only fires when palette actually changes
        objectWillChange.send()
    }

    // MARK: - Direct Color Access (No Caching - Colors Already Static Let)
    // These simply return adaptive colors created from the static let colors
    var primary: Color { Color.adaptive(light: currentPalette.primary.light, dark: currentPalette.primary.dark) }
    var secondary: Color { Color.adaptive(light: currentPalette.secondary.light, dark: currentPalette.secondary.dark) }
    var tertiary: Color { Color.adaptive(light: currentPalette.tertiary.light, dark: currentPalette.tertiary.dark) }
    var surface: Color { Color.adaptive(light: currentPalette.surface.light, dark: currentPalette.surface.dark) }
    var background: Color { Color.adaptive(light: currentPalette.background.light, dark: currentPalette.background.dark) }
    var onPrimary: Color { Color.adaptive(light: currentPalette.onPrimary.light, dark: currentPalette.onPrimary.dark) }
    var onSecondary: Color { Color.adaptive(light: currentPalette.onSecondary.light, dark: currentPalette.onSecondary.dark) }
    var onSurface: Color { Color.adaptive(light: currentPalette.onSurface.light, dark: currentPalette.onSurface.dark) }
    var onBackground: Color { Color.adaptive(light: currentPalette.onBackground.light, dark: currentPalette.onBackground.dark) }
    var accent: Color { Color.adaptive(light: currentPalette.accent.light, dark: currentPalette.accent.dark) }
    var error: Color { Color.adaptive(light: currentPalette.error.light, dark: currentPalette.error.dark) }
    var warning: Color { Color.adaptive(light: currentPalette.warning.light, dark: currentPalette.warning.dark) }
    var success: Color { Color.adaptive(light: currentPalette.success.light, dark: currentPalette.success.dark) }
}

// MARK: - Color Palette Manager
struct ColorPalette {
    // Default palette for static access (fallback only)
    static var current: ColorSchemeProtocol {
        return ArcticMinimalistPalette()
    }
}