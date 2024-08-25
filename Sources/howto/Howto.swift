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
        let configResult = Config.new(engineType: engineType, num: num)
        switch configResult {
        case let .success(config):
            await howto(config: config, query: query)
        case let .failure(error):
            print("Config error: \(error)")
        }
    }
    
    private func howto(config: Config, query: [String]) async {
        do {
            let searchService = SearchService(config: config)
            let batService = BatService()
            
            let htmlPage = try await searchService.performSearch(query: query)
            let results = try ParserService.parseSearchResults(htmlString: htmlPage, engine: config.engine)
            
            for result in results.prefix(config.num) {
                let url = try searchService.createURL(urlString: result.link)
                let soHtmlPage = try await searchService.fetchHtmlPage(url: url)
                let answer = try ParserService.parseStackOverflowAnswer(htmlString: soHtmlPage)
                
                let output = answer.codeSnippets.first ?? ""
                if bat {
                    await batService.printUsingBat(answer: answer)
                } else {
                    print(output)
                }
            }
        }
        catch {
            print(error)
        }
    }
    
    
}
