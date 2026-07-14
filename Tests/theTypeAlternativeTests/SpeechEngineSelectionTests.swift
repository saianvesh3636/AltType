import XCTest
import AppServices
import FullAppConfiguration
import SpeechKit

/// Tests to verify Full variant speech engine selection and availability
/// Tests that both Apple Speech and WhisperKit are supported
@MainActor
final class SpeechEngineSelectionTests: XCTestCase {

    var speechEngineManager: SpeechEngineManager!

    override func setUp() async throws {
        // Initialize Full configuration before each test
        FullAppConfiguration.initialize()

        // Create speech engine manager
        speechEngineManager = SpeechEngineManager()
        XCTAssertNotNil(speechEngineManager, "Failed to create SpeechEngineManager")
    }

    override func tearDown() async throws {
        speechEngineManager = nil
        AppServices.AppConfiguration.current = nil
    }

    // MARK: - WhisperKit Support Tests

    func testFullVariantSupportsWhisperKit() {
        // Given: Full variant is configured
        let features = AppServices.AppConfiguration.current.features

        // Then: WhisperKit should be supported
        XCTAssertTrue(features.supportsWhisperKit,
                     "Full variant should support WhisperKit")
    }

    // MARK: - Speech Engine Manager Tests

    func testSpeechEngineManagerIsCreated() {
        // Given: SpeechEngineManager is created

        // Then: It should be initialized
        XCTAssertNotNil(speechEngineManager, "SpeechEngineManager should be created")
    }

    func testSpeechEngineManagerHasModelManager() {
        // Given: SpeechEngineManager is created

        // Then: It should have model manager for WhisperKit models
        XCTAssertNotNil(speechEngineManager.modelManager,
                       "SpeechEngineManager should have model manager")
    }

    // MARK: - Engine Availability Tests

    func testAppleSpeechEngineIsAvailable() {
        // Given: AppleSpeechEngine class exists

        // When: We create an AppleSpeechEngine
        let appleSpeechEngine = AppleSpeechEngine()

        // Then: It should be available
        XCTAssertNotNil(appleSpeechEngine, "AppleSpeechEngine should be creatable")
        XCTAssertEqual(appleSpeechEngine.name, "System Speech",
                      "Engine name should be System Speech")
    }

    func testWhisperEngineIsAvailable() {
        // Given: Full variant supports WhisperKit

        // When: We try to create a WhisperEngine
        let whisperEngine = WhisperEngine()

        // Then: It should be available (though model may need download)
        XCTAssertNotNil(whisperEngine, "WhisperEngine should be creatable in Full variant")
        XCTAssertTrue(whisperEngine.name.contains("Whisper"),
                     "Engine name should contain 'Whisper'")
    }

    // MARK: - Processing Strategy Tests

    func testSpeechEngineManagerHasProcessingStrategies() {
        // Given: SpeechEngineManager is created

        // Then: It should have adaptive processing strategies
        XCTAssertNotNil(speechEngineManager.currentProcessingStrategy,
                       "Should have current processing strategy")

        // Should be one of: responsive, balanced, efficient
        let validStrategies: [ProcessingStrategy] = [.responsive, .balanced, .efficient]
        XCTAssertTrue(validStrategies.contains(speechEngineManager.currentProcessingStrategy),
                     "Processing strategy should be valid")
    }

    func testProcessingStrategyHasIntervals() {
        // Given: Processing strategies

        // Then: Each should have appropriate intervals
        XCTAssertEqual(ProcessingStrategy.responsive.interval, 0.2,
                      "Responsive strategy should have 0.2s interval")
        XCTAssertEqual(ProcessingStrategy.balanced.interval, 0.5,
                      "Balanced strategy should have 0.5s interval")
        XCTAssertEqual(ProcessingStrategy.efficient.interval, 1.0,
                      "Efficient strategy should have 1.0s interval")
    }

    // MARK: - Model Manager Tests

    func testModelManagerExists() {
        // Given: SpeechEngineManager with model manager

        // Then: Model manager should be accessible
        let modelManager = speechEngineManager.modelManager
        XCTAssertNotNil(modelManager, "Model manager should exist")
    }

    func testModelManagerHasModelStatuses() {
        // Given: Model manager

        // Then: It should track model statuses
        let statuses = speechEngineManager.modelManager.modelStatuses
        XCTAssertNotNil(statuses, "Model statuses should be accessible")
    }

    // MARK: - Engine Protocol Conformance Tests

    func testAppleSpeechEngineConformsToProtocol() {
        // Given: AppleSpeechEngine

        // When: We create an instance
        let engine = AppleSpeechEngine()

        // Then: It should conform to SpeechRecognitionEngine protocol
        XCTAssertNotNil(engine as SpeechRecognitionEngine,
                       "AppleSpeechEngine should conform to SpeechRecognitionEngine")
    }

    func testWhisperEngineConformsToProtocol() {
        // Given: WhisperEngine

        // When: We create an instance
        let engine = WhisperEngine()

        // Then: It should conform to SpeechRecognitionEngine protocol
        XCTAssertNotNil(engine as SpeechRecognitionEngine,
                       "WhisperEngine should conform to SpeechRecognitionEngine")
    }

    // MARK: - Required Permissions Tests

    func testAppleSpeechEngineRequiredPermissions() {
        // Given: AppleSpeechEngine

        // When: We check required permissions
        let engine = AppleSpeechEngine()
        let permissions = engine.requiredPermissions

        // Then: It should require microphone permission only
        // (SpeechAnalyzer needs no speech-recognition authorization)
        XCTAssertTrue(permissions.contains(.microphone),
                     "Apple Speech should require microphone permission")
        XCTAssertEqual(permissions.count, 1,
                     "Apple Speech should only require microphone")
    }

    func testWhisperEngineRequiredPermissions() {
        // Given: WhisperEngine

        // When: We check required permissions
        let engine = WhisperEngine()
        let permissions = engine.requiredPermissions

        // Then: It should require microphone permission (on-device, no cloud permissions)
        XCTAssertTrue(permissions.contains(.microphone),
                     "WhisperKit should require microphone permission")
    }

    // MARK: - Processing Unit Tests

    func testProcessingUnitWordCount() {
        // Given: Word-based processing unit (Apple Speech)
        let words = ProcessingUnit.words(100)

        // Then: Count should be accessible
        XCTAssertEqual(words.count, 100, "Word count should be 100")
        XCTAssertEqual(words.normalizedWordCount, 100.0, "Normalized word count should be 100.0")
        XCTAssertEqual(words.unitType, "words", "Unit type should be 'words'")
    }

    func testProcessingUnitTokenCount() {
        // Given: Token-based processing unit (WhisperKit)
        let tokens = ProcessingUnit.tokens(100)

        // Then: Count should be accessible and normalized
        XCTAssertEqual(tokens.count, 100, "Token count should be 100")
        XCTAssertEqual(tokens.normalizedWordCount, 75.0, "Normalized word count should be 75.0 (0.75 conversion)")
        XCTAssertEqual(tokens.unitType, "tokens", "Unit type should be 'tokens'")
    }

    func testProcessingUnitAddition() {
        // Given: Different processing units
        let words = ProcessingUnit.words(100)
        let tokens = ProcessingUnit.tokens(100)

        // When: We add them
        let total = words + tokens

        // Then: They should be combined with normalization
        XCTAssertEqual(total.normalizedWordCount, 175.0,
                      "Combined should be 100 + 75 = 175 normalized words")
    }
}
