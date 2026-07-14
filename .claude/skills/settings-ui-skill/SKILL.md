---
name: settings-ui-skill
description: Settings page UI and configuration management. Use when working with app settings, preferences UI, hotkey configuration, speech engine settings, appearance preferences, or storage management. Covers ModularSettingsView, HotkeySettings, SpeechEngineSettings, AppearanceDetailView, and SystemSettingsComponents.
---

# Settings UI - Configuration Interface

## Overview

Comprehensive settings UI with modular organization and macOS-native design patterns.

**Location**: `theTypeAlternative/Sources/`

**Key Components**:
- `ModularSettingsView.swift` - Main settings container
- `HotkeySettings.swift` - Hotkey customization UI
- `SpeechEngineSettings.swift` - Engine selection and model management
- `AppearanceDetailView.swift` - Theme and appearance preferences
- `StorageDetailView.swift` - Model storage management
- `SystemSettingsComponents.swift` - macOS-style components

## ModularSettingsView

```swift
struct ModularSettingsView: View {
    var body: some View {
        TabView {
            HotkeySettings()
                .tabItem {
                    Label("Hotkey", systemImage: "keyboard")
                }

            SpeechEngineSettings()
                .tabItem {
                    Label("Speech Engine", systemImage: "waveform")
                }

            AppearanceDetailView()
                .tabItem {
                    Label("Appearance", systemImage: "paintbrush")
                }

            StorageDetailView()
                .tabItem {
                    Label("Storage", systemImage: "internaldrive")
                }
        }
        .frame(minWidth: 600, minHeight: 400)
    }
}
```

## HotkeySettings

```swift
struct HotkeySettings: View {
    @StateObject private var hotkeyManager = HotkeyManager.shared
    @State private var isRecording = false

    var body: some View {
        Form {
            Section("Activation Hotkey") {
                HStack {
                    Text(hotkeyManager.currentHotkeyDescription)
                        .font(.system(.body, design: .monospaced))

                    Spacer()

                    Button(isRecording ? "Press Keys..." : "Record") {
                        isRecording.toggle()
                    }
                }

                Text("Press the key combination you want to use for dictation")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }
}
```

## SpeechEngineSettings

```swift
struct SpeechEngineSettings: View {
    @StateObject private var engineSelector = SpeechEngineSelector.shared
    @State private var selectedEngine: SpeechEngineType = .appleSpeech

    var body: some View {
        Form {
            Section("Speech Engine") {
                Picker("Engine", selection: $selectedEngine) {
                    Text("Apple Speech (Recommended)").tag(SpeechEngineType.appleSpeech)

                    if engineSelector.isProUser {
                        Text("WhisperKit").tag(SpeechEngineType.whisperKit)
                    }
                }

                if selectedEngine == .whisperKit {
                    ModelManagementView()
                }
            }
        }
    }
}

struct ModelManagementView: View {
    @StateObject private var modelManager = ModelManager.shared

    var body: some View {
        List {
            ForEach(WhisperModelSize.allCases, id: \.self) { size in
                HStack {
                    VStack(alignment: .leading) {
                        Text(size.displayName)
                        Text(size.fileSize)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    Spacer()

                    if modelManager.isDownloaded(size) {
                        Button("Delete") {
                            modelManager.delete(size)
                        }
                    } else {
                        Button("Download") {
                            Task {
                                await modelManager.download(size)
                            }
                        }
                    }
                }
            }
        }
    }
}
```

## macOS-Native Design Patterns

```swift
// Use Form for settings layouts
Form {
    Section("Section Title") {
        // Settings controls
    }
}

// Use native pickers
Picker("Option", selection: $value) {
    Text("Choice 1").tag(1)
    Text("Choice 2").tag(2)
}
.pickerStyle(.radioGroup) // macOS-native radio buttons

// Use Toggle for boolean settings
Toggle("Enable Feature", isOn: $isEnabled)

// Use native button styles
Button("Action") { }
    .controlSize(.large)
    .buttonStyle(.borderedProminent)
```

## Related Skills
- **hotkeykit-skill**: Hotkey configuration
- **speechkit-skill**: Engine selection
- **theme-appearance-skill**: Appearance preferences
