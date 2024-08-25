import Foundation

protocol OutputServiceProtocol {
    func output(answer: Answer) async throws
}

class OutputService: OutputServiceProtocol {
    private let config: Config
    private let batService: BatService

    init(config: Config, batService: BatService = BatService()) {
        self.config = config
        self.batService = batService
    }

    func output(answer: Answer) async throws {
        if config.useBat {
            do {
                try await batService.printUsingBat(answer: answer)
            } catch {
                deafultOutput(answer: answer)
            }
        } else {
            deafultOutput(answer: answer)
        }
    }

    private func deafultOutput(answer: Answer) {
        if let snippet = answer.codeSnippets.first {
            print(snippet)
        } else {
            print(answer.fullAnswer)
        }
    }
}
