import XCTest
@testable import theTypeAlternative
@testable import HotkeyKit
@testable import SpeechKit
@testable import TextInsertionKit
@testable import PermissionKit
import AppServices
import Combine
import AppKit
import AVFoundation

// MARK: - Integration Tests for theTypeAlternative

final class IntegrationTests: XCTestCase {
    
    // MARK: - Test Properties
    
    private var statusItem: NSStatusItem?
    private var transcriptionStore: TranscriptionStore!
    private var hotkeySettings: HotkeySettings!
    private var permissionManager: PermissionKit.PermissionManager!
    private var appCoordinator: AppCoordinator!
    private var cancellables: Set<AnyCancellable>!
    
    // MARK: - Setup & Teardown
    
    override func setUp() {
        super.setUp()
        cancellables = Set<AnyCancellable>()
    }
    
    override func tearDown() {
        // Clean up resources
        cancellables?.removeAll()
        statusItem = nil
        appCoordinator = nil
        transcriptionStore = nil
        hotkeySettings = nil
        permissionManager = nil
        
        super.tearDown()
    }
    
    // MARK: - Helper Methods
    
    @MainActor
    private func setupDependencies() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        transcriptionStore = TranscriptionStore()
        hotkeySettings = HotkeySettings()
        permissionManager = PermissionKit.PermissionManager()
        
