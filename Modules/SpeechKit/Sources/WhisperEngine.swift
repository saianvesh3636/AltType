import Foundation
@preconcurrency import AVFoundation
@preconcurrency import WhisperKit

// MARK: - Debug Logging Helper

/// Simple logging helper that only prints in DEBUG builds
private struct WhisperEngineLogger {
    static func engine(_ message: String) {
        #if DEBUG
        print("🤖 WhisperEngine: \(message)")
        #endif
    }
    
    static func process(_ message: String) {
        #if DEBUG
        print("🔄 WhisperEngine: \(message)")
        #endif
    }
    
    static func timing(_ message: String) {
        #if DEBUG
        print("⏱️ WhisperEngine: \(message)")
        #endif
    }
    
    static func transcription(_ message: String) {
        #if DEBUG
        print("🎯 WhisperEngine: \(message)")
        #endif
    }
    
    static func audio(_ message: String) {
        #if DEBUG
        print("🎤 WhisperEngine: \(message)")
        #endif
    }
    
    static func model(_ message: String) {
        #if DEBUG
        print("🔥 WhisperEngine: \(message)")
        #endif
    }
    
    static func success(_ message: String) {
        #if DEBUG
        print("✅ WhisperEngine: \(message)")
        #endif
    }
    
    static func warning(_ message: String) {
        print("⚠️ WhisperEngine: \(message)")
    }
    
    static func error(_ message: String) {
        print("❌ WhisperEngine: \(message)")
    }
    
    static func vad(_ message: String) {
        #if DEBUG
        print("🔍 WhisperEngine: \(message)")
        #endif
    }
    
    static func buffer(_ message: String) {
        #if DEBUG
        print("🔊 WhisperEngine: \(message)")
        #endif
    }
    
    static func speech(_ message: String) {
        #if DEBUG
        print("🔇 WhisperEngine: \(message)")
        #endif
    }
    
    static func stop(_ message: String) {
        #if DEBUG
        print("🛑 WhisperEngine: \(message)")
        #endif
    }
}

// MARK: - Circular Buffer Implementation for O(1) Operations

/// High-performance circular buffer for audio samples with O(1) append and trim operations
private struct CircularBuffer<T> {
    private var buffer: [T?]
    private var capacity: Int
    private var head: Int = 0
    private var tail: Int = 0
    private var count: Int = 0
    
    init(capacity: Int) {
        self.capacity = capacity
        self.buffer = Array(repeating: nil, count: capacity)
    }
    
    var isEmpty: Bool { count == 0 }
    var isFull: Bool { count == capacity }
    
    /// O(1) append operation
    mutating func append(contentsOf elements: [T]) {
        for element in elements {
            buffer[tail] = element
            tail = (tail + 1) % capacity
            
            if isFull {
                head = (head + 1) % capacity // Overwrite oldest
            } else {
                count += 1
            }
        }
    }
    
    /// O(1) trim operation (auto-handled by circular nature)
    func trimToCapacity() {
        // No-op: circular buffer automatically maintains capacity
    }
    
    /// O(n) copy to array when needed for processing
    func toArray() -> [T] {
        var result: [T] = []
        result.reserveCapacity(count)
        
        var index = head
        for _ in 0..<count {
            if let element = buffer[index] {
                result.append(element)
            }
            index = (index + 1) % capacity
        }
        return result
    }
    
    /// Current number of elements
    var currentCount: Int { count }
}

// MARK: - Voice Activity Detection Cache

private struct VADResult {
    let hasVoice: Bool
    let confidence: Float
    let timestamp: Date
}

// MARK: - Simple VAD Support
// No complex spectral features needed - keep it simple

// MARK: - WhisperKit Speech Recognition Engine

/// Speech recognition engine using WhisperKit for completely on-device processing
/// This serves as a fallback when Apple's Speech Framework is unavailable
@MainActor
public final class WhisperEngine: SpeechRecognitionEngine {
    
    // MARK: - SpeechRecognitionEngine Protocol
    
    public let name = "WhisperKit Engine"
    
    public var isAvailable: Bool {
        // Check if WhisperKit can be initialized on this device
        // This is more conservative than the Apple Speech check
        #if targetEnvironment(simulator)
        return false  // WhisperKit may not work well in simulator
        #else
        // Only report as available if WhisperKit is ready to use
        // This ensures automatic fallback to AppleSpeechEngine when WhisperKit is still loading
        // Note: This creates seamless UX - user gets instant Apple Speech transcription
        // while WhisperKit loads in the background (eager initialization)
        return isWhisperKitReady
        #endif
    }
    
    public let requiredPermissions: [SpeechPermissionType] = [.microphone]
    
    // MARK: - Configuration
    
    public struct Configuration: Sendable {
        public let modelName: String
        public let locale: Locale
        public let enableTimestamps: Bool
        public let enableVoiceActivityDetection: Bool
        public let chunkSize: TimeInterval
        
        public init(
            modelName: String = "base",  // Base model as default
            locale: Locale = Locale(identifier: "en-US"),
            enableTimestamps: Bool = false,
            enableVoiceActivityDetection: Bool = true,
            chunkSize: TimeInterval = 2.0  // Process audio in 2-second chunks
        ) {
            self.modelName = modelName
            self.locale = locale
            self.enableTimestamps = enableTimestamps
            self.enableVoiceActivityDetection = enableVoiceActivityDetection
            self.chunkSize = chunkSize
        }
    }

