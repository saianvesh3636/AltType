import Foundation
import Combine

// MARK: - Speech Service Protocol

/// Protocol for speech recognition service
/// This protocol defines the minimal interface for coordinating speech recognition
/// Engine-specific concerns (model selection, etc.) are handled by SpeechEngineManager
@MainActor
public protocol SpeechServiceProtocol: ObservableObject {
    // MARK: - Published State

    /// Whether the service is currently listening for speech
    var isListening: Bool { get }

    // MARK: - Recording Control

    /// Start listening for speech input
    func startListening()

    /// Stop listening and finalize any pending transcription
    func stopListening()
}
