import Foundation
import Combine
import AppServices
import SpeechKit

// MARK: - Speech Service Protocols

/// Protocol for text insertion delegate
@MainActor
protocol TextInsertionDelegate: AnyObject {
    func insertTranscribedText(_ text: String)
}

// MARK: - Speech Service Implementation

/// Service that coordinates speech recognition with state management
/// Follows Single Responsibility Principle - only handles speech coordination
@MainActor
final class SpeechService: ObservableObject, SpeechServiceProtocol {
    
    // MARK: - Dependencies
    
    private let transcriptionStore: TranscriptionStore
    private let speechRecognizer: SpeechRecognizer
    private let textInserter: any TextInsertionServiceProtocol

    // Delegate for text insertion
    private weak var textInsertionDelegate: TextInsertionDelegate?
    
    // Reference to speech engine manager for reactive state updates
    private weak var speechEngineManager: SpeechEngineManager?
    
    // MARK: - State
    
    @Published private(set) var isListening = false
    
    // MARK: - Private Properties
    
    private var recordingStartTime: Date?
    private var currentRecordingTask: Task<Void, Never>?
    private var recordingSessionID = UUID()
    private var lastPartialResult: String?
    
    // MARK: - Initialization
    
    init(transcriptionStore: TranscriptionStore,
         speechRecognizer: SpeechRecognizer,
         textInserter: any TextInsertionServiceProtocol,
         speechEngineManager: SpeechEngineManager? = nil,
         textInsertionDelegate: TextInsertionDelegate? = nil) {
        self.transcriptionStore = transcriptionStore
        self.speechRecognizer = speechRecognizer
        self.textInserter = textInserter
        self.speechEngineManager = speechEngineManager
        self.textInsertionDelegate = textInsertionDelegate
        Logger.speech("SpeechService: Initialization - isListening=\(self.isListening)")
        setupSpeechRecognizer()
    }
    
    // MARK: - Public Interface
    
    func setTextInsertionDelegate(_ delegate: TextInsertionDelegate?) {
        self.textInsertionDelegate = delegate
        Logger.speech("SpeechService: TextInsertionDelegate set")
    }
    
    func startListening() {
        Logger.speech("SpeechService.startListening() called - current isListening: \(isListening)")
        
        // Prevent multiple concurrent sessions
        guard !isListening else {
            Logger.warning("SpeechService: Already listening, ignoring duplicate startListening call")
            return
        }

        // Cancel any existing recording task
        currentRecordingTask?.cancel()
        
        // Clear any existing stream state
        streamContinuation?.finish()
        streamContinuation = nil
        currentSessionID = nil
        
        // Create new session ID for this recording
        recordingSessionID = UUID()
        let sessionID = recordingSessionID
        
        Logger.speech("SpeechService: Starting speech recognition (session: \(sessionID))")
        recordingStartTime = Date()
        lastPartialResult = nil // Clear any previous partial result
        isListening = true
        
        // Update store state
        transcriptionStore.setListening(true)
        
        // Start recording task
        currentRecordingTask = Task { @MainActor in
            await handleRecordingSession(sessionID: sessionID)
        }
        
        // Start speech recognizer
        speechRecognizer.startRecording()
        
        Logger.success("SpeechService: Speech recognition started")
    }
    
    func stopListening() {
        guard isListening else {
            Logger.warning("SpeechService: Not listening, ignoring stop request")
            return
        }
        
        Logger.speech("SpeechService: Stopping speech recognition - waiting for final result")
        
        // Update state immediately to prevent multiple calls
        isListening = false
        transcriptionStore.setListening(false)
        
        // Signal the speech recognizer to stop recording and finalize
        speechRecognizer.stopRecording()
        
        // The rest will be handled in the speechRecognizer delegate when we receive isFinal: true
        Logger.process("SpeechService: Waiting for final recognition result...")
    }
    
    // MARK: - Private Methods
    
    private func setupSpeechRecognizer() {
        speechRecognizer.delegate = self
        Logger.config("SpeechService: Speech recognizer delegate setup complete")
    }
    
    private func calculateDuration() -> TimeInterval? {
        guard let startTime = recordingStartTime else { return nil }
        return Date().timeIntervalSince(startTime)
    }
    
    @MainActor
    private func handleRecordingSession(sessionID: UUID) async {
        Logger.speech("SpeechService: Recording session \(sessionID) started")
        
        // Usage monitoring is now handled by DailyUsageTracker
        // No complex session-based monitoring needed
        
        // Track partial results for UI updates
        var partialResults: [String] = []
        
        // Use AsyncStream to collect speech results
        let continuation = AsyncStream<(String, Bool)> { continuation in
            // Store continuation for speech recognition callbacks
            self.setupStreamContinuation(continuation, sessionID: sessionID)
        }
        
        // Process speech results as they come in (partial results only for UI updates)
        for await (text, isFinal) in continuation {
            guard recordingSessionID == sessionID else {
                Logger.warning("Session \(sessionID) superseded, stopping processing")
                break
            }
            
            if isFinal {
                Logger.success("Session \(sessionID) received final result: '\(text)' - handled in delegate")
                break
            } else {
                partialResults.append(text)
                // Update live transcription for partial results (confidence will be updated in delegate)
                transcriptionStore.updateLiveTranscription(currentText: text)
                Logger.speech("Session \(sessionID) partial: '\(text)'")
            }
        }
        
        // Final result handling is now done in the speechRecognizer delegate
        // This async stream just handles partial results for UI updates
        
        // Session complete - simplified tracking
        if let duration = calculateDuration() {
            Logger.timing("SpeechService: Session duration: \(String(format: "%.1f", duration / 60.0)) minutes")
        }
        
        // Clean up session
        if recordingSessionID == sessionID {
            recordingStartTime = nil
            currentRecordingTask = nil
        }
        
        Logger.process("SpeechService: Recording session \(sessionID) completed")
    }
    
