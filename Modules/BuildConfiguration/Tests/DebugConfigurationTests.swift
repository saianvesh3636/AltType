import Testing
import Foundation
@testable import BuildConfiguration

@MainActor
struct DebugConfigurationTests {

    @Test("Debug configuration singleton")
    func testSingleton() throws {
        let config1 = DebugConfiguration.shared
        let config2 = DebugConfiguration.shared

        // Verify it's the same instance
        #expect(config1 === config2)
    }

    #if DEBUG
    @Test("Debug configuration properties in debug build")
    func testDebugBuildProperties() throws {
        let config = DebugConfiguration.shared

        // Reset to ensure clean state
        config.resetToDefaults()

        // Test default values
        #expect(config.enableVerboseLogging == false)
        #expect(config.simulateNetworkDelay == false)
        #expect(config.enableMockData == false)

        // Test that properties can be changed in debug builds
        config.enableVerboseLogging = true
        #expect(config.enableVerboseLogging == true)

        config.simulateNetworkDelay = true
        #expect(config.simulateNetworkDelay == true)

        config.enableMockData = true
        #expect(config.enableMockData == true)

        // Clean up
        config.resetToDefaults()
    }

    @Test("Debug configuration persistence")
    func testPersistence() throws {
        let config = DebugConfiguration.shared

        // Reset to clean state
        config.resetToDefaults()

        // Set some values
        config.enableVerboseLogging = true

        // Verify values are persisted in UserDefaults
        #expect(UserDefaults.standard.bool(forKey: "DebugConfiguration.enableVerboseLogging") == true)

        // Clean up
        config.resetToDefaults()
    }

    @Test("Debug configuration reset")
    func testReset() throws {
        let config = DebugConfiguration.shared

        // Set some non-default values
        config.enableVerboseLogging = true
        config.simulateNetworkDelay = true
        config.enableMockData = true

        // Reset
        config.resetToDefaults()

        // Verify all values are back to defaults
        #expect(config.enableVerboseLogging == false)
        #expect(config.simulateNetworkDelay == false)
        #expect(config.enableMockData == false)
    }

    #else

    @Test("Debug configuration properties in production build")
    func testProductionBuildProperties() throws {
        let config = DebugConfiguration.shared

        // In production builds, all debug properties should always be false
        #expect(config.enableVerboseLogging == false)
        #expect(config.simulateNetworkDelay == false)
        #expect(config.enableMockData == false)

        // Reset should be a no-op
        config.resetToDefaults() // Should not crash
    }

    #endif

    @Test("Debug configuration build detection")
    func testBuildDetection() throws {
        let config = DebugConfiguration.shared

        #if DEBUG
        #expect(config.isDebugBuild == true)
        #else
        #expect(config.isDebugBuild == false)
        #endif
    }

    @Test("Configuration summary")
    func testConfigurationSummary() throws {
        let config = DebugConfiguration.shared
        let summary = config.configurationSummary

        // Should contain key information
        #expect(summary.contains("Build Configuration"))
        #expect(summary.contains("Environment:"))
        #expect(summary.contains("Debug Build:"))

        #if DEBUG
        // Debug builds should include debug toggles section
        #expect(summary.contains("Debug Toggles"))
        #expect(summary.contains("Verbose Logging:"))
        #expect(summary.contains("Network Delay:"))
        #expect(summary.contains("Mock Data:"))
        #endif
    }
}
