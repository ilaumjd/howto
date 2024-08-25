import Foundation
import SwiftSoup

struct SearchService {
    
    let config: Config
    let session: URLSessionProtocol
    
    init(config: Config, session: URLSessionProtocol = URLSession.shared) {
        self.config = config
        self.session = session
    }
    
    func performSearch(query: [String]) async -> Result<String, HowtoError> {
        let keyword = createKeyword(query: query)
        let urlString = createSearchURL(keyword: keyword)
        return await createURL(urlString: urlString)
            .asyncFlatMap(fetchHtmlPage)
    }
    
    func createKeyword(query: [String]) -> String {
        "site:\(config.site) \(query.joined(separator: " "))"
    }
    
    func createSearchURL(keyword: String) -> String {
        String(format: config.engine.baseURL, keyword)
    }
    
    func createURL(urlString: String) -> Result<URL, HowtoError> {
        guard let url = URL(string: urlString) else {
            return .failure(.invalidURL)
        }
        return .success(url)
    }
    
    func fetchHtmlPage(url: URL) async -> Result<String, HowtoError> {
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
