import ArgumentParser
import Foundation

/// Main entry point for the howto CLI tool. Parses command-line arguments and orchestrates
/// the search, parsing, and output pipeline.
@main struct Howto: AsyncParsableCommand {
    /// Command-line configuration: name, description, and version.
    static let configuration = CommandConfiguration(
        commandName: "howto",
        abstract: "Find answer for coding questions",
        version: "0.0.2"
    )

    /// Search engine to use — "google" (default) or "bing".
    @Option(name: [.short, .customLong("engine")], help: "Search engine to use (google, bing)")
    var engineType: String = "google"

    /// Number of answers to return (default: 1).
    @Option(name: .shortAndLong, help: "Number of answers to return")
    var num: Int = 1

    /// Whether to show the source URL of each answer.
    @Flag(name: .shortAndLong, help: "Show source link of the answer")
    var link: Bool = false

    /// Whether to use `bat` for syntax-highlighted output.
    @Flag(name: .shortAndLong, help: "Use bat for syntax highlighting")
    var bat: Bool = false

    /// The coding question to search for. Multiple words are joined into a query string.
    @Argument(help: "Coding question you want to ask")
    var query: [String]

    /// Executes the search workflow: validates config, creates a search context,
    /// and runs the orchestrator.
    mutating func run() async {
        let configResult = Config.create(
            engineType: engineType,
            num: num,
            showLink: link,
            useBat: bat
        )
        switch configResult {
        case let .success(config):
            let context = SearchContext(config: config, queryTerms: query)
            let orchestrator = SearchOrchestrator(context: context)
            await orchestrator.run()
        case let .failure(error):
            print(HowtoError.config(error).message, to: &stdErr)
        }
    }
}
