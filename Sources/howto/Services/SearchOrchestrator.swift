import Foundation

/// Top-level coordinator that drives the search–fetch–parse–output pipeline.
struct SearchOrchestrator {
    /// The search context containing configuration and query terms.
    let context: SearchContext

    init(context: SearchContext) {
        self.context = context
    }

    /// Runs the full search pipeline:
    /// 1. Fetches the SERP HTML from the search engine.
    /// 2. Parses result links from the SERP.
    /// 3. Fetches the top N answer pages concurrently.
    /// 4. Parses each answer page.
    /// 5. Displays the results in order.
    func run() async {
        let webService = WebFetchService()
        let parserService = ParserService(config: context.config)
        let outputService = OutputService(context: context)

        do {
            let resultHtmlString = try await webService.fetchHtmlPage(urlString: context.searchURL)
            let answerURLs = try parserService.parseSearchResultLinks(htmlString: resultHtmlString)

            let answerURLsSlice = answerURLs.prefix(context.config.num)
            let answers = await withTaskGroup(of: (Int, Answer)?.self) { group in
                for (index, answerURL) in answerURLsSlice.enumerated() {
                    group.addTask {
                        do {
                            let answerHtmlString = try await webService.fetchHtmlPage(urlString: answerURL)
                            let answer = try parserService.parseStackOverflowAnswer(
                                url: answerURL, htmlString: answerHtmlString
                            )
                            return (index, answer)
                        } catch {
                            print("Failed to fetch answer \(index + 1): \(error)", to: &stdErr)
                            return nil
                        }
                    }
                }

                var collected = [(Int, Answer)]()
                for await result in group {
                    if let result {
                        collected.append(result)
                    }
                }
                return collected
            }

            for (index, answer) in answers.sorted(by: { $0.0 < $1.0 }) {
                await outputService.performOutput(index: index, answer: answer)
            }
        } catch let error as WebFetchError {
            print(HowtoError.webFetch(error, context: context.searchURL).message, to: &stdErr)
        } catch let error as ParserError {
            print(HowtoError.parser(error).message, to: &stdErr)
        } catch {
            print(HowtoError.other("Unexpected error: \(error.localizedDescription)").message, to: &stdErr)
        }
    }
}
