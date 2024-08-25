import Foundation

enum ConfigError: Error {
    case invalidSearchEngine
    case invalidNumber
}

enum HowtoError: Error {
    case invalidURL
    case networkError(Error)
    case noData
    case parsingError(Error)
    case noAnswer
}

enum ProcessError: Error {
    case runError(Error)
    case batLanguagesError(Error)
}

struct SearchResult {
    let title: String
    let link: String
    let snippet: String
}