    /// ISO 639-1 language code for WhisperKit, derived from the configured locale
    nonisolated private var whisperLanguageCode: String {
        configuration.locale.language.languageCode?.identifier ?? "en"
    }
    
    // MARK: - Private Properties
    
    private let configuration: Configuration
    nonisolated(unsafe) private let audioEngine = AVAudioEngine()
    
    // Dedicated queue for audio engine operations
    private let audioQueue = DispatchQueue(label: "whisper.audio", qos: .userInteractive)
    
    private weak var delegate: SpeechRecognitionEngineDelegate?
    private var isRecognitionActive = false
    
    // Optional reactive state management (simplified)
    private weak var speechEngineManager: SpeechEngineManager?
    
    // High-performance circular audio buffer - O(1) operations
    private var audioCircularBuffer: CircularBuffer<Float>
    private var totalSamplesProcessed: Int = 0
    
    // Simple voice activity detection
    private var lastVADResult: VADResult?
    private let vadCacheTimeout: TimeInterval = 0.1
    
    // WhisperKit integration
    private var whisperKit: WhisperKit?
    private var isWhisperKitReady = false
    private var isModelLoading = false
    private var modelLoadStartTime: Date?
    
    // Context management for continuous recognition
    private var confirmedTranscript: String = ""
    private var previousHypothesis: String = ""
    private var hypothesisBuffer: [String] = []
    
    // Industry-standard timer-based processing (like whisper.cpp stream)
    private var isProcessingTranscription = false
    
    // WhisperKit duration requirements (based on log analysis - needs 1.7s+ for reliable decoding)
    private let minimumAudioDuration: TimeInterval = 1.8 // Increased to ensure WhisperKit actually processes audio
    
    // VAD timing parameters (optimized for short utterances based on whisper.cpp research)
    private let energyThreshold: Float = 0.0008 // Slightly more sensitive for short audio
    private let silenceThreshold: Float = 0.0001 // Silence detection threshold (lower than speech)
    private let minSpeechDuration: TimeInterval = 0.20 // Reduced from 250ms to catch short words like "yes", "no"
    private let minSilenceDuration: TimeInterval = 0.08 // Reduced from 100ms to 80ms for quicker processing
    private let maxSpeechDuration: TimeInterval = 30.0 // VAD max speech duration (30s like whisper.cpp)
    private let speechPadMs: TimeInterval = 0.05 // Increased padding to 50ms for better context
    
    // Timer-based speech segment tracking (industry standard approach)
    private var speechStartTime: Date?
    private var lastSpeechTime: Date? 
    private var silenceStartTime: Date?
    private var isInSpeechSegment = false
    
    // Additional VAD state tracking (like whisper.cpp)
    private var currentSpeechDuration: TimeInterval = 0.0
    private var consecutiveSilenceTime: TimeInterval = 0.0
    
    // Centralized hallucination patterns
    private let hallucinationPatterns = [
        "[BLANK_AUDIO]",
        "[Music]",
        "[MUSIC PLAYING]",
        "[Silence]",
        "[INAUDIBLE]",
        "[Applause]",
        "[LAUGHTER]",
        "[COUGHING]",
        "[FOREIGN]",
        "[NOISE]",
        "[STATIC]",
        "Thank you for watching",
        "Subtitles by",
        "Subscribe to",
        "♪♪",
        "♪",
        "♫",
        "(music)",
        "(applause)",
        "(laughter)",
        "(inaudible)",
        "(silence)",
        "*music*",
        "*applause*",
        "*laughter*",
        "*inaudible*"
    ]
    
    
    // MARK: - Initialization
    
    public init(configuration: Configuration = Configuration(), speechEngineManager: SpeechEngineManager? = nil) {
        self.configuration = configuration
        self.speechEngineManager = speechEngineManager

        // Initialize circular buffer with 30-second capacity at 48kHz
        let maxSamples = Int(48000.0 * 30.0) // Support up to 48kHz sample rate
        self.audioCircularBuffer = CircularBuffer(capacity: maxSamples)

        // No rolling buffer needed - keep it simple

        WhisperEngineLogger.engine("Initialized with model '\(configuration.modelName)' and circular buffer (\(maxSamples) samples)")

        // EAGER INITIALIZATION: If model is already downloaded, start loading it immediately
        // This ensures WhisperKit is ready by the time the user presses the hotkey
        // Only check if we have a speechEngineManager (to access model status)
        if let manager = speechEngineManager {
            Task { @MainActor in
                let modelStatus = manager.modelManager.modelStatuses[configuration.modelName]

                if case .available = modelStatus {
                    WhisperEngineLogger.model("📦 Model '\(configuration.modelName)' already downloaded - starting eager initialization")
                    await initializeWhisperKit()
                } else {
                    WhisperEngineLogger.model("⏸️ Model '\(configuration.modelName)' not yet downloaded - initialization will happen on first use")
                }
            }
        } else {
            // Fallback to lazy initialization if no manager available
            WhisperEngineLogger.model("⏸️ No SpeechEngineManager - WhisperKit initialization will be lazy")
        }
    }
    
    // MARK: - SpeechRecognitionEngine Implementation
    
