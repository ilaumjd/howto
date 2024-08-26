import Foundation

struct Config {
  let site = "stackoverflow.com"

  let engine: SearchEngine
  let num: Int
  let useBat: Bool

  static func new(engineType: String = "google", num: Int = 1, useBat: Bool = false) -> Result<
    Config, ConfigError
  > {
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

    let config = Config(engine: engine, num: num, useBat: useBat)
    return .success(config)
  }
}
