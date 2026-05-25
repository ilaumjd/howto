import Foundation

/// Abstraction for presenting answers to the user.
protocol OutputServiceProtocol {
    /// Displays the answer at the given index, optionally using bat highlighting.
    func performOutput(index: Int, answer: Answer) async
    /// Creates an output service bound to the given search context.
    init(context: SearchContext)
}

/// Handles formatting and displaying answers, optionally with bat syntax highlighting.
struct OutputService: OutputServiceProtocol {
    /// The search context containing configuration and query terms.
    let context: SearchContext

    init(context: SearchContext) {
        self.context = context
    }

    /// Displays the answer: prints a decorative header (with source link if enabled),
    /// then renders the answer content via bat or plain text.
    func performOutput(index: Int, answer: Answer) async {
        printDecoration(index: index, answer: answer)
        if context.config.useBat {
            do {
                let batService = BatService(context: context)
                try await batService.performBatOutput(answer: answer)
            } catch {
                print("Warning: bat syntax highlighting failed — \(error.localizedDescription). Falling back to plain output.", to: &stdErr)
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
