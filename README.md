# AltType

**Voice to text, instantly. Private. On-device. Open source.**

AltType is a native macOS menu bar app that turns your voice into text — right where you need it. Hold a hotkey (default: `fn`), speak, release, and the transcribed text is inserted into whatever app you're typing in. All speech processing happens on your device; your voice never leaves your computer.

### [⬇ Download AltType 1.1.0 (.dmg)](https://github.com/saianvesh3636/AltType/releases/download/v1.1.0/AltType-1.1.0.dmg)

Signed and notarized by Apple. Requires macOS 26 (Tahoe) or later. All versions on the [Releases page](../../releases).

## Features

- **System-Wide Dictation** — works in any app with text input
- **On-Device Speech Recognition** — built on Apple's SpeechAnalyzer (the long-form model behind Notes and Voice Memos on macOS 26)
- **Optional WhisperKit Engine** — switch to OpenAI Whisper models (tiny → medium) running locally via [WhisperKit](https://github.com/argmaxinc/WhisperKit)
- **Privacy-First** — no cloud, no servers, no accounts, no analytics, no audio ever leaves your device
- **Smart Text Insertion** — Accessibility API with keyboard-simulation and clipboard fallbacks, so insertion works across stubborn apps
- **Energy Efficient** — event-driven dormant hotkey system keeps idle battery impact near zero
- **Free and Open Source** — no tiers, no limits, no subscriptions

## Install

1. **[Download AltType-1.1.0.dmg](https://github.com/saianvesh3636/AltType/releases/download/v1.1.0/AltType-1.1.0.dmg)** (or grab the latest from [Releases](../../releases))
2. Open the DMG and drag **AltType** into **Applications**
3. Launch it — macOS will ask for Microphone and Accessibility permissions, and the app walks you through both

Prefer building from source? See [Building](#building).

## Requirements

- **macOS 26 (Tahoe) or later** — the app uses the SpeechAnalyzer API introduced in macOS 26
- Xcode 26+ and [Tuist](https://tuist.dev) to build from source
- Microphone permission (dictation) and Accessibility permission (text insertion + global hotkey)

## Building

```bash
# Install dependencies and generate the Xcode project
tuist install
tuist generate

# Build from the command line…
xcodebuild -workspace theTypeAlternative.xcworkspace \
  -scheme theTypeAlternative build

# …or just open the workspace and hit Run
open theTypeAlternative.xcworkspace
```

To distribute signed builds, set `DEVELOPMENT_TEAM` in `XCConfig/Shared.xcconfig` to your own team ID. For local development, automatic signing works as-is.

```bash
# Run the test suite
xcodebuild -workspace theTypeAlternative.xcworkspace \
  -scheme theTypeAlternative test
```

## Speech Engines

AltType ships with two on-device engines:

| Engine | Model | Notes |
|---|---|---|
| **System Speech** (default) | Apple SpeechAnalyzer / SpeechTranscriber | Long-form model, no session length limit, assets are downloaded and managed by macOS |
| **WhisperKit** | OpenAI Whisper (tiny/base/small/medium) | Models download on demand and are stored in `~/Library/Application Support/TheTypeAlternative` |

### The Whisper switch

WhisperKit support is controlled by **one flag**:

```swift
// Modules/AppServices/Sources/Configuration/FeatureSet.swift
public enum WhisperSupport {
    public static let isEnabled = true   // set to false to build without any WhisperKit UI
}
```

Set it to `false` and the engine picker, model management UI, and model downloads disappear — the app becomes SpeechAnalyzer-only. Nothing else needs to change.

### Accuracy & speed guidance

- **Set the recognition language first** (Settings → Speech). It applies to both engines, and a mismatched language hurts accuracy far more than any engine choice.
- **System Speech** is the recommended default: best accuracy-to-speed balance, instant start, no session length limit.
- **WhisperKit tiny/base** are the fastest Whisper options with modest accuracy; **small/medium** are noticeably more accurate for heavy accents, jargon, and noisy rooms, at the cost of speed and download size.

There is one scheme (`theTypeAlternative`): Run and Test use the Debug configuration, Profile and Archive use Release. For an optimized daily-driver binary, use Product → Archive or `xcodebuild -configuration Release build`.

## Architecture

A modular Swift 6 / SwiftUI app managed by Tuist:

- `theTypeAlternative` — app target: lifecycle, menu bar, settings, onboarding
- `AppServices` — protocol layer and shared types (all DI flows through here)
- `HotkeyKit` — energy-efficient global hotkey engine (dormant/primed event tap)
- `SpeechKit` — speech engines (SpeechAnalyzer + WhisperKit), engine selection, model management
- `TextInsertionKit` — multi-strategy text insertion (Accessibility API → keyboard simulation → clipboard)
- `PermissionKit` — microphone + accessibility permission state, reactive monitoring
- `BuildConfiguration`, `FeatureFlags` — build environment and runtime flags
- `FullAppConfiguration` — dependency-injection bootstrap

## Privacy

AltType is built on a simple promise: **your voice stays on your device**. The app collects nothing — no audio, no transcripts, no telemetry. See [PRIVACY_POLICY.md](PRIVACY_POLICY.md).

## License

[MIT](LICENSE)
