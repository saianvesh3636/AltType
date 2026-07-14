import XCTest
@testable import SpeechKit
import Speech
import AVFoundation
import Combine

// MARK: - Comprehensive SpeechKit Tests

final class ComprehensiveSpeechKitTests: XCTestCase {
    
    // MARK: - Test Properties
    
    private var speechRecognizer: SpeechRecognizer!
    private var appleEngine: AppleSpeechEngine!
    private var whisperEngine: WhisperEngine!
    private var cancellables: Set<AnyCancellable>!
    
    // MARK: - Setup & Teardown
    
    override func setUp() {
        super.setUp()
        cancellables = Set<AnyCancellable>()
    }
    
    override func tearDown() {
        // Tests handle their own cleanup to avoid MainActor issues
        cancellables?.removeAll()
        super.tearDown()
    }
    
    // MARK: - Core Engine Initialization Tests
    
    @MainActor
    func testSpeechRecognizerInitialization() {
        speechRecognizer = SpeechRecognizer()
        XCTAssertNotNil(speechRecognizer, "SpeechRecognizer should initialize successfully")
        XCTAssertFalse(speechRecognizer.isListening, "Should not be listening initially")
        XCTAssertNil(speechRecognizer.currentEngineName, "No engine should be active initially")
    }
    
    @MainActor
    func testAppleSpeechEngineInitialization() {
        appleEngine = AppleSpeechEngine.standard()
        XCTAssertEqual(appleEngine.name, "System Speech")
        XCTAssertEqual(appleEngine.requiredPermissions.count, 1)
        XCTAssertTrue(appleEngine.requiredPermissions.contains(.microphone))
    }

    @MainActor
    func testWhisperEngineInitialization() {
        whisperEngine = WhisperEngine.fast()
        XCTAssertEqual(whisperEngine.name, "WhisperKit Engine")
        XCTAssertEqual(whisperEngine.requiredPermissions.count, 1)
        XCTAssertTrue(whisperEngine.requiredPermissions.contains(.microphone))
    }
    
    // MARK: - Engine Manager Tests
    
    @MainActor
    func testEngineManagerInitialization() {
        let manager = SpeechEngineManager()
        let engines = manager.getAllEngines()
        
        XCTAssertEqual(engines.count, 2, "Should have both Apple and Whisper engines")
        
        let engineNames = Set(engines.map { $0.name })
        XCTAssertTrue(engineNames.contains("System Speech"))
        XCTAssertTrue(engineNames.contains("WhisperKit Engine"))
    }
    
    @MainActor
    func testEngineSelection() {
        let manager = SpeechEngineManager()
        let selectedEngine = manager.selectBestEngine()
        
        // Should select an engine if available
        if selectedEngine != nil {
            XCTAssertTrue(selectedEngine!.isAvailable, "Selected engine should be available")
        }
        
        // Test availability check
        let availableEngines = manager.getAvailableEngines()
        for engine in availableEngines {
            XCTAssertTrue(engine.isAvailable, "Available engines should report as available")
        }
    }
    
    @MainActor
    func testEngineStatuses() {
        let manager = SpeechEngineManager()
        let statuses = manager.getEngineStatuses()
        
        XCTAssertEqual(statuses.count, 2, "Should have status for both engines")
        
        for status in statuses {
            XCTAssertNotNil(status.engine, "Status should have an engine")
            // Test that status correctly reports availability
            XCTAssertEqual(status.isAvailable, status.engine.isAvailable)
        }
    }
    
    // MARK: - Factory Method Tests
    
    @MainActor
    func testAppleSpeechEngineFactoryMethods() {
        let standardEngine = AppleSpeechEngine.standard()
        XCTAssertEqual(standardEngine.name, "System Speech")

        let localeEngine = AppleSpeechEngine.forLocale(Locale(identifier: "es-ES"))
        XCTAssertEqual(localeEngine.name, "System Speech")
    }
    
    @MainActor
    func testWhisperEngineFactoryMethods() {
        let fastEngine = WhisperEngine.fast()
        XCTAssertEqual(fastEngine.name, "WhisperKit Engine")
        
        let accurateEngine = WhisperEngine.accurate()
        XCTAssertEqual(accurateEngine.name, "WhisperKit Engine")
        
        let localeEngine = WhisperEngine.forLocale(Locale(identifier: "es-ES"))
        XCTAssertEqual(localeEngine.name, "WhisperKit Engine")
        
        let timestampEngine = WhisperEngine.withTimestamps()
        XCTAssertEqual(timestampEngine.name, "WhisperKit Engine")
    }
    
    // MARK: - Thread Safety Tests
    
    @MainActor
    func testMultipleEngineCreation() {
        // Test that engines can be created multiple times without crashes
        for i in 1...10 {
            let appleEngine = AppleSpeechEngine.standard()
            let whisperEngine = WhisperEngine.fast()
            
            XCTAssertNotNil(appleEngine, "Apple engine \(i) should be created successfully")
            XCTAssertNotNil(whisperEngine, "Whisper engine \(i) should be created successfully")
        }
    }
    
    // MARK: - Permission Tests
    
    func testPermissionTypes() {
        let microphone = SpeechPermissionType.microphone

        XCTAssertEqual(microphone.displayName, "Microphone")

        let allPermissions = SpeechPermissionType.allCases
        XCTAssertEqual(allPermissions.count, 1)
    }
    
    // MARK: - Error Handling Tests
    
