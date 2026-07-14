import XCTest
@testable import SpeechKit
import Speech
import AVFoundation

final class SpeechKitTests: XCTestCase {
    
    // MARK: - Core Engine Tests
    
    @MainActor
    func testSpeechRecognizerInitialization() {
        let recognizer = SpeechRecognizer()
        XCTAssertNotNil(recognizer, "SpeechRecognizer should initialize successfully")
        XCTAssertFalse(recognizer.isListening, "Should not be listening initially")
        XCTAssertNil(recognizer.currentEngineName, "No engine should be active initially")
    }
    
    @MainActor
    func testAppleSpeechEngineInitialization() {
        let engine = AppleSpeechEngine.standard()
        XCTAssertEqual(engine.name, "System Speech")
        XCTAssertEqual(engine.requiredPermissions.count, 1)
        XCTAssertTrue(engine.requiredPermissions.contains(.microphone))
    }
    
    @MainActor
    func testWhisperEngineInitialization() {
        let engine = WhisperEngine.fast()
        XCTAssertEqual(engine.name, "WhisperKit Engine")
        XCTAssertEqual(engine.requiredPermissions.count, 1)
        XCTAssertTrue(engine.requiredPermissions.contains(.microphone))
    }
    
    // MARK: - Engine Selection Tests
    
    @MainActor
    func testEngineManagerSelection() {
        let manager = SpeechEngineManager()
        let engines = manager.getAllEngines()
        XCTAssertEqual(engines.count, 2, "Should have both Apple and Whisper engines")
        
        let engineNames = Set(engines.map { $0.name })
        XCTAssertTrue(engineNames.contains("System Speech"))
        XCTAssertTrue(engineNames.contains("WhisperKit Engine"))
    }
    
    @MainActor
    func testEngineAvailability() {
        let manager = SpeechEngineManager()
        let availableEngines = manager.getAvailableEngines()
        
        // At least one engine should be available
        XCTAssertFalse(availableEngines.isEmpty, "At least one engine should be available")
        
        for engine in availableEngines {
            XCTAssertTrue(engine.isAvailable, "Available engines should report as available")
        }
    }
    
    // MARK: - Thread Safety Tests
    
    @MainActor
    func testAudioEngineThreadSafety() {
        let expectation = XCTestExpectation(description: "Audio engine operations complete")
        
        // Test that audio engines can be created on MainActor without crashes
        Task { @MainActor in
            for _ in 1...5 {
                let appleEngine = AppleSpeechEngine.standard()
                let whisperEngine = WhisperEngine.fast()
                
                XCTAssertNotNil(appleEngine)
                XCTAssertNotNil(whisperEngine)
            }
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 2.0)
    }
    
    // MARK: - Error Handling Tests
    
    @MainActor
    func testSpeechRecognitionErrors() {
        let error = SpeechRecognitionEngineError.engineNotAvailable
        XCTAssertNotNil(error.errorDescription)
        
        let permissionError = SpeechRecognitionEngineError.permissionDenied(.microphone)
        XCTAssertTrue(permissionError.errorDescription?.contains("Microphone") == true)
    }
}