    public func startRecognition(delegate: SpeechRecognitionEngineDelegate) throws {
        guard !isRecognitionActive else {
            WhisperEngineLogger.warning("Recognition already active")
            return
        }
        
        self.delegate = delegate
        
        // Reset circular buffer and processing state (O(1) operation)
        let sampleRate = audioEngine.inputNode.outputFormat(forBus: 0).sampleRate
        let maxSamples = Int(sampleRate * 30.0)
        audioCircularBuffer = CircularBuffer(capacity: maxSamples)
        
        // No rolling buffer needed
        
        totalSamplesProcessed = 0
        
        // Reset context management
        confirmedTranscript = ""
        previousHypothesis = ""
        hypothesisBuffer.removeAll()
        isProcessingTranscription = false
        lastVADResult = nil
        
        // Reset VAD state tracking
        speechStartTime = nil
        lastSpeechTime = nil
        silenceStartTime = nil
        isInSpeechSegment = false
        currentSpeechDuration = 0.0
        consecutiveSilenceTime = 0.0
        
        WhisperEngineLogger.success("Reset with circular buffer capacity: \(maxSamples) samples")
        
        // Ensure WhisperKit is initialized (only once)
        if !isWhisperKitReady && !isModelLoading {
            WhisperEngineLogger.process("⚠️ WhisperKit NOT ready - starting async initialization")
            Task {
                await initializeWhisperKit()
            }
        }

        WhisperEngineLogger.process("Starting recognition (WhisperKit ready: \(isWhisperKitReady), loading: \(isModelLoading))")

        if !isWhisperKitReady {
            WhisperEngineLogger.process("⚠️ WARNING: Starting audio capture while WhisperKit is still loading! This will result in empty transcriptions.")
        }

        do {
            try startAudioEngine()
            isRecognitionActive = true
            WhisperEngineLogger.success("Recognition started successfully")
        } catch {
            throw SpeechRecognitionEngineError.initializationFailed(error.localizedDescription)
        }
    }
    
    public func stopRecognition() {
        guard isRecognitionActive else {
            WhisperEngineLogger.warning("Recognition not active")
            return
        }
        
        WhisperEngineLogger.stop("Stopping recognition")
        isRecognitionActive = false
        
        // Stop audio engine first to prevent new audio data
        audioQueue.async { [weak self] in
            guard let self = self else { return }
            if self.audioEngine.isRunning {
                self.audioEngine.stop()
                self.audioEngine.inputNode.removeTap(onBus: 0)
                WhisperEngineLogger.stop("Audio engine stopped")
            }
        }
        
        // Process final result
        Task { [weak self] in
            guard let self = self else { return }
            
            // Always process final audio, even if it's short
            let sampleCount = await MainActor.run { self.audioCircularBuffer.currentCount }
            
            if sampleCount > 0 {
                let durationInSeconds = Double(sampleCount) / 48000.0
                WhisperEngineLogger.process("Processing final audio before stopping...")
                WhisperEngineLogger.process("Final audio has \(sampleCount) samples (\(String(format: "%.2f", durationInSeconds))s duration)")
                
                // Force processing even if currently processing
                await self.processContextualTranscription(isFinal: true)
            }
            
            // Wait for any ongoing processing to complete
            var stillProcessing = await MainActor.run { self.isProcessingTranscription }
            while stillProcessing {
                try? await Task.sleep(nanoseconds: 10_000_000) // 10ms
                stillProcessing = await MainActor.run { self.isProcessingTranscription }
            }
            
            // Check if we already sent a final result during processing
            await MainActor.run {
                // Only send final result if we haven't already sent one
                if self.previousHypothesis.isEmpty && self.confirmedTranscript.isEmpty {
                    WhisperEngineLogger.transcription("No valid transcription, sending empty final result")
                    self.delegate?.speechEngine(self, didRecognizeText: "", isFinal: true, confidence: 0.85)
                } else {
                    WhisperEngineLogger.transcription("Final result already sent during processing")
                }
                
                // Clean up but keep WhisperKit instance alive for reuse
                self.delegate = nil
                WhisperEngineLogger.success("Recognition stopped (WhisperKit kept alive for reuse) - buffer samples: \(self.audioCircularBuffer.currentCount)")
            }
        }
    }
    
    // MARK: - Private Methods - Audio Capture (Direct Audio Engine)
    
    nonisolated private func startAudioEngine() throws {
        try audioQueue.sync {
            // Ensure audio engine is stopped and clean before starting
            if audioEngine.isRunning {
                audioEngine.stop()
                audioEngine.inputNode.removeTap(onBus: 0)
            }
            
            WhisperEngineLogger.audio("Configuring audio engine for microphone input...")
            let inputNode = audioEngine.inputNode
            let recordingFormat = inputNode.outputFormat(forBus: 0)
            
            WhisperEngineLogger.audio("Audio format: \(recordingFormat)")
            
            // Install tap to capture audio data for WhisperKit processing
            inputNode.installTap(onBus: 0, bufferSize: 1024, format: nil) { [weak self] buffer, when in
                guard let self = self else { return }
                
                // Convert audio buffer to float array and accumulate
                if let audioData = self.convertBufferToFloatArray(buffer) {
                    Task { @MainActor [weak self] in
                        guard let self = self else { return }
                        self.accumulateAudioData(audioData)
                        
                        // Calculate and forward audio level
                        let level = self.calculateAudioLevel(from: buffer)
                        self.delegate?.speechEngine(self, didUpdateAudioLevel: level)
                    }
                }
            }
            WhisperEngineLogger.success("Audio tap installed")
            
            audioEngine.prepare()
            try audioEngine.start()
            
            WhisperEngineLogger.success("Audio engine started - isRunning: \(audioEngine.isRunning)")
        }
    }
    
