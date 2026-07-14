# Swift Code Quality Standards & Best Practices

This document captures the code quality standards, patterns, and practices established during the theTypeAlternative refactoring project. These standards represent 2024 Swift best practices and should be followed for all future development.

## Overview

This project successfully eliminated all anti-patterns and achieved exemplary Swift code quality through systematic application of modern software engineering principles. Use this document as a reference to maintain these standards.

## Critical Anti-Patterns to Avoid

### 1. Force Unwrap Operations (CRITICAL)

**❌ Never Use:**
```swift
// Force unwrap - causes crashes
textInserter: textInserter!

// Implicitly unwrapped optionals - dangerous
private var speechService: SpeechService!
```

**✅ Always Use:**
```swift
// Non-optional when guaranteed to exist
private let textInserter: UniversalTextInserter

// Proper optional handling with guard
guard let overlay = recordingOverlay else { return }
```

**Rule:** Zero tolerance for force unwraps (`!`) - always use proper optional handling.

### 2. Code Duplication in Switch Statements

**❌ Avoid:**
```swift
switch state {
case .needsMicrophone:
    self.state = .error(.microphonePermissionDenied)
    updateHotkeyManagerPermissions(hasPermissions: false)
    Logger.warning("Microphone permission needed")
case .needsAccessibility:
    self.state = .error(.accessibilityPermissionDenied)
    updateHotkeyManagerPermissions(hasPermissions: false)
    Logger.warning("Accessibility permission needed")
case .needsBoth:
    self.state = .error(.microphonePermissionDenied)
    updateHotkeyManagerPermissions(hasPermissions: false)
    Logger.warning("Both permissions needed")
}
```

**✅ Use Pattern Matching & Extraction:**
```swift
switch state {
case .ready:
    updateAppState(to: .idle, hasPermissions: true)
    Logger.success("All permissions granted")
    
case .needsMicrophone, .needsBoth:
    updateAppState(to: .error(.microphonePermissionDenied), hasPermissions: false)
    logPermissionIssue(for: state)
    
case .needsAccessibility:
    updateAppState(to: .error(.accessibilityPermissionDenied), hasPermissions: false)
    Logger.warning("Accessibility permission needed")
}

// Extracted helper methods
private func updateAppState(to newState: AppState, hasPermissions: Bool) {
    self.state = newState
    updateHotkeyManagerPermissions(hasPermissions: hasPermissions)
}

private func logPermissionIssue(for state: PermissionKit.OverallPermissionState) {
    let message = state == .needsBoth ? 
        "Both microphone and accessibility permissions needed" : 
        "Microphone permission needed"
    Logger.warning(message)
}
```

### 3. Mixed Dependency Injection Patterns

**❌ Inconsistent DI:**
```swift
// Mixing singleton access with dependency injection
@ObservedObject private var permissionManager = PermissionKit.PermissionManager.shared
```

**✅ Pure Dependency Injection:**
```swift
// Environment object pattern for SwiftUI
@EnvironmentObject var permissionManager: PermissionKit.PermissionManager

// Constructor injection for business logic
init(permissionManager: PermissionKit.PermissionManager) {
    self.permissionManager = permissionManager
}
```

### 4. Redundant Reactive Streams

**❌ Duplicate Streams:**
```swift
// Two streams doing similar work
permissionManager.$overallState.sink { ... }
Publishers.CombineLatest(permissionManager.$microphoneState, permissionManager.$accessibilityState)
    .map { ... }.sink { ... }
```

**✅ Single Source of Truth:**
```swift
// One reactive stream with proper operators
permissionManager.$overallState
    .removeDuplicates()
    .sink { [weak self] permissionState in
        self?.handlePermissionStateChange(permissionState)
    }
    .store(in: &cancellables)
```

## SOLID Principles Implementation

### 1. Single Responsibility Principle (SRP)

**Each class/method has one reason to change:**

