import XCTest
@testable import howto

class SearchServiceTests: XCTestCase {
    
    var mockConfig: Config!
    var mockEngine: MockSearchEngine!
    var mockSession: MockURLSession!
    var mockURL: URL!
    var service: SearchService!
    
    override func setUp() {
        super.setUp()
        mockEngine = MockSearchEngine()
        mockConfig = Config(engine: mockEngine, num: 5)
        mockSession = MockURLSession()
        mockURL = URL(string: "https://example.com")
        service = SearchService(config: mockConfig, session: mockSession)
    }
    
    override func tearDown() {
        mockConfig = nil
        mockEngine = nil
        mockSession = nil
        mockURL = nil
        service = nil
        super.tearDown()
    }
    
    func testCreateKeyword() {
        let query = ["swift", "testing"]
        let keyword = service.createKeyword(query: query)
        XCTAssertEqual(keyword, "site:stackoverflow.com swift testing")
    }
    
    func testCreateURLSuccess() {
        let keyword = "swift testing"
        
        let result = service.createURL(keyword: keyword)
        
        switch result {
        case .success(let url):
            XCTAssertEqual("https://test.com/search?q=swift%20testing", url.absoluteString)
        case .failure:
            XCTFail("Create url should not fail")
        }
    }
    
    func testFetchHtmlPageSuccess() async {
        let expectedHTML = "<html><body>Test</body></html>"
        mockSession.data = expectedHTML.data(using: .utf8)
        
        let result = await service.fetchHtmlPage(url: mockURL)
        
        switch result {
        case .success(let html):
            XCTAssertEqual(html, expectedHTML)
        case .failure:
            XCTFail("FetchHtmlPage should not fail")
        }
    }
    
    func testFetchHtmlPageNoData() async {
        mockSession.data = nil
        
        let result = await service.fetchHtmlPage(url: mockURL)
        
        switch result {
        case .success:
            XCTFail("FetchHtmlPage should fail with no data")
        case .failure(let error):
            XCTAssertEqual(error.localizedDescription, HowtoError.noData.localizedDescription)
        }
    }
    
    func testFetchHtmlPageNetworkError() async {
        struct TestError: Error {}
        mockSession.error = TestError()
        
        let result = await service.fetchHtmlPage(url: mockURL)
        
        switch result {
        case .success:
            XCTFail("FetchHtmlPage should fail with network error")
        case .failure(let error):
            if case .networkError = error {
                XCTAssertEqual(error.localizedDescription, HowtoError.networkError(mockSession.error!).localizedDescription)
            } else {
                XCTFail("Incorrect error type")
            }
        }
    }
    
    func testPerformSearchSuccess() async {
            let query = ["swift", "testing"]
            let mockHTML = "<html><body>Test</body></html>"
            
            mockEngine.mockURLResult = .success(mockURL)
            mockSession.data = mockHTML.data(using: .utf8)
            
            let result = await service.performSearch(query: query)
            
            switch result {
            case .success(let htmlString):
                XCTAssertEqual(htmlString, "<html><body>Test</body></html>")
            case .failure:
                XCTFail("performSearch should not fail")
            }
        }
        
}

class MockSearchEngine: SearchEngine {
    var baseURL: String = "https://test.com/search?q=%@"
    var resultSelector: String = ""
    var titleSelector: String = ""
    var linkSelector: String = ""
    var snippetSelector: String = ""
    
    var mockURLResult: Result<URL, HowtoError>!
}

class MockURLSession: URLSessionProtocol {
    var data: Data?
    var error: Error?
    
    func data(for request: URLRequest) async throws -> (Data, URLResponse) {
        if let error = error {
            throw error
        }
        return (data ?? Data(), URLResponse())
    }
}
