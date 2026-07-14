---
name: textinsertionkit-skill
description: Multi-strategy text insertion system with intelligent fallback. Use when working with text insertion, accessibility API, keyboard simulation, clipboard operations, or cross-application compatibility. Covers three strategies (Accessibility, Keyboard, Pasteboard) with priority-based selection and universal application support.
---

# TextInsertionKit - Multi-Strategy Text Insertion

## Overview

TextInsertionKit implements a **priority-based fallback system** that works with ANY macOS application through three strategies:

1. **Accessibility API** (Priority 100) - Fast, direct text insertion
2. **Keyboard Simulation** (Priority 90) - Universal, types like user would
3. **Pasteboard** (Priority 80) - Ultimate fallback, works everywhere

**Module Location**: `Modules/TextInsertionKit/`

**Key Component**: `UniversalTextInserter.swift`

**Full Documentation**: `docs/architecture/INSERTION_STRATEGY_BEHAVIOR.md`

## The Three Strategies

### 1. Accessibility API Strategy (Priority 100)

**Best For**: Text fields, search bars, native UI elements

```swift
// Direct value injection via AXUIElement
func insertViaAccessibility(text: String, element: AXUIElement) -> Bool {
    var value: CFTypeRef?
    let result = AXUIElementCopyAttributeValue(element, kAXValueAttribute as CFString, &value)

    guard result == .success else { return false }

    // Set new value
    let newValue = text as CFTypeRef
    let setResult = AXUIElementSetAttributeValue(element, kAXValueAttribute as CFString, newValue)

    return setResult == .success
}
```

**Advantages**:
- ✅ Fastest method (no delay)
- ✅ Doesn't disturb other UI state
- ✅ Works with most native macOS controls

**Limitations**:
- ❌ Doesn't work with terminals
- ❌ May fail with custom text editors
- ❌ Requires AXValueAttribute support

### 2. Keyboard Simulation Strategy (Priority 90)

**Best For**: Terminals, code editors, any app accepting keyboard input

```swift
// Simulate typing via CGEvent
func insertViaKeyboard(text: String) {
    let source = CGEventSource(stateID: .hidSystemState)

    for character in text.utf16 {
        let keyDown = CGEvent(keyboardEventSource: source, virtualKey: 0, keyDown: true)
        keyDown?.keyboardSetUnicodeString(stringLength: 1, unicodeString: [character])
        keyDown?.post(tap: .cghidEventTap)

        let keyUp = CGEvent(keyboardEventSource: source, virtualKey: 0, keyDown: false)
        keyUp?.keyboardSetUnicodeString(stringLength: 1, unicodeString: [character])
        keyUp?.post(tap: .cghidEventTap)
    }
}
```

**Advantages**:
- ✅ Works with terminals and code editors
- ✅ Triggers app keyboard handlers
- ✅ Universal compatibility

**Limitations**:
- ⚠️ Slightly slower (simulates typing)
- ⚠️ May trigger auto-complete/suggestions

### 3. Pasteboard Strategy (Priority 80)

**Best For**: Ultimate fallback when other strategies fail

```swift
// Copy to clipboard + Cmd+V
func insertViaPasteboard(text: String) {
    // Save original clipboard
    let originalContents = NSPasteboard.general.string(forType: .string)

    // Set new clipboard content
    NSPasteboard.general.clearContents()
    NSPasteboard.general.setString(text, forType: .string)

    // Simulate Cmd+V
    simulateCommandV()

    // Restore clipboard after 1ms (race condition prevention)
    DispatchQueue.main.asyncAfter(deadline: .now() + 0.001) {
        if let original = originalContents {
            NSPasteboard.general.setString(original, forType: .string)
        }
    }
}
```

**Advantages**:
- ✅ Works with ANY app that supports paste
- ✅ Ultimate fallback - always works

**Limitations**:
- ⚠️ Briefly disrupts clipboard
- ⚠️ Requires 1ms delay for race condition handling

## Automatic Strategy Selection

```swift
public class UniversalTextInserter {
    private var strategies: [InsertionStrategy] = [
        AccessibilityAPIStrategy(priority: 100),
        KeyboardSimulationStrategy(priority: 90),
        PasteboardStrategy(priority: 80)
    ]

    public func insertText(_ text: String) -> Bool {
        guard let focusedElement = getFocusedElement() else {
            return false
        }

        // Try strategies in priority order
        for strategy in strategies.sorted(by: { $0.priority > $1.priority }) {
            if strategy.canHandle(element: focusedElement) {
                return strategy.insert(text: text, element: focusedElement)
            }
        }

        return false
    }
}
```

## Future-Proof Design

**No Hardcoded Bundle IDs Required**:

```swift
// ✅ Good: Tests actual capabilities
func canHandle(element: AXUIElement) -> Bool {
    var value: CFTypeRef?
    let result = AXUIElementCopyAttributeValue(element, kAXValueAttribute as CFString, &value)
    return result == .success
}

// ❌ Bad: Hardcoded bundle checks (unnecessary)
func canHandle(bundleID: String) -> Bool {
    return bundleID == "com.apple.Terminal" // Too restrictive!
}
```

**New Apps Work Automatically**:
- New terminal app? → Falls back to keyboard simulation ✅
- New text editor? → Tests accessibility, falls back if needed ✅
- Unknown app? → Pasteboard as ultimate fallback ✅

## Performance Optimizations (Optional)

**Known App Bundle IDs** (for instant strategy selection):

