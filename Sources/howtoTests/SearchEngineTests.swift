import XCTest
@testable import howto
import SwiftSoup

class SearchEngineTests: XCTestCase {
    
    func testGoogleEngineParsing() throws {
        let engine = GoogleEngine()
        let htmlString = """
        <div class="g">
            <h3><a href="https://example.com">Example Title</a></h3>
            <div class="VwiC3b">Example Snippet</div>
        </div>
        """
        
        let result = engine.parse(htmlString: htmlString)
        
        switch result {
        case .success(let searchResults):
            XCTAssertEqual(searchResults.count, 1)
            XCTAssertEqual(searchResults[0].title, "Example Title")
            XCTAssertEqual(searchResults[0].link, "https://example.com")
            XCTAssertEqual(searchResults[0].snippet, "Example Snippet")
        case .failure:
            XCTFail("Parsing should not fail")
        }
    }
    
    func testBingEngineParsing() throws {
        let engine = BingEngine()
        let htmlString = """
        <li class="b_algo">
            <h2><a href="https://example.com">Example Title</a></h2>
            <div class="b_caption"><p>Example Snippet</p></div>
        </li>
        """
        
        let result = engine.parse(htmlString: htmlString)
        
        switch result {
        case .success(let searchResults):
            XCTAssertEqual(searchResults.count, 1)
            XCTAssertEqual(searchResults[0].title, "Example Title")
            XCTAssertEqual(searchResults[0].link, "https://example.com")
            XCTAssertEqual(searchResults[0].snippet, "Example Snippet")
        case .failure:
            XCTFail("Parsing should not fail")
        }
    }
    
    func testParsingWithNoResults() throws {
        let engine = GoogleEngine()
        let htmlString = "<div></div>"
        
        let result = engine.parse(htmlString: htmlString)
        
        switch result {
        case .success:
            XCTFail("Parsing should fail with no data")
        case .failure(let error):
            XCTAssertEqual(error.localizedDescription, HowtoError.noData.localizedDescription)
        }
    }
    
}
