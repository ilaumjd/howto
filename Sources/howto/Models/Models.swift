import Foundation

/// Holds the user's configuration and query terms needed to build a search request.
struct SearchContext {
    /// Resolved application configuration.
    let config: Config
    /// The raw query words that make up the user's question.
    let queryTerms: [String]

    /// Builds the fully-qualified search URL by combining the site restriction
    /// (stackoverflow.com) with the query terms into the selected engine's template.
    var searchURL: String {
        let keyword = "site:\(config.site) \(queryTerms.joined(separator: " "))"
            .addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        return String(format: config.engine.baseURL, keyword)
    }
}

/// Represents a parsed StackOverflow answer with its metadata and code content.
struct Answer {
    /// The permalink to the answer on StackOverflow.
    let url: String
    /// The title of the question this answer belongs to.
    let questionTitle: String
    /// Tags associated with the question.
    let tags: [String]
    /// Whether this answer was accepted by the asker.
    let accepted: Bool
    /// The number of votes this answer received.
    let voteCount: Int
    /// Code snippets extracted from the answer body.
    let codeSnippets: [String]
    /// The full text content of the answer body.
    let fullAnswer: String

    /// Returns the most representative snippet: the most frequent code block,
    /// or the longest one if there's a tie, falling back to the full answer text.
    var answerToShow: String {
        let frequency = codeSnippets.reduce(into: [:]) { counts, snippet in
            counts[snippet, default: 0] += 1
        }
        let maxFrequency = frequency.values.max() ?? 0
        return frequency
            .filter { $0.value == maxFrequency }
            .max(by: { $0.key.count < $1.key.count })?
            .key ?? fullAnswer
    }
}
