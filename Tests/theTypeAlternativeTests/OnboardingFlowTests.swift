import XCTest
import AppServices
import FullAppConfiguration

/// Tests to verify Full variant onboarding and permission configuration
@MainActor
final class OnboardingFlowTests: XCTestCase {

    override func setUp() async throws {
        // Initialize Full configuration before each test
        FullAppConfiguration.initialize()
    }

    override func tearDown() async throws {
        AppServices.AppConfiguration.current = nil
    }

    // MARK: - Permission Configuration Tests

    func testFullVariantRequiresInputMonitoring() {
        // Given: Full variant is configured
        let features = AppServices.AppConfiguration.current.features

        // Then: Input Monitoring SHOULD be required
        XCTAssertTrue(features.requiresInputMonitoring,
                     "Full variant SHOULD require input monitoring")
    }

    func testFullVariantRequiresAccessibility() {
        // Given: Full variant is configured
        let features = AppServices.AppConfiguration.current.features

        // Then: Accessibility SHOULD be required
        XCTAssertTrue(features.requiresAccessibility,
                     "Full variant SHOULD require accessibility")
    }

    func testFullVariantRequiresBothPermissions() {
        // Given: Full variant is configured
        let features = AppServices.AppConfiguration.current.features

        // Then: Both microphone AND input monitoring/accessibility are required
        XCTAssertTrue(features.requiresInputMonitoring,
                     "Full should require input monitoring")
        XCTAssertTrue(features.requiresAccessibility,
                     "Full should require accessibility")
    }

    func testFeatureSetConfiguration() {
        // Given: configuration is initialized
        let features = AppServices.AppConfiguration.current.features

        // Then: Verify feature flags
        XCTAssertTrue(features.requiresInputMonitoring,
                     "SHOULD require input monitoring")
        XCTAssertTrue(features.requiresAccessibility,
                     "SHOULD require accessibility")
        XCTAssertTrue(features.supportsHotkeys,
                     "SHOULD support hotkeys")
    }

    func testSupportsAdvancedFeatures() {
        // Given: configuration is initialized
        let features = AppServices.AppConfiguration.current.features

        // Supports hotkeys (requires input monitoring)
        XCTAssertTrue(features.supportsHotkeys,
                     "Supports hotkeys")
        XCTAssertTrue(features.requiresInputMonitoring,
                     "Hotkeys require input monitoring")

        // Uses accessibility-based text insertion
        XCTAssertTrue(features.requiresAccessibility,
                     "Uses accessibility API for text insertion")
    }
}
