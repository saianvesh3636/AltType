import Foundation
import SwiftUI

// MARK: - Whisper Support Switch

/// THE single switch for WhisperKit support.
///
/// Set `isEnabled` to `false` to compile the app without any WhisperKit surface:
/// the engine picker only offers Apple Speech, model management UI is hidden,
/// and no Whisper models are ever downloaded. Set it back to `true` to restore
/// the full WhisperKit experience. Nothing else needs to change.
public enum WhisperSupport {
    public static let isEnabled = true
}

// MARK: - Feature Set

/// Describes what features are available in this build
public struct FeatureSet: Sendable, Equatable {
    // MARK: - Core Features

    /// Whether system-wide hotkeys are supported (requires Input Monitoring)
    public let supportsHotkeys: Bool

    /// Whether advanced text insertion (AX API) is supported
    public let supportsAdvancedTextInsertion: Bool

    /// Whether menu bar integration is available
    public let supportsMenuBar: Bool

    /// Whether WhisperKit engine is available
    public let supportsWhisperKit: Bool

    // MARK: - Permission Requirements

    /// Whether Input Monitoring permission is required
    public let requiresInputMonitoring: Bool

    /// Whether Accessibility permission is required
    public let requiresAccessibility: Bool

    // MARK: - Display

    /// Display name for this app
    public let displayName: String

    /// Bundle identifier
    public let bundleIdentifier: String

    // MARK: - Presets

    /// Standard feature set
    public static let standard = FeatureSet(
        supportsHotkeys: true,
        supportsAdvancedTextInsertion: true,
        supportsMenuBar: true,
        supportsWhisperKit: WhisperSupport.isEnabled,
        requiresInputMonitoring: true,
        requiresAccessibility: true,
        displayName: "AltType",
        bundleIdentifier: "com.thetypealternative.app"
    )
}

// MARK: - Environment Key

private struct FeatureSetKey: EnvironmentKey {
    static let defaultValue: FeatureSet = .standard
}

public extension EnvironmentValues {
    var features: FeatureSet {
        get { self[FeatureSetKey.self] }
        set { self[FeatureSetKey.self] = newValue }
    }
}
