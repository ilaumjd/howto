import AsyncHTTPClient
import NIOCore
import NIOHTTP1

protocol WebFetchServiceProtocol {
    func fetchHtmlPage(urlString: String) async throws -> String
}

struct WebFetchService: WebFetchServiceProtocol {
    private let httpClient: HTTPClient
    let userAgent = "Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.114 Safari/537.36"

    init(httpClient: HTTPClient = HTTPClient.shared) {
        self.httpClient = httpClient
    }

    func fetchHtmlPage(urlString: String) async throws -> String {
        var request = HTTPClientRequest(url: urlString)
        request.headers.add(name: "User-Agent", value: userAgent)
        do {
            let response = try await httpClient.execute(request, timeout: .seconds(30))
            if response.status == .ok {
                let body = try await response.body.collect(upTo: 1024 * 1024)
                return String(buffer: body)
            } else {
                throw WebFetchError.noData
            }
        } catch let error as HTTPClientError {
            throw WebFetchError.networkError(error)
        } catch {
            throw WebFetchError.networkError(error)
        }
    }
}
