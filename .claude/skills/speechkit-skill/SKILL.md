---
name: speechkit-skill
description: Dual speech engine system with Apple SpeechAnalyzer (macOS 26) and optional WhisperKit. Use when working with speech recognition, audio capture, transcription, model management, engine selection, or on-device speech processing. Covers SpeechAnalyzer/SpeechTranscriber (primary), WhisperKit (optional, behind WhisperSupport.isEnabled), and the engine protocol.
---

# SpeechKit - On-Device Speech Recognition

## Overview

SpeechKit provides two fully on-device engines behind one protocol:

1. **AppleSpeechEngine** (`name: "System Speech"`, default) — Apple's **SpeechAnalyzer + SpeechTranscriber** API (macOS 26+). Long-form model, no session length limit, assets downloaded/managed by macOS system-wide.
2. **WhisperEngine** (`name: "WhisperKit Engine"`) — OpenAI Whisper via WhisperKit, models tiny/base/small/medium stored in `~/Library/Application Support/TheTypeAlternative`. Only exists when `WhisperSupport.isEnabled` (see below).

The deployment target is **macOS 26.0** — SpeechAnalyzer is used directly with no availability guards. There is NO SFSpeechRecognizer anywhere in the codebase, and no speech-recognition permission: **SpeechAnalyzer only needs microphone permission**.

## The Whisper Switch

```swift
// Modules/AppServices/Sources/Configuration/FeatureSet.swift
public enum WhisperSupport {
    public static let isEnabled = true
}
```

This is THE single switch. It feeds `FeatureSet.standard.supportsWhisperKit`, which gates:
- Engine creation in `SpeechEngineManager.recreateEngines` (never instantiates WhisperEngine when off)
- Engine picker options (`SpeechEngineSettings.updateAvailableOptions` → only `.appleSpeech`)
- Model management UI (`SpeechDetailView`, `ImprovedSettingsMainView` check `features.supportsWhisperKit`)

## Module Files

| File | Role |
|---|---|
| `SpeechRecognitionProtocol.swift` | `SpeechRecognitionEngine` + `SpeechRecognitionEngineDelegate` protocols, `ProcessingUnit`, `SpeechPermissionType` (microphone only), errors |
| `AppleSpeechEngine.swift` | SpeechAnalyzer engine (see lifecycle below) |
| `BufferConverter.swift` | AVAudioConverter wrapper — tap buffers → analyzer format (`primeMethod = .none`) |
| `WhisperEngine.swift` | WhisperKit engine: circular buffer, energy-threshold VAD, 2s chunked transcription |
| `SpeechRecognizer.swift` | Coordinator: picks engine via manager, forwards delegate callbacks, fallback engine on failure |
| `SpeechEngineManager.swift` | Engine lifecycle, reacts to settings changes, `selectBestEngine()` respects user preference order |
| `ModelManager.swift` / `ModelPaths.swift` | WhisperKit model download/status/storage |

## AppleSpeechEngine Lifecycle (SpeechAnalyzer)

The engine keeps the protocol's **sync** `startRecognition(delegate:) throws`; async setup runs in an internal Task and failures surface through `didFailWithError`.

**Start** (`beginSession()`):
1. `SpeechTranscriber.supportedLocale(equivalentTo:)` — locale check
2. `SpeechTranscriber(locale:transcriptionOptions:[], reportingOptions:[.volatileResults, .fastResults], attributeOptions:[.transcriptionConfidence])`
3. `AssetInventory.status(forModules:)` → `assetInstallationRequest(supporting:)` → `downloadAndInstall()` if missing (system-shared assets, usually already installed)
4. `SpeechAnalyzer(modules:[transcriber], options: .init(priority: .userInitiated, modelRetention: .processLifetime))` — retention keeps hotkey→first-result latency low
5. `SpeechAnalyzer.bestAvailableAudioFormat(compatibleWith:)` — MUST be after assets are installed (returns nil otherwise)
6. Results task starts consuming `transcriber.results` BEFORE audio is fed
7. `AVAudioEngine` tap (4096 frames) → `BufferConverter.convert` → `continuation.yield(AnalyzerInput(buffer:))` — the analyzer does NOT convert audio itself
8. `analyzer.start(inputSequence:)`

**Results assembly** (matches SpeechService's cumulative-text expectation):
- volatile result → `volatileText = text` (replaces previous volatile)
- final result → `finalizedText += text; volatileText = ""` (finals supersede volatiles for their audio range and never change)
- partial delegate callbacks send `finalizedText + volatileText` with `isFinal: false`

**Stop** (`stopRecognition()` → `finishSession()`):
1. remove tap, stop engine, `inputContinuation.finish()`
2. `analyzer.finalizeAndFinishThroughEndOfInput()` — flushes remaining audio into finals
3. `await resultsTask` — the results stream terminates after finish; do NOT cancel it early or trailing finals are lost
4. deliver ONE `isFinal: true` delegate callback with the full transcript → SpeechService inserts the text

**Errors**: the analyzer throws `SFSpeechError` codes (`noModel`, `assetLocaleNotAllocated`, `unexpectedAudioFormat`, `insufficientResources`, …). On a results-stream error the session is dead — tear down and recreate the engine for the next session.

**Gone with SFSpeech** (do not reintroduce): the ~60s session-chaining hack (long-form model has no task limit), `requiresOnDeviceRecognition` (always on-device), speech-recognition authorization, `NSSpeechRecognitionUsageDescription`.

## Result Flow (unchanged app-side)

```
Engine → SpeechRecognizer (SpeechRecognitionEngineDelegate)
       → SpeechService (SpeechRecognizerDelegate)
           partial → transcriptionStore.updateLiveTranscription (HUD preview)
           final   → TextInsertionDelegate (AppCoordinator) → textInserter.insertText
```

## Engine Selection & Language

- User preference (`SpeechEnginePreference`: auto / apple / whisper) stored in UserDefaults key `SpeechEnginePreference`
- Whisper model preference in `WhisperModelPreference` (tiny default)
- Recognition locale in UserDefaults key `SelectedLocaleIdentifier` (default en-US) — flows through `SettingsPublisher` (3-tuple: engine, model, locale) into BOTH engines: `AppleSpeechEngine.forLocale` and WhisperKit's `DecodingOptions.language` (ISO 639-1 code derived from the locale)
- The Settings → Speech language grid writes `SpeechEngineSettings.selectedLocaleIdentifier`; changing it recreates engines
- `SpeechEngineManager.bindToSettings(settings)` reacts to changes and recreates engines
- `selectBestEngine()`: preference order → availability (`SpeechTranscriber.isAvailable` for Apple) → microphone permission

## Testing Notes

- `AppleSpeechEngine` unit tests cover name/permissions/configuration/factories; live transcription needs mic + installed assets, so keep session tests out of CI
- Mock engines conform to `SpeechRecognitionEngine`; the delegate default extension makes `processingUnits` optional to implement

## Related Skills
- **app-architecture-skill**: Module graph and DI
- **permissionkit-skill**: Microphone/accessibility permission handling
- **settings-ui-skill**: Engine picker and model management UI
