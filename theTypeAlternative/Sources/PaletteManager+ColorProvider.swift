import SwiftUI

// MARK: - PaletteManager AppColors Extension
extension PaletteManager {
    
    @MainActor
    var appColors: AppColors {
        AppColors(
            primary: Color.appPrimary(from: self),
            secondary: Color.appSecondary(from: self),
            warning: Color.appWarning(from: self),
            error: Color.appError(from: self),
            background: Color.appBackground(from: self),
            surface: Color.appSurface(from: self),
            onSurface: Color.appOnSurface(from: self)
        )
    }
}

// MARK: - View Extension for AppColors
extension View {
    func appColors(_ appColors: AppColors) -> some View {
        environment(\.appColors, appColors)
    }
}