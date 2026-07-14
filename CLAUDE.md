# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Claude Skills System

This project uses **Claude Skills** for precise, context-aware assistance. Skills provide specialized expertise for each module and system component, automatically loading only relevant information when needed.

**📂 Skills Location**: `.claude/skills/`

**Available Skills** (13 total):

**Core Technical** (4):
- `hotkeykit-skill` - Smart dormant hotkey system, event taps, energy optimization
- `speechkit-skill` - SpeechAnalyzer (macOS 26) + optional WhisperKit, model management
- `textinsertionkit-skill` - Multi-strategy text insertion with universal app support
- `permissionkit-skill` - Microphone and accessibility permission management

**UI & User Experience** (5):
- `settings-ui-skill` - Settings page, modular UI, macOS-native components
- `theme-appearance-skill` - PaletteManager, color schemes, visual customization
- `user-feedback-skill` - Menu bar icon, contextual indicators, HUD, audio cues
- `onboarding-skill` - First-time user experience, permission flows
- `app-architecture-skill` - 8-module architecture, dependency injection, data flow

**Development & System** (4):
- `development-standards-skill` - Swift 6, SOLID principles, no force unwraps, no timers
- `debug-tools-skill` - FeatureFlags, BuildConfiguration, debug toggles
- `energy-performance-skill` - CPU/memory targets, battery optimization
- `testing-strategy-skill` - Unit/integration/performance tests, mocking patterns

**When to Reference Skills vs CLAUDE.md**:
- **Use Skills**: Module-specific implementation details, code patterns, technical deep-dives
- **Use CLAUDE.md**: Project vision, overall architecture, cross-cutting concerns, development workflows

---

## Project Vision

**theTypeAlternative (AltType)** solves a fundamental problem: typing is slow, physically taxing, and inaccessible for many users. Existing dictation solutions are clunky, app-specific, or privacy-invasive with cloud processing. AltType provides privacy-first, system-wide voice-to-text transcription that feels native to macOS — all speech processing happens on-device, works everywhere, and requires just a hotkey press.

### Current Status
- **Free and open source** (MIT). No subscriptions, tiers, usage limits, accounts, or App Store variants.
- **Deployment target**: macOS 26.0 (Tahoe) — the app uses the SpeechAnalyzer API directly, no availability guards.
- **Distribution**: build from source with Tuist; set your own `DEVELOPMENT_TEAM` in `XCConfig/Shared.xcconfig` for signed distribution.

## VibeTunnel Terminal Title Management

When working in VibeTunnel sessions, actively use the `vt title` command to communicate your current actions and progress:

### Usage
vt title "Current action - project context"

### Guidelines
- **Update frequently**: Set the title whenever you start a new task, change focus, or make significant progress
- **Be descriptive**: Use the title to explain what you're currently doing
- **Include context**: Add PR numbers, file names, or feature names when relevant
- If `vt` command fails (only works inside VibeTunnel), simply ignore the error and continue

## Project Overview

**theTypeAlternative** is a native macOS menu bar application that provides system-wide voice-to-text transcription. It's designed as a modern alternative to manual typing, allowing users to dictate text directly into any active text field across all macOS applications.

## Architecture

This is a modular Swift/SwiftUI application managed by Tuist:

### Modules
- **`theTypeAlternative` (App)**: App lifecycle, NSStatusItem (menu bar), settings window, onboarding, AppCoordinator state machine
- **`AppServices`**: Protocol layer + shared types. All service protocols live here. Also home of `FeatureSet` and the `WhisperSupport.isEnabled` switch
- **`HotkeyKit`**: Smart energy-efficient hotkey management with dual-mode event processing
- **`SpeechKit`**: Speech engines — Apple SpeechAnalyzer/SpeechTranscriber (primary) and WhisperKit (optional), engine selection, Whisper model management
- **`TextInsertionKit`**: Intelligent text insertion with multiple strategies
- **`PermissionKit`**: Microphone and accessibility permissions with reactive state updates
- **`BuildConfiguration`**: Debug vs Release build flags and environment configuration
- **`FeatureFlags`**: Runtime debug toggles
- **`FullAppConfiguration`**: Dependency-injection bootstrap (wires implementations into `AppConfiguration.current`)

### Key Technical Decisions
- **Privacy-First**: All speech processing occurs on-device (SpeechAnalyzer and WhisperKit are both local)
- **Speech engine**: Apple **SpeechAnalyzer + SpeechTranscriber** (macOS 26 API). No SFSpeechRecognizer, no speech-recognition permission — microphone only
- **WhisperKit is optional**: one switch (`WhisperSupport.isEnabled` in `Modules/AppServices/Sources/Configuration/FeatureSet.swift`) enables/disables every WhisperKit surface
- **Activation**: Global hotkey (default: Fn key, configurable)
- **Energy Efficiency**: Smart dormant system maintains hotkey responsiveness with minimal battery impact
- **Language**: Swift 6.x with SwiftUI for UI components
- **No Timers Policy**: Event-driven architecture preferred over timer-based logic

