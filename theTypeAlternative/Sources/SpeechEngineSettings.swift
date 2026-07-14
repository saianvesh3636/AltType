import Foundation
import Combine
import SwiftUI
import SpeechKit
import AppServices

// MARK: - Speech Engine Preference Types

public enum SpeechEnginePreference: String, CaseIterable, Identifiable {
    case auto = "auto"
    case appleSpeech = "apple"
    case whisperKit = "whisper"
    
    public var id: String { rawValue }
    
    var displayName: String {
        switch self {
        case .auto:
            return "Automatic"
        case .appleSpeech:
            return "System Speech"
        case .whisperKit:
            return "WhisperKit"
        }
    }
    
    var description: String {
        switch self {
        case .auto:
            return "Let AltType choose the best engine"
        case .appleSpeech:
            return "Use built-in on-device speech recognition"
        case .whisperKit:
            return "Use WhisperKit for local speech processing"
        }
    }
    
    var systemImage: String {
        switch self {
        case .auto:
            return "wand.and.rays"
        case .appleSpeech:
            return "waveform.circle"
        case .whisperKit:
            return "brain.head.profile"
        }
    }
}

public enum WhisperModelPreference: String, CaseIterable, Identifiable {
    case tiny = "tiny"
    case base = "base"
    case small = "small"
    case medium = "medium"
    // Note: "large" model not available in WhisperKit - removed

    public var id: String { rawValue }
    
    var displayName: String {
        switch self {
        case .tiny:
            return "Tiny (39M parameters)"
        case .base:
            return "Base (74M parameters)"
        case .small:
            return "Small (244M parameters)"
        case .medium:
            return "Medium (769M parameters)"
        }
    }
    
    var description: String {
        switch self {
        case .tiny:
            return "Quick processing, basic accuracy — ideal for real-time use"
        case .base:
            return "Recommended: Good balance of speed and accuracy"
        case .small:
            return "Better accuracy with moderate processing time"
        case .medium:
            return "Higher accuracy, handles accents and noise well"
        }
    }
    
    var sizeInfo: String {
        switch self {
        case .tiny:
            return "39 MB"
        case .base:
            return "74 MB"
        case .small:
            return "244 MB"
        case .medium:
            return "769 MB"
        }
    }
    
    var speedRating: Int {
        switch self {
        case .tiny:
            return 5
        case .base:
            return 4
        case .small:
            return 3
        case .medium:
            return 2
        }
    }
    
    var accuracyRating: Int {
        switch self {
        case .tiny:
            return 1
        case .base:
            return 2
        case .small:
            return 3
        case .medium:
            return 4
        }
    }
}

// MARK: - Speech Engine Settings

/// Observable settings for speech engine configuration
/// Uses SwiftUI reactive patterns with @Published properties
@MainActor
public final class SpeechEngineSettings: ObservableObject, SpeechKit.SettingsPublisher {

    // MARK: - Dependencies

    private var cancellables = Set<AnyCancellable>()

    // MARK: - Published Properties

    // Default to .auto to avoid requesting Documents permission on first launch
    // When user explicitly selects WhisperKit in Settings, explanation window will be shown first
    @Published var enginePreference: SpeechEnginePreference = .auto
    // Default to .tiny for faster first-time download (76MB vs 147MB for base)
    @Published var whisperModelPreference: WhisperModelPreference = .tiny
    // Recognition locale — drives both SpeechAnalyzer and WhisperKit
    @Published var selectedLocaleIdentifier: String = "en-US"

    // MARK: - Availability

    /// Available engine preferences
    @Published private(set) var availableEnginePreferences: [SpeechEnginePreference] = []

    /// Available WhisperKit models
    @Published private(set) var availableWhisperModels: [WhisperModelPreference] = []

    @Published var enableSounds: Bool = true
    @Published var silenceTimeout: Double = 15.0
    
    // MARK: - Computed Properties
    
    /// Publisher for settings changes: (engine preference, whisper model, locale identifier)
    /// Includes initial values and all subsequent changes
    public var settingsChangePublisher: AnyPublisher<(String, String, String), Never> {
        Publishers.CombineLatest3(
            $enginePreference,
            $whisperModelPreference,
            $selectedLocaleIdentifier
        )
        .map { enginePref, modelPref, localeId in
            (enginePref.rawValue, modelPref.rawValue, localeId)
        }
        .eraseToAnyPublisher()
    }
    
    // MARK: - Initialization

    init() {
        // Initialize with UserDefaults (will be enhanced with reactive bindings later)
        // Default to .auto on first launch to avoid requesting Documents permission before explanation
        let enginePref = UserDefaults.standard.string(forKey: "SpeechEnginePreference") ?? SpeechEnginePreference.auto.rawValue
        // Default to .tiny for faster first-time download (76MB vs 147MB for base)
        let whisperModelPref = UserDefaults.standard.string(forKey: "WhisperModelPreference") ?? WhisperModelPreference.tiny.rawValue

        let loadedEnginePreference = SpeechEnginePreference(rawValue: enginePref) ?? .auto
        let loadedWhisperPreference = WhisperModelPreference(rawValue: whisperModelPref) ?? .tiny

        self.enginePreference = loadedEnginePreference
        self.whisperModelPreference = loadedWhisperPreference
        self.selectedLocaleIdentifier = UserDefaults.standard.string(forKey: "SelectedLocaleIdentifier") ?? "en-US"
        self.enableSounds = UserDefaults.standard.object(forKey: "EnableSounds") as? Bool ?? true
        self.silenceTimeout = UserDefaults.standard.object(forKey: "SilenceTimeout") as? Double ?? 15.0
        
        // Set up reactive bindings with UserDefaults
        setupUserDefaultsBinding()

        // Update available options and make sure stored selections are still valid
        // (e.g. a stored WhisperKit preference while WhisperSupport is disabled)
        updateAvailableOptions()
        validateCurrentSelections()
    }
    
