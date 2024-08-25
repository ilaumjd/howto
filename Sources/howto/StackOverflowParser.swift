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

enum StackOverflowParserError: Error {
    case noAnswer
    case noAnswerBody
}

struct StackOverflowParser {
    static func parse(htmlString: String) throws -> Answer {
        let doc: Document = try SwiftSoup.parse(htmlString)
        
        // Parse question title
        let questionTitle = try doc.select("h1[itemprop=name] a.question-hyperlink").first()?.text() ?? ""
        
        // Parse tags
        let tags = try doc.select(".post-tag").map { try $0.text() }
        
        // Find the accepted answer or the highest voted answer
        let answerBlock = try doc.select("div.answer").first { element in
            try element.hasClass("accepted-answer") || element.select("div.js-vote-count").first()?.text() != "0"
        } ?? doc.select("div.answer").first()
        
        guard let answerBlock = answerBlock else {
            throw StackOverflowParserError.noAnswer
        }
        
        // Check if it's an accepted answer
        let hasAcceptedAnswer = answerBlock.hasClass("accepted-answer")
        
        // Parse vote count
        let voteCountString = try answerBlock.select("div.js-vote-count").first()?.text() ?? "0"
        let voteCount = Int(voteCountString) ?? 0
        
        // Parse answer body
        let answerBody = try answerBlock.select("div.js-post-body").first() ?? answerBlock.select("div.post-text").first()
        
        guard let answerBody = answerBody else {
            throw StackOverflowParserError.noAnswerBody
        }
        
        // Parse code snippets
        let preCodeBlocks = try answerBody.select("pre code")
        let codeSnippets: [String]
        if preCodeBlocks.isEmpty() {
            // If no <pre><code> blocks found, look for <code> elements
            let codeBlocks = try answerBody.select("code")
            codeSnippets = try codeBlocks.map { try $0.htmlDecoded() }
        } else {
            codeSnippets = try preCodeBlocks.map { try $0.htmlDecoded() }
        }
        
        // Parse full answer text
        let fullAnswer = try answerBody.htmlDecoded()
        
        // Create Answer
        return Answer(
            questionTitle: questionTitle,
            tags: tags,
            voteCount: voteCount,
            hasAcceptedAnswer: hasAcceptedAnswer,
            codeSnippets: codeSnippets,
            fullAnswer: fullAnswer
        )
    }
}
