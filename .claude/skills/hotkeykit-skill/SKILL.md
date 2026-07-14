---
name: hotkeykit-skill
description: Smart energy-efficient hotkey management system with dual-mode event processing. Use when working with hotkey detection, event taps, keyboard monitoring, dormant mode optimization, or energy-efficient system integration. Covers state management (PRIMED/DORMANT/DICTATING), emergency activation patterns, and universal hotkey support.
---

# HotkeyKit - Smart Dormant Hotkey System

## Overview

HotkeyKit implements a sophisticated dual-mode event processing system that maintains hotkey responsiveness while dramatically reducing battery usage through intelligent state management. The system achieves **85-90% reduction** in wake-ups during dormant periods while maintaining **sub-100ms activation** when the hotkey is pressed.

**Module Location**: `Modules/HotkeyKit/`

**Key Components**:
- `HotkeyManager.swift` - Core state management and event tap handling
- `HotkeyRecorder.swift` - User hotkey configuration and recording
- `KeyCodeMapping.swift` - Key code to character mapping

**Full Documentation**: `docs/architecture/SMART_DORMANT_HOTKEY_SYSTEM.md`

## The Problem & Solution

### Traditional Dilemma
- **Always-On Systems**: ~30 wake-ups/sec continuously = significant battery drain
- **Sleep-Mode Systems**: 0 wake-ups/sec = broken hotkey responsiveness

### Smart Dormant Solution: Traffic Light Approach 🚦

```
🟢 PRIMED Mode:     Full event processing (~30 wake-ups/sec)
                    Active during recent user interaction

🟡 DORMANT Mode:    Minimal processing (~2-5 wake-ups/sec)
                    Maintains hotkey responsiveness with 85-90% battery savings

🔴 DICTATING Mode:  Maximum resource utilization
                    Justified during active transcription
```

## Key Architecture Principles

### 1. Single Persistent Event Tap
- **NO event tap recreation** during state transitions
- Single `CGEventTap` maintained across all states
- State-aware processing logic inside the callback

### 2. Event-Driven State Management
- **NO timers** for state transitions (violates No Timer Policy)
- Pure reactive state changes based on event detection
- Efficient filtering using existing `requiredKeysSet.contains()` logic

### 3. Universal Hotkey Support
- Works with **any user-configured key combination**
- Not hardcoded to specific keys (Fn, Option+Space, etc.)
- Dynamic configuration without system restart

## Core Implementation Patterns

### State-Aware Event Tap Callback

```swift
// Single event tap callback with state-aware processing
callback: { (proxy, type, event, refcon) -> Unmanaged<CGEvent>? in
    let manager = Unmanaged<HotkeyManager>.fromOpaque(refcon).takeUnretainedValue()

    // State-aware processing switch
    if manager.managerState == .dormant {
        return manager.handleDormantMode(type: type, event: event)  // Minimal processing
    } else {
        return manager.handleFullMode(type: type, event: event)     // Complete processing
    }
}
```

**Key Points**:
- ✅ Single event tap for all states
- ✅ State-based routing of processing logic
- ✅ No overhead from tap recreation
- ✅ Seamless transitions

### Dormant Mode Processing

```swift
private func handleDormantMode(type: CGEventType, event: CGEvent) -> Unmanaged<CGEvent>? {
    // Only process key down events (99% of events ignored immediately)
    guard type == .keyDown else { return Unmanaged.passRetained(event) }

    let keyCode = UInt16(event.getIntegerValueField(.keyboardEventKeycode))

    // REUSE EXISTING FILTERING: Only check registered hotkey keys
    guard requiredKeysSet.contains(keyCode) else {
        return Unmanaged.passRetained(event)
    }

    // EMERGENCY ACTIVATION: Instant transition to full processing (<10ms)
    emergencyActivation(detectedKey: keyCode)

    // Process this event with full logic immediately
    return handleFullMode(type: type, event: event)
}
```

**Optimization Strategy**:
1. **Early exit**: Non-keyDown events passed through immediately
2. **Efficient filtering**: `Set.contains()` is O(1) operation
3. **Minimal overhead**: ~5 operations per relevant event
4. **Instant activation**: Emergency transition on hotkey detection

### Emergency Activation Pattern

