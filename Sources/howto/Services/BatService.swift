import Foundation

/// Orchestrates syntax-highlighted output via the `bat` command-line tool.
/// Determines the output language based on query terms, answer tags, or question title.
struct BatService {
    /// The search context including configuration and query terms.
    let context: SearchContext
    /// File manager for cache and file operations (injectable for testing).
    let fileManager: FileManager
    /// Process runner abstraction (injectable for testing).
    let processService: ProcessServiceProtocol

    /// Creates a bat service with optional dependency injection.
    /// - Parameters:
    ///   - context: The current search context.
    ///   - fileManager: File manager instance (default: `.default`).
    ///   - processService: Process runner instance (default: `ProcessService()`).
    init(
        context: SearchContext, fileManager: FileManager = .default,
        processService: ProcessServiceProtocol = ProcessService()
    ) {
        self.context = context
        self.fileManager = fileManager
        self.processService = processService
    }

    /// Pipes the answer text through bat for syntax-highlighted output.
    /// Locates bat, ensures the language mapping file exists, resolves the
    /// output language, and pipes the text through bat.
    func performBatOutput(answer: Answer) async throws {
        let batPath = try await getBatExecutablePath()
        let batLanguagesPath = try await createBatLanguagesFileIfNeeded(batPath: batPath)
        let batLanguages = try readBatLanguages(batLanguagesPath: batLanguagesPath)
        let language = try getOutputLanguage(batLanguages: batLanguages, answer: answer)
        let text = answer.answerToShow + "\n"
        try await pipeToBat(input: text, batPath: batPath, language: language)
    }

    private func createBatLanguagesFileIfNeeded(batPath: String) async throws -> String {
        let batLanguagesPath = fileManager.homeDirectoryForCurrentUser.appendingPathComponent(
            ".config/howto/bat-languages"
        ).path
        guard !fileManager.fileExists(atPath: batLanguagesPath) else { return batLanguagesPath }

        let rawString = try await getBatLanguagesFile(batPath: batPath)

        do {
            try fileManager.createDirectory(
                atPath: (batLanguagesPath as NSString).deletingLastPathComponent,
                withIntermediateDirectories: true, attributes: nil
            )
            try rawString.write(toFile: batLanguagesPath, atomically: true, encoding: .utf8)
            return batLanguagesPath
        } catch {
            throw BatServiceError.batLanguagesFileCreationFailed(error)
        }
    }

    private func readBatLanguages(batLanguagesPath: String) throws -> [String] {
        do {
            let contents = try String(contentsOfFile: batLanguagesPath, encoding: .utf8)
            return contents.components(separatedBy: .newlines)
                .flatMap { line -> [String] in
                    let parts = line.components(separatedBy: ":")
                    guard parts.count == 2 else { return [] }
                    let identifiers = parts[1].split(separator: ",").map {
                        $0.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
                    }
                    return [parts[0].trimmingCharacters(in: .whitespacesAndNewlines).lowercased()]
                        + identifiers
                }
        } catch {
            throw BatServiceError.batLanguagesFileReadFailed(error)
        }
    }

    private func getOutputLanguage(batLanguages: [String], answer: Answer) throws -> String {
        let batLanguagesSet = Set(batLanguages)

        if let queryMatch = context.queryTerms.first(where: { batLanguagesSet.contains($0.lowercased()) }) {
            return queryMatch.lowercased()
        }

        if let tagMatch = answer.tags.first(where: { batLanguagesSet.contains($0.lowercased()) }) {
            return tagMatch.lowercased()
        }

        let titleTerms = answer.questionTitle.split(separator: " ").map { $0.lowercased() }
        if let titleMatch = titleTerms.first(where: { batLanguagesSet.contains($0) }) {
            return titleMatch
        }

        throw BatServiceError.languageNotFound
    }

    private func getBatExecutablePath() async throws -> String {
        do {
            return try await processService.runProcessReturningOutput(
                executablePath: ProcessService.shellPath, arguments: ["-c", "command -v bat"]
            )
        } catch {
            throw BatServiceError.batNotFound
        }
    }

    private func getBatLanguagesFile(batPath: String) async throws -> String {
        do {
            return try await processService.runProcessReturningOutput(
                executablePath: batPath, arguments: ["--list-languages"]
            )
        } catch {
            throw BatServiceError.processError(.executionFailed(error))
        }
    }

    private func pipeToBat(input: String, batPath: String, language: String) async throws {
        do {
            try await processService.runProcessWithPipe(
                input: input, executablePath: batPath, arguments: ["-pp", "-l", language]
            )
        } catch {
            throw BatServiceError.processError(.executionFailed(error))
        }
    }
}
