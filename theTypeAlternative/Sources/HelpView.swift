import SwiftUI
import AppKit
import AppServices

struct HelpView: View {
    @EnvironmentObject var paletteManager: PaletteManager
    @Environment(\.features) var features
    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(spacing: 32) {
                
                VStack(spacing: 32) {
                    // Getting Started and Key Features - Horizontal Stack
                    HStack(alignment: .top, spacing: 24) {
                        HelpCard(title: "Getting Started", icon: "play.circle") {
                            VStack(alignment: .leading, spacing: 16) {
                                HelpStep(
                                    number: 1,
                                    title: "Enable Permissions",
                                    description: features.requiresAccessibility
                                        ? "Enable microphone and accessibility access in System Settings"
                                        : "Enable microphone access in System Settings"
                                )

                                if features.supportsHotkeys {
                                    HelpStep(
                                        number: 2,
                                        title: "Set Your Hotkey",
                                        description: "Configure your preferred global hotkey (default: fn)"
                                    )

                                    HelpStep(
                                        number: 3,
                                        title: "Start Dictating",
                                        description: "Press your hotkey anywhere to start voice transcription"
                                    )
                                } else {
                                    HelpStep(
                                        number: 2,
                                        title: "Start Dictating",
                                        description: "Use the record button in the app to start voice transcription"
                                    )
                                }

                                Spacer(minLength: 0)

                                if features.supportsHotkeys {
                                    Divider()
                                        .padding(.vertical, 8)

                                    HStack {
                                        Image(systemName: "keyboard")
                                            .font(.system(size: 16, weight: .medium))
                                            .foregroundColor(Color.appPrimary(from: paletteManager))

                                        Text("Press")
                                            .font(.subheadline)
                                            .foregroundColor(Color.appOnSurface(from: paletteManager).opacity(0.8))

                                        Text("fn")
                                            .font(.system(size: 12, weight: .medium, design: .monospaced))
                                            .padding(.horizontal, 8)
                                            .padding(.vertical, 4)
                                            .background(
                                                RoundedRectangle(cornerRadius: 6)
                                                    .fill(Color.appSecondary(from: paletteManager).opacity(0.3))
                                            )

                                        Text("to start/stop dictation")
                                            .font(.subheadline)
                                            .foregroundColor(Color.appOnSurface(from: paletteManager).opacity(0.8))
                                    }
                                }
                            }
                        }
                        .frame(maxWidth: .infinity, minHeight: 380)
                        
                        HelpCard(title: "Key Features", icon: "star") {
                            VStack(alignment: .leading, spacing: 18) {
                                FeatureItem(
                                    icon: "lock.shield",
                                    title: "Privacy First",
                                    description: "All speech processing happens locally on your device"
                                )

                                FeatureItem(
                                    icon: "globe",
                                    title: "Universal Compatibility",
                                    description: "Works with any text field in any application"
                                )

                                FeatureItem(
                                    icon: "waveform",
                                    title: "Real-time Transcription",
                                    description: "See your words appear as you speak"
                                )

                                if features.supportsHotkeys {
                                    FeatureItem(
                                        icon: "keyboard",
                                        title: "Global Hotkeys",
                                        description: "Quick access from anywhere on your system"
                                    )
                                }

                                Spacer(minLength: 0)
                            }
                        }
                        .frame(maxWidth: .infinity, minHeight: 380)
                    }
                    
                    // Troubleshooting and Privacy & Security - Horizontal Stack
                    HStack(alignment: .top, spacing: 24) {
                        HelpCard(title: "Troubleshooting", icon: "wrench.and.screwdriver") {
                            VStack(alignment: .leading, spacing: 18) {
                                TroubleshootingItem(
                                    title: "Dictation not working?",
                                    solutions: features.requiresAccessibility
                                        ? [
                                            "Check microphone permissions in System Settings",
                                            "Ensure accessibility access is enabled in System Settings",
                                            "Try restarting the application"
                                        ]
                                        : [
                                            "Check microphone permissions in System Settings",
                                            "Try restarting the application"
                                        ]
                                )

                                if features.requiresAccessibility {
                                    TroubleshootingItem(
                                        title: "Text not appearing in target app?",
                                        solutions: [
                                            "Verify accessibility permissions",
                                            "Click in the text field before dictating",
                                            "Some secure apps may not support text insertion"
                                        ]
                                    )
                                }

                                if features.supportsHotkeys {
                                    TroubleshootingItem(
                                        title: "Global hotkey not responding?",
                                        solutions: [
                                            "Check if another app is using the same hotkey",
                                            "Try changing to a different key combination",
                                            "Restart the application"
                                        ]
                                    )
                                }

                                Spacer(minLength: 0)
                            }
                        }
                        .frame(maxWidth: .infinity, minHeight: 350)
                        
                        HelpCard(title: "Privacy & Security", icon: "lock.shield") {
                            VStack(alignment: .leading, spacing: 18) {
                                SecurityFeature(
                                    icon: "checkmark.shield.fill",
                                    iconColor: Color.appSuccess(from: paletteManager),
                                    title: "Local Processing Only",
                                    description: "All speech recognition happens directly on your device using built-in on-device processing. Your voice never leaves your computer."
                                )

                                SecurityFeature(
                                    icon: "eye.slash.fill",
                                    iconColor: Color.appPrimary(from: paletteManager),
                                    title: "No Data Collection",
                                    description: "We don't collect, store, or transmit any of your transcriptions or personal data."
                                )

                                SecurityFeature(
                                    icon: "key.fill",
                                    iconColor: Color.appWarning(from: paletteManager),
                                    title: "Minimal Permissions",
                                    description: features.requiresAccessibility
                                        ? "We only request the minimum permissions needed: microphone access for listening and accessibility for text insertion."
                                        : "We only request microphone access for listening to your voice."
                                )

                                Spacer(minLength: 0)
                            }
                        }
                        .frame(maxWidth: .infinity, minHeight: 350)
                    }
                    
                    // Open Source
                    HelpCard(title: "Open Source", icon: "chevron.left.forwardslash.chevron.right") {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("AltType is free and open source (MIT License).")
                                .font(.subheadline)
                                .fontWeight(.medium)

                            Text("The full source code, license, and privacy policy ship with the project repository.")
                                .font(.caption)
                                .foregroundColor(Color.appOnSurface(from: paletteManager).opacity(0.7))
                        }
                    }
                }
                .padding(.horizontal, 40)
                
