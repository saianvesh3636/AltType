---
name: user-feedback-skill
description: User feedback mechanisms including menu bar icon, contextual indicators, HUD, and audio cues. Use when working with visual feedback, menu bar UI, dictation indicators, on-screen notifications, or audio feedback. Covers dynamic state indication and AXFrame positioning.
---

# User Feedback - Visual & Audio Cues

## Overview

Four feedback mechanisms provide real-time state indication to users:

1. **Menu Bar Icon** - Dynamic state indication (idle/listening/error)
2. **Contextual Dictation Indicator** - Animated dot near active text field
3. **On-Screen HUD** - Transient start/stop confirmations
4. **Auditory Cues** - Optional sound feedback

**Location**: `theTypeAlternative/Sources/`

**Key Component**: `MenuBarView.swift`

## 1. Menu Bar Icon (Dynamic State)

```swift
struct MenuBarView: View {
    @StateObject private var speechRecognizer: SpeechRecognizer

    var body: some View {
        HStack {
            Image(systemName: iconName)
                .foregroundColor(iconColor)

            if speechRecognizer.isRecording {
                Text("Recording...")
            }
        }
    }

    private var iconName: String {
        switch speechRecognizer.state {
        case .idle:
            return "mic.fill"
        case .listening:
            return "waveform"
        case .error:
            return "exclamationmark.triangle.fill"
        }
    }

    private var iconColor: Color {
        switch speechRecognizer.state {
        case .idle:
            return .primary
        case .listening:
            return .green
        case .error:
            return .red
        }
    }
}
```

## 2. Contextual Dictation Indicator

**Animated dot positioned near active text field using AXFrame coordinates**:

```swift
struct ContextualIndicator: View {
    let position: CGPoint // From AXFrame of focused element

    var body: some View {
        Circle()
            .fill(Color.green)
            .frame(width: 12, height: 12)
            .position(position)
            .overlay(
                Circle()
                    .stroke(Color.white, lineWidth: 2)
            )
            .animation(.easeInOut(duration: 0.8).repeatForever(), value: isAnimating)
    }
}

// Get position from focused element
func getFocusedElementPosition() -> CGPoint? {
    guard let element = getFocusedElement() else { return nil }

    var frameValue: CFTypeRef?
    AXUIElementCopyAttributeValue(element, kAXFrameAttribute as CFString, &frameValue)

    guard let frame = frameValue as? CGRect else { return nil }

    // Position indicator near text field
    return CGPoint(x: frame.minX, y: frame.minY - 20)
}
```

## 3. On-Screen HUD

```swift
struct TranscriptionHUD: View {
    let message: String
    @State private var isShowing = true

    var body: some View {
        if isShowing {
            VStack {
                Text(message)
                    .padding()
                    .background(.thinMaterial)
                    .cornerRadius(8)
            }
            .transition(.scale.combined(with: .opacity))
            .onAppear {
                DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                    withAnimation {
                        isShowing = false
                    }
                }
            }
        }
    }
}
```

## 4. Auditory Cues (Optional)

```swift
import AVFoundation

class AudioFeedback {
    private let startSound = NSSound(named: "start_dictation")
    private let stopSound = NSSound(named: "stop_dictation")

    func playStartSound() {
        guard UserDefaults.standard.bool(forKey: "audioFeedbackEnabled") else { return }
        startSound?.play()
    }

    func playStopSound() {
        guard UserDefaults.standard.bool(forKey: "audioFeedbackEnabled") else { return }
        stopSound?.play()
    }
}
```

## Integration

```swift
// When starting dictation
func startDictation() {
    // 1. Update menu bar icon
    menuBarManager.setState(.listening)

    // 2. Show contextual indicator
    showContextualIndicator(at: getFocusedElementPosition())

    // 3. Show HUD
    showHUD(message: "Listening...")

    // 4. Play audio (if enabled)
    audioFeedback.playStartSound()

    // Start actual recording
    speechRecognizer.startRecording()
}
```

## Related Skills
- **hotkeykit-skill**: State coordination
- **speechkit-skill**: Recording state
- **theme-appearance-skill**: UI colors
