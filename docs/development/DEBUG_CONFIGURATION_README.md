# Debug vs Production Build Configuration System

This document describes the debug vs production build configuration system for the macOS app. The system provides clean separation between debug and production builds while maintaining a professional, non-hacky architecture.

## Overview

The configuration system consists of two modules:

1. **BuildConfiguration** - Build-time environment detection and runtime configuration
2. **FeatureFlags** - Runtime feature toggle system with debug overrides

## Architecture

### Build-Time Configuration

```swift
// Compile-time environment detection
let environment = BuildEnvironment.current // .debug or .production

// Build-time conditional compilation
#if DEBUG
// Debug-only code paths
#else
// Production-only code paths
#endif
```

### Runtime Configuration

```swift
// Debug configuration with persistent settings
let debugConfig = DebugConfiguration.shared

// Feature flags with debug override support
let featureFlags = FeatureFlagManager.shared
```

## Key Features

### 1. Clean Debug/Production Separation

**Debug Builds:**
- Feature-flag overrides available in code (`FeatureFlagManager.setOverride`)
- All debug flags persisted in UserDefaults

**Production Builds:**
- No debug UI code included (stripped at compile time)
- Zero performance impact from debug features
- All debug properties return safe default values

### 2. Feature Flag System

**Predefined Categories:**
- **Speech Recognition**: Engine selection, real-time transcription
- **User Interface**: Contextual indicators, menu bar status, onboarding
- **Performance**: Model preloading, concurrent processing
- **Logging & Debug**: Detailed logging, performance metrics

**Example Usage:**
```swift
// Check if feature is enabled
if featureFlags.isRealTimeTranscriptionEnabled {
    // Show real-time transcription UI
}

// Set debug override (debug builds only)
featureFlags.setOverride(for: AppFeatureFlag.enableDetailedLogging, value: true)
```

## Build Scheme

There is a single `theTypeAlternative` scheme following the standard Xcode convention:

- **Run / Test** → Debug configuration (debug menu, feature-flag overrides enabled)
- **Profile / Archive** → Release configuration (all debug code stripped)

To exercise production behavior from the CLI: `xcodebuild -configuration Release build`.

## Implementation Guide

### 1. Project Setup

The system is already integrated into the Tuist configuration:

```swift
// Project.swift includes the modules
dependencies: [
    .target(name: "BuildConfiguration"),
    .target(name: "FeatureFlags")
]
```

### 2. SwiftUI Integration

Add environment objects to your app:

```swift
WindowGroup("AltType") {
    ContentView()
        .environmentObject(appDelegate.debugConfiguration)
        .environmentObject(appDelegate.featureFlagManager)
}
```

### 3. Usage in Views

```swift
struct TranscriptionView: View {
    @EnvironmentObject private var featureFlags: FeatureFlagManager

    var body: some View {
        VStack {
            if featureFlags.isContextualIndicatorEnabled {
                ContextualIndicatorView()
            }
        }
    }
}
```

## Testing

### Debug Build Testing

1. Run the scheme normally (Debug configuration)
2. Toggle feature flags via `FeatureFlagManager.shared.setOverride` and verify behavior

### Production Build Testing

1. Build with the Release configuration (Product → Archive, or `xcodebuild -configuration Release`)
2. Confirm debug overrides have no effect

### Unit Tests

Comprehensive test suites verify:
- Build environment detection
- Debug configuration persistence
- Feature flag behavior in debug vs production

```bash
# Run tests
tuist test
```

## Security Considerations

### Production Safety
- Zero debug code included in production builds
- No performance impact from configuration system
- Impossible to enable debug features in production

### Debug Convenience
- Settings persist between debug sessions
- Easy reset to defaults available
- Visual indicators prevent confusion
- Configuration export for bug reports

## Troubleshooting

### Feature Flags Not Working
- Confirm FeatureFlagManager is environment object
- Check that flags are properly defined
- Verify debug overrides aren't interfering

## Summary

This debug configuration system provides:

✅ **Clean Architecture**: Proper module separation and dependency management
✅ **Build-Time Safety**: Debug code completely stripped from production
✅ **Runtime Flexibility**: Easy feature testing without code changes
