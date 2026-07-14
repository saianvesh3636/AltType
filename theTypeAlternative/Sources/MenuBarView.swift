import SwiftUI
import AppServices
import AppKit
import SpeechKit

struct MenuBarView: View {
    @EnvironmentObject var appCoordinator: AppCoordinator
    @EnvironmentObject var paletteManager: PaletteManager
    @Environment(\.hotkeySettings) var hotkeySettings // Custom environment value (protocol-based, optional)
    @EnvironmentObject var navigationHandler: NavigationHandler

    // Check if variant supports hotkeys using feature flag
    private var supportsHotkeys: Bool {
        AppServices.AppConfiguration.current.features.supportsHotkeys
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack {
                Image(systemName: "mic.fill")
                    .foregroundColor(Color.appPrimary(from: paletteManager))
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("AltType")
                        .font(.headline)
                        .foregroundColor(Color.appOnSurface(from: paletteManager))
                    
                    Text("Voice to Text")
                        .font(.caption)
                        .foregroundColor(Color.appOnSurface(from: paletteManager).opacity(0.7))
                }
                
                Spacer()
                
                Button(action: openMainWindow) {
                    Image(systemName: "arrow.up.right.square")
                }
                .buttonStyle(.borderless)
                .help("Open Main Window")
            }
            
            Divider()
            
            // Status
            HStack {
                Circle()
                    .fill(statusColor)
                    .frame(width: 8, height: 8)
                
                Text(statusText)
                    .font(.subheadline)
                    .foregroundColor(Color.appOnSurface(from: paletteManager))
            }
            
            // Quick Actions
            VStack(alignment: .leading, spacing: 8) {
                Button {
                    if needsPermissions {
                        openPermissionSettings()
                    } else {
                        toggleListening()
                    }
                } label: {
                    HStack {
                        if needsPermissions {
                            Image(systemName: "lock.fill")
                                .foregroundColor(.orange)
                            Text("Permissions Needed")
                                .foregroundColor(Color.appOnSurface(from: paletteManager))
                        } else {
                            Image(systemName: isListening ? "stop.fill" : "mic.fill")
                                .foregroundColor(Color.appPrimary(from: paletteManager))
                            Text(isListening ? "Stop Listening" : "Start Listening")
                                .foregroundColor(Color.appOnSurface(from: paletteManager))
                        }
                        Spacer()
                        if !needsPermissions, let hotkeySettings = hotkeySettings, supportsHotkeys {
                            Text(hotkeySettings.displayName)
                                .font(.caption)
                                .foregroundColor(Color.appOnSurface(from: paletteManager).opacity(0.7))
                        }
                    }
                }
                .buttonStyle(.borderless)
                
                Button("Open Settings...") {
                    openSettings()
                }
                .buttonStyle(.borderless)
                .foregroundColor(Color.appOnSurface(from: paletteManager))
            }
            
            Divider()
            
            // Permissions Status
            VStack(alignment: .leading, spacing: 4) {
                Text("Permissions")
                    .font(.caption)
                    .foregroundColor(Color.appOnSurface(from: paletteManager).opacity(0.7))

                HStack {
                    PermissionDot(isGranted: appCoordinator.permissionManager.hasMicrophonePermission)
                    Text("Microphone")
                        .font(.caption)
                        .foregroundColor(Color.appOnSurface(from: paletteManager))

                    // Only show Accessibility if variant requires it
                    if AppServices.AppConfiguration.current.features.requiresAccessibility {
                        Spacer()

                        PermissionDot(isGranted: appCoordinator.permissionManager.hasAccessibilityPermission)
                        Text("Accessibility")
                            .font(.caption)
                            .foregroundColor(Color.appOnSurface(from: paletteManager))
                    }
                }
            }
            
            Divider()

