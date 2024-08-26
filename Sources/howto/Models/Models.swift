import Foundation

struct SearchContext {
  let config: Config
  let query: [String]
}

struct Answer {
  let url: String
  let questionTitle: String
  let tags: [String]
  let accepted: Bool
  let voteCount: Int
  let codeSnippets: [String]
  let fullAnswer: String
}