    private var streamContinuation: AsyncStream<(String, Bool)>.Continuation?
    private var currentSessionID: UUID?
    
    private func setupStreamContinuation(_ continuation: AsyncStream<(String, Bool)>.Continuation, sessionID: UUID) {
        streamContinuation = continuation
        currentSessionID = sessionID
        
        // The async stream will automatically finish when the task is cancelled
        continuation.onTermination = { _ in
            Task { @MainActor in
                if self.currentSessionID == sessionID {
                    self.streamContinuation = nil
                    self.currentSessionID = nil
                }
            }
        }
    }
    
}

// MARK: - SpeechRecognizerDelegate

extension SpeechService: SpeechRecognizerDelegate {
    
    func speechRecognizer(_ recognizer: SpeechRecognizer, didRecognizeText text: String, isFinal: Bool, confidence: Double) {
            Logger.speech("SpeechService: Received text: '\(text)' (isFinal: \(isFinal), confidence: \(String(format: "%.2f", confidence)))")
            
            // This is the fallback method - processing units will be handled by the primary method
            // Call internal handler with estimated processing units based on word count
            let words = countWords(text)
            let processingUnits = ProcessingUnit.words(words)
            handleRecognizedText(text: text, processingUnits: processingUnits, isFinal: isFinal, confidence: confidence)
    }
    
    func speechRecognizer(_ recognizer: SpeechRecognizer, didRecognizeText text: String, processingUnits: ProcessingUnit, isFinal: Bool, confidence: Double) {
        Logger.speech("SpeechService: Received text: '\(text)' (\(processingUnits.count) \(processingUnits.unitType), isFinal: \(isFinal), confidence: \(String(format: "%.2f", confidence)))")
        
        // This is the primary method that handles processing unit reporting
        handleRecognizedText(text: text, processingUnits: processingUnits, isFinal: isFinal, confidence: confidence)
    }
    
    /// Internal handler for recognized text
    private func handleRecognizedText(text: String, processingUnits: ProcessingUnit, isFinal: Bool, confidence: Double) {
            // Log ALL speech recognition results (partial and final) to SpeechLogger for debugging
            SpeechLogger.shared.logSpeechRecognition(text: text, isFinal: isFinal, confidence: confidence)
            
            // Always store the latest result
            lastPartialResult = text
            Logger.speech("Stored result: '\(text)' (isFinal: \(isFinal))")
            
            // Update live transcription with confidence for partial results
            if !isFinal {
                transcriptionStore.updateLiveTranscription(currentText: text, confidence: confidence)
            }
            
            // Send to active stream if still active
            if let continuation = streamContinuation, let sessionID = currentSessionID {
                Logger.speech("Sending to session \(sessionID): '\(text)' (final: \(isFinal))")
                continuation.yield((text, isFinal))
                
                if isFinal {
                    continuation.finish()
                    streamContinuation = nil
                    currentSessionID = nil
                }
            }
            
            // Handle final result - this is when we actually insert the text
            if isFinal {
                Logger.speech("Final result received - inserting text and cleaning up")
                
                // Insert the final text
                if !text.isEmpty {
                    Logger.speech("Inserting final text: '\(text)'")
                    let insertionStart = Date()
                    
                    // Use delegate if available, otherwise fallback to direct insertion
                    if let delegate = textInsertionDelegate {
                        Logger.speech("Using TextInsertionDelegate for insertion")
                        delegate.insertTranscribedText(text)
                    } else {
                        Logger.speech("No delegate available, using direct text insertion")
                        textInserter.insertText(text, isFinal: true)
                    }
                    
                    let insertionTime = Date().timeIntervalSince(insertionStart)
                    Logger.timing("SpeechService: Text insertion call took \(String(format: "%.1f", insertionTime * 1000))ms")
                    
                    // Add to transcription history
                    let duration = calculateDuration()
                    
                    transcriptionStore.addTranscription(
                        text: text,
                        confidence: confidence,
                        duration: duration
                    )
                }
                
                // Clean up session
                currentRecordingTask?.cancel()
                currentRecordingTask = nil
                recordingStartTime = nil
                lastPartialResult = nil
                
                Logger.success("Speech session completed and finalized")
            }
    }
    
    func speechRecognizer(_ recognizer: SpeechRecognizer, didFailWithError error: Error) {
        Logger.error("SpeechService: Speech recognition error: \(error)")
        
        
        // Finish the stream on error
        streamContinuation?.finish()
        streamContinuation = nil
        currentSessionID = nil
        
        stopListening()
    }
    
    func speechRecognizer(_ recognizer: SpeechRecognizer, didUpdateAudioLevel level: Double) {
        // Forward audio level updates to the transcription store for visualization
        updateAudioLevel(level)
    }
    
    /// Count words in text using word boundaries
    /// More accurate than simple whitespace splitting
    private func countWords(_ text: String) -> Int {
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

// MARK: - Audio Level Updates (Future Enhancement)

extension SpeechService {
    
    /// Update audio level for visualization
    /// This would typically come from the audio engine
    func updateAudioLevel(_ level: Double) {
        transcriptionStore.updateAudioLevel(level)
    }
}