    // MARK: - Private Methods - Contextual Audio Processing
    
    private func accumulateAudioData(_ data: [Float]) {
        // Simple audio accumulation - no complex buffers
        audioCircularBuffer.append(contentsOf: data)
        totalSamplesProcessed += data.count
        
        // Debug: Log buffer state periodically
        if totalSamplesProcessed % 48000 == 0 { // Every 1 second at 48kHz
            WhisperEngineLogger.buffer("Buffer samples: \(audioCircularBuffer.currentCount), Total processed: \(totalSamplesProcessed)")
        }
        
        // Industry-standard VAD-based speech segment detection (like whisper.cpp)
        let shouldProcess = vadBasedSpeechSegmentDetection(data: data)
        
        if shouldProcess && !isProcessingTranscription {
            // Simple synchronous call to avoid race conditions
            Task { [weak self] in
                await self?.processContextualTranscription(isFinal: false)
            }
        }
    }
    
    /// Industry-standard VAD-based speech segment detection
    /// Based on whisper.cpp and professional ASR implementations
    private func vadBasedSpeechSegmentDetection(data: [Float]) -> Bool {
        let now = Date()
        let energy = calculateRMSEnergy(data)
        
        // Determine current state: speech or silence
        let isSpeech = energy > energyThreshold
        let isSilence = energy < silenceThreshold
        
        // Track speech segments like industry implementations
        if isSpeech {
            // Speech detected
            if speechStartTime == nil {
                // Start of new speech segment
                speechStartTime = now
                consecutiveSilenceTime = 0.0
                WhisperEngineLogger.audio("Speech segment started")
            }
            lastSpeechTime = now
            
            // Calculate current speech duration
            if let startTime = speechStartTime {
                currentSpeechDuration = now.timeIntervalSince(startTime)
            }
            
            // Debug logging for speech activity
            if energy > 0.0001 {
                WhisperEngineLogger.vad("Energy: \(String(format: "%.6f", energy)), Speech duration: \(String(format: "%.2f", currentSpeechDuration))s")
            }
            
            // Auto-process very long utterances for responsiveness (like industry standard)
            if currentSpeechDuration >= maxSpeechDuration {
                WhisperEngineLogger.process("Long utterance (\(String(format: "%.1f", currentSpeechDuration))s) - processing for responsiveness")
                resetSpeechSegment()
                return true
            }
            
        } else if isSilence && speechStartTime != nil {
            // Silence after speech - accumulate silence duration
            if let lastSpeech = lastSpeechTime {
                consecutiveSilenceTime = now.timeIntervalSince(lastSpeech)
                
                // Check if we have enough silence to consider speech segment ended
                if consecutiveSilenceTime >= minSilenceDuration {
                    WhisperEngineLogger.speech("Speech segment ended after \(String(format: "%.2f", currentSpeechDuration))s speech, \(String(format: "%.2f", consecutiveSilenceTime))s silence")
                    
                    // Process when we have meaningful speech
                    let shouldProcess = currentSpeechDuration >= 0.2 // Reduced to 200ms for short words
                    resetSpeechSegment()
                    return shouldProcess
                }
            }
        }
        
        // Cache VAD result for compatibility
        lastVADResult = VADResult(
            hasVoice: isSpeech,
            confidence: isSpeech ? energy : 0.0,
            timestamp: now
        )
        
        return false // Don't process during active speech
    }
    
    /// Reset speech segment tracking
    private func resetSpeechSegment() {
        speechStartTime = nil
        lastSpeechTime = nil
        currentSpeechDuration = 0.0
        consecutiveSilenceTime = 0.0
    }
    
    /// Simple RMS energy calculation
    private func calculateRMSEnergy(_ data: [Float]) -> Float {
        guard !data.isEmpty else { return 0.0 }
        
        let sumOfSquares = data.reduce(0.0) { sum, sample in
            sum + (sample * sample)
        }
        
        return sqrt(sumOfSquares / Float(data.count))
    }
    
    // All the complex processing strategy logic removed
    // Keep it simple - WhisperKit handles the heavy lifting
    