```swift
private func emergencyActivation(detectedKey: UInt16) {
    debugLog("🔴 EMERGENCY: Activated full processing for key \(detectedKey)")

    // NO event tap recreation - just change state
    managerState = .primed

    // Reset state for clean hotkey detection
    pressedRequiredKeys.removeAll(keepingCapacity: true)
    _isActive = false
    lastFlagsValue = 0
    previousModifierState.removeAll()

    // Stay primed longer since user is actively using
    scheduleSingleDormancyCheck()
}
```

**Critical Rules**:
- ❌ NEVER recreate the event tap during activation
- ✅ Only change state and reset tracking variables
- ✅ Maintain capacity when clearing collections (performance)
- ✅ Schedule dormancy check for future transition back

### Smart Dormant Transition

```swift
public func transitionToDormantMode(reason: String) {
    debugLog("🟡 Smart DORMANT mode: \(reason) - maintaining hotkey responsiveness")

    // DON'T disable event tap - just change processing behavior
    // Event tap continues running but with minimal processing overhead

    managerState = .dormant
    debugLog("🟡 DORMANT: Event tap active with minimal processing - hotkey still works")
}
```

**Never Do This**:
```swift
// ❌ BAD: Recreating event tap
func transitionToDormantMode() {
    eventTap?.disable()  // ❌ WRONG
    eventTap = nil       // ❌ WRONG
    createNewEventTap()  // ❌ WRONG - expensive and unnecessary
}
```

## State Management

### State Definitions

```swift
enum ManagerState {
    case primed     // Full processing - recently active or during use
    case dormant    // Minimal processing - background operation
    case dictating  // Maximum resources - active transcription
}
```

### State Transitions

```
PRIMED → DORMANT:    After inactivity period (scheduleSingleDormancyCheck)
DORMANT → PRIMED:    On hotkey detection (emergencyActivation)
PRIMED → DICTATING:  On transcription start
DICTATING → PRIMED:  On transcription end
```

### Dormancy Check Pattern

```swift
private func scheduleSingleDormancyCheck() {
    // Single-shot check, not a repeating timer
    DispatchQueue.main.asyncAfter(deadline: .now() + dormancyDelay) { [weak self] in
        self?.checkIfShouldTransitionToDormant()
    }
}

private func checkIfShouldTransitionToDormant() {
    // Only transition if still not active and not dictating
    guard managerState != .dictating && !_isActive else { return }
    transitionToDormantMode(reason: "Inactivity detected")
}
```

**Important**:
- ✅ Single-shot dispatch, not a repeating timer
- ✅ Weak self to prevent retain cycles
- ✅ Guards to prevent invalid state transitions
- ❌ Never use `Timer.scheduledTimer` (violates No Timer Policy)

## Performance Metrics

### Resource Usage

| State | Wake-ups/sec | CPU Usage | Battery Impact |
|-------|-------------|-----------|----------------|
| DORMANT | 2-5 | <1% | Minimal |
| PRIMED | ~30 | 2-5% | Moderate |
| DICTATING | ~30 | 5-15% | Justified |

### Efficiency Gains
- **99% of events ignored** in dormant mode (early exit)
- **~5 operations** per relevant event in dormant mode
- **<10ms activation** time on hotkey press
- **85-90% reduction** in wake-ups during dormant periods

### Memory Footprint
- **Same as before**: No additional memory overhead
- **Single event tap**: No duplicate resources
- **Stateless transitions**: Minimal state management overhead

## Common Patterns

### Registering a Hotkey

```swift
let hotkeyManager = HotkeyManager()

// Set the hotkey combination
hotkeyManager.setHotkey(
    keyCode: 0x3A,  // Key code (e.g., Option)
    modifiers: [],   // Modifier flags if needed
    enabled: true
)

// Subscribe to activation events
hotkeyManager.activationPublisher
    .sink { isActive in
        if isActive {
            print("Hotkey activated!")
            // Start dictation, etc.
        } else {
            print("Hotkey deactivated!")
            // Stop dictation, etc.
        }
    }
    .store(in: &cancellables)
```

### State Transitions

```swift
// Transition to dictating (e.g., when starting transcription)
hotkeyManager.transitionToDictatingMode()

// Transition to primed (e.g., when stopping transcription)
hotkeyManager.transitionToPrimedMode(reason: "Transcription ended")

// Automatic dormant transition (handled internally after inactivity)
// No manual call needed - happens automatically
```

