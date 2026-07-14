import Foundation
import SwiftUI
import Combine
import AppServices

/// No-op hotkey settings for lite version
/// Provides safe defaults without actual functionality
/// Lite version doesn't support hotkeys (NoOpHotkeyService handles this)
@MainActor
class NoOpHotkeySettings: HotkeySettingsProtocol {

    // MARK: - Published Properties (No-op)

    /// Empty key set - no hotkeys in lite version
    @Published public private(set) var requiredKeys: Set<UInt16> = []

    /// Display name indicating no hotkey support
    @Published public private(set) var displayName: String = "Not Available"

    /// Publisher for requiredKeys changes (always emits empty set)
    public var requiredKeysPublisher: AnyPublisher<Set<UInt16>, Never> {
        $requiredKeys.eraseToAnyPublisher()
    }

    // MARK: - Computed Properties

    public var isSingleKey: Bool { false }
    public var isModifierOnly: Bool { false }

    // MARK: - No-op Methods

    public func updateHotkey(_ newKeys: Set<UInt16>) {
        // No-op: Lite version doesn't support hotkey configuration
    }

    public func updateHotkey(singleKey: UInt16) {
        // No-op: Lite version doesn't support hotkey configuration
    }

    public func resetToDefault() {
        // No-op: Lite version doesn't support hotkey configuration
    }

    // MARK: - Backward Compatibility

    public var keyCode: UInt16 { 0 }
    public var modifiers: NSEvent.ModifierFlags { [] }
    public var cgEventFlags: CGEventFlags { [] }
}