    nonisolated private func processContextualTranscription(isFinal: Bool) async {
        
        // Get audio buffer from MainActor context - simple approach
        let audioBuffer: [Float] = await MainActor.run { [weak self] in
            guard let self = self else { return [] }
            self.isProcessingTranscription = true
            return self.audioCircularBuffer.toArray()
        }
        
        defer {
            Task { @MainActor [weak self] in
                self?.isProcessingTranscription = false
            }
        }
        
        guard !audioBuffer.isEmpty else {
            WhisperEngineLogger.error("Audio buffer is empty")
            return
        }
        
        // Check audio duration and pad if needed for WhisperKit
        let audioDurationSeconds = Double(audioBuffer.count) / 48000.0
        var processableAudio = audioBuffer
        
        // Let WhisperKit handle any audio duration - remove artificial minimums
        // Only skip extremely short audio (< 0.1s) which is likely noise
        if !isFinal && audioDurationSeconds < 0.1 {
            WhisperEngineLogger.warning("Skipping very short audio (\(String(format: "%.2f", audioDurationSeconds))s - likely noise)")
            return
        }
        
        // For short final audio, add strategic padding for better WhisperKit processing
        if isFinal && audioDurationSeconds < 1.2 {
            let paddingSamples = Int(0.3 * 48000.0) // Add 300ms of padding for better context
            let padding = Array(repeating: Float(0.0), count: paddingSamples)
            processableAudio = audioBuffer + padding
            WhisperEngineLogger.process("Added 300ms padding to short audio: \(audioBuffer.count) audio + \(paddingSamples) padding = \(processableAudio.count) samples")
        }
        
        // Check if model is still loading
        let modelState = await MainActor.run { (self.whisperKit, self.isWhisperKitReady, self.isModelLoading, self.modelLoadStartTime) }
        
        if modelState.2 { // isModelLoading
            let loadingTime = modelState.3.map { Date().timeIntervalSince($0) } ?? 0
            WhisperEngineLogger.model("Model still loading (\(String(format: "%.1f", loadingTime))s), skipping transcription...")
            
            // If we're in final processing and model is taking too long, try to wait a bit
            if isFinal && loadingTime < 45.0 { // Wait up to 45 seconds for final result
                try? await Task.sleep(nanoseconds: 500_000_000) // Wait 500ms
                // Retry once more
                let retryState = await MainActor.run { (self.whisperKit, self.isWhisperKitReady, self.isModelLoading) }
                if retryState.2 {
                    WhisperEngineLogger.model("Model still not ready after retry, giving up")
                    return
                }
            } else {
                return
            }
        }
        
        guard let whisperKit = modelState.0, modelState.1 else {
            WhisperEngineLogger.error("WhisperKit not available")
            return
        }
        
        do {
            let processingStartTime = Date()
            let finalDuration = Double(processableAudio.count) / 48000.0
            WhisperEngineLogger.process("Processing \(processableAudio.count) samples (\(String(format: "%.2f", finalDuration))s duration)")
            
            // Write audio to temporary file - WhisperKit works best with files
            let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent("whisper_\(UUID().uuidString).wav")
            let fileWriteStart = Date()
            await self.writeContextualAudioToFile(processableAudio, to: tempURL)
            let fileWriteTime = Date().timeIntervalSince(fileWriteStart)
            WhisperEngineLogger.timing("File write took \(String(format: "%.1f", fileWriteTime * 1000))ms")
            
            // Optimized WhisperKit options for short audio transcription
            // Based on WhisperKit source: maxTokenContext = 448, sampleLength controls token context not audio samples
            let options = DecodingOptions(
                verbose: false,
                task: .transcribe,
                language: self.whisperLanguageCode,
                temperature: 0.0,
                temperatureIncrementOnFallback: 0.2, // Use WhisperKit default for stability
                temperatureFallbackCount: 8, // Increased attempts for difficult short audio
                // sampleLength controls token context (max 448), use default for best compatibility
                topK: 5,
                usePrefillPrompt: true, // Enable for better short audio context (WhisperKit default)
                usePrefillCache: true, // Enable for performance (WhisperKit default)
                skipSpecialTokens: false, // Allow special tokens for better transcription
                withoutTimestamps: true,
                wordTimestamps: false,
                clipTimestamps: []
            )
            let transcriptionStart = Date()
            let results = try await whisperKit.transcribe(audioPath: tempURL.path, decodeOptions: options)
            let transcriptionTime = Date().timeIntervalSince(transcriptionStart)
            WhisperEngineLogger.timing("WhisperKit transcription took \(String(format: "%.1f", transcriptionTime * 1000))ms")
            
            // Clean up temporary file
            try? FileManager.default.removeItem(at: tempURL)
            
            // Get the transcription text from first result
            let rawText = results.first?.text ?? ""
            WhisperEngineLogger.transcription("Raw WhisperKit result: '\(rawText)' (from \(results.count) results)")
            
            // Get patterns from MainActor context
            let patterns = await MainActor.run { self.hallucinationPatterns }
            
            // Filter out hallucinations using centralized method
            let text = self.filterHallucinations(rawText, patterns: patterns)
            if !text.isEmpty {
                WhisperEngineLogger.transcription("Transcription result: '\(text)'")
            }
            
            let totalProcessingTime = Date().timeIntervalSince(processingStartTime)
            WhisperEngineLogger.timing("Total processing took \(String(format: "%.1f", totalProcessingTime * 1000))ms")
            
            await MainActor.run {
                if isFinal {
                    // For final results, send immediately and update state
                    WhisperEngineLogger.transcription("Sending final result: '\(text)'")
                    let delegateStart = Date()
                    
                    // Estimate tokens for WhisperKit processing units
                    let processingUnits = self.estimateTokensFromText(text)
                    
                    self.delegate?.speechEngine(self, didRecognizeText: text, processingUnits: processingUnits, isFinal: true, confidence: 0.85)
                    let delegateTime = Date().timeIntervalSince(delegateStart)
                    WhisperEngineLogger.timing("Delegate callback took \(String(format: "%.1f", delegateTime * 1000))ms")
                    self.previousHypothesis = text
                    self.confirmedTranscript = text
                } else {
                    // For non-final, send immediately for responsiveness
                    if !text.isEmpty {
                        WhisperEngineLogger.transcription("Sending partial result: '\(text)'")
                        
                        // Estimate tokens for partial results too
                        let processingUnits = self.estimateTokensFromText(text)
                        
                        self.delegate?.speechEngine(self, didRecognizeText: text, processingUnits: processingUnits, isFinal: false, confidence: 0.80)
                    }
                    self.processWithLocalAgreement(text, isFinal: false)
                }
            }
            
        } catch {
            WhisperEngineLogger.error("Transcription failed: \(error)")
            await MainActor.run {
                self.delegate?.speechEngine(self, didFailWithError: SpeechRecognitionEngineError.recognitionFailed(error.localizedDescription))
            }
        }
    }
    
