import Foundation
import SwiftSoup

/// Abstraction for parsing search results and StackOverflow answer pages.
protocol ParserServiceProtocol {
    /// Extracts a list of result URLs from a search-engine results page HTML.
    func parseSearchResultLinks(htmlString: String) throws -> [String]
    /// Parses a StackOverflow answer page HTML into an `Answer` model.
    func parseStackOverflowAnswer(url: String, htmlString: String) throws -> Answer
    /// Creates a parser service with the given configuration.
    init(config: Config)
}

/// Backward-compatible wrapper that delegates to SearchResultParser and AnswerParser.
struct ParserService: ParserServiceProtocol {
    /// The resolved application configuration.
    let config: Config
    /// The dedicated search-result parser instance.
    let searchResultParser: SearchResultParser
    /// The dedicated answer-page parser instance.
    let answerParser: AnswerParser

    init(config: Config) {
        self.config = config
        self.searchResultParser = SearchResultParser(engine: config.engine)
        self.answerParser = AnswerParser()
    }

    func parseSearchResultLinks(htmlString: String) throws -> [String] {
        try searchResultParser.parse(htmlString: htmlString)
    }

    func parseStackOverflowAnswer(url: String, htmlString: String) throws -> Answer {
        try answerParser.parse(url: url, htmlString: htmlString)
    }
}
