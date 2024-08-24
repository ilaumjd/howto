import Foundation
import ArgumentParser
import SwiftSoup

enum HowtoError: Error {
    case invalidURL
    case networkError(Error)
    case noData
    case parsingError(Error)
}

struct SearchResult {
    let title: String
    let link: String
    let snippet: String
}

struct Howto: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "howto",
        abstract: "cli tool to find answers to programming questions using Google Search",
        version: "1.0.0"
    )
    
    @Argument(help: "The programming question you want to ask")
    var query: [String]
    
    private let site = "stackoverflow.com"
    
    func run() {
        let question = query.joined(separator: "+")
        let urlString = "https://www.google.com/search?q=site:\(site) \(question)&hl=en"
        
        print("URL: \(urlString)")
        
        let searchResult = search(urlString: urlString)
        
        switch searchResult {
        case .success(let results):
            for (index, result) in results.prefix(3).enumerated() {
                print("\nResult \(index + 1):")
                print("Title: \(result.title)")
                print("Link: \(result.link)")
                print("Snippet: \(result.snippet)")
            }
        case .failure(let error):
            print("Error: \(error)")
        }
    }
    
    private func search(urlString: String) -> Result<[SearchResult], HowtoError> {
        guard let url = URL(string: urlString) else {
            return .failure(.invalidURL)
        }
        
        var request = URLRequest(url: url)
        request.setValue("Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/14.0 Safari/605.1.15", forHTTPHeaderField: "User-Agent")
        
        let semaphore = DispatchSemaphore(value: 0)
        var searchResult: Result<[SearchResult], HowtoError> = .failure(.noData)
        
        let task = URLSession.shared.dataTask(with: request) { (data, response, error) in
            defer { semaphore.signal() }
            
            if let error = error {
                searchResult = .failure(.networkError(error))
                return
            }
            
            guard let data = data, let htmlString = String(data: data, encoding: .utf8) else {
                searchResult = .failure(.noData)
                return
            }
            
            searchResult = self.parseHtml(htmlString)
        }
        
        task.resume()
        semaphore.wait()
        
        return searchResult
    }

    private func parseHtml(_ html: String) -> Result<[SearchResult], HowtoError> {
        do {
            let doc: Document = try SwiftSoup.parse(html)
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
}

Howto.main()
