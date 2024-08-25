import Foundation

struct ProcessService {
    
    static func runProcessAndReturnOutput(executablePath: String, arguments: [String]) -> Result<String, ProcessError> {
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
    
    static func runProcessWithPipe(input: String, executablePath: String, arguments: [String]) {
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
            print("Error piping to \(executablePath): \(error)")
        }
    }
}
