import Foundation
import Combine

// MARK: - Speech Action Delegate

/// Protocol for speech actions triggered by hotkey
@MainActor
public protocol SpeechActionDelegate: AnyObject {
    func startSpeechRecording()
    func stopSpeechRecording()
}

// MARK: - Sound Feedback Delegate

/// Protocol for sound feedback on hotkey events
@MainActor
public protocol SoundFeedbackDelegate: AnyObject {
    func playStartSound()
    func playStopSound()
}

// MARK: - Hotkey Service Protocol

/// Protocol for hotkey management service
@MainActor
public protocol HotkeyServiceProtocol: ObservableObject {
    // MARK: - Published State
    var hotkeyState: HotkeyState { get }
    var managerState: HotkeyManagerState { get }
    var isRegistrationEnabled: Bool { get }

    // MARK: - Publishers (for reactive binding)
    var hotkeyStatePublisher: Published<HotkeyState>.Publisher { get }
    var managerStatePublisher: Published<HotkeyManagerState>.Publisher { get }

    // MARK: - Delegates
    var speechActionDelegate: SpeechActionDelegate? { get set }
    var soundFeedbackDelegate: SoundFeedbackDelegate? { get set }

    // MARK: - Registration
    func registerHotkey(_ keys: Set<UInt16>)
    func clearHotkey()

    // MARK: - State Transitions
    func transitionToPrimedMode(reason: String)
    func transitionToDormantMode(reason: String)
    func transitionToDictatingMode()
    func endDictatingSession()

    // MARK: - Permission Integration
    func setPermissionState(hasPermissions: Bool)

    // MARK: - User Intent
    func signalUserIntent(source: String)

    // MARK: - System Event Handling
    func handleSystemWake()
}
