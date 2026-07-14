import Testing
import Foundation
@testable import FeatureFlags
@testable import BuildConfiguration

@MainActor
struct FeatureFlagManagerTests {

    @Test("Feature flag manager singleton")
    func testSingleton() throws {
        let manager1 = FeatureFlagManager.shared
        let manager2 = FeatureFlagManager.shared

        #expect(manager1 === manager2)
    }

    @Test("Default flag values")
    func testDefaultValues() throws {
        let manager = FeatureFlagManager.shared

        // Reset any overrides to get clean state
        #if DEBUG
        manager.resetAllOverrides()
        #endif

        // Test some default values
        #expect(manager.isEnabled(AppFeatureFlag.enableWhisperEngine) == true)
        #expect(manager.isEnabled(AppFeatureFlag.enableContextualIndicator) == true)
        #expect(manager.isEnabled(AppFeatureFlag.enableDetailedLogging) == false)
    }

    #if DEBUG
    @Test("Feature flag overrides in debug build")
    func testOverridesInDebugBuild() throws {
        let manager = FeatureFlagManager.shared
        let testFlag = AppFeatureFlag.enableDetailedLogging

        // Reset to clean state
        manager.resetAllOverrides()

        // Initially should use default value
        #expect(manager.isEnabled(testFlag) == testFlag.defaultValue)
        #expect(manager.hasOverride(for: testFlag) == false)

        // Set override
        manager.setOverride(for: testFlag, value: !testFlag.defaultValue)

        // Should now use override value
        #expect(manager.isEnabled(testFlag) == !testFlag.defaultValue)
        #expect(manager.hasOverride(for: testFlag) == true)

        // Remove override
        manager.removeOverride(for: testFlag)

        // Should return to default
        #expect(manager.isEnabled(testFlag) == testFlag.defaultValue)
        #expect(manager.hasOverride(for: testFlag) == false)
    }

    @Test("Feature flag override persistence")
    func testOverridePersistence() throws {
        let manager = FeatureFlagManager.shared
        let testFlag = AppFeatureFlag.enableDetailedLogging

        // Reset to clean state
        manager.resetAllOverrides()

        // Set override
        manager.setOverride(for: testFlag, value: true)

        // Verify it's persisted in UserDefaults
        let key = "FeatureFlag.\(testFlag.key)"
        #expect(UserDefaults.standard.bool(forKey: key) == true)

        // Clean up
        manager.resetAllOverrides()
    }

    @Test("Reset all overrides")
    func testResetAllOverrides() throws {
        let manager = FeatureFlagManager.shared

        // Set some overrides
        manager.setOverride(for: AppFeatureFlag.enablePerformanceMetrics, value: true)
        manager.setOverride(for: AppFeatureFlag.enableDetailedLogging, value: true)

        // Verify they're set
        #expect(manager.hasOverride(for: AppFeatureFlag.enablePerformanceMetrics))
        #expect(manager.hasOverride(for: AppFeatureFlag.enableDetailedLogging))

        // Reset all
        manager.resetAllOverrides()

        // Verify they're cleared
        #expect(manager.hasOverride(for: AppFeatureFlag.enablePerformanceMetrics) == false)
        #expect(manager.hasOverride(for: AppFeatureFlag.enableDetailedLogging) == false)
    }

    #else

    @Test("Feature flag overrides disabled in production")
    func testNoOverridesInProduction() throws {
        let manager = FeatureFlagManager.shared
        let testFlag = AppFeatureFlag.enableDetailedLogging

        // In production builds, overrides should not work
        #expect(manager.hasOverride(for: testFlag) == false)

        // setOverride and removeOverride should be no-ops
        manager.setOverride(for: testFlag, value: true)
        #expect(manager.hasOverride(for: testFlag) == false)
        #expect(manager.isEnabled(testFlag) == testFlag.defaultValue)

        manager.removeOverride(for: testFlag)
        // Should not crash and should still return default
        #expect(manager.isEnabled(testFlag) == testFlag.defaultValue)
    }

    #endif

    @Test("Flag status method")
    func testFlagStatus() throws {
        let manager = FeatureFlagManager.shared
        let testFlag = AppFeatureFlag.enableDetailedLogging

        #if DEBUG
        manager.resetAllOverrides()

        // Test default status
        let defaultStatus = manager.flagStatus(for: testFlag)
        #expect(defaultStatus.enabled == testFlag.defaultValue)
        #expect(defaultStatus.isOverridden == false)

        // Test overridden status
        manager.setOverride(for: testFlag, value: !testFlag.defaultValue)
        let overriddenStatus = manager.flagStatus(for: testFlag)
        #expect(overriddenStatus.enabled == !testFlag.defaultValue)
        #expect(overriddenStatus.isOverridden == true)

        manager.resetAllOverrides()
        #else
        // In production, never overridden
        let status = manager.flagStatus(for: testFlag)
        #expect(status.enabled == testFlag.defaultValue)
        #expect(status.isOverridden == false)
        #endif
    }

    @Test("Convenience methods")
    func testConvenienceMethods() throws {
        let manager = FeatureFlagManager.shared

        #if DEBUG
        manager.resetAllOverrides()
        #endif

        // Test convenience properties match direct flag access
        #expect(manager.isWhisperEngineEnabled == manager.isEnabled(AppFeatureFlag.enableWhisperEngine))
        #expect(manager.isContextualIndicatorEnabled == manager.isEnabled(AppFeatureFlag.enableContextualIndicator))
        #expect(manager.isDetailedLoggingEnabled == manager.isEnabled(AppFeatureFlag.enableDetailedLogging))
    }

    @Test("Configuration summary")
    func testConfigurationSummary() throws {
        let manager = FeatureFlagManager.shared

        #if DEBUG
        manager.resetAllOverrides()
        #endif

        let summary = manager.configurationSummary

        // Should contain expected sections
        #expect(summary.contains("Feature Flag Configuration"))

        // Should contain category sections
        #expect(summary.contains("[Speech Recognition]"))
        #expect(summary.contains("[User Interface]"))

        // Should contain flag status indicators
        #expect(summary.contains("✓") || summary.contains("✗"))
    }
}
