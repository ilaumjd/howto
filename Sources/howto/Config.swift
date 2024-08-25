import Foundation

struct Config {
    let site = "stackoverflow.com"

    let engine: SearchEngine
    let num: Int
    
    static func create(engineType: String, num: Int) -> Result<Config, ConfigError> {
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