```swift
// ✅ Focused responsibility
private func updateAppState(to newState: AppState, hasPermissions: Bool) {
    self.state = newState
    updateHotkeyManagerPermissions(hasPermissions: hasPermissions)
}

private func logPermissionIssue(for state: PermissionKit.OverallPermissionState) {
    // Only handles logging logic
}
```

### 2. Open/Closed Principle

**Open for extension, closed for modification:**

```swift
// ✅ Protocol-based extension
protocol SpeechActionDelegate: AnyObject {
    func startSpeechRecording()
    func stopSpeechRecording()
}

// Easy to extend without modifying existing code
```

### 3. Dependency Inversion Principle

**Depend on abstractions, not concretions:**

```swift
// ✅ Inject dependencies, don't create them
@MainActor init(
    statusItem: NSStatusItem?,
    transcriptionStore: TranscriptionStore,
    hotkeySettings: HotkeySettings,
    permissionManager: PermissionKit.PermissionManager
) {
    // All dependencies injected
}
```

## Modern Swift 2024 Patterns

### 1. Reactive Programming with Combine

**Single reactive stream pattern:**

```swift
// ✅ Clean reactive binding
permissionManager.$overallState
    .removeDuplicates()
    .sink { [weak self] permissionState in
        self?.handlePermissionStateChange(permissionState)
    }
    .store(in: &cancellables)
```

### 2. Async/Await for Permission Requests

**Modern concurrency over callbacks:**

```swift
// ✅ Modern async pattern
Task {
    let granted = await permissionManager.requestMicrophone()
    if !granted {
        permissionManager.openSystemSettings(for: .microphone)
    }
}
```

### 3. SwiftUI Environment Object Pattern

**Proper dependency injection for SwiftUI:**

```swift
// ✅ Environment object setup
struct TheTypeAlternativeApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(permissionManager)
                .environmentObject(hotkeySettings)
        }
    }
}

// ✅ Environment object usage
struct SettingsView: View {
    @EnvironmentObject var permissionManager: PermissionKit.PermissionManager
}
```

### 4. Non-Optional Property Pattern

**Eliminate optionals when possible:**

```swift
// ✅ Non-optional properties with proper initialization order
private let textInserter: UniversalTextInserter
private let speechService: SpeechService

init(...) {
    // Initialize all let properties before calling methods
    self.textInserter = UniversalTextInserter()
    self.speechService = SpeechService(...)
    
    // Now safe to call methods
    setupManagers()
}
```

## Architecture Patterns

### 1. Reactive State Management

**Single source of truth with reactive updates:**

```swift
// ✅ Centralized permission state
@MainActor
public final class PermissionManager: ObservableObject {
    @Published public private(set) var microphoneState: PermissionState = .unknown
    @Published public private(set) var accessibilityState: PermissionState = .unknown
    @Published public private(set) var overallState: OverallPermissionState = .checking
}
```

### 2. Coordinator Pattern

**AppCoordinator handles orchestration, not implementation:**

```swift
// ✅ Coordinator delegates to specialized managers
class AppCoordinator: ObservableObject {
    private let permissionManager: PermissionKit.PermissionManager
    private let hotkeyManager: HotkeyManager
    
    // Coordinates between managers, doesn't implement logic
}
```

### 3. Module-Based Architecture

**Clear separation of concerns:**

```
Modules/
├── PermissionKit/     # Permission management
├── HotkeyKit/         # Hotkey handling  
├── SpeechKit/         # Speech recognition
└── TextInsertionKit/  # Text insertion
```

## Memory Management

### 1. Weak References in Closures

**Prevent retain cycles:**

```swift
// ✅ Always use weak self in closures
.sink { [weak self] permissionState in
    self?.handlePermissionStateChange(permissionState)
}
```

### 2. Proper Cancellable Management

**Store and manage subscriptions:**

```swift
// ✅ Centralized cancellable storage
private var cancellables = Set<AnyCancellable>()

// Store subscriptions
.store(in: &cancellables)
```

