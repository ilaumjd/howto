import Foundation

protocol ProcessServiceProtocol {
    func runProcessAndReturnOutput(executablePath: String, arguments: [String]) async throws -> String
    func runProcessWithPipe(input: String, executablePath: String, arguments: [String]) async throws
}

struct ProcessService: ProcessServiceProtocol {
    func runProcessAndReturnOutput(executablePath: String, arguments: [String]) async throws -> String {
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
            guard let outputString = String(data: outputData, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines) else {
                throw ProcessError.outputParsingFailed
            }
            return outputString
        } catch {
            throw ProcessError.executionFailed(error)
        }
    }
    
    func runProcessWithPipe(input: String, executablePath: String, arguments: [String]) async throws {
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
                try inputPipe.fileHandleForWriting.close()
            }
            process.waitUntilExit()
        } catch {
            throw ProcessError.executionFailed(error)
        }
    }
}
