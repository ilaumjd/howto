import Foundation
import SwiftSoup

struct HowtoService {
    
    let config: Config
    
    private let userAgent = "Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.114 Safari/537.36"
    
    func performSearch(query: [String]) async -> Result<[SearchResult], HowtoError> {
        return await createUrl(query: query)
            .asyncFlatMap(search)
            .flatMap(parseHtml)
    }
    
    private func createUrl(query: [String]) -> Result<URL, HowtoError> {
        let site = "stackoverflow.com"
        let question = query.joined(separator: "+")
        let urlString: String;
        
        switch config.engine {
        case .google:
            urlString = "https://www.google.com/search?q=site:\(site) \(question)&hl=en"
        case .bing:
            urlString = "https://www.bing.com/search?q=site:\(site) \(question)"
        }
        if let url = URL(string: urlString) {
            return .success(url)
        }
        return .failure(.invalidURL)
    }
    
    private func search(url: URL) async -> Result<String, HowtoError> {
        var request = URLRequest(url: url)
        request.setValue(userAgent, forHTTPHeaderField: "User-Agent")
        do {
            let (data, _) = try await URLSession.shared.data(for: request)
            if let htmlString = String(data: data, encoding: .utf8) {
                return .success(htmlString)
            }
            return .failure(.noData)
        } catch {
            return .failure(.networkError(error))
        }
    }
    
    private func parseHtml(htmlString: String) -> Result<[SearchResult], HowtoError> {
        let parser: SearchResultParser
        switch config.engine {
        case .google:
            parser = GoogleParser()
        case .bing:
            parser = BingParser()
        }
        return parser.parse(htmlString: htmlString)
    }
}
