import Foundation
import SwiftSoup

enum ParserError: Error {
    case noResults
    case noAnswer
    case noAnswerBody
    case parsingError(Error)
}

struct ParserService {
    static func parseSearchResults(htmlString: String, engine: SearchEngine) throws -> [SearchResult] {
        do {
            let doc: Document = try SwiftSoup.parse(htmlString)
            let results: Elements = try doc.select(engine.resultSelector)
            
            let searchResults = results.array().compactMap { result -> SearchResult? in
                guard let title = try? result.select(engine.titleSelector).first()?.text(),
                      let link = try? result.select(engine.linkSelector).first()?.attr("href"),
                      let snippet = try? result.select(engine.snippetSelector).first()?.text()
                else {
                    return nil
                }
                
                return SearchResult(title: title, link: link, snippet: snippet)
            }
            
            guard !searchResults.isEmpty else {
                throw ParserError.noResults
            }
            
            return searchResults
        } catch let error as ParserError {
            throw error
        } catch {
            throw ParserError.parsingError(error)
        }
    }
    
    static func parseStackOverflowAnswer(htmlString: String) throws -> Answer {
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
            throw ParserError.noAnswer
        }
        
        // Check if it's an accepted answer
        let hasAcceptedAnswer = answerBlock.hasClass("accepted-answer")
        
        // Parse vote count
        let voteCountString = try answerBlock.select("div.js-vote-count").first()?.text() ?? "0"
        let voteCount = Int(voteCountString) ?? 0
        
        // Parse answer body
        let answerBody = try answerBlock.select("div.js-post-body").first() ?? answerBlock.select("div.post-text").first()
        
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
            questionTitle: questionTitle,
            tags: tags,
            voteCount: voteCount,
            hasAcceptedAnswer: hasAcceptedAnswer,
            codeSnippets: codeSnippets,
            fullAnswer: fullAnswer
        )
    }
}
