# Comprehensive Testing Strategy for theTypeAlternative

## Project Overview

**theTypeAlternative** is a modular Swift/SwiftUI macOS application providing system-wide voice-to-text transcription. This document outlines a comprehensive testing strategy using modern Swift 6.0+ practices and the latest testing frameworks for 2024.

## Table of Contents

1. [Testing Framework Strategy](#testing-framework-strategy)
2. [Project Architecture](#project-architecture)
3. [Testing Pyramid Implementation](#testing-pyramid-implementation)
4. [Module-Specific Testing Plans](#module-specific-testing-plans)
5. [Integration Testing Strategy](#integration-testing-strategy)
6. [UI Testing for macOS/iOS Compatibility](#ui-testing-for-macosios-compatibility)
7. [Performance Testing](#performance-testing)
8. [Test Infrastructure Setup](#test-infrastructure-setup)
9. [CI/CD Integration](#cicd-integration)
10. [Migration Path](#migration-path)
11. [500+ Testing Scenarios](#500-testing-scenarios)

## Testing Framework Strategy

### Primary Framework: Swift Testing (2024)

**Language**: Swift 6.0+
**Framework**: Swift Testing (Apple's new open-source testing framework)
**Tools**: Xcode 16+, Tuist, Swift Package Manager

**Why Swift Testing?**
- Modern Swift-first design with macro support
- Better concurrency and async/await integration
- Cross-platform compatibility (macOS, iOS, watchOS, tvOS)
- Expressive API with enhanced error reporting
- Built-in parameterized testing support

### Secondary Framework: XCTest (Legacy Support)

**Framework**: XCTest
**Purpose**: Maintain existing tests during migration
**Timeline**: Gradual migration to Swift Testing

## Project Architecture

### Current Module Structure
```
theTypeAlternative/
├── theTypeAlternative/          # Main app target
├── Modules/
│   ├── HotkeyKit/              # Global hotkey management
│   ├── SpeechKit/              # Speech recognition
│   ├── TextInsertionKit/       # Text insertion via Accessibility API
│   └── PermissionKit/          # Permission management
└── Tests/                      # Test implementations
```

### Testing Architecture
```
Tests/
├── Unit/                       # 70% - Fast, isolated tests
│   ├── HotkeyKitTests/
│   ├── SpeechKitTests/
│   ├── TextInsertionKitTests/
│   └── PermissionKitTests/
├── Integration/                # 20% - Module interaction tests
│   ├── HotkeySpeechIntegration/
│   ├── SpeechTextIntegration/
│   └── PermissionFlowIntegration/
├── UI/                        # 10% - End-to-end tests
│   ├── OnboardingFlow/
│   ├── SettingsWindow/
│   └── MenuBarInteraction/
├── Performance/               # Performance benchmarks
└── Shared/                   # Test utilities and mocks
```

## Testing Pyramid Implementation

### Unit Tests (70% of test suite)

**Characteristics:**
- Fast execution (< 100ms per test)
- No external dependencies
- High code coverage
- Isolated component testing

**Technologies:**
- Swift Testing framework
- Mock objects and dependency injection
- Property-based testing where applicable

### Integration Tests (20% of test suite)

**Characteristics:**
- Test module interactions
- Verify data flow between components
- Test permission dependencies
- Moderate execution time (< 1s per test)

### UI Tests (10% of test suite)

**Characteristics:**
- End-to-end workflow validation
- User journey testing
- Accessibility compliance
- Cross-platform UI component testing

## Module-Specific Testing Plans

### 1. HotkeyKit Module Testing

**File**: `Modules/HotkeyKit/Tests/HotkeyKitTests.swift`
**Language**: Swift 6.0
**Framework**: Swift Testing

#### Key Testing Areas:
- Event tap lifecycle management
- Key code mapping accuracy
- Hotkey state transitions
- Global event handling
- Memory management for event taps

#### Implementation Example:

```swift
import Testing
@testable import HotkeyKit

@Suite("HotkeyKit Core Functionality")
struct HotkeyKitTests {
    
    @Test("Key code mapping validation")
    func keyCodeMappingAccuracy() {
        #expect(KeyCodeMapping.displayName(for: .functionKey) == "fn")
        #expect(KeyCodeMapping.displayName(for: .leftCommand) == "⌘")
        #expect(KeyCodeMapping.displayName(for: .leftOption) == "⌥")
        #expect(KeyCodeMapping.isModifierKey(.leftCommand) == true)
        #expect(KeyCodeMapping.isModifierKey(.space) == false)
    }
    
    @Test("Hotkey state transitions", arguments: [
        (HotkeyEvent.none, false),
        (HotkeyEvent.pressed(Date()), true),
        (HotkeyEvent.released(Date()), false)
    ])
    func hotkeyStateTransitions(event: HotkeyEvent, expectedPressed: Bool) {
        let state = HotkeyState(isPressed: expectedPressed, lastEvent: event)
        #expect(state.isPressed == expectedPressed)
        #expect(state.lastEvent == event)
    }
    
    @Test("Event tap lifecycle")
    func eventTapLifecycle() async throws {
        let manager = HotkeyManager()
        
        // Test setup without throwing
        #expect(throws: Never.self) {
            try manager.setupEventTap()
        }
        
        // Verify tap is active
        #expect(manager.isEventTapActive == true)
        
        // Test teardown
        manager.teardownEventTap()
        #expect(manager.isEventTapActive == false)
    }
    
    @Test("Memory management during rapid events")
    func memoryManagementDuringEvents() async {
        let manager = HotkeyManager()
        let initialMemory = getCurrentMemoryUsage()
        
        // Simulate rapid hotkey events
        for _ in 0..<1000 {
            manager.handleKeyEvent(.pressed(Date()))
            manager.handleKeyEvent(.released(Date()))
        }
        
        let finalMemory = getCurrentMemoryUsage()
        let memoryIncrease = finalMemory - initialMemory
        
        // Memory increase should be minimal
        #expect(memoryIncrease < 1_000_000) // Less than 1MB
    }
}
```

### 2. SpeechKit Module Testing

**File**: `Modules/SpeechKit/Tests/SpeechKitTests.swift`
**Language**: Swift 6.0
**Framework**: Swift Testing

#### Key Testing Areas:
- Speech recognition accuracy
- Audio level monitoring
- Permission handling
- Error recovery
- Performance optimization

#### Implementation Example:

```swift
import Testing
import Speech
import AVFoundation
@testable import SpeechKit

@Suite("SpeechKit Recognition")
struct SpeechKitTests {
    
    @Test("Speech recognizer configuration")
    func recognizerConfiguration() async throws {
        let recognizer = SpeechRecognizer()
        #expect(recognizer != nil)
        
        // Test on-device recognition preference
        if #available(macOS 13, *) {
            #expect(recognizer.prefersOnDeviceRecognition == true)
        }
    }
    
    @Test("Audio level monitoring precision")
    func audioLevelMonitoring() async throws {
        let monitor = AudioLevelMonitor()
        #expect(monitor.audioLevel == 0.0)
        #expect(monitor.isSilent == true)
        
        // Simulate audio input
        await monitor.simulateAudioInput(level: 0.5)
        #expect(monitor.audioLevel == 0.5)
        #expect(monitor.isSilent == false)
        
        // Test silence detection
        await monitor.simulateAudioInput(level: 0.01)
        #expect(monitor.isSilent == true)
    }
    
    @Test("Speech recognition delegate communication")
    func delegateCommunication() async throws {
        let recognizer = SpeechRecognizer()
        let mockDelegate = MockSpeechRecognizerDelegate()
        recognizer.delegate = mockDelegate
        
        // Simulate recognition result
        await recognizer.simulateRecognitionResult(
            text: "Hello world",
            isFinal: false,
            confidence: 0.95
        )
        
        #expect(mockDelegate.lastRecognizedText == "Hello world")
        #expect(mockDelegate.lastConfidence == 0.95)
        #expect(mockDelegate.lastIsFinal == false)
    }
    
    @Test("Error handling scenarios", arguments: [
        SpeechRecognitionError.microphonePermissionDenied,
        SpeechRecognitionError.speechRecognitionDenied,
        SpeechRecognitionError.networkUnavailable,
        SpeechRecognitionError.speechRecognitionTimeout
    ])
    func errorHandlingScenarios(error: SpeechRecognitionError) async throws {
        let recognizer = SpeechRecognizer()
        let mockDelegate = MockSpeechRecognizerDelegate()
        recognizer.delegate = mockDelegate
        
        await recognizer.simulateError(error)
        
        #expect(mockDelegate.lastError != nil)
        #expect(mockDelegate.lastError as? SpeechRecognitionError == error)
    }
    
    @Test("Recognition performance benchmarks")
    func recognitionPerformanceBenchmarks() async throws {
        let recognizer = SpeechRecognizer()
        let startTime = Date()
        
        // Measure startup time
        try await recognizer.startRecording()
        let startupTime = Date().timeIntervalSince(startTime)
        
        #expect(startupTime < 0.5) // Less than 500ms startup
        
        recognizer.stopRecording()
    }
}
```

### 3. TextInsertionKit Module Testing

**File**: `Modules/TextInsertionKit/Tests/TextInsertionKitTests.swift`
**Language**: Swift 6.0
**Framework**: Swift Testing

#### Key Testing Areas:
- Accessibility API integration
- Clipboard fallback mechanism
- Text replacement and refinement
- Multi-application compatibility
- Contextual indicator positioning

#### Implementation Example:

```swift
import Testing
import ApplicationServices
@testable import TextInsertionKit

@Suite("TextInsertionKit Functionality")
struct TextInsertionKitTests {
    
    @Test("Text insertion strategy selection")
    func textInsertionStrategySelection() async throws {
        let inserter = TextInserter()
        
        // Mock focused element with accessibility support
        let mockElement = MockAXUIElement(supportsAccessibility: true)
        let strategy = await inserter.determineInsertionStrategy(for: mockElement)
        
        #expect(strategy == .accessibility)
        
        // Mock element without accessibility support
        let incompatibleElement = MockAXUIElement(supportsAccessibility: false)
        let fallbackStrategy = await inserter.determineInsertionStrategy(for: incompatibleElement)
        
        #expect(fallbackStrategy == .clipboard)
    }
    
    @Test("Progressive text refinement")
    func progressiveTextRefinement() async throws {
        let inserter = TextInserter()
        let mockElement = MockAXUIElement(supportsAccessibility: true)
        
        // Insert initial text
        await inserter.insertText("Hello", isFinal: false, element: mockElement)
        #expect(inserter.currentText == "Hello")
        
        // Refine text
        await inserter.insertText("Hello world", isFinal: false, element: mockElement)
        #expect(inserter.currentText == "Hello world")
        
        // Finalize text
        await inserter.insertText("Hello world!", isFinal: true, element: mockElement)
        #expect(inserter.currentText == "Hello world!")
        #expect(inserter.isTextFinalized == true)
    }
    
    @Test("Contextual indicator positioning")
    func contextualIndicatorPositioning() async throws {
        let indicator = ContextualIndicator()
        let mockElement = MockAXUIElement(frame: CGRect(x: 100, y: 200, width: 300, height: 20))
        
        await indicator.positionNear(element: mockElement)
        
        let indicatorFrame = indicator.frame
        #expect(indicatorFrame.minX >= mockElement.frame.minX)
        #expect(indicatorFrame.maxX <= mockElement.frame.maxX)
        #expect(indicatorFrame.minY >= mockElement.frame.maxY)
    }
    
    @Test("Multi-application compatibility", arguments: [
        "com.apple.TextEdit",
        "com.microsoft.Word",
        "com.apple.dt.Xcode",
        "com.google.Chrome",
        "com.apple.Safari"
    ])
    func multiApplicationCompatibility(bundleIdentifier: String) async throws {
        let inserter = TextInserter()
        let compatibility = await inserter.checkCompatibility(for: bundleIdentifier)
        
        // All tested applications should support at least clipboard insertion
        #expect(compatibility.supportsClipboard == true)
        
        // Some applications should support accessibility API
        if bundleIdentifier == "com.apple.TextEdit" || bundleIdentifier == "com.apple.dt.Xcode" {
            #expect(compatibility.supportsAccessibility == true)
        }
    }
}
```

### 4. PermissionKit Module Testing

**File**: `Modules/PermissionKit/Tests/PermissionKitTests.swift`
**Language**: Swift 6.0
**Framework**: Swift Testing

#### Key Testing Areas:
- Permission request flows
- Permission state management
- Error handling and recovery
- User guidance and messaging

#### Implementation Example:

```swift
import Testing
@testable import PermissionKit

@Suite("PermissionKit Management")
struct PermissionKitTests {
    
    @Test("Permission state detection")
    func permissionStateDetection() async throws {
        let manager = PermissionManager()
        
        let microphoneState = await manager.checkMicrophonePermission()
        let accessibilityState = await manager.checkAccessibilityPermission()
        
        #expect([.granted, .denied, .notDetermined].contains(microphoneState))
        #expect([.granted, .denied, .notDetermined].contains(accessibilityState))
    }
    
    @Test("Permission request flow")
    func permissionRequestFlow() async throws {
        let manager = PermissionManager()
        let delegate = MockPermissionDelegate()
        manager.delegate = delegate
        
        await manager.requestMicrophonePermission()
        
        #expect(delegate.requestedPermissions.contains(.microphone))
        #expect(delegate.lastRequestResult != nil)
    }
    
    @Test("Permission dependency validation")
    func permissionDependencyValidation() async throws {
        let manager = PermissionManager()
        
        // Test that app functionality depends on both permissions
        let isFullyAuthorized = await manager.hasAllRequiredPermissions()
        let microphoneGranted = await manager.checkMicrophonePermission() == .granted
        let accessibilityGranted = await manager.checkAccessibilityPermission() == .granted
        
        #expect(isFullyAuthorized == (microphoneGranted && accessibilityGranted))
    }
    
    @Test("Permission recovery scenarios")
    func permissionRecoveryScenarios() async throws {
        let manager = PermissionManager()
        
        // Test recovery from denied state
        await manager.simulatePermissionDenied(.microphone)
        let recoveryGuidance = await manager.getRecoveryGuidance(for: .microphone)
        
        #expect(recoveryGuidance.shouldShowSystemPreferences == true)
        #expect(recoveryGuidance.userFriendlyMessage.contains("System Preferences"))
    }
}
```

## Integration Testing Strategy

### Cross-Module Integration Tests

**File**: `Tests/Integration/ModuleIntegrationTests.swift`
**Language**: Swift 6.0
**Framework**: Swift Testing

```swift
import Testing
@testable import HotkeyKit
@testable import SpeechKit
@testable import TextInsertionKit
@testable import PermissionKit

@Suite("Module Integration Tests")
struct ModuleIntegrationTests {
    
    @Test("Hotkey to Speech Pipeline")
    func hotkeyToSpeechPipeline() async throws {
        let hotkeyManager = HotkeyManager()
        let speechRecognizer = SpeechRecognizer()
        let mockDelegate = MockSpeechActionDelegate()
        
        hotkeyManager.speechDelegate = mockDelegate
        
        // Simulate hotkey press
        await hotkeyManager.handleHotkeyPress()
        
        #expect(mockDelegate.startRecordingCalled == true)
        #expect(speechRecognizer.isRecording == true)
        
        // Simulate hotkey release
        await hotkeyManager.handleHotkeyRelease()
        
        #expect(mockDelegate.stopRecordingCalled == true)
        #expect(speechRecognizer.isRecording == false)
    }
    
    @Test("Speech to Text Insertion Pipeline")
    func speechToTextInsertionPipeline() async throws {
        let speechRecognizer = SpeechRecognizer()
        let textInserter = TextInserter()
        let coordinator = SpeechTextCoordinator()
        
        coordinator.speechRecognizer = speechRecognizer
        coordinator.textInserter = textInserter
        
        // Simulate speech recognition result
        await speechRecognizer.simulateRecognitionResult(
            text: "Hello world",
            isFinal: false,
            confidence: 0.9
        )
        
        #expect(textInserter.currentText == "Hello world")
        #expect(textInserter.isTextFinalized == false)
        
        // Simulate final result
        await speechRecognizer.simulateRecognitionResult(
            text: "Hello world!",
            isFinal: true,
            confidence: 0.95
        )
        
        #expect(textInserter.currentText == "Hello world!")
        #expect(textInserter.isTextFinalized == true)
    }
    
    @Test("Permission dependency flow")
    func permissionDependencyFlow() async throws {
        let permissionManager = PermissionManager()
        let speechRecognizer = SpeechRecognizer()
        let textInserter = TextInserter()
        
        // Test that speech recognition requires microphone permission
        let canStartRecognition = await speechRecognizer.canStartRecording()
        let microphoneGranted = await permissionManager.checkMicrophonePermission() == .granted
        
        #expect(canStartRecognition == microphoneGranted)
        
        // Test that text insertion requires accessibility permission
        let canInsertText = await textInserter.canInsertText()
        let accessibilityGranted = await permissionManager.checkAccessibilityPermission() == .granted
        
        #expect(canInsertText == accessibilityGranted)
    }
    
    @Test("End-to-end workflow simulation")
    func endToEndWorkflowSimulation() async throws {
        let appCoordinator = AppCoordinator()
        
        // Setup all components
        await appCoordinator.initializeAllModules()
        
        // Verify all modules are properly connected
        #expect(appCoordinator.hotkeyManager != nil)
        #expect(appCoordinator.speechRecognizer != nil)
        #expect(appCoordinator.textInserter != nil)
        #expect(appCoordinator.permissionManager != nil)
        
        // Test complete workflow
        await appCoordinator.simulateUserDictation(text: "Testing complete workflow")
        
        #expect(appCoordinator.lastTranscribedText == "Testing complete workflow")
        #expect(appCoordinator.lastInsertionSuccessful == true)
    }
}
```

## UI Testing for macOS/iOS Compatibility

### UI Test Implementation

**File**: `Tests/UI/UIWorkflowTests.swift`
**Language**: Swift 6.0
**Framework**: Swift Testing + XCTest UI Testing

```swift
import Testing
import XCTest

@Suite("UI Workflow Tests")
struct UIWorkflowTests {
    
    @Test("Onboarding flow completion")
    func onboardingFlowCompletion() async throws {
        let app = XCUIApplication()
        app.launch()
        
        // Test permission request screens
        let microphonePermissionButton = app.buttons["Grant Microphone Access"]
        #expect(microphonePermissionButton.exists)
        
        microphonePermissionButton.tap()
        
        // Wait for system permission dialog
        let systemDialog = app.dialogs.firstMatch
        if systemDialog.waitForExistence(timeout: 5) {
            systemDialog.buttons["OK"].tap()
        }
        
        // Test accessibility permission
        let accessibilityPermissionButton = app.buttons["Grant Accessibility Access"]
        #expect(accessibilityPermissionButton.exists)
        
        accessibilityPermissionButton.tap()
        
        // Verify completion
        let completeButton = app.buttons["Complete Setup"]
        #expect(completeButton.waitForExistence(timeout: 10))
    }
    
    @Test("Settings window functionality")
    func settingsWindowFunctionality() async throws {
        let app = XCUIApplication()
        app.launch()
        
        // Open settings
        app.menuBars.menuItems["Preferences"].click()
        
        let settingsWindow = app.windows["Settings"]
        #expect(settingsWindow.exists)
        
        // Test hotkey configuration
        let hotkeyField = settingsWindow.textFields["Hotkey Configuration"]
        #expect(hotkeyField.exists)
        
        hotkeyField.click()
        hotkeyField.typeKey("space", modifierFlags: [.option])
        
        // Verify hotkey was set
        #expect(hotkeyField.value as? String == "⌥Space")
        
        // Test settings persistence
        settingsWindow.buttons["Save"].click()
        
        // Reopen settings and verify persistence
        app.menuBars.menuItems["Preferences"].click()
        #expect(hotkeyField.value as? String == "⌥Space")
    }
    
    @Test("Menu bar interaction")
    func menuBarInteraction() async throws {
        let app = XCUIApplication()
        app.launch()
        
        // Find menu bar item
        let menuBar = app.menuBars.firstMatch
        let statusItem = menuBar.menuBarItems["AltType"]
        #expect(statusItem.exists)
        
        // Test menu item click
        statusItem.click()
        
        let menu = app.menus.firstMatch
        #expect(menu.exists)
        
        // Verify menu items
        #expect(menu.menuItems["Start Dictation"].exists)
        #expect(menu.menuItems["Settings"].exists)
        #expect(menu.menuItems["Quit"].exists)
        
        // Test start dictation
        menu.menuItems["Start Dictation"].click()
        
        // Verify dictation starts (status item should change)
        #expect(statusItem.title.contains("Recording") || statusItem.images.count > 0)
    }
    
    // Future iOS compatibility test
    @Test("Cross-platform UI components", .enabled(if: ProcessInfo.processInfo.environment["TESTING_IOS"] != nil))
    func crossPlatformUIComponents() async throws {
        #if os(iOS)
        let app = XCUIApplication()
        app.launch()
        
        // Test SwiftUI components adapt to iOS
        let settingsButton = app.buttons["Settings"]
        #expect(settingsButton.exists)
        
        settingsButton.tap()
        
        // Verify iOS-specific navigation
        let navigationBar = app.navigationBars.firstMatch
        #expect(navigationBar.exists)
        
        let backButton = navigationBar.buttons["Back"]
        #expect(backButton.exists)
        #endif
    }
}
```

## Performance Testing

### Performance Benchmarks

**File**: `Tests/Performance/PerformanceTests.swift`
**Language**: Swift 6.0
**Framework**: Swift Testing

```swift
import Testing
@testable import SpeechKit
@testable import TextInsertionKit
@testable import HotkeyKit

@Suite("Performance Tests")
struct PerformanceTests {
    
    @Test("Speech recognition latency")
    func speechRecognitionLatency() async throws {
        let recognizer = SpeechRecognizer()
        
        let startTime = Date()
        try await recognizer.startRecording()
        let startupLatency = Date().timeIntervalSince(startTime)
        
        #expect(startupLatency < 0.5) // Less than 500ms
        
        recognizer.stopRecording()
    }
    
    @Test("Text insertion performance")
    func textInsertionPerformance() async throws {
        let inserter = TextInserter()
        let largeText = String(repeating: "Hello world! ", count: 1000)
        
        let startTime = Date()
        await inserter.insertText(largeText, isFinal: true)
        let insertionTime = Date().timeIntervalSince(startTime)
        
        #expect(insertionTime < 1.0) // Less than 1 second for large text
    }
    
    @Test("Memory usage during extended operation")
    func memoryUsageDuringExtendedOperation() async throws {
        let coordinator = AppCoordinator()
        await coordinator.initializeAllModules()
        
        let initialMemory = getCurrentMemoryUsage()
        
        // Simulate 1 hour of usage
        for _ in 0..<3600 {
            await coordinator.simulateOneSecondOfUsage()
        }
        
        let finalMemory = getCurrentMemoryUsage()
        let memoryIncrease = finalMemory - initialMemory
        
        // Memory should not increase significantly
        #expect(memoryIncrease < 50_000_000) // Less than 50MB over 1 hour
    }
    
    @Test("Concurrent operation performance")
    func concurrentOperationPerformance() async throws {
        let recognizer = SpeechRecognizer()
        let inserter = TextInserter()
        
        let startTime = Date()
        
        // Test concurrent operations
        async let recognition = recognizer.performRecognition()
        async let insertion = inserter.performInsertion("Test text")
        
        let _ = try await (recognition, insertion)
        let totalTime = Date().timeIntervalSince(startTime)
        
        #expect(totalTime < 2.0) // Concurrent operations should complete quickly
    }
}
```

## Test Infrastructure Setup

### Shared Test Utilities

**File**: `Tests/Shared/TestUtilities.swift`
**Language**: Swift 6.0

```swift
import Foundation
@testable import HotkeyKit
@testable import SpeechKit
@testable import TextInsertionKit
@testable import PermissionKit

// MARK: - Mock Objects

class MockSpeechRecognizerDelegate: SpeechRecognizerDelegate {
    var lastRecognizedText: String = ""
    var lastConfidence: Double = 0.0
    var lastIsFinal: Bool = false
    var lastError: Error?
    
    func speechRecognizer(_ recognizer: SpeechRecognizer, didRecognizeText text: String, isFinal: Bool, confidence: Double) {
        lastRecognizedText = text
        lastIsFinal = isFinal
        lastConfidence = confidence
    }
    
    func speechRecognizer(_ recognizer: SpeechRecognizer, didFailWithError error: Error) {
        lastError = error
    }
}

class MockSpeechActionDelegate: SpeechActionDelegate {
    var startRecordingCalled = false
    var stopRecordingCalled = false
    
    func startSpeechRecording() {
        startRecordingCalled = true
    }
    
    func stopSpeechRecording() {
        stopRecordingCalled = true
    }
}

class MockPermissionDelegate: PermissionDelegate {
    var requestedPermissions: Set<PermissionType> = []
    var lastRequestResult: PermissionResult?
    
    func permissionRequested(_ permission: PermissionType, result: PermissionResult) {
        requestedPermissions.insert(permission)
        lastRequestResult = result
    }
}

class MockAXUIElement {
    let supportsAccessibility: Bool
    let frame: CGRect
    
    init(supportsAccessibility: Bool = true, frame: CGRect = .zero) {
        self.supportsAccessibility = supportsAccessibility
        self.frame = frame
    }
}

// MARK: - Test Helpers

func getCurrentMemoryUsage() -> Int64 {
    var info = mach_task_basic_info()
    var count = mach_msg_type_number_t(MemoryLayout<mach_task_basic_info>.size)/4
    
    let kerr: kern_return_t = withUnsafeMutablePointer(to: &info) {
        $0.withMemoryRebound(to: integer_t.self, capacity: 1) {
            task_info(mach_task_self_,
                     task_flavor_t(MACH_TASK_BASIC_INFO),
                     $0,
                     &count)
        }
    }
    
    return kerr == KERN_SUCCESS ? Int64(info.resident_size) : 0
}

extension SpeechRecognizer {
    func simulateRecognitionResult(text: String, isFinal: Bool, confidence: Double) async {
        await MainActor.run {
            self.delegate?.speechRecognizer(self, didRecognizeText: text, isFinal: isFinal, confidence: confidence)
        }
    }
    
    func simulateError(_ error: Error) async {
        await MainActor.run {
            self.delegate?.speechRecognizer(self, didFailWithError: error)
        }
    }
}

extension AudioLevelMonitor {
    func simulateAudioInput(level: Float) async {
        await MainActor.run {
            self.audioLevel = level
        }
    }
}

// MARK: - Test Configuration

enum TestConfiguration {
    static let defaultTimeout: TimeInterval = 5.0
    static let performanceTimeout: TimeInterval = 10.0
    static let maxMemoryIncrease: Int64 = 10_000_000 // 10MB
    static let maxLatency: TimeInterval = 0.5 // 500ms
}
```

### Project Configuration for Testing

**File**: `Project.swift` (Updated sections)

```swift
// Add Swift Testing dependency
packages: [
    .remote(url: "https://github.com/swiftlang/swift-testing.git", requirement: .upToNextMajor(from: "0.1.0"))
],

// Add shared test utilities target
.target(
    name: "SharedTestUtilities",
    destinations: [.mac],
    product: .framework,
    bundleId: "com.thetypealternative.sharedtestutilities",
    sources: ["Tests/Shared/**"],
    dependencies: [
        .package(product: "Testing", type: .runtime),
        .target(name: "HotkeyKit"),
        .target(name: "SpeechKit"),
        .target(name: "TextInsertionKit"),
        .target(name: "PermissionKit")
    ]
),

// Update test targets to use Swift Testing
.target(
    name: "HotkeyKitTests",
    destinations: [.mac],
    product: .unitTests,
    bundleId: "com.thetypealternative.hotkeykit.tests",
    sources: ["Modules/HotkeyKit/Tests/**"],
    dependencies: [
        .target(name: "HotkeyKit"),
        .target(name: "SharedTestUtilities"),
        .package(product: "Testing", type: .runtime)
    ]
)
```

## CI/CD Integration

### GitHub Actions Workflow

**File**: `.github/workflows/test.yml`
**Language**: YAML

```yaml
name: Test Suite

on:
  push:
    branches: [ main, develop ]
  pull_request:
    branches: [ main ]

jobs:
  test:
    runs-on: macos-14
    
    steps:
    - uses: actions/checkout@v4
    
    - name: Setup Xcode
      uses: maxim-lobanov/setup-xcode@v1
      with:
        xcode-version: '16.0'
    
    - name: Install Tuist
      run: |
        brew install tuist
    
    - name: Generate project
      run: |
        tuist generate
    
    - name: Run unit tests
      run: |
        tuist test
        
    - name: Run performance tests
      run: |
        tuist test --configuration Release
        
    - name: Generate test coverage
      run: |
        tuist test --enable-code-coverage
        
    - name: Upload coverage to Codecov
      uses: codecov/codecov-action@v3
      with:
        file: ./coverage.lcov
        
  integration-test:
    runs-on: macos-14
    needs: test
    
    steps:
    - uses: actions/checkout@v4
    
    - name: Setup Xcode
      uses: maxim-lobanov/setup-xcode@v1
      with:
        xcode-version: '16.0'
        
    - name: Run integration tests
      run: |
        tuist test --scheme IntegrationTests
        
  ui-test:
    runs-on: macos-14
    needs: test
    
    steps:
    - uses: actions/checkout@v4
    
    - name: Setup Xcode
      uses: maxim-lobanov/setup-xcode@v1
      with:
        xcode-version: '16.0'
        
    - name: Run UI tests
      run: |
        tuist test --scheme UITests
```

### Local Testing Commands

**Add to CLAUDE.md**:

```bash
# Unit testing (all modules)
tuist test

# Specific module testing
tuist test HotkeyKitTests
tuist test SpeechKitTests
tuist test TextInsertionKitTests
tuist test PermissionKitTests

# Integration testing
tuist test IntegrationTests

# UI testing
tuist test UITests

# Performance testing
tuist test --configuration Release PerformanceTests

# Test with coverage
tuist test --enable-code-coverage

# Continuous testing (watch mode)
tuist test --watch

# Generate test report
tuist test --result-bundle-path TestResults.xcresult
```

## Migration Path

### Phase 1: Infrastructure Setup (Week 1-2)

**Tasks:**
1. Add Swift Testing framework to project
2. Create shared test utilities
3. Setup CI/CD pipeline
4. Create basic test structure

**Tools needed:**
- Xcode 16+
- Swift Testing package
- Tuist
- GitHub Actions

### Phase 2: Unit Test Implementation (Week 3-6)

**Tasks:**
1. Implement HotkeyKit tests
2. Implement SpeechKit tests  
3. Implement TextInsertionKit tests
4. Implement PermissionKit tests

**Focus:**
- Achieve 80%+ code coverage
- Test all public APIs
- Include error scenarios

### Phase 3: Integration Testing (Week 7-8)

**Tasks:**
1. Cross-module integration tests
2. Permission flow tests
3. End-to-end workflow tests

### Phase 4: UI Testing (Week 9-10)

**Tasks:**
1. Onboarding flow tests
2. Settings window tests
3. Menu bar interaction tests
4. iOS compatibility preparation

### Phase 5: Performance & Optimization (Week 11-12)

**Tasks:**
1. Performance benchmarks
2. Memory usage tests
3. Concurrency tests
4. Optimization based on results

## 500+ Testing Scenarios

### Core Functionality Tests (100 scenarios)

#### HotkeyKit Tests (25 scenarios)
1. Test default hotkey combination (fn)
2. Test custom hotkey combinations (Option + space)
3. Test modifier key detection (Command, Option, Control, Shift)
4. Test function key detection
5. Test special keys (Space, Return, Escape)
6. Test key code mapping accuracy for all supported keys
7. Test hotkey state transitions (none → pressed → released)
8. Test rapid hotkey presses
9. Test simultaneous modifier keys
10. Test hotkey conflicts with system shortcuts
11. Test event tap creation and destruction
12. Test event tap permissions
13. Test event tap re-creation after system sleep
14. Test hotkey recognition in different applications
15. Test hotkey recognition during fullscreen mode
16. Test memory management during event processing
17. Test CPU usage during continuous key monitoring
18. Test hotkey recognition accuracy under high system load
19. Test invalid key combinations handling
20. Test hotkey persistence across app restarts
21. Test hotkey configuration validation
22. Test accessibility compliance for hotkey selection
23. Test hotkey conflicts with accessibility tools
24. Test carbon event handling
25. Test global event monitoring edge cases

#### SpeechKit Tests (25 scenarios)
26. Test speech recognizer initialization
27. Test on-device recognition preference
28. Test locale-specific recognition (US English)
29. Test speech recognition accuracy with clear speech
30. Test speech recognition accuracy with background noise
31. Test speech recognition with different microphone types
32. Test speech recognition timeout handling
33. Test partial vs final recognition results
34. Test confidence score accuracy
35. Test speech recognition error recovery
36. Test microphone permission handling
37. Test audio engine configuration
38. Test audio level monitoring
39. Test silence detection
40. Test audio level calibration
41. Test continuous speech recognition
42. Test speech recognition interruption handling
43. Test multiple microphone support
44. Test speech recognition in different languages
45. Test speech recognition with accents
46. Test speech recognition with medical terminology
47. Test speech recognition with technical jargon
48. Test speech recognition with numbers and dates
49. Test speech recognition with punctuation
50. Test audio quality assessment

#### TextInsertionKit Tests (25 scenarios)
51. Test text insertion via Accessibility API
52. Test clipboard fallback mechanism
53. Test text replacement and refinement
54. Test progressive text updates
55. Test final text confirmation
56. Test insertion in different text fields
57. Test insertion in rich text editors
58. Test insertion in web browsers
59. Test insertion in terminal applications
60. Test insertion in password fields
61. Test contextual indicator positioning
62. Test multi-line text insertion
63. Test Unicode text insertion
64. Test emoji insertion
65. Test special character insertion
66. Test text insertion with formatting
67. Test insertion cursor positioning
68. Test text selection before insertion
69. Test insertion in read-only fields
70. Test insertion with undo/redo support
71. Test accessibility API compatibility
72. Test text insertion performance
73. Test concurrent text insertion requests
74. Test text insertion error recovery
75. Test insertion in different coordinate systems

#### PermissionKit Tests (25 scenarios)
76. Test microphone permission detection
77. Test accessibility permission detection
78. Test speech recognition permission detection
79. Test permission request flow
80. Test permission denial handling
81. Test permission recovery guidance
82. Test system preferences integration
83. Test permission status monitoring
84. Test permission change notifications
85. Test batch permission requests
86. Test permission caching
87. Test permission timeout handling
88. Test sandboxed environment permissions
89. Test enterprise policy permissions
90. Test parental control permissions
91. Test guest user permissions
92. Test admin user permissions
93. Test permission documentation
94. Test permission error messages
95. Test permission onboarding flow
96. Test permission debugging tools
97. Test permission analytics
98. Test permission fallback modes
99. Test permission compatibility checks
100. Test permission security validation

### Integration Tests (100 scenarios)

#### Module Communication (25 scenarios)
101. Test hotkey activation triggers speech recognition
102. Test speech results trigger text insertion
103. Test permission dependencies between modules
104. Test error propagation between modules
105. Test state synchronization across modules
106. Test concurrent module operations
107. Test module initialization order
108. Test module cleanup and teardown
109. Test module configuration sharing
110. Test module event broadcasting
111. Test cross-module memory management
112. Test cross-module error handling
113. Test module lifecycle management
114. Test module dependency injection
115. Test module interface contracts
116. Test module version compatibility
117. Test module update handling
118. Test module feature flags
119. Test module debugging integration
120. Test module performance monitoring
121. Test module crash recovery
122. Test module data persistence
123. Test module background/foreground transitions
124. Test module resource sharing
125. Test module security boundaries

#### Workflow Integration (25 scenarios)
126. Test complete dictation workflow
127. Test workflow interruption and resumption
128. Test workflow error recovery
129. Test workflow performance optimization
130. Test workflow state persistence
131. Test workflow cancellation
132. Test workflow timeout handling
133. Test workflow retry mechanisms
134. Test workflow progress tracking
135. Test workflow user feedback
136. Test workflow customization
137. Test workflow keyboard shortcuts
138. Test workflow menu integration
139. Test workflow dock integration
140. Test workflow notification integration
141. Test workflow clipboard integration
142. Test workflow undo/redo support
143. Test workflow batch operations
144. Test workflow scheduling
145. Test workflow automation
146. Test workflow logging
147. Test workflow analytics
148. Test workflow accessibility
149. Test workflow internationalization
150. Test workflow security compliance

#### Data Flow Integration (25 scenarios)
151. Test audio data flow from microphone to recognizer
152. Test recognition data flow from recognizer to text inserter
153. Test configuration data flow between modules
154. Test error data flow and aggregation
155. Test log data flow and collection
156. Test metrics data flow and reporting
157. Test user preference data synchronization
158. Test real-time data streaming
159. Test data validation across modules
160. Test data transformation between modules
161. Test data encryption in transit
162. Test data compression optimization
163. Test data caching strategies
164. Test data backup and recovery
165. Test data migration between versions
166. Test data export functionality
167. Test data import functionality
168. Test data archival policies
169. Test data privacy compliance
170. Test data retention policies
171. Test data access controls
172. Test data audit trails
173. Test data consistency checks
174. Test data conflict resolution
175. Test data synchronization timing

#### System Integration (25 scenarios)
176. Test macOS system integration
177. Test Xcode integration
178. Test Terminal integration
179. Test Safari integration
180. Test Chrome integration
181. Test Microsoft Office integration
182. Test Adobe Creative Suite integration
183. Test Slack integration
184. Test Discord integration
185. Test Zoom integration
186. Test Teams integration
187. Test Email client integration
188. Test Calendar integration
189. Test Notes app integration
190. Test TextEdit integration
191. Test System Preferences integration
192. Test Spotlight integration
193. Test Finder integration
194. Test Activity Monitor integration
195. Test Console integration
196. Test Accessibility Inspector integration
197. Test VoiceOver integration
198. Test Switch Control integration
199. Test Voice Control integration
200. Test Screen Time integration

### UI/UX Tests (100 scenarios)

#### Main Interface (25 scenarios)
201. Test app launch and initialization
202. Test menu bar icon display
203. Test menu bar icon state changes
204. Test menu bar menu items
205. Test menu bar click handling
206. Test status indicator animations
207. Test system tray integration
208. Test dock icon behavior
209. Test app activation and deactivation
210. Test window focus management
211. Test keyboard navigation
212. Test mouse interaction
213. Test trackpad gesture support
214. Test multi-touch support
215. Test external input device support
216. Test display scaling compatibility
217. Test dark mode support
218. Test light mode support
219. Test high contrast support
220. Test reduced motion support
221. Test color blind accessibility
222. Test font size adaptation
223. Test language localization
224. Test right-to-left language support
225. Test voice control integration

#### Settings Interface (25 scenarios)
226. Test settings window opening
227. Test settings window navigation
228. Test general settings tab
229. Test hotkey settings tab
230. Test speech settings tab
231. Test accessibility settings tab
232. Test advanced settings tab
233. Test settings validation
234. Test settings persistence
235. Test settings reset functionality
236. Test settings export/import
237. Test settings search functionality
238. Test settings help integration
239. Test settings keyboard shortcuts
240. Test settings undo/redo
241. Test settings real-time preview
242. Test settings error handling
243. Test settings accessibility compliance
244. Test settings responsive design
245. Test settings performance optimization
246. Test settings security validation
247. Test settings backup and restore
248. Test settings version migration
249. Test settings conflict resolution
250. Test settings internationalization

#### Onboarding Interface (25 scenarios)
251. Test welcome screen display
252. Test onboarding flow navigation
253. Test permission request screens
254. Test setup completion screen
255. Test skip functionality
256. Test back navigation
257. Test progress indicators
258. Test help and tutorial integration
259. Test accessibility onboarding
260. Test keyboard-only navigation
261. Test screen reader compatibility
262. Test gesture tutorials
263. Test video tutorials
264. Test interactive demos
265. Test troubleshooting guides
266. Test FAQ integration
267. Test support contact information
268. Test feedback collection
269. Test analytics integration
270. Test A/B testing support
271. Test localization testing
272. Test responsive design testing
273. Test performance optimization
274. Test error state handling
275. Test completion tracking

#### Contextual Interface (25 scenarios)
276. Test contextual indicator display
277. Test indicator positioning accuracy
278. Test indicator animation smoothness
279. Test indicator size adaptation
280. Test indicator color customization
281. Test indicator transparency effects
282. Test indicator multi-monitor support
283. Test indicator coordinate system handling
284. Test indicator collision detection
285. Test indicator z-order management
286. Test indicator performance optimization
287. Test indicator accessibility features
288. Test indicator user preferences
289. Test indicator debug mode
290. Test indicator error visualization
291. Test popup menu display
292. Test tooltip functionality
293. Test context menu integration
294. Test overlay window management
295. Test notification display
296. Test alert handling
297. Test confirmation dialogs
298. Test progress indicators
299. Test status messages
300. Test real-time feedback

### Performance Tests (100 scenarios)

#### Latency Tests (25 scenarios)
301. Test hotkey response latency
302. Test speech recognition startup latency
303. Test text insertion latency
304. Test UI responsiveness under load
305. Test memory allocation latency
306. Test disk I/O latency
307. Test network request latency
308. Test database query latency
309. Test image rendering latency
310. Test animation frame rate
311. Test audio processing latency
312. Test video processing latency
313. Test computation latency
314. Test garbage collection impact
315. Test thread switching latency
316. Test process communication latency
317. Test system call latency
318. Test hardware interaction latency
319. Test peripheral device latency
320. Test external service latency
321. Test cache access latency
322. Test memory access patterns
323. Test CPU instruction latency
324. Test synchronization primitive latency
325. Test real-time constraint validation

#### Throughput Tests (25 scenarios)
326. Test maximum words per minute recognition
327. Test concurrent user simulation
328. Test peak load handling
329. Test sustained load performance
330. Test batch processing throughput
331. Test parallel processing efficiency
332. Test queue processing rates
333. Test data processing bandwidth
334. Test network throughput optimization
335. Test disk throughput optimization
336. Test memory throughput testing
337. Test CPU utilization efficiency
338. Test GPU utilization testing
339. Test multi-core scaling
340. Test hyperthreading benefits
341. Test vectorization efficiency
342. Test cache efficiency optimization
343. Test branch prediction impact
344. Test memory prefetching
345. Test instruction pipeline optimization
346. Test syscall overhead reduction
347. Test context switching optimization
348. Test interrupt handling efficiency
349. Test I/O completion optimization
350. Test resource pooling efficiency

#### Memory Tests (25 scenarios)
351. Test memory usage during idle state
352. Test memory usage during active recording
353. Test memory usage during text insertion
354. Test memory leak detection
355. Test memory fragmentation analysis
356. Test peak memory consumption
357. Test memory allocation patterns
358. Test memory deallocation timing
359. Test garbage collection frequency
360. Test retained object analysis
361. Test weak reference handling
362. Test circular reference detection
363. Test memory pool efficiency
364. Test stack usage optimization
365. Test heap usage optimization
366. Test virtual memory usage
367. Test physical memory pressure
368. Test memory compression benefits
369. Test memory swapping behavior
370. Test memory-mapped file usage
371. Test shared memory efficiency
372. Test memory security validation
373. Test memory alignment optimization
374. Test cache line utilization
375. Test NUMA awareness testing

#### Scalability Tests (25 scenarios)
376. Test single user performance
377. Test multiple concurrent users
378. Test enterprise deployment scaling
379. Test cloud deployment scaling
380. Test horizontal scaling patterns
381. Test vertical scaling patterns
382. Test load balancing efficiency
383. Test auto-scaling behavior
384. Test resource contention handling
385. Test bottleneck identification
386. Test capacity planning validation
387. Test performance regression testing
388. Test stress testing under extreme load
389. Test endurance testing over time
390. Test spike testing with sudden load
391. Test volume testing with large datasets
392. Test configuration scaling impact
393. Test feature flag performance impact
394. Test A/B testing performance impact
395. Test monitoring overhead assessment
396. Test logging performance impact
397. Test security feature overhead
398. Test encryption performance impact
399. Test compression performance impact
400. Test optimization effectiveness measurement

### Error Handling and Edge Cases (100 scenarios)

#### System Error Scenarios (25 scenarios)
401. Test low memory conditions
402. Test low disk space conditions
403. Test network connectivity loss
404. Test system sleep/wake cycles
405. Test user account switching
406. Test admin privilege changes
407. Test system clock changes
408. Test timezone changes
409. Test display configuration changes
410. Test audio device changes
411. Test microphone disconnection
412. Test microphone quality degradation
413. Test system overload conditions
414. Test thermal throttling
415. Test power management events
416. Test system updates/reboots
417. Test file system corruption
418. Test registry corruption (Windows)
419. Test preferences corruption
420. Test application sandbox restrictions
421. Test parent process termination
422. Test signal handling
423. Test exception handling
424. Test crash recovery
425. Test automatic restart functionality

#### Permission Error Scenarios (25 scenarios)
426. Test microphone permission denied
427. Test accessibility permission denied
428. Test speech recognition permission denied
429. Test file system permission denied
430. Test network permission denied
431. Test privacy setting changes
432. Test parental control restrictions
433. Test enterprise policy restrictions
434. Test guest account limitations
435. Test temporary account restrictions
436. Test screen recording restrictions
437. Test automation restrictions
438. Test keyboard access restrictions
439. Test mouse access restrictions
440. Test application control restrictions
441. Test system preferences access restrictions
442. Test security policy violations
443. Test certificate validation failures
444. Test code signing validation failures
445. Test notarization requirement failures
446. Test sandboxing violations
447. Test entitlement validation failures
448. Test capability restrictions
449. Test resource quota exceeded
450. Test rate limiting violations

#### Data Error Scenarios (25 scenarios)
451. Test corrupted audio data
452. Test incomplete audio data
453. Test malformed speech recognition results
454. Test invalid text encoding
455. Test oversized text content
456. Test special character handling
457. Test emoji and Unicode edge cases
458. Test null/empty data handling
459. Test data type conversion errors
460. Test serialization failures
461. Test deserialization failures
462. Test data validation failures
463. Test checksum mismatches
464. Test version incompatibility
465. Test schema migration failures
466. Test backup corruption
467. Test restore failures
468. Test import/export errors
469. Test format conversion errors
470. Test compression failures
471. Test encryption failures
472. Test decryption failures
473. Test key management errors
474. Test certificate expiration
475. Test data retention policy violations

#### User Error Scenarios (25 scenarios)
476. Test invalid hotkey combinations
477. Test conflicting settings
478. Test rapid user input
479. Test simultaneous operations
480. Test interruption during operations
481. Test cancellation edge cases
482. Test undo/redo boundary conditions
483. Test clipboard conflicts
484. Test external application crashes
485. Test focus loss during operations
486. Test window occlusion scenarios
487. Test multi-monitor edge cases
488. Test display rotation
489. Test resolution changes
490. Test scaling factor changes
491. Test input method conflicts
492. Test language switching
493. Test accessibility tool conflicts
494. Test third-party software conflicts
495. Test antivirus interference
496. Test firewall restrictions
497. Test proxy configuration issues
498. Test DNS resolution failures
499. Test certificate trust issues
500. Test user workflow violations

### Additional Testing Categories

#### Security Testing (50+ scenarios)
- Input validation and sanitization
- SQL injection prevention
- Cross-site scripting prevention
- Buffer overflow protection
- Authentication and authorization
- Secure data transmission
- Secure data storage
- Privacy compliance (GDPR, CCPA)
- Audit trail verification
- Incident response testing

#### Compatibility Testing (50+ scenarios)
- macOS version compatibility
- Hardware compatibility
- Third-party application compatibility
- Accessibility tool compatibility
- Development tool compatibility
- Browser compatibility
- Office suite compatibility
- Creative software compatibility
- Enterprise software compatibility
- Gaming software compatibility

#### Localization Testing (50+ scenarios)
- Multi-language support
- Currency and date formatting
- Number formatting
- Text expansion/contraction
- Right-to-left language support
- Font rendering
- Input method compatibility
- Cultural appropriateness
- Legal compliance per region
- Character encoding support

#### Deployment Testing (50+ scenarios)
- Installation testing
- Update testing
- Rollback testing
- Migration testing
- Configuration management
- Environment validation
- Dependency verification
- License validation
- Digital signature verification
- Distribution channel testing

## Implementation Timeline

### Month 1: Foundation
- Setup Swift Testing framework
- Create test infrastructure
- Implement basic unit tests
- Establish CI/CD pipeline

### Month 2: Core Testing
- Complete unit test coverage
- Implement integration tests
- Add performance benchmarks
- Create mock objects and utilities

### Month 3: Advanced Testing
- Implement UI tests
- Add security testing
- Create error scenario tests
- Optimize test performance

### Month 4: Validation & Optimization
- Complete compatibility testing
- Validate all 500+ scenarios
- Optimize test execution
- Document testing procedures

## Conclusion

This comprehensive testing strategy provides:

1. **Modern Swift 6.0+ testing practices** using Swift Testing framework
2. **Complete coverage** of all application modules and scenarios
3. **Performance optimization** through extensive benchmarking
4. **Future-proof design** for iOS compatibility
5. **Robust CI/CD integration** for automated testing
6. **500+ detailed test scenarios** covering all aspects of the application

The strategy follows industry best practices while leveraging the latest Swift testing capabilities to ensure high-quality, maintainable, and reliable software.