                Spacer(minLength: 40)
            }
            .padding(.top, 32) // Add top padding for navigation bar spacing
        }
        .navigationTitle("Help & Support")
        .background(
            LinearGradient(
                gradient: Gradient(colors: [
                    Color.appBackground(from: paletteManager),
                    Color.appBackground(from: paletteManager).opacity(0.95)
                ]),
                startPoint: .top,
                endPoint: .bottom
            )
        )
    }
    
}

struct HelpCard<Content: View>: View {
    let title: String
    let icon: String
    @ViewBuilder let content: Content
    @EnvironmentObject var paletteManager: PaletteManager
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            HStack(spacing: 14) {
                ZStack {
                    Circle()
                        .fill(Color.appPrimary(from: paletteManager).opacity(0.1))
                        .frame(width: 36, height: 36)
                    
                    Image(systemName: icon)
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(Color.appPrimary(from: paletteManager))
                }
                
                Text(title)
                    .font(.title3)
                    .fontWeight(.semibold)
                    .foregroundColor(Color.appOnSurface(from: paletteManager))
                
                Spacer()
            }
            
            content
        }
        .padding(28)
        .frame(maxWidth: .infinity, alignment: .topLeading)
        .background(
            RoundedRectangle(cornerRadius: 18)
                .fill(Color.appSurface(from: paletteManager))
                .overlay(
                    RoundedRectangle(cornerRadius: 18)
                        .stroke(Color.appOnSurface(from: paletteManager).opacity(0.08), lineWidth: 1)
                )
                .shadow(color: Color.appOnSurface(from: paletteManager).opacity(0.08), radius: 12, x: 0, y: 4)
        )
    }
}