    // MARK: - UserDefaults Integration
    
    private func setupUserDefaultsBinding() {
        // Handle user changes - save to UserDefaults with validation
        $enginePreference
            .dropFirst()
            .sink { [weak self] preference in
                if let validatedPreference = self?.validateEnginePreference(preference) {
                    UserDefaults.standard.set(validatedPreference.rawValue, forKey: "SpeechEnginePreference")
                    Logger.debug("SpeechEngineSettings: Engine preference changed to \(validatedPreference.rawValue)")
                }
            }
            .store(in: &cancellables)

        $whisperModelPreference
            .dropFirst()
            .sink { [weak self] model in
                if let validatedModel = self?.validateWhisperModel(model) {
                    UserDefaults.standard.set(validatedModel.rawValue, forKey: "WhisperModelPreference")
                    Logger.debug("SpeechEngineSettings: WhisperKit model changed to \(validatedModel.rawValue)")
                }
            }
            .store(in: &cancellables)

        $selectedLocaleIdentifier
            .dropFirst()
            .sink { localeId in
                UserDefaults.standard.set(localeId, forKey: "SelectedLocaleIdentifier")
                Logger.debug("SpeechEngineSettings: Recognition locale changed to \(localeId)")
            }
            .store(in: &cancellables)

        $enableSounds
            .dropFirst()
            .sink { enabled in
                UserDefaults.standard.set(enabled, forKey: "EnableSounds")
            }
            .store(in: &cancellables)

        $silenceTimeout
            .dropFirst()
            .sink { timeout in
                UserDefaults.standard.set(timeout, forKey: "SilenceTimeout")
            }
            .store(in: &cancellables)
    }

    private func updateAvailableOptions() {
        // WhisperSupport.isEnabled is THE single switch for all WhisperKit surfaces
        if WhisperSupport.isEnabled {
            availableEnginePreferences = SpeechEnginePreference.allCases
            availableWhisperModels = WhisperModelPreference.allCases
        } else {
            availableEnginePreferences = [.appleSpeech]
            availableWhisperModels = []
        }
    }

    private func validateCurrentSelections() {
        let validEngine = validateEnginePreference(enginePreference)
        if validEngine != enginePreference {
            enginePreference = validEngine
        }

        if WhisperSupport.isEnabled {
            let validModel = validateWhisperModel(whisperModelPreference)
            if validModel != whisperModelPreference {
                whisperModelPreference = validModel
            }
        }
    }

    private func validateEnginePreference(_ preference: SpeechEnginePreference) -> SpeechEnginePreference {
        if availableEnginePreferences.contains(preference) {
            return preference
        }

        // Fallback to first available option
        if let fallback = availableEnginePreferences.first {
            Logger.debug("SpeechEngineSettings: Engine \(preference.rawValue) not available, falling back to \(fallback.rawValue)")
            return fallback
        }

        // This should never happen, but fallback to auto if no options available
        Logger.error("SpeechEngineSettings: No engine preferences available, falling back to auto")
        return .auto
    }

    private func validateWhisperModel(_ model: WhisperModelPreference) -> WhisperModelPreference {
        if availableWhisperModels.contains(model) {
            return model
        }

        // Fallback to first available model
        if let fallback = availableWhisperModels.first {
            Logger.debug("SpeechEngineSettings: Model \(model.rawValue) not available, falling back to \(fallback.rawValue)")
            return fallback
        }

        // Fallback to tiny if no models available (shouldn't happen)
        Logger.error("SpeechEngineSettings: No WhisperKit models available, falling back to tiny")
        return .tiny
    }

    // MARK: - Availability Checks

    /// Check if a specific engine preference is available
    public func isEngineAvailable(_ preference: SpeechEnginePreference) -> Bool {
        return availableEnginePreferences.contains(preference)
    }

    /// Check if a specific WhisperKit model is available
    public func isModelAvailable(_ model: WhisperModelPreference) -> Bool {
        return availableWhisperModels.contains(model)
    }

    // MARK: - Configuration Creation
    
    /// Create WhisperEngine configuration based on current settings
    func createWhisperConfiguration() -> WhisperEngineConfiguration {
        return WhisperEngineConfiguration(
            modelName: whisperModelPreference.rawValue,
            locale: Locale(identifier: selectedLocaleIdentifier),
            enableTimestamps: false,
            enableVoiceActivityDetection: true,
            chunkSize: 2.0
        )
    }
}

// MARK: - WhisperEngine Configuration

/// Configuration for WhisperEngine that can be created reactively
public struct WhisperEngineConfiguration {
    public let modelName: String
    public let locale: Locale
    public let enableTimestamps: Bool
    public let enableVoiceActivityDetection: Bool
    public let chunkSize: TimeInterval
}