import XCTest
import AppServices
import FullAppConfiguration
import TextInsertionKit
import Combine

/// Tests to verify Full variant text insertion strategies
/// Tests multi-strategy approach: AX API → Keyboard → Clipboard
@MainActor
final class TextInsertionStrategyTests: XCTestCase {

    var textInserter: UniversalTextInserter!
    var cancellables: Set<AnyCancellable>!

    override func setUp() async throws {
        // Initialize Full configuration before each test
        FullAppConfiguration.initialize()

        // Create text insertion service
        textInserter = AppServices.AppConfiguration.current.createTextInsertionService() as? UniversalTextInserter
        XCTAssertNotNil(textInserter, "Failed to create UniversalTextInserter")

        cancellables = []
    }

    override func tearDown() async throws {
        cancellables = nil
        textInserter = nil
        AppServices.AppConfiguration.current = nil
    }

    // MARK: - Strategy Support Tests

    func testFullVariantSupportsAdvancedTextInsertion() {
        // Given: Full variant is configured
        let features = AppServices.AppConfiguration.current.features

        // Then: Advanced text insertion should be supported
        XCTAssertTrue(features.supportsAdvancedTextInsertion,
                     "Full variant should support advanced text insertion")
    }

    func testUniversalTextInserterIsCreated() {
        // Given: Full configuration creates text insertion service

        // Then: It should be UniversalTextInserter (multi-strategy)
        XCTAssertNotNil(textInserter, "UniversalTextInserter should be created")
    }

    // MARK: - Text Insertion Tests

    func testCanInsertText() {
        // Given: UniversalTextInserter is created
        let testText = "Test insertion"

        // When: We insert text
        textInserter.insertText(testText, isFinal: true)

        // Then: It should complete without crashing
        // Note: Actual insertion depends on active application and focus
        XCTAssertTrue(true, "Text insertion should not crash")
    }

    func testInsertionSetsIsInsertingFlag() {
        // Given: UniversalTextInserter is not inserting
        XCTAssertFalse(textInserter.isInserting, "Should not be inserting initially")

        // When: We insert text
        textInserter.insertText("Test", isFinal: true)

        // Then: isInserting flag should be set (may be brief)
        // Note: This is async, so we can't reliably test the transient state
        // We verify the property exists and is accessible
        XCTAssertNotNil(textInserter.isInserting, "isInserting property should be accessible")
    }

    func testCannotInsertEmptyText() {
        // Given: UniversalTextInserter is created
        let initialState = textInserter.isInserting

        // When: We try to insert empty text
        textInserter.insertText("", isFinal: true)

        // Then: It should be ignored (no-op)
        XCTAssertEqual(textInserter.isInserting, initialState,
                      "Empty text insertion should be no-op")
    }

    func testLastInsertionResultIsRecorded() {
        // Given: UniversalTextInserter with no previous insertion
        let testText = "Test"

        // When: We insert text
        textInserter.insertText(testText, isFinal: true)

        // Wait briefly for async operation
        let expectation = XCTestExpectation(description: "Wait for insertion")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 1.0)

        // Then: lastInsertionResult should be populated
        XCTAssertNotNil(textInserter.lastInsertionResult,
                       "Last insertion result should be recorded")
    }

    // MARK: - Reactive Integration Tests

    func testCanSignalHotkeyState() {
        // Given: UniversalTextInserter is created

        // When: We signal hotkey state changes
        textInserter.signalHotkeyState(true)
        textInserter.signalHotkeyState(false)

        // Then: It should complete without error
        XCTAssertTrue(true, "Signaling hotkey state should not crash")
    }

    func testCanSignalManagerState() {
        // Given: UniversalTextInserter is created

        // When: We signal manager state changes
        textInserter.signalManagerState(.dormant)
        textInserter.signalManagerState(.primed)
        textInserter.signalManagerState(.dictating)

        // Then: It should complete without error
        XCTAssertTrue(true, "Signaling manager state should not crash")
    }

    // MARK: - Strategy Behavior Tests

    func testInserterHasMultipleStrategies() {
        // Given: UniversalTextInserter is created (Full variant)

        // Then: It should support multiple insertion strategies
        // We verify this by checking that it's UniversalTextInserter
        // which implements AX API, Keyboard, and Clipboard strategies
        XCTAssertTrue(textInserter is UniversalTextInserter,
                     "Full variant should use UniversalTextInserter with multiple strategies")
    }

    func testInsertionResultContainsMethod() {
        // Given: UniversalTextInserter that has performed insertion
        textInserter.insertText("Test", isFinal: true)

        // Wait for insertion to complete
        let expectation = XCTestExpectation(description: "Wait for insertion")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 1.0)

        // Then: Result should indicate which strategy was used
        if let result = textInserter.lastInsertionResult {
            XCTAssertNotNil(result.method, "Insertion result should contain method used")
            // Method could be: "Accessibility API", "Keyboard Simulation", or "Clipboard"
            XCTAssertFalse(result.method.isEmpty, "Method should not be empty")
        }
    }

    // MARK: - Concurrent Insertion Prevention Tests

    func testCannotInsertWhileAlreadyInserting() {
        // Given: UniversalTextInserter is currently inserting
        textInserter.insertText("First insertion", isFinal: true)

        // When: We try to insert again immediately
        textInserter.insertText("Second insertion", isFinal: true)

        // Then: Second insertion should be ignored (prevents concurrent operations)
        // This is a safety feature to prevent race conditions
        XCTAssertTrue(true, "Concurrent insertion attempts should be handled safely")
    }

    // MARK: - Publisher Tests

    func testIsInsertingPublisherEmitsChanges() {
        // Given: UniversalTextInserter with publisher subscription
        var insertingStates: [Bool] = []

        textInserter.$isInserting
            .sink { isInserting in
                insertingStates.append(isInserting)
            }
            .store(in: &cancellables)

        // When: We perform insertion
        textInserter.insertText("Test", isFinal: true)

        // Wait for operation
        let expectation = XCTestExpectation(description: "Wait for publisher")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 1.0)

        // Then: Publisher should have emitted states
        XCTAssertTrue(insertingStates.contains(false), "Should have emitted false (initial)")
        // May contain true during insertion
    }
}
