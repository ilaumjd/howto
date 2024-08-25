import Foundation

struct SearchResult {
    let title: String
    let link: String
    let snippet: String
}

struct Answer {
    let questionTitle: String
    let tags: [String]
    let voteCount: Int
    let hasAcceptedAnswer: Bool
    let codeSnippets: [String]
    let fullAnswer: String
}
