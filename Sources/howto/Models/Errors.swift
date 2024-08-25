import Foundation

enum ConfigError: Error {
    case invalidSearchEngine
    case invalidNumber
}

enum BatServiceError: Error {
    case batNotFound
    case batLanguagesFileCreationFailed(Error)
    case batLanguagesFileReadFailed(Error)
    case languageNotFound
    case processError(ProcessError)
}

enum ParserError: Error {
    case noResults
    case noAnswer
    case noAnswerBody
    case parsingError(Error)
}

enum ProcessError: Error {
    case executionFailed(Error)
    case outputParsingFailed
}

enum SearchError: Error {
    case invalidURL
    case noData
    case networkError(Error)
}

