---
name: permissionkit-skill
description: Microphone and accessibility permission management with reactive state updates. Use when working with system permissions, authorization flows, permission UI, or access control. Covers permission checking, requesting, and state monitoring for microphone and accessibility APIs.
---

# PermissionKit - Permission Management

## Overview

PermissionKit manages two critical macOS permissions:
1. **Microphone Access** - Required for audio capture
2. **Accessibility Access** - Required for text insertion

**Module Location**: `Modules/PermissionKit/`

**Key Component**: `PermissionManager.swift`

## The Two Permission Types

### 1. Microphone Permission

**Required For**: Audio capture, speech recognition

```swift
import AVFoundation

func checkMicrophonePermission() -> AVAudioSession.RecordPermission {
    return AVAudioSession.sharedInstance().recordPermission
}

func requestMicrophonePermission() async -> Bool {
    await withCheckedContinuation { continuation in
        AVAudioSession.sharedInstance().requestRecordPermission { granted in
            continuation.resume(returning: granted)
        }
    }
}
```

**States**:
- `.undetermined` - Not yet requested
- `.granted` - User approved
- `.denied` - User denied

### 2. Accessibility Permission

**Required For**: Text insertion, system-wide keyboard monitoring

```swift
import ApplicationServices

func checkAccessibilityPermission() -> Bool {
    let options: NSDictionary = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: false]
    return AXIsProcessTrustedWithOptions(options)
}

func requestAccessibilityPermission() {
    // Open System Settings to accessibility pane
    let options: NSDictionary = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true]
    _ = AXIsProcessTrustedWithOptions(options)
}
```

**Note**: Accessibility permission requires manual approval in System Settings.

## PermissionManager

```swift
public class PermissionManager: ObservableObject {
    @Published public private(set) var microphoneStatus: PermissionStatus = .notDetermined
    @Published public private(set) var accessibilityStatus: PermissionStatus = .notDetermined

    public enum PermissionStatus {
        case notDetermined
        case granted
        case denied
    }

    public func checkAllPermissions() {
        microphoneStatus = checkMicrophoneStatus()
        accessibilityStatus = checkAccessibilityStatus()
    }

    public func requestMicrophonePermission() async -> Bool {
        let granted = await AVAudioSession.sharedInstance().requestRecordPermission()
        await MainActor.run {
            microphoneStatus = granted ? .granted : .denied
        }
        return granted
    }

    public func requestAccessibilityPermission() {
        let options: NSDictionary = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true]
        _ = AXIsProcessTrustedWithOptions(options)
        // User must manually approve in System Settings
    }
}
```

## Integration with Onboarding

```swift
// During onboarding
func setupPermissions() async {
    let permissionManager = PermissionManager()

    // Request microphone first
    let micGranted = await permissionManager.requestMicrophonePermission()
    guard micGranted else {
        showMicrophoneDeniedAlert()
        return
    }

    // Request accessibility
    permissionManager.requestAccessibilityPermission()
    showAccessibilityInstructions()  // Guide user through System Settings
}
```

## Info.plist Requirements

```xml
<key>NSMicrophoneUsageDescription</key>
<string>AltType captures audio to transcribe your speech into text. Your voice never leaves your Mac.</string>

<key>NSAccessibilityUsageDescription</key>
<string>AltType requires permission to insert the transcribed text into other applications. It is only used to type on your behalf when you are dictating.</string>

<key>NSSpeechRecognitionUsageDescription</key>
<string>AltType uses on-device speech recognition to convert your voice to text. No audio data is sent to external servers.</string>
```

## Monitoring Permission Changes

```swift
// Poll for accessibility changes (no native notification)
class PermissionMonitor {
    private var timer: Timer?

    func startMonitoring(interval: TimeInterval = 1.0) {
        timer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { [weak self] _ in
            self?.checkPermissionChanges()
        }
    }

    func checkPermissionChanges() {
        let hasAccess = AXIsProcessTrustedWithOptions(nil)
        if hasAccess != previousAccessibilityState {
            // Permission changed!
            handlePermissionChange(hasAccess)
        }
    }
}
```

## Critical Rules & Best Practices

### Do's ✅

1. **Request microphone before accessibility**: Better UX flow
2. **Provide clear explanations**: Users need to understand why
3. **Monitor permission state**: Handle revocation gracefully
4. **Use async/await**: Modern permission requests

### Don'ts ❌

1. **NEVER proceed without permissions**: App won't work
2. **NEVER spam permission requests**: Respect user choices
3. **NEVER use misleading descriptions**: Be honest about usage

## When to Use This Skill

Use this skill when working with permission flows, onboarding, or access control.

## Related Skills

- **onboarding-skill**: Permission request flows
- **speechkit-skill**: Microphone permission usage
- **textinsertionkit-skill**: Accessibility permission usage
