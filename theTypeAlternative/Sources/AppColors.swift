import SwiftUI

// MARK: - App Colors Structure

struct AppColors: Sendable {
    let primary: Color
    let secondary: Color
    let warning: Color
    let error: Color
    let background: Color
    let surface: Color
    let onSurface: Color

    init(
        primary: Color,
        secondary: Color,
        warning: Color,
        error: Color
    ) {
        self.primary = primary
        self.secondary = secondary
        self.warning = warning
        self.error = error
        self.background = Color(NSColor.windowBackgroundColor)
        self.surface = Color(NSColor.controlBackgroundColor)
        self.onSurface = Color(NSColor.controlTextColor)
    }

    init(
        primary: Color,
        secondary: Color,
        warning: Color,
        error: Color,
        background: Color,
        surface: Color,
        onSurface: Color
    ) {
        self.primary = primary
        self.secondary = secondary
        self.warning = warning
        self.error = error
        self.background = background
        self.surface = surface
        self.onSurface = onSurface
    }
}

// MARK: - Environment Key

struct AppColorsKey: EnvironmentKey {
    static let defaultValue: AppColors = AppColors(
        primary: .blue,
        secondary: .purple,
        warning: .orange,
        error: .red,
        background: Color(NSColor.windowBackgroundColor),
        surface: Color(NSColor.controlBackgroundColor),
        onSurface: Color(NSColor.controlTextColor)
    )
}

extension EnvironmentValues {
    var appColors: AppColors {
        get { self[AppColorsKey.self] }
        set { self[AppColorsKey.self] = newValue }
    }
}
