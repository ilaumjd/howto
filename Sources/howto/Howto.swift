import Foundation
import ArgumentParser

@main struct Howto: AsyncParsableCommand {
    
    static let configuration = CommandConfiguration(
        commandName: "howto",
        abstract: "Find answer for programming questions",
        version: "0.0.1"
    )
    
    @Option(name: [.short, .customLong("engine")], help: "Search engine to use (google, bing)")
    var engineType: String = "google"
    
    @Option(name: .shortAndLong, help: "Number of answers to return")
    var num: Int = 1
    
    @Flag(name: .shortAndLong, help: "Pipe output to bat for syntax highlighting")
    var bat: Bool = false
    
    @Argument(help: "The programming question you want to ask")
    var query: [String]
    
    mutating func run() async {
        let configResult = Config.new(engineType: engineType, num: num, useBat: bat)
        switch configResult {
        case let .success(config):
            await howto(config: config, query: query)
        case let .failure(error):
            print("Config error: \(error)")
        }
    }
    
    private func howto(config: Config, query: [String]) async {
        do {
            let context = SearchContext(config: config, query: query)

            let searchService = SearchService(context: context)
            let parserService = ParserService(config: config)
            
            let resultHtmlString = try await searchService.performSearch()
            let answerURLs = try parserService.parseSearchResultLinks(htmlString: resultHtmlString)
            
            for answerURL in answerURLs.prefix(config.num) {
                let answerHtmlString = try await searchService.fetchHtmlPage(urlString: answerURL)
                let answer = try parserService.parseStackOverflowAnswer(url: answerURL, htmlString: answerHtmlString)
                
                let outputService = OutputService(context: context)
                await outputService.output(answer: answer)
            }
        }
        catch {
            print(error)
        }
    }
    
    
}
