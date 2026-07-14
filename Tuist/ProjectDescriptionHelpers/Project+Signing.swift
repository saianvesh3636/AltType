import ProjectDescription

/// Extension to create settings that use xcconfig files for code signing
/// This approach lets xcconfig files control signing settings instead of Tuist defaults
public extension Settings {
    /// Creates settings with xcconfig-based code signing
    /// - Parameters:
    ///   - baseSettings: Base settings to apply globally
    ///   - xconfigPath: Path to the XCConfig directory
    /// - Returns: Settings configured with xcconfig files for Debug and Release
    static func withXCConfigSigning(
        baseSettings: SettingsDictionary = [:],
        xconfigPath: String = "XCConfig"
    ) -> Settings {
        return .settings(
            base: baseSettings,
            configurations: [
                .debug(
                    name: .debug,
                    settings: [:],  // Empty - let xcconfig handle everything
                    xcconfig: .relativeToRoot("\(xconfigPath)/Debug.xcconfig")
                ),
                .release(
                    name: .release,
                    settings: [:],  // Empty - let xcconfig handle everything
                    xcconfig: .relativeToRoot("\(xconfigPath)/Release.xcconfig")
                )
            ],
            defaultSettings: .none  // CRITICAL: Prevents Tuist from overriding xcconfig values
        )
    }
}

/// Extension for common base settings used across the project
public extension SettingsDictionary {
    /// Base settings for the main app target
    static var appBaseSettings: SettingsDictionary {
        [
            "PRODUCT_NAME": "theTypeAlternative",
            "MARKETING_VERSION": "1.0.0",
            "CURRENT_PROJECT_VERSION": "10",
            "GENERATE_INFOPLIST_FILE": false,
        ]
    }

    /// Base settings for framework targets
    static var frameworkBaseSettings: SettingsDictionary {
        [
            "SKIP_INSTALL": true,
            "ALWAYS_EMBED_SWIFT_STANDARD_LIBRARIES": false,
            "LD_RUNPATH_SEARCH_PATHS": ["$(inherited)", "@loader_path/Frameworks"],
        ]
    }
}
