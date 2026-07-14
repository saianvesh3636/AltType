import Foundation

// MARK: - Debug Logging Helper

/// Simple logging helper that only prints in DEBUG builds
private struct SpeechRecognizerLogger {
    static func initialize(_ message: String) {
        #if DEBUG
        print("🎯 SpeechRecognizer: \(message)")
        #endif
    }
    
    static func speech(_ message: String) {
        #if DEBUG
        print("🎤 SpeechRecognizer: \(message)")
        #endif
    }
    
    static func process(_ message: String) {
        #if DEBUG
        print("🔄 SpeechRecognizer: \(message)")
        #endif
    }
    
    static func stop(_ message: String) {
        #if DEBUG
        print("🛑 SpeechRecognizer: \(message)")
        #endif
    }
    
    static func success(_ message: String) {
        #if DEBUG
        print("✅ SpeechRecognizer: \(message)")
        #endif
    }
    
    static func warning(_ message: String) {
        print("⚠️ SpeechRecognizer: \(message)")
    }
    
    static func error(_ message: String) {
        print("❌ SpeechRecognizer: \(message)")
    }
    
    static func engine(_ message: String) {
        #if DEBUG
        print("🎯 \(message)")
        #endif
    }
    
    static func model(_ message: String) {
        #if DEBUG
        print("🔄 \(message)")
        #endif
    }
}

// MARK: - Speech Recognizer Delegate

@MainActor
public protocol SpeechRecognizerDelegate: AnyObject {
    func speechRecognizer(_ recognizer: SpeechRecognizer, didRecognizeText text: String, isFinal: Bool, confidence: Double)
    func speechRecognizer(_ recognizer: SpeechRecognizer, didFailWithError error: Error)
    func speechRecognizer(_ recognizer: SpeechRecognizer, didUpdateAudioLevel level: Double)
    
    // Processing unit reporting for usage tracking
    func speechRecognizer(_ recognizer: SpeechRecognizer, didRecognizeText text: String, processingUnits: ProcessingUnit, isFinal: Bool, confidence: Double)
}

// MARK: - Default Implementations
extension SpeechRecognizerDelegate {
    /// Default implementation for processing unit reporting (falls back to original text recognition)
    /// This allows existing delegates to work without modification
    public func speechRecognizer(_ recognizer: SpeechRecognizer, didRecognizeText text: String, processingUnits: ProcessingUnit, isFinal: Bool, confidence: Double) {
        // Default implementation calls the original method for backward compatibility
        speechRecognizer(recognizer, didRecognizeText: text, isFinal: isFinal, confidence: confidence)
    }
}

@MainActor
public protocol SpeechRecognizerModelLoadingDelegate: AnyObject {
    func speechRecognizer(_ recognizer: SpeechRecognizer, didUpdateModelLoadingState isLoading: Bool, progress: Double)
}

// MARK: - Speech Recognizer

/// Main speech recognizer that coordinates different recognition engines
/// Automatically selects the best available engine and provides fallback
@MainActor
public final class SpeechRecognizer: NSObject, @unchecked Sendable {
    
    // MARK: - Properties
    
    public weak var delegate: SpeechRecognizerDelegate?
    
    // MARK: - Public Properties
    
    /// Access to the speech engine manager for reactive state observation
    public var speechEngineManager: SpeechEngineManager {
        return engineManager
    }
    
    // MARK: - Private Properties
    
    private let engineManager: SpeechEngineManager
    private var currentEngine: SpeechRecognitionEngine?
    private var isRecording = false
    
    // MARK: - Initialization
    
    public override init() {
        self.engineManager = SpeechEngineManager()
        super.init()
        
        SpeechRecognizerLogger.initialize("Initialized with modular engine architecture")
    }
    
    /// Initialize with provided SpeechEngineManager for shared state
    public init(speechEngineManager: SpeechEngineManager) {
        self.engineManager = speechEngineManager
        super.init()
        
        SpeechRecognizerLogger.initialize("Initialized with shared SpeechEngineManager")
    }
    
    /// Initialize with reactive speech engine settings
    public convenience init<T: SettingsPublisher>(speechEngineSettings: T) {
        self.init()
        
        // Bind the existing manager to settings
        engineManager.bindToSettings(speechEngineSettings)
        
        SpeechRecognizerLogger.initialize("Initialized with reactive speech engine settings")
    }
    
    // MARK: - Public Interface
    
