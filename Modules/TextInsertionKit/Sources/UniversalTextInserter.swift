import Foundation
import AppKit
@preconcurrency import ApplicationServices
@preconcurrency import CoreGraphics
import AppServices
import HotkeyKit
import os.log

// MARK: - Simple Logging Helper

private struct TextInserterLogger {
    static func info(_ message: String) {
        #if DEBUG
        print("📝 UniversalTextInserter: \(message)")
        #endif
    }
    
    static func success(_ message: String) {
        #if DEBUG
        print("✅ UniversalTextInserter: \(message)")
        #endif
    }
    
    static func warning(_ message: String) {
        print("⚠️ UniversalTextInserter: \(message)")
    }
    
    static func error(_ message: String) {
        print("❌ UniversalTextInserter: \(message)")
    }
}

// MARK: - Insertion Strategy Protocol

protocol TextInsertionStrategy: AnyObject {
    var name: String { get }
    var priority: Int { get set }
    func canInsert(into element: AXUIElement?, application: NSRunningApplication?) -> Bool
    func insertText(_ text: String, into element: AXUIElement?, application: NSRunningApplication?) -> Bool
}

// MARK: - Simple Text Inserter

@MainActor
public final class UniversalTextInserter: ObservableObject, TextInsertionServiceProtocol {
    
    // MARK: - Simple State
    
    @Published public private(set) var isInserting = false
    @Published public private(set) var lastInsertionResult: InsertionResult?
    
    // MARK: - Strategies
    
    private let strategies: [TextInsertionStrategy]
    
    // MARK: - Debug Configuration
    
    #if DEBUG
    public enum InsertionStrategyOrder: String, CaseIterable {
        case accessibilityFirst = "Accessibility → Keyboard → Pasteboard"
        case keyboardFirst = "Keyboard → Accessibility → Pasteboard"
        case pasteboardFirst = "Pasteboard → Keyboard → Accessibility"
        case keyboardOnly = "Keyboard Only"
        case accessibilityOnly = "Accessibility Only"
        case pasteboardOnly = "Pasteboard Only"
        
        var strategyPriorities: [(String, Int)] {
            switch self {
            case .accessibilityFirst:
                return [("Accessibility API", 100), ("Keyboard Simulation", 90), ("Pasteboard + Cmd+V", 70)]
            case .keyboardFirst:
                return [("Keyboard Simulation", 100), ("Accessibility API", 90), ("Pasteboard + Cmd+V", 70)]
            case .pasteboardFirst:
                return [("Pasteboard + Cmd+V", 100), ("Keyboard Simulation", 90), ("Accessibility API", 70)]
            case .keyboardOnly:
                return [("Keyboard Simulation", 100)]
            case .accessibilityOnly:
                return [("Accessibility API", 100)]
            case .pasteboardOnly:
                return [("Pasteboard + Cmd+V", 100)]
            }
        }
    }
    
    @Published public var debugStrategyOrder: InsertionStrategyOrder = .accessibilityFirst {
        didSet {
            updateStrategies()
        }
    }
    #endif
    
    // MARK: - Initialization
    
    public init() {
        #if DEBUG
        // Load saved preference or use default (Accessibility first)
        let savedOrder = UserDefaults.standard.string(forKey: "TextInsertionStrategyOrder")
        let order = savedOrder.flatMap { InsertionStrategyOrder(rawValue: $0) } ?? .accessibilityFirst

        // Create strategies based on debug configuration
        self.strategies = Self.createStrategies(for: order)
        self.debugStrategyOrder = order

        TextInserterLogger.info("DEBUG: Initialized with strategy order: \(order.rawValue)")
        #else
        // Production: Choose strategies based on app variant capabilities
        if AppServices.AppConfiguration.current.features.supportsAdvancedTextInsertion {
            // Full app: Use Accessibility API first (requires non-sandboxed app with Accessibility permission)
            self.strategies = [
                AccessibilityStrategy(priority: 100),
                KeyboardStrategy(priority: 90),
                PasteboardStrategy(priority: 70)
            ].sorted { $0.priority > $1.priority }

            TextInserterLogger.info("Initialized with \(strategies.count) strategies (Accessibility → Keyboard → Pasteboard)")
        } else {
            // Lite app: No Accessibility API (sandboxed, no accessibility permission)
            self.strategies = [
                KeyboardStrategy(priority: 100),
                PasteboardStrategy(priority: 70)
            ].sorted { $0.priority > $1.priority }

            TextInserterLogger.info("Initialized with \(strategies.count) strategies (Keyboard → Pasteboard)")
        }
        #endif
    }
    
    #if DEBUG
    private static func createStrategies(for order: InsertionStrategyOrder) -> [TextInsertionStrategy] {
        let priorities = order.strategyPriorities
        var strategies: [TextInsertionStrategy] = []
        
        // Create strategies with appropriate priorities
        for (strategyName, priority) in priorities {
            switch strategyName {
            case "Accessibility API":
                strategies.append(AccessibilityStrategy(priority: priority))
            case "Keyboard Simulation":
                strategies.append(KeyboardStrategy(priority: priority))
            case "Pasteboard + Cmd+V":
                strategies.append(PasteboardStrategy(priority: priority))
            default:
                break
            }
        }
        
        // Sort by priority (highest first)
        return strategies.sorted { $0.priority > $1.priority }
    }
    