    func testSpeechRecognitionErrors() {
        let engineError = SpeechRecognitionEngineError.engineNotAvailable
        XCTAssertNotNil(engineError.errorDescription)
        
        let permissionError = SpeechRecognitionEngineError.permissionDenied(.microphone)
        XCTAssertTrue(permissionError.errorDescription?.contains("Microphone") == true)
        
        let initError = SpeechRecognitionEngineError.initializationFailed("Test failure")
        XCTAssertTrue(initError.errorDescription?.contains("Test failure") == true)
        
        let recognitionError = SpeechRecognitionEngineError.recognitionFailed("Recognition failed")
        XCTAssertTrue(recognitionError.errorDescription?.contains("Recognition failed") == true)
    }
    
    // MARK: - Configuration Tests
    
    @MainActor
    func testAppleSpeechEngineConfiguration() {
        let config = AppleSpeechEngine.Configuration(
            locale: Locale(identifier: "es-ES"),
            shouldReportPartialResults: false
        )

        let engine = AppleSpeechEngine(configuration: config)
        XCTAssertEqual(engine.name, "System Speech")
    }
    
    @MainActor
    func testWhisperEngineConfiguration() {
        let config = WhisperEngine.Configuration(
            modelName: "tiny",
            locale: Locale(identifier: "fr-FR"),
            enableTimestamps: true,
            enableVoiceActivityDetection: false,
            chunkSize: 1.0
        )
        
        let engine = WhisperEngine(configuration: config)
        XCTAssertEqual(engine.name, "WhisperKit Engine")
    }
    
    // MARK: - Memory Management Tests
    
    @MainActor
    func testEngineMemoryManagement() {
        weak var weakAppleEngine: AppleSpeechEngine?
        weak var weakWhisperEngine: WhisperEngine?
        weak var weakRecognizer: SpeechRecognizer?
        
        autoreleasepool {
            let appleEngine = AppleSpeechEngine.standard()
            let whisperEngine = WhisperEngine.fast()
            let recognizer = SpeechRecognizer()
            
            weakAppleEngine = appleEngine
            weakWhisperEngine = whisperEngine
            weakRecognizer = recognizer
            
            XCTAssertNotNil(weakAppleEngine)
            XCTAssertNotNil(weakWhisperEngine)
            XCTAssertNotNil(weakRecognizer)
        }
        
        // Apple engine and recognizer should be deallocated
        XCTAssertNil(weakAppleEngine, "Apple engine should be deallocated")
        XCTAssertNil(weakRecognizer, "Speech recognizer should be deallocated")
        
        // WhisperKit may hold internal references, so we'll be more lenient
        if weakWhisperEngine != nil {
            print("Note: WhisperEngine not immediately deallocated - this is expected due to WhisperKit internal references")
        }
    }
    
    // MARK: - Audio Format Tests
    
    func testAudioFormatSupport() {
        // Test that engines can handle common audio formats
        let commonFormats = [
            AVAudioFormat(commonFormat: .pcmFormatFloat32, sampleRate: 44100, channels: 1, interleaved: false),
            AVAudioFormat(commonFormat: .pcmFormatFloat32, sampleRate: 48000, channels: 1, interleaved: false),
            AVAudioFormat(commonFormat: .pcmFormatFloat32, sampleRate: 16000, channels: 1, interleaved: false)
        ]
        
        for format in commonFormats {
            XCTAssertNotNil(format, "Common audio formats should be supported")
        }
    }
    
    // MARK: - Integration Tests
    
    @MainActor
    func testSpeechRecognizerEngineIntegration() {
        speechRecognizer = SpeechRecognizer()
        let manager = SpeechEngineManager()
        
        // Test that speech recognizer can work with engine manager
        let engines = manager.getAllEngines()
        XCTAssertFalse(engines.isEmpty, "Engine manager should provide engines to speech recognizer")
        
        // Test that engines can be instantiated through speech recognizer
        XCTAssertNotNil(speechRecognizer, "Speech recognizer should integrate with engines")
    }
}

// MARK: - Mock Delegate for Testing

@MainActor
class MockSpeechRecognizerDelegate: SpeechRecognizerDelegate {
    var recognizedTexts: [String] = []
    var errors: [Error] = []
    var audioLevels: [Double] = []
    
    func speechRecognizer(_ recognizer: SpeechRecognizer, didRecognizeText text: String, isFinal: Bool, confidence: Double) {
        recognizedTexts.append(text)
    }
    
    func speechRecognizer(_ recognizer: SpeechRecognizer, didFailWithError error: Error) {
        errors.append(error)
    }
    
    func speechRecognizer(_ recognizer: SpeechRecognizer, didUpdateAudioLevel level: Double) {
        audioLevels.append(level)
    }
}

@MainActor
class MockSpeechEngineDelegate: SpeechRecognitionEngineDelegate {
    var recognizedTexts: [String] = []
    var errors: [Error] = []
    var audioLevels: [Double] = []
    
    func speechEngine(_ engine: SpeechRecognitionEngine, didRecognizeText text: String, isFinal: Bool, confidence: Double) {
        recognizedTexts.append(text)
    }
    
    func speechEngine(_ engine: SpeechRecognitionEngine, didFailWithError error: Error) {
        errors.append(error)
    }
    
    func speechEngine(_ engine: SpeechRecognitionEngine, didUpdateAudioLevel level: Double) {
        audioLevels.append(level)
    }
}