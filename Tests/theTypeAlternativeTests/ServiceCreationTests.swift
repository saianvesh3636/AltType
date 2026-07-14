import XCTest
import AppServices
import FullAppConfiguration
import HotkeyKit
import PermissionKit
import TextInsertionKit

/// Tests to verify Full variant creates correct service implementations via DI
@MainActor
final class ServiceCreationTests: XCTestCase {

    override func setUp() async throws {
        // Initialize Full configuration before each test
        FullAppConfiguration.initialize()
    }

    override func tearDown() async throws {
        // Clean up after each test
        AppServices.AppConfiguration.current = nil
    }

    // MARK: - Service Creation Tests

    func testCreateHotkeyServiceReturnsHotkeyManager() {
        // Given: Full configuration is initialized
        let config: AppServices.AppConfiguration = AppServices.AppConfiguration.current

        // When: We create a hotkey service
        let hotkeyService = config.createHotkeyService()

        // Then: It should be a HotkeyManager instance
        XCTAssertTrue(hotkeyService is HotkeyManager,
                     "Full variant should create HotkeyManager instance")
    }

    func testCreatePermissionServiceReturnsPermissionManager() {
        // Given: Full configuration is initialized
        let config: AppServices.AppConfiguration = AppServices.AppConfiguration.current

        // When: We create a permission service
        let permissionService = config.createPermissionService()

        // Then: It should be a PermissionManager instance
        XCTAssertTrue(permissionService is PermissionManager,
                     "Full variant should create PermissionManager instance")
    }

    func testCreateTextInsertionServiceReturnsUniversalTextInserter() {
        // Given: Full configuration is initialized
        let config: AppServices.AppConfiguration = AppServices.AppConfiguration.current

        // When: We create a text insertion service
        let textInserter = config.createTextInsertionService()

        // Then: It should be a UniversalTextInserter instance
        XCTAssertTrue(textInserter is UniversalTextInserter,
                     "Full variant should create UniversalTextInserter instance")
    }

    func testHotkeyServiceConformsToProtocol() {
        // Given: Full configuration is initialized
        let config: AppServices.AppConfiguration = AppServices.AppConfiguration.current

        // When: We create a hotkey service
        let hotkeyService = config.createHotkeyService()

        // Then: It should conform to HotkeyServiceProtocol
        XCTAssertNotNil(hotkeyService as? any HotkeyServiceProtocol,
                       "Hotkey service should conform to HotkeyServiceProtocol")
    }

    func testPermissionServiceConformsToProtocol() {
        // Given: Full configuration is initialized
        let config: AppServices.AppConfiguration = AppServices.AppConfiguration.current

        // When: We create a permission service
        let permissionService = config.createPermissionService()

        // Then: It should conform to PermissionServiceProtocol
        XCTAssertNotNil(permissionService as? any PermissionServiceProtocol,
                       "Permission service should conform to PermissionServiceProtocol")
    }

    func testTextInsertionServiceConformsToProtocol() {
        // Given: Full configuration is initialized
        let config: AppServices.AppConfiguration = AppServices.AppConfiguration.current

        // When: We create a text insertion service
        let textInserter = config.createTextInsertionService()

        // Then: It should conform to TextInsertionServiceProtocol
        XCTAssertNotNil(textInserter as? any TextInsertionServiceProtocol,
                       "Text insertion service should conform to TextInsertionServiceProtocol")
    }

    func testServicesAreNewInstancesEachTime() {
        // Given: Full configuration is initialized
        let config: AppServices.AppConfiguration = AppServices.AppConfiguration.current

        // When: We create services multiple times
        let hotkeyService1 = config.createHotkeyService()
        let hotkeyService2 = config.createHotkeyService()

        // Then: They should be different instances (factory pattern)
        XCTAssertFalse(hotkeyService1 === hotkeyService2,
                      "Factory should create new instances each time")
    }
}
