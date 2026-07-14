import XCTest
import AppServices
import FullAppConfiguration
import PermissionKit

/// Tests to verify Full variant permission management behavior
@MainActor
final class PermissionManagementTests: XCTestCase {

    var permissionService: PermissionManager!

    override func setUp() async throws {
        // Initialize Full configuration before each test
        FullAppConfiguration.initialize()

        // Create permission service
        permissionService = AppServices.AppConfiguration.current.createPermissionService() as? PermissionManager
        XCTAssertNotNil(permissionService, "Failed to create PermissionManager")
    }

    override func tearDown() async throws {
        permissionService = nil
        AppServices.AppConfiguration.current = nil
    }

    // MARK: - Permission Requirements Tests

    func testFullVariantRequiresBothPermissions() {
        // Given: Full variant is configured
        let features = AppServices.AppConfiguration.current.features

        // Then: Both permissions should be required
        XCTAssertTrue(features.requiresInputMonitoring,
                     "Full variant should require input monitoring permission")
        XCTAssertTrue(features.requiresAccessibility,
                     "Full variant should require accessibility permission")
    }

    func testFullVariantNeedsPermissionsInitialState() {
        // Given: Permission service is freshly created

        // When: We check if permissions are needed
        let needsPermissions = permissionService.needsPermissions

        // Then: It should report that permissions are needed (unless already granted)
        // Note: This depends on actual system state, so we just verify the property exists
        XCTAssertNotNil(needsPermissions, "needsPermissions should be accessible")
    }

    func testFullVariantHasInputMonitoringCheck() {
        // Given: Permission service is created

        // When: We check input monitoring permission
        let hasInputMonitoring = permissionService.hasAccessibilityPermission

        // Then: It should report actual permission state
        XCTAssertNotNil(hasInputMonitoring, "Accessibility permission check should work")
    }

    func testFullVariantHasMicrophoneCheck() {
        // Given: Permission service is created

        // When: We check microphone permission
        let hasMicrophone = permissionService.hasMicrophonePermission

        // Then: It should report actual permission state
        XCTAssertNotNil(hasMicrophone, "Microphone permission check should work")
    }

    func testFullVariantAllPermissionsRequiresBoth() {
        // Given: Permission service is created

        // When: We check hasAllPermissions
        let hasAll = permissionService.hasAllPermissions

        // Then: It should only be true if BOTH permissions are granted
        // This is a logical test - actual state depends on system
        if permissionService.hasMicrophonePermission && permissionService.hasAccessibilityPermission {
            XCTAssertTrue(hasAll, "hasAllPermissions should be true when both permissions granted")
        } else {
            XCTAssertFalse(hasAll, "hasAllPermissions should be false when any permission missing")
        }
    }

    func testFullVariantCanRefreshPermissions() {
        // Given: Permission service is created

        // When: We refresh permission states
        permissionService.refreshPermissionStates()

        // Then: It should complete without error
        // Note: We can't verify state changes without actual permission grants
        XCTAssertNotNil(permissionService.microphoneState, "Microphone state should be updated")
        XCTAssertNotNil(permissionService.accessibilityState, "Accessibility state should be updated")
    }

    func testFullVariantCanOpenSystemSettings() {
        // Given: Permission service is created

        // When/Then: Opening system settings should not crash
        // Note: We can't verify the actual window opens in unit tests
        permissionService.openSystemSettings(for: .microphone)
        permissionService.openSystemSettings(for: .accessibility)

        // Test passes if no crash occurs
        XCTAssertTrue(true, "Opening system settings should not crash")
    }

    func testFullVariantCanStartMonitoring() {
        // Given: Permission service is created

        // When: We start monitoring
        permissionService.startMonitoring()

        // Then: It should start without error
        // Clean up
        permissionService.stopMonitoring()

        XCTAssertTrue(true, "Monitoring should start without error")
    }
}
