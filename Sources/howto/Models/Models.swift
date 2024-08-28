import Foundation

struct SearchContext {
    let config: Config
    let query: [String]

    var searchURL: String {
        let keyword = "site:\(config.site) \(query.joined(separator: " "))"
            .addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? ""
        return String(format: config.engine.baseURL, keyword)
    }
}

struct Answer {
    let url: String
    let questionTitle: String
    let tags: [String]
    let accepted: Bool
    let voteCount: Int
    let codeSnippets: [String]
    let fullAnswer: String

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
