import SwiftSoup
import XCTest

@testable import howto

class ParserServiceTests: XCTestCase {

  var parserService: ParserService!

  override func setUp() {
    super.setUp()
    let config = Config(engine: GoogleEngine(), num: 5, useBat: false)
    parserService = ParserService(config: config)
  }

  func testGoogleEngineParsingLinks() throws {
    let htmlString = """
      <div class="g">
          <h3><a href="https://example.com">Example Title</a></h3>
          <div class="VwiC3b">Example Snippet</div>
      </div>
      """

    let links = try parserService.parseSearchResultLinks(htmlString: htmlString)

    XCTAssertEqual(links.count, 1)
    XCTAssertEqual(links[0], "https://example.com")
  }

  func testBingEngineParsingLinks() throws {
    let bingConfig = Config(engine: BingEngine(), num: 5, useBat: false)
    parserService = ParserService(config: bingConfig)

    let htmlString = """
      <li class="b_algo">
          <h2><a href="https://example.com">Example Title</a></h2>
          <div class="b_caption"><p>Example Snippet</p></div>
      </li>
      """

    let links = try parserService.parseSearchResultLinks(htmlString: htmlString)

    XCTAssertEqual(links.count, 1)
    XCTAssertEqual(links[0], "https://example.com")
  }

  func testParsingWithNoResults() throws {
    let htmlString = "<div></div>"

    XCTAssertThrowsError(try parserService.parseSearchResultLinks(htmlString: htmlString)) {
      error in
      XCTAssertEqual(error.localizedDescription, ParserError.noResults.localizedDescription)
    }
  }

  func testParseStackOverflowAnswer() throws {
    let htmlString = """
      <h1 itemprop="name"><a class="question-hyperlink">Example Question</a></h1>
      <span class="post-tag">swift</span>
      <span class="post-tag">parsing</span>
      <div class="answer accepted-answer">
          <div class="js-vote-count">42</div>
          <div class="js-post-body">
              <p>Here's an example:</p>
              <pre><code>print("Hello, World!")</code></pre>
          </div>
      </div>
      """

    let answer = try parserService.parseStackOverflowAnswer(
      url: "https://example.com", htmlString: htmlString)

    XCTAssertEqual(answer.url, "https://example.com")
    XCTAssertEqual(answer.questionTitle, "Example Question")
    XCTAssertEqual(answer.tags, ["swift", "parsing"])
    XCTAssertTrue(answer.accepted)
    XCTAssertEqual(answer.voteCount, 42)
    XCTAssertEqual(answer.codeSnippets, ["print(\"Hello, World!\")"])
    XCTAssertTrue(answer.fullAnswer.contains("Here's an example:"))
  }

  func testParseStackOverflowAnswerNoAnswer() throws {
    let htmlString = "<div></div>"

    XCTAssertThrowsError(
      try parserService.parseStackOverflowAnswer(url: "https://example.com", htmlString: htmlString)
    ) { error in
      XCTAssertEqual(error.localizedDescription, ParserError.noAnswer.localizedDescription)
    }
  }
}
