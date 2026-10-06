import Foundation

enum Tools {
    static let searchPaths = [
        "/opt/homebrew/bin",
        "/usr/local/bin",
        NSHomeDirectory() + "/Library/Android/sdk/platform-tools",
        "/usr/bin",
    ]

    private static let environment: [String: String] = {
        var env = ProcessInfo.processInfo.environment
        env["PATH"] = (searchPaths + [env["PATH"] ?? ""]).joined(separator: ":")
        return env
    }()

    static func find(_ name: String) -> URL? {
        searchPaths
            .map { URL(fileURLWithPath: $0).appendingPathComponent(name) }
            .first { FileManager.default.isExecutableFile(atPath: $0.path) }
    }

    static func require(_ name: String) throws -> URL {
        guard let url = find(name) else { throw ToolError.missing(name) }
        return url
    }

    static var isInstalled: Bool {
        find("adb") != nil && find("scrcpy") != nil
    }

    static func makeProcess(_ executable: URL, _ arguments: [String], environment extra: [String: String] = [:]) -> Process {
        let process = Process()
        process.executableURL = executable
        process.arguments = arguments
        process.environment = environment.merging(extra) { $1 }
        process.standardInput = FileHandle.nullDevice
        return process
    }

    static func run(
        _ executable: URL,
        _ arguments: [String],
        timeout: TimeInterval,
        captureOutput: Bool = true
    ) async throws -> CommandResult {
        let process = makeProcess(executable, arguments)

        guard captureOutput else {
            process.standardOutput = FileHandle.nullDevice
            process.standardError = FileHandle.nullDevice
            try await launch(process, timeout: timeout)
            return CommandResult(stdout: "", stderr: "")
        }

        let out = Pipe(), err = Pipe()
        process.standardOutput = out
        process.standardError = err
        async let stdout = read(out)
        async let stderr = read(err)
        do {
            try await launch(process, timeout: timeout)
        } catch {
            try? out.fileHandleForWriting.close()
            try? err.fileHandleForWriting.close()
            _ = await (stdout, stderr)
            throw error
        }
        return CommandResult(stdout: await stdout, stderr: await stderr)
    }

    private static func launch(_ process: Process, timeout: TimeInterval) async throws {
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            process.terminationHandler = { _ in continuation.resume() }
            do {
                try process.run()
            } catch {
                process.terminationHandler = nil
                continuation.resume(throwing: error)
                return
            }
            DispatchQueue.global().asyncAfter(deadline: .now() + timeout) {
                if process.isRunning { process.terminate() }
            }
        }
    }

    private static func read(_ pipe: Pipe) async -> String {
        var data = Data()
        do {
            for try await byte in pipe.fileHandleForReading.bytes { data.append(byte) }
        } catch {}
        return String(decoding: data, as: UTF8.self)
    }
}
