import Foundation
import SwiftSoup

typealias SearchEngine = SearchEngineURL & SearchResultParser

protocol SearchEngineURL {
    var baseURL: String { get }
}

protocol SearchResultParser {
    var resultSelector: String { get }
    var linkSelector: String { get }
}

struct GoogleEngine: SearchEngineURL, SearchResultParser {
    let baseURL: String = "https://www.google.com/search?q=%@&hl=en"

    let resultSelector = "div.g"
    let linkSelector = "a"
}

struct BingEngine: SearchEngineURL, SearchResultParser {
    let baseURL: String = "https://www.bing.com/search?q=%@"

    let resultSelector = "li.b_algo"
    let linkSelector = "h2 a"
}
