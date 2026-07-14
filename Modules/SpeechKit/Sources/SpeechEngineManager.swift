import Foundation
import AVFoundation
import Speech
import Combine
import os.log
import AppServices

// MARK: - Debug Logging Helper

/// Simple logging helper that only prints in DEBUG builds
private struct SpeechEngineManagerLogger {
    static let performanceLogger = Logger(subsystem: "com.thetypealternative.performance", category: "SpeechEngineSwitch")
    
    static func config(_ message: String) {
        #if DEBUG
        print("🔧 SpeechEngineManager: \(message)")
        #endif
        performanceLogger.info("🔧 \(message)")
    }
    
    static func process(_ message: String) {
        #if DEBUG
        print("🔄 SpeechEngineManager: \(message)")
        #endif
        performanceLogger.info("🔄 \(message)")
    }
    
    static func target(_ message: String) {
        #if DEBUG
        print("🎯 SpeechEngineManager: \(message)")
        #endif
    }
    
    static func success(_ message: String) {
        #if DEBUG
        print("✅ SpeechEngineManager: \(message)")
        #endif
    }
    
    static func warning(_ message: String) {
        print("⚠️ SpeechEngineManager: \(message)")
    }
    
    static func error(_ message: String) {
        print("❌ SpeechEngineManager: \(message)")
    }
    
    static func list(_ message: String) {
        #if DEBUG
        print("📋 \(message)")
        #endif
    }
    
    static func item(_ message: String) {
        #if DEBUG
        print("   \(message)")
        #endif
    }
}

// MARK: - Settings Change Publisher

/// Protocol for objects that can publish settings changes
/// Emits (enginePreference, whisperModelPreference, localeIdentifier)
@MainActor
public protocol SettingsPublisher: AnyObject {
    var settingsChangePublisher: AnyPublisher<(String, String, String), Never> { get }
}

// MARK: - Adaptive Processing Strategy

/// Processing strategy for adaptive audio processing
public enum ProcessingStrategy: String, CaseIterable {
    case responsive = "responsive"    // 0.2s intervals for short words
    case balanced = "balanced"        // 0.5s intervals for normal speech  
    case efficient = "efficient"      // 1.0s intervals for long speech
    
    public var displayName: String {
        switch self {
        case .responsive: return "Responsive (Short Words)"
        case .balanced: return "Balanced (Normal Speech)"
        case .efficient: return "Efficient (Long Speech)"
        }
    }
    
    public var interval: TimeInterval {
        switch self {
        case .responsive: return 0.2
        case .balanced: return 0.5
        case .efficient: return 1.0
        }
    }
}

// MARK: - Speech Engine Manager

/// Manages available speech recognition engines and handles engine selection
/// Supports reactive engine recreation when settings change
@MainActor
public final class SpeechEngineManager: ObservableObject {
    
    // MARK: - Properties
    
    private var availableEngines: [SpeechRecognitionEngine] = []
    private var cancellables = Set<AnyCancellable>()
    
    // Model management
    public let modelManager = ModelManager()
    
    // MARK: - Adaptive Processing State (Reactive)
    
    @Published public private(set) var currentProcessingStrategy: ProcessingStrategy = .balanced
    @Published public private(set) var voiceActivityLevel: Double = 0.0
    @Published public private(set) var adaptiveTimeout: TimeInterval = 2.0
    @Published public private(set) var isProcessingOptimized: Bool = false
    
    // MARK: - Initialization
    
    public init() {
        createInitialEngines()
    }
    
    // MARK: - Reactive Settings Binding
    
