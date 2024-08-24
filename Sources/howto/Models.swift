import Foundation

struct Config {
    let site = "stackoverflow.com"
    let userAgent = "Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.114 Safari/537.36"

    let engine: SearchEngineURL & SearchResultParser
    let num: Int
}

enum HowtoError: Error {
    case invalidURL
    case networkError(Error)
    case noData
    case parsingError(Error)
}

struct SearchResult {
    let title: String
    let link: String
    let snippet: String
}
