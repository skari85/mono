import XCTest
@testable import Mono

final class StructuredSummaryTests: XCTestCase {
    func testToMarkdown() {
        let s = StructuredSummary(tags: ["idea","urgent"], keyPoints: ["Alpha","Beta"], actionItems: ["Do X","Ship Y"], keyInsights: ["Z matters"]) 
        let md = s.toMarkdown()
        XCTAssertTrue(md.contains("## Action Items"))
        XCTAssertTrue(md.contains("- Do X"))
        XCTAssertTrue(md.contains("Tags:"))
    }

    func testSummarizeStructuredParsesJSON() async throws {
        UserDefaults.standard.set("test_key", forKey: "groq_api_key")
        // Inject a mock URLSession into SummarizationService isn't set up; instead, emulate decode path directly
        let json = "{" +
        "\"key_points\":[\"A\",\"B\"]," +
        "\"action_items\":[\"Do\"]," +
        "\"key_insights\":[\"Note\"]," +
        "\"tags\":[\"idea\"]" +
        "}"
        let data = json.data(using: .utf8)!
        let decoded = try JSONDecoder().decode(StructuredSummary.self, from: data)
        XCTAssertEqual(decoded.tags.first, "idea")
        XCTAssertEqual(decoded.keyPoints.count, 2)
    }
}