    private func updateStrategies() {
        // Save preference
        UserDefaults.standard.set(debugStrategyOrder.rawValue, forKey: "TextInsertionStrategyOrder")
        
        TextInserterLogger.info("DEBUG: Strategy order changed to: \(debugStrategyOrder.rawValue)")
        TextInserterLogger.info("DEBUG: Restart may be required for full effect")
    }
    
    public func getCurrentStrategyOrder() -> String {
        return strategies.map { "\($0.name) (p:\($0.priority))" }.joined(separator: " → ")
    }
    #endif
    
    // MARK: - Public Interface
    
    /// Insert text using the best available strategy
    public func insertText(_ text: String, isFinal: Bool = true) {
        TextInserterLogger.info("📥 insertText() called with text: '\(text)' (isFinal: \(isFinal))")
        
        guard !text.isEmpty else {
            TextInserterLogger.warning("Empty text provided")
            return
        }
        
        guard !isInserting else {
            TextInserterLogger.warning("Already inserting text - skipping concurrent request")
            return
        }
        
        isInserting = true
        
        Task {
            let result = await performInsertion(text)
            
            await MainActor.run {
                self.lastInsertionResult = result
                self.isInserting = false
                
                if result.success {
                    TextInserterLogger.success("Text inserted via \(result.method)")
                } else {
                    TextInserterLogger.error("Text insertion failed: \(result.error?.localizedDescription ?? "Unknown error")")
                }
            }
        }
    }
    
    // MARK: - Backwards Compatibility (No-ops)
    
    public func updateHotkeyState(_ isPressed: Bool) { }
    public func updateDictationState(_ isDictating: Bool) { }
    public func signalHotkeyState(_ isPressed: Bool) { }
    public func signalManagerState(_ managerState: HotkeyManagerState) { }
    
    // MARK: - Implementation
    
    private func performInsertion(_ text: String) async -> InsertionResult {
        let focusedElement = getFocusedElement()
        let activeApp = NSWorkspace.shared.frontmostApplication
        let appName = activeApp?.localizedName ?? "Unknown"
        
        print("\n Stratagies: \(strategies)")
        // Try each strategy in priority order
        for strategy in strategies {
            print("\n one strategy: \(strategy)")
            if strategy.canInsert(into: focusedElement, application: activeApp) {
                let success = strategy.insertText(text, into: focusedElement, application: activeApp)
                
                if success {
                    return InsertionResult(success: true, method: strategy.name)
                }
            }
        }
        
        TextInserterLogger.error("All strategies failed for app: \(appName)")
        return InsertionResult(
            success: false, 
            method: "none", 
            error: TextInsertionError.allStrategiesFailed
        )
    }
    
    private func getFocusedElement() -> AXUIElement? {
        // Force fresh check using options with prompt: false
        let options: NSDictionary = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as NSString: false]
        guard AXIsProcessTrustedWithOptions(options) else { return nil }

        let systemWideElement = AXUIElementCreateSystemWide()
        var focusedElement: CFTypeRef?

        let result = AXUIElementCopyAttributeValue(
            systemWideElement,
            kAXFocusedUIElementAttribute as CFString,
            &focusedElement
        )

        return result == .success ? (focusedElement as! AXUIElement) : nil
    }
}

// MARK: - Accessibility Strategy

private class AccessibilityStrategy: TextInsertionStrategy {
    let name = "Accessibility API"
    var priority: Int
    
    init(priority: Int = 90) {
        self.priority = priority
    }
    
    func canInsert(into element: AXUIElement?, application: NSRunningApplication?) -> Bool {
        // Force fresh check using options with prompt: false
        let options: NSDictionary = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as NSString: false]
        guard AXIsProcessTrustedWithOptions(options), let element = element else { return false }

        var isSettable: DarwinBoolean = false
        let result = AXUIElementIsAttributeSettable(
            element,
            kAXValueAttribute as CFString,
            &isSettable
        )

