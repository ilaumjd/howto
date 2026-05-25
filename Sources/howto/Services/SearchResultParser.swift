import Foundation
import SwiftSoup

/// Parses Search Engine Results Page (SERP) HTML to extract result links using
/// engine-specific CSS selectors.
struct SearchResultParser {
    /// The search engine whose selectors will be used to find result links.
    let engine: any SearchResultSelectors

    init(engine: any SearchResultSelectors) {
        self.engine = engine
    }

    /// Extracts all result URLs from the given SERP HTML string.
    /// - Parameter htmlString: The raw HTML of the search results page.
    /// - Returns: An array of URL strings extracted from the search results.
    /// - Throws: `ParserError.noResults` if no links are found, or `ParserError.parsingError` on SwiftSoup failures.
    func parse(htmlString: String) throws -> [String] {
        do {
            let doc: Document = try SwiftSoup.parse(htmlString)
            let results: Elements = try doc.select(engine.resultSelector)

            let links = results.array().compactMap { result -> String? in
                guard let link = try? result.select(engine.linkSelector).first()?.attr("href") else {
                    return nil
                }
                return link
            }

            guard !links.isEmpty else {
                throw ParserError.noResults
            }

            return links
        } catch let error as ParserError {
            throw error
        } catch {
            throw ParserError.parsingError(error)
        }
    }
}
