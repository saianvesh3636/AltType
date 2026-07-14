---
name: testing-strategy-skill
description: Testing patterns, strategies, and best practices. Use when writing tests, understanding test coverage, or implementing testing infrastructure. Covers unit tests, integration tests, performance tests, and mocking strategies.
---

# Testing Strategy - Quality Assurance

## Overview

Comprehensive testing strategy across all modules with mocking and performance tests.

**Full Documentation**: `docs/testing/TESTING_STRATEGY.md`

## Test Organization

### Unit Tests (Per Module)
- `HotkeyKitTests/`
- `SpeechKitTests/`
- `TextInsertionKitTests/`
- `PermissionKitTests/`
- `BuildConfigurationTests/`
- `FeatureFlagsTests/`

### Integration Tests
- `Tests/IntegrationTests/`

### Performance Tests
- `Tests/PerformanceTests/`

## Unit Test Patterns

### Testing with Mocks

```swift
// Mock SpeechEngine for testing
class MockSpeechEngine: SpeechEngine {
    var mockTranscription: String = "test"
    var mockIsAvailable: Bool = true
    var transcribeCalled = false

    func transcribe(audio: Data) async throws -> String {
        transcribeCalled = true
        return mockTranscription
    }

    func isAvailable() -> Bool {
        return mockIsAvailable
    }
}

@Test("Engine selection prefers available engine")
func testEngineSelection() {
    let mockApple = MockSpeechEngine(name: "Apple", mockIsAvailable: true)
    let mockWhisper = MockSpeechEngine(name: "Whisper", mockIsAvailable: false)

    let manager = SpeechEngineManager(engines: [mockApple, mockWhisper])
    let selected = manager.selectBestEngine()

    #expect(selected?.name == "Apple")
}
```

### Testing Reactive Publishers

```swift
@Test("Hotkey activation triggers state change")
func testHotkeyActivation() async {
    let hotkeyManager = HotkeyManager()
    var receivedStates: [Bool] = []

    let cancellable = hotkeyManager.activationPublisher
        .sink { isActive in
            receivedStates.append(isActive)
        }

    hotkeyManager.simulateHotkeyPress()
    await Task.yield() // Allow async updates

    #expect(receivedStates == [true])
}
```

## Integration Tests
- `Tests/IntegrationTests/`

### Performance Tests
- `Tests/PerformanceTests/`

## Unit Test Patterns

### Testing with Mocks

```swift
// Mock SpeechEngine for testing
class MockSpeechEngine: SpeechEngine {
    var mockTranscription: String = "test"
    var mockIsAvailable: Bool = true
    var transcribeCalled = false

    func transcribe(audio: Data) async throws -> String {
        transcribeCalled = true
        return mockTranscription
    }

    func isAvailable() -> Bool {
        return mockIsAvailable
    }
}

@Test("Engine selection prefers available engine")
func testEngineSelection() {
    let mockApple = MockSpeechEngine(name: "Apple", mockIsAvailable: true)
    let mockWhisper = MockSpeechEngine(name: "Whisper", mockIsAvailable: false)

    let manager = SpeechEngineManager(engines: [mockApple, mockWhisper])
    let selected = manager.selectBestEngine()

    #expect(selected?.name == "Apple")
}
```

### Testing Reactive Publishers

```swift
@Test("Hotkey activation triggers state change")
func testHotkeyActivation() async {
    let hotkeyManager = HotkeyManager()
    var receivedStates: [Bool] = []

    let cancellable = hotkeyManager.activationPublisher
        .sink { isActive in
            receivedStates.append(isActive)
        }

    hotkeyManager.simulateHotkeyPress()
    await Task.yield() // Allow async updates

    #expect(receivedStates == [true])
}
```

### Testing Tier Validation

```swift
@Test("Free tier blocks at usage limit")
func testFreeTierLimit() {
    let tierManager = TierManager()
    tierManager.setDebugTier(.free)

    let usageGuardian = UsageGuardian(tierManager: tierManager)
    usageGuardian.recordUsage(wordCount: 2000) // Hit free limit

    #expect(usageGuardian.canStartTranscription() == false)
    #expect(usageGuardian.state == .limitReached)
}
```

## Integration Tests

### Testing Complete Flow

```swift
@Test("Complete transcription flow")
func testCompleteTranscriptionFlow() async throws {
    // Setup
    let permissionManager = PermissionManager()
    let hotkeyManager = HotkeyManager()
    let speechRecognizer = SpeechRecognizer()
    let textInserter = UniversalTextInserter()

    // Simulate hotkey press
    hotkeyManager.simulateHotkeyPress()

    // Wait for recording to start
    try await Task.sleep(nanoseconds: 100_000_000) // 0.1s

    #expect(speechRecognizer.isRecording == true)

    // Simulate transcription
    speechRecognizer.simulateTranscription("Hello World")

    // Release hotkey
    hotkeyManager.simulateHotkeyRelease()

    // Wait for insertion
    try await Task.sleep(nanoseconds: 100_000_000)

    #expect(textInserter.lastInsertedText == "Hello World")
}
```

## Performance Tests

### CPU Usage Test

```swift
@Test("Dormant mode uses minimal CPU")
func testDormantCPUUsage() {
    let hotkeyManager = HotkeyManager()
    hotkeyManager.transitionToDormantMode(reason: "Test")

    let cpuBefore = getCPUUsage()
    sleep(5) // Let it settle
    let cpuAfter = getCPUUsage()

    #expect(cpuAfter < 2.0) // < 2% CPU in dormant
}
```

### Memory Leak Test

```swift
@Test("No memory leaks in hotkey manager")
func testNoMemoryLeaks() {
    weak var weakManager: HotkeyManager?

    autoreleasepool {
        let manager = HotkeyManager()
        weakManager = manager
        manager.startMonitoring()
        manager.stopMonitoring()
    }

    #expect(weakManager == nil) // Should be deallocated
}
```

## Mocking Strategies

## Running Tests

```bash
# All tests
tuist test

# Specific module
tuist test HotkeyKit

# Release configuration
tuist test --configuration Release
```

## Related Skills
- **development-standards-skill**: Testing best practices
- **speechkit-skill**: Mock engines
