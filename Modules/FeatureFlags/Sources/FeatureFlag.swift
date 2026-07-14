import Foundation

/// Protocol defining a feature flag
public protocol FeatureFlag: Sendable {
    /// Unique identifier for the feature flag
    var key: String { get }
    
    /// Human-readable name for the feature
    var name: String { get }
    
    /// Description of what this feature flag controls
    var description: String { get }
    
    /// Default value for the feature flag
    var defaultValue: Bool { get }
    
    /// Whether this flag can be overridden in debug builds
    var allowsDebugOverride: Bool { get }
    
    /// Category for organization in debug menus
    var category: FeatureFlagCategory { get }
}

/// Categories for organizing feature flags
public enum FeatureFlagCategory: String, CaseIterable, Sendable {
    case speech = "Speech Recognition"
    case ui = "User Interface"
    case permissions = "Permissions"
    case performance = "Performance"
    case logging = "Logging & Debug"

    public var displayName: String {
        return rawValue
    }
}

/// Concrete feature flag implementation
public struct AppFeatureFlag: FeatureFlag, Sendable {
    public let key: String
    public let name: String
    public let description: String
    public let defaultValue: Bool
    public let allowsDebugOverride: Bool
    public let category: FeatureFlagCategory
    
    public init(
        key: String,
        name: String,
        description: String,
        defaultValue: Bool,
        allowsDebugOverride: Bool = true,
        category: FeatureFlagCategory
    ) {
        self.key = key
        self.name = name
        self.description = description
        self.defaultValue = defaultValue
        self.allowsDebugOverride = allowsDebugOverride
        self.category = category
    }
}

// MARK: - Predefined Feature Flags

public extension AppFeatureFlag {

    // MARK: - Speech Recognition
    
    static let enableWhisperEngine = AppFeatureFlag(
        key: "enable_whisper_engine",
        name: "Whisper Engine",
        description: "Enable WhisperKit for speech recognition",
        defaultValue: true,
        allowsDebugOverride: true,
        category: .speech
    )
    
    static let enableAppleSpeechEngine = AppFeatureFlag(
        key: "enable_apple_speech_engine",
        name: "System Speech Engine",
        description: "Enable built-in on-device speech recognition",
        defaultValue: true,
        allowsDebugOverride: true,
        category: .speech
    )
    
    static let enableRealTimeTranscription = AppFeatureFlag(
        key: "enable_real_time_transcription",
        name: "Real-time Transcription",
        description: "Show transcription results as they're being processed",
        defaultValue: true,
        allowsDebugOverride: true,
        category: .speech
    )
    
    // MARK: - UI Features
    
    static let enableContextualIndicator = AppFeatureFlag(
        key: "enable_contextual_indicator",
        name: "Contextual Indicator",
        description: "Show recording indicator near active text field",
        defaultValue: true,
        allowsDebugOverride: true,
        category: .ui
    )
    
    static let enableMenuBarStatus = AppFeatureFlag(
        key: "enable_menu_bar_status",
        name: "Menu Bar Status",
        description: "Show recording status in menu bar",
        defaultValue: true,
        allowsDebugOverride: true,
        category: .ui
    )
    
    static let enableOnboardingFlow = AppFeatureFlag(
        key: "enable_onboarding_flow",
        name: "Onboarding Flow",
        description: "Show onboarding screens for new users",
        defaultValue: true,
        allowsDebugOverride: true,
        category: .ui
    )
    
    // MARK: - Performance
    
    static let enableModelPreloading = AppFeatureFlag(
        key: "enable_model_preloading",
        name: "Model Preloading",
        description: "Preload speech recognition models for faster startup",
        defaultValue: true,
        allowsDebugOverride: true,
        category: .performance
    )
    
    static let enableConcurrentProcessing = AppFeatureFlag(
        key: "enable_concurrent_processing",
        name: "Concurrent Processing",
        description: "Process multiple audio chunks concurrently",
        defaultValue: true,
        allowsDebugOverride: true,
        category: .performance
    )
    
    // MARK: - Logging & Debug
    
    static let enableDetailedLogging = AppFeatureFlag(
        key: "enable_detailed_logging",
        name: "Detailed Logging",
        description: "Enable comprehensive application logging",
        defaultValue: false,
        allowsDebugOverride: true,
        category: .logging
    )
    
    static let enablePerformanceMetrics = AppFeatureFlag(
        key: "enable_performance_metrics",
        name: "Performance Metrics",
        description: "Collect and log performance metrics",
        defaultValue: false,
        allowsDebugOverride: true,
        category: .logging
    )
}

// MARK: - All Feature Flags Registry

public extension AppFeatureFlag {
    /// All available feature flags in the application
    static let allFlags: [AppFeatureFlag] = [
        // Speech
        .enableWhisperEngine,
        .enableAppleSpeechEngine,
        .enableRealTimeTranscription,
        
        // UI
        .enableContextualIndicator,
        .enableMenuBarStatus,
        .enableOnboardingFlow,
        
        // Performance
        .enableModelPreloading,
        .enableConcurrentProcessing,
        
        // Logging
        .enableDetailedLogging,
        .enablePerformanceMetrics
    ]
    
    /// Feature flags grouped by category
    static var flagsByCategory: [FeatureFlagCategory: [AppFeatureFlag]] {
        return Dictionary(grouping: allFlags) { $0.category }
    }
}