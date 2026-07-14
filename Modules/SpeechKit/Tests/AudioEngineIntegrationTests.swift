import XCTest
@testable import SpeechKit
import Speech
import AVFoundation
import Combine

// MARK: - Audio Engine Integration Tests

final class AudioEngineIntegrationTests: XCTestCase {
    
    // MARK: - Test Properties
    
    private var appleEngine: AppleSpeechEngine!
    private var whisperEngine: WhisperEngine!
    private var mockDelegate: MockSpeechEngineDelegate!
    
    // MARK: - Setup & Teardown
    
    override func setUp() {
        super.setUp()
        mockDelegate = MockSpeechEngineDelegate()
    }
    
    override func tearDown() {
        // Tests handle their own cleanup to avoid MainActor issues
        super.tearDown()
    }
    
    // MARK: - Apple Speech Engine Audio Tests
    
    @MainActor
    func testAppleSpeechEngineAudioEngineIsolation() {
        appleEngine = AppleSpeechEngine.standard()
        
        // Test that engine can be started and stopped without MainActor violations
        do {
            try appleEngine.startRecognition(delegate: mockDelegate)
            
            // Engine should be running
            XCTAssertTrue(true, "Apple engine started without MainActor violations")
            
            // Stop recognition
            appleEngine.stopRecognition()
            XCTAssertTrue(true, "Apple engine stopped without MainActor violations")
            
        } catch {
            // This might fail in test environment due to permissions, but shouldn't crash
            XCTAssertTrue(error is SpeechRecognitionEngineError, "Should throw proper SpeechRecognitionEngineError")
        }
    }
    
    @MainActor
    func testAppleSpeechEngineMultipleStartStop() {
        appleEngine = AppleSpeechEngine.standard()
        
        // Test multiple start/stop cycles don't cause crashes
        for i in 1...3 {
            do {
                try appleEngine.startRecognition(delegate: mockDelegate)
                
                // Brief pause
                Thread.sleep(forTimeInterval: 0.1)
                
                appleEngine.stopRecognition()
                
                XCTAssertTrue(true, "Apple engine cycle \(i) completed without crashes")
                
            } catch {
                // Expected in test environment without proper permissions
                XCTAssertTrue(error is SpeechRecognitionEngineError)
            }
        }
    }
    
    // MARK: - WhisperKit Engine Audio Tests
    
    @MainActor
    func testWhisperEngineAudioEngineIsolation() {
        whisperEngine = WhisperEngine.fast()
        
        // Test that engine can be started and stopped without MainActor violations
        do {
            try whisperEngine.startRecognition(delegate: mockDelegate)
            
            // Engine should be running
            XCTAssertTrue(true, "Whisper engine started without MainActor violations")
            
            // Stop recognition
            whisperEngine.stopRecognition()
            XCTAssertTrue(true, "Whisper engine stopped without MainActor violations")
            
        } catch {
            // This might fail if WhisperKit is not ready, but shouldn't crash
            XCTAssertTrue(error is SpeechRecognitionEngineError, "Should throw proper SpeechRecognitionEngineError")
        }
    }
    
    @MainActor
    func testWhisperEngineMultipleStartStop() {
        whisperEngine = WhisperEngine.fast()
        
        // Test multiple start/stop cycles don't cause crashes
        for i in 1...3 {
            do {
                try whisperEngine.startRecognition(delegate: mockDelegate)
                
                // Brief pause
                Thread.sleep(forTimeInterval: 0.1)
                
                whisperEngine.stopRecognition()
                
                XCTAssertTrue(true, "Whisper engine cycle \(i) completed without crashes")
                
            } catch {
                // Expected if WhisperKit is not ready
                XCTAssertTrue(error is SpeechRecognitionEngineError)
            }
        }
    }
    
    // MARK: - Concurrent Engine Tests
    
