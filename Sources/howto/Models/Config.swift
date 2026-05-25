import Foundation

/// Resolved application configuration derived from command-line arguments.
struct Config {
    /// The target site to restrict search results to (always stackoverflow.com).
    let site = "stackoverflow.com"

    /// The search engine implementation (Google or Bing).
    let engine: SearchEngine
    /// Maximum number of answers to retrieve.
    let num: Int
    /// Whether to display the source URL alongside each answer.
    let showLink: Bool
    /// Whether to use `bat` for syntax-highlighted output.
    let useBat: Bool

    /// Validates and creates a `Config` from raw CLI parameter values.
    /// - Parameters:
    ///   - engineType: The search engine name ("google" or "bing").
    ///   - num: The requested number of answers.
    ///   - showLink: Whether to show answer source links.
    ///   - useBat: Whether to use bat syntax highlighting.
    /// - Returns: A `.success(Config)` on valid input, or `.failure(ConfigError)` otherwise.
    static func create(engineType: String = "google",
                    num: Int = 1,
                    showLink: Bool = false,
                    useBat: Bool = false) -> Result<Config, ConfigError>
    {
        let engine: SearchEngine
        switch engineType.lowercased() {
        case "google":
            engine = GoogleEngine()
        case "bing":
            engine = BingEngine()
        default:
            return .failure(.invalidSearchEngine)
        }

        guard num > 0 else {
            return .failure(.invalidNumber)
        }

        let config = Config(engine: engine,
                            num: num,
                            showLink: showLink,
                            useBat: useBat)
        return .success(config)
    }
}
