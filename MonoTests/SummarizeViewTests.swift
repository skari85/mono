import XCTest
@testable import Mono

final class SummarizeViewTests: XCTestCase {
    func testAutoSummarizeDefaultOff() {
        UserDefaults.standard.removeObject(forKey: "auto_summarize_after_recording")
        XCTAssertFalse(UserDefaults.standard.bool(forKey: "auto_summarize_after_recording"))
    }
}