    private func processWithLocalAgreement(_ transcript: String, isFinal: Bool) {
        // Filter hallucinations and check if we have valid text
        let cleanTranscript = filterHallucinations(transcript, patterns: hallucinationPatterns)
        guard !cleanTranscript.isEmpty else {
            return
        }
        
        // Add to hypothesis buffer for agreement checking
        hypothesisBuffer.append(cleanTranscript)
        
        // Keep only last 2 hypotheses
        if hypothesisBuffer.count > 2 {
            hypothesisBuffer.removeFirst()
        }
        
        // Send current hypothesis for responsiveness
        delegate?.speechEngine(self, didRecognizeText: cleanTranscript, isFinal: false, confidence: 0.75)
        WhisperEngineLogger.transcription("Hypothesis: '\(cleanTranscript)'")
        
        // Simplified agreement checking - only check if we have stable text
        if hypothesisBuffer.count >= 2 {
            // If the last two hypotheses are very similar, we have stable text
            let prev = hypothesisBuffer[hypothesisBuffer.count - 2]
            let curr = hypothesisBuffer[hypothesisBuffer.count - 1]
            
            // Check if current builds on previous (incremental speech)
            if curr.hasPrefix(prev) && prev.count > confirmedTranscript.count {
                let newConfirmed = String(prev.dropFirst(confirmedTranscript.count))
                if !newConfirmed.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    confirmedTranscript = prev
                    WhisperEngineLogger.transcription("Confirmed incremental text: '\(newConfirmed)'")
                }
            }
        }
        
