---
name: app-architecture-skill
description: Application architecture, module dependencies, and state management patterns. Use when working with overall app structure, module organization, reactive programming, dependency injection, or data flow. Covers the 8-module architecture and SOLID principles.
---

# App Architecture - System Design

## Overview

Modular Swift 6 architecture with 8 modules organized by responsibility and a clear dependency hierarchy. Free and open source — there is no monetization layer, no tiering, no app variants.

**Module Structure**:
```
theTypeAlternative (Main App)
├── AppServices - Protocol layer, shared types, FeatureSet + WhisperSupport switch
├── HotkeyKit - Keyboard monitoring (dormant/primed event tap)
├── SpeechKit - Speech engines (SpeechAnalyzer + optional WhisperKit)
├── TextInsertionKit - Multi-strategy text insertion
├── PermissionKit - Microphone + Accessibility permissions
├── BuildConfiguration - Debug/Release environment
├── FeatureFlags - Runtime debug toggles
└── FullAppConfiguration - DI bootstrap (wires implementations into AppConfiguration)
```

## Dependency Injection

**Bootstrap** (`AppConfigurationBootstrap.initialize()` in AppDelegate.init, before any service is created):

```swift
// FullAppConfiguration wires concrete implementations into the DI container
AppConfiguration.current = AppConfiguration(
    features: .standard,
    createHotkeyService: { HotkeyManager() },
    createPermissionService: { PermissionManager() },
    createTextInsertionService: { UniversalTextInserter() }
)
```

**Rules**:
- All service protocols live in `AppServices` (`HotkeyServiceProtocol`, `PermissionServiceProtocol`, `TextInsertionServiceProtocol`, `SpeechServiceProtocol`)
- App code depends on `any <Protocol>`, resolved through `AppConfiguration.current.create…()`
- SpeechService is created at app level (needs transcriptionStore etc.) and conforms to `SpeechServiceProtocol`

**EnvironmentObject Pattern** (SwiftUI): AppDelegate owns the long-lived objects (TranscriptionStore, PaletteManager, SpeechEngineSettings, SpeechEngineManager, DebugConfiguration, FeatureFlagManager, NavigationHandler, AppCoordinator) and injects them at the WindowGroup root.

## FeatureSet

One preset, no variants:

```swift
// Modules/AppServices/Sources/Configuration/FeatureSet.swift
public enum WhisperSupport {
    public static let isEnabled = true   // THE switch for all WhisperKit surfaces
}

FeatureSet.standard   // hotkeys, AX insertion, menu bar, whisper per switch
```

Views read it via `@Environment(\.features)`.

## Reactive Programming with Combine

```swift
class AppCoordinator {
    private var cancellables = Set<AnyCancellable>()

    func setupBindings() {
        hotkeySettings.requiredKeysPublisher
            .removeDuplicates()
            .sink { [weak self] keys in self?.updateHotkey(requiredKeys: keys) }
            .store(in: &cancellables)

        permissionManager.overallStatePublisher
            .removeDuplicates()
            .sink { [weak self] state in self?.handlePermissionStateChange(state) }
            .store(in: &cancellables)
    }
}
```

**Combine Best Practices**:
- ✅ Use `.removeDuplicates()` to avoid redundant updates
- ✅ Use `[weak self]` to prevent retain cycles
- ✅ Store subscriptions in `cancellables` set
- ✅ One reactive stream per data flow (single source of truth)

## Module Dependencies

**Dependency Graph** (acyclic, enforced by Tuist):
```
Main App
  ├─ AppServices                (no deps)
  ├─ BuildConfiguration         (no deps)
  ├─ HotkeyKit                  → AppServices, BuildConfiguration
  ├─ SpeechKit                  → AppServices, BuildConfiguration, WhisperKit (SPM)
  ├─ TextInsertionKit           → AppServices, HotkeyKit, BuildConfiguration
  ├─ PermissionKit              → AppServices
  ├─ FeatureFlags               → BuildConfiguration
  └─ FullAppConfiguration       → AppServices, HotkeyKit, PermissionKit, TextInsertionKit, SpeechKit
```

**Rules**:
- ✅ Modules depend on abstractions (protocols), not implementations
- ✅ Lower-level modules don't depend on higher-level modules
- ✅ Circular dependencies are prohibited

## App State

`AppCoordinator` owns the app state machine (`AppState`: idle / listening / error) and implements `SpeechActionDelegate` (hotkey → start/stop), `TextInsertionDelegate` (final text → inserter), and `SoundFeedbackDelegate`. UI observes `@Published var state`.

## Related Skills
- **development-standards-skill**: SOLID principles, code quality
- **speechkit-skill**: Engine architecture
- **hotkeykit-skill**: Event tap lifecycle
