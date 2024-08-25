import Foundation

struct ProcessService {
    private let fileManager = FileManager.default
    
    func printUsingBat(answer: Answer) {
        guard case .success(let batPath) = findBatPath() else { return }
        guard case .success(let batLanguagesPath) = ensureBatLanguagesFileExists(batPath: batPath) else { return }
        guard case .success(let batLanguages) = readBatLanguages(batLanguagesPath: batLanguagesPath) else { return }
        guard case .success(let language) = getOutputLanguage(batLanguages: batLanguages, answer: answer) else { return }
        let text = (answer.codeSnippets.first ?? "") + "\n"
        pipeToBat(text: text, batPath: batPath, language: language)
    }
    
    func getOutputLanguage(batLanguages: Set<String>, answer: Answer) -> Result<String, Error> {
        return .success(Set(answer.tags).intersection(batLanguages).first ?? "bash")
    }
    
    private func ensureBatLanguagesFileExists(batPath: String) -> Result<String, ProcessError> {
        let batLanguagesPath = fileManager.homeDirectoryForCurrentUser.appendingPathComponent(".config/howto/bat-languages").path
        guard !fileManager.fileExists(atPath: batLanguagesPath) else { return .success(batLanguagesPath) }
        
        let batLanguagesRawStringResult = runProcessAndReturn(executablePath: batPath, arguments: ["--list-languages"])
        
        switch batLanguagesRawStringResult {
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
    
    private func pipeToBat(text: String, batPath: String, language: String) {
        runProcessWithPipe(input: text, executablePath: batPath, arguments: ["-pp", "-l", language])
    }
    private func runProcessWithPipe(input: String, executablePath: String, arguments: [String]) {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: executablePath)
        process.arguments = arguments
        
        let inputPipe = Pipe()
        process.standardInput = inputPipe
        process.standardOutput = FileHandle.standardOutput
        process.standardError = FileHandle.standardError
        
        do {
            try process.run()
            if let data = input.data(using: .utf8) {
                inputPipe.fileHandleForWriting.write(data)
                inputPipe.fileHandleForWriting.closeFile()
            }
            process.waitUntilExit()
        } catch {
            print("Error piping to bat: \(error)")
        }
    }
    
    private func findBatPath() -> Result<String, ProcessError> {
        runProcessAndReturn(executablePath: "/bin/sh", arguments: ["-c", "command -v bat"])
    }
    
    private func runProcessAndReturn(executablePath: String, arguments: [String]) -> Result<String, ProcessError> {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: executablePath)
        process.arguments = arguments
        
        let outputPipe = Pipe()
        process.standardOutput = outputPipe
        process.standardError = FileHandle.standardError
        
        do {
            try process.run()
            process.waitUntilExit()
            
            let outputData = outputPipe.fileHandleForReading.readDataToEndOfFile()
            let outputString = String(data: outputData, encoding: .utf8)!.trimmingCharacters(in: .whitespacesAndNewlines)
            return .success(outputString)
        } catch {
            return .failure(.runError(error))
        }
    }
}