        return result == .success && isSettable.boolValue
    }
    
    func insertText(_ text: String, into element: AXUIElement?, application: NSRunningApplication?) -> Bool {
        guard let element = element else { return false }
        
        // Get initial value for verification
        let initialValue = getCurrentValue(from: element)
        
        // Direct fast insertion: Try selected text replacement first
        let selectedTextResult = AXUIElementSetAttributeValue(
            element,
            kAXSelectedTextAttribute as CFString,
            text as CFString
        )
        
        if selectedTextResult == .success {
            // Verify the text was actually inserted
            return verifyTextInsertion(text: text, element: element, initialValue: initialValue)
        }
        
        // Fallback: Direct value setting for instant insertion
        let valueResult = AXUIElementSetAttributeValue(
            element,
            kAXValueAttribute as CFString,
            text as CFString
        )
        
        if valueResult == .success {
            return verifyTextInsertion(text: text, element: element, initialValue: initialValue)
        }
        
        return false
    }
    
    private func getCurrentValue(from element: AXUIElement) -> String? {
        var value: CFTypeRef?
        let result = AXUIElementCopyAttributeValue(
            element,
            kAXValueAttribute as CFString,
            &value
        )
        
        return result == .success ? (value as? String) : nil
    }
    
    private func verifyTextInsertion(text: String, element: AXUIElement, initialValue: String?) -> Bool {
        // Get current value after insertion attempt
        let currentValue = getCurrentValue(from: element)
        
        // Check if text was actually inserted
        guard let current = currentValue else {
            // If we can't read the value, assume success (some fields are write-only)
            return true
        }
        
        // Verification strategies:
        // 1. Text was appended to existing content
        if let initial = initialValue {
            if current == initial + text || current == text + initial {
                return true
            }
        }
        
        // 2. Text completely replaced existing content
        if current == text {
            return true
        }
        
        // 3. Text was inserted and content changed from initial
        if current != initialValue {
            return true
        }
        
        // 4. Special case: Empty initial value and text was inserted
        if (initialValue?.isEmpty ?? true) && !current.isEmpty {
            return true
        }
        
        TextInserterLogger.warning("Accessibility insertion claimed success but text didn't change. Initial: '\(initialValue ?? "nil")', Current: '\(current)', Attempted: '\(text)'")
        return false
    }
}

// MARK: - Keyboard Strategy

private class KeyboardStrategy: TextInsertionStrategy {
    let name = "Keyboard Simulation"
    var priority: Int
    
    init(priority: Int = 100) {
        self.priority = priority
    }
    
    func canInsert(into element: AXUIElement?, application: NSRunningApplication?) -> Bool {
        return true // Keyboard simulation works with any app
    }
    
    func insertText(_ text: String, into element: AXUIElement?, application: NSRunningApplication?) -> Bool {
        let eventSource = CGEventSource(stateID: .hidSystemState)
        
        guard let event = CGEvent(keyboardEventSource: eventSource, virtualKey: 0, keyDown: true) else {
            return false
        }
        
        // Single event for entire text - no chunking, no delays
        let utf16Array = Array(text.utf16)
        let success = utf16Array.withUnsafeBufferPointer { buffer -> Bool in
            guard let baseAddress = buffer.baseAddress else { return false }
            event.keyboardSetUnicodeString(stringLength: utf16Array.count, unicodeString: baseAddress)
            return true
        }
        
        guard success else { return false }
        
        event.post(tap: .cghidEventTap)
        return true
    }
}

// MARK: - Pasteboard Strategy

private class PasteboardStrategy: TextInsertionStrategy {
    let name = "Pasteboard + Cmd+V"
    var priority: Int
    
    init(priority: Int = 70) {
        self.priority = priority
    }
    
    func canInsert(into element: AXUIElement?, application: NSRunningApplication?) -> Bool {
        return true // Pasteboard works with any app
    }
    
    func insertText(_ text: String, into element: AXUIElement?, application: NSRunningApplication?) -> Bool {
        let pasteboard = NSPasteboard.general
        let originalContents = pasteboard.string(forType: .string)
        
        pasteboard.clearContents()
        guard pasteboard.setString(text, forType: .string) else { return false }
        
        let cmdVSuccess = simulateCommandV()
        
        if cmdVSuccess {
            // Ultra-fast minimal synchronization - just 1 runloop cycle
            // This is typically < 1ms and ensures the paste event is processed
            CFRunLoopRunInMode(.defaultMode, 0.001, false)
        }
        
        // Restore clipboard
        pasteboard.clearContents()
        if let original = originalContents {
            pasteboard.setString(original, forType: .string)
        }
        
        return cmdVSuccess
    }
    
    private func simulateCommandV() -> Bool {
        let eventSource = CGEventSource(stateID: .hidSystemState)
        
        guard let keyDownEvent = CGEvent(keyboardEventSource: eventSource, virtualKey: 0x09, keyDown: true),
              let keyUpEvent = CGEvent(keyboardEventSource: eventSource, virtualKey: 0x09, keyDown: false) else {
            return false
        }
        
        keyDownEvent.flags = .maskCommand
        keyUpEvent.flags = .maskCommand
        
        keyDownEvent.post(tap: .cghidEventTap)
        keyUpEvent.post(tap: .cghidEventTap)
        
        return true
    }
}

// MARK: - Error Types

public enum TextInsertionError: LocalizedError, Sendable {
    case allStrategiesFailed
    case noFocusedElement
    case unsupportedApplication
    case strategyFailed(String)
    
    public var errorDescription: String? {
        switch self {
        case .allStrategiesFailed:
            return "All text insertion strategies failed"
        case .noFocusedElement:
            return "No focused element found"
        case .unsupportedApplication:
            return "Application does not support text insertion"
        case .strategyFailed(let strategyName):
            return "Text insertion strategy '\(strategyName)' failed"
        }
    }
}
