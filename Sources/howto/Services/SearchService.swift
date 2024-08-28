import Foundation

struct SearchService: ~Copyable {
    private let context: SearchContext

    init(context: SearchContext) {
        self.context = context
    }

    func performSearch() async throws -> String {
        let keyword = createKeyword(query: context.query)
        let urlString = createSearchURL(keyword: keyword)
        return urlString
    }

    func createKeyword(query: [String]) -> String {
        "site:\(context.config.site) \(query.joined(separator: " "))"
            .addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? ""
    }

    func createSearchURL(keyword: String) -> String {
        String(format: context.config.engine.baseURL, keyword)
    }
}
