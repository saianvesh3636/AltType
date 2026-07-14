import SwiftUI
import AppServices
import AppKit
import AppServices
import Carbon.HIToolbox

struct HotkeyRecorderView: View {
    @Binding var hotkey: String
    @Environment(\.hotkeySettings) private var hotkeySettings // Custom environment value (protocol-based, optional)
    @EnvironmentObject var paletteManager: PaletteManager
    @State private var isRecording = false
    @State private var recordedKeyCode: UInt16?
    @State private var recordedModifiers: NSEvent.ModifierFlags = []
    @State private var previousModifiers: NSEvent.ModifierFlags = []

    private var formattedHotkey: String {
        // Use the cached display name from optimized HotkeySettings
        let display = hotkeySettings?.displayName ?? "Not Available"
        return display.isEmpty ? "Click to set hotkey" : display
    }
    
    var body: some View {
        Button(action: toggleRecording) {
            HStack(spacing: 8) {
                if isRecording {
                    HStack(spacing: 6) {
                        Image(systemName: "circle.fill")
                            .foregroundColor(Color.appError(from: paletteManager))
                            .font(.system(size: 8))
                            .symbolEffect(.pulse.byLayer)
                        
                        Text("Press key combination...")
                            .foregroundColor(Color.appError(from: paletteManager))
                            .font(.system(size: 13, weight: .medium))
                    }
                } else {
                    HStack(spacing: 6) {
                        Image(systemName: "keyboard")
                            .font(.system(size: 14))
                            .foregroundColor(Color.appOnSurface(from: paletteManager).opacity(0.7))
                        
                        Text(formattedHotkey)
                            .font(.system(size: 13, weight: .medium, design: .monospaced))
                            .foregroundColor((hotkeySettings?.requiredKeys.isEmpty ?? true) ? Color.appOnSurface(from: paletteManager).opacity(0.7) : Color.appOnSurface(from: paletteManager))
                    }
                }
                
                Spacer()
                
                Image(systemName: isRecording ? "stop.circle.fill" : "pencil.circle")
                    .font(.system(size: 16))
                    .foregroundColor(isRecording ? Color.appError(from: paletteManager) : Color.appPrimary(from: paletteManager))
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color.appSurface(from: paletteManager))
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(isRecording ? Color.appError(from: paletteManager).opacity(0.6) : Color.appPrimary(from: paletteManager).opacity(0.4), lineWidth: 1.5)
                    )
            )
        }
        .buttonStyle(.plain)
        .onAppear {
            setupEventMonitor()
        }
    }
    
    private func toggleRecording() {
        isRecording.toggle()

        if isRecording {
            // Reset state for clean recording
            recordedKeyCode = nil
            recordedModifiers = []
            previousModifiers = []
        } else if recordedKeyCode != nil {
            updateHotkey()
        }
    }
    
    private func setupEventMonitor() {
        // Use local event monitoring for the recorder UI
        // This only captures events within our app window, which is sufficient for settings
        _ = NSEvent.addLocalMonitorForEvents(matching: [.keyDown, .flagsChanged]) { event in
            guard self.isRecording else { return event }
            
            if event.type == .keyDown {
                // Regular key + modifier combination
                self.recordedKeyCode = UInt16(event.keyCode)
                self.recordedModifiers = event.modifierFlags.intersection(.deviceIndependentFlagsMask)
                
                // Stop recording and update
                DispatchQueue.main.async {
                    self.isRecording = false
                    self.updateHotkey()
                }
                return nil // Consume the event
                
            } else if event.type == .flagsChanged {
                // Modifier-only recording: detect press vs release
                let currentModifiers = event.modifierFlags.intersection(.deviceIndependentFlagsMask)

                // Detect if modifiers were pressed or released
                let modifiersReleased = !currentModifiers.contains(self.previousModifiers) && !self.previousModifiers.isEmpty

                if modifiersReleased {
                    // Modifiers were released - complete recording with modifier-only hotkey
                    self.recordedKeyCode = 0 // 0 means "modifier only"
                    self.recordedModifiers = self.previousModifiers

                    DispatchQueue.main.async {
                        self.isRecording = false
                        self.updateHotkey()
                    }
                    return nil // Consume the event
                }

                // Track current state for next comparison
                self.previousModifiers = currentModifiers
            }
            
            return event
        }
    }
    
    private func updateHotkey() {
        guard let keyCode = recordedKeyCode else { return }
        
        // Convert recorded keys to Set<UInt16> for new system
        Task { @MainActor in
            var keys: Set<UInt16> = []
            
            // Add regular key if it's not modifier-only
            if keyCode != 0 {
                keys.insert(keyCode)
            }
            
            // Add modifier keys
            if recordedModifiers.contains(.control) {
                keys.insert(59) // Left Control
            }
            if recordedModifiers.contains(.option) {
                keys.insert(58) // Left Option
            }
            if recordedModifiers.contains(.shift) {
                keys.insert(56) // Left Shift
            }
            if recordedModifiers.contains(.command) {
                keys.insert(55) // Left Command
            }
            if recordedModifiers.contains(.function) {
                keys.insert(179) // Function key
            }
            
            // Update with new Set<UInt16> system (only if available)
            hotkeySettings?.updateHotkey(keys)

            // Update the display string for UI purposes only
            hotkey = formattedHotkey
        }
    }
    
    private func keyCodeToString(_ keyCode: UInt16) -> String? {
        switch Int(keyCode) {
        case kVK_Space: return "Space"
        case kVK_Return: return "Return"
        case kVK_Tab: return "Tab"
        case kVK_Delete: return "Delete"
        case kVK_Escape: return "Escape"
        case kVK_F1: return "F1"
        case kVK_F2: return "F2"
        case kVK_F3: return "F3"
        case kVK_F4: return "F4"
        case kVK_F5: return "F5"
        case kVK_F6: return "F6"
        case kVK_F7: return "F7"
        case kVK_F8: return "F8"
        case kVK_F9: return "F9"
        case kVK_F10: return "F10"
        case kVK_F11: return "F11"
        case kVK_F12: return "F12"
        case kVK_F13: return "F13"
        case kVK_F14: return "F14"
        case kVK_F15: return "F15"
        case kVK_F16: return "F16"
        case kVK_F17: return "F17"
        case kVK_F18: return "F18"
        case kVK_F19: return "F19"
        case kVK_F20: return "F20"
        default:
            let source = TISCopyCurrentKeyboardInputSource().takeRetainedValue()
            let layoutData = TISGetInputSourceProperty(source, kTISPropertyUnicodeKeyLayoutData)
            
            guard let data = layoutData else { return nil }
            
            let layout = unsafeBitCast(data, to: CFData.self)
            let keyboardLayout = unsafeBitCast(CFDataGetBytePtr(layout), to: UnsafePointer<UCKeyboardLayout>.self)
            
            var deadKeyState: UInt32 = 0
            var chars = [UniChar](repeating: 0, count: 4)
            var length = 0
            
            let status = UCKeyTranslate(
                keyboardLayout,
                keyCode,
                UInt16(kUCKeyActionDisplay),
                0,
                UInt32(LMGetKbdType()),
                UInt32(kUCKeyTranslateNoDeadKeysBit),
                &deadKeyState,
                chars.count,
                &length,
                &chars
            )
            
            if status == noErr && length > 0 {
                return String(utf16CodeUnits: chars, count: length).uppercased()
            }
            
            return nil
        }
    }
    
}

// // #Preview {
//     HotkeyRecorderView(hotkey: .constant("Option+Space"))
// }