### Debug Logging

```swift
#if DEBUG
hotkeyManager.enableDebugLogging = true
#endif

// Logs will show:
// 🟢 PRIMED mode: User interaction detected
// 🟡 Smart DORMANT mode: Inactivity detected - maintaining hotkey responsiveness
// 🔴 EMERGENCY: Activated full processing for key 58
```

## Integration with Other Modules

### With SpeechKit

```swift
// When starting transcription
speechRecognizer.startRecording()
hotkeyManager.transitionToDictatingMode()  // Full resources justified

// When stopping transcription
speechRecognizer.stopRecording()
hotkeyManager.transitionToPrimedMode(reason: "Transcription ended")
// Will auto-transition to dormant after inactivity
```

### With BuildConfiguration

```swift
#if DEBUG
// Debug builds: More verbose logging
hotkeyManager.enableDebugLogging = true
hotkeyManager.dormancyDelay = 5.0  // Shorter delay for testing
#else
// Release builds: Minimal logging
hotkeyManager.dormancyDelay = 30.0  // Longer delay for battery savings
#endif
```

## Critical Rules & Best Practices

### Do's ✅

1. **Use the single event tap pattern**: Never recreate event taps during state transitions
2. **Leverage existing filtering**: Reuse `requiredKeysSet.contains()` for efficiency
3. **Event-driven architecture**: Use event detection for state changes
4. **Weak self in closures**: Always use `[weak self]` in async closures
5. **Early exit patterns**: Return immediately for irrelevant events
6. **State guards**: Protect against invalid state transitions

### Don'ts ❌

1. **NEVER use repeating timers**: Violates No Timer Policy
2. **NEVER recreate event taps**: Use state-aware processing instead
3. **NEVER process all events in dormant**: Only check registered keys
4. **NEVER hardcode specific keys**: Support universal hotkey configuration
5. **NEVER skip weak self**: Prevent retain cycles in async code
6. **NEVER use force unwraps**: Proper optional handling required

## Troubleshooting

### Hotkey Not Responding After Inactivity
- **Check**: Is dormant mode properly handling the hotkey key code?
- **Verify**: `requiredKeysSet` contains the correct key code
- **Debug**: Enable debug logging to see emergency activation

### High CPU Usage in Dormant Mode
- **Check**: Are you processing all events instead of just keyDown?
- **Verify**: Early exit pattern is working for non-keyDown events
- **Debug**: Log how many events are being processed

### Event Tap Stops Working
- **Check**: Did you accidentally disable/recreate the event tap?
- **Verify**: Single event tap is maintained across state transitions
- **Debug**: Check if event tap is still active

### State Stuck in Primed Mode
- **Check**: Is dormancy check being scheduled?
- **Verify**: No active dictation session preventing transition
- **Debug**: Log state transition calls

## Testing Strategies

### Unit Tests
- Mock event tap creation and state tracking
- Verify state transitions under different conditions
- Test emergency activation logic
- Verify efficiency metrics (event filtering)

### Integration Tests
- Test with actual hotkey presses after long inactivity
- Measure CPU usage in each state
- Verify battery impact over time
- Test with various hotkey combinations

### Performance Tests
- Measure activation latency (<10ms requirement)
- Track wake-up frequency in dormant mode
- Monitor memory footprint across states

## When to Use This Skill

**Use this skill when**:
- Implementing or modifying hotkey detection logic
- Optimizing battery usage for system-wide event monitoring
- Debugging hotkey responsiveness issues
- Adding new states or transitions to HotkeyKit
- Understanding energy-efficient event processing patterns
- Working with CGEventTap and system-level keyboard monitoring

**Reference the main documentation** (`SMART_DORMANT_HOTKEY_SYSTEM.md`) for:
- Detailed architecture diagrams
- Performance benchmarks and measurements
- Implementation history and decision rationale
- Future enhancement roadmap

## Related Skills

- **speechkit-skill**: Integration with transcription engine selection
- **energy-performance-skill**: Battery optimization strategies
- **development-standards-skill**: Swift 6 patterns and best practices
- **debug-tools-skill**: Debug logging and testing utilities