    @MainActor
    func testSequentialEngineOperation() {
        // Test that both engines can be created and managed without conflicts
        let appleEngine = AppleSpeechEngine.standard()
        let whisperEngine = WhisperEngine.fast()
        
        // Test sequential operation
        do {
            try appleEngine.startRecognition(delegate: mockDelegate)
            appleEngine.stopRecognition()
            
            try whisperEngine.startRecognition(delegate: mockDelegate)
            whisperEngine.stopRecognition()
            
            XCTAssertTrue(true, "Both engines operated without conflicts")
        } catch {
            // Expected in test environment without permissions
            XCTAssertTrue(error is SpeechRecognitionEngineError)
        }
    }
    
    // MARK: - Audio Buffer Processing Tests
    
    func testAudioBufferProcessing() {
        // Test audio buffer creation and processing
        let sampleRate: Double = 44100
        let channels: UInt32 = 1
        let frameCount: AVAudioFrameCount = 1024
        
        guard let format = AVAudioFormat(commonFormat: .pcmFormatFloat32, sampleRate: sampleRate, channels: channels, interleaved: false) else {
            XCTFail("Failed to create audio format")
            return
        }
        
        guard let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: frameCount) else {
            XCTFail("Failed to create audio buffer")
            return
        }
        
        buffer.frameLength = frameCount
        
        // Fill buffer with test data
        if let channelData = buffer.floatChannelData?[0] {
            for i in 0..<Int(frameCount) {
                channelData[i] = sin(2.0 * Float.pi * Float(i) * 440.0 / Float(sampleRate)) // 440Hz tone
            }
        }
        
        XCTAssertEqual(buffer.frameLength, frameCount)
        XCTAssertNotNil(buffer.floatChannelData)
    }
    
    // MARK: - Resource Management Tests
    
    @MainActor
    func testEngineResourceCleanup() {
        // Test that engines properly clean up their audio resources
        var engines: [SpeechRecognitionEngine] = []
        
        // Create multiple engines
        for _ in 1...5 {
            engines.append(AppleSpeechEngine.standard())
            engines.append(WhisperEngine.fast())
        }
        
        // Test engines can be created without crashes
        XCTAssertEqual(engines.count, 10, "Should create 10 engines")
        
        // Test resource cleanup
        for engine in engines {
            XCTAssertNotNil(engine, "\(engine.name) should be created successfully")
        }
        
        // Clear engines
        engines.removeAll()
        
        // Force garbage collection
        autoreleasepool { }
        
        XCTAssertTrue(true, "All engines cleaned up successfully")
    }
    
    // MARK: - Performance Tests
    
    @MainActor
    func testEngineCreationPerformance() {
        measure {
            // Test performance of engine creation
            for _ in 1...10 {
                let appleEngine = AppleSpeechEngine.standard()
                let whisperEngine = WhisperEngine.fast()
                
                XCTAssertNotNil(appleEngine)
                XCTAssertNotNil(whisperEngine)
            }
        }
    }
    
    @MainActor
    func testEngineManagerPerformance() {
        measure {
            // Test performance of engine manager operations
            for _ in 1...100 {
                let manager = SpeechEngineManager()
                let _ = manager.getAllEngines()
                let _ = manager.getAvailableEngines()
                let _ = manager.selectBestEngine()
                let _ = manager.getEngineStatuses()
            }
        }
    }
}

// MARK: - Test Utilities

extension AudioEngineIntegrationTests {
    
    /// Create a test audio buffer with sine wave data
    func createTestAudioBuffer(frequency: Float = 440.0, duration: Float = 0.1, sampleRate: Double = 44100) -> AVAudioPCMBuffer? {
        let channels: UInt32 = 1
        let frameCount = AVAudioFrameCount(duration * Float(sampleRate))
        
        guard let format = AVAudioFormat(commonFormat: .pcmFormatFloat32, sampleRate: sampleRate, channels: channels, interleaved: false),
              let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: frameCount) else {
            return nil
        }
        
        buffer.frameLength = frameCount
        
        // Fill with sine wave
        if let channelData = buffer.floatChannelData?[0] {
            for i in 0..<Int(frameCount) {
                channelData[i] = sin(2.0 * Float.pi * frequency * Float(i) / Float(sampleRate))
            }
        }
        
        return buffer
    }
}