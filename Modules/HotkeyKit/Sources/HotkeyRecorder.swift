import SwiftUI
import Carbon

public struct HotkeyRecorder: NSViewRepresentable {
    @Binding var keyCode: UInt16
    @Binding var modifiers: CGEventFlags
    
    public init(keyCode: Binding<UInt16>, modifiers: Binding<CGEventFlags>) {
        self._keyCode = keyCode
        self._modifiers = modifiers
    }
    
    public func makeNSView(context: Context) -> HotkeyRecorderView {
        let view = HotkeyRecorderView()
        view.delegate = context.coordinator
        return view
    }
    
    public func updateNSView(_ nsView: HotkeyRecorderView, context: Context) {
        nsView.keyCode = keyCode
        nsView.modifiers = modifiers
    }
    
    public func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    @MainActor
    public class Coordinator: NSObject, HotkeyRecorderViewDelegate {
        var parent: HotkeyRecorder
        
        init(_ parent: HotkeyRecorder) {
            self.parent = parent
        }
        
        public func hotkeyRecorderDidChangeHotkey(keyCode: UInt16, modifiers: CGEventFlags) {
            parent.keyCode = keyCode
            parent.modifiers = modifiers
        }
    }
}

@MainActor
public protocol HotkeyRecorderViewDelegate: AnyObject {
    func hotkeyRecorderDidChangeHotkey(keyCode: UInt16, modifiers: CGEventFlags)
}

public class HotkeyRecorderView: NSView {
    public weak var delegate: HotkeyRecorderViewDelegate?
    
    public var keyCode: UInt16 = 49
    public var modifiers: CGEventFlags = .maskAlternate
    
    private var textField: NSTextField!
    private var isRecording = false
    
    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        setupView()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupView()
    }
    
    private func setupView() {
        textField = NSTextField(frame: bounds)
        textField.isEditable = false
        textField.isSelectable = false
        textField.alignment = .center
        textField.bezelStyle = .roundedBezel
        textField.translatesAutoresizingMaskIntoConstraints = false
        
        addSubview(textField)
        
        NSLayoutConstraint.activate([
            textField.leadingAnchor.constraint(equalTo: leadingAnchor),
            textField.trailingAnchor.constraint(equalTo: trailingAnchor),
            textField.topAnchor.constraint(equalTo: topAnchor),
            textField.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
        
        updateDisplay()
    }
    
    public override func mouseDown(with event: NSEvent) {
        isRecording = true
        textField.stringValue = "Press a key combination..."
        window?.makeFirstResponder(self)
    }
    
    public override var acceptsFirstResponder: Bool {
        return true
    }
    
    public override func keyDown(with event: NSEvent) {
        if isRecording {
            keyCode = event.keyCode
            // Convert NSEvent.ModifierFlags to CGEventFlags
            var cgModifiers = CGEventFlags(rawValue: 0)
            if event.modifierFlags.contains(.command) {
                cgModifiers.insert(.maskCommand)
            }
            if event.modifierFlags.contains(.option) {
                cgModifiers.insert(.maskAlternate)
            }
            if event.modifierFlags.contains(.control) {
                cgModifiers.insert(.maskControl)
            }
            if event.modifierFlags.contains(.shift) {
                cgModifiers.insert(.maskShift)
            }
            if event.modifierFlags.contains(.function) {
                cgModifiers.insert(.maskSecondaryFn)
            }
            modifiers = cgModifiers
            isRecording = false
            
            delegate?.hotkeyRecorderDidChangeHotkey(keyCode: keyCode, modifiers: modifiers)
            updateDisplay()
        }
    }
    
    private func updateDisplay() {
        var keys: [String] = []
        
        if modifiers.contains(.maskControl) {
            keys.append("⌃")
        }
        if modifiers.contains(.maskAlternate) {
            keys.append("⌥")
        }
        if modifiers.contains(.maskShift) {
            keys.append("⇧")
        }
        if modifiers.contains(.maskCommand) {
            keys.append("⌘")
        }
        if modifiers.contains(.maskSecondaryFn) {
            keys.append("fn")
        }
        
        if let keyString = keyCodeToString(keyCode) {
            keys.append(keyString)
        }
        
        textField.stringValue = keys.joined(separator: " ")
    }
    
    private func keyCodeToString(_ keyCode: UInt16) -> String? {
        switch Int(keyCode) {
        case kVK_Space: return "Space"
        case kVK_Return: return "Return"
        case kVK_Tab: return "Tab"
        case kVK_Delete: return "Delete"
        case kVK_Escape: return "Escape"
        case kVK_F1...kVK_F20: return "F\(keyCode - UInt16(kVK_F1) + 1)"
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