        previousHypothesis = cleanTranscript
    }
    
    private func longestCommonPrefix(_ str1: String, _ str2: String) -> String {
        let chars1 = Array(str1)
        let chars2 = Array(str2)
        let minLength = min(chars1.count, chars2.count)
        
        var commonLength = 0
        for i in 0..<minLength {
            if chars1[i] == chars2[i] {
                commonLength = i + 1
            } else {
                break
            }
        }
        
        return String(chars1.prefix(commonLength))
    }
    
    /// Centralized method to check if text is a hallucination
    /// Made nonisolated so it can be called from any context
    nonisolated private func isHallucination(_ text: String, patterns: [String]) -> Bool {
        // Check if text is empty or whitespace only
        let trimmedText = text.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmedText.isEmpty {
            return true
        }
        
        // Check against known hallucination patterns
        for pattern in patterns {
            if text.localizedCaseInsensitiveContains(pattern) {
                return true
            }
        }
        
        // Check if text is enclosed in brackets/parentheses (likely metadata)
        if (trimmedText.hasPrefix("[") && trimmedText.hasSuffix("]")) ||
           (trimmedText.hasPrefix("(") && trimmedText.hasSuffix(")")) ||
           (trimmedText.hasPrefix("*") && trimmedText.hasSuffix("*")) {
            return true
        }
        
        // Check if it's just punctuation or very short non-meaningful text
        if trimmedText.count <= 2 && !trimmedText.contains(where: { $0.isLetter || $0.isNumber }) {
            return true
        }
        
        // Check if text contains mostly non-alphabetic characters (likely not speech)
        let letterCount = trimmedText.filter { $0.isLetter }.count
        let totalCount = trimmedText.count
        if totalCount > 3 && Double(letterCount) / Double(totalCount) < 0.5 {
            return true
        }
        
        // Check for repeated characters (often Whisper artifacts)
        if trimmedText.count >= 3 {
            let firstChar = trimmedText.first!
            if trimmedText.allSatisfy({ $0 == firstChar || $0.isWhitespace }) {
                return true
            }
        }
        
        return false
    }
    
    /// Filter hallucinations from text and return cleaned result
    /// Made nonisolated so it can be called from any context
    nonisolated private func filterHallucinations(_ text: String, patterns: [String]) -> String {
        if isHallucination(text, patterns: patterns) {
            if !text.isEmpty && !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                WhisperEngineLogger.warning("Filtered hallucination: '\(text)'")
            }
            return ""
        }
        WhisperEngineLogger.transcription("Valid transcription passed filter: '\(text)'")
        return text
    }
    
    
    // MARK: - WhisperKit Implementation

    /// Get the model folder path for WhisperKit - uses Application Support for sandboxed apps
    private func getModelFolder() -> URL? {
        // Ensure directory exists
        ModelPaths.ensureModelsDirectoryExists()

        guard let modelsURL = ModelPaths.modelsDirectory else {
            WhisperEngineLogger.error("Could not access Application Support directory")
            return nil
        }

        WhisperEngineLogger.model("Using model folder: \(modelsURL.path)")
        return modelsURL
    }

    /// Initialize WhisperKit once using official pattern - reused across sessions
    private func initializeWhisperKit() async {
        // Check if already loading to avoid duplicate initialization
        let alreadyLoading = await MainActor.run {
            if self.isModelLoading {
                return true
            }
            self.isModelLoading = true
            self.modelLoadStartTime = Date()
            return false
        }
        
        if alreadyLoading {
            WhisperEngineLogger.model("Model already loading, skipping duplicate initialization")
            return
        }
        
        do {
            // Check model status before initializing
            if let manager = speechEngineManager {
                let modelStatus = await MainActor.run { manager.modelManager.modelStatuses[configuration.modelName] }

                switch modelStatus {
                case .available:
                    WhisperEngineLogger.model("✅ Model '\(configuration.modelName)' already downloaded, loading...")
                case .downloading(let progress):
                    WhisperEngineLogger.model("⏳ Model '\(configuration.modelName)' currently downloading (\(Int(progress * 100))%), will load when complete")
                case .notDownloaded:
                    WhisperEngineLogger.model("📥 Model '\(configuration.modelName)' not downloaded, WhisperKit will download it now (may take 10-30 seconds)")
                case .failed(let error):
                    WhisperEngineLogger.model("❌ Model '\(configuration.modelName)' download failed: \(error)")
                case .none:
                    WhisperEngineLogger.model("⚠️ Model status unknown for '\(configuration.modelName)'")
                }
            }

            WhisperEngineLogger.model("Initializing WhisperKit with model '\(configuration.modelName)'...")

            // Notify UI that model is loading
            await MainActor.run {
                self.delegate?.speechEngine(self, didUpdateModelLoadingState: true, progress: 0.0)
            }

            // Test: Use WhisperKit defaults to see if download works at all in sandbox
            WhisperEngineLogger.model("Initializing WhisperKit with model: \(configuration.modelName) using defaults")
            
            let config = WhisperKitConfig(model: configuration.modelName)
            
            // NOTE: This call will DOWNLOAD the model if it doesn't exist (10-30 seconds)
            let whisperKit = try await WhisperKit(config)
            
            // Warm up the model with a tiny silent audio to eliminate first-use penalty
            let warmupStart = Date()
            await self.warmupWhisperKit(whisperKit)
            let warmupTime = Date().timeIntervalSince(warmupStart)
            WhisperEngineLogger.model("Model warmed up in \(String(format: "%.1f", warmupTime * 1000))ms")
            
            await MainActor.run {
                self.whisperKit = whisperKit
                self.isWhisperKitReady = true
                self.isModelLoading = false
                
                // Notify UI that model loading is complete
                self.delegate?.speechEngine(self, didUpdateModelLoadingState: false, progress: 1.0)
                
                if let startTime = self.modelLoadStartTime {
                    let loadTime = Date().timeIntervalSince(startTime)
                    WhisperEngineLogger.success("WhisperKit initialized with model '\(self.configuration.modelName)' in \(String(format: "%.1f", loadTime))s")
                } else {
                    WhisperEngineLogger.success("WhisperKit initialized with model '\(self.configuration.modelName)'")
                }
                
                self.modelLoadStartTime = nil
            }
        } catch {
            await MainActor.run {
                self.isWhisperKitReady = false
                self.isModelLoading = false
                self.modelLoadStartTime = nil
                
                // Notify UI that model loading failed
                self.delegate?.speechEngine(self, didUpdateModelLoadingState: false, progress: 0.0)
                
                WhisperEngineLogger.error("WhisperKit initialization failed: \(error)")
            }
        }
    }
    
    /// Warm up WhisperKit with minimal audio to eliminate first-use penalty
    nonisolated private func warmupWhisperKit(_ whisperKit: WhisperKit) async {
        do {
            // Create minimal silent audio for warmup (0.5 seconds at 16kHz)
            let sampleRate: Double = 16000
            let duration: Double = 0.5
            let sampleCount = Int(sampleRate * duration)
            let silentAudio = Array(repeating: Float(0.0), count: sampleCount)
            
            // Write to temporary file
            let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent("warmup_\(UUID().uuidString).wav")
            await writeWarmupAudioToFile(silentAudio, to: tempURL, sampleRate: sampleRate)
            
            // Minimal transcription options for fastest warmup
            let warmupOptions = DecodingOptions(
                verbose: false,
                task: .transcribe,
                language: "en",
                temperature: 0.0
            )
            
            // Perform warmup transcription (result doesn't matter)
            let _ = try await whisperKit.transcribe(audioPath: tempURL.path, decodeOptions: warmupOptions)
            
            // Clean up
            try? FileManager.default.removeItem(at: tempURL)
            
        } catch {
            WhisperEngineLogger.warning("Warmup failed (not critical): \(error)")
        }
    }
    
    /// Write warmup audio file with specific sample rate
    nonisolated private func writeWarmupAudioToFile(_ audioData: [Float], to url: URL, sampleRate: Double) async {
        let format = AVAudioFormat(commonFormat: .pcmFormatFloat32, sampleRate: sampleRate, channels: 1, interleaved: false)!
        
        do {
            let audioFile = try AVAudioFile(forWriting: url, settings: format.settings)
            
            let frameCount = AVAudioFrameCount(audioData.count)
            guard let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: frameCount) else {
                return
            }
            
            buffer.frameLength = frameCount
            
            if let channelData = buffer.floatChannelData?[0] {
                for i in 0..<audioData.count {
                    channelData[i] = audioData[i]
                }
            }
            
            try audioFile.write(from: buffer)
        } catch {
            WhisperEngineLogger.warning("Warmup file write failed: \(error)")
        }
    }
    
    
    // MARK: - Audio File Writing (restored for working transcription)
    
    nonisolated private func writeContextualAudioToFile(_ audioData: [Float], to url: URL) async {
        // Use the actual audio engine's input format
        let inputFormat = await MainActor.run { audioEngine.inputNode.outputFormat(forBus: 0) }
        let sampleRate = inputFormat.sampleRate
        let channels: UInt32 = 1
        let format = AVAudioFormat(commonFormat: .pcmFormatFloat32, sampleRate: sampleRate, channels: channels, interleaved: false)!
        
        do {
            let audioFile = try AVAudioFile(forWriting: url, settings: format.settings)
            
            let frameCount = AVAudioFrameCount(audioData.count)
            guard let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: frameCount) else {
                WhisperEngineLogger.error("Failed to create contextual audio buffer")
                return
            }
            
            buffer.frameLength = frameCount
            
            // Copy audio data to buffer
            if let channelData = buffer.floatChannelData?[0] {
                for i in 0..<audioData.count {
                    channelData[i] = audioData[i]
                }
            }
            
            try audioFile.write(from: buffer)
            
        } catch {
            WhisperEngineLogger.error("Failed to write contextual audio file: \(error)")
        }
    }
    
    // MARK: - Audio Utilities
    
    nonisolated private func convertBufferToFloatArray(_ buffer: AVAudioPCMBuffer) -> [Float]? {
        guard let channelData = buffer.floatChannelData?[0] else { return nil }
        
        let frameLength = Int(buffer.frameLength)
        return Array(UnsafeBufferPointer(start: channelData, count: frameLength))
    }
    
    // Simple audio level calculation for WhisperKit feedback
    nonisolated private func calculateAudioLevel(from buffer: AVAudioPCMBuffer) -> Double {
        guard let channelData = buffer.floatChannelData?[0] else { return -160.0 }
        
        let frameLength = Int(buffer.frameLength)
        guard frameLength > 0 else { return -160.0 }
        
        var sum: Float = 0.0
        for i in 0..<frameLength {
            let sample = channelData[i]
            sum += sample * sample
        }
        
        let rms = sqrt(sum / Float(frameLength))
        guard rms > 0 else { return -160.0 }
        
        let avgPower = 20 * log10(rms)
        return Double(max(-160.0, min(0.0, avgPower)))
    }
    
    /// Estimate tokens from text for WhisperKit and return as ProcessingUnit
    /// BPE tokenization typically results in ~1.33 tokens per word
    private func estimateTokensFromText(_ text: String) -> ProcessingUnit {
        let words = countWordsInText(text)
        // Conservative estimate: 1.33 tokens per word for English text
        let estimatedTokens = Int(Double(words) * 1.33)
        return .tokens(max(1, estimatedTokens)) // Ensure at least 1 token for non-empty text
    }
    
    /// Count words in text using word boundaries
    /// More accurate than simple whitespace splitting
    private func countWordsInText(_ text: String) -> Int {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return 0 }
        
        // Use NSString's word enumeration for accurate word counting
        var wordCount = 0
        trimmed.enumerateSubstrings(in: trimmed.startIndex..<trimmed.endIndex, 
                                   options: [.byWords, .localized]) { _, _, _, _ in
            wordCount += 1
        }
        
        return wordCount
    }
    
}


