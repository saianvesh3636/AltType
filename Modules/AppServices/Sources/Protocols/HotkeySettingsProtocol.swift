import Foundation
import Combine
import AppKit
import CoreGraphics

/// Protocol for hotkey settings configuration
/// Provides abstraction for different app variants (Full vs Lite)
@MainActor
public protocol HotkeySettingsProtocol: ObservableObject {
    // MARK: - Published Properties

    /// The set of keys that must be pressed simultaneously
    var requiredKeys: Set<UInt16> { get }

    /// Human-readable display name for the hotkey combination
    var displayName: String { get }

    /// Publisher for requiredKeys changes
    var requiredKeysPublisher: AnyPublisher<Set<UInt16>, Never> { get }

    // MARK: - Computed Properties

    /// Check if this is a single key hotkey
    var isSingleKey: Bool { get }

    /// Check if this contains only modifier keys
    var isModifierOnly: Bool { get }

    // MARK: - Configuration Methods

    /// Update the hotkey combination
    func updateHotkey(_ newKeys: Set<UInt16>)

    /// Update with single key (convenience method)
    func updateHotkey(singleKey: UInt16)

    /// Reset to default hotkey
    func resetToDefault()

    // MARK: - Backward Compatibility

    /// Legacy keyCode property for backward compatibility
    var keyCode: UInt16 { get }

    /// Legacy modifiers property
    var modifiers: NSEvent.ModifierFlags { get }

    /// Legacy CGEventFlags
    var cgEventFlags: CGEventFlags { get }
}
