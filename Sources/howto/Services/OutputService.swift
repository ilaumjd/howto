import Foundation

struct OutputService {
    let context: SearchContext

    func performOutput(index: Int, answer: Answer) async {
        printDecoration(index: index, answer: answer)
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

    private func printDecoration(index: Int, answer: Answer) {
        if index > 0 {
            print("\n==============================================================\n")
        }
        if context.config.showLink {
            print("Source link:", answer.url)
        }
    }

    private func performDefaultOutput(answer: Answer) {
        print(answer.answerToShow)
    }
}
