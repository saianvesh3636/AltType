import SwiftUI
import AppKit

struct AppearanceDetailView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var appearanceSettings: AppearanceSettings
    @EnvironmentObject var paletteManager: PaletteManager
    
    var body: some View {
        ScrollView {
                VStack(spacing: 32) {
                    // Header
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("Appearance")
                                .font(.system(size: 28, weight: .bold, design: .rounded))
                                .foregroundColor(Color.appOnSurface(from: paletteManager))
                            
                            Spacer()
                        }
                        
                        Text("Customize how AltType looks and feels")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(Color.appOnSurface(from: paletteManager).opacity(0.7))
                    }
                    .padding(.horizontal, 32)
                    .padding(.top, 24)
                    
                    VStack(spacing: 24) {
                        // Theme Selection
                        SettingsDetailCard(title: "Theme", icon: "circle.lefthalf.filled") {
                            VStack(spacing: 16) {
                                ForEach(AppearanceMode.allCases) { mode in
                                    ThemeOptionRow(
                                        mode: mode,
                                        isSelected: appearanceSettings.preferredMode == mode,
                                        action: {
                                            appearanceSettings.preferredMode = mode
                                        }
                                    )
                                }
                            }
                        }
                        
                        // Color Palette Selection
                        SettingsDetailCard(title: "Color Palette", icon: "paintpalette.fill") {
                            VStack(spacing: 12) {
                                ForEach(PaletteOption.allCases) { palette in
                                    ColorPaletteRow(
                                        palette: palette,
                                        isSelected: paletteManager.selectedPalette == palette,
                                        action: {
                                            paletteManager.selectedPalette = palette
                                        }
                                    )
                                }
                            }
                        }
                        
                        // Preview Section
                        SettingsDetailCard(title: "Live Preview", icon: "eye.fill") {
                            AppearancePreviewCard()
                        }
                    }
                    .padding(.horizontal, 32)
                    
                    Spacer(minLength: 32)
                }
        }
        .background(Color.appBackground(from: paletteManager))
        .overlay(
            VStack {
                HStack {
                    Spacer()
                    Button("Done") {
                        dismiss()
                    }
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(Color.appPrimary(from: paletteManager))
                    .padding()
                }
                Spacer()
            }
        )
        .preferredColorScheme(appearanceSettings.preferredMode == .system ? nil : 
                            (appearanceSettings.preferredMode == .dark ? .dark : .light))
    }
}

struct ThemeOptionRow: View {
    let mode: AppearanceMode
    let isSelected: Bool
    let action: () -> Void
    @EnvironmentObject var paletteManager: PaletteManager
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                // Theme Icon with Preview
                RoundedRectangle(cornerRadius: 12)
                    .fill(themePreviewGradient)
                    .frame(width: 48, height: 48)
                    .overlay(
                        Image(systemName: mode.systemImage)
                            .font(.system(size: 20, weight: .medium))
                            .foregroundColor(themeIconColor)
                    )
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(mode.displayName)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(Color.appOnSurface(from: paletteManager))
                    
                    Text(mode.description)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(Color.appOnSurface(from: paletteManager).opacity(0.7))
                        .multilineTextAlignment(.leading)
                }
                
                Spacer()
                
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 20, weight: .medium))
                        .foregroundColor(Color.appSuccess(from: paletteManager))
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? Color.appPrimary(from: paletteManager).opacity(0.08) : Color.appSurface(from: paletteManager))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(isSelected ? Color.appPrimary(from: paletteManager).opacity(0.3) : Color.appOnSurface(from: paletteManager).opacity(0.1), lineWidth: 1.5)
                    )
            )
            .contentShape(Rectangle())
        }
        .buttonStyle(PlainButtonStyle())
        //.contentShape(Rectangle())
    }
    
    private var themePreviewGradient: LinearGradient {
        switch mode {
        case .light:
            return LinearGradient(colors: [.white, Color.gray.opacity(0.2)], startPoint: .topLeading, endPoint: .bottomTrailing)
        case .dark:
            return LinearGradient(colors: [Color.black, Color.gray.opacity(0.8)], startPoint: .topLeading, endPoint: .bottomTrailing)
        case .system:
            return LinearGradient(colors: [.white, Color.black], startPoint: .topLeading, endPoint: .bottomTrailing)
        }
    }
    
    private var themeIconColor: Color {
        switch mode {
        case .light:
            return .black
        case .dark:
            return .white
        case .system:
            return Color.appOnSurface(from: paletteManager)
        }
    }
}

