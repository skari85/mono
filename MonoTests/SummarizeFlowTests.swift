import XCTest
@testable import Mono

final class SummarizeFlowTests: XCTestCase {
    func testSummarizeSendToChatAddsMessage() throws {
        let dm = DataManager.shared
        let initialCount = dm.chatMessages.count

        let exp = expectation(description: "message added")
        let token = NotificationCenter.default.addObserver(forName: .summarizeSendToChat, object: nil, queue: .main) { note in
            if let text = note.object as? String {
                let aiMessage = ChatMessage(text: text, isUser: false)
                dm.addChatMessage(aiMessage)
                exp.fulfill()
            }
        }
        defer { NotificationCenter.default.removeObserver(token) }

        NotificationCenter.default.post(name: .summarizeSendToChat, object: "Test summary")
        waitForExpectations(timeout: 1.0)

        XCTAssertEqual(dm.chatMessages.count, initialCount + 1)
        XCTAssertEqual(dm.chatMessages.last?.text, "Test summary")
        XCTAssertEqual(dm.chatMessages.last?.isUser, false)
    }
}

