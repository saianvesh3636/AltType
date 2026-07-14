import XCTest
import AppServices
import FullAppConfiguration
import HotkeyKit
import Combine

/// Tests to verify Full variant smart dormant hotkey system
/// Tests dormant → primed → dictating state transitions and energy efficiency
@MainActor
final class HotkeyDormantModeTests: XCTestCase {

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

    // MARK: - Initial State Tests

    func testInitialStateIsDormant() {
        // Given: HotkeyManager is freshly created

        // Then: It should start in dormant mode (energy-efficient)
        XCTAssertEqual(hotkeyManager.managerState, .dormant,
                      "Initial manager state should be dormant for energy efficiency")
    }

    // MARK: - State Transition Tests

    func testDormantToPrimedTransition() {
        // Given: HotkeyManager in dormant mode
        XCTAssertEqual(hotkeyManager.managerState, .dormant)

        // When: We transition to primed mode (user activity detected)
        hotkeyManager.transitionToPrimedMode(reason: "User activity")

        // Then: Manager should enter primed mode (full event processing)
        XCTAssertEqual(hotkeyManager.managerState, .primed,
                      "Manager should transition from dormant to primed")
    }

    func testPrimedToDictatingTransition() {
        // Given: HotkeyManager in primed mode
        hotkeyManager.transitionToPrimedMode(reason: "Setup")
        XCTAssertEqual(hotkeyManager.managerState, .primed)

        // When: We transition to dictating mode (hotkey detected)
        hotkeyManager.transitionToDictatingMode()

        // Then: Manager should enter dictating mode
        XCTAssertEqual(hotkeyManager.managerState, .dictating,
                      "Manager should transition from primed to dictating")
    }

    func testDictatingBackToPrimedAfterSession() {
        // Given: HotkeyManager in dictating mode
        hotkeyManager.transitionToPrimedMode(reason: "Setup")
        hotkeyManager.transitionToDictatingMode()
        XCTAssertEqual(hotkeyManager.managerState, .dictating)

        // When: We end the dictating session
        hotkeyManager.endDictatingSession()

        // Then: Manager should return to primed mode (ready for next activation)
        XCTAssertEqual(hotkeyManager.managerState, .primed,
                      "Manager should return to primed after ending dictation")
    }

    func testPrimedBackToDormantAfterInactivity() {
        // Given: HotkeyManager in primed mode
        hotkeyManager.transitionToPrimedMode(reason: "Setup")
        XCTAssertEqual(hotkeyManager.managerState, .primed)

        // When: We transition back to dormant (energy saving after inactivity)
        hotkeyManager.transitionToDormantMode(reason: "Inactivity timeout")

        // Then: Manager should return to dormant mode
        XCTAssertEqual(hotkeyManager.managerState, .dormant,
                      "Manager should transition from primed back to dormant")
    }

    // MARK: - State Machine Validation Tests

    func testFullStateCycle() {
        // Given: HotkeyManager in dormant mode
        XCTAssertEqual(hotkeyManager.managerState, .dormant)

        // When: We go through a full cycle: dormant → primed → dictating → primed → dormant

        // Step 1: User activity → primed
        hotkeyManager.transitionToPrimedMode(reason: "User activity")
        XCTAssertEqual(hotkeyManager.managerState, .primed,
                      "Step 1: Should be primed")

        // Step 2: Hotkey detected → dictating
        hotkeyManager.transitionToDictatingMode()
        XCTAssertEqual(hotkeyManager.managerState, .dictating,
                      "Step 2: Should be dictating")

        // Step 3: Dictation ends → back to primed
        hotkeyManager.endDictatingSession()
        XCTAssertEqual(hotkeyManager.managerState, .primed,
                      "Step 3: Should be back to primed")

        // Step 4: Inactivity → back to dormant
        hotkeyManager.transitionToDormantMode(reason: "Inactivity")
        XCTAssertEqual(hotkeyManager.managerState, .dormant,
                      "Step 4: Should be back to dormant")
    }

