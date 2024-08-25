import Foundation
import SwiftSoup

struct Answer {
    let questionTitle: String
    let tags: [String]
    let voteCount: Int
    let hasAcceptedAnswer: Bool
    let codeSnippets: [String]
    let fullAnswer: String
}
