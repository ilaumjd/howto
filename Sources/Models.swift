import Foundation
import ArgumentParser

enum SearchEngine: String, ExpressibleByArgument {
    case google
    case bing

    init?(argument: String) {
        switch argument.lowercased() {
        case "google":
            self = .google
        case "bing":
            self = .bing
        default:
            return nil
        }
    }
}

struct Config {
    let engine: SearchEngine
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
