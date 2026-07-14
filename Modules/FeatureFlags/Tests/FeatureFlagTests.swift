import Testing
@testable import FeatureFlags

struct FeatureFlagTests {

    @Test("Feature flag properties")
    func testFeatureFlagProperties() throws {
        let flag = AppFeatureFlag.enableWhisperEngine

        #expect(flag.key == "enable_whisper_engine")
        #expect(flag.name == "Whisper Engine")
        #expect(flag.description == "Enable WhisperKit for speech recognition")
        #expect(flag.defaultValue == true)
        #expect(flag.allowsDebugOverride == true)
        #expect(flag.category == .speech)
    }

    @Test("Feature flag categories")
    func testFeatureFlagCategories() throws {
        let allCategories = FeatureFlagCategory.allCases

        #expect(allCategories.contains(.speech))
        #expect(allCategories.contains(.ui))
        #expect(allCategories.contains(.permissions))
        #expect(allCategories.contains(.performance))
        #expect(allCategories.contains(.logging))

        // Test display names
        #expect(FeatureFlagCategory.speech.displayName == "Speech Recognition")
        #expect(FeatureFlagCategory.logging.displayName == "Logging & Debug")
    }

    @Test("All feature flags registry")
    func testAllFlagsRegistry() throws {
        let allFlags = AppFeatureFlag.allFlags

        // Verify specific flags exist
        #expect(allFlags.contains { $0.key == "enable_whisper_engine" })
        #expect(allFlags.contains { $0.key == "enable_apple_speech_engine" })
        #expect(allFlags.contains { $0.key == "enable_contextual_indicator" })
        #expect(allFlags.contains { $0.key == "enable_detailed_logging" })
    }

    @Test("Feature flags by category grouping")
    func testFlagsByCategory() throws {
        let flagsByCategory = AppFeatureFlag.flagsByCategory

        // Test speech flags
        let speechFlags = flagsByCategory[.speech] ?? []
        #expect(speechFlags.contains { $0.key == "enable_whisper_engine" })
        #expect(speechFlags.contains { $0.key == "enable_apple_speech_engine" })

        // Test UI flags
        let uiFlags = flagsByCategory[.ui] ?? []
        #expect(uiFlags.contains { $0.key == "enable_contextual_indicator" })
        #expect(uiFlags.contains { $0.key == "enable_menu_bar_status" })
    }

    @Test("Convenience flag creation")
    func testConvenienceFlags() throws {
        let whisperFlag = AppFeatureFlag.enableWhisperEngine
        #expect(whisperFlag.category == .speech)
        #expect(whisperFlag.defaultValue == true)

        let indicatorFlag = AppFeatureFlag.enableContextualIndicator
        #expect(indicatorFlag.category == .ui)
        #expect(indicatorFlag.defaultValue == true)
    }

    @Test("Custom feature flag creation")
    func testCustomFeatureFlag() throws {
        let customFlag = AppFeatureFlag(
            key: "test_custom_feature",
            name: "Test Feature",
            description: "A test feature for unit testing",
            defaultValue: true,
            allowsDebugOverride: false,
            category: .performance
        )

        #expect(customFlag.key == "test_custom_feature")
        #expect(customFlag.name == "Test Feature")
        #expect(customFlag.description == "A test feature for unit testing")
        #expect(customFlag.defaultValue == true)
        #expect(customFlag.allowsDebugOverride == false)
        #expect(customFlag.category == .performance)
    }
}