struct HelpStep: View {
    let number: Int
    let title: String
    let description: String
    @EnvironmentObject var paletteManager: PaletteManager
    
    var body: some View {
        HStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(Color.appPrimary(from: paletteManager))
                    .frame(width: 36, height: 36)
                
                Text("\(number)")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(Color.appOnPrimary(from: paletteManager))
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.body)
                    .fontWeight(.medium)
                    .foregroundColor(Color.appOnSurface(from: paletteManager))
                
                Text(description)
                    .font(.subheadline)
                    .foregroundColor(Color.appOnSurface(from: paletteManager).opacity(0.7))
                    .lineSpacing(1)
            }
            
            Spacer()
        }
    }
}

struct FeatureItem: View {
    let icon: String
    let title: String
    let description: String
    @EnvironmentObject var paletteManager: PaletteManager
    
    var body: some View {
        HStack(spacing: 16) {
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.appPrimary(from: paletteManager).opacity(0.1))
                    .frame(width: 32, height: 32)
                
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(Color.appPrimary(from: paletteManager))
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.body)
                    .fontWeight(.medium)
                    .foregroundColor(Color.appOnSurface(from: paletteManager))
                
                Text(description)
                    .font(.subheadline)
                    .foregroundColor(Color.appOnSurface(from: paletteManager).opacity(0.7))
                    .lineSpacing(1)
            }
            
            Spacer()
        }
    }
}

struct ShortcutRow: View {
    let shortcut: String
    let description: String
    @EnvironmentObject var paletteManager: PaletteManager
    
    var body: some View {
        HStack {
            Text(description)
                .font(.subheadline)
            
            Spacer()
            
            Text(shortcut)
                .font(.system(size: 12, weight: .medium, design: .monospaced))
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(
                    RoundedRectangle(cornerRadius: 6)
                        .fill(Color.appSecondary(from: paletteManager).opacity(0.3))
                )
        }
    }
}

struct TroubleshootingItem: View {
    let title: String
    let solutions: [String]
    @EnvironmentObject var paletteManager: PaletteManager
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(.body)
                .fontWeight(.medium)
                .foregroundColor(Color.appOnSurface(from: paletteManager))
            
            VStack(alignment: .leading, spacing: 6) {
                ForEach(solutions, id: \.self) { solution in
                    HStack(alignment: .top, spacing: 10) {
                        Circle()
                            .fill(Color.appPrimary(from: paletteManager))
                            .frame(width: 4, height: 4)
                            .padding(.top, 8)
                        
                        Text(solution)
                            .font(.subheadline)
                            .foregroundColor(Color.appOnSurface(from: paletteManager).opacity(0.7))
                            .lineSpacing(1)
                    }
                }
            }
        }
    }
}

struct SecurityFeature: View {
    let icon: String
    let iconColor: Color
    let title: String
    let description: String
    @EnvironmentObject var paletteManager: PaletteManager
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 12) {
                ZStack {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(iconColor.opacity(0.1))
                        .frame(width: 32, height: 32)
                    
                    Image(systemName: icon)
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(iconColor)
                }
                
                Text(title)
                    .font(.body)
                    .fontWeight(.medium)
                    .foregroundColor(Color.appOnSurface(from: paletteManager))
            }
            
            Text(description)
                .font(.subheadline)
                .foregroundColor(Color.appOnSurface(from: paletteManager).opacity(0.7))
                .lineSpacing(1.5)
        }
    }
}

// // #Preview {
//     HelpView()
//         .environmentObject(PaletteManager())
//         .environmentObject(TierManager.shared)
//         .frame(width: 800, height: 600)
// }