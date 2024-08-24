import Foundation
import ArgumentParser

@main struct Howto: AsyncParsableCommand {

    static let configuration = CommandConfiguration(
        commandName: "howto",
        abstract: "cli tool to find answers to programming questions using Google Search",
        version: "1.0.0"
    )
    
    @Option(name: .shortAndLong, help: "Search engine to use (google, bing)")
    var engine: SearchEngine = .google
    
    @Option(name: .shortAndLong, help: "Number of answers to return")
    var num: Int = 1

    @Argument(help: "The programming question you want to ask")
    var query: [String]
    
    mutating func run() async {
        let searchService = SearchService()
        let searchResult = await searchService.performSearch(engine: engine, query: query)
        
        switch searchResult {
        case .success(let results):
            for (index, result) in results.prefix(num).enumerated() {
                print("\nResult \(index + 1):")
                print("Title: \(result.title)")
                print("Link: \(result.link)")
                print("Snippet: \(result.snippet)")
            }
        case .failure(let error):
            print("Error: \(error)")
        }
    }
    
}