```swift
private let knownTerminalBundleIDs: Set<String> = [
    "com.apple.Terminal",
    "com.googlecode.iterm2",
    "com.github.wez.wezterm",
    "net.kovidgoyal.kitty"
]

func selectStrategy(for bundleID: String) -> InsertionStrategy {
    // Performance optimization: Skip accessibility test for known terminals
    if knownTerminalBundleIDs.contains(bundleID) {
        return KeyboardSimulationStrategy()
    }

    // Default: Test capabilities
    return selectStrategyByCapabilities()
}
```

**Note**: This is purely for performance - fallback chain ensures functionality without it.

## Debug Strategy Selector

**Available in DEBUG builds**:

```swift
#if DEBUG
enum DebugInsertionStrategy {
    case automatic  // Normal priority-based selection
    case forceAccessibility
    case forceKeyboard
    case forcePasteboard
}

var debugStrategy: DebugInsertionStrategy = .automatic
#endif
```

## Integration with Other Modules

### With SpeechKit

```swift
func speechRecognizer(_ recognizer: SpeechRecognizer, didRecognize text: String) {
    let success = textInserter.insertText(text)

    if !success {
        // Log failure for debugging
        logger.error("Failed to insert text: \(text)")
    }
}
```

### With HotkeyKit

```swift
// Ensure text insertion happens after hotkey release
hotkeyManager.activationPublisher
    .sink { [weak self] isActive in
        if !isActive {
            // Hotkey released, safe to insert text
            self?.insertPendingText()
        }
    }
    .store(in: &cancellables)
```

## Common Patterns

### Getting Focused Element

```swift
func getFocusedElement() -> AXUIElement? {
    let systemWide = AXUIElementCreateSystemWide()
    var focusedApp: CFTypeRef?

    AXUIElementCopyAttributeValue(systemWide, kAXFocusedApplicationAttribute as CFString, &focusedApp)

    guard let app = focusedApp else { return nil }

    var focusedElement: CFTypeRef?
    AXUIElementCopyAttributeValue(app as! AXUIElement, kAXFocusedUIElementAttribute as CFString, &focusedElement)

    return focusedElement as! AXUIElement?
}
```

### Simulating Cmd+V

```swift
func simulateCommandV() {
    let source = CGEventSource(stateID: .hidSystemState)

    // Cmd down
    let cmdDown = CGEvent(keyboardEventSource: source, virtualKey: 0x37, keyDown: true)
    cmdDown?.flags = .maskCommand
    cmdDown?.post(tap: .cghidEventTap)

    // V key
    let vDown = CGEvent(keyboardEventSource: source, virtualKey: 0x09, keyDown: true)
    vDown?.flags = .maskCommand
    vDown?.post(tap: .cghidEventTap)

    let vUp = CGEvent(keyboardEventSource: source, virtualKey: 0x09, keyDown: false)
    vUp?.post(tap: .cghidEventTap)

    // Cmd up
    let cmdUp = CGEvent(keyboardEventSource: source, virtualKey: 0x37, keyDown: false)
    cmdUp?.post(tap: .cghidEventTap)
}
```

## Critical Rules & Best Practices

### Do's ✅

1. **Try strategies in priority order**: Accessibility → Keyboard → Pasteboard
2. **Test capabilities, not bundle IDs**: Future-proof design
3. **Always restore clipboard**: User experience priority
4. **Use minimal delay (1ms)**: Race condition prevention only
5. **Log strategy selection**: Debug visibility

### Don'ts ❌

1. **NEVER skip fallback chain**: Always provide working solution
2. **NEVER hardcode all bundle IDs**: Use capability testing
3. **NEVER leave clipboard modified**: Always restore
4. **NEVER use character-by-character for keyboard**: Use Unicode strings
5. **NEVER block main thread**: Insertion should be fast

## Troubleshooting

### Text Not Inserting
- **Check**: Accessibility permission granted?
- **Verify**: Focused element detected correctly?
- **Debug**: Enable debug logging to see which strategy tried

### Clipboard Not Restored
- **Check**: Is 1ms delay sufficient for your Mac?
- **Try**: Increase delay slightly (up to 5ms max)

### Safari Address Bar Issues
- **Known Issue**: Accessibility API reports false positive
- **Solution**: Use verification step to detect failure
- **Fallback**: Keyboard simulation works for Safari

## Testing Strategies

### Unit Tests
```swift
func testStrategyPriority() {
    let inserter = UniversalTextInserter()
    let strategies = inserter.strategies.sorted(by: { $0.priority > $1.priority })

    XCTAssertEqual(strategies[0].name, "Accessibility")
    XCTAssertEqual(strategies[1].name, "Keyboard")
    XCTAssertEqual(strategies[2].name, "Pasteboard")
}
```

### Integration Tests
```swift
// Test with various apps
func testTextEditorInsertion() {
    // Launch TextEdit, focus text field
    let app = XCUIApplication(bundleIdentifier: "com.apple.TextEdit")
    app.launch()

    let success = textInserter.insertText("Hello World")
    XCTAssertTrue(success)

    // Verify text appeared
    XCTAssertTrue(app.textViews.firstMatch.value as? String == "Hello World")
}
```

## When to Use This Skill

**Use this skill when**:
- Implementing or modifying text insertion logic
- Adding support for new applications
- Debugging insertion failures
- Understanding strategy selection
- Optimizing insertion performance

## Related Skills

- **hotkeykit-skill**: Coordinate insertion timing with hotkey release
- **speechkit-skill**: Insert transcribed text
- **permissionkit-skill**: Accessibility permission requirements
- **debug-tools-skill**: Debug strategy selector
