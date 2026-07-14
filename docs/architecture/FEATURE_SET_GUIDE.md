# FeatureSet System - Developer Guide

## Overview

The **FeatureSet** system provides a centralized, type-safe way to describe feature availability. Since the open-source conversion there is exactly **one preset** (`FeatureSet.standard`) — no app variants — plus one compile-time switch for WhisperKit.

## Architecture

```
AppServices Module
├── Configuration/
│   ├── AppConfiguration.swift    # DI container (AppConfiguration.current)
│   └── FeatureSet.swift          # FeatureSet + WhisperSupport switch
```

## The Whisper Switch

```swift
// Modules/AppServices/Sources/Configuration/FeatureSet.swift
public enum WhisperSupport {
    public static let isEnabled = true
}
```

This single Bool is the only intended configuration point. It feeds `FeatureSet.standard.supportsWhisperKit`, which gates engine creation (`SpeechEngineManager`), the engine picker (`SpeechEngineSettings`), and all model-management UI. Set it to `false` to build a SpeechAnalyzer-only app.

## FeatureSet Fields

| Field | Value in `.standard` | Meaning |
|---|---|---|
| `supportsHotkeys` | `true` | Global hotkey (Input Monitoring) |
| `supportsAdvancedTextInsertion` | `true` | Accessibility-API insertion |
| `supportsMenuBar` | `true` | Menu bar integration |
| `supportsWhisperKit` | `WhisperSupport.isEnabled` | WhisperKit engine + model UI |
| `requiresInputMonitoring` | `true` | Permission requirement |
| `requiresAccessibility` | `true` | Permission requirement |
| `displayName` | `"AltType"` | App display name |
| `bundleIdentifier` | `com.thetypealternative.app` | Bundle ID |

## Usage

**Bootstrap** (once, in `AppDelegate.init` via `AppConfigurationBootstrap.initialize()`):

```swift
AppConfiguration.current = AppConfiguration(
    features: .standard,
    createHotkeyService: { HotkeyManager() },
    createPermissionService: { PermissionManager() },
    createTextInsertionService: { UniversalTextInserter() }
)
```

**In SwiftUI views** (injected at the WindowGroup root):

```swift
@Environment(\.features) var features

if features.supportsWhisperKit {
    WhisperModelSection()
}
```

**In non-UI code**:

```swift
let supportsWhisper = AppConfiguration.current?.features.supportsWhisperKit ?? WhisperSupport.isEnabled
```

(The optional-chained form keeps unit tests working when no DI container was bootstrapped.)

## Rules

- Don't add a second whisper flag anywhere — all gating flows through `WhisperSupport.isEnabled`.
- Don't reintroduce variant presets; if a feature needs an on/off state, prefer a runtime `FeatureFlags` toggle (debug) or a `WhisperSupport`-style compile-time switch (release behavior).
