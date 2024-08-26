import Foundation

protocol OutputServiceProtocol {
    func output(answer: Answer) async throws
}

struct OutputService: OutputServiceProtocol {

    let config: Config

    func output(answer: Answer) async {
        if config.useBat {
            do {
                let batService = BatService(config: config)
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
