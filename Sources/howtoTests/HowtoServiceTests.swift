import XCTest
@testable import howto

class HowtoServiceTests: XCTestCase {
    
    var mockConfig: Config!
    var mockEngine: MockSearchEngine!
    var mockSession: MockURLSession!
    var mockURL: URL!
    var service: HowtoService!
    
    override func setUp() {
        super.setUp()
        mockEngine = MockSearchEngine()
        mockConfig = Config(engine: mockEngine, num: 5)
        mockSession = MockURLSession()
        mockURL = URL(string: "https://example.com")
        service = HowtoService(config: mockConfig, session: mockSession)
    }
    
    override func tearDown() {
        mockConfig = nil
        mockEngine = nil
        mockSession = nil
        service = nil
        super.tearDown()
    }
    
    func testCreateKeyword() {
        let query = ["swift", "testing"]
        let keyword = service.createKeyword(query: query)
        XCTAssertEqual(keyword, "site:stackoverflow.com swift testing")
    }
    
    func testSearchSuccess() async {
        let expectedHTML = "<html><body>Test</body></html>"
        mockSession.data = expectedHTML.data(using: .utf8)
        
        let result = await service.search(url: mockURL)
        
        switch result {
        case .success(let html):
            XCTAssertEqual(html, expectedHTML)
        case .failure:
            XCTFail("Search should not fail")
        }
    }
    
    func testSearchNoData() async {
        mockSession.data = nil
        
        let result = await service.search(url: mockURL)
        
        switch result {
        case .success:
            XCTFail("Search should fail with no data")
        case .failure(let error):
            XCTAssertEqual(error.localizedDescription, HowtoError.noData.localizedDescription)
        }
    }
    
    func testSearchNetworkError() async {
        struct TestError: Error {}
        mockSession.error = TestError()
        
        let result = await service.search(url: mockURL)
        
        switch result {
        case .success:
            XCTFail("Search should fail with network error")
        case .failure(let error):
            if case .networkError = error {
                // Success
            } else {
                XCTFail("Incorrect error type")
            }
        }
    }
    
    func testPerformSearchSuccess() async {
            // Setup
            let query = ["swift", "testing"]
            let mockURL = URL(string: "https://example.com")!
            let mockHTML = "<html><body>Test</body></html>"
            let mockSearchResult = SearchResult(title: "Test", link: "https://example.com", snippet: "This is a test")
            
            mockEngine.mockURLResult = .success(mockURL)
            mockSession.data = mockHTML.data(using: .utf8)
            mockEngine.mockParseResult = .success([mockSearchResult])
            
            // Perform search
            let result = await service.performSearch(query: query)
            
            // Assert
            switch result {
            case .success(let searchResults):
                XCTAssertEqual(searchResults.count, 1)
                XCTAssertEqual(searchResults[0].title, "Test")
                XCTAssertEqual(searchResults[0].link, "https://example.com")
                XCTAssertEqual(searchResults[0].snippet, "This is a test")
            case .failure:
                XCTFail("performSearch should not fail")
            }
        }
        
        func testPerformSearchURLCreationFailure() async {
            // Setup
            let query = ["swift", "testing"]
            mockEngine.mockURLResult = .failure(.invalidURL)
            
            // Perform search
            let result = await service.performSearch(query: query)
            
            // Assert
            switch result {
            case .success:
                XCTFail("performSearch should fail with invalid URL")
            case .failure(let error):
                XCTAssertEqual(error.localizedDescription, HowtoError.invalidURL.localizedDescription)
            }
        }
        
        func testPerformSearchNetworkFailure() async {
            // Setup
            let query = ["swift", "testing"]
            let mockURL = URL(string: "https://example.com")!
            mockEngine.mockURLResult = .success(mockURL)
            mockSession.error = NSError(domain: "test", code: 0, userInfo: nil)
            
            // Perform search
            let result = await service.performSearch(query: query)
            
            // Assert
            switch result {
            case .success:
                XCTFail("performSearch should fail with network error")
            case .failure(let error):
                if case .networkError = error {
                    // Success
                } else {
                    XCTFail("Incorrect error type")
                }
            }
        }
        
        func testPerformSearchParsingFailure() async {
            // Setup
            let query = ["swift", "testing"]
            let mockURL = URL(string: "https://example.com")!
            let mockHTML = "<html><body>Test</body></html>"
            
            mockEngine.mockURLResult = .success(mockURL)
            mockSession.data = mockHTML.data(using: .utf8)
            mockEngine.mockParseResult = .failure(.parsingError(NSError(domain: "test", code: 0, userInfo: nil)))
            
            // Perform search
            let result = await service.performSearch(query: query)
            
            // Assert
            switch result {
            case .success:
                XCTFail("performSearch should fail with parsing error")
            case .failure(let error):
                if case .parsingError = error {
                    // Success
                } else {
                    XCTFail("Incorrect error type")
                }
            }
        }
}

class MockSearchEngine: SearchEngineURL, SearchResultParser {
    var searchURL: String = "https://test.com/search?q=%@"
    var resultSelector: String = ""
    var titleSelector: String = ""
    var linkSelector: String = ""
    var snippetSelector: String = ""
    
    var mockURLResult: Result<URL, HowtoError>!
    var mockParseResult: Result<[SearchResult], HowtoError>!
    
    func createURL(keyword: String) -> Result<URL, HowtoError> {
        return mockURLResult
    }
    
    func parse(htmlString: String) -> Result<[SearchResult], HowtoError> {
        return mockParseResult
    }
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
