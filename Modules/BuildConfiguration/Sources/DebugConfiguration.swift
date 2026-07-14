import Foundation
import Combine

/// Runtime debug configuration that can be toggled in debug builds
@MainActor
public final class DebugConfiguration: ObservableObject {

    // MARK: - Singleton

    public static let shared = DebugConfiguration()

    private init() {
        #if DEBUG
        self.enableVerboseLogging = UserDefaults.standard.bool(forKey: Keys.enableVerboseLogging)
        self.simulateNetworkDelay = UserDefaults.standard.bool(forKey: Keys.simulateNetworkDelay)
        self.enableMockData = UserDefaults.standard.bool(forKey: Keys.enableMockData)
        #endif
    }

    // MARK: - Debug Toggles (Only available in DEBUG builds)

    #if DEBUG

    /// Enable verbose logging for debugging
    @Published public var enableVerboseLogging: Bool = false {
        didSet {
            UserDefaults.standard.set(enableVerboseLogging, forKey: Keys.enableVerboseLogging)
        }
    }

    /// Simulate network delays for testing
    @Published public var simulateNetworkDelay: Bool = false {
        didSet {
            UserDefaults.standard.set(simulateNetworkDelay, forKey: Keys.simulateNetworkDelay)
        }
    }

    /// Use mock data instead of real data
    @Published public var enableMockData: Bool = false {
        didSet {
            UserDefaults.standard.set(enableMockData, forKey: Keys.enableMockData)
        }
    }

    /// Reset all debug settings to default values
    public func resetToDefaults() {
        enableVerboseLogging = false
        simulateNetworkDelay = false
        enableMockData = false
    }

    #else

    public let enableVerboseLogging: Bool = false
    public let simulateNetworkDelay: Bool = false
    public let enableMockData: Bool = false

    public func resetToDefaults() {
        // No-op in production
    }

    #endif

    // MARK: - Configuration Properties

    /// Whether debug features are available (compile-time check)
    public var isDebugBuild: Bool {
        return BuildEnvironment.current.isDebug
    }

    // MARK: - Private

    private struct Keys {
        static let enableVerboseLogging = "DebugConfiguration.enableVerboseLogging"
        static let simulateNetworkDelay = "DebugConfiguration.simulateNetworkDelay"
        static let enableMockData = "DebugConfiguration.enableMockData"
    }
}

// MARK: - Notification Names

public extension Notification.Name {
    static let debugConfigurationChanged = Notification.Name("DebugConfigurationChanged")
}

// MARK: - Configuration Summary

public extension DebugConfiguration {
    /// Get a summary of current configuration for debugging
    var configurationSummary: String {
        var summary = ["=== Build Configuration ==="]
        summary.append("Environment: \(BuildEnvironment.current.displayName)")
        summary.append("Debug Build: \(isDebugBuild)")

        #if DEBUG
        summary.append("")
        summary.append("=== Debug Toggles ===")
        summary.append("Verbose Logging: \(enableVerboseLogging)")
        summary.append("Network Delay: \(simulateNetworkDelay)")
        summary.append("Mock Data: \(enableMockData)")
        #endif

        return summary.joined(separator: "\n")
    }
}
