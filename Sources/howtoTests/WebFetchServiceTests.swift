import XCTest

@testable import howto

class WebFetchServiceTests: XCTestCase {
    var mockSession: MockURLSession!
    var service: WebFetchService!

    override func setUp() {
        super.setUp()
        mockSession = MockURLSession()
        service = WebFetchService(session: mockSession)
    }

    override func tearDown() {
        mockSession = nil
        service = nil
        super.tearDown()
    }

    func testFetchHtmlPageSuccess() async {
        let expectedHTML = "<html><body>Test</body></html>"
        mockSession.data = expectedHTML.data(using: .utf8)

        do {
            let html = try await service.fetchHtmlPage(urlString: "https://test.com")
            XCTAssertEqual(html, expectedHTML)
        } catch {
            XCTFail("fetchHtmlPage should not fail")
        }
    }

    func testFetchHtmlPageNoData() async {
        mockSession.data = nil

        do {
            _ = try await service.fetchHtmlPage(urlString: "https://test.com")
            XCTFail("fetchHtmlPage should fail with no data")
        } catch {
            XCTAssertEqual(error.localizedDescription, WebFetchError.noData.localizedDescription)
        }
    }

    func testFetchHtmlPageNetworkError() async {
        struct TestError: Error {}
        mockSession.error = TestError()

        do {
            _ = try await service.fetchHtmlPage(urlString: "https://test.com")
            XCTFail("fetchHtmlPage should fail with network error")
        } catch {
            XCTAssertEqual(
                error.localizedDescription,
                WebFetchError.networkError(mockSession.error!).localizedDescription
            )
        }
    }
}

// Mock classes for testing

class MockURLSession: URLSessionProtocol {
    var data: Data?
    var error: Error?

    func data(for _: URLRequest) async throws -> (Data, URLResponse) {
        if let error = error {
            throw error
        }
        return (data ?? Data(), URLResponse())
    }
}
