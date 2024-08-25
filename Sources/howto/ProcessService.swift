import Foundation

struct ProcessService {
    
    func printUsingBat(answer: Answer, output: String) {
        if let batPath = findBatPath() {
            ensureBatLanguagesFileExists()
            let language = getOutputLanguageByTags(answer: answer)
            pipeOutputToBat(language: language, output: output + "\n", batPath: batPath)
        }
    }
    
    func getOutputLanguageByTags(answer: Answer) -> String {
        let batLanguages = readBatLanguages()
        let tags = Set(answer.tags)
        return batLanguages.first { tags.contains($0) } ?? "bash"
    }
    
    func ensureBatLanguagesFileExists() {
        let filePath = getBatLanguagesPath()
        let fileManager = FileManager.default
        
        if !fileManager.fileExists(atPath: filePath) {
            print("bat-languages file not found. Creating default file at \(filePath)")
            
            let defaultContent = getBatLanguagesFiles() ?? ""
            print("dadsasd", defaultContent)
            
            do {
                try fileManager.createDirectory(atPath: (filePath as NSString).deletingLastPathComponent, withIntermediateDirectories: true, attributes: nil)
                try defaultContent.write(toFile: filePath, atomically: true, encoding: .utf8)
            } catch {
                print("Error creating default bat-languages file: \(error)")
            }
        }
    }
    
    func getBatLanguagesFiles() -> String? {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: findBatPath()!)
        process.arguments = ["--list-languages"]
        
        let outputPipe = Pipe()
        process.standardOutput = outputPipe
        process.standardError = FileHandle.standardError
        
        do {
            try process.run()
            process.waitUntilExit()
            
            let outputData = outputPipe.fileHandleForReading.readDataToEndOfFile()
            if let outputString = String(data: outputData, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines) {
                return outputString.isEmpty ? nil : outputString
            }
        } catch {
            print("Error finding bat path: \(error)")
        }
        
        return nil
    }
    
    func getBatLanguagesPath() -> String {
        let fileManager = FileManager.default
        let homeDirectory = fileManager.homeDirectoryForCurrentUser
        return homeDirectory.appendingPathComponent(".config/howto/bat-languages").path
    }

    func readBatLanguages() -> [String] {
        let filePath = getBatLanguagesPath()
        
        do {
            let contents = try String(contentsOfFile: filePath, encoding: .utf8)
            let lines = contents.components(separatedBy: .newlines)
            
            var languageIdentifiers = [String]()
            for line in lines {
                let parts = line.components(separatedBy: ":")
                if parts.count == 2 {
                    let identifiers = parts[1].split(separator: ",")
                        .map { $0.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() }
                    languageIdentifiers.append(contentsOf: identifiers)
                    
                    let languageName = parts[0].trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
                    languageIdentifiers.append(languageName)
                }
            }
            
            return Array(Set(languageIdentifiers)).sorted()
        } catch {
            print("Error reading bat-languages file: \(error)")
            return []
        }
    }
    
    
    func pipeOutputToBat(language: String, output: String, batPath: String) {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: batPath)
        process.arguments = ["-pp", "-l", language]

        let inputPipe = Pipe()
        
        process.standardInput = inputPipe
        process.standardOutput = FileHandle.standardOutput
        process.standardError = FileHandle.standardError

        do {
            try process.run()
            if let data = output.data(using: .utf8) {
                inputPipe.fileHandleForWriting.write(data)
                inputPipe.fileHandleForWriting.closeFile()
            }

            process.waitUntilExit()
        } catch {
            print("Error piping to bat: \(error)")
        }
    }
    
    func findBatPath() -> String? {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/bin/sh")
        process.arguments = ["-c", "command -v bat"]
        
        let outputPipe = Pipe()
        process.standardOutput = outputPipe
        process.standardError = FileHandle.standardError
        
        do {
            try process.run()
            process.waitUntilExit()
            
            let outputData = outputPipe.fileHandleForReading.readDataToEndOfFile()
            if let outputString = String(data: outputData, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines) {
                return outputString.isEmpty ? nil : outputString
            }
        } catch {
            print("Error finding bat path: \(error)")
        }
        
        return nil
    }
    
}
