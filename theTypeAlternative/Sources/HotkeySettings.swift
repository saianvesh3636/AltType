import Foundation
import SwiftUI
import Combine
import AppServices

/// Resource-optimized hotkey settings with reactive persistence
/// Full implementation for variants that support hotkeys
@MainActor
class HotkeySettings: HotkeySettingsProtocol {
    
    // MARK: - Optimized Storage (HotkeySettingsProtocol conformance)

    /// The set of keys that must be pressed simultaneously (cached for performance)
    @Published public private(set) var requiredKeys: Set<UInt16>

    /// Cached display name (updated reactively for performance)
    @Published public private(set) var displayName: String

    /// Publisher for requiredKeys changes
    public var requiredKeysPublisher: AnyPublisher<Set<UInt16>, Never> {
        $requiredKeys.eraseToAnyPublisher()
    }

    /// Check if this is a single key hotkey
    public var isSingleKey: Bool {
        requiredKeys.count == 1
    }

    /// Check if this contains only modifier keys
    public var isModifierOnly: Bool {
        requiredKeys.allSatisfy { Self.isModifierKey($0) }
    }
    
    // MARK: - Reactive Persistence
    
    private var cancellables = Set<AnyCancellable>()
    private static let storageKey = "HotkeyKeys"
    
    // MARK: - Initialization
    
    init() {
        // Load from UserDefaults with efficient deserialization
        if let savedData = UserDefaults.standard.data(forKey: Self.storageKey),
           let savedKeys = try? JSONDecoder().decode([UInt16].self, from: savedData),
           !savedKeys.isEmpty {
            
            let keys = Set(savedKeys)
            self.requiredKeys = keys
            self.displayName = Self.computeDisplayName(for: keys)
            print("🎹 Loaded saved hotkey: \(self.displayName)")
            
        } else {
            // Default to Function key as requested
            let defaultKeys: Set<UInt16> = [179]  // Function key
            self.requiredKeys = defaultKeys
            self.displayName = Self.computeDisplayName(for: defaultKeys)
            print("🎹 Setting default hotkey: Function key")
        }
        
        setupReactivePersistence()
    }
    
    // MARK: - Reactive Persistence (Performance Optimized)
    
    private func setupReactivePersistence() {
        // Efficiently persist changes with debouncing to avoid excessive I/O
        $requiredKeys
            .debounce(for: .milliseconds(200), scheduler: DispatchQueue.main)
            .sink { [weak self] keys in
                self?.persistKeys(keys)
                self?.updateDisplayName(for: keys)
            }
            .store(in: &cancellables)
    }
    
    private func persistKeys(_ keys: Set<UInt16>) {
        do {
            let keysArray = Array(keys).sorted() // Consistent ordering
            let data = try JSONEncoder().encode(keysArray)
            UserDefaults.standard.set(data, forKey: Self.storageKey)
            print("🎹 Persisted hotkey: \(keys)")
        } catch {
            print("❌ Failed to persist hotkey: \(error)")
        }
    }
    
    private func updateDisplayName(for keys: Set<UInt16>) {
        displayName = Self.computeDisplayName(for: keys)
    }
    
    // MARK: - Public Interface (HotkeySettingsProtocol conformance)

    /// Update the hotkey combination (optimized for performance)
    public func updateHotkey(_ newKeys: Set<UInt16>) {
        guard newKeys != requiredKeys else { return }

        requiredKeys = newKeys
        print("🎹 Updated hotkey: \(displayName)")
    }

    /// Update with single key (convenience method)
    public func updateHotkey(singleKey: UInt16) {
        updateHotkey([singleKey])
    }

    /// Reset to default Fn key
    public func resetToDefault() {
        updateHotkey([179])  // Fn key
        print("🎹 Reset to default: Fn key")
    }
    
    // MARK: - Efficient Display Name Generation
    
    private static func computeDisplayName(for keys: Set<UInt16>) -> String {
        guard !keys.isEmpty else { return "None" }
        
        if keys.count == 1 {
            return keyDisplayName(for: keys.first!)
        }
        
        // Separate and order modifiers and regular keys for better UX
        var modifiers: [String] = []
        var regularKeys: [String] = []
        
        for keyCode in keys.sorted() {  // Consistent ordering
            let displayName = keyDisplayName(for: keyCode)
            
            if Self.isModifierKey(keyCode) {
                modifiers.append(displayName)
            } else {
                regularKeys.append(displayName)
            }
        }
        
        // Combine in logical order: modifiers first, then regular keys
        let allComponents = modifiers + regularKeys
        return allComponents.joined(separator: " + ")
    }
    
    private static func keyDisplayName(for keyCode: UInt16) -> String {
        // Use KeyCodeMapping for comprehensive key display
        return KeyCodeMapping.displayName(for: keyCode)
    }
    
    private static func isModifierKey(_ keyCode: UInt16) -> Bool {
        return KeyCodeMapping.isModifierKey(keyCode)
    }
    
    // MARK: - Backward Compatibility (HotkeySettingsProtocol conformance)

    /// Legacy keyCode property for backward compatibility
    public var keyCode: UInt16 {
        isSingleKey ? requiredKeys.first! : 0
    }

    /// Legacy modifiers property (empty for new system)
    public var modifiers: NSEvent.ModifierFlags {
        [] // No longer used in new system
    }

    /// Legacy CGEventFlags (empty for new system)
    public var cgEventFlags: CGEventFlags {
        [] // No longer used in new system
    }
}

// MARK: - Common Hotkey Presets

extension HotkeySettings {
    
    /// Common hotkey combinations for quick setup
    static let functionKey: Set<UInt16> = [179]
    static let spaceKey: Set<UInt16> = [49]
    static let commandKey: Set<UInt16> = [55]
    static let optionKey: Set<UInt16> = [58]
    static let optionCommand: Set<UInt16> = [58, 55]
    static let optionSpace: Set<UInt16> = [58, 49]
}