import Foundation

struct SearchService {
    private let context: SearchContext
    private let webService: WebFetchService
    
    init(context: SearchContext, webService: WebFetchService) {
        self.context = context
        self.webService = webService
    }
    
    func performSearch() async throws -> String {
        let keyword = createKeyword(query: context.query)
        let urlString = createSearchURL(keyword: keyword)
        return try await webService.fetchHtmlPage(urlString: urlString)
    }
    
    func createKeyword(query: [String]) -> String {
        "site:\(context.config.site) \(query.joined(separator: " "))"
    }
    
    func createSearchURL(keyword: String) -> String {
        String(format: context.config.engine.baseURL, keyword)
    }
}
