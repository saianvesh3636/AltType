---
name: debug-tools-skill
description: Debug tools, feature flags, and build configuration. Use when working with debug menus, feature toggles, build configurations, testing utilities, or development tools. Covers FeatureFlags, BuildConfiguration, and debug toggles.
---

# Debug Tools - Development Utilities

## Overview

Debug-only tools and feature flags for development and testing.

**Modules**:
- `FeatureFlags` - Runtime feature toggles
- `BuildConfiguration` - Debug vs Release flags

## BuildConfiguration

```swift
public enum BuildConfiguration {
    public static var isDebug: Bool {
        #if DEBUG
        return true
        #else
        return false
        #endif
    }

    public static var isRelease: Bool {
        return !isDebug
    }
}
```

**Usage**:
```swift
#if DEBUG
// Debug-only code
hotkeyManager.enableDebugLogging = true
#endif

if BuildConfiguration.isDebug {
    // Runtime debug features
}
```

## FeatureFlags

```swift
public enum FeatureFlags {
    public static var enableWhisperKit: Bool = BuildConfiguration.isDebug
    public static var enableUsageTracking: Bool = true
    public static var enableDebugOverlay: Bool = BuildConfiguration.isDebug

    // A/B testing flags
    public static var useNewOnboarding: Bool = false
}
```


**Text Insertion Strategy Selector**:
```swift
#if DEBUG
struct DebugInsertionStrategySelector: View {
    @State private var selectedStrategy: InsertionStrategy = .automatic

    enum InsertionStrategy {
        case automatic
        case forceAccessibility
        case forceKeyboard
        case forcePasteboard
    }

    var body: some View {
        Picker("Debug Strategy", selection: $selectedStrategy) {
            Text("Automatic").tag(InsertionStrategy.automatic)
            Text("Force Accessibility").tag(InsertionStrategy.forceAccessibility)
            Text("Force Keyboard").tag(InsertionStrategy.forceKeyboard)
            Text("Force Pasteboard").tag(InsertionStrategy.forcePasteboard)
        }
        .onChange(of: selectedStrategy) { newValue in
            TextInsertionKit.debugStrategy = newValue
        }
    }
}
#endif
```

## Performance Logging

```swift
#if DEBUG
public struct PerformanceLogger {
    static func measure<T>(_ name: String, operation: () -> T) -> T {
        let start = CFAbsoluteTimeGetCurrent()
        let result = operation()
        let end = CFAbsoluteTimeGetCurrent()

        print("⏱️ \(name): \(String(format: "%.2fms", (end - start) * 1000))")
        return result
    }
}

// Usage
#if DEBUG
let text = PerformanceLogger.measure("Text Insertion") {
    textInserter.insertText("Hello World")
}
#endif
#endif
```

## Related Skills
- **development-standards-skill**: Build configurations
- **textinsertionkit-skill**: Strategy selector
