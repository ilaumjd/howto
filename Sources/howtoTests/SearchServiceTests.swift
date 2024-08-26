import XCTest

@testable import howto

class SearchServiceTests: XCTestCase {

  var mockContext: SearchContext!
  var mockWebService: MockWebFetchService!
  var service: SearchService!

  override func setUp() {
    super.setUp()
    mockWebService = MockWebFetchService()
    let mockConfig = Config(engine: MockSearchEngine(), num: 1, useBat: false)
    mockContext = SearchContext(config: mockConfig, query: ["swift", "testing"])
    service = SearchService(context: mockContext, webService: mockWebService)
  }

  override func tearDown() {
    mockContext = nil
    mockWebService = nil
    service = nil
    super.tearDown()
  }
  func testCreateKeywordAndSearchURL() {
    let query = ["swift", "testing"]
    let keyword = service.createKeyword(query: query)
    let urlString = service.createSearchURL(keyword: keyword)
    XCTAssertEqual(keyword, "site:stackoverflow.com swift testing")
    XCTAssertEqual(urlString, "https://test.com/search?q=site:stackoverflow.com swift testing")
  }

  func testPerformSearchSuccess() async {
    let mockHTML = "<html><body>Test</body></html>"
    mockWebService.htmlResult = .success(mockHTML)

    do {
      let htmlString = try await service.performSearch()
      XCTAssertEqual(htmlString, "<html><body>Test</body></html>")
    } catch {
      XCTFail("performSearch should not fail")
    }
  }

  func testPerformSearchFailureInvalidURL() async {
    mockWebService.htmlResult = .failure(.invalidURL)
    do {
      _ = try await service.performSearch()
      XCTFail("performSearch should fail with invalid URL error")
    } catch {
      XCTAssertEqual(error.localizedDescription, WebFetchError.invalidURL.localizedDescription)
    }
  }

  func testPerformSearchFailureNoData() async {
    mockWebService.htmlResult = .failure(.noData)
    do {
      _ = try await service.performSearch()
      XCTFail("performSearch should fail with no data error")
    } catch {
      XCTAssertEqual(error.localizedDescription, WebFetchError.noData.localizedDescription)
    }
  }
}

// Mock classes for testing

class MockSearchEngine: SearchEngine {
  var baseURL: String = "https://test.com/search?q=%@"
  var resultSelector: String = ""
  var titleSelector: String = ""
  var linkSelector: String = ""
  var snippetSelector: String = ""
}

class MockWebFetchService: WebFetchServiceProtocol {
  var htmlResult: Result<String, WebFetchError>!

  func fetchHtmlPage(urlString: String) async throws -> String {
    switch htmlResult {
    case .success(let html):
      return html
    case .failure(let error):
      throw error
    case .none:
      throw WebFetchError.noData
    }
  }
}