            // Quit
            Button("Quit AltType") {
                NSApplication.shared.terminate(nil)
            }
            .buttonStyle(.borderless)
            .foregroundColor(Color.appOnSurface(from: paletteManager))
        }
        .padding(12)
        .frame(width: 250)
        .background(Color.appSurface(from: paletteManager))
        .onAppear {
            // Signal user intent when menu bar is opened
            appCoordinator.signalUserIntent(source: "Menu bar opened")
        }
    }
    
    private var statusColor: Color {
        switch appCoordinator.state {
        case .idle:
            return Color.appSuccess(from: paletteManager)
        case .listening:
            return Color.appAccent(from: paletteManager)
        case .error:
            return Color.appError(from: paletteManager)
        }
    }
    
    private var statusText: String {
        switch appCoordinator.state {
        case .idle:
            return "Ready"
        case .listening:
            return "Listening..."
        case .error(let error):
            return error.localizedDescription
        }
    }
    
    private var isListening: Bool {
        if case .listening = appCoordinator.state {
            return true
        }
        return false
    }
    
    private var canToggle: Bool {
        switch appCoordinator.state {
        case .idle, .listening:
            return true
        case .error:
            return false
        }
    }

    /// True when any required permission is missing — derived from appCoordinator.state
    /// so SwiftUI re-renders when the state changes
    private var needsPermissions: Bool {
        if case .error(let err) = appCoordinator.state {
            switch err {
            case .microphonePermissionDenied, .accessibilityPermissionDenied:
                return true
            default:
                return false
            }
        }
        return !appCoordinator.permissionManager.hasMicrophonePermission ||
               (AppServices.AppConfiguration.current.features.requiresAccessibility &&
                !appCoordinator.permissionManager.hasAccessibilityPermission)
    }

    /// Opens the relevant System Settings pane for the missing permission
    private func openPermissionSettings() {
        if !appCoordinator.permissionManager.hasMicrophonePermission {
            appCoordinator.permissionManager.openSystemSettings(for: .microphone)
        } else if AppServices.AppConfiguration.current.features.requiresAccessibility &&
                  !appCoordinator.permissionManager.hasAccessibilityPermission {
            appCoordinator.permissionManager.openSystemSettings(for: .accessibility)
        }
    }

    private func toggleListening() {
        // Toggle listening state through AppCoordinator
        switch appCoordinator.state {
        case .idle:
            appCoordinator.startListening()
        case .listening:
            appCoordinator.stopListening()
        case .error:
            break
        }
    }
    
    private func openMainWindow() {
        // Activate main window
        NSApp.activate(ignoringOtherApps: true)
        
        // Find the main window (it should already exist from TheTypeAlternativeApp)
        // Look for any window that contains our ContentView (the main app window)
        if let mainWindow = NSApp.windows.first(where: { window in
            // Check if this is our main app window by looking for the title or checking if it's the main window
            return window.isMainWindow || window.title.contains("AltType") || window.isKeyWindow
        }) {
            // Bring existing main window to front
            mainWindow.makeKeyAndOrderFront(nil)
            mainWindow.orderFrontRegardless()
        } else {
            // Fallback: try to find any visible window
            if let anyWindow = NSApp.windows.first(where: { !$0.isFloatingPanel }) {
                anyWindow.makeKeyAndOrderFront(nil)
                anyWindow.orderFrontRegardless()
            } else {
                // Last resort: This should not happen as the main window should always exist
                // But if it doesn't, just activate the app which will show the main window
                NSApp.activate(ignoringOtherApps: true)
            }
        }
    }
    
    private func openSettings() {
        // Signal user intent before navigation
        appCoordinator.signalUserIntent(source: "Settings access from menu bar")

        // Use NavigationHandler to navigate to settings
        navigationHandler.navigateToSettings()

        // Dismiss the popover before activating the main window
        // to avoid the transient popover intercepting focus changes
        NSApp.sendAction(#selector(NSPopover.performClose(_:)), to: nil, from: nil)

        // Delay slightly to let the popover close before bringing up main window
        DispatchQueue.main.async { [self] in
            openMainWindow()
        }
    }
    
}

struct PermissionDot: View {
    let isGranted: Bool
    @EnvironmentObject var paletteManager: PaletteManager
    
    var body: some View {
        Circle()
            .fill(isGranted ? Color.appSuccess(from: paletteManager) : Color.appError(from: paletteManager))
            .frame(width: 6, height: 6)
    }
}

// // #Preview {
//     let store = TranscriptionStore()
//     let hotkeySettings = HotkeySettings()
//     let paletteManager = PaletteManager()
//     
//     // Create a mock AppCoordinator for preview
//     let mockCoordinator = AppCoordinator(
//         statusItem: nil,
//         transcriptionStore: store,
//         hotkeySettings: hotkeySettings,
//         permissionManager: PermissionManager(),
//         speechEngineManager: SpeechEngineManager(),
//         speechEngineSettings: SpeechEngineSettings(),
//         tierManager: TierManager.shared
//     )
//     
//     return MenuBarView()
//         .environmentObject(mockCoordinator)
//         .environmentObject(paletteManager)
//         .environmentObject(hotkeySettings)
//         .environmentObject(NavigationHandler())
// }