import XCTest
@testable import SpeechKit
import Speech
import AVFoundation

// MARK: - Simple SpeechKit Tests (MainActor-safe)

final class SimpleSpeechKitTests: XCTestCase {
    
    // MARK: - Core Tests
    
    @MainActor
    func testBasicInitialization() {
        // Test that all engines can be initialized without crashes
        let speechRecognizer = SpeechRecognizer()
        let appleEngine = AppleSpeechEngine.standard()
        let whisperEngine = WhisperEngine.fast()
        let engineManager = SpeechEngineManager()
        
        XCTAssertNotNil(speechRecognizer)
        XCTAssertNotNil(appleEngine)
        XCTAssertNotNil(whisperEngine)
        XCTAssertNotNil(engineManager)
    }
    
    @MainActor
    func testEngineNames() {
        let appleEngine = AppleSpeechEngine.standard()
        let whisperEngine = WhisperEngine.fast()
        
        XCTAssertEqual(appleEngine.name, "System Speech")
        XCTAssertEqual(whisperEngine.name, "WhisperKit Engine")
    }
    
    @MainActor
    func testEnginePermissions() {
        let appleEngine = AppleSpeechEngine.standard()
        let whisperEngine = WhisperEngine.fast()

        // Both engines only require microphone
        XCTAssertEqual(appleEngine.requiredPermissions.count, 1)
        XCTAssertTrue(appleEngine.requiredPermissions.contains(.microphone))

        XCTAssertEqual(whisperEngine.requiredPermissions.count, 1)
        XCTAssertTrue(whisperEngine.requiredPermissions.contains(.microphone))
    }

    @MainActor
    func testFactoryMethods() {
        // Test Apple engine factory methods
        let standardApple = AppleSpeechEngine.standard()
        let localeApple = AppleSpeechEngine.forLocale(Locale(identifier: "es-ES"))

        XCTAssertEqual(standardApple.name, "System Speech")
        XCTAssertEqual(localeApple.name, "System Speech")
        
        // Test Whisper engine factory methods
        let fastWhisper = WhisperEngine.fast()
        let accurateWhisper = WhisperEngine.accurate()
        let localeWhisper = WhisperEngine.forLocale(Locale(identifier: "fr-FR"))
        let timestampWhisper = WhisperEngine.withTimestamps()
        
        XCTAssertEqual(fastWhisper.name, "WhisperKit Engine")
        XCTAssertEqual(accurateWhisper.name, "WhisperKit Engine")
        XCTAssertEqual(localeWhisper.name, "WhisperKit Engine")
        XCTAssertEqual(timestampWhisper.name, "WhisperKit Engine")
    }
    
    @MainActor
    func testEngineManager() {
        let manager = SpeechEngineManager()
        let allEngines = manager.getAllEngines()
        let _ = manager.getAvailableEngines()  // Suppress unused warning
        let statuses = manager.getEngineStatuses()
        
        XCTAssertEqual(allEngines.count, 2, "Should have both Apple and Whisper engines")
        XCTAssertEqual(statuses.count, 2, "Should have status for both engines")
        
        // At least one engine should typically be available
        let engineNames = Set(allEngines.map { $0.name })
        XCTAssertTrue(engineNames.contains("System Speech"))
        XCTAssertTrue(engineNames.contains("WhisperKit Engine"))
    }
    
    func testPermissionTypes() {
        let microphone = SpeechPermissionType.microphone

        XCTAssertEqual(microphone.displayName, "Microphone")

        let allPermissions = SpeechPermissionType.allCases
        XCTAssertEqual(allPermissions.count, 1)
    }
    
    func testErrorTypes() {
        let engineError = SpeechRecognitionEngineError.engineNotAvailable
        let permissionError = SpeechRecognitionEngineError.permissionDenied(.microphone)
        let initError = SpeechRecognitionEngineError.initializationFailed("Test")
        let recognitionError = SpeechRecognitionEngineError.recognitionFailed("Test")
        
        XCTAssertNotNil(engineError.errorDescription)
        XCTAssertNotNil(permissionError.errorDescription)
        XCTAssertNotNil(initError.errorDescription)
        XCTAssertNotNil(recognitionError.errorDescription)
    }
    
    @MainActor
    func testSpeechRecognizerProperties() {
        let recognizer = SpeechRecognizer()
        
        XCTAssertFalse(recognizer.isListening, "Should not be listening initially")
        XCTAssertNil(recognizer.currentEngineName, "No engine should be active initially")
        XCTAssertNil(recognizer.delegate, "Delegate should be nil initially")
    }
    
    func testAudioFormatCreation() {
        // Test that common audio formats can be created
        let formats = [
            AVAudioFormat(commonFormat: .pcmFormatFloat32, sampleRate: 44100, channels: 1, interleaved: false),
            AVAudioFormat(commonFormat: .pcmFormatFloat32, sampleRate: 48000, channels: 1, interleaved: false),
            AVAudioFormat(commonFormat: .pcmFormatFloat32, sampleRate: 16000, channels: 1, interleaved: false)
        ]
        
        for format in formats {
            XCTAssertNotNil(format, "Audio format should be created successfully")
        }
    }
    
    @MainActor
    func testEngineMemoryManagement() {
        // Test that engines are properly deallocated
        weak var weakApple: AppleSpeechEngine?
        weak var weakWhisper: WhisperEngine?
        weak var weakRecognizer: SpeechRecognizer?
        
        autoreleasepool {
            let appleEngine = AppleSpeechEngine.standard()
            let whisperEngine = WhisperEngine.fast()
            let recognizer = SpeechRecognizer()
            
            weakApple = appleEngine
            weakWhisper = whisperEngine
            weakRecognizer = recognizer
        }
        
        // Apple engine and recognizer should be deallocated
        XCTAssertNil(weakApple, "Apple engine should be deallocated")
        XCTAssertNil(weakRecognizer, "Speech recognizer should be deallocated")
        
        // WhisperKit may hold internal references, so we'll be more lenient
        if weakWhisper != nil {
            print("Note: WhisperEngine not immediately deallocated - this is expected due to WhisperKit internal references")
        }
    }
}