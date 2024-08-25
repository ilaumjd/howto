import Foundation

struct ProcessService {
    
    func printUsingBat(output: String) {
        if let batPath = findBatPath() {
            pipeOutputToBat(output: output, batPath: batPath)
        }
    }
    
    func pipeOutputToBat(output: String, batPath: String) {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: batPath)
        process.arguments = ["-pp", "-l", "kotlin"]

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
