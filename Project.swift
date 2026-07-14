import ProjectDescription

// MARK: - Code Signing Configuration
// Code signing uses Team ID WGJDQSJR57 for BOTH Debug and Release:
// - Debug: "Apple Development" certificate
// - Release: "Apple Distribution" certificate
// Additional build settings are in XCConfig/ directory (Shared, Debug, Release xcconfig files)

let project = Project(
    name: "theTypeAlternative",
    organizationName: "theTypeAlternative",
    options: .options(
        automaticSchemesOptions: .disabled,
        disableBundleAccessors: false,
        disableShowEnvironmentVarsInScriptPhases: false,
        disableSynthesizedResourceAccessors: false,
        textSettings: .textSettings(
            usesTabs: false,
            indentWidth: 4,
            tabWidth: 4,
            wrapsLines: true
        )
    ),
    packages: [
        .remote(
            url: "https://github.com/swiftlang/swift-testing.git",
            requirement: .exact("0.99.0")
        ),
    ],
    settings: .settings(
        base: [
            "SWIFT_VERSION": "6.0",
            "MACOSX_DEPLOYMENT_TARGET": "26.0",
            "IPHONEOS_DEPLOYMENT_TARGET": "17.0",
            "PRODUCT_NAME": "$(TARGET_NAME)",
            "SWIFT_EMIT_LOC_STRINGS": true,
            "ENABLE_TESTING_SEARCH_PATHS": true,
            "ALWAYS_SEARCH_USER_PATHS": false
        ],
        configurations: [
            .debug(
                name: .debug,
                settings: [:],
                xcconfig: .relativeToRoot("XCConfig/Debug.xcconfig")
            ),
            .release(
                name: .release,
                settings: [:],
                xcconfig: .relativeToRoot("XCConfig/Release.xcconfig")
            )
        ],
        defaultSettings: .recommended(excluding: [
            "CODE_SIGN_IDENTITY",
            "DEVELOPMENT_TEAM"
        ])  // Keep essential settings, let xcconfig control signing
    ),
    targets: [
        // Main Application Target
        .target(
            name: "theTypeAlternative",
            destinations: [.mac],
            product: .app,
            bundleId: "com.thetypealternative.app",
            deploymentTargets: .macOS("26.0"),
            infoPlist: .extendingDefault(with: [
                "CFBundleDisplayName": "AltType",
                "CFBundleShortVersionString": "1.1.0",
                "CFBundleVersion": "10",
                "LSUIElement": false, // Full app with Dock icon
                "LSApplicationCategoryType": "public.app-category.productivity",
                "NSMicrophoneUsageDescription": "AltType captures audio to transcribe your speech into text. All processing happens on your device.",
                "NSAccessibilityUsageDescription": "AltType requires permission to insert the transcribed text into other applications and to capture the global hotkey (fn) that starts dictation.",
                "NSHumanReadableCopyright": "Copyright © 2026 The Type Alternative contributors. MIT License.",
                "NSMainStoryboardFile": "",
                "NSPrincipalClass": "NSApplication",
                "ITSAppUsesNonExemptEncryption": false
            ]),
            sources: ["theTypeAlternative/Sources/**"],
            resources: [
                .folderReference(path: "theTypeAlternative/Resources/Assets.xcassets"),
                .folderReference(path: "theTypeAlternative/Resources/Models"),
                .glob(pattern: "theTypeAlternative/Resources/PrivacyInfo.xcprivacy")
            ],
            entitlements: .file(path: "theTypeAlternative/theTypeAlternative.entitlements"),
            dependencies: [
                .target(name: "AppServices"),
                .target(name: "FullAppConfiguration"),
                .target(name: "HotkeyKit"),
                .target(name: "SpeechKit"),
                .target(name: "TextInsertionKit"),
                .target(name: "PermissionKit"),
                .target(name: "BuildConfiguration"),
                .target(name: "FeatureFlags")
            ],
            settings: .settings(
                base: [
                    "PRODUCT_NAME": "AltType",
                    // Visible app is AltType.app; the Swift module keeps the internal name
                    // so `@testable import theTypeAlternative` keeps working
                    "PRODUCT_MODULE_NAME": "theTypeAlternative",
                    "MARKETING_VERSION": "1.1.0",
                    "CURRENT_PROJECT_VERSION": "10",
                    "GENERATE_INFOPLIST_FILE": false,
                    "ENABLE_APP_SANDBOX": "NO"  // No sandbox (uses Accessibility API)
                ],
                configurations: [
                    .debug(
                        name: .debug,
                        settings: [:],
                        xcconfig: .relativeToRoot("XCConfig/Debug.xcconfig")
                    ),
                    .release(
                        name: .release,
                        settings: [:],
                        xcconfig: .relativeToRoot("XCConfig/Release.xcconfig")
                    )
                ],
                defaultSettings: .recommended(excluding: [
                    "CODE_SIGN_IDENTITY",
                    "DEVELOPMENT_TEAM"
                ])
            )
        ),

        // AppServices Framework (Protocols only)
        .target(
            name: "AppServices",
            destinations: [.mac],
            product: .framework,
            bundleId: "com.thetypealternative.appservices",
            deploymentTargets: .macOS("26.0"),
            infoPlist: .default,
            sources: ["Modules/AppServices/Sources/**"],
            resources: [],
            dependencies: [],
            settings: .settings(
                base: [
                    "PRODUCT_BUNDLE_IDENTIFIER": "com.thetypealternative.appservices",
                    "PRODUCT_NAME": "AppServices",
                    "SKIP_INSTALL": true,
                    "SWIFT_VERSION": "6.0",
                    "SWIFT_STRICT_CONCURRENCY": "complete",
                    "ALWAYS_EMBED_SWIFT_STANDARD_LIBRARIES": false,
                    "LD_RUNPATH_SEARCH_PATHS": ["$(inherited)", "@loader_path/Frameworks"]
                ]
            )
        ),

        // HotkeyKit Framework
        .target(
            name: "HotkeyKit",
            destinations: [.mac],
            product: .framework,
            bundleId: "com.thetypealternative.hotkeykit",
            deploymentTargets: .macOS("26.0"),
            infoPlist: .default,
            sources: ["Modules/HotkeyKit/Sources/**"],
            resources: [],
            dependencies: [
                .target(name: "AppServices"),
                .target(name: "BuildConfiguration")
            ],
            settings: .settings(
                base: [
                    "PRODUCT_BUNDLE_IDENTIFIER": "com.thetypealternative.hotkeykit",
                    "PRODUCT_NAME": "HotkeyKit",
                    "SKIP_INSTALL": true,
                    "ALWAYS_EMBED_SWIFT_STANDARD_LIBRARIES": false,
                    "LD_RUNPATH_SEARCH_PATHS": ["$(inherited)", "@loader_path/Frameworks"]
                ]
            )
        ),

        // SpeechKit Framework
        .target(
            name: "SpeechKit",
            destinations: [.mac],
            product: .framework,
            bundleId: "com.thetypealternative.speechkit",
            deploymentTargets: .macOS("26.0"),
            infoPlist: .default,
            sources: ["Modules/SpeechKit/Sources/**"],
            resources: [
                .folderReference(path: "Modules/SpeechKit/Resources")
            ],
            dependencies: [
                .target(name: "AppServices"),
                .target(name: "BuildConfiguration"),
                .external(name: "WhisperKit")
            ],
            settings: .settings(
                base: [
                    "PRODUCT_BUNDLE_IDENTIFIER": "com.thetypealternative.speechkit",
                    "PRODUCT_NAME": "SpeechKit",
                    "SKIP_INSTALL": true,
                    "ALWAYS_EMBED_SWIFT_STANDARD_LIBRARIES": false,
                    "LD_RUNPATH_SEARCH_PATHS": ["$(inherited)", "@loader_path/Frameworks"]
                ]
            )
        ),

        // TextInsertionKit Framework
        .target(
            name: "TextInsertionKit",
            destinations: [.mac],
            product: .framework,
            bundleId: "com.thetypealternative.textinsertionkit",
            deploymentTargets: .macOS("26.0"),
            infoPlist: .default,
            sources: ["Modules/TextInsertionKit/Sources/**"],
            resources: [],
            dependencies: [
                .target(name: "AppServices"),
                .target(name: "HotkeyKit"),
                .target(name: "BuildConfiguration")
            ],
            settings: .settings(
                base: [
                    "PRODUCT_BUNDLE_IDENTIFIER": "com.thetypealternative.textinsertionkit",
                    "PRODUCT_NAME": "TextInsertionKit",
                    "SKIP_INSTALL": true,
                    "ALWAYS_EMBED_SWIFT_STANDARD_LIBRARIES": false,
                    "LD_RUNPATH_SEARCH_PATHS": ["$(inherited)", "@loader_path/Frameworks"]
                ]
            )
        ),

        // PermissionKit Framework
        .target(
            name: "PermissionKit",
            destinations: [.mac],
            product: .framework,
            bundleId: "com.thetypealternative.permissionkit",
            deploymentTargets: .macOS("26.0"),
            infoPlist: .default,
            sources: ["Modules/PermissionKit/Sources/**"],
            resources: [],
            dependencies: [
                .target(name: "AppServices")
            ],
            settings: .settings(
                base: [
                    "PRODUCT_BUNDLE_IDENTIFIER": "com.thetypealternative.permissionkit",
                    "PRODUCT_NAME": "PermissionKit",
                    "SKIP_INSTALL": true,
                    "ALWAYS_EMBED_SWIFT_STANDARD_LIBRARIES": false,
                    "LD_RUNPATH_SEARCH_PATHS": ["$(inherited)", "@loader_path/Frameworks"]
                ]
            )
        ),

        // BuildConfiguration Framework
        .target(
            name: "BuildConfiguration",
            destinations: [.mac],
            product: .framework,
            bundleId: "com.thetypealternative.buildconfiguration",
            deploymentTargets: .macOS("26.0"),
            infoPlist: .default,
            sources: ["Modules/BuildConfiguration/Sources/**"],
            resources: [],
            dependencies: [],
            settings: .settings(
                base: [
                    "PRODUCT_BUNDLE_IDENTIFIER": "com.thetypealternative.buildconfiguration",
                    "PRODUCT_NAME": "BuildConfiguration",
                    "SKIP_INSTALL": true,
                    "ALWAYS_EMBED_SWIFT_STANDARD_LIBRARIES": false,
                    "LD_RUNPATH_SEARCH_PATHS": ["$(inherited)", "@loader_path/Frameworks"]
                ]
            )
        ),

        // FeatureFlags Framework
        .target(
            name: "FeatureFlags",
            destinations: [.mac],
            product: .framework,
            bundleId: "com.thetypealternative.featureflags",
            deploymentTargets: .macOS("26.0"),
            infoPlist: .default,
            sources: ["Modules/FeatureFlags/Sources/**"],
            resources: [],
            dependencies: [
                .target(name: "BuildConfiguration")
            ],
            settings: .settings(
                base: [
                    "PRODUCT_BUNDLE_IDENTIFIER": "com.thetypealternative.featureflags",
                    "PRODUCT_NAME": "FeatureFlags",
                    "SKIP_INSTALL": true,
                    "ALWAYS_EMBED_SWIFT_STANDARD_LIBRARIES": false,
                    "LD_RUNPATH_SEARCH_PATHS": ["$(inherited)", "@loader_path/Frameworks"]
                ]
            )
        ),

        // FullAppConfiguration Framework (DI setup)
        .target(
            name: "FullAppConfiguration",
            destinations: [.mac],
            product: .framework,
            bundleId: "com.thetypealternative.fullappconfiguration",
            deploymentTargets: .macOS("26.0"),
            infoPlist: .default,
            sources: ["Modules/FullAppConfiguration/Sources/**"],
            resources: [],
            dependencies: [
                .target(name: "AppServices"),
                .target(name: "HotkeyKit"),
                .target(name: "PermissionKit"),
                .target(name: "TextInsertionKit"),
                .target(name: "SpeechKit")
            ],
            settings: .settings(
                base: [
                    "PRODUCT_BUNDLE_IDENTIFIER": "com.thetypealternative.fullappconfiguration",
                    "PRODUCT_NAME": "FullAppConfiguration",
                    "SKIP_INSTALL": true,
                    "ALWAYS_EMBED_SWIFT_STANDARD_LIBRARIES": false,
                    "LD_RUNPATH_SEARCH_PATHS": ["$(inherited)", "@loader_path/Frameworks"]
                ]
            )
        ),

        // Shared Test Utilities Framework
        .target(
            name: "SharedTestUtilities",
            destinations: [.mac],
            product: .framework,
            bundleId: "com.thetypealternative.sharedtestutilities",
            deploymentTargets: .macOS("26.0"),
            infoPlist: .default,
            sources: ["Tests/Shared/**"],
            dependencies: [
                .target(name: "HotkeyKit"),
                .target(name: "SpeechKit"),
                .target(name: "TextInsertionKit")
            ],
            settings: .settings(
                base: [
                    "PRODUCT_BUNDLE_IDENTIFIER": "com.thetypealternative.sharedtestutilities",
                    "PRODUCT_NAME": "SharedTestUtilities",
                    "SKIP_INSTALL": true,
                    "ALWAYS_EMBED_SWIFT_STANDARD_LIBRARIES": false,
                    "LD_RUNPATH_SEARCH_PATHS": ["$(inherited)", "@loader_path/Frameworks"]
                ]
            )
        ),

        // Test Targets
        .target(
            name: "HotkeyKitTests",
            destinations: [.mac],
            product: .unitTests,
            bundleId: "com.thetypealternative.hotkeykit.tests",
            deploymentTargets: .macOS("26.0"),
            infoPlist: .default,
            sources: ["Modules/HotkeyKit/Tests/**"],
            dependencies: [
                .target(name: "HotkeyKit"),
                .target(name: "SharedTestUtilities")
            ],
        ),

        .target(
            name: "SpeechKitTests",
            destinations: [.mac],
            product: .unitTests,
            bundleId: "com.thetypealternative.speechkit.tests",
            deploymentTargets: .macOS("26.0"),
            infoPlist: .default,
            sources: ["Modules/SpeechKit/Tests/**"],
            dependencies: [
                .target(name: "SpeechKit"),
                .target(name: "SharedTestUtilities")
            ],
        ),

        .target(
            name: "TextInsertionKitTests",
            destinations: [.mac],
            product: .unitTests,
            bundleId: "com.thetypealternative.textinsertionkit.tests",
            deploymentTargets: .macOS("26.0"),
            infoPlist: .default,
            sources: ["Modules/TextInsertionKit/Tests/**"],
            dependencies: [
                .target(name: "TextInsertionKit"),
                .target(name: "SharedTestUtilities")
            ],
        ),

        .target(
            name: "PermissionKitTests",
            destinations: [.mac],
            product: .unitTests,
            bundleId: "com.thetypealternative.permissionkit.tests",
            deploymentTargets: .macOS("26.0"),
            infoPlist: .default,
            sources: ["Modules/PermissionKit/Tests/**"],
            dependencies: [
                .target(name: "PermissionKit"),
                .target(name: "SharedTestUtilities")
            ],
        ),

        // BuildConfiguration Tests
        .target(
            name: "BuildConfigurationTests",
            destinations: [.mac],
            product: .unitTests,
            bundleId: "com.thetypealternative.buildconfiguration.tests",
            deploymentTargets: .macOS("26.0"),
            infoPlist: .default,
            sources: ["Modules/BuildConfiguration/Tests/**"],
            dependencies: [
                .target(name: "BuildConfiguration"),
                .target(name: "SharedTestUtilities")
            ],
        ),

        // FeatureFlags Tests
        .target(
            name: "FeatureFlagsTests",
            destinations: [.mac],
            product: .unitTests,
            bundleId: "com.thetypealternative.featureflags.tests",
            deploymentTargets: .macOS("26.0"),
            infoPlist: .default,
            sources: ["Modules/FeatureFlags/Tests/**"],
            dependencies: [
                .target(name: "FeatureFlags"),
                .target(name: "BuildConfiguration"),
                .target(name: "SharedTestUtilities")
            ],
        ),

        // Integration Tests
        .target(
            name: "IntegrationTests",
            destinations: [.mac],
            product: .unitTests,
            bundleId: "com.thetypealternative.integration.tests",
            deploymentTargets: .macOS("26.0"),
            infoPlist: .default,
            sources: ["Tests/IntegrationTests/**"],
            dependencies: [
                .target(name: "theTypeAlternative"),
                .target(name: "HotkeyKit"),
                .target(name: "SpeechKit"),
                .target(name: "TextInsertionKit"),
                .target(name: "PermissionKit"),
                .target(name: "SharedTestUtilities")
            ],
            settings: .settings(
                base: [
                    // The app's PRODUCT_NAME (AltType) differs from its target name,
                    // so the derived TEST_HOST must be spelled out explicitly
                    "TEST_HOST": "$(BUILT_PRODUCTS_DIR)/AltType.app/Contents/MacOS/AltType",
                    "BUNDLE_LOADER": "$(TEST_HOST)"
                ]
            )
        ),

        // Performance Tests
        .target(
            name: "PerformanceTests",
            destinations: [.mac],
            product: .unitTests,
            bundleId: "com.thetypealternative.performance.tests",
            deploymentTargets: .macOS("26.0"),
            infoPlist: .default,
            sources: ["Tests/PerformanceTests/**"],
            dependencies: [
                .target(name: "theTypeAlternative"),
                .target(name: "HotkeyKit"),
                .target(name: "SpeechKit"),
                .target(name: "TextInsertionKit"),
                .target(name: "PermissionKit"),
                .target(name: "SharedTestUtilities")
            ],
            settings: .settings(
                base: [
                    "TEST_HOST": "$(BUILT_PRODUCTS_DIR)/AltType.app/Contents/MacOS/AltType",
                    "BUNDLE_LOADER": "$(TEST_HOST)"
                ]
            )
        ),

        // End-to-End Tests
        .target(
            name: "theTypeAlternativeTests",
            destinations: [.mac],
            product: .unitTests,
            bundleId: "com.thetypealternative.app.tests",
            deploymentTargets: .macOS("26.0"),
            infoPlist: .default,
            sources: ["Tests/theTypeAlternativeTests/**"],
            dependencies: [
                .target(name: "AppServices"),
                .target(name: "FullAppConfiguration"),
                .target(name: "HotkeyKit"),
                .target(name: "PermissionKit"),
                .target(name: "TextInsertionKit"),
                .target(name: "SpeechKit"),
                .target(name: "SharedTestUtilities")
            ],
        )
    ],
    schemes: [
        // Single scheme, standard Xcode convention:
        // Run/Test use Debug; Profile/Archive use Release
        .scheme(
            name: "theTypeAlternative",
            shared: true,
            buildAction: .buildAction(
                targets: ["theTypeAlternative"]
            ),
            testAction: .targets(
                [
                    "theTypeAlternativeTests",
                    "HotkeyKitTests",
                    "SpeechKitTests",
                    "TextInsertionKitTests",
                    "PermissionKitTests",
                    "BuildConfigurationTests",
                    "FeatureFlagsTests",
                    "IntegrationTests",
                    "PerformanceTests"
                ]
            ),
            runAction: .runAction(
                configuration: .debug,
                executable: "theTypeAlternative"
            ),
            archiveAction: .archiveAction(
                configuration: .release
            ),
            profileAction: .profileAction(
                configuration: .release,
                executable: "theTypeAlternative"
            )
        )
    ]
)