## Error Handling

### 1. Defensive Programming

**Guard against invalid states:**

```swift
// ✅ Clear guard statements
guard state == .idle else {
    Logger.warning("Cannot start listening - current state: \(state)")
    return
}
```

### 2. Comprehensive Error Types

**Type-safe error handling:**

```swift
enum AppError: LocalizedError, Equatable, Sendable {
    case microphonePermissionDenied
    case accessibilityPermissionDenied
    case speechRecognizerUnavailable
    
    // Convert between error types
    static func from(_ permissionError: PermissionKit.PermissionError) -> AppError {
        // Type-safe conversion
    }
}
```

## Performance Patterns

### 1. Efficient Reactive Streams

**Use operators to optimize performance:**

```swift
// ✅ Avoid duplicate updates
.removeDuplicates()
.sink { ... }

// ✅ Debounce rapid changes
.debounce(for: .milliseconds(300), scheduler: RunLoop.main)
```

### 2. NSApplication Notifications Over Timers

**Event-driven vs polling:**

```swift
// ✅ Reactive to system events
NotificationCenter.default
    .publisher(for: NSApplication.didBecomeActiveNotification)
    .sink { [weak self] _ in
        Task { @MainActor in
            self?.checkPermissions()
        }
    }
```

## Testing Enablement

### 1. Dependency Injection for Testing

**All dependencies injectable:**

```swift
// ✅ Testable through DI
init(permissionManager: PermissionKit.PermissionManager) {
    self.permissionManager = permissionManager
}

// Easy to mock in tests
let mockPermissionManager = MockPermissionManager()
let coordinator = AppCoordinator(permissionManager: mockPermissionManager)
```

### 2. Pure Functions

**Stateless, testable functions:**

```swift
// ✅ Pure function - easy to test
static func from(_ permissionError: PermissionKit.PermissionError) -> AppError {
    switch permissionError.type {
    case .microphone: return .microphonePermissionDenied
    case .accessibility: return .accessibilityPermissionDenied
    }
}
```

## Code Quality Metrics

### Target Standards

- **Force Unwraps**: 0 instances
- **Code Duplication**: 0% (no repeated patterns)
- **SOLID Compliance**: 5/5 principles
- **Reactive Streams**: Single source of truth
- **Memory Leaks**: 0 (weak references)
- **Testability**: High (dependency injection)

### Quality Gates

Before merging any code, verify:

1. ✅ No force unwraps (`!`) anywhere
2. ✅ No duplicate code patterns
3. ✅ All dependencies injected
4. ✅ Reactive streams optimized
5. ✅ Proper error handling
6. ✅ Memory safety (weak refs)
7. ✅ SOLID principles followed

## Tools and Automation

### Recommended Tools

- **SwiftLint**: Automated style checking
- **Periphery**: Dead code detection  
- **Tuist**: Project generation and management
- **Swift Testing**: Modern testing framework

### Pre-commit Hooks

```bash
# Suggested pre-commit checks
swiftlint --strict
periphery scan
tuist build
tuist test
```

## Migration Guidelines

When refactoring existing code:

1. **Identify Anti-patterns**: Force unwraps, code duplication
2. **Extract Methods**: Break down large functions  
3. **Introduce DI**: Replace singleton access
4. **Optimize Reactive**: Consolidate streams
5. **Add Error Handling**: Comprehensive error types
6. **Test**: Verify behavior unchanged

## Conclusion

These standards represent the culmination of modern Swift development practices. They ensure:

- **Maintainability**: Clean, readable code
- **Reliability**: Crash-free operation  
- **Performance**: Optimized reactive patterns
- **Testability**: Easy to mock and test
- **Scalability**: Modular architecture

Follow these patterns to maintain the high code quality achieved in this project and ensure future development continues to meet these standards.

---

*Last Updated: August 2024*  
*Project: theTypeAlternative*  
*Standards Version: 1.0*