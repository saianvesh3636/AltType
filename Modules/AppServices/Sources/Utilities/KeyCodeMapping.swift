import Foundation
import AppKit
import Carbon.HIToolbox

/// Comprehensive key code mapping for all supported hotkeys
/// Moved to AppServices to avoid lite app needing to link full HotkeyKit
public struct KeyCodeMapping {

    // MARK: - Modifier Keys (Physical Key Codes)
    public static let functionKey: UInt16 = 179
    public static let leftCommand: UInt16 = 55
    public static let rightCommand: UInt16 = 54
    public static let leftOption: UInt16 = 58
    public static let rightOption: UInt16 = 61
    public static let leftShift: UInt16 = 56
    public static let rightShift: UInt16 = 60
    public static let leftControl: UInt16 = 59
    public static let rightControl: UInt16 = 62

    // MARK: - Regular Keys
    public static let space: UInt16 = 49
    public static let enter: UInt16 = 36
    public static let tab: UInt16 = 48
    public static let delete: UInt16 = 51
    public static let escape: UInt16 = 53

    // MARK: - Letter Keys (a-z)
    public static let letterKeys: [Character: UInt16] = [
        "a": 0, "b": 11, "c": 8, "d": 2, "e": 14, "f": 3, "g": 5, "h": 4, "i": 34,
        "j": 38, "k": 40, "l": 37, "m": 46, "n": 45, "o": 31, "p": 35, "q": 12,
        "r": 15, "s": 1, "t": 17, "u": 32, "v": 9, "w": 13, "x": 7, "y": 16, "z": 6
    ]

    // MARK: - Number Keys (0-9)
    public static let numberKeys: [Character: UInt16] = [
        "1": 18, "2": 19, "3": 20, "4": 21, "5": 23,
        "6": 22, "7": 26, "8": 28, "9": 25, "0": 29
    ]

    // MARK: - Function Keys
    public static let functionKeys: [String: UInt16] = [
        "F1": 122, "F2": 120, "F3": 99, "F4": 118, "F5": 96, "F6": 97,
        "F7": 98, "F8": 100, "F9": 101, "F10": 109, "F11": 103, "F12": 111,
        "F13": 105, "F14": 107, "F15": 113, "F16": 106, "F17": 64, "F18": 79, "F19": 80, "F20": 90
    ]

    // MARK: - Helper Methods

    /// Get display name for a key code
    public static func displayName(for keyCode: UInt16) -> String {
        // Check modifier keys first
        switch keyCode {
        case functionKey: return "fn"
        case leftCommand, rightCommand: return "⌘"
        case leftOption, rightOption: return "⌥"
        case leftShift, rightShift: return "⇧"
        case leftControl, rightControl: return "⌃"
        case space: return "Space"
        case enter: return "Return"
        case tab: return "Tab"
        case delete: return "Delete"
        case escape: return "Escape"
        default: break
        }

        // Check letter keys
        for (char, code) in letterKeys {
            if code == keyCode {
                return String(char).uppercased()
            }
        }

        // Check number keys
        for (char, code) in numberKeys {
            if code == keyCode {
                return String(char)
            }
        }

        // Check function keys
        for (name, code) in functionKeys {
            if code == keyCode {
                return name
            }
        }

        return "Key \(keyCode)"
    }

    /// Check if a key code is a modifier key
    public static func isModifierKey(_ keyCode: UInt16) -> Bool {
        return [functionKey, leftCommand, rightCommand, leftOption, rightOption,
                leftShift, rightShift, leftControl, rightControl].contains(keyCode)
    }

    /// Get key code for a character (for letters and numbers)
    public static func keyCode(for character: Character) -> UInt16? {
        let lowercased = Character(character.lowercased())
        return letterKeys[lowercased] ?? numberKeys[lowercased]
    }

    /// Get all available key codes with their display names
    public static func allAvailableKeys() -> [(keyCode: UInt16, displayName: String)] {
        var keys: [(UInt16, String)] = []

        // Add modifier keys
        keys.append((functionKey, "fn"))
        keys.append((leftCommand, "⌘ Left"))
        keys.append((rightCommand, "⌘ Right"))
        keys.append((leftOption, "⌥ Left"))
        keys.append((rightOption, "⌥ Right"))
        keys.append((leftShift, "⇧ Left"))
        keys.append((rightShift, "⇧ Right"))
        keys.append((leftControl, "⌃ Left"))
        keys.append((rightControl, "⌃ Right"))

        // Add common keys
        keys.append((space, "Space"))
        keys.append((enter, "Return"))
        keys.append((tab, "Tab"))
        keys.append((escape, "Escape"))

        // Add letters
        for (char, code) in letterKeys.sorted(by: { $0.key < $1.key }) {
            keys.append((code, String(char).uppercased()))
        }

        // Add numbers
        for (char, code) in numberKeys.sorted(by: { $0.key < $1.key }) {
            keys.append((code, String(char)))
        }

        return keys.sorted { (first: (keyCode: UInt16, displayName: String), second: (keyCode: UInt16, displayName: String)) in
            first.displayName < second.displayName
        }
    }
}
