import Foundation

struct OutputService {
    let context: SearchContext

    func performOutput(index: Int, answer: Answer) async {
        if index > 0 {
            print("\n==============================================================\n")
        }
        if context.config.useBat {
            do {
                let batService = BatService(context: context)
                try await batService.performBatOuput(answer: answer)
            } catch {
                performDefaultOutput(answer: answer)
            }
        } else {
            performDefaultOutput(answer: answer)
        }
    }

    private func performDefaultOutput(answer: Answer) {
        if let snippet = answer.codeSnippets.first {
            print(snippet)
        } else {
            print(answer.fullAnswer)
        }
    }
}
