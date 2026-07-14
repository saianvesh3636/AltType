---
name: development-standards-skill
description: Swift 6 code quality standards, SOLID principles, and best practices. Use when writing or reviewing code, refactoring, or ensuring code quality. Covers strict concurrency, no force unwraps, no timers policy, proper optional handling, and modern Swift patterns.
---

# Development Standards - Code Quality

## Overview

Zero-tolerance code quality standards for Swift 6 with strict concurrency.

**Full Documentation**: `docs/development/SWIFT_CODE_QUALITY_STANDARDS.md`

## Critical Rules (Zero Tolerance)

### 1. No Force Unwraps

**❌ NEVER:**
```swift
textInserter: textInserter!  // Crash waiting to happen
private var speechService: SpeechService!  // Implicitly unwrapped - dangerous
```

**✅ ALWAYS:**
```swift
private let textInserter: UniversalTextInserter  // Non-optional when guaranteed
guard let overlay = recordingOverlay else { return }  // Proper optional handling
```

### 2. No Code Duplication

**❌ Avoid:**
```swift
switch state {
case .needsMicrophone:
    self.state = .error(.microphonePermissionDenied)
    updateHotkeyManagerPermissions(hasPermissions: false)
case .needsAccessibility:
    self.state = .error(.accessibilityPermissionDenied)
    updateHotkeyManagerPermissions(hasPermissions: false)
}
```

**✅ Use Pattern Matching:**
```swift
switch state {
case .needsMicrophone, .needsBoth:
    updateAppState(to: .error(.microphonePermissionDenied), hasPermissions: false)
case .needsAccessibility:
    updateAppState(to: .error(.accessibilityPermissionDenied), hasPermissions: false)
}

private func updateAppState(to newState: AppState, hasPermissions: Bool) {
    self.state = newState
    updateHotkeyManagerPermissions(hasPermissions: hasPermissions)
}
```

### 3. Dependency Injection

**❌ Singleton Access:**
```swift
@ObservedObject private var permissionManager = PermissionKit.PermissionManager.shared
```

**✅ Pure DI:**
```swift
@EnvironmentObject var permissionManager: PermissionKit.PermissionManager
```

### 4. Weak References in Closures

**❌ Retain Cycles:**
```swift
.sink { state in
    self.handleStateChange(state)  // Retain cycle!
}
```

**✅ Weak Self:**
```swift
.sink { [weak self] state in
    self?.handleStateChange(state)
}
```

### 5. No Timers Policy

**❌ NEVER:**
```swift
Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
    self.checkState()
}
```

**✅ Event-Driven:**
```swift
// Single-shot dispatch (acceptable for one-time delay)
DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
    self?.checkState()
}

// Or reactive programming
statePublisher.sink { [weak self] state in
    self?.react(to: state)
}
```

## SOLID Principles

### Single Responsibility
Each class has one reason to change

### Open/Closed
Use protocols for extension, avoid modifying existing code

### Liskov Substitution
Subtypes must be substitutable for base types

### Interface Segregation
Small, focused protocols

### Dependency Inversion
Depend on abstractions (protocols), not implementations

## Swift 6 Concurrency

### Strict Concurrency Checking

**✅ All code must pass Swift 6 concurrency checking**

### Sendable Conformance

```swift
// Types crossing actor boundaries must be Sendable
public struct UsageStats: Sendable {
    public let wordCount: Int
    public let date: Date
}
```

### MainActor Isolation

```swift
@MainActor
public final class ViewModel: ObservableObject {
    @Published var state: AppState

    // All methods run on main thread
    func updateState() {
        // Safe to update @Published properties
    }
}
```

### Async/Await

**✅ Use modern concurrency:**
```swift
func fetchData() async throws -> Data {
    let data = try await URLSession.shared.data(from: url)
    return data.0
}
```

**❌ Avoid callbacks:**
```swift
func fetchData(completion: @escaping (Data?) -> Void) {
    // Old pattern - avoid
}
```

## Related Skills
- **app-architecture-skill**: SOLID application
- **hotkeykit-skill**: No timer examples
- **testing-strategy-skill**: Testing patterns
