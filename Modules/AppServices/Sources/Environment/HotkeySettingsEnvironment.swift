import Foundation
import SwiftUI

// MARK: - Hotkey Settings Environment Key

/// Environment key for hotkey settings
/// Allows optional injection based on app variant
struct HotkeySettingsKey: EnvironmentKey {
    nonisolated(unsafe) static let defaultValue: (any HotkeySettingsProtocol)? = nil
}

extension EnvironmentValues {
    /// Hotkey settings for the current environment
    /// - Full version: Provides HotkeySettings with configuration
    /// - Lite version: Provides NoOpHotkeySettings with safe defaults
    public var hotkeySettings: (any HotkeySettingsProtocol)? {
        get { self[HotkeySettingsKey.self] }
        set { self[HotkeySettingsKey.self] = newValue }
    }
}
