import Foundation
import SwiftSoup

/// Combines both URL-building and selector-providing capabilities into a single search engine type.
typealias SearchEngine = SearchEngineURL & SearchResultSelectors

/// A search engine that can provide a templated search URL.
protocol SearchEngineURL {
    /// The base search URL template with a `%@` placeholder for the query string.
    var baseURL: String { get }
}

/// A search engine that provides CSS selectors for parsing SERP results.
protocol SearchResultSelectors: Sendable {
    /// CSS selector for individual result containers on the SERP.
    var resultSelector: String { get }
    /// CSS selector for extracting the link from a result container.
    var linkSelector: String { get }
}

/// Google search engine implementation with Google-specific CSS selectors.
struct GoogleEngine: SearchEngineURL, SearchResultSelectors {
    let baseURL: String = "https://www.google.com/search?q=%@&hl=en"

    let resultSelector = "div.g"
    let linkSelector = "a"
}

/// Bing search engine implementation with Bing-specific CSS selectors.
struct BingEngine: SearchEngineURL, SearchResultSelectors {
    let baseURL: String = "https://www.bing.com/search?q=%@"

    let resultSelector = "li.b_algo"
    let linkSelector = "h2 a"
}
