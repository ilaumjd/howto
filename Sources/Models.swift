import Foundation

struct Config {
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
