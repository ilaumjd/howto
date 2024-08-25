import Foundation
import SwiftSoup

struct Answer {
    let questionTitle: String
    let voteCount: Int
    let hasAcceptedAnswer: Bool
    let codeSnippets: [String]
    let fullAnswer: String
}

struct StackOverflowParser {
    static func parse(htmlString: String) -> Result<Answer, HowtoError> {
        do {
            let doc: Document = try SwiftSoup.parse(htmlString)
            
            // Parse question title
            let questionTitle = try doc.select("h1[itemprop=name] a.question-hyperlink").first()?.text() ?? ""
            
            // Find the accepted answer or the highest voted answer
            let answerBlock = try doc.select("div.answer").first { element in
                try element.hasClass("accepted-answer") || element.select("div.js-vote-count").first()?.text() != "0"
            } ?? doc.select("div.answer").first()
            
            guard let answerBlock = answerBlock else {
                return .failure(.noData)
            }
            
            // Check if it's an accepted answer
            let hasAcceptedAnswer = answerBlock.hasClass("accepted-answer")
            
            // Parse vote count
            let voteCountString = try answerBlock.select("div.js-vote-count").first()?.text() ?? "0"
            let voteCount = Int(voteCountString) ?? 0
            
            // Parse answer body
            guard let answerBody = try answerBlock.select("div.js-post-body").first() ?? answerBlock.select("div.post-text").first() else {
                return .failure(.parsingError(NSError(domain: "StackOverflowParser", code: 1, userInfo: [NSLocalizedDescriptionKey: "Could not find answer body"])))
            }
            
            // Extract code snippets
            let preCodeBlocks = try answerBody.select("pre code")
            let codeSnippets: [String]
            if preCodeBlocks.isEmpty() {
                // If no <pre><code> blocks found, look for <code> elements
                let codeBlocks = try answerBody.select("code")
                codeSnippets = try codeBlocks.map { try $0.htmlDecoded() }
            } else {
                codeSnippets = try preCodeBlocks.map { try $0.htmlDecoded() }
            }
            
            // Get full answer text
            let fullAnswer = try answerBody.htmlDecoded()
            
            // Create Answer
            let answer = Answer(
                questionTitle: questionTitle,
                voteCount: voteCount,
                hasAcceptedAnswer: hasAcceptedAnswer,
                codeSnippets: codeSnippets,
                fullAnswer: fullAnswer
            )
            
            return .success(answer)
        } catch {
            return .failure(.parsingError(error))
        }
    }
}
