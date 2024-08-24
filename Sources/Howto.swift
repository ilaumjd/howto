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

enum SearchEngine: String, ExpressibleByArgument {
    case google
    case bing
    
    init?(argument: String) {
        switch argument.lowercased() {
        case "google":
            self = .google
        case "bing":
            self = .bing
        default:
            return nil
        }
    }
}

extension Result {
    func asyncFlatMap<NewSuccess>(_ transform: (Success) async -> Result<NewSuccess, Failure>) async -> Result<NewSuccess, Failure> {
        switch self {
        case .success(let value):
            return await transform(value)
        case .failure(let error):
            return .failure(error)
        }
    }
}

@main struct Howto: AsyncParsableCommand {

    static let configuration = CommandConfiguration(
        commandName: "howto",
        abstract: "cli tool to find answers to programming questions using Google Search",
        version: "1.0.0"
    )
    
    @Option(name: .shortAndLong, help: "Search engine to use (google, bing)")
    var engine: SearchEngine

    @Argument(help: "The programming question you want to ask")
    var query: [String]
    
    mutating func run() async {
        let searchResult = await getUrl(engine: engine, query: query).asyncFlatMap(search).flatMap{ parseHtml(engine: engine, htmlString: $0) }
        
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
    
    private func getUrl(engine: SearchEngine, query: [String]) -> Result<URL, HowtoError> {
        let site = "stackoverflow.com"
        let question = query.joined(separator: "+")
        let urlString: String;
        
        switch engine {
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
//                print(htmlString)
                return .success(htmlString)
            }
            return .failure(.noData)
        } catch {
            return .failure(.networkError(error))
        }
    }
    
    private func parseHtml(engine: SearchEngine, htmlString: String) -> Result<[SearchResult], HowtoError> {
        switch engine {
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
