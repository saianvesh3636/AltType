import XCTest
@testable import theTypeAlternative
@testable import HotkeyKit
@testable import SpeechKit
@testable import TextInsertionKit
@testable import PermissionKit
import Combine
import AppKit

// MARK: - Performance Tests for theTypeAlternative

final class PerformanceTests: XCTestCase {
    
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
    
    // MARK: - App Startup Performance Tests
    
    @MainActor
    func testAppCoordinatorInitializationPerformance() {
        // Test the performance of creating an AppCoordinator with all dependencies
        measure {
            let tempStatusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
            let tempStore = TranscriptionStore()
            let tempSettings = HotkeySettings()
            let tempPermissions = PermissionKit.PermissionManager()
            
            let coordinator = AppCoordinator(
                statusItem: tempStatusItem,
                transcriptionStore: tempStore,
                hotkeySettings: tempSettings,
                permissionManager: tempPermissions,
                speechEngineManager: SpeechEngineManager(),
                speechEngineSettings: SpeechEngineSettings()
            )
            
            // Use the coordinator to prevent optimization
            XCTAssertNotNil(coordinator)
        }
    }
    
    @MainActor
    func testAppStartupPerformance() {
        setupDependencies()
        
        // Test the performance of starting the app coordinator
        measure {
            appCoordinator.start()
        }
    }
    
    // MARK: - Module Creation Performance Tests
    
    @MainActor
    func testTranscriptionStoreCreationPerformance() {
        // Test the performance of creating a TranscriptionStore
        measure {
            for _ in 0..<10 {
                let store = TranscriptionStore()
                XCTAssertNotNil(store)
            }
        }
    }
    
    @MainActor
    func testHotkeySettingsCreationPerformance() {
        // Test the performance of creating HotkeySettings
        measure {
            for _ in 0..<10 {
                let settings = HotkeySettings()
                XCTAssertNotNil(settings)
            }
        }
    }
    
    @MainActor
    func testPermissionManagerCreationPerformance() {
        // Test the performance of creating PermissionManager
        measure {
            for _ in 0..<10 {
                let manager = PermissionKit.PermissionManager()
                XCTAssertNotNil(manager)
            }
        }
    }
    
    // MARK: - Audio Processing Performance Tests
    
    @MainActor
    func testSpeechEngineCreationPerformance() {
        // Test the performance of creating speech engines (replaced AudioLevelMonitor)
        measure {
            for _ in 0..<100 {
                let appleEngine = SpeechKit.AppleSpeechEngine.standard()
                let whisperEngine = SpeechKit.WhisperEngine.fast()
                XCTAssertNotNil(appleEngine)
                XCTAssertNotNil(whisperEngine)
            }
        }
    }
    
    @MainActor
    func testSpeechRecognizerCreationPerformance() {
        // Test the performance of creating SpeechRecognizer
        measure {
            for _ in 0..<10 {
                let recognizer = SpeechKit.SpeechRecognizer()
                XCTAssertNotNil(recognizer)
            }
        }
    }
    
    // MARK: - Text Insertion Performance Tests
    
    @MainActor
    func testTextInserterCreationPerformance() {
        // Test the performance of creating TextInserter
        measure {
            for _ in 0..<100 {
                let inserter = TextInsertionKit.TextInserter()
                XCTAssertNotNil(inserter)
            }
        }
    }
    
    @MainActor
    func testUniversalTextInserterCreationPerformance() {
        // Test the performance of creating UniversalTextInserter
        measure {
            for _ in 0..<100 {
                let inserter = TextInsertionKit.UniversalTextInserter()
                XCTAssertNotNil(inserter)
            }
        }
    }
    
    @MainActor
    func testContextualIndicatorCreationPerformance() {
        // Test the performance of creating ContextualIndicator
        measure {
            for _ in 0..<100 {
                let indicator = TextInsertionKit.ContextualIndicator()
                XCTAssertNotNil(indicator)
            }
        }
    }
    
    // MARK: - Hotkey Performance Tests
    
    @MainActor
    func testHotkeyManagerCreationPerformance() {
        // Test the performance of creating HotkeyManager
        measure {
            for _ in 0..<10 {
                let manager = HotkeyKit.HotkeyManager()
                XCTAssertNotNil(manager)
            }
        }
    }
    
    // MARK: - Data Processing Performance Tests
    
    @MainActor
    func testTranscriptionStoreDataProcessingPerformance() {
        setupDependencies()
        
        // Test the performance of adding many transcriptions
        measure {
            for i in 0..<100 {
                transcriptionStore.addTranscription(
                    text: "Test transcription \(i)",
                    confidence: 0.95,
                    duration: 1.0
                )
            }
        }
    }
    
    @MainActor
    func testLiveTranscriptionUpdatePerformance() {
        setupDependencies()
        
        // Test the performance of updating live transcription frequently
        measure {
            for i in 0..<1000 {
                transcriptionStore.updateLiveTranscription(
                    currentText: "Current text \(i)",
                    partialText: "Partial \(i)",
                    confidence: Double(i % 100) / 100.0
                )
            }
        }
    }
    
