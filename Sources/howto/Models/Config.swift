import Foundation

struct Config {
    let site = "stackoverflow.com"
    let userAgent = "Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.114 Safari/537.36"

    let engine: SearchEngine
    let num: Int
    
    static func new(engineType: String, num: Int) -> Result<Config, ConfigError> {
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
        
        let config = Config(engine: engine, num: num)
        return .success(config)
    }
}
