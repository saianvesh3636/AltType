import Foundation
import AppServices
@_exported import HotkeyKit
@_exported import PermissionKit
@_exported import TextInsertionKit
import SpeechKit

/// Full app configuration module
/// Wires up all Full implementations with complete feature set

// Type aliases for shared code (already using standard names, but explicit for clarity)
public typealias PermissionManager = PermissionKit.PermissionManager
public typealias HotkeyManager = HotkeyKit.HotkeyManager
public typealias UniversalTextInserter = TextInsertionKit.UniversalTextInserter

@MainActor
public struct FullAppConfiguration {

    /// Initialize the full app configuration
    /// This sets up AppConfiguration.current with all Full implementations
    public static func initialize() {
        AppConfiguration.current = AppConfiguration(
            features: .standard,

            // HotkeyKit - Full implementation with event taps and state management
            createHotkeyService: {
                HotkeyManager()
            },

            // PermissionKit - Full implementation with Microphone + Input Monitoring + Accessibility
            createPermissionService: {
                PermissionManager()
            },

            // TextInsertionKit - Multi-strategy (Accessibility API, Keyboard, Clipboard)
            createTextInsertionService: {
                UniversalTextInserter()
            }

            // Note: Speech service is created at app level (SpeechService)
            // because it requires additional dependencies (transcriptionStore, etc.)
            // The app creates the service and it conforms to SpeechServiceProtocol
        )
    }
}
