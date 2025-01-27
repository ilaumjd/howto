import Foundation

struct BatService: ~Copyable {
    let context: SearchContext
    let fileManager: FileManager
    let processService: ProcessServiceProtocol

    init(
        context: SearchContext, fileManager: FileManager = .default,
        processService: ProcessServiceProtocol = ProcessService()
    ) {
        self.context = context
        self.fileManager = fileManager
        self.processService = processService
    }

    func performBatOuput(answer: Answer) async throws {
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

        if let queryMatch = context.query.first(where: { batLanguagesSet.contains($0.lowercased()) }) {
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
            return try await processService.runProcessAndReturnOutput(
                executablePath: "/bin/sh", arguments: ["-c", "command -v bat"]
            )
        } catch {
            throw BatServiceError.batNotFound
        }
    }

    private func getBatLanguagesFile(batPath: String) async throws -> String {
        do {
            return try await processService.runProcessAndReturnOutput(
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
