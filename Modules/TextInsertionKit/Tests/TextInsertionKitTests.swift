import XCTest
@testable import TextInsertionKit

final class TextInsertionKitTests: XCTestCase {
    
    func testTextInserterInitialization() {
        let inserter = TextInserter()
        XCTAssertNotNil(inserter)
    }
    
    @MainActor
    func testContextualIndicatorInitialization() {
        let indicator = ContextualIndicator()
        XCTAssertNotNil(indicator)
    }
}