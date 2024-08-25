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
        return await createURL(keyword: keyword)
            .asyncFlatMap(fetchHtmlPage)
    }
    
    func createKeyword(query: [String]) -> String {
        "site:\(config.site) \(query.joined(separator: " "))"
    }
    
    func createURL(keyword: String) -> Result<URL, HowtoError> {
        guard let encodedKeyword = keyword.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) else {
            return .failure(.invalidURL)
        }
        let urlString = String(format: config.engine.baseURL, encodedKeyword)
        guard let url = URL(string: urlString) else {
            return .failure(.invalidURL)
        }
        return .success(url)
    }
    
    func fetchHtmlPage(url: URL) async -> Result<String, HowtoError> {
        var request = URLRequest(url: url)
        request.setValue(config.userAgent, forHTTPHeaderField: "User-Agent")
        do {
            print("log", request)
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
