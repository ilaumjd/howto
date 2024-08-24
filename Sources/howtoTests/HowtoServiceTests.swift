import XCTest
@testable import howto

class HowtoServiceTests: XCTestCase {

    var service: HowtoService!
    var mockConfig: Config!
    var mockEngine: MockSearchEngine!

    override func setUp() {
        super.setUp()
        mockEngine = MockSearchEngine()
        mockConfig = Config(engine: mockEngine, num: 5)
        service = HowtoService(config: mockConfig)
    }

    override func tearDown() {
        service = nil
        mockConfig = nil
        mockEngine = nil
        super.tearDown()
    }

    func testCreateKeyword() {
        let query = ["swift", "testing"]
        let keyword = service.createKeyword(query: query)
        XCTAssertEqual(keyword, "site:stackoverflow.com swift testing")
    }
}

// Mock implementation of SearchEngineURL & SearchResultParser for testing
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
