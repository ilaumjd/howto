import Foundation
import SwiftSoup

struct HowtoService {
    
    let config: Config
    
    private let userAgent = "Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.114 Safari/537.36"
    
    func performSearch(query: [String]) async -> Result<[SearchResult], HowtoError> {
        let keyword = createKeyword(query: query)
        return await config.engine.createURL(keyword: keyword)
            .asyncFlatMap(search)
            .flatMap(config.engine.parse)
    }
    
    private func createKeyword(query: [String]) -> String {
        let site = "stackoverflow.com"
        let keyword = "site:\(site) \(query.joined(separator: " "))"
        return keyword
    }
    
    private func search(url: URL) async -> Result<String, HowtoError> {
        var request = URLRequest(url: url)
        request.setValue(userAgent, forHTTPHeaderField: "User-Agent")
        do {
            let (data, _) = try await URLSession.shared.data(for: request)
            guard let htmlString = String(data: data, encoding: .utf8) else {
                return .failure(.noData)
            }
            return .success(htmlString)
        } catch {
            return .failure(.networkError(error))
        }
    }
}
