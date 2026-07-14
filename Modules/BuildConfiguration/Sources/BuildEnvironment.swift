import Foundation

/// Defines the build environment configuration
public enum BuildEnvironment: String, CaseIterable, Sendable {
    case debug = "DEBUG"
    case production = "PRODUCTION"

    /// Current build environment determined at compile time
    public static let current: BuildEnvironment = {
        #if DEBUG
        return .debug
        #else
        return .production
        #endif
    }()

    /// Whether this is a debug build
    public var isDebug: Bool {
        return self == .debug
    }

    /// Whether this is a production build
    public var isProduction: Bool {
        return self == .production
    }

    /// Whether debug features should be available
    public var allowsDebugFeatures: Bool {
        switch self {
        case .debug:
            return true
        case .production:
            return false
        }
    }

    /// Bundle identifier suffix for different environments
    public var bundleIdSuffix: String {
        switch self {
        case .debug:
            return ".debug"
        case .production:
            return ""
        }
    }

    /// Display name for the environment
    public var displayName: String {
        switch self {
        case .debug:
            return "Debug"
        case .production:
            return "Production"
        }
    }
}