    /// Bind to settings changes and recreate engines when needed
    public func bindToSettings<T: SettingsPublisher>(_ settings: T) {
        // React to settings changes
        settings.settingsChangePublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] (enginePreference, whisperModelPreference, localeIdentifier) in
                self?.recreateEngines(
                    enginePreference: enginePreference,
                    whisperModelPreference: whisperModelPreference,
                    localeIdentifier: localeIdentifier
                )
            }
            .store(in: &cancellables)

        // React to model download completion
        // Track previous status to detect transitions (not-available → available)
        // Initialize with current statuses to avoid false triggers on first observation
        var previousStatuses = modelManager.modelStatuses

        modelManager.$modelStatuses
            .receive(on: DispatchQueue.main)
            .sink { [weak self] statuses in
                guard let self = self else { return }

                // Check if any model just became available and it's the current preferred model
                let whisperModelPref = UserDefaults.standard.string(forKey: "WhisperModelPreference") ?? "tiny"

                let previousStatus = previousStatuses[whisperModelPref]
                let currentStatus = statuses[whisperModelPref]

                // Only react if status CHANGED from not-available to available
                // This prevents unnecessary recreation when model was already available at launch
                let wasNotAvailable: Bool = {
                    if let prev = previousStatus {
                        if case .available = prev { return false }
                        return true
                    }
                    return false  // No previous status means first observation, skip it
                }()

                let isNowAvailable: Bool = {
                    if case .available = currentStatus { return true }
                    return false
                }()

                if wasNotAvailable && isNowAvailable {
                    let enginePref = UserDefaults.standard.string(forKey: "SpeechEnginePreference") ?? "auto"

                    // Only reinitialize if using WhisperKit
                    if enginePref == "whisper" || enginePref == "auto" {
                        SpeechEngineManagerLogger.config("Model \(whisperModelPref) transitioned to available, reinitializing engine")
                        let localeIdentifier = UserDefaults.standard.string(forKey: "SelectedLocaleIdentifier") ?? "en-US"
                        self.recreateEngines(
                            enginePreference: enginePref,
                            whisperModelPreference: whisperModelPref,
                            localeIdentifier: localeIdentifier
                        )
                    }
                }
                // Note: Removed unnecessary "already available" logging that created noise
                // The important case is detecting transitions (wasNotAvailable && isNowAvailable)

                // Update previous status for next observation
                previousStatuses = statuses
            }
            .store(in: &cancellables)

        SpeechEngineManagerLogger.config("Bound to reactive settings")
    }
    
    // MARK: - Engine Management
    
    /// Create engines with current UserDefaults (fallback)
    private func createInitialEngines() {
        let enginePreference = UserDefaults.standard.string(forKey: "SpeechEnginePreference") ?? "auto"
        let whisperModelPreference = UserDefaults.standard.string(forKey: "WhisperModelPreference") ?? "base"
        let localeIdentifier = UserDefaults.standard.string(forKey: "SelectedLocaleIdentifier") ?? "en-US"

        recreateEngines(enginePreference: enginePreference, whisperModelPreference: whisperModelPreference, localeIdentifier: localeIdentifier)
    }
    
    /// Recreate engines based on new settings
    private func recreateEngines(enginePreference: String, whisperModelPreference: String, localeIdentifier: String) {
        let locale = Locale(identifier: localeIdentifier)
        let recreateStart = CFAbsoluteTimeGetCurrent()
        SpeechEngineManagerLogger.performanceLogger.info("🔄 Starting engine recreation - preference: \(enginePreference), model: \(whisperModelPreference), locale: \(localeIdentifier)")
        SpeechEngineManagerLogger.process("Recreating engines with preference: \(enginePreference), model: \(whisperModelPreference), locale: \(localeIdentifier)")

        // WhisperKit downloads models lazily when actually needed
        // No need for eager model preparation
        
        // Clear existing engines
        let clearStart = CFAbsoluteTimeGetCurrent()
        availableEngines.removeAll()
        let clearEnd = CFAbsoluteTimeGetCurrent()
        SpeechEngineManagerLogger.performanceLogger.info("🧹 Engine clearing: \((clearEnd - clearStart) * 1000)ms")
        
        // Create new engines based on preference
        let creationStart = CFAbsoluteTimeGetCurrent()
        var engines: [SpeechRecognitionEngine] = []

        // WhisperSupport.isEnabled is THE single switch for all WhisperKit surfaces
        // (AppConfiguration mirrors it; fall back to the switch when no DI container exists, e.g. unit tests)
        let supportsWhisperKit = AppConfiguration.current?.features.supportsWhisperKit ?? WhisperSupport.isEnabled

        if supportsWhisperKit {
            // WhisperKit supported: Use both Apple Speech and WhisperKit based on user preference
            switch enginePreference {
            case "whisper":
                SpeechEngineManagerLogger.performanceLogger.info("🎤 Creating Whisper-first engine set")
                // User prefers WhisperKit - add it first
                engines.append(createWhisperEngine(modelName: whisperModelPreference, locale: locale))
                engines.append(AppleSpeechEngine.forLocale(locale))
            case "apple":
                SpeechEngineManagerLogger.performanceLogger.info("🍎 Creating Apple-first engine set")
                // User prefers Apple Speech - add it first
                engines.append(AppleSpeechEngine.forLocale(locale))
                engines.append(createWhisperEngine(modelName: whisperModelPreference, locale: locale))
            default: // "auto"
                SpeechEngineManagerLogger.performanceLogger.info("🤖 Creating auto-selection engine set")
                // Auto selection - prioritize Apple Speech for reliability, WhisperKit as fallback
                engines.append(AppleSpeechEngine.forLocale(locale))
                engines.append(createWhisperEngine(modelName: whisperModelPreference, locale: locale))
            }
        } else {
            // WhisperKit disabled via WhisperSupport.isEnabled: Apple Speech only
            SpeechEngineManagerLogger.performanceLogger.info("🍎 Creating Apple Speech only engine set (WhisperKit not supported)")
            engines.append(AppleSpeechEngine.forLocale(locale))
        }
        
        let creationEnd = CFAbsoluteTimeGetCurrent()
        SpeechEngineManagerLogger.performanceLogger.info("🏗️ Engine creation: \((creationEnd - creationStart) * 1000)ms")
        
        let assignmentStart = CFAbsoluteTimeGetCurrent()
        self.availableEngines = engines
        let assignmentEnd = CFAbsoluteTimeGetCurrent()
        SpeechEngineManagerLogger.performanceLogger.info("📝 Engine assignment: \((assignmentEnd - assignmentStart) * 1000)ms")
        
        SpeechEngineManagerLogger.success("Recreated \(availableEngines.count) engines")
        
        let loggingStart = CFAbsoluteTimeGetCurrent()
        logAvailableEngines()
        let loggingEnd = CFAbsoluteTimeGetCurrent()
        SpeechEngineManagerLogger.performanceLogger.info("📋 Engine logging: \((loggingEnd - loggingStart) * 1000)ms")
        
        // Notify observers that engines have changed
        let notifyStart = CFAbsoluteTimeGetCurrent()
        objectWillChange.send()
        let notifyEnd = CFAbsoluteTimeGetCurrent()
        SpeechEngineManagerLogger.performanceLogger.info("📡 Observer notification: \((notifyEnd - notifyStart) * 1000)ms")
        
        let recreateEnd = CFAbsoluteTimeGetCurrent()
        SpeechEngineManagerLogger.performanceLogger.info("🏁 Total engine recreation: \((recreateEnd - recreateStart) * 1000)ms")
    }
    
    /// Create WhisperEngine with user-selected model and optimized configuration for speech recognition
    private func createWhisperEngine(modelName: String, locale: Locale) -> WhisperEngine {
        // Use ModelManager to get the best available model
        let actualModelName = modelManager.getBestAvailableModel(preferredModel: modelName)

        // Prepare the preferred model for future use (non-blocking)
        if actualModelName != modelName {
            modelManager.prepareModel(modelName)
        }

        let config = WhisperEngine.Configuration(
            modelName: actualModelName,
            locale: locale,
            enableTimestamps: false,
            enableVoiceActivityDetection: true,
            chunkSize: 2.0
        )

        SpeechEngineManagerLogger.target("Creating WhisperEngine with model '\(actualModelName)' (requested: '\(modelName)', locale: \(locale.identifier))")
        return WhisperEngine(configuration: config, speechEngineManager: self)
    }
    
    // MARK: - Engine Selection
    
    /// Select the best available speech recognition engine
    /// Respects user's preference order while ensuring availability and permissions
    public func selectBestEngine() -> SpeechRecognitionEngine? {
        // First try to use engines in the user's preferred order
        // The availableEngines array is already ordered by user preference
        let selectedEngine = availableEngines.first { engine in
            engine.isAvailable && hasAllPermissions(for: engine)
        }
        
        if let engine = selectedEngine {
            SpeechEngineManagerLogger.target("Selected \(engine.name)")
            return engine
        }
        
        // If no engine with all permissions, try to find any available engine
        // Still respecting the user's preference order
        let fallbackEngine = availableEngines.first { $0.isAvailable }
        
        if let engine = fallbackEngine {
            SpeechEngineManagerLogger.warning("Using fallback engine \(engine.name) (missing permissions)")
            return engine
        }
        
        SpeechEngineManagerLogger.error("No available engines found")
        return nil
    }
    
    /// Get all available engines for debugging or user selection
    public func getAllEngines() -> [SpeechRecognitionEngine] {
        return availableEngines
    }
    
    /// Get engines that are currently available
    public func getAvailableEngines() -> [SpeechRecognitionEngine] {
        return availableEngines.filter { $0.isAvailable }
    }
    
    // MARK: - Permission Checking
    
    private func hasAllPermissions(for engine: SpeechRecognitionEngine) -> Bool {
        for permission in engine.requiredPermissions {
            if !hasPermission(permission) {
                return false
            }
        }
        return true
    }
    
    private func hasPermission(_ permission: SpeechPermissionType) -> Bool {
        switch permission {
        case .microphone:
            #if os(macOS)
            // On macOS, check microphone permission using AVCaptureDevice
            return AVCaptureDevice.authorizationStatus(for: .audio) == .authorized
            #else
            return AVAudioSession.sharedInstance().recordPermission == .granted
            #endif
        }
    }
    
    // MARK: - Debugging
    
    private func logAvailableEngines() {
        SpeechEngineManagerLogger.list("Available Speech Engines:")
        for engine in availableEngines {
            let availability = engine.isAvailable ? "✅" : "❌"
            let permissions = engine.requiredPermissions.map { $0.displayName }.joined(separator: ", ")
            let hasAllPerms = hasAllPermissions(for: engine) ? "✅" : "❌"
            
            SpeechEngineManagerLogger.item("\(availability) \(engine.name)")
            SpeechEngineManagerLogger.item("    Permissions: \(permissions) \(hasAllPerms)")
        }
    }
    
    /// Force refresh engine availability (useful after permission changes)
    public func refreshEngineAvailability() {
        SpeechEngineManagerLogger.process("Refreshing engine availability")
        logAvailableEngines()
    }
    
    /// Update engine configuration when user preferences change
    public func updateEnginePreferences() {
        // Note: Engines are initialized once. For preference changes to take effect,
        // the app needs to be restarted or a new SpeechEngineManager instance created.
        // This could be enhanced in the future to support runtime engine reconfiguration.
        SpeechEngineManagerLogger.process("Engine preferences updated - restart app to apply changes")
    }
    
    // MARK: - Reactive State Updates
    
    /// Update processing strategy reactively
    public func updateProcessingStrategy(_ strategy: ProcessingStrategy) {
        currentProcessingStrategy = strategy
        SpeechEngineManagerLogger.process("Processing strategy updated to \(strategy.displayName)")
    }
    
    /// Update voice activity level for UI feedback
    public func updateVoiceActivityLevel(_ level: Double) {
        voiceActivityLevel = max(0.0, min(1.0, level))
    }
    
    /// Update adaptive timeout reactively  
    public func updateAdaptiveTimeout(_ timeout: TimeInterval) {
        adaptiveTimeout = timeout
    }
    
    /// Update processing optimization state
    public func updateProcessingOptimization(_ optimized: Bool) {
        isProcessingOptimized = optimized
    }
}

// MARK: - Engine Status Information

public struct EngineStatus {
    public let engine: SpeechRecognitionEngine
    public let isAvailable: Bool
    public let hasAllPermissions: Bool
    public let missingPermissions: [SpeechPermissionType]
    
    public var canBeUsed: Bool {
        return isAvailable && hasAllPermissions
    }
}

extension SpeechEngineManager {
    
    /// Get detailed status for all engines
    public func getEngineStatuses() -> [EngineStatus] {
        return availableEngines.map { engine in
            let hasAllPerms = hasAllPermissions(for: engine)
            let missing = engine.requiredPermissions.filter { !hasPermission($0) }
            
            return EngineStatus(
                engine: engine,
                isAvailable: engine.isAvailable,
                hasAllPermissions: hasAllPerms,
                missingPermissions: missing
            )
        }
    }
}
