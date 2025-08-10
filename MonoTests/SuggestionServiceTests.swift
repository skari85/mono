import XCTest
@testable import Mono

final class SuggestionServiceTests: XCTestCase {

    override func setUp() {
        super.setUp()
        UserDefaults.standard.set("test_key", forKey: "groq_api_key")
    }

    func testSuggestParsesMockResponse() async throws {
        // Arrange a URLSession with custom protocol
        let config = URLSessionConfiguration.ephemeral
        config.protocolClasses = [MockURLProtocol.self]
        let session = URLSession(configuration: config)

        // Stubbed JSON matching Groq schema
        let json = """
        {"choices": [{"message": {"content": "Here are top picks"}}]}
        """.data(using: .utf8)!
        MockURLProtocol.requestHandler = { request in
            // Verify headers and method
            XCTAssertEqual(request.httpMethod, "POST")
            XCTAssertEqual(request.value(forHTTPHeaderField: "Content-Type"), "application/json")
            XCTAssertNotNil(request.value(forHTTPHeaderField: "Authorization"))
            let response = HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: nil, headerFields: nil)!
            return (response, json)
        }

        // Act
        let svc = SuggestionService(session: session)
        let result = try await svc.suggest(query: "beaches", topN: 5)

        // Assert
        XCTAssertEqual(result, "Here are top picks")
    }
}

// Simple URLProtocol mock to intercept requests
final class MockURLProtocol: URLProtocol {
    static var requestHandler: ((URLRequest) throws -> (HTTPURLResponse, Data))?

    override class func canInit(with request: URLRequest) -> Bool { true }
    override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }

    override func startLoading() {
        guard let handler = Self.requestHandler else {
            client?.urlProtocol(self, didFailWithError: NSError(domain: "Mock", code: 0))
            return
        }
        do {
            let (response, data) = try handler(request)
            client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
            client?.urlProtocol(self, didLoad: data)
            client?.urlProtocolDidFinishLoading(self)
        } catch {
            client?.urlProtocol(self, didFailWithError: error)
        }
    }

    override func stopLoading() {}
}

