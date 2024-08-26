import Foundation

struct OutputService {

    let config: Config

    func output(query: [String], answer: Answer) async {
        if config.useBat {
            do {
                let batService = BatService(config: config)
                try await batService.printUsingBat(query: query, answer: answer)
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