    /// Start speech recognition using the best available engine
    public func startRecording() {
        SpeechRecognizerLogger.speech(".startRecording called")
        
        guard !isRecording else {
            SpeechRecognizerLogger.warning("Already recording, ignoring duplicate start call")
            return
        }
        
        // Stop any existing recognition (cleanup)
        if currentEngine != nil {
            SpeechRecognizerLogger.process("Cleaning up previous engine")
            stopRecording()
        }
        
        // Select best available engine
        guard let engine = engineManager.selectBestEngine() else {
            let error = SpeechRecognitionEngineError.engineNotAvailable
            SpeechRecognizerLogger.error("No available speech recognition engines")
            delegate?.speechRecognizer(self, didFailWithError: error)
            return
        }
        
        // Attempt to start with selected engine
        currentEngine = engine
        SpeechRecognizerLogger.initialize("Starting with engine: \(engine.name)")
        
        do {
            try engine.startRecognition(delegate: self)
            isRecording = true
            SpeechRecognizerLogger.success("started successfully with \(engine.name)")
        } catch {
            SpeechRecognizerLogger.error("Engine \(engine.name) failed to start: \(error)")
            currentEngine = nil
            
            // Try fallback engine
            attemptFallbackEngine(primaryError: error)
        }
    }
    
    /// Stop speech recognition and clean up resources
    public func stopRecording() {
        SpeechRecognizerLogger.stop(".stopRecording called")
        
        guard isRecording else {
            SpeechRecognizerLogger.warning("Not recording, ignoring stop call")
            return
        }
        
        guard let engine = currentEngine else {
            SpeechRecognizerLogger.warning("No active engine to stop")
            isRecording = false
            return
        }
        
        SpeechRecognizerLogger.stop("Stopping engine: \(engine.name)")
        engine.stopRecognition()
        
        // Clean up state
        currentEngine = nil
        isRecording = false
        
        SpeechRecognizerLogger.success("stopped successfully")
    }
    
    // MARK: - Engine Management
    
    /// Get information about available engines (for debugging/UI)
    public func getEngineStatuses() -> [EngineStatus] {
        return engineManager.getEngineStatuses()
    }
    
    /// Get the currently active engine name (if any)
    public var currentEngineName: String? {
        return currentEngine?.name
    }
    
    /// Whether speech recognition is currently active
    public var isListening: Bool {
        return isRecording
    }
    
    // MARK: - Private Methods
    
    private func attemptFallbackEngine(primaryError: Error) {
        let availableEngines = engineManager.getAvailableEngines()
        
        // Find a different engine than the one that failed
        let fallbackEngine = availableEngines.first { engine in
            engine.name != currentEngine?.name
        }
        
        guard let fallback = fallbackEngine else {
            SpeechRecognizerLogger.error("No fallback engines available")
            delegate?.speechRecognizer(self, didFailWithError: primaryError)
            return
        }
        
        SpeechRecognizerLogger.process("Attempting fallback with: \(fallback.name)")
        currentEngine = fallback
        
        do {
            try fallback.startRecognition(delegate: self)
            isRecording = true
            SpeechRecognizerLogger.success("Fallback engine \(fallback.name) started successfully")
        } catch {
            SpeechRecognizerLogger.error("Fallback engine also failed: \(error)")
            currentEngine = nil
            delegate?.speechRecognizer(self, didFailWithError: error)
        }
    }
}

// MARK: - SpeechRecognitionEngineDelegate

extension SpeechRecognizer: SpeechRecognitionEngineDelegate {
    
    public func speechEngine(_ engine: SpeechRecognitionEngine, didRecognizeText text: String, isFinal: Bool, confidence: Double) {
        SpeechRecognizerLogger.engine("\(engine.name): '\(text)' (final: \(isFinal), confidence: \(String(format: "%.2f", confidence)))")
        delegate?.speechRecognizer(self, didRecognizeText: text, isFinal: isFinal, confidence: confidence)
    }
    
    public func speechEngine(_ engine: SpeechRecognitionEngine, didRecognizeText text: String, processingUnits: ProcessingUnit, isFinal: Bool, confidence: Double) {
        SpeechRecognizerLogger.engine("\(engine.name): '\(text)' (\(processingUnits.count) \(processingUnits.unitType), final: \(isFinal), confidence: \(String(format: "%.2f", confidence)))")
        delegate?.speechRecognizer(self, didRecognizeText: text, processingUnits: processingUnits, isFinal: isFinal, confidence: confidence)
    }
    
    public func speechEngine(_ engine: SpeechRecognitionEngine, didFailWithError error: Error) {
        SpeechRecognizerLogger.error("\(engine.name) failed: \(error)")
        
        // Clean up current engine
        currentEngine = nil
        isRecording = false
        
        delegate?.speechRecognizer(self, didFailWithError: error)
    }
    
    public func speechEngine(_ engine: SpeechRecognitionEngine, didUpdateAudioLevel level: Double) {
        // Forward audio level updates to delegate for visualization
        delegate?.speechRecognizer(self, didUpdateAudioLevel: level)
    }
    
    public func speechEngine(_ engine: SpeechRecognitionEngine, didUpdateModelLoadingState isLoading: Bool, progress: Double) {
        // Forward model loading state to delegate for UI feedback
        if let recognizerDelegate = delegate as? SpeechRecognizerModelLoadingDelegate {
            recognizerDelegate.speechRecognizer(self, didUpdateModelLoadingState: isLoading, progress: progress)
        }
        
        SpeechRecognizerLogger.model("\(engine.name): Model loading state - isLoading: \(isLoading), progress: \(String(format: "%.1f%%", progress * 100))")
    }
}