    // MARK: - Memory Usage Performance Tests
    
    @MainActor
    func testMemoryUsageUnderLoad() {
        // Test memory usage when creating many objects
        let memoryBefore = getMemoryUsage()
        
        measure {
            var objects: [Any] = []
            
            // Create many objects to test memory management
            for _ in 0..<100 {
                objects.append(TranscriptionStore())
                objects.append(HotkeySettings())
                objects.append(PermissionKit.PermissionManager())
                objects.append(SpeechKit.SpeechRecognizer())
                objects.append(TextInsertionKit.TextInserter())
            }
            
            // Use the objects to prevent optimization
            XCTAssertEqual(objects.count, 500)
            
            // Clear objects to test deallocation
            objects.removeAll()
        }
        
        let memoryAfter = getMemoryUsage()
        
        // Verify memory is reasonable (allowing for some variance in test environment)
        let memoryIncrease = memoryAfter - memoryBefore
        XCTAssertLessThan(memoryIncrease, 100_000_000, // 100MB limit
                         "Memory usage increased by \(memoryIncrease) bytes")
    }
    
    // MARK: - Reactive Performance Tests
    
    @MainActor
    func testReactiveStateUpdatesPerformance() {
        setupDependencies()
        
        // Test the performance of reactive state updates
        measure {
            for _ in 0..<100 {
                // Trigger state updates that should propagate through the reactive system
                permissionManager.refreshPermissionStates()
            }
        }
    }
    
    @MainActor
    func testCombinePublisherPerformance() {
        setupDependencies()
        
        var receivedUpdates = 0
        let expectation = XCTestExpectation(description: "Publisher performance")
        expectation.expectedFulfillmentCount = 100
        
        // Test Combine publisher performance
        transcriptionStore.$transcriptionHistory
            .sink { _ in
                receivedUpdates += 1
                expectation.fulfill()
            }
            .store(in: &cancellables)
        
        measure {
            for i in 0..<100 {
                transcriptionStore.addTranscription(
                    text: "Performance test \(i)",
                    confidence: 0.8,
                    duration: 0.5
                )
            }
        }
        
        wait(for: [expectation], timeout: 5.0)
        XCTAssertEqual(receivedUpdates, 100)
    }
    
    // MARK: - Concurrency Performance Tests
    
    @MainActor
    func testConcurrentObjectCreationPerformance() {
        // Test performance when creating objects concurrently
        measure {
            let group = DispatchGroup()
            let queue = DispatchQueue.global(qos: .userInitiated)
            
            for _ in 0..<10 {
                group.enter()
                queue.async {
                    // Create objects on background queue where possible
                    _ = SpeechKit.SpeechPermissionType.microphone
                    group.leave()
                }
            }
            
            group.wait()
        }
    }
    
    // MARK: - Helper Methods for Performance Testing
    
    private func getMemoryUsage() -> UInt64 {
        var info = mach_task_basic_info()
        var count = mach_msg_type_number_t(MemoryLayout<mach_task_basic_info>.size) / 4
        
        let result = withUnsafeMutablePointer(to: &info) {
            $0.withMemoryRebound(to: integer_t.self, capacity: 1) {
                task_info(mach_task_self_, task_flavor_t(MACH_TASK_BASIC_INFO), $0, &count)
            }
        }
        
        return result == KERN_SUCCESS ? info.resident_size : 0
    }
    
    // MARK: - Stress Testing
    
    @MainActor
    func testStressTestAppCoordinatorLifecycle() {
        // Stress test the complete app coordinator lifecycle
        measure {
            for _ in 0..<10 {
                let tempStatusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
                let tempStore = TranscriptionStore()
                let tempSettings = HotkeySettings()
                let tempPermissions = PermissionKit.PermissionManager()
                
                let coordinator = AppCoordinator(
                    statusItem: tempStatusItem,
                    transcriptionStore: tempStore,
                    hotkeySettings: tempSettings,
                    permissionManager: tempPermissions,
                    speechEngineManager: SpeechEngineManager(),
                    speechEngineSettings: SpeechEngineSettings()
                )
                
                coordinator.start()
                
                // Simulate some activity
                tempStore.addTranscription(
                    text: "Stress test transcription",
                    confidence: 0.9,
                    duration: 1.5
                )
                
                XCTAssertNotNil(coordinator)
            }
        }
    }
    
    // MARK: - Baseline Performance Tests
    
    func testBaselineObjectCreationPerformance() {
        // Baseline test for simple object creation
        measure {
            for _ in 0..<1000 {
                let _ = Date()
                let _ = UUID()
                let _ = NSObject()
            }
        }
    }
    
    func testBaselineArrayPerformance() {
        // Baseline test for array operations
        measure {
            var array: [String] = []
            for i in 0..<1000 {
                array.append("Item \(i)")
            }
            array.removeAll()
        }
    }
}