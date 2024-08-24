import Foundation
import ArgumentParser
import SwiftSoup

enum SearchEngineType: String, ExpressibleByArgument {
    case google
    case bing

    init?(argument: String) {
        switch argument.lowercased() {
        case "bing":
            self = .bing
        default:
            self = .google
        }
    }
    
    var engine: SearchEngineURL & SearchResultParser {
        switch self {
        case .google:
            GoogleEngine()
        case .bing:
            BingEngine()
        }
    }
}

protocol SearchEngineURL {
    var searchURL: String { get }
    func createURL(keyword: String) -> Result<URL, HowtoError>
}

extension SearchEngineURL {
    func createURL(keyword: String) -> Result<URL, HowtoError> {
        guard let encodedKeyword = keyword.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) else {
            return .failure(.invalidURL)
        }
        let urlString = String(format: searchURL, encodedKeyword)
        guard let url = URL(string: urlString) else {
            return .failure(.invalidURL)
        }
        return .success(url)
    }
}

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

struct GoogleEngine: SearchEngineURL, SearchResultParser {
    let searchURL: String = "https://www.google.com/search?q=%@&hl=en"
    
    let resultSelector = "div.g"
    let titleSelector = "h3"
    let linkSelector = "a"
    let snippetSelector = "div.VwiC3b"
}

struct BingEngine: SearchEngineURL, SearchResultParser {
    let searchURL: String = "https://www.bing.com/search?q=%@"
    
    let resultSelector = "li.b_algo"
    let titleSelector = "h2"
    let linkSelector = "h2 a"
    let snippetSelector = "div.b_caption p"
}
