import SwiftUI
import AppKit
import Combine
import AppServices

// Legacy SettingsView - Replaced by ImprovedSettingsMainView
// This is kept for compatibility but redirects to the improved version
struct SettingsView: View {
    @Environment(\.hotkeySettings) var hotkeySettings
    @EnvironmentObject var paletteManager: PaletteManager
    @StateObject private var appearanceSettings = AppearanceSettings()

    let permissionManager: any PermissionServiceProtocol

    var body: some View {
        ImprovedSettingsMainView(permissionManager: permissionManager)
            .environmentObject(paletteManager)
            .environmentObject(appearanceSettings)
    }
}

struct PalettePreviewCard: View {
    let palette: PaletteOption
    let isSelected: Bool
    let onSelect: () -> Void
    @EnvironmentObject var paletteManager: PaletteManager
    
    var body: some View {
        Button(action: onSelect) {
            HStack(spacing: 12) {
                // Icon
                Image(systemName: palette.systemImage)
                    .font(.title3)
                    .foregroundColor(Color(palette.createPalette().primary.light))
                    .frame(width: 24, height: 24)
                
                // Name and Description
                VStack(alignment: .leading, spacing: 2) {
                    Text(palette.displayName)
                        .font(.system(.body, design: .default, weight: .medium))
                        .foregroundColor(Color.appOnSurface(from: paletteManager))
                    
                    Text(palette.description)
                        .font(.caption)
                        .foregroundColor(Color.appOnSurface(from: paletteManager).opacity(0.7))
                }
                
                Spacer()
                
                // Color Preview Dots
                HStack(spacing: 4) {
                    let paletteColors = palette.createPalette()
                    
                    Circle()
                        .fill(Color(paletteColors.primary.light))
                        .frame(width: 12, height: 12)
                    
                    Circle()
                        .fill(Color(paletteColors.secondary.light))
                        .frame(width: 12, height: 12)
                    
                    Circle()
                        .fill(Color(paletteColors.accent.light))
                        .frame(width: 12, height: 12)
                }
                
                // Selection Indicator
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(Color.appAccent(from: paletteManager))
                }
            }
            .padding(.vertical, 8)
            .padding(.horizontal, 12)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(isSelected ? Color.appAccent(from: paletteManager).opacity(0.1) : Color.clear)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(isSelected ? Color.appAccent(from: paletteManager).opacity(0.3) : Color.clear, lineWidth: 1)
                    )
            )
            .contentShape(Rectangle())
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// // #Preview {
//     SettingsView(permissionManager: PermissionManager.shared)
//         .environmentObject(AppearanceSettings())
//         .environmentObject(PaletteManager())
//         .frame(width: 800, height: 600)
// }