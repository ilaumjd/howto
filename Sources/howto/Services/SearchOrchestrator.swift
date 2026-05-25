import Foundation
import SwiftSoup

/// Top-level coordinator that drives the search–fetch–parse–output pipeline.
struct SearchOrchestrator {
    /// The search context containing configuration and query terms.
    let context: SearchContext

    init(context: SearchContext) {
        self.context = context
    }

    /// Runs the full search pipeline via the Stack Exchange API:
    /// 1. Searches Stack Overflow questions matching the query.
    /// 2. Fetches the top answer for each question concurrently.
    /// 3. Parses code snippets from each answer body.
    /// 4. Displays the results in order.
    func run() async {
        let seService = StackExchangeService()
        let answerParser = AnswerParser()
        let outputService = OutputService(context: context)

        let query = context.queryTerms.joined(separator: " ")

        do {
            let questions = try await seService.searchQuestions(
                query: query, pageSize: context.config.num)

            guard !questions.isEmpty else {
                print(HowtoError.parser(.noResults).message, to: &stdErr)
                return
            }

            let answers = await withTaskGroup(of: (Int, Answer)?.self) { group in
                for (index, question) in questions.enumerated() {
                    group.addTask {
                        do {
                            guard let seAnswer = try await seService.fetchTopAnswer(
                                questionId: question.questionId)
                            else { return nil }

                            let title =
                                (try? Entities.unescape(string: question.title, strict: false))
                                ?? question.title
                            let (codeSnippets, fullAnswer) = try answerParser.parseBody(
                                htmlString: seAnswer.body)
                            return (
                                index,
                                Answer(
                                    url: question.link,
                                    questionTitle: title,
                                    tags: question.tags,
                                    accepted: seAnswer.isAccepted,
                                    voteCount: seAnswer.score,
                                    codeSnippets: codeSnippets,
                                    fullAnswer: fullAnswer
                                )
                            )
                        } catch {
                            print("Failed to fetch answer \(index + 1): \(error)", to: &stdErr)
                            return nil
                        }
                    }
                }

                var collected = [(Int, Answer)]()
                for await result in group {
                    if let result { collected.append(result) }
                }
                return collected
            }

            for (index, answer) in answers.sorted(by: { $0.0 < $1.0 }) {
                await outputService.performOutput(index: index, answer: answer)
            }
        } catch let error as WebFetchError {
            print(HowtoError.webFetch(error, context: query).message, to: &stdErr)
        } catch {
            print(HowtoError.other("Unexpected error: \(error.localizedDescription)").message, to: &stdErr)
        }
    }
}
