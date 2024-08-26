import Foundation

enum ConfigError: Error {
    case invalidSearchEngine
    case invalidNumber
}

enum WebFetchError: Error {
    case invalidURL
    case noData
    case networkError(Error)
}

enum ParserError: Error {
    case noResults
    case noAnswer
    case noAnswerBody
    case parsingError(Error)
}

enum BatServiceError: Error {
    case batNotFound
    case batLanguagesFileCreationFailed(Error)
    case batLanguagesFileReadFailed(Error)
    case languageNotFound
    case processError(ProcessError)
}

enum ProcessError: Error {
    case executionFailed(Error)
    case outputParsingFailed
}
