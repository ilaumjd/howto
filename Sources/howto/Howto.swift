import ArgumentParser
import Foundation

@main struct Howto: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "howto",
        abstract: "Find answer for coding questions",
        version: "0.0.2"
    )

    @Option(name: [.short, .customLong("engine")], help: "Search engine to use (google, bing)")
    var engineType: String = "google"

    @Option(name: .shortAndLong, help: "Number of answers to return")
    var num: Int = 1

    @Flag(name: .shortAndLong, help: "Show source link of the answer")
    var link: Bool = false

    @Flag(name: .shortAndLong, help: "Use bat for syntax highlighting")
    var bat: Bool = false

    @Argument(help: "Coding question you want to ask")
    var query: [String]

    mutating func run() async {
        let configResult = Config.new(engineType: engineType,
                                      num: num,
                                      showLink: link,
                                      useBat: bat)
        switch configResult {
        case let .success(config):
            let context = SearchContext(config: config, query: query)
            await howto(context: context)
        case let .failure(error):
            print("Config error: \(error)")
        }
    }

    private func howto(context: SearchContext) async {
        let webService = WebFetchService()
        let parserService = ParserService(config: context.config)
        let outputService = OutputService(context: context)

        do {
            let resultHtmlString = try await webService.fetchHtmlPage(urlString: context.searchURL)
            let answerURLs = try parserService.parseSearchResultLinks(htmlString: resultHtmlString)

            for (index, answerURL) in answerURLs.prefix(context.config.num).enumerated() {
                let answerHtmlString = try await webService.fetchHtmlPage(urlString: answerURL)
                let answer = try parserService.parseStackOverflowAnswer(
                    url: answerURL, htmlString: answerHtmlString
                )

                await outputService.performOutput(index: index, answer: answer)
            }
        } catch {
            print(error)
        }
    }
}
