import Foundation
import SwiftSoup

protocol SearchResultParser {
    var resultSelector: String { get }
    var titleSelector: String { get }
    var linkSelector: String { get }
    var snippetSelector: String { get }

    func parse(htmlString: String) -> Result<[SearchResult], HowtoError>
}

extension SearchResultParser {
    func parse(htmlString: String) -> Result<[SearchResult], HowtoError> {
        do {
            let doc: Document = try SwiftSoup.parse(htmlString)
            let results: Elements = try doc.select(resultSelector)
            
            let searchResults = results.array().compactMap { result -> SearchResult? in
                guard let title = try? result.select(titleSelector).first()?.text(),
                      let link = try? result.select(linkSelector).first()?.attr("href"),
                      let snippet = try? result.select(snippetSelector).first()?.text()
                else {
                    return nil
                }
                
                return SearchResult(title: title, link: link, snippet: snippet)
            }
            
            return .success(searchResults)
        } catch {
            return .failure(.parsingError(error))
        }
    }
}

struct GoogleParser: SearchResultParser {
    let resultSelector = "div.g"
    let titleSelector = "h3"
    let linkSelector = "a"
    let snippetSelector = "div.VwiC3b"
}

struct BingParser: SearchResultParser {
    let resultSelector = "li.b_algo"
    let titleSelector = "h2"
    let linkSelector = "h2 a"
    let snippetSelector = "div.b_caption p"
}
