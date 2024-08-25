import Foundation
import SwiftSoup

typealias SearchEngine = SearchEngineURL & SearchResultParser

protocol SearchEngineURL {
    var baseURL: String { get }
}

protocol SearchResultParser {
    var resultSelector: String { get }
    var titleSelector: String { get }
    var linkSelector: String { get }
    var snippetSelector: String { get }
}

enum SearchParserError: Error {
    case noResults
    case parsingError(Error)
}

struct GoogleEngine: SearchEngineURL, SearchResultParser {
    let baseURL: String = "https://www.google.com/search?q=%@&hl=en"
    
    let resultSelector = "div.g"
    let titleSelector = "h3"
    let linkSelector = "a"
    let snippetSelector = "div.VwiC3b"
}

struct BingEngine: SearchEngineURL, SearchResultParser {
    let baseURL: String = "https://www.bing.com/search?q=%@"
    
    let resultSelector = "li.b_algo"
    let titleSelector = "h2"
    let linkSelector = "h2 a"
    let snippetSelector = "div.b_caption p"
}
