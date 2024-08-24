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

@main struct Howto: AsyncParsableCommand {

    static let configuration = CommandConfiguration(
        commandName: "howto",
        abstract: "cli tool to find answers to programming questions using Google Search",
        version: "1.0.0"
    )
    
    @Argument(help: "The programming question you want to ask")
    var query: [String]
    
    mutating func run() async {
        let site = "stackoverflow.com"
        let question = query.joined(separator: "+")
        let urlString = "https://www.google.com/search?q=site:\(site) \(question)&hl=en"
        
        let searchResult = await search(urlString: urlString).flatMap(parseHtml)
        
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
    
    private func search(urlString: String) async -> Result<String, HowtoError> {
        guard let url = URL(string: urlString) else {
            return .failure(.invalidURL)
        }
        
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
