import Foundation
import SwiftSoup

struct SearchService {
    private let config: Config
    private let session: URLSessionProtocol
    
    init(config: Config, session: URLSessionProtocol = URLSession.shared) {
        self.config = config
        self.session = session
    }
    
    func performSearch(query: [String]) async throws -> String {
        let keyword = createKeyword(query: query)
        let urlString = createSearchURL(keyword: keyword)
        return try await fetchHtmlPage(urlString: urlString)
    }
    
    func createKeyword(query: [String]) -> String {
        "site:\(config.site) \(query.joined(separator: " "))"
    }
    
    func createSearchURL(keyword: String) -> String {
        String(format: config.engine.baseURL, keyword)
    }
    
    func fetchHtmlPage(urlString: String) async throws -> String {
        guard let url = URL(string: urlString) else {
            throw SearchError.invalidURL
        }
        var request = URLRequest(url: url)
        request.setValue(config.userAgent, forHTTPHeaderField: "User-Agent")
        do {
            let (data, _) = try await session.data(for: request)
            guard let htmlString = String(data: data, encoding: .utf8), !htmlString.isEmpty else {
                throw SearchError.noData
            }
            return htmlString
        } catch let error as SearchError {
            throw error
        } catch {
            throw SearchError.networkError(error)
        }
    }
}