struct ColorPaletteRow: View {
    let palette: PaletteOption
    let isSelected: Bool
    let action: () -> Void
    @EnvironmentObject var paletteManager: PaletteManager
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                // Color Preview
                HStack(spacing: 6) {
                    let paletteColors = palette.createPalette()
                    
                    ForEach(0..<3) { index in
                        let color = [paletteColors.primary.light, paletteColors.secondary.light, paletteColors.accent.light][index]
                        Circle()
                            .fill(Color(color))
                            .frame(width: 16, height: 16)
                    }
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.appSurface(from: paletteManager).opacity(0.5))
                )
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(palette.displayName)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(Color.appOnSurface(from: paletteManager))
                    
                    Text(palette.description)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(Color.appOnSurface(from: paletteManager).opacity(0.7))
                        .multilineTextAlignment(.leading)
                }
                
                Spacer()
                
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 20, weight: .medium))
                        .foregroundColor(Color.appSuccess(from: paletteManager))
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? Color.appPrimary(from: paletteManager).opacity(0.08) : Color.appSurface(from: paletteManager))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(isSelected ? Color.appPrimary(from: paletteManager).opacity(0.3) : Color.appOnSurface(from: paletteManager).opacity(0.1), lineWidth: 1.5)
                    )
            )
            .contentShape(Rectangle())
        }
        .buttonStyle(PlainButtonStyle())
        //.contentShape(Rectangle())
    }
}

struct AppearancePreviewCard: View {
    @EnvironmentObject var paletteManager: PaletteManager
    
    var body: some View {
        VStack(spacing: 16) {
            HStack {
                Text("Preview")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(Color.appOnSurface(from: paletteManager))
                Spacer()
            }
            
            // Sample UI Elements Preview
            VStack(spacing: 12) {
                // Sample Row
                HStack(spacing: 12) {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.appPrimary(from: paletteManager))
                        .frame(width: 32, height: 32)
                        .overlay(
                            Image(systemName: "mic.fill")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.white)
                        )
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Sample Setting")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(Color.appOnSurface(from: paletteManager))
                        
                        Text("This is how settings will look")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(Color.appOnSurface(from: paletteManager).opacity(0.7))
                    }
                    
                    Spacer()
                    
                    Toggle("", isOn: .constant(true))
                        .toggleStyle(SwitchToggleStyle(tint: Color.appPrimary(from: paletteManager)))
                        .scaleEffect(0.8)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.appSurface(from: paletteManager).opacity(0.5))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.appOnSurface(from: paletteManager).opacity(0.1), lineWidth: 1)
                        )
                )
                
                // Sample Button
                HStack {
                    Spacer()
                    Button("Sample Button") {}
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 8)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color.appAccent(from: paletteManager))
                        )
                    Spacer()
                }
            }
            
            Text("Changes apply immediately to all app elements")
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(Color.appOnSurface(from: paletteManager).opacity(0.6))
                .multilineTextAlignment(.center)
        }
    }
}

struct SettingsDetailCard<Content: View>: View {
    let title: String
    let icon: String
    @ViewBuilder let content: Content
    @EnvironmentObject var paletteManager: PaletteManager
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(Color.appPrimary(from: paletteManager))
                    .frame(width: 24)
                
                Text(title)
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(Color.appOnSurface(from: paletteManager))
                
                Spacer()
            }
            
            content
        }
        .padding(24)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.appSurface(from: paletteManager))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.appOnSurface(from: paletteManager).opacity(0.1), lineWidth: 1)
                )
        )
        .shadow(color: Color.appOnSurface(from: paletteManager).opacity(0.05), radius: 12, x: 0, y: 4)
    }
}

extension AppearanceMode {
    var description: String {
        switch self {
        case .light:
            return "Bright interface, great for daytime use"
        case .dark:
            return "Dark interface, easier on the eyes"
        case .system:
            return "Follows your system appearance"
        }
    }
}

// // #Preview {
//     AppearanceDetailView()
//         .environmentObject(AppearanceSettings())
//         .environmentObject(PaletteManager())
//         .frame(width: 500, height: 700)
// }