// MARK: - Public Factory

extension WhisperEngine {
    
    /// Create a WhisperEngine optimized for speed with the smallest model
    public static func fast(speechEngineManager: SpeechEngineManager? = nil) -> WhisperEngine {
        return WhisperEngine(configuration: Configuration(modelName: "base"), speechEngineManager: speechEngineManager)
    }
    
    /// Create a WhisperEngine optimized for accuracy with a larger model
    public static func accurate(speechEngineManager: SpeechEngineManager? = nil) -> WhisperEngine {
        return WhisperEngine(configuration: Configuration(modelName: "base"), speechEngineManager: speechEngineManager)
    }
    
    /// Create a WhisperEngine for a specific locale
    public static func forLocale(_ locale: Locale, modelName: String = "base", speechEngineManager: SpeechEngineManager? = nil) -> WhisperEngine {
        return WhisperEngine(configuration: Configuration(modelName: modelName, locale: locale), speechEngineManager: speechEngineManager)
    }
    
    /// Create a WhisperEngine with timestamps enabled
    public static func withTimestamps(speechEngineManager: SpeechEngineManager? = nil) -> WhisperEngine {
        return WhisperEngine(configuration: Configuration(enableTimestamps: true), speechEngineManager: speechEngineManager)
    }
}

// MARK: - WhisperKit Model Information

/*
 Available WhisperKit models (in order of speed vs accuracy):
 
 - "tiny": Fastest, least accurate (~39 MB)
 - "base": Good balance of speed and accuracy (~74 MB) [DEFAULT]
 - "small": Better accuracy, slower (~244 MB)
 - "medium": High accuracy, slower (~769 MB)
 - "large": Highest accuracy, slowest (~1550 MB)
 
 Models are downloaded automatically on first use.
 Choose based on your speed vs accuracy requirements.
 */