## Development Commands

### Project Setup
```bash
tuist install    # resolve SPM dependencies (WhisperKit, swift-testing)
tuist generate   # generate the Xcode project/workspace
```

### Building
```bash
xcodebuild -workspace theTypeAlternative.xcworkspace -scheme theTypeAlternative build
# or open theTypeAlternative.xcworkspace and hit Run (single scheme: Run/Test = Debug, Archive = Release)
```

### Testing
```bash
tuist test
# or
xcodebuild -workspace theTypeAlternative.xcworkspace -scheme theTypeAlternative test
```

Known: a handful of IntegrationTests/PerformanceTests are environment-dependent (they need real microphone/accessibility permission state and are sensitive to persisted UserDefaults) and may fail in clean CI environments.

## Code Quality Standards

### Critical Rules (Zero Tolerance)
1. **No Force Unwraps**: Never use `!` operator or implicitly unwrapped optionals—use proper optional handling
2. **No Code Duplication**: Extract methods, use pattern matching in switch statements
3. **Dependency Injection**: All dependencies must be injected, never use singleton access directly
4. **Weak References**: Always use `[weak self]` in closures to prevent retain cycles
5. **Single Source of Truth**: One reactive stream per data flow, use `.removeDuplicates()` to optimize
6. **Minimal Comments**: Keep comments minimal. Only add comments where logic isn't self-evident.

### Swift 6 Best Practices
- **Strict Concurrency**: All code passes Swift 6 concurrency checking
- **Sendable Conformance**: Types crossing actor boundaries must be Sendable
- **MainActor Isolation**: UI code explicitly marked with `@MainActor`
- **Async/Await**: Use modern concurrency over callbacks and completion handlers
- **Reactive Programming**: Combine for state management with proper operators

**See**: `docs/development/SWIFT_CODE_QUALITY_STANDARDS.md` for comprehensive guidelines

## HotkeyKit: Smart Energy-Efficient Hotkey System

- **🔴 PRIMED Mode**: Full event processing (~30 wake-ups/sec)
- **🟡 DORMANT Mode**: Minimal processing (~2-5 wake-ups/sec, 95% battery savings)
- **🔥 DICTATING Mode**: Active transcription with full resource utilization
- **Emergency Activation**: Instant transition from dormant to primed when hotkey detected (<10ms)
- **No Timer Dependencies**: Pure event-driven architecture

**See**: `docs/architecture/SMART_DORMANT_HOTKEY_SYSTEM.md` for technical details

## Core Implementation Requirements

### Permissions
The app requires two macOS permissions, both explained in the generated Info.plist:
1. **Microphone** (`NSMicrophoneUsageDescription`) — speech capture
2. **Accessibility** (`NSAccessibilityUsageDescription`) — text insertion + global hotkey

There is **no speech-recognition permission** — SpeechAnalyzer doesn't need one.

### State Management
- **Idle**: Not listening
- **Listening**: Actively transcribing speech
- **Error**: Permission denied or recognizer unavailable

### Text Insertion Strategy
- **Primary**: Accessibility API with verification to detect false positives (e.g., Safari address bar)
- **Secondary**: Keyboard simulation using Unicode string events
- **Fallback**: Clipboard with minimal synchronization for race condition prevention
- **Debug**: Menu bar strategy selector available in DEBUG builds

### Hotkey System Guidelines
- **Always maintain responsiveness**: Smart dormant mode ensures hotkey works even after inactivity
- **Avoid timer-based solutions**: Prefer event-driven state management
- **Emergency activation pattern**: Instant transition to full processing when hotkey detected

## Documentation References

### Architecture & Design
- `docs/architecture/SMART_DORMANT_HOTKEY_SYSTEM.md` - Hotkey energy optimization
- `docs/architecture/INSERTION_STRATEGY_BEHAVIOR.md` - Text insertion strategies
- `docs/architecture/FEATURE_SET_GUIDE.md` - FeatureSet configuration

### Development Guides
- `docs/development/SWIFT_CODE_QUALITY_STANDARDS.md` - Code quality rules (REQUIRED reading)
- `docs/development/SWIFT6_CONCURRENCY_FIXES.md` - Swift 6 migration notes
- `docs/development/DEBUG_CONFIGURATION_README.md` - Debug features and tools
- `docs/testing/TESTING_STRATEGY.md` - Testing approach and coverage

### Performance
- `docs/performance/PERFORMANCE_GUIDE.md` - Performance optimization techniques
