import Foundation
import Combine
import SwiftUI

// MARK: - Models

struct TranscriptionEntry: Identifiable, Codable, Sendable {
    let id: UUID
    let text: String
    let timestamp: Date
    let duration: TimeInterval?
    let confidence: Double

    init(text: String, timestamp: Date, duration: TimeInterval?, confidence: Double) {
        self.id = UUID()
        self.text = text
        self.timestamp = timestamp
        self.duration = duration
        self.confidence = confidence
    }

    nonisolated var formattedTime: String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: timestamp)
    }
}

struct LiveTranscription: Sendable {
    let currentText: String
    let partialText: String
    let confidence: Double
    let audioLevel: Double
    
    static let empty = LiveTranscription(
        currentText: "",
        partialText: "",
        confidence: 0.0,
        audioLevel: 0.0
    )
}

// MARK: - State Management

/// Central store for all transcription-related state
/// Follows Single Responsibility Principle - only manages transcription data
@MainActor
final class TranscriptionStore: ObservableObject {
    
    // MARK: - Published State
    
    @Published private(set) var transcriptionHistory: [TranscriptionEntry] = []
    @Published private(set) var liveTranscription = LiveTranscription.empty
    @Published private(set) var isListening = false
    
    // MARK: - Private State
    
    private var cancellables = Set<AnyCancellable>()
    private let persistenceService: TranscriptionPersistenceService
    
    // MARK: - Initialization
    
    init(persistenceService: TranscriptionPersistenceService = FileBasedPersistenceService()) {
        self.persistenceService = persistenceService
        loadPersistedHistory()
        setupAutomaticSaving()
    }
    
    // MARK: - Public Interface
    
    /// Add a completed transcription to history
    func addTranscription(text: String, confidence: Double, duration: TimeInterval? = nil) {
        guard !text.isEmpty else { return }
        
        let entry = TranscriptionEntry(
            text: text,
            timestamp: Date(),
            duration: duration,
            confidence: confidence
        )
        
        transcriptionHistory.insert(entry, at: 0) // Newest first
        print("📝 TranscriptionStore: Added transcription to history. Total: \(transcriptionHistory.count)")
        
        // Clear live transcription after adding to history
        clearLiveTranscription()
    }
    
    /// Update live transcription during recording
    func updateLiveTranscription(currentText: String, partialText: String = "", confidence: Double = 0.0) {
        liveTranscription = LiveTranscription(
            currentText: currentText,
            partialText: partialText,
            confidence: confidence,
            audioLevel: liveTranscription.audioLevel // Preserve audio level
        )
    }
    
    /// Update audio level for visualization
    func updateAudioLevel(_ level: Double) {
        liveTranscription = LiveTranscription(
            currentText: liveTranscription.currentText,
            partialText: liveTranscription.partialText,
            confidence: liveTranscription.confidence,
            audioLevel: level
        )
    }
    
    /// Set listening state
    func setListening(_ listening: Bool) {
        isListening = listening
        
        if !listening {
            // Clear live transcription when stopping
            clearLiveTranscription()
        }
    }
    
    /// Clear all transcription history
    func clearHistory() {
        transcriptionHistory.removeAll()
        print("🧹 TranscriptionStore: Cleared all history")
    }
    
    
    /// Clear current live transcription
    func clearLiveTranscription() {
        liveTranscription = LiveTranscription.empty
    }
    
    // MARK: - Persistence
    
    private func loadPersistedHistory() {
        transcriptionHistory = persistenceService.loadTranscriptions()
        print("📚 TranscriptionStore: Loaded \(transcriptionHistory.count) persisted entries")
    }
    
    private func setupAutomaticSaving() {
        // Save history whenever it changes
        $transcriptionHistory
            .debounce(for: .seconds(1), scheduler: RunLoop.main)
            .sink { [weak self] history in
                self?.persistenceService.saveTranscriptions(history)
            }
            .store(in: &cancellables)
    }
}

// MARK: - Persistence Service Protocol

/// Protocol for transcription persistence - follows Interface Segregation Principle
protocol TranscriptionPersistenceService: Sendable {
    func saveTranscriptions(_ transcriptions: [TranscriptionEntry])
    func loadTranscriptions() -> [TranscriptionEntry]
}

// MARK: - File-Based Persistence Implementation

/// File-based implementation of persistence service
/// Follows Single Responsibility Principle - only handles file operations
final class FileBasedPersistenceService: TranscriptionPersistenceService, Sendable {

    private let fileName = "transcription_history.json"

    private var fileURL: URL {
        // Use App's Application Support directory to avoid Documents folder permissions
        let appSupportPath = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        let appDirectory = appSupportPath.appendingPathComponent("com.thetypealternative.app")

        // Create directory if it doesn't exist
        try? FileManager.default.createDirectory(at: appDirectory, withIntermediateDirectories: true)

        return appDirectory.appendingPathComponent(fileName)
    }

    func saveTranscriptions(_ transcriptions: [TranscriptionEntry]) {
        do {
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            let data = try encoder.encode(transcriptions)
            try data.write(to: fileURL)
            print("💾 Saved \(transcriptions.count) transcriptions to app storage")
        } catch {
            print("❌ Failed to save transcriptions: \(error)")
        }
    }

    func loadTranscriptions() -> [TranscriptionEntry] {
        do {
            let data = try Data(contentsOf: fileURL)
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            let transcriptions = try decoder.decode([TranscriptionEntry].self, from: data)
            // Log removed - TranscriptionStore logs this at a higher level
            return transcriptions
        } catch {
            print("ℹ️ No existing transcriptions found or failed to load: \(error)")
            return []
        }
    }
}

// MARK: - Store Access

/// Global access point for the transcription store
/// In a larger app, this would be injected via dependency injection
// Note: Environment access is handled via @EnvironmentObject in the UI layer
// This eliminates the need for a custom EnvironmentKey with MainActor isolation issues