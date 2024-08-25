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
            let searchService = SearchService(config: config)
            let batService = BatService()
            
            let htmlPage = try await searchService.performSearch(query: query)
            let resultURLs = try ParserService.parseSearchResultLinks(htmlString: htmlPage, engine: config.engine)
            
            for resultURL in resultURLs.prefix(config.num) {
                let url = try searchService.createURL(urlString: resultURL)
                let soHtmlPage = try await searchService.fetchHtmlPage(url: url)
                let answer = try ParserService.parseStackOverflowAnswer(url: resultURL, htmlString: soHtmlPage)
                
                if config.useBat {
                    try await batService.printUsingBat(answer: answer)
                } else {
                    print(answer.codeSnippets.first ?? "")
                }
            }
        }
        catch {
            print(error)
        }
    }
    
    
}
