import Foundation

// MARK: - Permission State Enums

public enum PermissionState: Equatable, Sendable {
    case unknown
    case granted
    case denied
    case requesting
    case restricted
}

public enum OverallPermissionState: Equatable, Sendable {
    case checking
    case ready          // All permissions granted
    case needsMicrophone
    case needsAccessibility
    case needsBoth
    case error(PermissionError)
}

public enum PermissionType: CaseIterable, Sendable, Hashable {
    case microphone
    case accessibility

    public var displayName: String {
        switch self {
        case .microphone: return "Microphone"
        case .accessibility: return "Accessibility"
        }
    }

    #if os(macOS)
    public var systemSettingsURL: String {
        switch self {
        case .microphone:
            return "x-apple.systempreferences:com.apple.preference.security?Privacy_Microphone"
        case .accessibility:
            return "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility"
        }
    }
    #elseif os(iOS)
    public var systemSettingsURL: String {
        // iOS uses App-prefs: for Settings app deep linking
        switch self {
        case .microphone:
            return "App-prefs:Privacy&path=MICROPHONE"
        case .accessibility:
            return "App-prefs:Privacy&path=ACCESSIBILITY"
        }
    }
    #else
    public var systemSettingsURL: String {
        // For other platforms, return empty string or generic settings
        return ""
    }
    #endif
}

// MARK: - Permission Error Types

public struct PermissionError: Error, LocalizedError, Equatable, Sendable {
    public let type: PermissionType
    public let reason: FailureReason

    public enum FailureReason: Equatable, Sendable {
        case denied
        case restricted
        case systemError
        case timeout
    }

    public init(type: PermissionType, reason: FailureReason) {
        self.type = type
        self.reason = reason
    }

    public var errorDescription: String? {
        switch reason {
        case .denied:
            return "\(type.displayName) permission was denied"
        case .restricted:
            return "\(type.displayName) permission is restricted"
        case .systemError:
            return "System error requesting \(type.displayName) permission"
        case .timeout:
            return "Timeout requesting \(type.displayName) permission"
        }
    }
}

// MARK: - Permission State Helpers

extension PermissionState {
    public var isGranted: Bool {
        return self == .granted
    }

    public var isRequestable: Bool {
        return self == .unknown || self == .denied
    }

    public var displayText: String {
        switch self {
        case .unknown: return "Unknown"
        case .granted: return "Enabled"
        case .denied: return "Denied"
        case .requesting: return "Requesting..."
        case .restricted: return "Restricted"
        }
    }
}

extension OverallPermissionState {
    public var needsPermissions: Bool {
        switch self {
        case .ready: return false
        case .checking: return false
        default: return true
        }
    }

    public var displayText: String {
        switch self {
        case .checking: return "Checking permissions..."
        case .ready: return "All permissions granted"
        case .needsMicrophone: return "Microphone permission required"
        case .needsAccessibility: return "Accessibility permission required"
        case .needsBoth: return "Multiple permissions required"
        case .error(let error): return "Error: \(error.reason)"
        }
    }
}
