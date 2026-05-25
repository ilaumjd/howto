import Foundation

/// Abstraction for running external processes, enabling dependency injection for testing.
protocol ProcessServiceProtocol {
    /// Runs a process that returns its stdout as a string.
    func runProcessReturningOutput(executablePath: String, arguments: [String]) async throws -> String
    /// Runs a process with piped input, writing to its stdin and forwarding stdout to the terminal.
    func runProcessWithPipe(input: String, executablePath: String, arguments: [String]) async throws
}

/// Runs external shell processes using `Foundation.Process` with async/await continuations.
struct ProcessService: ProcessServiceProtocol {
    private let bufferSize = 1024 * 1024
    /// Path to the system shell (`/bin/sh`) for executing shell commands.
    static let shellPath = "/bin/sh"

    /// Executes a process and returns its captured stdout as a trimmed string.
    func runProcessReturningOutput(executablePath: String, arguments: [String]) async throws -> String {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: executablePath)
        process.arguments = arguments

        let outputPipe = Pipe()
        process.standardOutput = outputPipe
        process.standardError = FileHandle.standardError

        do {
            try process.run()
        } catch {
            throw ProcessError.executionFailed(error)
        }

        return try await withCheckedThrowingContinuation { continuation in
            process.terminationHandler = { _ in
                let outputData = outputPipe.fileHandleForReading.readDataToEndOfFile()
                let outputString = String(decoding: outputData, as: UTF8.self)
                    .trimmingCharacters(in: .whitespacesAndNewlines)
                continuation.resume(returning: outputString)
            }
        }
    }

    /// Pipes `input` data into the process's stdin and forwards its stdout to the terminal.
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
        } catch {
            throw ProcessError.executionFailed(error)
        }

        if let data = input.data(using: .utf8) {
            inputPipe.fileHandleForWriting.write(data)
            try inputPipe.fileHandleForWriting.close()
        }

        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            process.terminationHandler = { _ in
                continuation.resume()
            }
        }
    }
}
