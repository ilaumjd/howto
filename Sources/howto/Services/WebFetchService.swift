import Foundation

protocol WebFetchServiceProtocol {
    func fetchHtmlPage(urlString: String) async throws -> String
}

struct WebFetchService: WebFetchServiceProtocol {

    private let session: URLSessionProtocol

    let userAgent = "Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.114 Safari/537.36"
    
    init(session: URLSessionProtocol = URLSession.shared) {
        self.session = session
    }
    
    func fetchHtmlPage(urlString: String) async throws -> String {
        guard let url = URL(string: urlString) else {
            throw WebFetchError.invalidURL
        }
        var request = URLRequest(url: url)
        request.setValue(userAgent, forHTTPHeaderField: "User-Agent")
        do {
            let (data, _) = try await session.data(for: request)
            guard let htmlString = String(data: data, encoding: .utf8), !htmlString.isEmpty else {
                throw WebFetchError.noData
            }
            return htmlString
        } catch let error as WebFetchError {
            throw error
        } catch {
            throw WebFetchError.networkError(error)
        }
    }
}
