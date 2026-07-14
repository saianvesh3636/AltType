import Foundation

/// Processing unit types for usage tracking
public enum ProcessingUnit: Codable, Sendable {
    case words(Int)     // For Apple Speech Framework (word-based counting)
    case tokens(Int)    // For WhisperKit and other token-based engines
    
    /// Get the raw count value regardless of unit type
    public var count: Int {
        switch self {
        case .words(let count), .tokens(let count):
            return count
        }
    }
    
    /// Convert to a standardized unit (using words as base)
    /// Tokens are roughly equivalent to 0.75 words on average
    public var normalizedWordCount: Double {
        switch self {
        case .words(let count):
            return Double(count)
        case .tokens(let count):
            return Double(count) * 0.75
        }
    }
    
    /// Unit type description
    public var unitType: String {
        switch self {
        case .words: return "words"
        case .tokens: return "tokens"
        }
    }
    
    /// Add processing units together (converts to common base)
    public static func + (lhs: ProcessingUnit, rhs: ProcessingUnit) -> ProcessingUnit {
        let totalWords = lhs.normalizedWordCount + rhs.normalizedWordCount
        return .words(Int(totalWords))
    }
}

// MARK: - Core Speech Recognition Protocol

/// Protocol defining the interface for different speech recognition backends
/// This allows easy swapping between Apple Speech Framework, WhisperKit, etc.
@MainActor
public protocol SpeechRecognitionEngine {
    /// Human-readable name for this recognition engine
    var name: String { get }
    
    /// Whether this engine is available on the current device
    var isAvailable: Bool { get }
    
    /// System permissions required by this engine
    var requiredPermissions: [SpeechPermissionType] { get }
    
    /// Start speech recognition with the provided delegate
    func startRecognition(delegate: SpeechRecognitionEngineDelegate) throws
    
    /// Stop speech recognition and clean up resources
    func stopRecognition()
}

// MARK: - Speech Recognition Delegate

@MainActor
public protocol SpeechRecognitionEngineDelegate: AnyObject {
    func speechEngine(_ engine: SpeechRecognitionEngine, didRecognizeText text: String, isFinal: Bool, confidence: Double)
    func speechEngine(_ engine: SpeechRecognitionEngine, didFailWithError error: Error)
    func speechEngine(_ engine: SpeechRecognitionEngine, didUpdateAudioLevel level: Double)
    func speechEngine(_ engine: SpeechRecognitionEngine, didUpdateModelLoadingState isLoading: Bool, progress: Double)
    
    // Processing unit reporting for usage tracking
    func speechEngine(_ engine: SpeechRecognitionEngine, didRecognizeText text: String, processingUnits: ProcessingUnit, isFinal: Bool, confidence: Double)
}

// MARK: - Default Implementations
extension SpeechRecognitionEngineDelegate {
    /// Default implementation for model loading state updates (optional for engines that don't need it)
    public func speechEngine(_ engine: SpeechRecognitionEngine, didUpdateModelLoadingState isLoading: Bool, progress: Double) {
        // Default no-op implementation - engines like Apple Speech don't need model loading
    }
    
    /// Default implementation for processing unit reporting (falls back to original text recognition)
    /// This allows existing delegates to work without modification
    public func speechEngine(_ engine: SpeechRecognitionEngine, didRecognizeText text: String, processingUnits: ProcessingUnit, isFinal: Bool, confidence: Double) {
        // Default implementation calls the original method for backward compatibility
        speechEngine(engine, didRecognizeText: text, isFinal: isFinal, confidence: confidence)
    }
}

// MARK: - Permission Types

public enum SpeechPermissionType: CaseIterable, Sendable {
    case microphone

    public var displayName: String {
        switch self {
        case .microphone:
            return "Microphone"
        }
    }
}

// MARK: - Speech Recognition Errors

public enum SpeechRecognitionEngineError: LocalizedError, Sendable {
    case engineNotAvailable
    case permissionDenied(SpeechPermissionType)
    case initializationFailed(String)
    case recognitionFailed(String)
    
    public var errorDescription: String? {
        switch self {
        case .engineNotAvailable:
            return "Speech recognition engine is not available on this device"
        case .permissionDenied(let type):
            return "\(type.displayName) permission is required for speech recognition"
        case .initializationFailed(let details):
            return "Failed to initialize speech recognition: \(details)"
        case .recognitionFailed(let details):
            return "Speech recognition failed: \(details)"
        }
    }
}