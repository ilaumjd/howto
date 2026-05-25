import Foundation

struct SESearchQuestion: Decodable, Sendable {
    let questionId: Int
    let title: String
    let link: String
    let tags: [String]

    enum CodingKeys: String, CodingKey {
        case questionId = "question_id"
        case title, link, tags
    }
}

struct SEAnswer: Decodable, Sendable {
    let isAccepted: Bool
    let score: Int
    let body: String

    enum CodingKeys: String, CodingKey {
        case isAccepted = "is_accepted"
        case score, body
    }
}

private struct SEResponse<T: Decodable>: Decodable {
    let items: [T]
}

struct StackExchangeService: Sendable {
    private let baseURL = "https://api.stackexchange.com/2.3"
    private let requestTimeout: TimeInterval = 10

    func searchQuestions(query: String, pageSize: Int) async throws -> [SESearchQuestion] {
        let encoded = query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? query
        let urlString =
            "\(baseURL)/search/advanced?order=desc&sort=relevance&q=\(encoded)&site=stackoverflow&pagesize=\(pageSize)"
        return try await fetch(SEResponse<SESearchQuestion>.self, from: urlString).items
    }

    func fetchTopAnswer(questionId: Int) async throws -> SEAnswer? {
        let urlString =
            "\(baseURL)/questions/\(questionId)/answers?order=desc&sort=votes&site=stackoverflow&filter=withbody&pagesize=3"
        let answers = try await fetch(SEResponse<SEAnswer>.self, from: urlString).items
        return answers.first(where: { $0.isAccepted }) ?? answers.first
    }

    private func fetch<T: Decodable>(_ type: T.Type, from urlString: String) async throws -> T {
        guard let url = URL(string: urlString) else {
            throw WebFetchError.invalidURL
        }
        var request = URLRequest(url: url)
        request.timeoutInterval = requestTimeout
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            guard let httpResponse = response as? HTTPURLResponse,
                (200...299).contains(httpResponse.statusCode)
            else {
                throw WebFetchError.noData
            }
            return try JSONDecoder().decode(T.self, from: data)
        } catch let error as WebFetchError {
            throw error
        } catch {
            throw WebFetchError.networkError(error)
        }
    }
}
