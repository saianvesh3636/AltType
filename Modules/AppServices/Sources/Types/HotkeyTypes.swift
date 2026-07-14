import Foundation

// MARK: - Hotkey Manager States

/// States the hotkey system can be in
public enum HotkeyManagerState: Equatable, Sendable {
    case dormant    // Minimal processing (~2-5 wake-ups/sec)
    case primed     // Full processing (~30 wake-ups/sec)
    case dictating  // Active transcription
}

// MARK: - Hotkey Events

/// Hotkey event types
public enum HotkeyEvent: Equatable, Sendable {
    case none
    case pressed(Date)
    case released(Date)
}

// MARK: - Hotkey State

/// Current hotkey state
public struct HotkeyState: Equatable, Sendable {
    public let isPressed: Bool
    public let lastEvent: HotkeyEvent

    public static let idle = HotkeyState(isPressed: false, lastEvent: .none)

    public init(isPressed: Bool, lastEvent: HotkeyEvent) {
        self.isPressed = isPressed
        self.lastEvent = lastEvent
    }
}
