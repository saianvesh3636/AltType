import Foundation
import AppServices
@testable import HotkeyKit
@testable import SpeechKit
@testable import TextInsertionKit

// MARK: - Mock Objects

@MainActor
class MockSpeechRecognizerDelegate: SpeechRecognizerDelegate {
    var lastRecognizedText: String = ""
    var lastConfidence: Double = 0.0
    var lastIsFinal: Bool = false
    var lastError: Error?
    var callCount: Int = 0
    
    func speechRecognizer(_ recognizer: SpeechRecognizer, didRecognizeText text: String, isFinal: Bool, confidence: Double) {
        lastRecognizedText = text
        lastIsFinal = isFinal
        lastConfidence = confidence
        callCount += 1
    }
    
    func speechRecognizer(_ recognizer: SpeechRecognizer, didFailWithError error: Error) {
        lastError = error
        callCount += 1
    }
    
    func speechRecognizer(_ recognizer: SpeechRecognizer, didUpdateAudioLevel level: Double) {
        callCount += 1
    }
    
    func reset() {
        lastRecognizedText = ""
        lastConfidence = 0.0
        lastIsFinal = false
        lastError = nil
        callCount = 0
    }
}

@MainActor
class MockSpeechActionDelegate: SpeechActionDelegate {
    var startRecordingCalled = false
    var stopRecordingCalled = false
    var startCallCount = 0
    var stopCallCount = 0
    
    func startSpeechRecording() {
        startRecordingCalled = true
        startCallCount += 1
    }
    
    func stopSpeechRecording() {
        stopRecordingCalled = true
        stopCallCount += 1
    }
    
    func reset() {
        startRecordingCalled = false
        stopRecordingCalled = false
        startCallCount = 0
        stopCallCount = 0
    }
}

@MainActor
class MockSoundFeedbackDelegate: SoundFeedbackDelegate {
    var playStartSoundCalled = false
    var playStopSoundCalled = false
    var startSoundCallCount = 0
    var stopSoundCallCount = 0
    
    func playStartSound() {
        playStartSoundCalled = true
        startSoundCallCount += 1
    }
    
    func playStopSound() {
        playStopSoundCalled = true
        stopSoundCallCount += 1
    }
    
    func reset() {
        playStartSoundCalled = false
        playStopSoundCalled = false
        startSoundCallCount = 0
        stopSoundCallCount = 0
    }
}

// MARK: - Mock AX Elements

class MockAXUIElement {
    let supportsAccessibility: Bool
    let frame: CGRect
    let role: String
    let value: String?
    let isEditable: Bool
    
    init(
        supportsAccessibility: Bool = true,
        frame: CGRect = CGRect(x: 100, y: 200, width: 300, height: 20),
        role: String = "AXTextField",
        value: String? = "",
        isEditable: Bool = true
    ) {
        self.supportsAccessibility = supportsAccessibility
        self.frame = frame
        self.role = role
        self.value = value
        self.isEditable = isEditable
    }
}

// MARK: - Test Error Types

enum TestError: Error, Equatable {
    case simulatedError
    case permissionDenied
    case networkUnavailable
    case audioDeviceUnavailable
    case speechRecognitionTimeout
    case accessibilityAPIUnavailable
    
    var localizedDescription: String {
        switch self {
        case .simulatedError:
            return "Simulated test error"
        case .permissionDenied:
            return "Permission denied"
        case .networkUnavailable:
            return "Network unavailable"
        case .audioDeviceUnavailable:
            return "Audio device unavailable"
        case .speechRecognitionTimeout:
            return "Speech recognition timeout"
        case .accessibilityAPIUnavailable:
            return "Accessibility API unavailable"
        }
    }
}

// MARK: - Performance Helpers

func getCurrentMemoryUsage() -> Int64 {
    var info = mach_task_basic_info()
    var count = mach_msg_type_number_t(MemoryLayout<mach_task_basic_info>.size)/4
    
    let kerr: kern_return_t = withUnsafeMutablePointer(to: &info) {
        $0.withMemoryRebound(to: integer_t.self, capacity: 1) {
            task_info(mach_task_self_,
                     task_flavor_t(MACH_TASK_BASIC_INFO),
                     $0,
                     &count)
        }
    }
    
    return kerr == KERN_SUCCESS ? Int64(info.resident_size) : 0
}

func measureExecutionTime<T>(_ operation: () async throws -> T) async rethrows -> (result: T, duration: TimeInterval) {
    let startTime = Date()
    let result = try await operation()
    let duration = Date().timeIntervalSince(startTime)
    return (result, duration)
}

// MARK: - Test Configuration

enum TestConfiguration {
    static let defaultTimeout: TimeInterval = 5.0
    static let performanceTimeout: TimeInterval = 10.0
    static let maxMemoryIncrease: Int64 = 10_000_000 // 10MB
    static let maxLatency: TimeInterval = 0.5 // 500ms
    static let maxStartupLatency: TimeInterval = 1.0 // 1000ms
}

// MARK: - Test Data Generators

struct TestDataGenerator {
    static let sampleTexts = [
        "Hello world",
        "The quick brown fox jumps over the lazy dog",
        "Swift Testing is amazing!",
        "This is a test of the speech recognition system",
        "Testing with special characters: @#$%^&*()",
        "Numbers and dates: 123, January 1st, 2024",
        "Unicode text: 🎤 🗣️ 💬 ✅",
        "Multiple sentences. Each one should be processed correctly. Final sentence here."
    ]
    
    static let hotkeyTestCombinations: [Set<UInt16>] = [
        [58, 49], // Option + Space
        [55, 49], // Command + Space
        [58, 11], // Option + B
        [179],    // Function key only
        [58, 55, 49] // Option + Command + Space
    ]
    
    static func randomText(length: Int = 50) -> String {
        let characters = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789 "
        return String((0..<length).map { _ in characters.randomElement()! })
    }
    
    static func randomHotkeyCombo() -> Set<UInt16> {
        return hotkeyTestCombinations.randomElement() ?? [58, 49]
    }
}

// MARK: - Assertion Helpers

extension SpeechRecognizer {
    func simulateRecognitionResult(text: String, isFinal: Bool, confidence: Double) async {
        await MainActor.run {
            self.delegate?.speechRecognizer(self, didRecognizeText: text, isFinal: isFinal, confidence: confidence)
        }
    }
    
    func simulateError(_ error: Error) async {
        await MainActor.run {
            self.delegate?.speechRecognizer(self, didFailWithError: error)
        }
    }
}

// AudioLevelMonitor removed - audio levels now handled directly by each engine

// MARK: - Wait Helpers

func waitFor(
    condition: @escaping () async -> Bool,
    timeout: TimeInterval = TestConfiguration.defaultTimeout,
    pollingInterval: TimeInterval = 0.1
) async throws {
    let deadline = Date().addingTimeInterval(timeout)
    
    while Date() < deadline {
        if await condition() {
            return
        }
        try await Task.sleep(nanoseconds: UInt64(pollingInterval * 1_000_000_000))
    }
    
    throw TestError.simulatedError
}

// MARK: - Test Categories (for future Swift Testing migration)

enum TestCategory {
    case unit
    case integration
    case performance
    case ui
    case permissions
    case accessibility
    case speech
    case hotkey
    case textInsertion
}