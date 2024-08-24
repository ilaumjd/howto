import Foundation
import SwiftSoup

struct HowtoService {
    
    let config: Config
    let session: URLSessionProtocol
    
    init(config: Config, session: URLSessionProtocol = URLSession.shared) {
        self.config = config
        self.session = session
    }
    
    func performSearch(query: [String]) async -> Result<[SearchResult], HowtoError> {
        let keyword = createKeyword(query: query)
        return await config.engine.createURL(keyword: keyword)
            .asyncFlatMap(search)
            .flatMap(config.engine.parse)
    }
    
    func createKeyword(query: [String]) -> String {
        let keyword = "site:\(config.site) \(query.joined(separator: " "))"
        return keyword
    }
    
    func search(url: URL) async -> Result<String, HowtoError> {
        var request = URLRequest(url: url)
        request.setValue(config.userAgent, forHTTPHeaderField: "User-Agent")
        do {
            let (data, _) = try await session.data(for: request)
            guard let htmlString = String(data: data, encoding: .utf8), !htmlString.isEmpty else {
                return .failure(.noData)
            }
            return .success(htmlString)
        } catch {
            return .failure(.networkError(error))
        }
    }
}
