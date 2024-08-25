import Foundation
import ArgumentParser

@main struct Howto: AsyncParsableCommand {

    static let configuration = CommandConfiguration(
        commandName: "howto",
        abstract: "Find answer for programming questions",
        version: "0.0.1"
    )
    
    @Option(name: .shortAndLong, help: "Search engine to use (google, bing)")
    var engine: String = "google"
    
    @Option(name: .shortAndLong, help: "Number of answers to return")
    var num: Int = 1

    @Argument(help: "The programming question you want to ask")
    var query: [String]
    
    mutating func run() async {
        let configResult = Config.create(engineType: engine, num: num)
        
        switch configResult {
        case let .success(config):
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
        case let .failure(error):
            print("Config error: \(error)")
        }

    }
    
}
