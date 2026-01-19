import Foundation

public enum Shell {
    public struct Line {
        public let text: String
        public let isError: Bool
    }

    @discardableResult
    public static func run(_ launchPath: String, _ args: [String] = []) throws -> (Int32, String, String) {
        let p = Process()
        p.executableURL = URL(fileURLWithPath: launchPath)
        p.arguments = args
        let out = Pipe(), err = Pipe()
        p.standardOutput = out; p.standardError = err
        try p.run(); p.waitUntilExit()
        let stdout = String(data: out.fileHandleForReading.readDataToEndOfFile(), encoding: .utf8) ?? ""
        let stderr = String(data: err.fileHandleForReading.readDataToEndOfFile(), encoding: .utf8) ?? ""
        return (p.terminationStatus, stdout, stderr)
    }

    /// Run a process and stream stdout/stderr as they arrive.
    /// Example:
    /// for try await line in Shell.stream("/bin/zsh", ["-lc", "echo hi; sleep 1; echo bye"]) {
    ///     print(line.text)
    /// }
    public static func stream(
        _ launchPath: String,
        _ arguments: [String] = []
    ) -> AsyncThrowingStream<Line, Error> {
        AsyncThrowingStream { continuation in
            let process = Process()
            process.executableURL = URL(fileURLWithPath: launchPath)
            process.arguments = arguments

            let stdoutPipe = Pipe()
            let stderrPipe = Pipe()
            process.standardOutput = stdoutPipe
            process.standardError = stderrPipe

            func handle(_ handle: FileHandle, isError: Bool) {
                handle.readabilityHandler = { fh in
                    let data = fh.availableData
                    if !data.isEmpty, let str = String(data: data, encoding: .utf8) {
                        for line in str.split(separator: "\n", omittingEmptySubsequences: false) {
                            continuation.yield(Line(text: String(line), isError: isError))
                        }
                    }
                }
            }

            func readRemaining(_ handle: FileHandle, isError: Bool) {
                // Read any remaining data in the buffer after process terminates
                let data = handle.readDataToEndOfFile()
                if !data.isEmpty, let str = String(data: data, encoding: .utf8) {
                    for line in str.split(separator: "\n", omittingEmptySubsequences: false) {
                        continuation.yield(Line(text: String(line), isError: isError))
                    }
                }
            }

            handle(stdoutPipe.fileHandleForReading, isError: false)
            handle(stderrPipe.fileHandleForReading, isError: true)

            process.terminationHandler = { _ in
                // Stop the readability handlers first
                stdoutPipe.fileHandleForReading.readabilityHandler = nil
                stderrPipe.fileHandleForReading.readabilityHandler = nil

                // Read any remaining buffered data
                readRemaining(stdoutPipe.fileHandleForReading, isError: false)
                readRemaining(stderrPipe.fileHandleForReading, isError: true)

                continuation.finish()
            }

            do {
                try process.run()
            } catch {
                continuation.finish(throwing: error)
            }

            continuation.onTermination = { _ in
                if process.isRunning {
                    process.terminate()
                }
            }
        }
    }
}
