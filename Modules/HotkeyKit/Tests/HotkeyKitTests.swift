import XCTest
@testable import HotkeyKit

final class HotkeyKitTests: XCTestCase {
    
    // MARK: - KeyCodeMapping Tests
    
    func testKeyCodeMappingDisplayNames() {
        XCTAssertEqual(KeyCodeMapping.displayName(for: KeyCodeMapping.functionKey), "fn")
        XCTAssertEqual(KeyCodeMapping.displayName(for: KeyCodeMapping.leftCommand), "⌘")
        XCTAssertEqual(KeyCodeMapping.displayName(for: KeyCodeMapping.leftOption), "⌥")
        XCTAssertEqual(KeyCodeMapping.displayName(for: KeyCodeMapping.space), "Space")
        XCTAssertEqual(KeyCodeMapping.displayName(for: KeyCodeMapping.leftControl), "⌃")
        XCTAssertEqual(KeyCodeMapping.displayName(for: KeyCodeMapping.leftShift), "⇧")
    }
    
    func testModifierKeyDetection() {
        // Test modifier keys
        XCTAssertTrue(KeyCodeMapping.isModifierKey(KeyCodeMapping.functionKey))
        XCTAssertTrue(KeyCodeMapping.isModifierKey(KeyCodeMapping.leftCommand))
        XCTAssertTrue(KeyCodeMapping.isModifierKey(KeyCodeMapping.leftOption))
        XCTAssertTrue(KeyCodeMapping.isModifierKey(KeyCodeMapping.leftControl))
        XCTAssertTrue(KeyCodeMapping.isModifierKey(KeyCodeMapping.leftShift))
        
        // Test non-modifier keys
        XCTAssertFalse(KeyCodeMapping.isModifierKey(KeyCodeMapping.space))
        XCTAssertFalse(KeyCodeMapping.isModifierKey(KeyCodeMapping.enter))
        XCTAssertFalse(KeyCodeMapping.isModifierKey(KeyCodeMapping.escape))
    }
}