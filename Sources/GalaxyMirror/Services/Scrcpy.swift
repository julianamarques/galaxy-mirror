import Darwin
import Foundation

enum Scrcpy {
    private static let log = FileManager.default.temporaryDirectory.appendingPathComponent("GalaxyMirror-scrcpy.log")

    static func launch(
        serial: String,
        title: String,
        onExit: @escaping @Sendable (_ failure: String?) -> Void
    ) throws -> Process {
        let process = Tools.makeProcess(
            try Tools.require("scrcpy"),
            MirrorArguments.make(serial: serial, title: title),
            environment: ["ADB": try Tools.require("adb").path]
        )

        FileManager.default.createFile(atPath: log.path, contents: nil)
        let output = try FileHandle(forWritingTo: log)

        var primary: Int32 = -1
        var replica: Int32 = -1
        guard openpty(&primary, &replica, nil, nil, nil) == 0 else {
            throw ToolError.failed("Não foi possível iniciar o scrcpy.")
        }
        let terminal = FileHandle(fileDescriptor: replica, closeOnDealloc: true)
        process.standardOutput = terminal
        process.standardError = terminal

        let reader = DispatchSource.makeReadSource(fileDescriptor: primary, queue: .global(qos: .utility))
        reader.setEventHandler {
            var buffer = [UInt8](repeating: 0, count: 4096)
            let count = read(primary, &buffer, buffer.count)
            if count > 0 {
                try? output.write(contentsOf: buffer[..<count])
            } else {
                reader.cancel()
            }
        }
        reader.setCancelHandler {
            close(primary)
            try? output.close()
        }

        process.terminationHandler = { process in
            let status = process.terminationStatus
            DispatchQueue.global().asyncAfter(deadline: .now() + 0.3) {
                onExit(status == 0 ? nil : errorSummary())
            }
        }

        do {
            try process.run()
        } catch {
            close(primary)
            try? output.close()
            throw error
        }
        try? terminal.close()
        reader.resume()
        return process
    }

    static func waitUntilStreaming(_ process: Process, timeout: TimeInterval) async -> Bool {
        let deadline = Date().addingTimeInterval(timeout)
        while Date() < deadline, !Task.isCancelled, process.isRunning {
            if let text = try? String(contentsOf: log, encoding: .utf8), text.contains("Texture:") { return true }
            try? await Task.sleep(for: .milliseconds(300))
        }
        return false
    }

    private static func errorSummary() -> String {
        let errors = ((try? String(contentsOf: log, encoding: .utf8)) ?? "")
            .split(whereSeparator: \.isNewline)
            .filter { $0.contains("ERROR") }
            .suffix(3)
            .joined(separator: "\n")
        return errors.isEmpty ? "O espelhamento foi encerrado inesperadamente." : errors
    }
}
