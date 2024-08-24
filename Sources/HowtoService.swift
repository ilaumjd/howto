import Foundation
import SwiftSoup

struct HowtoService {
    
    let config: Config
    
    func performSearch(query: [String]) async -> Result<[SearchResult], HowtoError> {
        return await getUrl(query: query)
            .asyncFlatMap(search)
            .flatMap(parseHtml)
    }
    
    private func getUrl(query: [String]) -> Result<URL, HowtoError> {
        let site = "stackoverflow.com"
        let question = query.joined(separator: "+")
        let urlString: String;
        
        switch config.engine {
        case .bing:
            urlString = "https://www.bing.com/search?q=site:\(site) \(question)"
        default:
            urlString = "https://www.google.com/search?q=site:\(site) \(question)&hl=en"
        }
        if let url = URL(string: urlString) {
            return .success(url)
        }
        return .failure(.invalidURL)
    }
    
    private func search(url: URL) async -> Result<String, HowtoError> {
        var request = URLRequest(url: url)
        request.setValue("Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.114 Safari/537.36", forHTTPHeaderField: "User-Agent")
        
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
        switch config.engine {
        case .bing:
            parseHtmlBing(htmlString: htmlString)
        default:
            parseHtmlGoogle(htmlString: htmlString)
        }
    }
    
    private func parseHtmlGoogle(htmlString: String) -> Result<[SearchResult], HowtoError> {
        do {
            let doc: Document = try SwiftSoup.parse(htmlString)
            let results: Elements = try doc.select("div.g")
            
            let searchResults = results.array().compactMap { result -> SearchResult? in
                guard let titleElement = try? result.select("h3").first(),
                      let title = try? titleElement.text(),
                      let linkElement = try? result.select("a").first(),
                      let link = try? linkElement.attr("href"),
                      let snippetElement = try? result.select("div.VwiC3b").first(),
                      let snippet = try? snippetElement.text() else {
                    return nil
                }
                
                return SearchResult(title: title, link: link, snippet: snippet)
            }
            
            return .success(searchResults)
        } catch {
            return .failure(.parsingError(error))
        }
    }
    
    private func parseHtmlBing(htmlString: String) -> Result<[SearchResult], HowtoError> {
        do {
            let doc: Document = try SwiftSoup.parse(htmlString)
            let results: Elements = try doc.select("li.b_algo")
            
            let searchResults = results.array().compactMap { result -> SearchResult? in
                guard let titleElement = try? result.select("h2").first(),
                      let title = try? titleElement.text(),
                      let linkElement = try? titleElement.select("a").first(),
                      let link = try? linkElement.attr("href"),
                      let snippetElement = try? result.select("div.b_caption p").first(),
                      let snippet = try? snippetElement.text() else {
                    return nil
                }
                
                return SearchResult(title: title, link: link, snippet: snippet)
            }
            
            return .success(searchResults)
        } catch {
            return .failure(.parsingError(error))
        }
    }
}