    func testMultipleDictationSessions() {
        // Given: HotkeyManager ready for dictation
        hotkeyManager.transitionToPrimedMode(reason: "Setup")

        // When: We perform multiple dictation sessions
        for i in 1...3 {
            // Start dictation
            hotkeyManager.transitionToDictatingMode()
            XCTAssertEqual(hotkeyManager.managerState, .dictating,
                          "Dictation session \(i) should start")

            // End dictation
            hotkeyManager.endDictatingSession()
            XCTAssertEqual(hotkeyManager.managerState, .primed,
                          "After session \(i), should return to primed")
        }

        // Then: Manager should still be in primed mode
        XCTAssertEqual(hotkeyManager.managerState, .primed,
                      "After multiple sessions, should remain in primed mode")
    }

    // MARK: - Event Tap Behavior Tests

    func testManagerStatePublisherEmitsChanges() {
        // Given: HotkeyManager in dormant mode
        var stateChanges: [HotkeyManagerState] = []

        hotkeyManager.managerStatePublisher
            .sink { state in
                stateChanges.append(state)
            }
            .store(in: &cancellables)

        // When: We transition through states
        hotkeyManager.transitionToPrimedMode(reason: "Test")
        hotkeyManager.transitionToDictatingMode()
        hotkeyManager.endDictatingSession()

        // Then: Publisher should have emitted all state changes
        XCTAssertTrue(stateChanges.contains(.dormant), "Should have emitted dormant state")
        XCTAssertTrue(stateChanges.contains(.primed), "Should have emitted primed state")
        XCTAssertTrue(stateChanges.contains(.dictating), "Should have emitted dictating state")
    }

    // MARK: - Permission Integration Tests

    func testManagerRespectsPermissionState() {
        // Given: HotkeyManager with permissions denied
        hotkeyManager.setPermissionState(hasPermissions: false)

        // Then: Registration should be disabled
        XCTAssertFalse(hotkeyManager.isRegistrationEnabled,
                      "Registration should be disabled without permissions")

        // When: Permissions are granted
        hotkeyManager.setPermissionState(hasPermissions: true)

        // Then: Registration should be enabled
        XCTAssertTrue(hotkeyManager.isRegistrationEnabled,
                     "Registration should be enabled with permissions")
    }

    // MARK: - User Intent Signal Tests

    func testUserIntentSignalTransitionsToPrimed() {
        // Given: HotkeyManager in dormant mode
        XCTAssertEqual(hotkeyManager.managerState, .dormant)

        // When: User intent is signaled (e.g., user clicked button, moved mouse)
        hotkeyManager.signalUserIntent(source: "User click")

        // Then: Manager should transition to primed mode for responsiveness
        XCTAssertEqual(hotkeyManager.managerState, .primed,
                      "User intent should wake manager from dormant to primed")
    }

    // MARK: - System Wake Tests

    func testSystemWakeTransitionsToPrimed() {
        // Given: HotkeyManager in dormant mode
        XCTAssertEqual(hotkeyManager.managerState, .dormant)

        // When: System wakes from sleep
        hotkeyManager.handleSystemWake()

        // Then: Manager should transition to primed mode
        XCTAssertEqual(hotkeyManager.managerState, .primed,
                      "System wake should transition manager to primed for responsiveness")
    }

    // MARK: - Energy Efficiency Behavior Tests

    func testDormantModeReducesProcessing() {
        // Given: HotkeyManager can transition between modes

        // When: In dormant mode
        hotkeyManager.transitionToDormantMode(reason: "Energy saving")
        XCTAssertEqual(hotkeyManager.managerState, .dormant)

        // Then: Manager is in low-power state
        // Note: This test verifies the state exists
        // Actual energy measurement would require integration tests
        XCTAssertEqual(hotkeyManager.managerState, .dormant,
                      "Dormant mode should be active for energy efficiency")
    }

    func testPrimedModeEnablesFullProcessing() {
        // Given: HotkeyManager transitions to primed

        // When: In primed mode
        hotkeyManager.transitionToPrimedMode(reason: "Full processing needed")

        // Then: Manager is ready for instant hotkey response
        XCTAssertEqual(hotkeyManager.managerState, .primed,
                      "Primed mode should be active for full event processing")
    }
}
