import Foundation

struct BatService {
    private let fileManager = FileManager.default
    
    func printUsingBat(answer: Answer) {
        guard case .success(let batPath) = getBatExecutablePath() else { return }
        guard case .success(let batLanguagesPath) = ensureBatLanguagesFileExists(batPath: batPath) else { return }
        guard case .success(let batLanguages) = readBatLanguages(batLanguagesPath: batLanguagesPath) else { return }
        guard case .success(let language) = getOutputLanguage(batLanguages: batLanguages, answer: answer) else { return }
        let text = (answer.codeSnippets.first ?? "") + "\n"
        pipeToBat(text: text, batPath: batPath, language: language)
    }
    
    private func ensureBatLanguagesFileExists(batPath: String) -> Result<String, ProcessError> {
        let batLanguagesPath = fileManager.homeDirectoryForCurrentUser.appendingPathComponent(".config/howto/bat-languages").path
        guard !fileManager.fileExists(atPath: batLanguagesPath) else { return .success(batLanguagesPath) }
        
        let rawStringResult = getBatLanguagesFile(batPath: batPath)
        
        switch rawStringResult {
        case .success(let rawString):
            do {
                try fileManager.createDirectory(atPath: (batLanguagesPath as NSString).deletingLastPathComponent, withIntermediateDirectories: true, attributes: nil)
                try rawString.write(toFile: batLanguagesPath, atomically: true, encoding: .utf8)
                return .success(batLanguagesPath)
            } catch {
                return .failure(.batLanguagesError(error))
            }
        case .failure(let error):
            return .failure(.batLanguagesError(error))
        }
    }
    
    private func readBatLanguages(batLanguagesPath: String) -> Result<Set<String>, ProcessError> {
        do {
            let contents = try String(contentsOfFile: batLanguagesPath, encoding: .utf8)
            let languages = Set(contents.components(separatedBy: .newlines)
                .flatMap { line -> [String] in
                    let parts = line.components(separatedBy: ":")
                    guard parts.count == 2 else { return [] }
                    let identifiers = parts[1].split(separator: ",").map { $0.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() }
                    return [parts[0].trimmingCharacters(in: .whitespacesAndNewlines).lowercased()] + identifiers
                })
            return .success(languages)
        } catch {
            return .failure(.batLanguagesError(error))
        }
    }
    
    func getOutputLanguage(batLanguages: Set<String>, answer: Answer) -> Result<String, Error> {
        return .success(Set(answer.tags).intersection(batLanguages).first ?? "bash")
    }
    
    private func getBatExecutablePath() -> Result<String, ProcessError> {
        ProcessService.runProcessAndReturnOutput(executablePath: "/bin/sh", arguments: ["-c", "command -v bat"])
    }
    
    private func getBatLanguagesFile(batPath: String) -> Result<String, ProcessError> {
        ProcessService.runProcessAndReturnOutput(executablePath: batPath, arguments: ["--list-languages"])
    }
    
    private func pipeToBat(text: String, batPath: String, language: String) {
        ProcessService.runProcessWithPipe(input: text, executablePath: batPath, arguments: ["-pp", "-l", language])
    }
}
