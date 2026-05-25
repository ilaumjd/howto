import Foundation

// MARK: - FileHandle TextOutputStream conformance for stderr support

/// Allows `FileHandle.standardError` to be used as a `TextOutputStream`
/// so that `print(..., to: &stdErr)` writes to stderr.
extension FileHandle: @retroactive TextOutputStream {
    public func write(_ string: String) {
        guard let data = string.data(using: .utf8) else { return }
        write(data)
    }
}

/// Global stderr stream for use with `print(..., to: &stdErr)`
nonisolated(unsafe) var stdErr = FileHandle.standardError

// MARK: - Existing error types

/// Errors that can occur during configuration validation.
enum ConfigError: Error {
    /// The user specified an engine name other than "google" or "bing".
    case invalidSearchEngine
    /// The number of answers requested is zero or negative.
    case invalidNumber
}

/// Errors that can occur when fetching web pages.
enum WebFetchError: Error {
    /// The provided URL string could not be parsed as a valid URL.
    case invalidURL
    /// The HTTP response contained no usable data.
    case noData
    /// A network-level error occurred (e.g. timeout, connection refused).
    case networkError(Error)
}

/// Errors that can occur when parsing HTML content.
enum ParserError: Error {
    /// No search result links were found in the SERP HTML.
    case noResults
    /// No answer block could be identified on the page.
    case noAnswer
    /// The answer body element was missing from the parsed document.
    case noAnswerBody
    /// A SwiftSoup parsing error occurred.
    case parsingError(Error)
}

/// Errors that can occur when invoking the `bat` syntax-highlighting tool.
enum BatServiceError: Error {
    /// The `bat` executable could not be found on the system PATH.
    case batNotFound
    /// Failed to create the bat languages mapping file.
    case batLanguagesFileCreationFailed(Error)
    /// Failed to read the bat languages mapping file.
    case batLanguagesFileReadFailed(Error)
    /// Could not determine a suitable language for bat highlighting.
    case languageNotFound
    /// An underlying process error occurred while running bat.
    case processError(ProcessError)
}

/// Errors that can occur when running external processes.
enum ProcessError: Error {
    /// The process failed to execute.
    case executionFailed(Error)
    /// The process output could not be parsed.
    case outputParsingFailed
}

// MARK: - Unified HowtoError with user-friendly messages

/// Unified error type that wraps all domain-specific errors with user-friendly messages.
enum HowtoError: Error {
    /// A configuration error.
    case config(ConfigError)
    /// A web-fetching error, annotated with the URL or context string.
    case webFetch(WebFetchError, context: String)
    /// A parsing error.
    case parser(ParserError)
    /// A bat syntax-highlighting error.
    case bat(BatServiceError)
    /// A process execution error.
    case process(ProcessError)
    /// An uncategorized error with a custom message.
    case other(String)

    /// Human-readable error message for end-user display.
    var message: String {
        switch self {
        case .config(let error):
            switch error {
            case .invalidSearchEngine:
                return "Invalid search engine specified. Use \"google\" or \"bing\"."
            case .invalidNumber:
                return "Number of answers must be greater than 0."
            }

        case .webFetch(let error, let context):
            switch error {
            case .invalidURL:
                return "Invalid URL: \(context)"
            case .noData:
                return "No data received from \(context)."
            case .networkError(let underlying):
                return "Network error fetching \(context): \(underlying.localizedDescription)"
            }

        case .parser(let error):
            switch error {
            case .noResults:
                return "No search results found."
            case .noAnswer:
                return "No answer could be parsed from the page."
            case .noAnswerBody:
                return "No answer body found on the page."
            case .parsingError(let underlying):
                return "Parsing error: \(underlying.localizedDescription)"
            }

        case .bat(let error):
            switch error {
            case .batNotFound:
                return "bat executable not found. Install bat for syntax-highlighted output."
            case .batLanguagesFileCreationFailed(let underlying):
                return "Failed to create bat languages file: \(underlying.localizedDescription)"
            case .batLanguagesFileReadFailed(let underlying):
                return "Failed to read bat languages file: \(underlying.localizedDescription)"
            case .languageNotFound:
                return "Could not determine language for bat syntax highlighting."
            case .processError(let processErr):
                return "Bat process error: \(processErr.message)"
            }

        case .process(let error):
            return error.message

        case .other(let msg):
            return msg
        }
    }
}

extension ProcessError {
    /// Human-readable error message for process-related errors.
    var message: String {
        switch self {
        case .executionFailed(let underlying):
            return "Process execution failed: \(underlying.localizedDescription)"
        case .outputParsingFailed:
            return "Failed to parse process output."
        }
    }
}
