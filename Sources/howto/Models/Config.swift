import Foundation

struct Config {
    let site = "stackoverflow.com"

    let engine: SearchEngine
    let num: Int
    let showLink: Bool
    let useBat: Bool

    static func new(engineType: String = "google",
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
