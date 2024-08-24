import Foundation
import ArgumentParser

@main struct Howto: AsyncParsableCommand {

    static let configuration = CommandConfiguration(
        commandName: "howto",
        abstract: "Find answer for programming questions",
        version: "0.0.1"
    )
    
    @Option(name: .shortAndLong, help: "Search engine to use (google, bing)")
    var engine: SearchEngineType = .google
    
    @Option(name: .shortAndLong, help: "Number of answers to return")
    var num: Int = 1

    @Argument(help: "The programming question you want to ask")
    var query: [String]
    
    mutating func run() async {
        let config = Config(engine: engine.engine, num: num)
        let service = HowtoService(config: config)
        let searchResult = await service.performSearch(query: query)
        
        switch searchResult {
        case .success(let results):
            for (index, result) in results.prefix(config.num).enumerated() {
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
