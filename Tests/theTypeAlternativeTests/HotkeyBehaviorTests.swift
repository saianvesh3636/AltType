import XCTest
import AppServices
import FullAppConfiguration
import HotkeyKit
import Combine

/// Tests to verify Full variant hotkey behavior and state management
@MainActor
final class HotkeyBehaviorTests: XCTestCase {

    var hotkeyManager: HotkeyManager!
    var cancellables: Set<AnyCancellable>!

    override func setUp() async throws {
        // Initialize Full configuration before each test
        FullAppConfiguration.initialize()

        // Create hotkey manager
        hotkeyManager = AppServices.AppConfiguration.current.createHotkeyService() as? HotkeyManager
        XCTAssertNotNil(hotkeyManager, "Failed to create HotkeyManager")

        cancellables = []
    }

    override func tearDown() async throws {
        cancellables = nil
        hotkeyManager = nil
        AppServices.AppConfiguration.current = nil
    }

    // MARK: - Hotkey Support Tests

    func testFullVariantSupportsHotkeys() {
        // Given: Full variant is configured
        let features = AppServices.AppConfiguration.current.features

        // Then: Hotkeys should be supported
        XCTAssertTrue(features.supportsHotkeys,
                     "Full variant should support hotkeys")
    }

    func testHotkeyManagerInitialState() {
        // Given: HotkeyManager is freshly created

        // Then: It should be in initial states
        XCTAssertEqual(hotkeyManager.hotkeyState, .idle,
                      "Initial hotkey state should be idle")
        XCTAssertEqual(hotkeyManager.managerState, .dormant,
                      "Initial manager state should be dormant")
    }

    func testHotkeyManagerHasPublishers() {
        // Given: HotkeyManager is created

        // Then: Publishers should be accessible
        var hotkeyStateReceived = false
        var managerStateReceived = false

        hotkeyManager.hotkeyStatePublisher
            .sink { _ in hotkeyStateReceived = true }
            .store(in: &cancellables)

        hotkeyManager.managerStatePublisher
            .sink { _ in managerStateReceived = true }
            .store(in: &cancellables)

        XCTAssertTrue(hotkeyStateReceived, "Hotkey state publisher should emit initial value")
        XCTAssertTrue(managerStateReceived, "Manager state publisher should emit initial value")
    }

    func testCanRegisterHotkey() {
        // Given: HotkeyManager is created
        let testKeys: Set<UInt16> = [0x3F] // Fn key

        // When: We register a hotkey
        hotkeyManager.registerHotkey(testKeys)

        // Then: It should complete without error
        // Note: Actual registration depends on permissions
        XCTAssertTrue(true, "Hotkey registration should not crash")
    }

    func testCanClearHotkey() {
        // Given: HotkeyManager with a registered hotkey
        let testKeys: Set<UInt16> = [0x3F]
        hotkeyManager.registerHotkey(testKeys)

        // When: We clear the hotkey
        hotkeyManager.clearHotkey()

        // Then: It should complete without error
        XCTAssertTrue(true, "Hotkey clearing should not crash")
    }

    func testCanTransitionToPrimedMode() {
        // Given: HotkeyManager in dormant mode

        // When: We transition to primed mode
        hotkeyManager.transitionToPrimedMode(reason: "Test")

        // Then: Manager state should change to primed
        XCTAssertEqual(hotkeyManager.managerState, .primed,
                      "Manager state should be primed after transition")
    }

    func testCanTransitionToDormantMode() {
        // Given: HotkeyManager in primed mode
        hotkeyManager.transitionToPrimedMode(reason: "Setup")

        // When: We transition to dormant mode
        hotkeyManager.transitionToDormantMode(reason: "Test")

        // Then: Manager state should change to dormant
        XCTAssertEqual(hotkeyManager.managerState, .dormant,
                      "Manager state should be dormant after transition")
    }

    func testCanTransitionToDictatingMode() {
        // Given: HotkeyManager in primed mode
        hotkeyManager.transitionToPrimedMode(reason: "Setup")

        // When: We transition to dictating mode
        hotkeyManager.transitionToDictatingMode()

        // Then: Manager state should change to dictating
        XCTAssertEqual(hotkeyManager.managerState, .dictating,
                      "Manager state should be dictating after transition")
    }

    func testCanEndDictatingSession() {
        // Given: HotkeyManager in dictating mode
        hotkeyManager.transitionToPrimedMode(reason: "Setup")
        hotkeyManager.transitionToDictatingMode()

        // When: We end dictating session
        hotkeyManager.endDictatingSession()

        // Then: Manager state should return to primed
        XCTAssertEqual(hotkeyManager.managerState, .primed,
                      "Manager state should return to primed after ending dictation")
    }

    func testCanSetPermissionState() {
        // Given: HotkeyManager is created

        // When: We set permission state
        hotkeyManager.setPermissionState(hasPermissions: true)

        // Then: Registration should be enabled
        XCTAssertTrue(hotkeyManager.isRegistrationEnabled,
                     "Registration should be enabled when permissions granted")

        // When: We revoke permissions
        hotkeyManager.setPermissionState(hasPermissions: false)

        // Then: Registration should be disabled
        XCTAssertFalse(hotkeyManager.isRegistrationEnabled,
                      "Registration should be disabled when permissions revoked")
    }

    func testCanSignalUserIntent() {
        // Given: HotkeyManager is created

        // When: We signal user intent
        hotkeyManager.signalUserIntent(source: "Test")

        // Then: It should complete without error
        XCTAssertTrue(true, "Signaling user intent should not crash")
    }

    func testCanHandleSystemWake() {
        // Given: HotkeyManager is created

        // When: We handle system wake
        hotkeyManager.handleSystemWake()

        // Then: It should complete without error
        XCTAssertTrue(true, "Handling system wake should not crash")
    }
}
