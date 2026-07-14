import XCTest
import AppServices
import FullAppConfiguration

/// Tests to verify Full variant configuration initialization
@MainActor
final class ConfigurationInitializationTests: XCTestCase {

    override func setUp() async throws {
        // Initialize Full configuration before each test
        FullAppConfiguration.initialize()
    }

    override func tearDown() async throws {
        // Clean up after each test
        AppServices.AppConfiguration.current = nil
    }

    // MARK: - Configuration Initialization Tests

    func testFullAppConfigurationInitializes() {
        // Given: FullAppConfiguration.initialize() was called in setUp

        // When: We access the current configuration
        let config = AppServices.AppConfiguration.current

        // Then: Configuration should exist
        XCTAssertNotNil(config, "AppConfiguration.current should be initialized")
    }

    func testFeatureSetIsStandard() {
        // Given: configuration is initialized
        let features = AppServices.AppConfiguration.current.features

        // Then: FeatureSet should be .standard
        XCTAssertEqual(features, FeatureSet.standard, "Features should match FeatureSet.standard")
    }

    func testFeatureFlags() {
        // Given: configuration is initialized
        let features = AppServices.AppConfiguration.current.features

        // Then: Feature flags should match expectations
        XCTAssertTrue(features.supportsHotkeys, "Should support hotkeys")
        XCTAssertTrue(features.supportsAdvancedTextInsertion, "Should support advanced text insertion")
        XCTAssertTrue(features.supportsMenuBar, "Should support menu bar")
        XCTAssertEqual(features.supportsWhisperKit, WhisperSupport.isEnabled, "WhisperKit support should follow the WhisperSupport switch")
        XCTAssertTrue(features.requiresInputMonitoring, "Should require input monitoring")
        XCTAssertTrue(features.requiresAccessibility, "Should require accessibility")
    }

    func testDisplayName() {
        // Given: configuration is initialized
        let features = AppServices.AppConfiguration.current.features

        // Then: Display name should be "AltType"
        XCTAssertEqual(features.displayName, "AltType", "Display name should be 'AltType'")
    }

    func testBundleIdentifier() {
        // Given: configuration is initialized
        let features = AppServices.AppConfiguration.current.features

        // Then: Bundle ID should be correct
        XCTAssertEqual(features.bundleIdentifier, "com.thetypealternative.app",
                      "Bundle ID should be 'com.thetypealternative.app'")
    }
}
