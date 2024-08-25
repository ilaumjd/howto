import Foundation
import SwiftSoup

struct SearchService {
    let config: Config
    let session: URLSessionProtocol
    
    init(config: Config, session: URLSessionProtocol = URLSession.shared) {
        self.config = config
        self.session = session
    }
    
    func performSearch(query: [String]) async throws -> String {
        let keyword = createKeyword(query: query)
        let urlString = createSearchURL(keyword: keyword)
        let url = try createURL(urlString: urlString)
        return try await fetchHtmlPage(url: url)
    }
    
    func createKeyword(query: [String]) -> String {
        "site:\(config.site) \(query.joined(separator: " "))"
    }
    
    func createSearchURL(keyword: String) -> String {
        String(format: config.engine.baseURL, keyword)
    }
    
    func createURL(urlString: String) throws -> URL {
        guard let url = URL(string: urlString) else {
            throw HowtoError.invalidURL
        }
        return url
    }
    
    func fetchHtmlPage(url: URL) async throws -> String {
        var request = URLRequest(url: url)
        request.setValue(config.userAgent, forHTTPHeaderField: "User-Agent")
        do {
            let (data, _) = try await session.data(for: request)
            guard let htmlString = String(data: data, encoding: .utf8), !htmlString.isEmpty else {
                throw HowtoError.noData
            }
            return htmlString
        } catch let error as HowtoError {
            throw error
        } catch {
            throw HowtoError.networkError(error)
        }
    }
}
