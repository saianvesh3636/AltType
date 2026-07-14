import Foundation
import Combine
import BuildConfiguration

/// Manages feature flags throughout the application
@MainActor
public final class FeatureFlagManager: ObservableObject {
    
    // MARK: - Singleton
    
    public static let shared = FeatureFlagManager()
    
    private init() {
        // Load initial values from UserDefaults
        loadStoredValues()
        setupConfigurationObserver()
    }
    
    // MARK: - Published Properties
    
    @Published private var overrideValues: [String: Bool] = [:]
    @Published private var debugConfiguration: DebugConfiguration?
    
    // MARK: - Private Properties
    
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Public Interface
    
    /// Check if a feature flag is enabled
    public func isEnabled(_ flag: FeatureFlag) -> Bool {
        // In production builds, debug overrides are ignored
        #if DEBUG
        // If debug configuration allows override and we have a stored override value
        if debugConfiguration?.isDebugBuild == true,
           flag.allowsDebugOverride,
           let overrideValue = overrideValues[flag.key] {
            return overrideValue
        }
        #endif

        // Return default value
        return flag.defaultValue
    }
    
    /// Set an override value for a feature flag (debug builds only)
    public func setOverride(for flag: FeatureFlag, value: Bool) {
        #if DEBUG
        guard flag.allowsDebugOverride else { return }
        
        overrideValues[flag.key] = value
        UserDefaults.standard.set(value, forKey: userDefaultsKey(for: flag))
        
        // Notify observers
        objectWillChange.send()
        
        // Post notification for specific flag change
        NotificationCenter.default.post(
            name: .featureFlagChanged,
            object: self,
            userInfo: [
                "flagKey": flag.key,
                "enabled": value,
                "isOverride": true
            ]
        )
        #endif
    }
    
    /// Remove override for a feature flag (debug builds only)
    public func removeOverride(for flag: FeatureFlag) {
        #if DEBUG
        overrideValues.removeValue(forKey: flag.key)
        UserDefaults.standard.removeObject(forKey: userDefaultsKey(for: flag))

        objectWillChange.send()

        NotificationCenter.default.post(
            name: .featureFlagChanged,
            object: self,
            userInfo: [
                "flagKey": flag.key,
                "enabled": flag.defaultValue,
                "isOverride": false
            ]
        )
        #endif
    }
    
    /// Check if a flag has an active override (debug builds only)
    public func hasOverride(for flag: FeatureFlag) -> Bool {
        #if DEBUG
        return overrideValues[flag.key] != nil
        #else
        return false
        #endif
    }
    
    /// Get the current effective value and whether it's overridden
    public func flagStatus(for flag: FeatureFlag) -> (enabled: Bool, isOverridden: Bool) {
        let enabled = isEnabled(flag)
        let isOverridden = hasOverride(for: flag)
        return (enabled: enabled, isOverridden: isOverridden)
    }
    
    /// Reset all overrides (debug builds only)
    public func resetAllOverrides() {
        #if DEBUG
        for flag in AppFeatureFlag.allFlags {
            UserDefaults.standard.removeObject(forKey: userDefaultsKey(for: flag))
        }
        overrideValues.removeAll()
        objectWillChange.send()
        
        NotificationCenter.default.post(
            name: .featureFlagsReset,
            object: self
        )
        #endif
    }
    
    /// Get configuration summary for debugging
    public var configurationSummary: String {
        var summary = ["=== Feature Flag Configuration ==="]
        
        let flagsByCategory = AppFeatureFlag.flagsByCategory
        for category in FeatureFlagCategory.allCases.sorted(by: { $0.displayName < $1.displayName }) {
            guard let flags = flagsByCategory[category], !flags.isEmpty else { continue }
            
            summary.append("")
            summary.append("[\(category.displayName)]")
            
            for flag in flags.sorted(by: { $0.name < $1.name }) {
                let status = flagStatus(for: flag)
                let statusIndicator = status.enabled ? "✓" : "✗"
                let overrideIndicator = status.isOverridden ? " (override)" : ""
                summary.append("  \(statusIndicator) \(flag.name)\(overrideIndicator)")
            }
        }
        
        return summary.joined(separator: "\n")
    }
    
    // MARK: - Private Methods
    
    private func loadStoredValues() {
        #if DEBUG
        for flag in AppFeatureFlag.allFlags {
            guard flag.allowsDebugOverride else { continue }
            
            let key = userDefaultsKey(for: flag)
            if UserDefaults.standard.object(forKey: key) != nil {
                overrideValues[flag.key] = UserDefaults.standard.bool(forKey: key)
            }
        }
        #endif
    }
    
    private func setupConfigurationObserver() {
        #if DEBUG
        // Keep a reference for debug-build override gating
        debugConfiguration = DebugConfiguration.shared
        #endif
    }
    
    private func userDefaultsKey(for flag: FeatureFlag) -> String {
        return "FeatureFlag.\(flag.key)"
    }
}

// MARK: - Notification Names

public extension Notification.Name {
    static let featureFlagChanged = Notification.Name("FeatureFlagChanged")
    static let featureFlagsReset = Notification.Name("FeatureFlagsReset")
}

// MARK: - Convenience Methods

public extension FeatureFlagManager {

    // MARK: - Speech Recognition Flags
    
    var isWhisperEngineEnabled: Bool {
        isEnabled(AppFeatureFlag.enableWhisperEngine)
    }
    
    var isAppleSpeechEngineEnabled: Bool {
        isEnabled(AppFeatureFlag.enableAppleSpeechEngine)
    }
    
    var isRealTimeTranscriptionEnabled: Bool {
        isEnabled(AppFeatureFlag.enableRealTimeTranscription)
    }
    
    // MARK: - UI Flags
    
    var isContextualIndicatorEnabled: Bool {
        isEnabled(AppFeatureFlag.enableContextualIndicator)
    }
    
    var isMenuBarStatusEnabled: Bool {
        isEnabled(AppFeatureFlag.enableMenuBarStatus)
    }
    
    var isOnboardingFlowEnabled: Bool {
        isEnabled(AppFeatureFlag.enableOnboardingFlow)
    }
    
    // MARK: - Performance Flags
    
    var isModelPreloadingEnabled: Bool {
        isEnabled(AppFeatureFlag.enableModelPreloading)
    }
    
    var isConcurrentProcessingEnabled: Bool {
        isEnabled(AppFeatureFlag.enableConcurrentProcessing)
    }
    
    // MARK: - Logging Flags
    
    var isDetailedLoggingEnabled: Bool {
        isEnabled(AppFeatureFlag.enableDetailedLogging)
    }
    
    var isPerformanceMetricsEnabled: Bool {
        isEnabled(AppFeatureFlag.enablePerformanceMetrics)
    }
}