import Foundation
import SwiftSoup

/// Parses a StackOverflow answer page HTML to extract the answer content.
struct AnswerParser {
    /// Parses a single StackOverflow answer page into an `Answer` model.
    /// - Parameters:
    ///   - url: The source URL of the answer page.
    ///   - htmlString: The raw HTML of the answer page.
    /// - Returns: A fully populated `Answer` struct.
    /// - Throws: `ParserError.noAnswer` or `ParserError.noAnswerBody` if parsing fails.
    /// Extracts code snippets and full answer text from an answer body HTML fragment.
    func parseBody(htmlString: String) throws -> (codeSnippets: [String], fullAnswer: String) {
        let doc: Document = try SwiftSoup.parse(htmlString)
        guard let body = doc.body() else {
            throw ParserError.noAnswerBody
        }

        let preCodeBlocks = try body.select("pre code")
        let codeSnippets: [String]
        if preCodeBlocks.isEmpty() {
            let codeBlocks = try body.select("code")
            codeSnippets = try codeBlocks.map { try $0.htmlDecoded() }
        } else {
            codeSnippets = try preCodeBlocks.map { try $0.htmlDecoded() }
        }

        let fullAnswer = try body.htmlDecoded()
        return (codeSnippets: codeSnippets, fullAnswer: fullAnswer)
    }

    func parse(url: String, htmlString: String) throws -> Answer {
        let doc: Document = try SwiftSoup.parse(htmlString)

        // Parse question title
        let questionTitle =
            try doc.select("h1[itemprop=name] a.question-hyperlink").first()?.text() ?? ""

        // Parse tags
        let tags = try doc.select(".post-tag").map { try $0.text() }

        // Find the accepted answer or the highest voted answer
        let answerBlock =
            try doc.select("div.answer").first { element in
                try element.hasClass("accepted-answer")
                    || element.select("div.js-vote-count").first()?.text() != "0"
            } ?? doc.select("div.answer").first()

        guard let answerBlock = answerBlock else {
            throw ParserError.noAnswer
        }

        // Check if it's an accepted answer
        let accepted = answerBlock.hasClass("accepted-answer")

        // Parse vote count
        let voteCountString = try answerBlock.select("div.js-vote-count").first()?.text() ?? "0"
        let voteCount = Int(voteCountString) ?? 0

        // Parse answer body
        let answerBody =
            try answerBlock.select("div.js-post-body").first()
                ?? answerBlock.select("div.post-text").first()

        guard let answerBody = answerBody else {
            throw ParserError.noAnswerBody
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

        return Answer(
            url: url,
            questionTitle: questionTitle,
            tags: tags,
            accepted: accepted,
            voteCount: voteCount,
            codeSnippets: codeSnippets,
            fullAnswer: fullAnswer
        )
    }
}
