import Foundation
import AppKit
import ApplicationServices

public final class TextInserter: @unchecked Sendable {
    private var currentText: String = ""
    private var lastInsertedRange: NSRange?
    
    public init() {}
    
    public func insertText(_ text: String, isFinal: Bool) {
        DispatchQueue.main.async { [weak self] in
            self?.performInsertion(text, isFinal: isFinal)
        }
    }
    
    private func performInsertion(_ text: String, isFinal: Bool) {
        print("📝 TextInserter: Attempting to insert text: '\(text)' (isFinal: \(isFinal))")
        
        guard let focusedElement = getFocusedElement() else {
            print("❌ TextInserter: No focused element found")
            fallbackToClipboard(text)
            return
        }
        
        print("✅ TextInserter: Found focused element")
        
        if canUseAccessibilityAPI(element: focusedElement) {
            print("✅ TextInserter: Using accessibility API")
            insertViaAccessibility(text: text, element: focusedElement, isFinal: isFinal)
        } else {
            print("❌ TextInserter: Accessibility API not available, using clipboard fallback")
            fallbackToClipboard(text)
        }
    }
    
    private func getFocusedElement() -> AXUIElement? {
        let systemWideElement = AXUIElementCreateSystemWide()
        var focusedElement: CFTypeRef?
        
        let result = AXUIElementCopyAttributeValue(
            systemWideElement,
            kAXFocusedUIElementAttribute as CFString,
            &focusedElement
        )
        
        guard result == .success,
              let element = focusedElement else {
            return nil
        }
        
        return (element as! AXUIElement)
    }
    
    private func canUseAccessibilityAPI(element: AXUIElement) -> Bool {
        var isAttributeSettable: DarwinBoolean = false
        
        let result = AXUIElementIsAttributeSettable(
            element,
            kAXValueAttribute as CFString,
            &isAttributeSettable
        )
        
        return result == .success && isAttributeSettable.boolValue
    }
    
    private func insertViaAccessibility(text: String, element: AXUIElement, isFinal: Bool) {
        var currentValue: CFTypeRef?
        _ = AXUIElementCopyAttributeValue(
            element,
            kAXValueAttribute as CFString,
            &currentValue
        )
        
        let existingText = (currentValue as? String) ?? ""
        
        var selectedRange: CFTypeRef?
        let rangeResult = AXUIElementCopyAttributeValue(
            element,
            kAXSelectedTextRangeAttribute as CFString,
            &selectedRange
        )
        
        var insertPosition = existingText.count
        
        if rangeResult == .success,
           let rangeValue = selectedRange {
            var range = CFRange()
            AXValueGetValue(rangeValue as! AXValue, .cfRange, &range)
            insertPosition = max(0, min(range.location, existingText.count))
        }
        
        let newText: String
        if !isFinal && lastInsertedRange != nil {
            let range = lastInsertedRange!
            // Validate range bounds to prevent crashes
            let validLocation = max(0, min(range.location, existingText.count))
            let validEnd = max(validLocation, min(range.location + range.length, existingText.count))
            
            let beforeText = String(existingText.prefix(validLocation))
            let afterText = validEnd < existingText.count ? 
                String(existingText.suffix(from: existingText.index(existingText.startIndex, offsetBy: validEnd))) : ""
            newText = beforeText + text + afterText
            lastInsertedRange = NSRange(location: validLocation, length: text.count)
        } else {
            // Validate insert position to prevent crashes
            let validPosition = max(0, min(insertPosition, existingText.count))
            
            let beforeText = String(existingText.prefix(validPosition))
            let afterText = validPosition < existingText.count ? 
                String(existingText.suffix(from: existingText.index(existingText.startIndex, offsetBy: validPosition))) : ""
            newText = beforeText + text + afterText
            
            if isFinal {
                lastInsertedRange = nil
            } else {
                lastInsertedRange = NSRange(location: validPosition, length: text.count)
            }
        }
        
        let setResult = AXUIElementSetAttributeValue(
            element,
            kAXValueAttribute as CFString,
            newText as CFString
        )
        
        if setResult == .success {
            let newCursorPosition = (lastInsertedRange?.location ?? insertPosition) + text.count
            var newRange = CFRange(location: newCursorPosition, length: 0)
            let rangeValue = AXValueCreate(.cfRange, &newRange)
            
            AXUIElementSetAttributeValue(
                element,
                kAXSelectedTextRangeAttribute as CFString,
                rangeValue!
            )
        } else {
            fallbackToClipboard(text)
        }
    }
    
    private func fallbackToClipboard(_ text: String) {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(text, forType: .string)
        
        showNotification(
            title: "Text Copied",
            message: "Please paste manually (⌘V)"
        )
    }
    
    private func showNotification(title: String, message: String) {
        // For now, just print to console
        // In production, you'd use UserNotifications framework
        print("\(title): \(message)")
    }
}

extension CFRange {
    init(location: Int, length: Int) {
        self = CFRangeMake(location, length)
    }
}