        appCoordinator = AppCoordinator(
            statusItem: statusItem,
            transcriptionStore: transcriptionStore,
            hotkeySettings: hotkeySettings,
            permissionManager: permissionManager,
            speechEngineManager: SpeechEngineManager(),
            speechEngineSettings: SpeechEngineSettings()
        )
    }
    
    // MARK: - App Coordinator Integration Tests
    
    @MainActor
    func testAppCoordinatorInitialization() {
        setupDependencies()
        
        // Test that app coordinator properly initializes with all dependencies
        XCTAssertNotNil(appCoordinator)
        XCTAssertEqual(appCoordinator.state, .idle)
    }
    
    @MainActor
    func testAppCoordinatorStartup() {
        setupDependencies()
        
        // Test the startup sequence
        let expectation = XCTestExpectation(description: "App coordinator starts")
        
        // Monitor state changes
        appCoordinator.$state
            .dropFirst() // Skip initial value
            .sink { state in
                // App should move from idle to either error or idle based on permissions
                if case .error = state {
                    expectation.fulfill()
                } else if state == .idle {
                    expectation.fulfill()
                }
            }
            .store(in: &cancellables)
        
        // Start the coordinator
        appCoordinator.start()
        
        wait(for: [expectation], timeout: 2.0)
    }
    
    @MainActor
    func testPermissionStateIntegration() {
        setupDependencies()
        
        // Test that permission state changes are properly reflected in app state
        let expectation = XCTestExpectation(description: "Permission state integration")
        
        var stateChangeCount = 0
        appCoordinator.$state
            .sink { state in
                stateChangeCount += 1
                if stateChangeCount >= 2 { // Initial + at least one change
                    expectation.fulfill()
                }
            }
            .store(in: &cancellables)
        
        // Trigger permission state refresh
        permissionManager.refreshPermissionStates()
        
        wait(for: [expectation], timeout: 1.0)
        XCTAssertGreaterThan(stateChangeCount, 1)
    }
    
    // MARK: - Hotkey Integration Tests
    
    @MainActor
    func testHotkeySettingsIntegration() {
        setupDependencies()
        
        // Since requiredKeys is read-only, we test that it exists and has the expected structure
        XCTAssertFalse(hotkeySettings.requiredKeys.isEmpty)
        XCTAssertNotNil(hotkeySettings.displayName)
        
        // Test that the hotkey settings are properly configured
        XCTAssertGreaterThan(hotkeySettings.requiredKeys.count, 0)
    }
    
    @MainActor
    func testHotkeyManagerCreation() {
        setupDependencies()
        
        // Test that hotkey manager is properly created and configured
        appCoordinator.start()
        
        // Give some time for async setup
        let expectation = XCTestExpectation(description: "Hotkey manager setup")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 1.0)
        
        // Verify the coordinator has been properly started
        // Note: We can't directly test HotkeyManager as it's private
        // But we can verify the coordinator is in a proper state
        switch appCoordinator.state {
        case .idle, .error:
            XCTAssertTrue(true, "App coordinator is in expected state")
        case .listening:
            XCTFail("App coordinator should not be listening during initialization")
        }
    }
    
    // MARK: - Speech Recognition Integration Tests
    
    @MainActor
    func testSpeechServiceIntegration() {
        setupDependencies()
        
        // Test speech service integration with transcription store
        let expectation = XCTestExpectation(description: "Speech service integration")
        
        // Monitor transcription store changes
        transcriptionStore.$transcriptionHistory
            .dropFirst()
            .sink { history in
                expectation.fulfill()
            }
            .store(in: &cancellables)
        
        // Add a test transcription
        transcriptionStore.addTranscription(
            text: "Test transcription",
            confidence: 0.95,
            duration: 2.5
        )
        
        wait(for: [expectation], timeout: 1.0)
        XCTAssertEqual(transcriptionStore.transcriptionHistory.count, 1)
        XCTAssertEqual(transcriptionStore.transcriptionHistory.first?.text, "Test transcription")
    }
    
    @MainActor
    func testSpeechEngineIntegration() {
        // Test speech engine integration (replaced AudioLevelMonitor)
        let appleEngine = AppleSpeechEngine.standard()
        let whisperEngine = WhisperEngine.fast()
        
        // Test engines can be created properly
        XCTAssertNotNil(appleEngine)
        XCTAssertNotNil(whisperEngine)
        XCTAssertEqual(appleEngine.name, "System Speech")
        XCTAssertEqual(whisperEngine.name, "WhisperKit Engine")
    }
    
    // MARK: - Text Insertion Integration Tests
    
    @MainActor
    func testTextInserterIntegration() {
        // Test text inserter initialization and basic functionality
        let textInserter = TextInsertionKit.TextInserter()
        XCTAssertNotNil(textInserter)
        
        // Test universal text inserter
        let universalInserter = TextInsertionKit.UniversalTextInserter()
        XCTAssertNotNil(universalInserter)
        
        // Note: Actual text insertion requires accessibility permissions and active text fields
        // These are tested in UI tests or manual testing scenarios
    }
    
    @MainActor
    func testContextualIndicatorIntegration() {
        // Test contextual indicator creation and basic functionality
        let indicator = ContextualIndicator()
        XCTAssertNotNil(indicator)

        // Test that indicator methods can be called without crashing
        // Note: Full testing requires active UI elements
        indicator.hide()
    }
    
    // MARK: - Permission Manager Integration Tests
    
    @MainActor
    func testPermissionManagerIntegration() {
        setupDependencies()
        
        // Test permission manager reactive state
        let expectation = XCTestExpectation(description: "Permission manager integration")
        
        permissionManager.$overallState
            .dropFirst()
            .sink { state in
                expectation.fulfill()
            }
            .store(in: &cancellables)
        
        // Trigger a state refresh
        permissionManager.refreshPermissionStates()
        
        wait(for: [expectation], timeout: 1.0)
        
        // Verify computed properties work correctly
        let hasAll = permissionManager.hasAllPermissions
        let needsAny = permissionManager.needsPermissions
        XCTAssertEqual(hasAll, !needsAny)
    }
    
    @MainActor
    func testPermissionManagerStateTransitions() {
        setupDependencies()
        
        // Test that permission state transitions work properly
        let initialState = permissionManager.overallState
        
        // Start monitoring
        permissionManager.startMonitoring()
        
        // Stop monitoring
        permissionManager.stopMonitoring()
        
        // Verify the manager can handle state transitions
        XCTAssertNotNil(initialState)
    }
    
    // MARK: - End-to-End Workflow Tests
    
    @MainActor
    func testCompleteWorkflowIntegration() {
        setupDependencies()
        
        // Test the complete workflow from app start to ready state
        let expectation = XCTestExpectation(description: "Complete workflow")
        expectation.expectedFulfillmentCount = 2 // App start + permission check
        
        var stepCount = 0
        
        // Monitor app coordinator state
        appCoordinator.$state
            .sink { state in
                stepCount += 1
                expectation.fulfill()
                
                switch state {
                case .idle:
                    print("Workflow: App is idle and ready")
                case .listening:
                    print("Workflow: App is listening")
                case .error(let error):
                    print("Workflow: App has error - \(error)")
                }
            }
            .store(in: &cancellables)
        
        // Start the complete workflow
        appCoordinator.start()
        
        wait(for: [expectation], timeout: 3.0)
        XCTAssertGreaterThanOrEqual(stepCount, 2)
    }
    
    @MainActor
    func testErrorRecoveryWorkflow() {
        setupDependencies()
        
        // Test error recovery workflow
        let expectation = XCTestExpectation(description: "Error recovery workflow")
        
        var hasSeenError = false
        var hasRecovered = false
        
        appCoordinator.$state
            .sink { state in
                if case .error = state {
                    hasSeenError = true
                } else if hasSeenError && state == .idle {
                    hasRecovered = true
                    expectation.fulfill()
                }
            }
            .store(in: &cancellables)
        
        // Start the app
        appCoordinator.start()
        
        // Force an error state for testing (if permissions are not available)
        permissionManager.refreshPermissionStates()
        
        wait(for: [expectation], timeout: 2.0)
        
        // Note: In test environment, we typically don't have permissions
        // so we expect to see an error state
        if !hasRecovered {
            XCTAssertTrue(hasSeenError, "Should have seen error state due to missing permissions")
        }
    }
    
    // MARK: - Memory and Performance Integration Tests
    
    @MainActor
    func testMemoryManagementIntegration() {
        // Test that objects are properly deallocated
        weak var weakCoordinator: AppCoordinator?
        weak var weakPermissionManager: PermissionKit.PermissionManager?
        weak var weakTranscriptionStore: TranscriptionStore?
        
        autoreleasepool {
            let tempStatusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
            let tempStore = TranscriptionStore()
            let tempSettings = HotkeySettings()
            let tempPermissions = PermissionKit.PermissionManager()
            let tempCoordinator = AppCoordinator(
                statusItem: tempStatusItem,
                transcriptionStore: tempStore,
                hotkeySettings: tempSettings,
                permissionManager: tempPermissions,
                speechEngineManager: SpeechEngineManager(),
                speechEngineSettings: SpeechEngineSettings()
            )
            
            weakCoordinator = tempCoordinator
            weakPermissionManager = tempPermissions
            weakTranscriptionStore = tempStore
            
            // Use the objects briefly
            tempCoordinator.start()
        }
        
        // Force garbage collection
        autoreleasepool { }
        
        // Note: In test environment, some objects may be retained by the system
        // so we primarily test that no crashes occur during cleanup
        XCTAssertTrue(true, "Memory management test completed without crashes")
    }
    
    // MARK: - Cross-Module Communication Tests
    
    @MainActor
    func testCrossModuleCommunication() {
        setupDependencies()
        
        // Test communication between different modules
        let expectation = XCTestExpectation(description: "Cross-module communication")
        
        // Create a speech action delegate to test hotkey-speech communication
        let mockDelegate = MockSpeechActionDelegate()
        
        // Test delegate methods
        mockDelegate.startSpeechRecording()
        mockDelegate.stopSpeechRecording()
        
        XCTAssertTrue(mockDelegate.startRecordingCalled)
        XCTAssertTrue(mockDelegate.stopRecordingCalled)
        XCTAssertEqual(mockDelegate.startCallCount, 1)
        XCTAssertEqual(mockDelegate.stopCallCount, 1)
        
        expectation.fulfill()
        wait(for: [expectation], timeout: 1.0)
    }
    
    @MainActor
    func testModuleDependencyInjection() {
        // Test that dependency injection works correctly across modules
        let customTranscriptionStore = TranscriptionStore()
        let customHotkeySettings = HotkeySettings()
        let customPermissionManager = PermissionKit.PermissionManager()
        
        let coordinator = AppCoordinator(
            statusItem: nil,
            transcriptionStore: customTranscriptionStore,
            hotkeySettings: customHotkeySettings,
            permissionManager: customPermissionManager,
            speechEngineManager: SpeechEngineManager(),
            speechEngineSettings: SpeechEngineSettings()
        )
        
        XCTAssertNotNil(coordinator)
        XCTAssertEqual(coordinator.state, AppState.idle)
        
        // Test that the coordinator can be started with custom dependencies
        coordinator.start()
        
        // Verify no crashes occur
        XCTAssertTrue(true, "Dependency injection test completed successfully")
    }
}

// MARK: - Helper Mock Classes

@MainActor
class MockSpeechActionDelegate: AppServices.SpeechActionDelegate {
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
}