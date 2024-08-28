import Foundation
import SwiftSoup

struct ParserService: ~Copyable {
    let config: Config

    func parseSearchResultLinks(htmlString: String) throws -> [String] {
        do {
            let engine = config.engine
            let doc: Document = try SwiftSoup.parse(htmlString)
            let results: Elements = try doc.select(engine.resultSelector)

            let links = results.array().compactMap { result -> String? in
                guard let link = try? result.select(engine.linkSelector).first()?.attr("href") else {
                    return nil
                }
                return link
            }

            guard !links.isEmpty else {
                throw ParserError.noResults
            }

            return links
        } catch let error as ParserError {
            throw error
        } catch {
            throw ParserError.parsingError(error)
        }
    }

    func parseStackOverflowAnswer(url: String, htmlString: String) throws -> Answer {
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

        // Create Answer
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
